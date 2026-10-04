import 'package:flutter/foundation.dart';

/// Target types supported by Pace habits
enum HabitType {
  binary,   // Yes/No (Completed/Not completed)
  quantity, // e.g. 20 pages, 6 glasses of water
  duration, // e.g. 45 minutes
  count,    // e.g. 3 problems, 5 reps
}

extension HabitTypeExtension on HabitType {
  String get name {
    switch (this) {
      case HabitType.binary:
        return 'binary';
      case HabitType.quantity:
        return 'quantity';
      case HabitType.duration:
        return 'duration';
      case HabitType.count:
        return 'count';
    }
  }

  static HabitType fromName(String name) {
    switch (name.toLowerCase()) {
      case 'quantity':
        return HabitType.quantity;
      case 'duration':
        return HabitType.duration;
      case 'count':
        return HabitType.count;
      case 'binary':
      default:
        return HabitType.binary;
    }
  }

  String get label {
    switch (this) {
      case HabitType.binary:
        return 'Yes / No';
      case HabitType.quantity:
        return 'Quantity';
      case HabitType.duration:
        return 'Duration (Min)';
      case HabitType.count:
        return 'Count / Reps';
    }
  }
}

/// Frequency schedule for habits
enum HabitFrequency {
  daily,
  weekdays,
  weeklyDays}

extension HabitFrequencyExtension on HabitFrequency {
  String get name {
    switch (this) {
      case HabitFrequency.daily:
        return 'daily';
      case HabitFrequency.weekdays:
        return 'weekdays';
      case HabitFrequency.weeklyDays:
        return 'weekly_days';
    }
  }

  static HabitFrequency fromName(String name) {
    switch (name.toLowerCase()) {
      case 'weekdays':
        return HabitFrequency.weekdays;
      case 'weekly_days':
        return HabitFrequency.weeklyDays;
      case 'daily':
      default:
        return HabitFrequency.daily;
    }
  }
}

/// Core Habit Domain Model
@immutable
class Habit {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final int colorValue;
  final HabitType habitType;
  final double targetValue;
  final String targetUnit;
  final HabitFrequency frequency;
  final List<int> selectedWeekdays; // 1 = Mon, 7 = Sun
  final String? reminderTime; // 'HH:mm' format
  final String startDate; // YYYY-MM-DD
  final String? endDate;   // YYYY-MM-DD
  final bool isArchived;
  final String createdAt;
  final String updatedAt;

  const Habit({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'General',
    this.icon = 'check_circle',
    this.colorValue = 0xFF0D9488,
    this.habitType = HabitType.binary,
    this.targetValue = 1.0,
    this.targetUnit = '',
    this.frequency = HabitFrequency.daily,
    this.selectedWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.reminderTime,
    required this.startDate,
    this.endDate,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt});

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? icon,
    int? colorValue,
    HabitType? habitType,
    double? targetValue,
    String? targetUnit,
    HabitFrequency? frequency,
    List<int>? selectedWeekdays,
    String? reminderTime,
    String? startDate,
    String? endDate,
    bool? isArchived,
    String? createdAt,
    String? updatedAt}) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      habitType: habitType ?? this.habitType,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      frequency: frequency ?? this.frequency,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      reminderTime: reminderTime ?? this.reminderTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'colorValue': colorValue,
      'habitType': habitType.name,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'frequency': frequency.name,
      'selectedWeekdays': selectedWeekdays,
      'reminderTime': reminderTime,
      'startDate': startDate,
      'endDate': endDate,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt};
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      icon: json['icon'] as String? ?? 'check_circle',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF0D9488,
      habitType: HabitTypeExtension.fromName(json['habitType'] as String? ?? 'binary'),
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
      targetUnit: json['targetUnit'] as String? ?? '',
      frequency: HabitFrequencyExtension.fromName(json['frequency'] as String? ?? 'daily'),
      selectedWeekdays: (json['selectedWeekdays'] is List)
          ? List<int>.from(json['selectedWeekdays'] as List)
          : [1, 2, 3, 4, 5, 6, 7],
      reminderTime: json['reminderTime'] as String?,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
      isArchived: (json['isArchived'] == 1 || json['isArchived'] == true),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  bool isScheduledForDay(DateTime date) {
    if (isArchived) return false;
    final isoDate = date.toString().split(' ').first;
    if (isoDate.compareTo(startDate) < 0) return false;
    if (endDate != null && isoDate.compareTo(endDate!) > 0) return false;

    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekdays:
        return date.weekday >= 1 && date.weekday <= 5;
      case HabitFrequency.weeklyDays:
        return selectedWeekdays.contains(date.weekday);
    }
  }
}

/// Habit Completion Record
@immutable
class HabitCompletion {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD
  final double value;
  final double targetValue;
  final bool isCompleted;
  final String timestamp;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    required this.value,
    required this.targetValue,
    required this.isCompleted,
    required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date,
      'value': value,
      'targetValue': targetValue,
      'isCompleted': isCompleted ? 1 : 0,
      'timestamp': timestamp};
  }

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: json['date'] as String,
      value: (json['value'] as num).toDouble(),
      targetValue: (json['targetValue'] as num).toDouble(),
      isCompleted: (json['isCompleted'] == 1 || json['isCompleted'] == true),
      timestamp: json['timestamp'] as String,
    );
  }
}

/// Activity Log Entry (from habit completion, manual entry, or focus session)
@immutable
class Activity {
  final String id;
  final String? habitId;
  final String title;
  final String category;
  final int durationMinutes;
  final double quantity;
  final String unit;
  final String date; // YYYY-MM-DD
  final String timestamp;
  final String notes;
  final String source; // 'habit', 'focus', 'manual'

  const Activity({
    required this.id,
    this.habitId,
    required this.title,
    this.category = 'General',
    this.durationMinutes = 0,
    this.quantity = 0.0,
    this.unit = '',
    required this.date,
    required this.timestamp,
    this.notes = '',
    this.source = 'manual'});

  Activity copyWith({
    String? id,
    String? habitId,
    String? title,
    String? category,
    int? durationMinutes,
    double? quantity,
    String? unit,
    String? date,
    String? timestamp,
    String? notes,
    String? source,
  }) {
    return Activity(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      title: title ?? this.title,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'title': title,
      'category': category,
      'durationMinutes': durationMinutes,
      'quantity': quantity,
      'unit': unit,
      'date': date,
      'timestamp': timestamp,
      'notes': notes,
      'source': source};
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      habitId: json['habitId'] as String?,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'General',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      date: json['date'] as String,
      timestamp: json['timestamp'] as String,
      notes: json['notes'] as String? ?? '',
      source: json['source'] as String? ?? 'manual',
    );
  }
}

/// Focus Session Record
@immutable
class FocusSession {
  final String id;
  final String? habitId;
  final String title;
  final int targetDurationMinutes;
  final int actualDurationMinutes;
  final String date; // YYYY-MM-DD
  final String startedAt;
  final String completedAt;
  final bool isCompleted;

  const FocusSession({
    required this.id,
    this.habitId,
    required this.title,
    required this.targetDurationMinutes,
    required this.actualDurationMinutes,
    required this.date,
    required this.startedAt,
    required this.completedAt,
    this.isCompleted = true});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'title': title,
      'targetDurationMinutes': targetDurationMinutes,
      'actualDurationMinutes': actualDurationMinutes,
      'date': date,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'isCompleted': isCompleted ? 1 : 0};
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      habitId: json['habitId'] as String?,
      title: json['title'] as String,
      targetDurationMinutes: (json['targetDurationMinutes'] as num).toInt(),
      actualDurationMinutes: (json['actualDurationMinutes'] as num).toInt(),
      date: json['date'] as String,
      startedAt: json['startedAt'] as String,
      completedAt: json['completedAt'] as String,
      isCompleted: (json['isCompleted'] == 1 || json['isCompleted'] == true),
    );
  }
}

/// Long-Term Goal
@immutable
class Goal {
  final String id;
  final String title;
  final String description;
  final String startDate; // YYYY-MM-DD
  final String targetDate; // YYYY-MM-DD
  final String category;
  final double targetValue;
  final String targetUnit;
  final bool isCompleted;
  final bool isArchived;
  final double calculatedProgress; // 0.0 to 1.0
  final bool reminderEnabled;
  final String? reminderTime; // 'HH:mm' format
  final String createdAt;

  const Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.startDate = '',
    required this.targetDate,
    this.category = 'General',
    this.targetValue = 0.0,
    this.targetUnit = '',
    this.isCompleted = false,
    this.isArchived = false,
    this.calculatedProgress = 0.0,
    this.reminderEnabled = false,
    this.reminderTime,
    required this.createdAt});

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    String? startDate,
    String? targetDate,
    String? category,
    double? targetValue,
    String? targetUnit,
    bool? isCompleted,
    bool? isArchived,
    double? calculatedProgress,
    bool? reminderEnabled,
    String? reminderTime,
    String? createdAt}) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      calculatedProgress: calculatedProgress ?? this.calculatedProgress,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate,
      'targetDate': targetDate,
      'category': category,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'isCompleted': isCompleted ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'calculatedProgress': calculatedProgress,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderTime': reminderTime,
      'createdAt': createdAt};
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      targetDate: json['targetDate'] as String,
      category: json['category'] as String? ?? 'General',
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 0.0,
      targetUnit: json['targetUnit'] as String? ?? '',
      isCompleted: (json['isCompleted'] == 1 || json['isCompleted'] == true),
      isArchived: (json['isArchived'] == 1 || json['isArchived'] == true),
      calculatedProgress: (json['calculatedProgress'] as num?)?.toDouble() ?? 0.0,
      reminderEnabled: (json['reminderEnabled'] == 1 || json['reminderEnabled'] == true),
      reminderTime: json['reminderTime'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

/// Link between a Goal and a Habit
@immutable
class GoalHabitLink {
  final String id;
  final String goalId;
  final String habitId;
  final double weight; // Weight towards total goal

  const GoalHabitLink({
    required this.id,
    required this.goalId,
    required this.habitId,
    this.weight = 1.0});

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'habitId': habitId,
        'weight': weight};

  factory GoalHabitLink.fromJson(Map<String, dynamic> json) => GoalHabitLink(
        id: json['id'] as String,
        goalId: json['goalId'] as String,
        habitId: json['habitId'] as String,
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      );
}

/// Goal Milestone
@immutable
class Milestone {
  final String id;
  final String goalId;
  final String title;
  final bool isCompleted;
  final String targetDate;
  final int orderIndex;

  const Milestone({
    required this.id,
    required this.goalId,
    required this.title,
    this.isCompleted = false,
    required this.targetDate,
    this.orderIndex = 0});

  Milestone copyWith({
    String? id,
    String? goalId,
    String? title,
    bool? isCompleted,
    String? targetDate,
    int? orderIndex}) {
    return Milestone(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      targetDate: targetDate ?? this.targetDate,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'title': title,
        'isCompleted': isCompleted ? 1 : 0,
        'targetDate': targetDate,
        'orderIndex': orderIndex};

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        goalId: json['goalId'] as String,
        title: json['title'] as String,
        isCompleted: (json['isCompleted'] == 1 || json['isCompleted'] == true),
        targetDate: json['targetDate'] as String,
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      );
}

/// Daily Journal Reflection
@immutable
class JournalEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final String title;
  final String content;
  final String mood; // 'great', 'good', 'neutral', 'low', 'tough'
  final String createdAt;
  final String updatedAt;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.mood = 'good',
    required this.createdAt,
    required this.updatedAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'title': title,
        'content': content,
        'mood': mood,
        'createdAt': createdAt,
        'updatedAt': updatedAt};

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        date: json['date'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        mood: json['mood'] as String? ?? 'good',
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
      );
}

/// Authoritative Daily Summary Projection
@immutable
class DailySummary {
  final String date; // YYYY-MM-DD
  final int totalActivities;
  final int habitsCompleted;
  final int totalHabitsScheduled;
  final int totalFocusMinutes;
  final double completionPercentage; // 0.0 to 100.0
  final double contributionScore;
  final int contributionLevel; // 0, 1, 2, 3, 4
  final String updatedAt;

  const DailySummary({
    required this.date,
    this.totalActivities = 0,
    this.habitsCompleted = 0,
    this.totalHabitsScheduled = 0,
    this.totalFocusMinutes = 0,
    this.completionPercentage = 0.0,
    this.contributionScore = 0.0,
    this.contributionLevel = 0,
    required this.updatedAt});

  DailySummary copyWith({
    String? date,
    int? totalActivities,
    int? habitsCompleted,
    int? totalHabitsScheduled,
    int? totalFocusMinutes,
    double? completionPercentage,
    double? contributionScore,
    int? contributionLevel,
    String? updatedAt}) {
    return DailySummary(
      date: date ?? this.date,
      totalActivities: totalActivities ?? this.totalActivities,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      totalHabitsScheduled: totalHabitsScheduled ?? this.totalHabitsScheduled,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      contributionScore: contributionScore ?? this.contributionScore,
      contributionLevel: contributionLevel ?? this.contributionLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'totalActivities': totalActivities,
        'habitsCompleted': habitsCompleted,
        'totalHabitsScheduled': totalHabitsScheduled,
        'totalFocusMinutes': totalFocusMinutes,
        'completionPercentage': completionPercentage,
        'contributionScore': contributionScore,
        'contributionLevel': contributionLevel,
        'updatedAt': updatedAt};

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        date: json['date'] as String,
        totalActivities: (json['totalActivities'] as num?)?.toInt() ?? 0,
        habitsCompleted: (json['habitsCompleted'] as num?)?.toInt() ?? 0,
        totalHabitsScheduled: (json['totalHabitsScheduled'] as num?)?.toInt() ?? 0,
        totalFocusMinutes: (json['totalFocusMinutes'] as num?)?.toInt() ?? 0,
        completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
        contributionScore: (json['contributionScore'] as num?)?.toDouble() ?? 0.0,
        contributionLevel: (json['contributionLevel'] as num?)?.toInt() ?? 0,
        updatedAt: json['updatedAt'] as String,
      );
}

/// Contribution Calendar Day Representation
@immutable
class ContributionDay {
  final DateTime date;
  final int intensityLevel; // 0..4
  final int totalActivities;
  final int habitsCompleted;
  final int focusMinutes;
  final double completionPercentage;
  final bool isToday;
  final bool isFuture;

  const ContributionDay({
    required this.date,
    required this.intensityLevel,
    this.totalActivities = 0,
    this.habitsCompleted = 0,
    this.focusMinutes = 0,
    this.completionPercentage = 0.0,
    this.isToday = false,
    this.isFuture = false});
}

/// User Consistency Statistics Overview
@immutable
class ConsistencyStats {
  final int currentStreak;
  final int bestStreak;
  final int activeDays;
  final int totalActivitiesLogged;
  final int totalFocusMinutes;
  final double weeklyCompletionPercentage;
  final double monthlyCompletionPercentage;
  final double overallCompletionPercentage;

  const ConsistencyStats({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.activeDays = 0,
    this.totalActivitiesLogged = 0,
    this.totalFocusMinutes = 0,
    this.weeklyCompletionPercentage = 0.0,
    this.monthlyCompletionPercentage = 0.0,
    this.overallCompletionPercentage = 0.0});
}

/// Achievement Milestone
@immutable
class Achievement {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;
  final bool isUnlocked;
  final String? unlockedAt;
  final double progress; // 0.0 to 1.0
  final double currentValue;
  final double targetValue;
  final String unit;
  final String evidenceText;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'General',
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
    this.currentValue = 0.0,
    this.targetValue = 1.0,
    this.unit = '',
    this.evidenceText = ''});

  bool get isEarned => isUnlocked;
  String? get earnedAt => unlockedAt;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? icon,
    bool? isUnlocked,
    String? unlockedAt,
    double? progress,
    double? currentValue,
    double? targetValue,
    String? unit,
    String? evidenceText}) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      evidenceText: evidenceText ?? this.evidenceText,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'icon': icon,
        'isUnlocked': isUnlocked ? 1 : 0,
        'unlockedAt': unlockedAt,
        'progress': progress,
        'currentValue': currentValue,
        'targetValue': targetValue,
        'unit': unit,
        'evidenceText': evidenceText};

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String? ?? 'General',
        icon: json['icon'] as String,
        isUnlocked: (json['isUnlocked'] == 1 || json['isUnlocked'] == true),
        unlockedAt: json['unlockedAt'] as String?,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
        targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
        unit: json['unit'] as String? ?? '',
        evidenceText: json['evidenceText'] as String? ?? '',
      );
}

/// Application User Preferences
@immutable
class UserPreferences {
  final bool firstDayIsMonday;
  final bool notificationsEnabled;
  final bool habitRemindersEnabled;
  final bool goalRemindersEnabled;
  final bool focusRemindersEnabled;
  final bool dailyReflectionEnabled;
  final String dailyReflectionTime; // '21:00' format
  final bool quietHoursEnabled;
  final String quietHoursStart; // '22:00'
  final String quietHoursEnd; // '07:00'
  final String notificationDetail; // 'full' or 'minimal'
  final String defaultFocusDuration; // '25', '45', '60'
  final String userName;
  final String onboardingStatus; // 'notStarted', 'completed', 'skipped'
  final String accentColor;
  final String completionNotePreference; // 'ask' or 'dont_ask'
  final bool showProfileAchievements;
  final String consistencyMapDefaultRange; // 'month' or 'year'
  final String consistencyMapDisplayStyle; // 'grid' or 'calendar'

  const UserPreferences({
    this.firstDayIsMonday = true,
    this.notificationsEnabled = true,
    this.habitRemindersEnabled = true,
    this.goalRemindersEnabled = false,
    this.focusRemindersEnabled = false,
    this.dailyReflectionEnabled = false,
    this.dailyReflectionTime = '21:00',
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.notificationDetail = 'full',
    this.defaultFocusDuration = '25',
    this.userName = 'User',
    this.onboardingStatus = 'notStarted',
    this.accentColor = 'green',
    this.completionNotePreference = 'ask',
    this.showProfileAchievements = true,
    this.consistencyMapDefaultRange = 'month',
    this.consistencyMapDisplayStyle = 'grid'});

  bool get hasCompletedOnboarding => onboardingStatus == 'completed' || onboardingStatus == 'skipped';

  UserPreferences copyWith({
    bool? firstDayIsMonday,
    bool? notificationsEnabled,
    bool? habitRemindersEnabled,
    bool? goalRemindersEnabled,
    bool? focusRemindersEnabled,
    bool? dailyReflectionEnabled,
    String? dailyReflectionTime,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? notificationDetail,
    String? defaultFocusDuration,
    String? userName,
    String? onboardingStatus,
    String? accentColor,
    String? completionNotePreference,
    bool? showProfileAchievements,
    String? consistencyMapDefaultRange,
    String? consistencyMapDisplayStyle}) {
    return UserPreferences(
      firstDayIsMonday: firstDayIsMonday ?? this.firstDayIsMonday,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      habitRemindersEnabled: habitRemindersEnabled ?? this.habitRemindersEnabled,
      goalRemindersEnabled: goalRemindersEnabled ?? this.goalRemindersEnabled,
      focusRemindersEnabled: focusRemindersEnabled ?? this.focusRemindersEnabled,
      dailyReflectionEnabled: dailyReflectionEnabled ?? this.dailyReflectionEnabled,
      dailyReflectionTime: dailyReflectionTime ?? this.dailyReflectionTime,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      notificationDetail: notificationDetail ?? this.notificationDetail,
      defaultFocusDuration: defaultFocusDuration ?? this.defaultFocusDuration,
      userName: userName ?? this.userName,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      accentColor: accentColor ?? this.accentColor,
      completionNotePreference: completionNotePreference ?? this.completionNotePreference,
      showProfileAchievements: showProfileAchievements ?? this.showProfileAchievements,
      consistencyMapDefaultRange: consistencyMapDefaultRange ?? this.consistencyMapDefaultRange,
      consistencyMapDisplayStyle: consistencyMapDisplayStyle ?? this.consistencyMapDisplayStyle,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstDayIsMonday': firstDayIsMonday,
        'notificationsEnabled': notificationsEnabled,
        'habitRemindersEnabled': habitRemindersEnabled,
        'goalRemindersEnabled': goalRemindersEnabled,
        'focusRemindersEnabled': focusRemindersEnabled,
        'dailyReflectionEnabled': dailyReflectionEnabled,
        'dailyReflectionTime': dailyReflectionTime,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'notificationDetail': notificationDetail,
        'defaultFocusDuration': defaultFocusDuration,
        'userName': userName,
        'onboardingStatus': onboardingStatus,
        'accentColor': accentColor,
        'completionNotePreference': completionNotePreference,
        'showProfileAchievements': showProfileAchievements,
        'consistencyMapDefaultRange': consistencyMapDefaultRange,
        'consistencyMapDisplayStyle': consistencyMapDisplayStyle};

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        firstDayIsMonday: json['firstDayIsMonday'] as bool? ?? true,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        habitRemindersEnabled: json['habitRemindersEnabled'] as bool? ?? true,
        goalRemindersEnabled: json['goalRemindersEnabled'] as bool? ?? false,
        focusRemindersEnabled: json['focusRemindersEnabled'] as bool? ?? false,
        dailyReflectionEnabled: json['dailyReflectionEnabled'] as bool? ?? false,
        dailyReflectionTime: json['dailyReflectionTime'] as String? ?? '21:00',
        quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
        quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
        quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00',
        notificationDetail: json['notificationDetail'] as String? ?? 'full',
        defaultFocusDuration: json['defaultFocusDuration'] as String? ?? '25',
        userName: json['userName'] as String? ?? 'User',
        onboardingStatus: json['onboardingStatus'] as String? ?? 'notStarted',
        accentColor: json['accentColor'] as String? ?? 'green',
        completionNotePreference: json['completionNotePreference'] as String? ?? 'ask',
        showProfileAchievements: json['showProfileAchievements'] as bool? ?? true,
        consistencyMapDefaultRange: json['consistencyMapDefaultRange'] as String? ?? 'month',
        consistencyMapDisplayStyle: json['consistencyMapDisplayStyle'] as String? ?? 'grid',
      );
}

/// Backup Export Format Metadata
@immutable
class BackupMetadata {
  final int backupVersion;
  final String appVersion;
  final String exportedAt;
  final int totalHabits;
  final int totalCompletions;
  final int totalActivities;
  final int totalGoals;
  final int totalFocusSessions;
  final int totalJournalEntries;

  const BackupMetadata({
    this.backupVersion = 1,
    required this.appVersion,
    required this.exportedAt,
    required this.totalHabits,
    required this.totalCompletions,
    required this.totalActivities,
    required this.totalGoals,
    required this.totalFocusSessions,
    required this.totalJournalEntries});

  Map<String, dynamic> toJson() => {
        'backupVersion': backupVersion,
        'appVersion': appVersion,
        'exportedAt': exportedAt,
        'totalHabits': totalHabits,
        'totalCompletions': totalCompletions,
        'totalActivities': totalActivities,
        'totalGoals': totalGoals,
        'totalFocusSessions': totalFocusSessions,
        'totalJournalEntries': totalJournalEntries};

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
        backupVersion: (json['backupVersion'] as num?)?.toInt() ?? 1,
        appVersion: json['appVersion'] as String? ?? '1.0.0',
        exportedAt: json['exportedAt'] as String? ?? DateTime.now().toIso8601String(),
        totalHabits: (json['totalHabits'] as num?)?.toInt() ?? 0,
        totalCompletions: (json['totalCompletions'] as num?)?.toInt() ?? 0,
        totalActivities: (json['totalActivities'] as num?)?.toInt() ?? 0,
        totalGoals: (json['totalGoals'] as num?)?.toInt() ?? 0,
        totalFocusSessions: (json['totalFocusSessions'] as num?)?.toInt() ?? 0,
        totalJournalEntries: (json['totalJournalEntries'] as num?)?.toInt() ?? 0,
      );
}
