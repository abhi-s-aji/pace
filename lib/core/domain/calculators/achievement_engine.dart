import '../models/models.dart';
import '../../utils/date_utils.dart';

/// Authoritative Engine for Evaluating System-Derived Badges/Achievements.
/// All achievement evaluation is deterministic, idempotent, and based strictly on
/// domain data (HabitCompletions, Activities, FocusSessions, Goals, Milestones, DailySummaries, JournalEntries).
abstract class AchievementEngine {
  static List<Achievement> evaluateAchievements({
    required ConsistencyStats stats,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<Activity> activities,
    required List<FocusSession> focusSessions,
    required List<Goal> goals,
    required List<Milestone> milestones,
    required Map<String, DailySummary> dailySummaries,
    required List<JournalEntry> journalEntries,
    Map<String, String> existingEarnedMap = const {},
    DateTime? referenceDate}) {
    final nowIso = (referenceDate ?? DateTime.now()).toIso8601String();

    final activeHabitsCount = habits.where((h) => !h.isArchived).length;
    final totalCompletions = completions.where((c) => c.isCompleted).length;
    final totalActivitiesLogged = activities.length;
    final totalFocusMins = focusSessions.fold<int>(0, (sum, f) => sum + f.actualDurationMinutes);
    final focusHours = totalFocusMins / 60.0;
    final completedGoalsCount = goals.where((g) => g.isCompleted || g.calculatedProgress >= 1.0).length;
    final completedMilestonesCount = milestones.where((m) => m.isCompleted).length;
    final journalEntriesCount = journalEntries.length;

    Achievement buildAch({
      required String id,
      required String title,
      required String description,
      required String category,
      required String icon,
      required double targetValue,
      required double currentValue,
      required String unit,
      required bool conditionMet,
      required String activeEvidenceText}) {
      final wasEarnedAlready = existingEarnedMap.containsKey(id);
      final isEarnedNow = wasEarnedAlready || conditionMet;
      final earnedTime = wasEarnedAlready
          ? existingEarnedMap[id]!
          : (conditionMet ? nowIso : null);

      final val = isEarnedNow ? targetValue : currentValue.clamp(0.0, targetValue);
      final prog = targetValue > 0 ? (val / targetValue).clamp(0.0, 1.0) : 0.0;

      String evidence = activeEvidenceText;
      if (isEarnedNow && earnedTime != null) {
        final dt = DateTime.tryParse(earnedTime);
        if (dt != null) {
          evidence = 'Earned on ${PaceDateUtils.toIsoDateString(dt)}. $activeEvidenceText';
        }
      }

      return Achievement(
        id: id,
        title: title,
        description: description,
        category: category,
        icon: icon,
        isUnlocked: isEarnedNow,
        unlockedAt: earnedTime,
        progress: prog,
        currentValue: val,
        targetValue: targetValue,
        unit: unit,
        evidenceText: evidence,
      );
    }

    final List<Achievement> results = [];

    // --- 1. Getting Started ---
    results.add(buildAch(
      id: 'ach_first_step',
      title: 'First Step',
      description: 'Log your first activity or complete a scheduled habit.',
      category: 'Getting Started',
      icon: 'flag',
      targetValue: 1.0,
      currentValue: (totalActivitiesLogged + totalCompletions).toDouble(),
      unit: 'action',
      conditionMet: (totalActivitiesLogged + totalCompletions) >= 1 || stats.activeDays >= 1,
      activeEvidenceText: 'Based on ${totalActivitiesLogged + totalCompletions} total logged actions.',
    ));

    results.add(buildAch(
      id: 'ach_first_focus',
      title: 'First Focus Session',
      description: 'Complete your first intentional focus session.',
      category: 'Getting Started',
      icon: 'timer',
      targetValue: 1.0,
      currentValue: focusSessions.length.toDouble(),
      unit: 'session',
      conditionMet: focusSessions.isNotEmpty,
      activeEvidenceText: 'Based on ${focusSessions.length} focus sessions.',
    ));

    results.add(buildAch(
      id: 'ach_first_goal',
      title: 'First Goal Set',
      description: 'Define your first long-term goal in Pace.',
      category: 'Getting Started',
      icon: 'target',
      targetValue: 1.0,
      currentValue: goals.length.toDouble(),
      unit: 'goal',
      conditionMet: goals.isNotEmpty,
      activeEvidenceText: 'Based on ${goals.length} defined long-term goals.',
    ));

    results.add(buildAch(
      id: 'ach_first_journal',
      title: 'Reflection Beginner',
      description: 'Write your first daily reflection entry in Pace.',
      category: 'Getting Started',
      icon: 'book_open',
      targetValue: 1.0,
      currentValue: journalEntriesCount.toDouble(),
      unit: 'entry',
      conditionMet: journalEntriesCount >= 1,
      activeEvidenceText: 'Based on $journalEntriesCount reflection entries.',
    ));

    // --- 2. Consistency ---
    results.add(buildAch(
      id: 'ach_active_3',
      title: '3 Active Days',
      description: 'Record meaningful progress on 3 distinct days.',
      category: 'Consistency',
      icon: 'calendar',
      targetValue: 3.0,
      currentValue: stats.activeDays.toDouble(),
      unit: 'days',
      conditionMet: stats.activeDays >= 3,
      activeEvidenceText: 'Based on ${stats.activeDays} active days.',
    ));

    results.add(buildAch(
      id: 'ach_active_7',
      title: '7 Active Days',
      description: 'Record meaningful progress on 7 distinct days.',
      category: 'Consistency',
      icon: 'calendar',
      targetValue: 7.0,
      currentValue: stats.activeDays.toDouble(),
      unit: 'days',
      conditionMet: stats.activeDays >= 7,
      activeEvidenceText: 'Based on ${stats.activeDays} active days.',
    ));

    results.add(buildAch(
      id: 'ach_active_14',
      title: '14 Active Days',
      description: 'Record meaningful progress on 14 distinct days.',
      category: 'Consistency',
      icon: 'calendar_check',
      targetValue: 14.0,
      currentValue: stats.activeDays.toDouble(),
      unit: 'days',
      conditionMet: stats.activeDays >= 14,
      activeEvidenceText: 'Based on ${stats.activeDays} active days.',
    ));

    results.add(buildAch(
      id: 'ach_active_30',
      title: '30 Active Days',
      description: 'Record meaningful progress on 30 distinct days.',
      category: 'Consistency',
      icon: 'calendar_check',
      targetValue: 30.0,
      currentValue: stats.activeDays.toDouble(),
      unit: 'days',
      conditionMet: stats.activeDays >= 30,
      activeEvidenceText: 'Based on ${stats.activeDays} active days.',
    ));

    results.add(buildAch(
      id: 'ach_streak_3',
      title: 'Starting Spark',
      description: 'Maintain consistency for 3 consecutive days.',
      category: 'Consistency',
      icon: 'flame',
      targetValue: 3.0,
      currentValue: stats.bestStreak.toDouble(),
      unit: 'days',
      conditionMet: stats.bestStreak >= 3,
      activeEvidenceText: 'Based on a record streak of ${stats.bestStreak} days.',
    ));

    results.add(buildAch(
      id: 'ach_streak_7',
      title: 'Steady Pace',
      description: 'Maintain consistency for 7 consecutive days.',
      category: 'Consistency',
      icon: 'flame',
      targetValue: 7.0,
      currentValue: stats.bestStreak.toDouble(),
      unit: 'days',
      conditionMet: stats.bestStreak >= 7,
      activeEvidenceText: 'Based on a record streak of ${stats.bestStreak} days.',
    ));

    results.add(buildAch(
      id: 'ach_streak_14',
      title: 'Momentum Builder',
      description: 'Achieve a 14-day consistency streak.',
      category: 'Consistency',
      icon: 'shield_check',
      targetValue: 14.0,
      currentValue: stats.bestStreak.toDouble(),
      unit: 'days',
      conditionMet: stats.bestStreak >= 14,
      activeEvidenceText: 'Based on a record streak of ${stats.bestStreak} days.',
    ));

    results.add(buildAch(
      id: 'ach_streak_30',
      title: 'Fortitude',
      description: 'Achieve a 30-day consistency streak.',
      category: 'Consistency',
      icon: 'shield_check',
      targetValue: 30.0,
      currentValue: stats.bestStreak.toDouble(),
      unit: 'days',
      conditionMet: stats.bestStreak >= 30,
      activeEvidenceText: 'Based on a record streak of ${stats.bestStreak} days.',
    ));

    // --- 3. Habits ---
    results.add(buildAch(
      id: 'ach_habits_3',
      title: 'Routine Architect',
      description: 'Build a structured suite of 3 or more active habits.',
      category: 'Habits',
      icon: 'layout',
      targetValue: 3.0,
      currentValue: activeHabitsCount.toDouble(),
      unit: 'habits',
      conditionMet: activeHabitsCount >= 3,
      activeEvidenceText: 'Based on $activeHabitsCount active habits.',
    ));

    results.add(buildAch(
      id: 'ach_habits_5',
      title: 'Habit Beginner',
      description: 'Complete 5 scheduled habit occurrences.',
      category: 'Habits',
      icon: 'check_circle',
      targetValue: 5.0,
      currentValue: totalCompletions.toDouble(),
      unit: 'completions',
      conditionMet: totalCompletions >= 5,
      activeEvidenceText: 'Based on $totalCompletions habit completions.',
    ));

    results.add(buildAch(
      id: 'ach_habits_25',
      title: '25 Habit Completions',
      description: 'Complete 25 scheduled habit occurrences.',
      category: 'Habits',
      icon: 'check_circle',
      targetValue: 25.0,
      currentValue: totalCompletions.toDouble(),
      unit: 'completions',
      conditionMet: totalCompletions >= 25,
      activeEvidenceText: 'Based on $totalCompletions habit completions.',
    ));

    results.add(buildAch(
      id: 'ach_habits_50',
      title: '50 Habit Completions',
      description: 'Complete 50 scheduled habit occurrences.',
      category: 'Habits',
      icon: 'award',
      targetValue: 50.0,
      currentValue: totalCompletions.toDouble(),
      unit: 'completions',
      conditionMet: totalCompletions >= 50,
      activeEvidenceText: 'Based on $totalCompletions habit completions.',
    ));

    results.add(buildAch(
      id: 'ach_habits_100',
      title: '100 Habit Completions',
      description: 'Complete 100 scheduled habit occurrences.',
      category: 'Habits',
      icon: 'award',
      targetValue: 100.0,
      currentValue: totalCompletions.toDouble(),
      unit: 'completions',
      conditionMet: totalCompletions >= 100,
      activeEvidenceText: 'Based on $totalCompletions habit completions.',
    ));

    // --- 4. Focus ---
    results.add(buildAch(
      id: 'ach_focus_1_hour',
      title: '1 Hour Focus',
      description: 'Record 1 total hour (60 minutes) of focused time.',
      category: 'Focus',
      icon: 'clock',
      targetValue: 1.0,
      currentValue: focusHours,
      unit: 'hours',
      conditionMet: totalFocusMins >= 60,
      activeEvidenceText: 'Based on ${focusHours.toStringAsFixed(1)} hours across ${focusSessions.length} sessions.',
    ));

    results.add(buildAch(
      id: 'ach_focus_5_hours',
      title: '5 Hours Focus',
      description: 'Record 5 total hours (300 minutes) of focused time.',
      category: 'Focus',
      icon: 'clock',
      targetValue: 5.0,
      currentValue: focusHours,
      unit: 'hours',
      conditionMet: totalFocusMins >= 300,
      activeEvidenceText: 'Based on ${focusHours.toStringAsFixed(1)} hours across ${focusSessions.length} sessions.',
    ));

    results.add(buildAch(
      id: 'ach_focus_10_hours',
      title: '10 Hours Focus',
      description: 'Record 10 total hours (600 minutes) of focused time.',
      category: 'Focus',
      icon: 'zap',
      targetValue: 10.0,
      currentValue: focusHours,
      unit: 'hours',
      conditionMet: totalFocusMins >= 600,
      activeEvidenceText: 'Based on ${focusHours.toStringAsFixed(1)} hours across ${focusSessions.length} sessions.',
    ));

    results.add(buildAch(
      id: 'ach_focus_25_hours',
      title: '25 Hours Focus',
      description: 'Record 25 total hours (1,500 minutes) of focused time.',
      category: 'Focus',
      icon: 'zap',
      targetValue: 25.0,
      currentValue: focusHours,
      unit: 'hours',
      conditionMet: totalFocusMins >= 1500,
      activeEvidenceText: 'Based on ${focusHours.toStringAsFixed(1)} hours across ${focusSessions.length} sessions.',
    ));

    results.add(buildAch(
      id: 'ach_focus_50_hours',
      title: 'Deep Work Master',
      description: 'Record 50 total hours (3,000 minutes) of focused time.',
      category: 'Focus',
      icon: 'psychology',
      targetValue: 50.0,
      currentValue: focusHours,
      unit: 'hours',
      conditionMet: totalFocusMins >= 3000,
      activeEvidenceText: 'Based on ${focusHours.toStringAsFixed(1)} hours across ${focusSessions.length} sessions.',
    ));

    // --- 5. Goals & Milestones ---
    results.add(buildAch(
      id: 'ach_milestone_1',
      title: 'First Milestone',
      description: 'Complete a milestone on any long-term goal.',
      category: 'Goals',
      icon: 'check_square',
      targetValue: 1.0,
      currentValue: completedMilestonesCount.toDouble(),
      unit: 'milestones',
      conditionMet: completedMilestonesCount >= 1,
      activeEvidenceText: 'Based on $completedMilestonesCount completed milestones.',
    ));

    results.add(buildAch(
      id: 'ach_milestone_5',
      title: 'Milestone Master',
      description: 'Complete 5 milestones across long-term goals.',
      category: 'Goals',
      icon: 'check_square',
      targetValue: 5.0,
      currentValue: completedMilestonesCount.toDouble(),
      unit: 'milestones',
      conditionMet: completedMilestonesCount >= 5,
      activeEvidenceText: 'Based on $completedMilestonesCount completed milestones.',
    ));

    results.add(buildAch(
      id: 'ach_goal_1',
      title: 'Goal Reached',
      description: 'Fully achieve a long-term goal.',
      category: 'Goals',
      icon: 'trophy',
      targetValue: 1.0,
      currentValue: completedGoalsCount.toDouble(),
      unit: 'goals',
      conditionMet: completedGoalsCount >= 1,
      activeEvidenceText: 'Based on $completedGoalsCount achieved goals.',
    ));

    results.add(buildAch(
      id: 'ach_goal_3',
      title: 'Goal Master',
      description: 'Fully achieve 3 long-term goals.',
      category: 'Goals',
      icon: 'trophy',
      targetValue: 3.0,
      currentValue: completedGoalsCount.toDouble(),
      unit: 'goals',
      conditionMet: completedGoalsCount >= 3,
      activeEvidenceText: 'Based on $completedGoalsCount achieved goals.',
    ));

    // --- 6. History & Journal ---
    results.add(buildAch(
      id: 'ach_journal_5',
      title: 'Mirror of Reflection',
      description: 'Record 5 daily journal reflection entries.',
      category: 'History',
      icon: 'edit_note',
      targetValue: 5.0,
      currentValue: journalEntriesCount.toDouble(),
      unit: 'entries',
      conditionMet: journalEntriesCount >= 5,
      activeEvidenceText: 'Based on $journalEntriesCount reflection entries.',
    ));

    results.add(buildAch(
      id: 'ach_history_30',
      title: '30 Days Recorded',
      description: 'Accumulate 30 total recorded daily summaries in Pace.',
      category: 'History',
      icon: 'book_open',
      targetValue: 30.0,
      currentValue: dailySummaries.length.toDouble(),
      unit: 'summaries',
      conditionMet: dailySummaries.length >= 30,
      activeEvidenceText: 'Based on ${dailySummaries.length} recorded summaries.',
    ));

    results.add(buildAch(
      id: 'ach_activities_100',
      title: '100 Activities Logged',
      description: 'Log 100 total meaningful actions.',
      category: 'History',
      icon: 'timeline',
      targetValue: 100.0,
      currentValue: totalActivitiesLogged.toDouble(),
      unit: 'activities',
      conditionMet: totalActivitiesLogged >= 100,
      activeEvidenceText: 'Based on $totalActivitiesLogged logged activity records.',
    ));

    return results;
  }
}
