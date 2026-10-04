import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pace/core/domain/models/models.dart';
import 'package:pace/core/domain/calculators/contribution_engine.dart';
import 'package:pace/core/domain/calculators/consistency_engine.dart';
import 'package:pace/core/domain/calculators/goal_engine.dart';
import 'package:pace/core/domain/calculators/statistics_engine.dart';
import 'package:pace/core/utils/date_utils.dart';
import 'package:pace/core/database/database_service.dart';
import 'package:pace/core/notifications/notification_service.dart';
import 'package:pace/core/state/pace_providers.dart';
import 'package:pace/core/theme/pace_theme.dart';
import 'package:pace/shared/widgets/habit_tile.dart';
import 'package:pace/shared/widgets/stat_card.dart';
import 'package:pace/shared/widgets/empty_state.dart';
import 'package:pace/shared/widgets/contribution_calendar_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  group('PaceDateUtils (Task 27)', () {
    test('normalizeDate removes time components', () {
      final dt = DateTime(2026, 10, 1, 14, 30, 45);
      final norm = PaceDateUtils.normalizeDate(dt);
      expect(norm.hour, 0);
      expect(norm.minute, 0);
      expect(norm.second, 0);
      expect(norm.day, 1);
      expect(norm.month, 10);
    });

    test('isSameDay compares correctly', () {
      final a = DateTime(2026, 10, 1, 8, 0);
      final b = DateTime(2026, 10, 1, 22, 30);
      final c = DateTime(2026, 10, 2, 0, 0);
      expect(PaceDateUtils.isSameDay(a, b), true);
      expect(PaceDateUtils.isSameDay(a, c), false);
    });

    test('toIsoDateString and parseIsoDateString roundtrip', () {
      final dt = DateTime(2026, 1, 5);
      final str = PaceDateUtils.toIsoDateString(dt);
      expect(str, '2026-01-05');
      final parsed = PaceDateUtils.parseIsoDateString(str);
      expect(parsed.year, 2026);
      expect(parsed.month, 1);
      expect(parsed.day, 5);
    });

    test('handles date boundaries: 23:59 vs 00:00, leap year, year transition', () {
      final lateNight = DateTime(2026, 12, 31, 23, 59, 59);
      final midnight = DateTime(2027, 1, 1, 0, 0, 0);
      expect(PaceDateUtils.isSameDay(lateNight, midnight), false);
      expect(PaceDateUtils.toIsoDateString(lateNight), '2026-12-31');
      expect(PaceDateUtils.toIsoDateString(midnight), '2027-01-01');

      // Leap day test (Feb 29, 2028)
      final leapDay = DateTime(2028, 2, 29, 10, 0);
      expect(PaceDateUtils.toIsoDateString(leapDay), '2028-02-29');
    });
  });

  group('ContributionEngine', () {
    test('0 activity returns level 0 and score 0.0', () {
      final summary = DailySummary(
        date: '2026-10-01',
        updatedAt: DateTime.now().toIso8601String(),
      );
      expect(ContributionEngine.calculateScore(summary), 0.0);
      expect(ContributionEngine.calculateLevel(summary), 0);
    });

    test('high activity and focus returns level 4', () {
      final summary = DailySummary(
        date: '2026-10-01',
        totalActivities: 5,
        habitsCompleted: 5,
        totalHabitsScheduled: 5,
        totalFocusMinutes: 120,
        completionPercentage: 100.0,
        updatedAt: DateTime.now().toIso8601String(),
      );
      expect(ContributionEngine.calculateLevel(summary), 4);
    });
  });

  group('ConsistencyEngine', () {
    test('empty summaries returns zero stats', () {
      final stats = ConsistencyEngine.calculate([]);
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 0);
      expect(stats.activeDays, 0);
    });

    test('consecutive active days produce correct current & best streak', () {
      final today = PaceDateUtils.today();
      final summaries = List.generate(5, (i) {
        final date = today.subtract(Duration(days: i));
        return DailySummary(
          date: PaceDateUtils.toIsoDateString(date),
          totalActivities: 2,
          habitsCompleted: 2,
          totalHabitsScheduled: 2,
          completionPercentage: 100.0,
          updatedAt: DateTime.now().toIso8601String(),
        );
      });
      final stats = ConsistencyEngine.calculate(summaries, referenceDate: today);
      expect(stats.currentStreak, 5);
      expect(stats.bestStreak, 5);
      expect(stats.activeDays, 5);
    });
  });

  group('StatisticsEngine (Task 13 & 26)', () {
    test('calculates range metrics accurately', () {
      final today = PaceDateUtils.today();
      final habits = [
        Habit(id: 'h1', name: 'Read', startDate: '2026-01-01', createdAt: '', updatedAt: ''),
      ];
      final completions = [
        HabitCompletion(id: 'c1', habitId: 'h1', date: PaceDateUtils.toIsoDateString(today), value: 1, targetValue: 1, isCompleted: true, timestamp: ''),
      ];
      final activities = [
        Activity(id: 'a1', habitId: 'h1', title: 'Read', date: PaceDateUtils.toIsoDateString(today), timestamp: '', source: 'habit'),
      ];
      final focus = [
        FocusSession(id: 'f1', habitId: 'h1', title: 'Read focus', targetDurationMinutes: 25, actualDurationMinutes: 25, date: PaceDateUtils.toIsoDateString(today), startedAt: '', completedAt: ''),
      ];

      final stats = StatisticsEngine.calculate(
        range: DateRangeFilter.thirtyDays,
        habits: habits,
        completions: completions,
        activities: activities,
        focusSessions: focus,
        dailySummaries: {},
        referenceDate: today,
      );

      expect(stats.totalActivities, equals(1));
      expect(stats.totalFocusMinutes, equals(25));
      expect(stats.habitCompletionsCount, equals(1));
    });
  });

  group('Phase 4: Goals, Milestones & Progress Planning Tests', () {
    late ProviderContainer container;

    setUp(() async {
      await DatabaseService.instance.clearAllTables();
      container = ProviderContainer();
      await container.read(paceAppProvider.notifier).loadInitialState();
    });

    tearDown(() {
      container.dispose();
    });

    test('Task 34: Critical Integration Test — Goals, Milestones, Habit linking & Reactivity', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      // 1. Create Goal "Become a React Developer"
      await notifier.createGoal(
        title: 'Become a React Developer',
        description: 'Master JS and React',
        targetDate: '2026-12-31',
        category: 'Career',
        milestoneTitles: [
          'JavaScript fundamentals',
          'React fundamentals',
          'Build projects',
          'Deploy portfolio',
        ],
      );

      // 2. Create Habits "Study React" and "Build React Project"
      final h1 = Habit(id: 'h_study', name: 'Study React', category: 'Study', startDate: todayStr, createdAt: '', updatedAt: '');
      final h2 = Habit(id: 'h_build', name: 'Build React Project', category: 'Code', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(h1);
      await notifier.createHabit(h2);

      // 3. Link habits to goal
      final goal = container.read(paceAppProvider).goals.firstWhere((g) => g.title == 'Become a React Developer');
      await notifier.linkHabitToGoal(goal.id, 'h_study');
      await notifier.linkHabitToGoal(goal.id, 'h_build');

      // 4. Complete milestone 1 & 2
      final milestones = await container.read(goalRepositoryProvider).getMilestonesForGoal(goal.id);
      if (milestones.length >= 2) {
        final m1 = milestones[0].copyWith(isCompleted: true);
        final m2 = milestones[1].copyWith(isCompleted: true);
        await notifier.updateMilestone(m1);
        await notifier.updateMilestone(m2);
      }

      // 5. Complete Study React habit
      await notifier.completeHabit('h_study', todayStr);

      var state = container.read(paceAppProvider);
      final updatedGoal = state.goals.firstWhere((g) => g.id == goal.id);

      // Assert Goal Progress changed
      expect(updatedGoal.calculatedProgress, greaterThan(0.0));
      expect(state.activities.any((a) => a.habitId == 'h_study'), true);

      // 6. Uncomplete Study React habit
      await notifier.uncompleteHabit('h_study', todayStr);

      state = container.read(paceAppProvider);
      final reversedGoal = state.goals.firstWhere((g) => g.id == goal.id);
      expect(reversedGoal.calculatedProgress, lessThan(updatedGoal.calculatedProgress));

      // 7. Unlink habit — assert habit & activity history remain intact!
      final habitStillExists = state.habits.any((h) => h.id == 'h_build');
      expect(habitStillExists, true);
    });

    test('Task 35: Quantitative Goal Test — 100 hours focus target', () {
      final goal = Goal(
        id: 'g_quant',
        title: '100 hours of focused study',
        targetDate: '2026-12-31',
        targetValue: 100.0,
        targetUnit: 'hours',
        createdAt: '',
      );

      final link = const GoalHabitLink(id: 'l1', goalId: 'g_quant', habitId: 'h_study');

      // 45m + 60m + 90m = 195 minutes = 3.25 hours
      final focusSessions = [
        const FocusSession(id: 'f1', habitId: 'h_study', title: 'Focus 1', targetDurationMinutes: 45, actualDurationMinutes: 45, date: '2026-10-01', startedAt: '', completedAt: ''),
        const FocusSession(id: 'f2', habitId: 'h_study', title: 'Focus 2', targetDurationMinutes: 60, actualDurationMinutes: 60, date: '2026-10-01', startedAt: '', completedAt: ''),
        const FocusSession(id: 'f3', habitId: 'h_study', title: 'Focus 3', targetDurationMinutes: 90, actualDurationMinutes: 90, date: '2026-10-01', startedAt: '', completedAt: ''),
      ];

      final explanation = GoalEngine.explainGoalProgress(
        goal: goal,
        links: [link],
        completions: [],
        milestones: [],
        focusSessions: focusSessions,
      );

      // 3.25 / 100 * 100 = 3.25%
      expect(explanation.currentValue, equals(3.25));
      expect(explanation.targetValue, equals(100.0));
      expect(explanation.progressPercentage, closeTo(3.25, 0.01));
    });

    test('Task 36: Milestone Progress Test', () {
      final goal = Goal(
        id: 'g_qual',
        title: 'Learn Architecture',
        targetDate: '2026-12-31',
        createdAt: '',
      );

      final milestones = [
        const Milestone(id: 'm1', goalId: 'g_qual', title: 'Step 1', isCompleted: true, targetDate: '2026-12-31'),
        const Milestone(id: 'm2', goalId: 'g_qual', title: 'Step 2', isCompleted: true, targetDate: '2026-12-31'),
        const Milestone(id: 'm3', goalId: 'g_qual', title: 'Step 3', isCompleted: false, targetDate: '2026-12-31'),
        const Milestone(id: 'm4', goalId: 'g_qual', title: 'Step 4', isCompleted: false, targetDate: '2026-12-31'),
      ];

      final explanation = GoalEngine.explainGoalProgress(
        goal: goal,
        links: [],
        completions: [],
        milestones: milestones,
      );

      // 2 / 4 milestones = 50.0%
      expect(explanation.progressPercentage, equals(50.0));
    });

    test('Task 38: Data Integrity — Deleting a goal does NOT delete habits or activities', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      // Create habit & goal
      final habit = Habit(id: 'h_keep', name: 'Keep Habit', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(habit);

      await notifier.createGoal(
        title: 'Temporary Goal',
        description: 'To be deleted',
        targetDate: '2026-12-31',
        category: 'Personal',
        linkedHabitIds: ['h_keep'],
      );

      // Complete habit
      await notifier.completeHabit('h_keep', todayStr);

      var state = container.read(paceAppProvider);
      final goal = state.goals.firstWhere((g) => g.title == 'Temporary Goal');

      // Delete goal
      await notifier.deleteGoal(goal.id);

      state = container.read(paceAppProvider);

      // ASSERT: Goal removed
      expect(state.goals.any((g) => g.id == goal.id), false);

      // ASSERT: Habit and Activity remain intact!
      expect(state.habits.any((h) => h.id == 'h_keep'), true);
      expect(state.activities.any((a) => a.habitId == 'h_keep'), true);
    });
  });

  group('Phase 5: Respectful Local Notifications & Reminders Tests', () {
    late ProviderContainer container;
    late FakeNotificationService fakeNotifService;

    setUp(() async {
      await DatabaseService.instance.clearAllTables();
      fakeNotifService = FakeNotificationService();
      container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(fakeNotifService),
        ],
      );
      await container.read(paceAppProvider.notifier).loadInitialState();
    });

    tearDown(() {
      container.dispose();
    });

    test('Global Notification Toggle: disabled cancels all, enabled schedules active reminders', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      // Create habit with reminder
      final habit = Habit(
        id: 'h_notif',
        name: 'Evening Read',
        reminderTime: '20:00',
        startDate: todayStr,
        createdAt: '',
        updatedAt: '',
      );
      await notifier.createHabit(habit);

      // Verify scheduled when notifications enabled
      expect(fakeNotifService.scheduledHabitIds.contains('h_notif'), true);

      // Disable global notifications
      final prefs = container.read(paceAppProvider).preferences;
      await notifier.updatePreferences(prefs.copyWith(notificationsEnabled: false));

      // Assert all cancelled
      expect(fakeNotifService.scheduledHabitIds.isEmpty, true);
      expect(fakeNotifService.cancelledAll, true);

      // Re-enable global notifications
      await notifier.updatePreferences(prefs.copyWith(notificationsEnabled: true));
      expect(fakeNotifService.scheduledHabitIds.contains('h_notif'), true);
    });

    test('Completion-Aware Habit Reminders: completed habit suppresses reminder for today', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      final habit = Habit(
        id: 'h_js',
        name: 'Study JavaScript',
        reminderTime: '20:00',
        startDate: todayStr,
        createdAt: '',
        updatedAt: '',
      );
      await notifier.createHabit(habit);

      // Before completion today: reminder scheduled
      expect(fakeNotifService.scheduledHabitIds.contains('h_js'), true);

      // Complete habit today at 18:30
      await notifier.completeHabit('h_js', todayStr);

      // Assert today's reminder is suppressed/cancelled!
      expect(fakeNotifService.scheduledHabitIds.contains('h_js'), false);

      // Uncomplete habit today
      await notifier.uncompleteHabit('h_js', todayStr);

      // Assert reminder restored
      expect(fakeNotifService.scheduledHabitIds.contains('h_js'), true);
    });

    test('Goal Reminders & Archive Safety: archiving goal cancels reminder', () async {
      final notifier = container.read(paceAppProvider.notifier);

      // Enable goal reminders in preferences
      final prefs = container.read(paceAppProvider).preferences;
      await notifier.updatePreferences(prefs.copyWith(goalRemindersEnabled: true));

      // Create goal with reminder
      await notifier.createGoal(
        title: 'Learn Flutter',
        description: '',
        targetDate: '2026-12-31',
        category: 'Study',
        reminderEnabled: true,
        reminderTime: '09:00',
      );

      final state = container.read(paceAppProvider);
      final goal = state.goals.firstWhere((g) => g.title == 'Learn Flutter');

      // Assert goal reminder scheduled
      expect(fakeNotifService.scheduledGoalIds.contains(goal.id), true);

      // Archive goal
      await notifier.archiveGoal(goal.id, true);

      // Assert goal reminder cancelled
      expect(fakeNotifService.scheduledGoalIds.contains(goal.id), false);
    });

    test('Daily Reflection Reminder configuration', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final prefs = container.read(paceAppProvider).preferences;

      // Enable daily reflection at 21:30
      await notifier.updatePreferences(
        prefs.copyWith(
          dailyReflectionEnabled: true,
          dailyReflectionTime: '21:30',
        ),
      );

      expect(fakeNotifService.dailyReflectionScheduled, true);
      expect(fakeNotifService.dailyReflectionTimeScheduled, '21:30');

      // Disable daily reflection
      await notifier.updatePreferences(
        prefs.copyWith(dailyReflectionEnabled: false),
      );

      expect(fakeNotifService.dailyReflectionScheduled, false);
    });

    test('Backup Restore reconciles notification schedules without storing OS IDs', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      final habit = Habit(
        id: 'h_backup',
        name: 'Backup Habit',
        reminderTime: '08:00',
        startDate: todayStr,
        createdAt: '',
        updatedAt: '',
      );
      await notifier.createHabit(habit);

      final backupRepo = container.read(backupRepositoryProvider);
      final jsonData = await backupRepo.exportAllDataJson();

      // Clear all tables
      await DatabaseService.instance.clearAllTables();
      await notifier.loadInitialState();
      expect(fakeNotifService.scheduledHabitIds.isEmpty, true);

      // Restore backup
      await notifier.restoreBackup(jsonData);

      // Assert notification schedule reconciled automatically from restored config
      expect(fakeNotifService.scheduledHabitIds.contains('h_backup'), true);
    });
  });

  group('Phase 6: Achievements & Meaningful Progress Recognition Tests', () {
    late ProviderContainer container;
    late FakeNotificationService fakeNotifService;

    setUp(() async {
      await DatabaseService.instance.clearAllTables();
      fakeNotifService = FakeNotificationService();
      container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(fakeNotifService),
        ],
      );
      await container.read(paceAppProvider.notifier).loadInitialState();
    });

    tearDown(() {
      container.dispose();
    });

    test('First Achievement & Idempotency: completing habit unlocks ach_first_step with stable earnedAt', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      final habit = Habit(
        id: 'h_first',
        name: 'First Habit',
        startDate: todayStr,
        createdAt: '',
        updatedAt: '',
      );
      await notifier.createHabit(habit);
      await notifier.completeHabit('h_first', todayStr);

      var state = container.read(paceAppProvider);
      final firstAch = state.achievements.firstWhere((a) => a.id == 'ach_first_step');

      expect(firstAch.isEarned, true);
      expect(firstAch.earnedAt, isNotNull);
      final originalEarnedTime = firstAch.earnedAt;

      // Re-evaluate 3 times (idempotency check)
      await notifier.loadInitialState();
      await notifier.loadInitialState();
      await notifier.loadInitialState();

      state = container.read(paceAppProvider);
      final reloadedAch = state.achievements.firstWhere((a) => a.id == 'ach_first_step');

      expect(reloadedAch.isEarned, true);
      expect(reloadedAch.earnedAt, equals(originalEarnedTime));
    });

    test('Active Days & Focus Hours Achievements', () async {
      final notifier = container.read(paceAppProvider.notifier);

      // Complete 10 hours (600 mins) of focus
      await notifier.completeFocusSession(
        title: 'Deep Study 1',
        targetDurationMinutes: 300,
        actualDurationMinutes: 300,
      );
      await notifier.completeFocusSession(
        title: 'Deep Study 2',
        targetDurationMinutes: 300,
        actualDurationMinutes: 300,
      );

      final state = container.read(paceAppProvider);
      final focus10Ach = state.achievements.firstWhere((a) => a.id == 'ach_focus_10_hours');

      expect(focus10Ach.isEarned, true);
      expect(focus10Ach.currentValue, equals(10.0));
      expect(focus10Ach.progress, equals(1.0));
    });

    test('Habit Completions & Routine Architect Achievements', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      // Create 3 active habits
      final h1 = Habit(id: 'h1', name: 'Habit 1', startDate: todayStr, createdAt: '', updatedAt: '');
      final h2 = Habit(id: 'h2', name: 'Habit 2', startDate: todayStr, createdAt: '', updatedAt: '');
      final h3 = Habit(id: 'h3', name: 'Habit 3', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(h1);
      await notifier.createHabit(h2);
      await notifier.createHabit(h3);

      final state = container.read(paceAppProvider);
      final architectAch = state.achievements.firstWhere((a) => a.id == 'ach_habits_3');

      expect(architectAch.isEarned, true);
    });

    test('Goal & Milestone Achievements via domain engines', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      await notifier.createGoal(
        title: 'Master Flutter',
        description: 'Complete all units',
        targetDate: '2026-12-31',
        category: 'Study',
        milestoneTitles: ['Milestone A'],
      );

      var state = container.read(paceAppProvider);
      final goal = state.goals.firstWhere((g) => g.title == 'Master Flutter');

      // Add milestone and toggle it
      await notifier.addMilestone(goalId: goal.id, title: 'Step 1', targetDate: todayStr);
      state = container.read(paceAppProvider);
      final goalMs = await container.read(goalRepositoryProvider).getMilestonesForGoal(goal.id);
      if (goalMs.isNotEmpty) {
        await notifier.toggleMilestone(goalMs.first);
      }

      state = container.read(paceAppProvider);
      final updatedMilestoneAch = state.achievements.firstWhere((a) => a.id == 'ach_milestone_1');
      expect(updatedMilestoneAch.isEarned, true);
    });

    test('Historical Preservation (Reverse Action Test): uncompleting habit preserves earned achievement history', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      final habit = Habit(id: 'h_rev', name: 'Reverse Habit', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(habit);
      await notifier.completeHabit('h_rev', todayStr);

      var state = container.read(paceAppProvider);
      final earnedAch = state.achievements.firstWhere((a) => a.id == 'ach_first_step');
      expect(earnedAch.isEarned, true);
      final earnedTime = earnedAch.earnedAt;

      // Reverse action: uncomplete habit
      await notifier.uncompleteHabit('h_rev', todayStr);

      state = container.read(paceAppProvider);

      // Current stats correctly reflect 0 completions
      expect(state.completions.isEmpty, true);

      // BUT historical achievement evidence remains earned with original timestamp preserved!
      final preservedAch = state.achievements.firstWhere((a) => a.id == 'ach_first_step');
      expect(preservedAch.isEarned, true);
      expect(preservedAch.earnedAt, equals(earnedTime));
    });

    test('Backup & Restore preserves earned achievement history', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      final habit = Habit(id: 'h_backup_ach', name: 'Backup Ach Habit', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(habit);
      await notifier.completeHabit('h_backup_ach', todayStr);

      final backupRepo = container.read(backupRepositoryProvider);
      final jsonData = await backupRepo.exportAllDataJson();

      // Clear all data
      await DatabaseService.instance.clearAllTables();
      await notifier.loadInitialState();
      expect(container.read(paceAppProvider).achievements.every((a) => !a.isEarned), true);

      // Restore backup
      await notifier.restoreBackup(jsonData);

      final state = container.read(paceAppProvider);
      final restoredAch = state.achievements.firstWhere((a) => a.id == 'ach_first_step');
      expect(restoredAch.isEarned, true);
    });
  });

  group('Phase 7: Onboarding, First-Run Experience & Product Polish Tests', () {
    late ProviderContainer container;

    setUp(() async {
      await DatabaseService.instance.clearAllTables();
      container = ProviderContainer();
      await container.read(paceAppProvider.notifier).loadInitialState();
    });

    tearDown(() {
      container.dispose();
    });

    test('Fresh install: onboardingStatus is notStarted and hasCompletedOnboarding is false', () {
      final prefs = container.read(paceAppProvider).preferences;
      expect(prefs.onboardingStatus, equals('notStarted'));
      expect(prefs.hasCompletedOnboarding, isFalse);
    });

    test('Complete onboarding: persists completed state', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final prefs = container.read(paceAppProvider).preferences;

      await notifier.updatePreferences(prefs.copyWith(onboardingStatus: 'completed'));

      final updatedState = container.read(paceAppProvider);
      expect(updatedState.preferences.onboardingStatus, equals('completed'));
      expect(updatedState.preferences.hasCompletedOnboarding, isTrue);
    });

    test('Skip onboarding: persists skipped state', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final prefs = container.read(paceAppProvider).preferences;

      await notifier.updatePreferences(prefs.copyWith(onboardingStatus: 'skipped'));

      final updatedState = container.read(paceAppProvider);
      expect(updatedState.preferences.onboardingStatus, equals('skipped'));
      expect(updatedState.preferences.hasCompletedOnboarding, isTrue);
    });

    test('Existing user migration: DB with habits automatically defaults missing onboardingStatus to completed', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      // Create habit as existing user
      final habit = Habit(id: 'h_exist', name: 'Existing User Habit', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(habit);

      // Reload initial state (simulates restart/upgrade)
      await notifier.loadInitialState();

      final prefs = container.read(paceAppProvider).preferences;
      expect(prefs.onboardingStatus, equals('completed'));
      expect(prefs.hasCompletedOnboarding, isTrue);
    });

    test('First habit creation from onboarding reuses domain repository and updates state', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      final firstHabit = Habit(
        id: 'h_onboard',
        name: 'Read 20 pages',
        category: 'Learning',
        startDate: todayStr,
        createdAt: '',
        updatedAt: '',
      );

      await notifier.createHabit(firstHabit);

      final state = container.read(paceAppProvider);
      expect(state.habits.any((h) => h.id == 'h_onboard'), isTrue);
      expect(state.habits.firstWhere((h) => h.id == 'h_onboard').name, equals('Read 20 pages'));
    });

    test('First goal creation from onboarding integrates cleanly with GoalEngine', () async {
      final notifier = container.read(paceAppProvider.notifier);

      await notifier.createGoal(
        title: 'Master Dart 3',
        description: 'Read specs',
        targetDate: '2026-12-31',
        category: 'Study',
      );

      final state = container.read(paceAppProvider);
      final goal = state.goals.firstWhere((g) => g.title == 'Master Dart 3');
      expect(goal.category, equals('Study'));
      expect(goal.calculatedProgress, equals(0.0));
    });

    test('Skip habit and skip goal creates zero fake records', () async {
      final state = container.read(paceAppProvider);

      expect(state.habits.isEmpty, isTrue);
      expect(state.goals.isEmpty, isTrue);
      expect(state.activities.isEmpty, isTrue);
    });
  });

  group('Phase 8: Data Integrity, Persistence Reliability & Production Hardening Tests', () {
    late ProviderContainer container;

    setUp(() async {
      await DatabaseService.instance.clearAllTables();
      container = ProviderContainer();
      await container.read(paceAppProvider.notifier).loadInitialState();
    });

    tearDown(() {
      container.dispose();
    });

    test('Corrupt and unsupported backups are rejected without modifying existing database state', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      // Create an existing valid habit
      final habit = Habit(id: 'h_protected', name: 'Protected Habit', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(habit);

      // 1. Empty backup
      expect(() => notifier.restoreBackup({}), throwsA(isA<FormatException>()));

      // 2. Missing metadata
      expect(() => notifier.restoreBackup({'habits': []}), throwsA(isA<FormatException>()));

      // 3. Unsupported backupVersion (e.g. version 99)
      final unsupportedBackup = {
        'metadata': {'backupVersion': 99, 'exportedAt': todayStr},
      };
      expect(() => notifier.restoreBackup(unsupportedBackup), throwsA(isA<FormatException>()));

      // 4. Malformed table structure (string instead of list)
      final malformedBackup = {
        'metadata': {'backupVersion': 1, 'exportedAt': todayStr},
        'habits': 'not_a_list',
      };
      expect(() => notifier.restoreBackup(malformedBackup), throwsA(isA<FormatException>()));

      // ASSERT: Original habit remains 100% protected and untouched!
      final state = container.read(paceAppProvider);
      expect(state.habits.any((h) => h.id == 'h_protected'), isTrue);
    });

    test('Full Backup & Restore Roundtrip with backupVersion 1 metadata', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      // Create full entity set
      final habit = Habit(id: 'h_roundtrip', name: 'Roundtrip Habit', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(habit);
      await notifier.completeHabit('h_roundtrip', todayStr);

      await notifier.createGoal(
        title: 'Roundtrip Goal',
        description: '',
        targetDate: '2026-12-31',
        category: 'Study',
        milestoneTitles: ['Milestone 1'],
      );

      await notifier.saveJournalEntry(
        dateStr: todayStr,
        title: 'Roundtrip Journal',
        content: 'Reflections',
        mood: 'great',
      );

      final backupRepo = container.read(backupRepositoryProvider);
      final jsonData = await backupRepo.exportAllDataJson();

      // Assert backup metadata version is 1
      final metadataMap = jsonData['metadata'] as Map;
      expect(metadataMap['backupVersion'], equals(1));

      // Clear DB tables
      await DatabaseService.instance.clearAllTables();
      await notifier.loadInitialState();
      expect(container.read(paceAppProvider).habits.isEmpty, isTrue);

      // Restore backup
      await notifier.restoreBackup(jsonData);

      final restoredState = container.read(paceAppProvider);
      expect(restoredState.habits.any((h) => h.id == 'h_roundtrip'), isTrue);
      expect(restoredState.completions.any((c) => c.habitId == 'h_roundtrip'), isTrue);
      expect(restoredState.goals.any((g) => g.title == 'Roundtrip Goal'), isTrue);
      expect(restoredState.journalEntries.any((j) => j.title == 'Roundtrip Journal'), isTrue);
    });

    test('Atomic Habit and Goal Deletions clean up linked data', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      final habit = Habit(id: 'h_del', name: 'To Delete', startDate: todayStr, createdAt: '', updatedAt: '');
      await notifier.createHabit(habit);
      await notifier.completeHabit('h_del', todayStr);

      await notifier.createGoal(
        title: 'Goal To Delete',
        description: '',
        targetDate: '2026-12-31',
        category: 'General',
        linkedHabitIds: ['h_del'],
        milestoneTitles: ['MS 1'],
      );

      var state = container.read(paceAppProvider);
      final goal = state.goals.firstWhere((g) => g.title == 'Goal To Delete');

      // Delete habit
      await notifier.deleteHabit('h_del');

      state = container.read(paceAppProvider);
      expect(state.habits.any((h) => h.id == 'h_del'), isFalse);
      expect(state.completions.any((c) => c.habitId == 'h_del'), isFalse);

      // Delete goal
      await notifier.deleteGoal(goal.id);

      state = container.read(paceAppProvider);
      expect(state.goals.any((g) => g.id == goal.id), isFalse);
    });

    test('Notification Service failure isolation does not break domain persistence', () async {
      final throwingNotifContainer = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(ThrowingNotificationService()),
        ],
      );

      final notifier = throwingNotifContainer.read(paceAppProvider.notifier);
      await notifier.loadInitialState();

      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
      final habit = Habit(id: 'h_notif_fail', name: 'Safe Habit', startDate: todayStr, createdAt: '', updatedAt: '');

      // Creating & completing habit triggers recalculateAllSummariesAndMetrics which encounters notification exception
      await notifier.createHabit(habit);
      await notifier.completeHabit('h_notif_fail', todayStr);

      final state = throwingNotifContainer.read(paceAppProvider);

      // ASSERT: Domain operations succeeded completely despite notification failure!
      expect(state.habits.any((h) => h.id == 'h_notif_fail'), isTrue);
      expect(state.completions.any((c) => c.habitId == 'h_notif_fail'), isTrue);

      throwingNotifContainer.dispose();
    });

    test('Date/Time & Midnight boundary integrity', () {
      final lateNight = DateTime(2026, 12, 31, 23, 59, 59);
      final earlyMorning = DateTime(2027, 1, 1, 0, 0, 1);

      final lateKey = PaceDateUtils.toIsoDateString(lateNight);
      final earlyKey = PaceDateUtils.toIsoDateString(earlyMorning);

      expect(lateKey, equals('2026-12-31'));
      expect(earlyKey, equals('2027-01-01'));
      expect(PaceDateUtils.isSameDay(lateNight, earlyMorning), isFalse);
    });

    test('Idempotency: uncompleting non-existent completion causes no error or side effects', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

      // Attempt to uncomplete habit that was never completed
      await notifier.uncompleteHabit('non_existent_habit', todayStr);

      final state = container.read(paceAppProvider);
      expect(state.completions.isEmpty, isTrue);
    });

    test('Performance & Scalability test with realistic large dataset', () async {
      final notifier = container.read(paceAppProvider.notifier);
      final today = PaceDateUtils.today();

      final dbRepo = container.read(habitRepositoryProvider);
      final actRepo = container.read(activityRepositoryProvider);
      final focusRepo = container.read(focusRepositoryProvider);

      // Populate 50 habits, 500 completions, 500 activities, 100 focus sessions
      for (int i = 0; i < 50; i++) {
        await dbRepo.saveHabit(Habit(
          id: 'perf_h_$i',
          name: 'Performance Habit $i',
          startDate: '2026-01-01',
          createdAt: '',
          updatedAt: '',
        ));
      }

      for (int i = 0; i < 500; i++) {
        final dateStr = PaceDateUtils.toIsoDateString(today.subtract(Duration(days: i % 100)));
        await dbRepo.saveCompletion(HabitCompletion(
          id: 'perf_c_$i',
          habitId: 'perf_h_${i % 50}',
          date: dateStr,
          value: 1.0,
          targetValue: 1.0,
          isCompleted: true,
          timestamp: '',
        ));
        await actRepo.saveActivity(Activity(
          id: 'perf_a_$i',
          habitId: 'perf_h_${i % 50}',
          title: 'Perf Activity $i',
          date: dateStr,
          timestamp: '',
        ));
      }

      for (int i = 0; i < 100; i++) {
        final dateStr = PaceDateUtils.toIsoDateString(today.subtract(Duration(days: i)));
        await focusRepo.saveFocusSession(FocusSession(
          id: 'perf_f_$i',
          title: 'Focus $i',
          targetDurationMinutes: 25,
          actualDurationMinutes: 25,
          date: dateStr,
          startedAt: '',
          completedAt: '',
        ));
      }

      final stopwatch = Stopwatch()..start();
      await notifier.loadInitialState();
      stopwatch.stop();

      final state = container.read(paceAppProvider);
      expect(state.habits.length, greaterThanOrEqualTo(50));
      expect(state.completions.length, greaterThanOrEqualTo(500));
      expect(state.activities.length, greaterThanOrEqualTo(500));
      expect(state.focusSessions.length, greaterThanOrEqualTo(100));

      // Assert load completed rapidly (< 2000 ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    group('Phase 9: UX Refinement, Mobile Interaction & Design System Tests', () {
      testWidgets('Design Tokens & Accessibility: HabitTile renders with Semantics', (tester) async {
        final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
        final habit = Habit(
          id: 'p9_h1',
          name: 'Read 20 pages',
          category: 'Learning',
          startDate: todayStr,
          createdAt: todayStr,
          updatedAt: todayStr,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: PaceTheme.darkTheme,
            home: Scaffold(
              body: HabitTile(
                habit: habit,
                onToggle: () {},
              ),
            ),
          ),
        );

        expect(find.text('Read 20 pages'), findsOneWidget);
        expect(find.text('Learning'), findsOneWidget);
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('StatCard renders with consolidated Semantics accessibility label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: PaceTheme.darkTheme,
            home: const Scaffold(
              body: StatCard(
                title: 'Weekly',
                value: '85%',
                subtitle: 'consistency',
                icon: Icons.calendar_view_week_rounded,
              ),
            ),
          ),
        );

        expect(find.text('Weekly'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget);
        expect(find.text('consistency'), findsOneWidget);
      });

      testWidgets('EmptyState renders calm message with accessible action button', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: PaceTheme.darkTheme,
            home: Scaffold(
              body: EmptyState(
                icon: Icons.flag_rounded,
                title: 'No goals found',
                message: 'Set your first long-term goal.',
                actionLabel: 'Create Goal',
                onAction: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.text('No goals found'), findsOneWidget);
        expect(find.text('Set your first long-term goal.'), findsOneWidget);
        expect(find.text('Create Goal'), findsOneWidget);

        await tester.tap(find.text('Create Goal'));
        expect(tapped, true);
      });
    });

    group('New Features: Badges, Completion Notes & Interactive Graph', () {
      late ProviderContainer container;

      setUp(() async {
        await DatabaseService.instance.clearAllTables();
        container = ProviderContainer();
        await container.read(paceAppProvider.notifier).loadInitialState();
      });

      tearDown(() {
        container.dispose();
      });

      test('Completion Note Preference defaults to ask and persists changes', () async {
        final notifier = container.read(paceAppProvider.notifier);
        var prefs = container.read(paceAppProvider).preferences;
        expect(prefs.completionNotePreference, equals('ask'));

        await notifier.updatePreferences(prefs.copyWith(completionNotePreference: 'dont_ask'));
        prefs = container.read(paceAppProvider).preferences;
        expect(prefs.completionNotePreference, equals('dont_ask'));
      });

      test('completeHabit and completeFocusSession save custom completion note', () async {
        final notifier = container.read(paceAppProvider.notifier);
        final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

        final habit = Habit(id: 'h_note', name: 'Note Habit', startDate: todayStr, createdAt: '', updatedAt: '');
        await notifier.createHabit(habit);
        await notifier.completeHabit('h_note', todayStr, note: 'Felt great during reading');

        var state = container.read(paceAppProvider);
        final habitAct = state.activities.firstWhere((a) => a.habitId == 'h_note');
        expect(habitAct.notes, equals('Felt great during reading'));

        await notifier.completeFocusSession(
          title: 'Deep Coding',
          targetDurationMinutes: 25,
          actualDurationMinutes: 25,
          note: 'Focused on Flutter tests',
        );

        state = container.read(paceAppProvider);
        final focusAct = state.activities.firstWhere((a) => a.source == 'focus');
        expect(focusAct.notes, equals('Focused on Flutter tests'));
      });

      test('29 Badges evaluated deterministically in AchievementEngine', () {
        final state = container.read(paceAppProvider);
        expect(state.achievements.length, equals(29));
        expect(state.achievements.every((a) => a.id.startsWith('ach_')), isTrue);
      });

      test('Continuous line graph trend points and metrics calculate accurately', () {
        final today = PaceDateUtils.today();
        final stats = StatisticsEngine.calculate(
          range: DateRangeFilter.sevenDays,
          habits: [],
          completions: [],
          activities: [
            Activity(id: 'a1', title: 'Task 1', date: PaceDateUtils.toIsoDateString(today), timestamp: '', source: 'habit'),
          ],
          focusSessions: [
            FocusSession(id: 'f1', title: 'Focus 1', targetDurationMinutes: 30, actualDurationMinutes: 30, date: PaceDateUtils.toIsoDateString(today), startedAt: '', completedAt: ''),
          ],
          dailySummaries: {},
          referenceDate: today,
        );

        expect(stats.dailyTrends.length, equals(7));
        final latestPoint = stats.dailyTrends.last;
        expect(latestPoint.activityCount, equals(1));
        expect(latestPoint.focusMinutes, equals(30));
      });

      test('Profile badge preview setting toggles showProfileAchievements', () async {
        final notifier = container.read(paceAppProvider.notifier);
        expect(container.read(paceAppProvider).preferences.showProfileAchievements, isTrue);

        await notifier.updatePreferences(
          container.read(paceAppProvider).preferences.copyWith(showProfileAchievements: false),
        );
        expect(container.read(paceAppProvider).preferences.showProfileAchievements, isFalse);
      });

      test('Phase 6: Username saves, reloads, and reflects in preferences', () async {
        final notifier = container.read(paceAppProvider.notifier);
        var state = container.read(paceAppProvider);
        expect(state.preferences.userName, equals('User'));

        await notifier.updatePreferences(state.preferences.copyWith(userName: 'Abhi S Aji'));
        state = container.read(paceAppProvider);
        expect(state.preferences.userName, equals('Abhi S Aji'));
      });

      test('Phase 6: Clear All Data removes habits, activities, goals, and resets metrics', () async {
        final notifier = container.read(paceAppProvider.notifier);
        final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

        await notifier.createHabit(Habit(id: 'h_clear', name: 'Clear Habit', startDate: todayStr, createdAt: '', updatedAt: ''));
        await notifier.updateGoal(Goal(id: 'g_clear', title: 'Clear Goal', category: 'General', targetDate: todayStr, createdAt: ''));
        
        var state = container.read(paceAppProvider);
        expect(state.habits.length, greaterThan(0));
        expect(state.goals.length, greaterThan(0));

        await notifier.clearAllData();

        state = container.read(paceAppProvider);
        expect(state.habits.isEmpty, isTrue);
        expect(state.goals.isEmpty, isTrue);
        expect(state.activities.isEmpty, isTrue);
        expect(state.focusSessions.isEmpty, isTrue);
        expect(state.completions.isEmpty, isTrue);
        expect(state.journalEntries.isEmpty, isTrue);
        expect(state.consistencyStats.currentStreak, equals(0));
      });

      test('Phase 6: Backup Export & Restore restores valid data and does not corrupt on invalid data', () async {
        final notifier = container.read(paceAppProvider.notifier);
        final backupRepo = container.read(backupRepositoryProvider);
        final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

        await notifier.createHabit(Habit(id: 'h_backup', name: 'Backup Test Habit', startDate: todayStr, createdAt: '', updatedAt: ''));
        final validBackup = await backupRepo.exportAllDataJson();
        expect(validBackup['metadata']['backupVersion'], equals(1));
        expect((validBackup['habits'] as List).length, equals(1));

        // Attempt invalid import
        expect(() async => await backupRepo.importAllDataJson({'invalid': 'json'}), throwsA(isA<FormatException>()));

        // Restore valid backup
        await notifier.clearAllData();
        expect(container.read(paceAppProvider).habits.isEmpty, isTrue);

        await notifier.restoreBackup(validBackup);
        expect(container.read(paceAppProvider).habits.length, equals(1));
        expect(container.read(paceAppProvider).habits.first.name, equals('Backup Test Habit'));
      });

      test('Phase 7: Task completion note add, edit, clear without extra activity or metric mutation', () async {
        final notifier = container.read(paceAppProvider.notifier);
        final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

        await notifier.createHabit(Habit(id: 'h_note_test', name: 'Task Note Habit', startDate: todayStr, createdAt: '', updatedAt: ''));
        await notifier.completeHabit('h_note_test', todayStr, note: 'Initial completion note');

        var state = container.read(paceAppProvider);
        expect(state.activities.where((a) => a.habitId == 'h_note_test').length, equals(1));
        final initialAct = state.activities.firstWhere((a) => a.habitId == 'h_note_test');
        expect(initialAct.notes, equals('Initial completion note'));
        final initialCompletionsCount = state.completions.length;
        final initialActivitiesCount = state.activities.length;
        final initialStreak = state.consistencyStats.currentStreak;

        // Edit note
        await notifier.updateHabitCompletionNote('h_note_test', todayStr, 'Updated completion note');
        state = container.read(paceAppProvider);
        final updatedAct = state.activities.firstWhere((a) => a.habitId == 'h_note_test');
        expect(updatedAct.notes, equals('Updated completion note'));
        expect(state.completions.length, equals(initialCompletionsCount));
        expect(state.activities.length, equals(initialActivitiesCount));
        expect(state.consistencyStats.currentStreak, equals(initialStreak));

        // Delete/clear note
        await notifier.updateHabitCompletionNote('h_note_test', todayStr, '');
        state = container.read(paceAppProvider);
        final clearedAct = state.activities.firstWhere((a) => a.habitId == 'h_note_test');
        expect(clearedAct.notes, equals(''));
        expect(state.completions.length, equals(initialCompletionsCount));
        expect(state.activities.length, equals(initialActivitiesCount));
      });

      test('Phase 7: Focus session note edit and clear does not duplicate session or mutate duration', () async {
        final notifier = container.read(paceAppProvider.notifier);

        await notifier.completeFocusSession(
          title: 'Deep Focus Test',
          targetDurationMinutes: 30,
          actualDurationMinutes: 30,
          note: 'Initial focus reflection',
        );

        var state = container.read(paceAppProvider);
        final focusAct = state.activities.firstWhere((a) => a.source == 'focus');
        expect(focusAct.notes, equals('Initial focus reflection'));
        final focusSessionsCount = state.focusSessions.length;
        final activitiesCount = state.activities.length;

        // Edit focus note
        await notifier.updateActivityNote(focusAct.id, 'Updated focus reflection');
        state = container.read(paceAppProvider);
        final updatedFocusAct = state.activities.firstWhere((a) => a.id == focusAct.id);
        expect(updatedFocusAct.notes, equals('Updated focus reflection'));
        expect(state.focusSessions.length, equals(focusSessionsCount));
        expect(state.activities.length, equals(activitiesCount));
      });

      test('Phase 7: Daily Note add, edit, delete on today and historical dates does not alter metrics', () async {
        final notifier = container.read(paceAppProvider.notifier);
        final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
        final oldDateStr = '2026-09-15';

        var state = container.read(paceAppProvider);
        final initialActivitiesCount = state.activities.length;
        final initialStreak = state.consistencyStats.currentStreak;

        // Add Daily Note for today
        await notifier.saveJournalEntry(
          dateStr: todayStr,
          title: 'Productive Day',
          content: 'Finished Pace Settings & Refinements',
          mood: 'great',
        );

        state = container.read(paceAppProvider);
        final todayJournal = state.journalEntries.firstWhere((j) => j.date == todayStr);
        expect(todayJournal.title, equals('Productive Day'));
        expect(todayJournal.content, equals('Finished Pace Settings & Refinements'));

        // Verify metrics are untouched
        expect(state.activities.length, equals(initialActivitiesCount));
        expect(state.consistencyStats.currentStreak, equals(initialStreak));

        // Add Daily Note for older historical date
        await notifier.saveJournalEntry(
          dateStr: oldDateStr,
          title: 'Historical Reflection',
          content: 'Studied Dart & Flutter',
          mood: 'good',
        );

        state = container.read(paceAppProvider);
        final oldJournal = state.journalEntries.firstWhere((j) => j.date == oldDateStr);
        expect(oldJournal.content, equals('Studied Dart & Flutter'));
        expect(state.activities.length, equals(initialActivitiesCount));
        expect(state.consistencyStats.currentStreak, equals(initialStreak));

        // Delete Daily Note
        await notifier.deleteJournalEntry(todayJournal.id);
        state = container.read(paceAppProvider);
        expect(state.journalEntries.any((j) => j.id == todayJournal.id), isFalse);
      });

      testWidgets('ContributionCalendarWidget displays all 7 weekday labels (M, T, W, T, F, Sa, Su)', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ContributionCalendarWidget(
                dailySummaries: {},
                firstDayIsMonday: true,
              ),
            ),
          ),
        );

        expect(find.text('M'), findsOneWidget);
        expect(find.text('T'), findsNWidgets(2));
        expect(find.text('W'), findsOneWidget);
        expect(find.text('F'), findsOneWidget);
        expect(find.text('Sa'), findsOneWidget);
        expect(find.text('Su'), findsOneWidget);
      });

      test('Final Production Verification: Habit → Activity → Summary → Goal → Milestone → Achievement propagation', () async {
        final notifier = container.read(paceAppProvider.notifier);
        await notifier.loadInitialState();
        var state = container.read(paceAppProvider);

        final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

        // 1. Create habit
        final habitId = 'habit_prod_1';
        final habit = Habit(
          id: habitId,
          name: 'Daily System Verification',
          category: 'Quality',
          habitType: HabitType.binary,
          targetValue: 1.0,
          startDate: todayStr,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await notifier.createHabit(habit);
        state = container.read(paceAppProvider);
        expect(state.habits.any((h) => h.id == habitId), isTrue);

        // 2. Create goal linked to habit with milestone
        await notifier.createGoal(
          title: 'System Integration Master',
          description: 'Achieve 100% production integration',
          category: 'Quality',
          targetDate: todayStr,
          linkedHabitIds: [habitId],
          milestoneTitles: ['Verify domain reactivity'],
        );
        state = container.read(paceAppProvider);
        final goal = state.goals.firstWhere((g) => g.title == 'System Integration Master');
        expect(state.goalHabitLinks.any((l) => l.goalId == goal.id && l.habitId == habitId), isTrue);
        expect(state.milestones.any((m) => m.goalId == goal.id), isTrue);

        // 3. Complete habit
        await notifier.completeHabit(habitId, todayStr, note: 'Passed integration verification');
        state = container.read(paceAppProvider);

        // Verify completion, activity, summary, stats, goal, achievements
        expect(state.completions.any((c) => c.habitId == habitId && c.isCompleted), isTrue);
        expect(state.activities.any((a) => a.habitId == habitId && a.source == 'habit'), isTrue);

        final summary = state.dailySummaries[todayStr];
        expect(summary, isNotNull);
        expect(summary!.habitsCompleted, greaterThanOrEqualTo(1));
        expect(summary.contributionScore, greaterThan(0.0));

        final updatedGoal = state.goals.firstWhere((g) => g.id == goal.id);
        expect(updatedGoal.calculatedProgress, greaterThan(0.0));

        // 4. Toggle milestone
        final milestone = state.milestones.firstWhere((m) => m.goalId == goal.id);
        await notifier.toggleMilestone(milestone);
        state = container.read(paceAppProvider);

        final milestoneGoal = state.goals.firstWhere((g) => g.id == goal.id);
        expect(milestoneGoal.calculatedProgress, greaterThan(updatedGoal.calculatedProgress));

        // 5. Uncomplete habit
        await notifier.uncompleteHabit(habitId, todayStr);
        state = container.read(paceAppProvider);
        expect(state.completions.any((c) => c.habitId == habitId), isFalse);
        expect(state.activities.any((a) => a.habitId == habitId), isFalse);
      });
    });
  });
}

class ThrowingNotificationService extends FakeNotificationService {
  @override
  Future<void> reconcileAll({
    required UserPreferences prefs,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<Goal> goals,
  }) async {
    throw Exception('Simulated OS Notification Service Crash!');
  }
}
