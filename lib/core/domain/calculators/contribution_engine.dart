import '../models/models.dart';

/// Central Domain Contribution Engine.
/// Calculates intensity levels (0..4) and contribution scores
/// strictly from authoritative DailySummary models.
/// NEVER calculates level directly inside UI widgets.
abstract class ContributionEngine {
  /// Calculates contribution level (0 to 4) based on daily summary data
  static int calculateLevel(DailySummary summary) {
    if (summary.totalActivities == 0 && summary.habitsCompleted == 0 && summary.totalFocusMinutes == 0) {
      return 0; // Level 0: No activity
    }

    final score = calculateScore(summary);

    if (score <= 0.0) return 0;
    if (score < 30.0) return 1;  // Light activity
    if (score < 65.0) return 2;  // Moderate activity
    if (score < 90.0) return 3;  // Good activity
    return 4;                   // Strong activity
  }

  /// Calculates a continuous contribution score (0.0 to 100.0+)
  static double calculateScore(DailySummary summary) {
    // Weight factors:
    // Habit completion: up to 60 points based on completion percentage
    // Activities: 15 points per logged activity (up to 30 max)
    // Focus minutes: 0.5 points per focus minute (up to 30 max)

    final habitScore = (summary.completionPercentage.clamp(0.0, 100.0)) * 0.6;
    final activityScore = (summary.totalActivities * 15.0).clamp(0.0, 30.0);
    final focusScore = (summary.totalFocusMinutes * 0.5).clamp(0.0, 30.0);

    final total = habitScore + activityScore + focusScore;
    return total;
  }
}
