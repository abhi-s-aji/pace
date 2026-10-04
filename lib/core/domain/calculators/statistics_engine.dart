import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'consistency_engine.dart';
import '../../utils/date_utils.dart';

enum DateRangeFilter {
  sevenDays,
  thirtyDays,
  ninetyDays,
  oneYear,
  allTime}

extension DateRangeFilterExtension on DateRangeFilter {
  String get label {
    switch (this) {
      case DateRangeFilter.sevenDays:
        return '7 Days';
      case DateRangeFilter.thirtyDays:
        return '30 Days';
      case DateRangeFilter.ninetyDays:
        return '90 Days';
      case DateRangeFilter.oneYear:
        return '1 Year';
      case DateRangeFilter.allTime:
        return 'All Time';
    }
  }

  int? get dayCount {
    switch (this) {
      case DateRangeFilter.sevenDays:
        return 7;
      case DateRangeFilter.thirtyDays:
        return 30;
      case DateRangeFilter.ninetyDays:
        return 90;
      case DateRangeFilter.oneYear:
        return 365;
      case DateRangeFilter.allTime:
        return null;
    }
  }
}

@immutable
class HabitStat {
  final String habitId;
  final String name;
  final String category;
  final int completionsCount;
  final int scheduledCount;
  final double completionRatePercentage;

  const HabitStat({
    required this.habitId,
    required this.name,
    required this.category,
    required this.completionsCount,
    required this.scheduledCount,
    required this.completionRatePercentage});
}

@immutable
class DailyTrendPoint {
  final String date;
  final DateTime dateTime;
  final int activityCount;
  final int focusMinutes;
  final int habitsCompleted;
  final double completionPercentage;

  const DailyTrendPoint({
    required this.date,
    required this.dateTime,
    this.activityCount = 0,
    this.focusMinutes = 0,
    this.habitsCompleted = 0,
    this.completionPercentage = 0.0});
}

@immutable
class ComprehensiveStatistics {
  final DateRangeFilter range;
  final int totalActivities;
  final int activeDays;
  final int currentStreak;
  final int bestStreak;
  final double consistencyPercentage;
  final int totalFocusMinutes;
  final int totalFocusSessions;
  final double avgFocusSessionMinutes;
  final int activeFocusDays;
  final int habitCompletionsCount;
  final double overallHabitCompletionRate;
  final Map<String, int> activitiesBySource;
  final Map<String, int> activitiesByCategory;
  final List<HabitStat> habitBreakdown;
  final List<DailyTrendPoint> dailyTrends;

  const ComprehensiveStatistics({
    required this.range,
    this.totalActivities = 0,
    this.activeDays = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.consistencyPercentage = 0.0,
    this.totalFocusMinutes = 0,
    this.totalFocusSessions = 0,
    this.avgFocusSessionMinutes = 0.0,
    this.activeFocusDays = 0,
    this.habitCompletionsCount = 0,
    this.overallHabitCompletionRate = 0.0,
    this.activitiesBySource = const {},
    this.activitiesByCategory = const {},
    this.habitBreakdown = const [],
    this.dailyTrends = const []});
}

abstract class StatisticsEngine {
  static ComprehensiveStatistics calculate({
    required DateRangeFilter range,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<Activity> activities,
    required List<FocusSession> focusSessions,
    required Map<String, DailySummary> dailySummaries,
    DateTime? referenceDate}) {
    final today = referenceDate != null
        ? PaceDateUtils.normalizeDate(referenceDate)
        : PaceDateUtils.today();

    DateTime? startDate;
    if (range.dayCount != null) {
      startDate = today.subtract(Duration(days: range.dayCount! - 1));
    }

    final startDateStr = startDate != null ? PaceDateUtils.toIsoDateString(startDate) : null;
    final endDateStr = PaceDateUtils.toIsoDateString(today);

    // 1. Filter activities within date range
    final filteredActivities = activities.where((a) {
      if (startDateStr != null && a.date.compareTo(startDateStr) < 0) return false;
      if (a.date.compareTo(endDateStr) > 0) return false;
      return true;
    }).toList();

    // 2. Filter completions within range
    final filteredCompletions = completions.where((c) {
      if (startDateStr != null && c.date.compareTo(startDateStr) < 0) return false;
      if (c.date.compareTo(endDateStr) > 0) return false;
      return true;
    }).toList();

    // 3. Filter focus sessions within range
    final filteredFocus = focusSessions.where((f) {
      if (startDateStr != null && f.date.compareTo(startDateStr) < 0) return false;
      if (f.date.compareTo(endDateStr) > 0) return false;
      return true;
    }).toList();

    // 4. Summaries calculation (Consistency Engine)
    final sortedSummaries = dailySummaries.values.where((s) {
      if (startDateStr != null && s.date.compareTo(startDateStr) < 0) return false;
      if (s.date.compareTo(endDateStr) > 0) return false;
      return true;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final consistencyStats = ConsistencyEngine.calculate(sortedSummaries, referenceDate: today);

    // 5. Activity breakdown by source & category
    final Map<String, int> bySource = {'habit': 0, 'focus': 0, 'manual': 0};
    final Map<String, int> byCategory = {};

    for (final act in filteredActivities) {
      bySource[act.source] = (bySource[act.source] ?? 0) + 1;
      final cat = act.category.isEmpty ? 'General' : act.category;
      byCategory[cat] = (byCategory[cat] ?? 0) + 1;
    }

    // 6. Focus Statistics
    final totalFocusMins = filteredFocus.fold<int>(0, (sum, f) => sum + f.actualDurationMinutes);
    final focusSessionCount = filteredFocus.length;
    final avgFocusMins = focusSessionCount > 0 ? (totalFocusMins / focusSessionCount) : 0.0;
    final activeFocusDaysCount = filteredFocus.map((f) => f.date).toSet().length;

    // 7. Habit breakdown
    final List<HabitStat> habitBreakdown = [];
    int totalScheduledHabitInstances = 0;
    int totalCompletedHabitInstances = 0;

    final activeHabits = habits.where((h) => !h.isArchived).toList();
    for (final habit in activeHabits) {
      final habitComps = filteredCompletions.where((c) => c.habitId == habit.id && c.isCompleted).length;

      // Count scheduled days in date range
      int scheduledCount = 0;
      final rangeDays = range.dayCount ?? 30; // Default to 30 if all-time
      for (int i = 0; i < rangeDays; i++) {
        final d = today.subtract(Duration(days: i));
        if (habit.isScheduledForDay(d)) {
          scheduledCount++;
        }
      }

      totalScheduledHabitInstances += scheduledCount;
      totalCompletedHabitInstances += habitComps;

      final pct = scheduledCount > 0 ? ((habitComps / scheduledCount) * 100.0).clamp(0.0, 100.0) : 0.0;

      habitBreakdown.add(HabitStat(
        habitId: habit.id,
        name: habit.name,
        category: habit.category,
        completionsCount: habitComps,
        scheduledCount: scheduledCount,
        completionRatePercentage: pct,
      ));
    }

    final overallHabitRate = totalScheduledHabitInstances > 0
        ? ((totalCompletedHabitInstances / totalScheduledHabitInstances) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    // 8. Daily trend points
    final List<DailyTrendPoint> dailyTrends = [];
    final trendDaysCount = range.dayCount ?? 14;
    for (int i = trendDaysCount - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = PaceDateUtils.toIsoDateString(date);

      final summary = dailySummaries[dateStr];
      final dayActs = filteredActivities.where((a) => a.date == dateStr).length;
      final dayFocusMins = filteredFocus.where((f) => f.date == dateStr).fold<int>(0, (sum, f) => sum + f.actualDurationMinutes);
      final dayHabitsDone = filteredCompletions.where((c) => c.date == dateStr && c.isCompleted).length;

      dailyTrends.add(DailyTrendPoint(
        date: dateStr,
        dateTime: date,
        activityCount: dayActs,
        focusMinutes: dayFocusMins,
        habitsCompleted: dayHabitsDone,
        completionPercentage: summary?.completionPercentage ?? 0.0,
      ));
    }

    return ComprehensiveStatistics(
      range: range,
      totalActivities: filteredActivities.length,
      activeDays: consistencyStats.activeDays,
      currentStreak: consistencyStats.currentStreak,
      bestStreak: consistencyStats.bestStreak,
      consistencyPercentage: consistencyStats.overallCompletionPercentage,
      totalFocusMinutes: totalFocusMins,
      totalFocusSessions: focusSessionCount,
      avgFocusSessionMinutes: avgFocusMins,
      activeFocusDays: activeFocusDaysCount,
      habitCompletionsCount: totalCompletedHabitInstances,
      overallHabitCompletionRate: overallHabitRate,
      activitiesBySource: bySource,
      activitiesByCategory: byCategory,
      habitBreakdown: habitBreakdown,
      dailyTrends: dailyTrends,
    );
  }
}
