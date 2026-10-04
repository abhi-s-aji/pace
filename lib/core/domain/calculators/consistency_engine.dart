import '../models/models.dart';
import '../../utils/date_utils.dart';

/// Central Domain Consistency & Streak Engine.
/// Authoritative source of truth for:
/// - Current streak
/// - Best streak
/// - Active days count
/// - Weekly/Monthly consistency ratios
abstract class ConsistencyEngine {
  /// Calculates consistency stats given a list of DailySummary sorted by date ascending or descending
  static ConsistencyStats calculate(List<DailySummary> summaries, {DateTime? referenceDate}) {
    if (summaries.isEmpty) {
      return const ConsistencyStats();
    }

    final today = PaceDateUtils.normalizeDate(referenceDate ?? DateTime.now());
    
    // Map of date ISO string -> DailySummary
    final Map<String, DailySummary> summaryMap = {
      for (final s in summaries) s.date: s
    };

    // Helper to check if a day had meaningful activity
    bool hasActivity(DateTime date) {
      final iso = PaceDateUtils.toIsoDateString(date);
      final s = summaryMap[iso];
      if (s == null) return false;
      return s.habitsCompleted > 0 || s.totalActivities > 0 || s.totalFocusMinutes > 0;
    }

    // 1. Calculate Active Days & Total Logged
    int activeDays = 0;
    int totalActivities = 0;
    int totalFocusMins = 0;

    for (final s in summaries) {
      if (s.habitsCompleted > 0 || s.totalActivities > 0 || s.totalFocusMinutes > 0) {
        activeDays++;
      }
      totalActivities += s.totalActivities;
      totalFocusMins += s.totalFocusMinutes;
    }

    // 2. Calculate Current Streak
    int currentStreak = 0;
    DateTime checkDate = today;

    // If today has activity, count today and step backward.
    // If today does NOT have activity yet, check yesterday. If yesterday has activity, start from yesterday!
    if (!hasActivity(checkDate)) {
      final yesterday = checkDate.subtract(const Duration(days: 1));
      if (hasActivity(yesterday)) {
        checkDate = yesterday;
      } else {
        // Streak is 0 if neither today nor yesterday had activity
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    while (hasActivity(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // 3. Calculate Best Streak across all history
    int bestStreak = 0;
    int runningStreak = 0;

    // Find min date and max date in summaries
    final dates = summaryMap.keys.map(PaceDateUtils.parseIsoDateString).toList()..sort();
    if (dates.isNotEmpty) {
      final minDate = dates.first;
      final maxDate = dates.last.isAfter(today) ? today : dates.last;

      DateTime curr = minDate;
      while (!curr.isAfter(maxDate)) {
        if (hasActivity(curr)) {
          runningStreak++;
          if (runningStreak > bestStreak) {
            bestStreak = runningStreak;
          }
        } else {
          runningStreak = 0;
        }
        curr = curr.add(const Duration(days: 1));
      }
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    // 4. Calculate Weekly & Monthly consistency percentages (last 7 and last 30 days)
    int weeklyActive = 0;
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i));
      if (hasActivity(d)) weeklyActive++;
    }
    final weeklyCompletionPercentage = (weeklyActive / 7.0) * 100.0;

    int monthlyActive = 0;
    for (int i = 0; i < 30; i++) {
      final d = today.subtract(Duration(days: i));
      if (hasActivity(d)) monthlyActive++;
    }
    final monthlyCompletionPercentage = (monthlyActive / 30.0) * 100.0;

    return ConsistencyStats(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      activeDays: activeDays,
      totalActivitiesLogged: totalActivities,
      totalFocusMinutes: totalFocusMins,
      weeklyCompletionPercentage: weeklyCompletionPercentage,
      monthlyCompletionPercentage: monthlyCompletionPercentage,
      overallCompletionPercentage: (activeDays > 0 && summaries.isNotEmpty)
          ? (activeDays / summaries.length) * 100.0
          : 0.0,
    );
  }
}
