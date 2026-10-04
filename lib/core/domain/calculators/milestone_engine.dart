import '../models/models.dart';
import 'achievement_engine.dart';

/// Central Domain Milestone & Achievement Engine.
/// Delegates evaluation to AchievementEngine using domain data.
abstract class MilestoneEngine {
  static List<Achievement> evaluateAchievements({
    required ConsistencyStats stats,
    required List<Habit> habits,
    required List<Goal> goals,
    required int totalJournalEntries,
    List<HabitCompletion> completions = const [],
    List<Activity> activities = const [],
    List<FocusSession> focusSessions = const [],
    List<Milestone> milestones = const [],
    Map<String, DailySummary> dailySummaries = const {},
    Map<String, String> existingEarnedMap = const {}}) {
    return AchievementEngine.evaluateAchievements(
      stats: stats,
      habits: habits,
      completions: completions,
      activities: activities,
      focusSessions: focusSessions,
      goals: goals,
      milestones: milestones,
      dailySummaries: dailySummaries,
      journalEntries: List.generate(totalJournalEntries, (i) => JournalEntry(id: '$i', date: '', title: '', content: '', createdAt: '', updatedAt: '')),
      existingEarnedMap: existingEarnedMap,
    );
  }
}
