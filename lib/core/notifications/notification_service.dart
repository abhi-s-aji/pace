import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../domain/models/models.dart';
import '../utils/date_utils.dart';

/// Notification Service Abstraction Interface
abstract class NotificationService {
  Future<void> initialize({Function(String payload)? onNotificationSelect});
  Future<bool> requestPermission();
  Future<bool> hasPermission();

  Future<void> scheduleHabitReminder(Habit habit, {required bool isCompletedToday});
  Future<void> cancelHabitReminder(String habitId);

  Future<void> scheduleGoalReminder(Goal goal);
  Future<void> cancelGoalReminder(String goalId);

  Future<void> scheduleDailyReflection(String reflectionTime);
  Future<void> cancelDailyReflection();

  Future<void> cancelAll();

  Future<void> reconcileAll({
    required UserPreferences prefs,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<Goal> goals});
}

/// Helper to generate deterministic notification IDs
int getDeterministicNotificationId(String type, String id) {
  return (type.hashCode ^ id.hashCode) & 0x7FFFFFFF;
}

/// Production Local Notification Service using flutter_local_notifications
class LocalNotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionGranted = false;
  Function(String payload)? _onNotificationSelect;

  void _ensureTimezonesInitialized() {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {}
  }

  @override
  Future<void> initialize({Function(String payload)? onNotificationSelect}) async {
    if (_initialized) return;
    _onNotificationSelect = onNotificationSelect;

    try {
      _ensureTimezonesInitialized();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: iosInit,
        linux: LinuxInitializationSettings(defaultActionName: 'Open Pace'),
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _onNotificationSelect?.call(response.payload!);
          }
        },
      );
      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationServiceImpl initialize warning/error: $e');
      _initialized = false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        _permissionGranted = granted ?? false;
        return _permissionGranted;
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionGranted = granted ?? false;
        return _permissionGranted;
      }

      _permissionGranted = true;
      return true;
    } catch (e) {
      debugPrint('requestPermission warning/error: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    return _permissionGranted;
  }

  @override
  Future<void> scheduleHabitReminder(Habit habit, {required bool isCompletedToday}) async {
    if (habit.reminderTime == null || habit.reminderTime!.isEmpty) return;
    if (habit.isArchived) {
      await cancelHabitReminder(habit.id);
      return;
    }

    final notifId = getDeterministicNotificationId('habit', habit.id);

    // Completion awareness: If already completed today, suppress/cancel today's reminder
    if (isCompletedToday) {
      try {
        await _plugin.cancel(notifId);
      } catch (_) {}
      return;
    }

    final parts = habit.reminderTime!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 20;
    final minute = int.tryParse(parts[1]) ?? 0;

    final title = habit.name;
    const body = 'A reminder for your scheduled habit.';

    try {
      _ensureTimezonesInitialized();
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      var scheduledTime = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'pace_reminders',
        'Pace Reminders',
        channelDescription: 'Scheduled habit and goal reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit:${habit.id}',
      );
    } catch (e) {
      debugPrint('scheduleHabitReminder error: $e');
    }
  }

  @override
  Future<void> cancelHabitReminder(String habitId) async {
    if (!_initialized) return;
    final notifId = getDeterministicNotificationId('habit', habitId);
    try {
      _ensureTimezonesInitialized();
      await _plugin.cancel(notifId);
    } catch (e) {
      debugPrint('cancelHabitReminder error: $e');
    }
  }

  @override
  Future<void> scheduleGoalReminder(Goal goal) async {
    if (!goal.reminderEnabled || goal.reminderTime == null || goal.reminderTime!.isEmpty) return;
    if (goal.isArchived || goal.isCompleted) {
      await cancelGoalReminder(goal.id);
      return;
    }

    final notifId = getDeterministicNotificationId('goal', goal.id);

    final parts = goal.reminderTime!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;

    final title = goal.title;
    const body = 'A reminder to spend some time on your goal.';

    try {
      _ensureTimezonesInitialized();
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      var scheduledTime = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'pace_reminders',
        'Pace Reminders',
        channelDescription: 'Scheduled habit and goal reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'goal:${goal.id}',
      );
    } catch (e) {
      debugPrint('scheduleGoalReminder error: $e');
    }
  }

  @override
  Future<void> cancelGoalReminder(String goalId) async {
    if (!_initialized) return;
    final notifId = getDeterministicNotificationId('goal', goalId);
    try {
      _ensureTimezonesInitialized();
      await _plugin.cancel(notifId);
    } catch (e) {
      debugPrint('cancelGoalReminder error: $e');
    }
  }

  @override
  Future<void> scheduleDailyReflection(String reflectionTime) async {
    final notifId = getDeterministicNotificationId('reflection', 'daily');

    final parts = reflectionTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 21;
    final minute = int.tryParse(parts[1]) ?? 0;

    const title = 'Daily Reflection';
    const body = 'Take a moment to record how today went.';

    try {
      _ensureTimezonesInitialized();
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      var scheduledTime = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'pace_reflections',
        'Pace Reflections',
        channelDescription: 'Daily reflection and journaling reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reflection:daily',
      );
    } catch (e) {
      debugPrint('scheduleDailyReflection error: $e');
    }
  }

  @override
  Future<void> cancelDailyReflection() async {
    if (!_initialized) return;
    final notifId = getDeterministicNotificationId('reflection', 'daily');
    try {
      _ensureTimezonesInitialized();
      await _plugin.cancel(notifId);
    } catch (e) {
      debugPrint('cancelDailyReflection error: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      _ensureTimezonesInitialized();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAll error: $e');
    }
  }

  @override
  Future<void> reconcileAll({
    required UserPreferences prefs,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<Goal> goals}) async {
    if (!prefs.notificationsEnabled) {
      await cancelAll();
      return;
    }

    final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
    final todayDate = DateTime.now();

    // 1. Habit Reminders
    if (!prefs.habitRemindersEnabled) {
      for (final h in habits) {
        await cancelHabitReminder(h.id);
      }
    } else {
      for (final h in habits) {
        if (h.isArchived || h.reminderTime == null || h.reminderTime!.isEmpty) {
          await cancelHabitReminder(h.id);
          continue;
        }

        final isScheduledToday = h.isScheduledForDay(todayDate);
        if (!isScheduledToday) {
          continue;
        }

        final isCompletedToday = completions.any(
          (c) => c.habitId == h.id && c.date == todayStr && c.isCompleted,
        );

        if (isCompletedToday) {
          await cancelHabitReminder(h.id);
        } else {
          await scheduleHabitReminder(h, isCompletedToday: false);
        }
      }
    }

    // 2. Goal Reminders
    if (!prefs.goalRemindersEnabled) {
      for (final g in goals) {
        await cancelGoalReminder(g.id);
      }
    } else {
      for (final g in goals) {
        if (g.isArchived || g.isCompleted || !g.reminderEnabled || g.reminderTime == null || g.reminderTime!.isEmpty) {
          await cancelGoalReminder(g.id);
        } else {
          await scheduleGoalReminder(g);
        }
      }
    }

    // 3. Daily Reflection Reminder
    if (prefs.dailyReflectionEnabled) {
      await scheduleDailyReflection(prefs.dailyReflectionTime);
    } else {
      await cancelDailyReflection();
    }
  }
}

/// Fake Notification Service for Unit Testing & Deterministic Verification
class FakeNotificationService implements NotificationService {
  bool permissionGranted = true;
  bool initialized = false;
  bool cancelledAll = false;
  final Set<String> scheduledHabitIds = {};
  final Set<String> scheduledGoalIds = {};
  bool dailyReflectionScheduled = false;
  String? dailyReflectionTimeScheduled;
  Function(String payload)? onNotificationSelect;

  @override
  Future<void> initialize({Function(String payload)? onNotificationSelect}) async {
    initialized = true;
    this.onNotificationSelect = onNotificationSelect;
  }

  @override
  Future<bool> requestPermission() async {
    permissionGranted = true;
    return true;
  }

  @override
  Future<bool> hasPermission() async {
    return permissionGranted;
  }

  @override
  Future<void> scheduleHabitReminder(Habit habit, {required bool isCompletedToday}) async {
    if (isCompletedToday) {
      scheduledHabitIds.remove(habit.id);
      return;
    }
    if (!habit.isArchived && habit.reminderTime != null && habit.reminderTime!.isNotEmpty) {
      scheduledHabitIds.add(habit.id);
    } else {
      scheduledHabitIds.remove(habit.id);
    }
  }

  @override
  Future<void> cancelHabitReminder(String habitId) async {
    scheduledHabitIds.remove(habitId);
  }

  @override
  Future<void> scheduleGoalReminder(Goal goal) async {
    if (!goal.isArchived && !goal.isCompleted && goal.reminderEnabled && goal.reminderTime != null && goal.reminderTime!.isNotEmpty) {
      scheduledGoalIds.add(goal.id);
    } else {
      scheduledGoalIds.remove(goal.id);
    }
  }

  @override
  Future<void> cancelGoalReminder(String goalId) async {
    scheduledGoalIds.remove(goalId);
  }

  @override
  Future<void> scheduleDailyReflection(String reflectionTime) async {
    dailyReflectionScheduled = true;
    dailyReflectionTimeScheduled = reflectionTime;
  }

  @override
  Future<void> cancelDailyReflection() async {
    dailyReflectionScheduled = false;
    dailyReflectionTimeScheduled = null;
  }

  @override
  Future<void> cancelAll() async {
    cancelledAll = true;
    scheduledHabitIds.clear();
    scheduledGoalIds.clear();
    dailyReflectionScheduled = false;
    dailyReflectionTimeScheduled = null;
  }

  @override
  Future<void> reconcileAll({
    required UserPreferences prefs,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<Goal> goals}) async {
    if (!prefs.notificationsEnabled) {
      await cancelAll();
      return;
    }

    final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
    final todayDate = DateTime.now();

    // Habits
    scheduledHabitIds.clear();
    if (prefs.habitRemindersEnabled) {
      for (final h in habits) {
        if (h.isArchived || h.reminderTime == null || h.reminderTime!.isEmpty) {
          continue;
        }
        if (!h.isScheduledForDay(todayDate)) continue;

        final isCompletedToday = completions.any(
          (c) => c.habitId == h.id && c.date == todayStr && c.isCompleted,
        );

        if (!isCompletedToday) {
          scheduledHabitIds.add(h.id);
        }
      }
    }

    // Goals
    scheduledGoalIds.clear();
    if (prefs.goalRemindersEnabled) {
      for (final g in goals) {
        if (!g.isArchived && !g.isCompleted && g.reminderEnabled && g.reminderTime != null && g.reminderTime!.isNotEmpty) {
          scheduledGoalIds.add(g.id);
        }
      }
    }

    // Reflection
    if (prefs.dailyReflectionEnabled) {
      dailyReflectionScheduled = true;
      dailyReflectionTimeScheduled = prefs.dailyReflectionTime;
    } else {
      dailyReflectionScheduled = false;
      dailyReflectionTimeScheduled = null;
    }
  }
}

/// Notification Service Riverpod Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationServiceImpl();
});
