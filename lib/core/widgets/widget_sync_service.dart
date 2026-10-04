import 'package:home_widget/home_widget.dart';
import '../state/pace_providers.dart';
import '../utils/date_utils.dart';

class WidgetSyncService {
  /// Synchronizes PaceAppState into Android Home Screen Widgets
  static Future<void> sync(PaceAppState state) async {
    try {
      final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
      final now = DateTime.now();

      final scheduledToday = state.habits.where((h) => !h.isArchived && h.isScheduledForDay(now)).toList();
      final completionsToday = state.completions.where((c) => c.date == todayStr && c.isCompleted).toList();
      final completedHabitIds = completionsToday.map((c) => c.habitId).toSet();

      final totalCount = scheduledToday.length;
      final completedCount = completionsToday.length;
      final percent = totalCount > 0 ? ((completedCount / totalCount) * 100).round().clamp(0, 100) : 0;

      // Find first uncompleted habit scheduled for today
      final uncompleted = scheduledToday.where((h) => !completedHabitIds.contains(h.id)).toList();
      final firstUncompleted = uncompleted.isNotEmpty ? uncompleted.first : null;

      final habitId = firstUncompleted?.id ?? (scheduledToday.isNotEmpty ? scheduledToday.first.id : '');
      final habitName = firstUncompleted != null
          ? firstUncompleted.name
          : (scheduledToday.isNotEmpty && uncompleted.isEmpty
              ? 'All habits completed!'
              : 'No habits scheduled');
      final isCompleted = firstUncompleted == null && scheduledToday.isNotEmpty;

      final remaining = uncompleted.length;
      final streak = state.consistencyStats.currentStreak;

      await HomeWidget.saveWidgetData<int>('today_completed', completedCount);
      await HomeWidget.saveWidgetData<int>('today_total', totalCount);
      await HomeWidget.saveWidgetData<int>('today_progress', percent);
      await HomeWidget.saveWidgetData<String>('quick_habit_id', habitId);
      await HomeWidget.saveWidgetData<String>('quick_habit_name', habitName);
      await HomeWidget.saveWidgetData<bool>('quick_habit_completed', isCompleted);
      await HomeWidget.saveWidgetData<int>('current_streak', streak);
      await HomeWidget.saveWidgetData<int>('remaining_habits', remaining);

      await HomeWidget.updateWidget(androidName: 'TodayProgressWidgetReceiver');
      await HomeWidget.updateWidget(androidName: 'HabitActionWidgetReceiver');
      await HomeWidget.updateWidget(androidName: 'StreakWidgetReceiver');
    } catch (_) {
      // Isolate widget update errors so domain state computation is never affected
    }
  }
}
