import '../models/models.dart';

abstract class HabitRepository {
  Future<List<Habit>> getAllHabits({bool includeArchived = false});
  Future<Habit?> getHabitById(String id);
  Future<void> saveHabit(Habit habit);
  Future<void> deleteHabit(String id);
  Future<void> archiveHabit(String id, bool archive);

  Future<List<HabitCompletion>> getCompletionsForDate(String dateStr);
  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId);
  Future<List<HabitCompletion>> getAllCompletions();
  Future<void> saveCompletion(HabitCompletion completion);
  Future<void> deleteCompletion(String habitId, String dateStr);
}

abstract class ActivityRepository {
  Future<List<Activity>> getAllActivities();
  Future<List<Activity>> getActivitiesForDate(String dateStr);
  Future<List<Activity>> getActivitiesForRange(String startDate, String endDate);
  Future<void> saveActivity(Activity activity);
  Future<void> deleteActivity(String id);
  Future<void> deleteActivityForHabitDate(String habitId, String dateStr);
}

abstract class FocusRepository {
  Future<List<FocusSession>> getAllFocusSessions();
  Future<List<FocusSession>> getFocusSessionsForDate(String dateStr);
  Future<void> saveFocusSession(FocusSession session);
  Future<void> deleteFocusSession(String id);
}

abstract class GoalRepository {
  Future<List<Goal>> getAllGoals();
  Future<Goal?> getGoalById(String id);
  Future<void> saveGoal(Goal goal);
  Future<void> deleteGoal(String id);

  Future<List<GoalHabitLink>> getAllGoalHabitLinks();
  Future<List<GoalHabitLink>> getLinksForGoal(String goalId);
  Future<void> saveGoalHabitLink(GoalHabitLink link);
  Future<void> deleteGoalHabitLink(String linkId);

  Future<List<Milestone>> getAllMilestones();
  Future<List<Milestone>> getMilestonesForGoal(String goalId);
  Future<void> saveMilestone(Milestone milestone);
  Future<void> deleteMilestone(String milestoneId);
}

abstract class JournalRepository {
  Future<List<JournalEntry>> getAllJournalEntries();
  Future<JournalEntry?> getEntryForDate(String dateStr);
  Future<void> saveEntry(JournalEntry entry);
  Future<void> deleteEntry(String id);
}

abstract class DailySummaryRepository {
  Future<List<DailySummary>> getAllSummaries();
  Future<DailySummary?> getSummaryForDate(String dateStr);
  Future<List<DailySummary>> getSummariesForRange(String startDate, String endDate);
  Future<void> saveSummary(DailySummary summary);
  Future<void> deleteSummary(String dateStr);
}

abstract class PreferencesRepository {
  Future<UserPreferences> getPreferences();
  Future<void> savePreferences(UserPreferences preferences);
}

abstract class AchievementRepository {
  Future<Map<String, String>> getEarnedAchievementsMap();
  Future<void> saveEarnedAchievement(String id, String earnedAt);
  Future<void> clearEarnedAchievements();
}

abstract class BackupRepository {
  Future<Map<String, dynamic>> exportAllDataJson();
  Future<void> importAllDataJson(Map<String, dynamic> jsonData);
  Future<String> exportCsvData();
}
