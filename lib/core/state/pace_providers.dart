import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';
import '../database/database_service.dart';
import '../database/repositories_impl.dart';
import '../domain/calculators/achievement_engine.dart';
import '../domain/calculators/contribution_engine.dart';
import '../domain/calculators/consistency_engine.dart';
import '../domain/calculators/goal_engine.dart';
import '../utils/date_utils.dart';

import '../notifications/notification_service.dart';
import '../theme/pace_colors.dart';
import '../widgets/widget_sync_service.dart';

const _uuid = Uuid();

// --- Repository Providers ---
final habitRepositoryProvider = Provider<HabitRepository>((ref) => SqliteHabitRepository());
final activityRepositoryProvider = Provider<ActivityRepository>((ref) => SqliteActivityRepository());
final focusRepositoryProvider = Provider<FocusRepository>((ref) => SqliteFocusRepository());
final goalRepositoryProvider = Provider<GoalRepository>((ref) => SqliteGoalRepository());
final journalRepositoryProvider = Provider<JournalRepository>((ref) => SqliteJournalRepository());
final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) => SqliteDailySummaryRepository());
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) => SqlitePreferencesRepository());
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) => SqliteAchievementRepository());
final backupRepositoryProvider = Provider<BackupRepository>((ref) => SqliteBackupRepository());

/// Master Application Domain State Container
class PaceAppState {
  final bool isLoading;
  final UserPreferences preferences;
  final List<Habit> habits;
  final List<HabitCompletion> completions;
  final List<Activity> activities;
  final List<FocusSession> focusSessions;
  final List<Goal> goals;
  final List<GoalHabitLink> goalHabitLinks;
  final List<Milestone> milestones;
  final List<JournalEntry> journalEntries;
  final Map<String, DailySummary> dailySummaries;
  final ConsistencyStats consistencyStats;
  final List<Achievement> achievements;
  final DateTime selectedDate;

  const PaceAppState({
    this.isLoading = true,
    this.preferences = const UserPreferences(),
    this.habits = const [],
    this.completions = const [],
    this.activities = const [],
    this.focusSessions = const [],
    this.goals = const [],
    this.goalHabitLinks = const [],
    this.milestones = const [],
    this.journalEntries = const [],
    this.dailySummaries = const {},
    this.consistencyStats = const ConsistencyStats(),
    this.achievements = const [],
    required this.selectedDate});

  PaceAppState copyWith({
    bool? isLoading,
    UserPreferences? preferences,
    List<Habit>? habits,
    List<HabitCompletion>? completions,
    List<Activity>? activities,
    List<FocusSession>? focusSessions,
    List<Goal>? goals,
    List<GoalHabitLink>? goalHabitLinks,
    List<Milestone>? milestones,
    List<JournalEntry>? journalEntries,
    Map<String, DailySummary>? dailySummaries,
    ConsistencyStats? consistencyStats,
    List<Achievement>? achievements,
    DateTime? selectedDate}) {
    return PaceAppState(
      isLoading: isLoading ?? this.isLoading,
      preferences: preferences ?? this.preferences,
      habits: habits ?? this.habits,
      completions: completions ?? this.completions,
      activities: activities ?? this.activities,
      focusSessions: focusSessions ?? this.focusSessions,
      goals: goals ?? this.goals,
      goalHabitLinks: goalHabitLinks ?? this.goalHabitLinks,
      milestones: milestones ?? this.milestones,
      journalEntries: journalEntries ?? this.journalEntries,
      dailySummaries: dailySummaries ?? this.dailySummaries,
      consistencyStats: consistencyStats ?? this.consistencyStats,
      achievements: achievements ?? this.achievements,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

/// Central Domain Notifier enforcing Single Source of Truth
class PaceAppNotifier extends Notifier<PaceAppState> {
  @override
  PaceAppState build() {
    // Schedule initial load after the notifier is created
    Future.microtask(() => loadInitialState());
    return PaceAppState(selectedDate: PaceDateUtils.today());
  }

  HabitRepository get _habitRepo => ref.read(habitRepositoryProvider);
  ActivityRepository get _activityRepo => ref.read(activityRepositoryProvider);
  FocusRepository get _focusRepo => ref.read(focusRepositoryProvider);
  GoalRepository get _goalRepo => ref.read(goalRepositoryProvider);
  JournalRepository get _journalRepo => ref.read(journalRepositoryProvider);
  DailySummaryRepository get _summaryRepo => ref.read(dailySummaryRepositoryProvider);
  PreferencesRepository get _prefRepo => ref.read(preferencesRepositoryProvider);
  AchievementRepository get _achievementRepo => ref.read(achievementRepositoryProvider);
  NotificationService get _notifService => ref.read(notificationServiceProvider);

  /// Initial state load & authoritative aggregation pass
  Future<void> loadInitialState() async {
    state = state.copyWith(isLoading: true);

    final prefs = await _prefRepo.getPreferences();
    PaceColors.setAccentColor(prefs.accentColor);
    final habits = await _habitRepo.getAllHabits(includeArchived: true);
    final completions = await _habitRepo.getAllCompletions();
    final activities = await _activityRepo.getAllActivities();
    final focusSessions = await _focusRepo.getAllFocusSessions();
    final rawGoals = await _goalRepo.getAllGoals();
    final goalHabitLinks = await _goalRepo.getAllGoalHabitLinks();
    final milestones = await _goalRepo.getAllMilestones();
    final journalEntries = await _journalRepo.getAllJournalEntries();

    await _recalculateAllSummariesAndMetrics(
      prefs: prefs,
      habits: habits,
      completions: completions,
      activities: activities,
      focusSessions: focusSessions,
      rawGoals: rawGoals,
      goalHabitLinks: goalHabitLinks,
      milestones: milestones,
      journalEntries: journalEntries,
    );
  }

  /// Recalculates summaries, streaks, goals, and achievements
  Future<void> _recalculateAllSummariesAndMetrics({
    required UserPreferences prefs,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<Activity> activities,
    required List<FocusSession> focusSessions,
    required List<Goal> rawGoals,
    required List<GoalHabitLink> goalHabitLinks,
    required List<Milestone> milestones,
    required List<JournalEntry> journalEntries}) async {
    // 1. Group completions, activities, focus by date
    final Set<String> allDates = {};
    for (final c in completions) {
      allDates.add(c.date);
    }
    for (final a in activities) {
      allDates.add(a.date);
    }
    for (final f in focusSessions) {
      allDates.add(f.date);
    }
    allDates.add(PaceDateUtils.toIsoDateString(DateTime.now()));

    final Map<String, DailySummary> summaryMap = {};

    for (final dateStr in allDates) {
      final date = PaceDateUtils.parseIsoDateString(dateStr);

      final scheduledHabits = habits.where((h) => h.isScheduledForDay(date)).toList();
      final dateCompletions = completions.where((c) => c.date == dateStr).toList();
      final dateActivities = activities.where((a) => a.date == dateStr).toList();
      final dateFocus = focusSessions.where((f) => f.date == dateStr).toList();

      final completedCount = dateCompletions.where((c) => c.isCompleted).length;
      final totalScheduled = scheduledHabits.length;

      final completionPct = totalScheduled > 0
          ? ((completedCount / totalScheduled) * 100.0).clamp(0.0, 100.0)
          : (completedCount > 0 ? 100.0 : 0.0);

      final totalFocusMins = dateFocus.fold<int>(0, (sum, f) => sum + f.actualDurationMinutes);

      var tempSummary = DailySummary(
        date: dateStr,
        totalActivities: dateActivities.length,
        habitsCompleted: completedCount,
        totalHabitsScheduled: totalScheduled,
        totalFocusMinutes: totalFocusMins,
        completionPercentage: completionPct,
        updatedAt: DateTime.now().toIso8601String(),
      );

      final score = ContributionEngine.calculateScore(tempSummary);
      final level = ContributionEngine.calculateLevel(tempSummary);

      tempSummary = tempSummary.copyWith(
        contributionScore: score,
        contributionLevel: level,
      );

      summaryMap[dateStr] = tempSummary;
      await _summaryRepo.saveSummary(tempSummary);
    }

    // 2. Consistency & Streak Engine calculation
    final sortedSummaries = summaryMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final stats = ConsistencyEngine.calculate(sortedSummaries);

    // 3. Goal Engine recalculation
    final List<Goal> updatedGoals = [];
    for (final rawGoal in rawGoals) {
      final links = goalHabitLinks.where((l) => l.goalId == rawGoal.id).toList();
      final goalMilestones = milestones.where((m) => m.goalId == rawGoal.id).toList();
      final progress = GoalEngine.calculateGoalProgress(
        goal: rawGoal,
        links: links,
        completions: completions,
        milestones: goalMilestones,
        focusSessions: focusSessions,
        activities: activities,
      );
      final isComp = progress >= 1.0;
      final updatedGoal = rawGoal.copyWith(
        calculatedProgress: progress,
        isCompleted: isComp,
      );
      updatedGoals.add(updatedGoal);
      await _goalRepo.saveGoal(updatedGoal);
    }

    // 4. Achievement calculation with persistence & idempotency
    final existingEarnedMap = await _achievementRepo.getEarnedAchievementsMap();

    final achievements = AchievementEngine.evaluateAchievements(
      stats: stats,
      habits: habits,
      completions: completions,
      activities: activities,
      focusSessions: focusSessions,
      goals: updatedGoals,
      milestones: milestones,
      dailySummaries: summaryMap,
      journalEntries: journalEntries,
      existingEarnedMap: existingEarnedMap,
    );

    for (final ach in achievements) {
      if (ach.isEarned && ach.earnedAt != null && !existingEarnedMap.containsKey(ach.id)) {
        await _achievementRepo.saveEarnedAchievement(ach.id, ach.earnedAt!);
      }
    }

    // 5. Notification reconciliation pass
    if (ref.mounted) {
      try {
        await _notifService.reconcileAll(
          prefs: prefs,
          habits: habits,
          completions: completions,
          goals: updatedGoals,
        );
      } catch (_) {
        // Notification service errors must be isolated from domain state computation.
      }
    }

    if (ref.mounted) {
      state = state.copyWith(
        isLoading: false,
        preferences: prefs,
        habits: habits,
        completions: completions,
        activities: activities,
        focusSessions: focusSessions,
        goals: updatedGoals,
        goalHabitLinks: goalHabitLinks,
        milestones: milestones,
        journalEntries: journalEntries,
        dailySummaries: summaryMap,
        consistencyStats: stats,
        achievements: achievements,
      );
      WidgetSyncService.sync(state);
    }
  }

  // --- ACTIONS ---

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: PaceDateUtils.normalizeDate(date));
  }

  Future<void> completeHabit(String habitId, String dateStr, {double? value, String? note}) async {
    final habit = state.habits.firstWhere((h) => h.id == habitId);
    final targetVal = habit.targetValue;
    final val = value ?? targetVal;
    final isDone = val >= targetVal;

    final completion = HabitCompletion(
      id: _uuid.v4(),
      habitId: habitId,
      date: dateStr,
      value: val,
      targetValue: targetVal,
      isCompleted: isDone,
      timestamp: DateTime.now().toIso8601String(),
    );

    await _habitRepo.saveCompletion(completion);

    if (isDone) {
      final actNote = (note != null && note.trim().isNotEmpty)
          ? note.trim()
          : 'Completed habit ${habit.name}';

      final activity = Activity(
        id: 'act_${_uuid.v4()}',
        habitId: habitId,
        title: habit.name,
        category: habit.category,
        durationMinutes: habit.habitType == HabitType.duration ? val.toInt() : 0,
        quantity: habit.habitType == HabitType.quantity || habit.habitType == HabitType.count ? val : 0.0,
        unit: habit.targetUnit,
        date: dateStr,
        timestamp: DateTime.now().toIso8601String(),
        notes: actNote,
        source: 'habit',
      );
      await _activityRepo.saveActivity(activity);
    }

    await loadInitialState();
  }

  Future<void> uncompleteHabit(String habitId, String dateStr) async {
    await _habitRepo.deleteCompletion(habitId, dateStr);
    await _activityRepo.deleteActivityForHabitDate(habitId, dateStr);
    await loadInitialState();
  }

  Future<void> createHabit(Habit habit) async {
    await _habitRepo.saveHabit(habit);
    await loadInitialState();
  }

  Future<void> updateHabit(Habit habit) async {
    await _habitRepo.saveHabit(habit);
    await loadInitialState();
  }

  Future<void> archiveHabit(String id, bool archive) async {
    await _habitRepo.archiveHabit(id, archive);
    await loadInitialState();
  }

  Future<void> deleteHabit(String id) async {
    await _habitRepo.deleteHabit(id);
    await loadInitialState();
  }

  Future<void> logActivity({
    required String title,
    required String category,
    int durationMinutes = 0,
    double quantity = 0.0,
    String unit = '',
    String? habitId,
    String? dateStr,
    String notes = ''}) async {
    final date = dateStr ?? PaceDateUtils.toIsoDateString(state.selectedDate);
    final activity = Activity(
      id: _uuid.v4(),
      habitId: habitId,
      title: title,
      category: category,
      durationMinutes: durationMinutes,
      quantity: quantity,
      unit: unit,
      date: date,
      timestamp: DateTime.now().toIso8601String(),
      notes: notes,
      source: 'manual',
    );
    await _activityRepo.saveActivity(activity);
    await loadInitialState();
  }

  Future<void> completeFocusSession({
    required String title,
    required int targetDurationMinutes,
    required int actualDurationMinutes,
    String? habitId,
    String? note}) async {
    final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
    final nowIso = DateTime.now().toIso8601String();

    final session = FocusSession(
      id: _uuid.v4(),
      habitId: habitId,
      title: title,
      targetDurationMinutes: targetDurationMinutes,
      actualDurationMinutes: actualDurationMinutes,
      date: todayStr,
      startedAt: DateTime.now().subtract(Duration(minutes: actualDurationMinutes)).toIso8601String(),
      completedAt: nowIso,
      isCompleted: true,
    );

    await _focusRepo.saveFocusSession(session);

    final actNote = (note != null && note.trim().isNotEmpty)
        ? note.trim()
        : 'Completed $actualDurationMinutes min focus session';

    final activity = Activity(
      id: 'act_focus_${_uuid.v4()}',
      habitId: habitId,
      title: 'Focus: $title',
      category: 'Focus',
      durationMinutes: actualDurationMinutes,
      date: todayStr,
      timestamp: nowIso,
      notes: actNote,
      source: 'focus',
    );
    await _activityRepo.saveActivity(activity);

    if (habitId != null) {
      await completeHabit(habitId, todayStr, value: actualDurationMinutes.toDouble(), note: note);
    } else {
      await loadInitialState();
    }
  }

  Future<void> createGoal({
    required String title,
    required String description,
    required String targetDate,
    required String category,
    String startDate = '',
    double targetValue = 0.0,
    String targetUnit = '',
    bool reminderEnabled = false,
    String? reminderTime,
    List<String> linkedHabitIds = const [],
    List<String> milestoneTitles = const []}) async {
    final goalId = _uuid.v4();
    final nowIso = DateTime.now().toIso8601String();
    final sDate = startDate.isNotEmpty ? startDate : PaceDateUtils.toIsoDateString(DateTime.now());

    final goal = Goal(
      id: goalId,
      title: title,
      description: description,
      startDate: sDate,
      targetDate: targetDate,
      category: category,
      targetValue: targetValue,
      targetUnit: targetUnit,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
      createdAt: nowIso,
    );

    await _goalRepo.saveGoal(goal);

    for (final habitId in linkedHabitIds) {
      final link = GoalHabitLink(
        id: _uuid.v4(),
        goalId: goalId,
        habitId: habitId,
      );
      await _goalRepo.saveGoalHabitLink(link);
    }

    int idx = 0;
    for (final mTitle in milestoneTitles) {
      if (mTitle.trim().isEmpty) continue;
      final m = Milestone(
        id: _uuid.v4(),
        goalId: goalId,
        title: mTitle.trim(),
        targetDate: targetDate,
        orderIndex: idx++,
      );
      await _goalRepo.saveMilestone(m);
    }

    await loadInitialState();
  }

  Future<void> deleteActivity(String id) async {
    await _activityRepo.deleteActivity(id);
    await loadInitialState();
  }

  Future<void> updateActivityNote(String activityId, String newNotes) async {
    final activity = state.activities.firstWhere((a) => a.id == activityId);
    final updated = activity.copyWith(notes: newNotes.trim());
    await _activityRepo.saveActivity(updated);
    await loadInitialState();
  }

  Future<void> updateHabitCompletionNote(String habitId, String dateStr, String newNote) async {
    final trimmed = newNote.trim();
    final existingAct = state.activities.cast<Activity?>().firstWhere(
      (a) => a?.habitId == habitId && a?.date == dateStr && a?.source == 'habit',
      orElse: () => null,
    );

    if (existingAct != null) {
      final updated = existingAct.copyWith(notes: trimmed);
      await _activityRepo.saveActivity(updated);
    } else {
      final habit = state.habits.firstWhere((h) => h.id == habitId);
      final completion = state.completions.cast<HabitCompletion?>().firstWhere(
        (c) => c?.habitId == habitId && c?.date == dateStr,
        orElse: () => null,
      );
      final val = completion?.value ?? habit.targetValue;
      final activity = Activity(
        id: 'act_${_uuid.v4()}',
        habitId: habitId,
        title: habit.name,
        category: habit.category,
        durationMinutes: habit.habitType == HabitType.duration ? val.toInt() : 0,
        quantity: habit.habitType == HabitType.quantity || habit.habitType == HabitType.count ? val : 0.0,
        unit: habit.targetUnit,
        date: dateStr,
        timestamp: DateTime.now().toIso8601String(),
        notes: trimmed,
        source: 'habit',
      );
      await _activityRepo.saveActivity(activity);
    }
    await loadInitialState();
  }

  Future<void> deleteFocusSession(String id) async {
    await _focusRepo.deleteFocusSession(id);
    await loadInitialState();
  }

  Future<void> updateGoal(Goal goal) async {
    await _goalRepo.saveGoal(goal);
    await loadInitialState();
  }

  Future<void> archiveGoal(String goalId, bool archive) async {
    final goal = state.goals.firstWhere((g) => g.id == goalId);
    final updated = goal.copyWith(isArchived: archive);
    await _goalRepo.saveGoal(updated);
    await loadInitialState();
  }

  Future<void> addMilestone({
    required String goalId,
    required String title,
    required String targetDate}) async {
    final existing = await _goalRepo.getMilestonesForGoal(goalId);
    final milestone = Milestone(
      id: _uuid.v4(),
      goalId: goalId,
      title: title.trim(),
      targetDate: targetDate,
      orderIndex: existing.length,
    );
    await _goalRepo.saveMilestone(milestone);
    await loadInitialState();
  }

  Future<void> updateMilestone(Milestone milestone) async {
    await _goalRepo.saveMilestone(milestone);
    await loadInitialState();
  }

  Future<void> deleteMilestone(String milestoneId) async {
    await _goalRepo.deleteMilestone(milestoneId);
    await loadInitialState();
  }

  Future<void> linkHabitToGoal(String goalId, String habitId, {double weight = 1.0}) async {
    final link = GoalHabitLink(
      id: _uuid.v4(),
      goalId: goalId,
      habitId: habitId,
      weight: weight,
    );
    await _goalRepo.saveGoalHabitLink(link);
    await loadInitialState();
  }

  Future<void> unlinkHabitFromGoal(String linkId) async {
    await _goalRepo.deleteGoalHabitLink(linkId);
    await loadInitialState();
  }

  Future<void> deleteGoal(String goalId) async {
    await _goalRepo.deleteGoal(goalId);
    await loadInitialState();
  }

  Future<void> toggleMilestone(Milestone milestone) async {
    final updated = milestone.copyWith(isCompleted: !milestone.isCompleted);
    await _goalRepo.saveMilestone(updated);
    await loadInitialState();
  }

  Future<void> saveJournalEntry({
    required String dateStr,
    required String title,
    required String content,
    required String mood}) async {
    final existing = await _journalRepo.getEntryForDate(dateStr);
    final nowIso = DateTime.now().toIso8601String();

    final entry = JournalEntry(
      id: existing?.id ?? _uuid.v4(),
      date: dateStr,
      title: title,
      content: content,
      mood: mood,
      createdAt: existing?.createdAt ?? nowIso,
      updatedAt: nowIso,
    );

    await _journalRepo.saveEntry(entry);
    await loadInitialState();
  }

  Future<void> deleteJournalEntry(String id) async {
    await _journalRepo.deleteEntry(id);
    await loadInitialState();
  }

  Future<void> updatePreferences(UserPreferences newPrefs) async {
    PaceColors.setAccentColor(newPrefs.accentColor);
    await _prefRepo.savePreferences(newPrefs);
    await loadInitialState();
  }

  Future<void> restoreBackup(Map<String, dynamic> jsonData) async {
    final backupRepo = ref.read(backupRepositoryProvider);
    await backupRepo.importAllDataJson(jsonData);
    await loadInitialState();
  }

  Future<void> clearAllData() async {
    final currentPrefs = state.preferences;
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.delete('goal_habit_links');
      await txn.delete('milestones');
      await txn.delete('habit_completions');
      await txn.delete('activities');
      await txn.delete('focus_sessions');
      await txn.delete('goals');
      await txn.delete('habits');
      await txn.delete('journal_entries');
      await txn.delete('daily_summaries');
      await txn.delete('earned_achievements');
    });
    await _prefRepo.savePreferences(currentPrefs);
    await loadInitialState();
  }
}

/// Master Provider
final paceAppProvider = NotifierProvider<PaceAppNotifier, PaceAppState>(() {
  return PaceAppNotifier();
});
