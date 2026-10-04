import 'package:flutter/foundation.dart';
import '../models/models.dart';

@immutable
class GoalProgressExplanation {
  final double progressPercentage;
  final double currentValue;
  final double targetValue;
  final String unit;
  final int habitCompletionsCount;
  final int focusSessionsCount;
  final int focusMinutes;
  final int completedMilestonesCount;
  final int totalMilestonesCount;
  final List<String> explanationBullets;

  const GoalProgressExplanation({
    required this.progressPercentage,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.habitCompletionsCount,
    required this.focusSessionsCount,
    required this.focusMinutes,
    required this.completedMilestonesCount,
    required this.totalMilestonesCount,
    required this.explanationBullets});
}

abstract class GoalEngine {
  /// Calculates overall goal progress percentage (0.0 to 1.0)
  static double calculateGoalProgress({
    required Goal goal,
    required List<GoalHabitLink> links,
    required List<HabitCompletion> completions,
    required List<Milestone> milestones,
    List<FocusSession> focusSessions = const [],
    List<Activity> activities = const []}) {
    final explanation = explainGoalProgress(
      goal: goal,
      links: links,
      completions: completions,
      milestones: milestones,
      focusSessions: focusSessions,
      activities: activities,
    );

    return (explanation.progressPercentage / 100.0).clamp(0.0, 1.0);
  }

  /// Calculates detailed progress metrics and human-understandable explanation
  static GoalProgressExplanation explainGoalProgress({
    required Goal goal,
    required List<GoalHabitLink> links,
    required List<HabitCompletion> completions,
    required List<Milestone> milestones,
    List<FocusSession> focusSessions = const [],
    List<Activity> activities = const []}) {
    final linkedHabitIds = links.map((l) => l.habitId).toSet();

    // 1. Filter relevant completions, focus, and activities for linked habits
    final relevantCompletions = completions.where((c) => c.isCompleted && linkedHabitIds.contains(c.habitId)).toList();
    final relevantFocus = focusSessions.where((f) => f.habitId != null && linkedHabitIds.contains(f.habitId)).toList();
    final relevantActivities = activities.where((a) => a.habitId != null && linkedHabitIds.contains(a.habitId)).toList();

    final habitCompletionsCount = relevantCompletions.length;
    final focusSessionsCount = relevantFocus.length;
    final totalFocusMins = relevantFocus.fold<int>(0, (sum, f) => sum + f.actualDurationMinutes);
    final completedMilestonesCount = milestones.where((m) => m.isCompleted).length;
    final totalMilestonesCount = milestones.length;

    final List<String> bullets = [];

    // --- Quantitative Calculation ---
    if (goal.targetValue > 0) {
      final unitLower = goal.targetUnit.toLowerCase().trim();
      double currentVal = 0.0;
      final targetVal = goal.targetValue;

      if (unitLower.contains('hour') || unitLower == 'h' || unitLower == 'hrs') {
        // Duration in hours: 1 focus minute = 1/60 hr
        final focusHours = totalFocusMins / 60.0;
        final actHours = relevantActivities.fold<double>(
          0.0,
          (sum, a) => sum + (a.durationMinutes / 60.0),
        );
        currentVal = focusHours + actHours;
        if (currentVal == 0 && habitCompletionsCount > 0) {
          // If binary habits linked to hourly target, count each completion as 1 hour equivalent
          currentVal = habitCompletionsCount.toDouble();
        }
      } else if (unitLower.contains('min') || unitLower == 'm') {
        currentVal = totalFocusMins.toDouble();
      } else {
        // Count/sessions/items
        final totalActions = habitCompletionsCount + focusSessionsCount + relevantActivities.where((a) => a.source == 'manual').length;
        currentVal = totalActions.toDouble();
      }

      final progressPct = ((currentVal / targetVal) * 100.0).clamp(0.0, 100.0);

      if (currentVal > 0) {
        bullets.add('${currentVal.toStringAsFixed(currentVal.truncateToDouble() == currentVal ? 0 : 1)} / ${targetVal.toStringAsFixed(targetVal.truncateToDouble() == targetVal ? 0 : 1)} ${goal.targetUnit} completed');
      }
      if (habitCompletionsCount > 0) {
        bullets.add('$habitCompletionsCount linked habit completions');
      }
      if (totalFocusMins > 0) {
        bullets.add('$focusSessionsCount focus sessions (${totalFocusMins}m focused)');
      }
      if (totalMilestonesCount > 0) {
        bullets.add('$completedMilestonesCount of $totalMilestonesCount milestones completed');
      }
      if (bullets.isEmpty) {
        bullets.add('No logged activity yet toward this target');
      }

      return GoalProgressExplanation(
        progressPercentage: progressPct,
        currentValue: currentVal,
        targetValue: targetVal,
        unit: goal.targetUnit,
        habitCompletionsCount: habitCompletionsCount,
        focusSessionsCount: focusSessionsCount,
        focusMinutes: totalFocusMins,
        completedMilestonesCount: completedMilestonesCount,
        totalMilestonesCount: totalMilestonesCount,
        explanationBullets: bullets,
      );
    }

    // --- Qualitative Calculation (Milestones + Linked Habits) ---
    if (links.isEmpty && milestones.isEmpty) {
      final isDone = goal.isCompleted;
      return GoalProgressExplanation(
        progressPercentage: isDone ? 100.0 : 0.0,
        currentValue: isDone ? 1.0 : 0.0,
        targetValue: 1.0,
        unit: '',
        habitCompletionsCount: 0,
        focusSessionsCount: 0,
        focusMinutes: 0,
        completedMilestonesCount: 0,
        totalMilestonesCount: 0,
        explanationBullets: [isDone ? 'Goal marked as complete' : 'Add linked habits or milestones to track progress'],
      );
    }

    double totalWeight = 0.0;
    double earnedWeight = 0.0;

    for (final link in links) {
      final habitComps = completions.where((c) => c.habitId == link.habitId && c.isCompleted).length;
      final habitFocus = focusSessions.where((f) => f.habitId == link.habitId).length;
      final habitActs = activities.where((a) => a.habitId == link.habitId && a.source != 'habit').length;

      final totalActions = habitComps + habitFocus + habitActs;
      final habitProgress = (totalActions / 20.0).clamp(0.0, 1.0);

      totalWeight += link.weight;
      earnedWeight += (habitProgress * link.weight);
    }

    if (totalMilestonesCount > 0) {
      const milestoneWeight = 1.0;
      final milestoneProgress = completedMilestonesCount / totalMilestonesCount;
      totalWeight += milestoneWeight;
      earnedWeight += (milestoneProgress * milestoneWeight);
    }

    final progressPct = totalWeight > 0.0 ? ((earnedWeight / totalWeight) * 100.0).clamp(0.0, 100.0) : 0.0;

    if (habitCompletionsCount > 0) {
      bullets.add('$habitCompletionsCount linked habit completions');
    }
    if (totalFocusMins > 0) {
      bullets.add('$focusSessionsCount focus sessions (${totalFocusMins}m focused)');
    }
    if (totalMilestonesCount > 0) {
      bullets.add('$completedMilestonesCount of $totalMilestonesCount milestones completed');
    }
    if (bullets.isEmpty) {
      bullets.add('No logged activity yet toward this goal');
    }

    return GoalProgressExplanation(
      progressPercentage: progressPct,
      currentValue: progressPct,
      targetValue: 100.0,
      unit: '%',
      habitCompletionsCount: habitCompletionsCount,
      focusSessionsCount: focusSessionsCount,
      focusMinutes: totalFocusMins,
      completedMilestonesCount: completedMilestonesCount,
      totalMilestonesCount: totalMilestonesCount,
      explanationBullets: bullets,
    );
  }
}
