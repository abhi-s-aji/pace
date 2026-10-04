import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';
import 'database_service.dart';

class SqliteHabitRepository implements HabitRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'habits',
      where: includeArchived ? null : 'isArchived = 0',
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      if (map['selectedWeekdays'] is String) {
        map['selectedWeekdays'] = jsonDecode(map['selectedWeekdays'] as String);
      }
      return Habit.fromJson(map);
    }).toList();
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final map = Map<String, dynamic>.from(maps.first);
    if (map['selectedWeekdays'] is String) {
      map['selectedWeekdays'] = jsonDecode(map['selectedWeekdays'] as String);
    }
    return Habit.fromJson(map);
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final db = await _dbService.database;
    final json = habit.toJson();
    json['selectedWeekdays'] = jsonEncode(json['selectedWeekdays']);
    final count = await db.update(
      'habits',
      json,
      where: 'id = ?',
      whereArgs: [habit.id],
    );
    if (count == 0) {
      await db.insert('habits', json);
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
      await txn.delete('habit_completions', where: 'habitId = ?', whereArgs: [id]);
      await txn.delete('goal_habit_links', where: 'habitId = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> archiveHabit(String id, bool archive) async {
    final db = await _dbService.database;
    await db.update(
      'habits',
      {
        'isArchived': archive ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<HabitCompletion>> getCompletionsForDate(String dateStr) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'habit_completions',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    return maps.map((m) => HabitCompletion.fromJson(m)).toList();
  }

  @override
  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'habit_completions',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    return maps.map((m) => HabitCompletion.fromJson(m)).toList();
  }

  @override
  Future<List<HabitCompletion>> getAllCompletions() async {
    final db = await _dbService.database;
    final maps = await db.query('habit_completions');
    return maps.map((m) => HabitCompletion.fromJson(m)).toList();
  }

  @override
  Future<void> saveCompletion(HabitCompletion completion) async {
    final db = await _dbService.database;
    await db.insert(
      'habit_completions',
      completion.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteCompletion(String habitId, String dateStr) async {
    final db = await _dbService.database;
    await db.delete(
      'habit_completions',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, dateStr],
    );
  }
}

class SqliteActivityRepository implements ActivityRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<Activity>> getAllActivities() async {
    final db = await _dbService.database;
    final maps = await db.query('activities', orderBy: 'timestamp DESC');
    return maps.map((m) => Activity.fromJson(m)).toList();
  }

  @override
  Future<List<Activity>> getActivitiesForDate(String dateStr) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'activities',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => Activity.fromJson(m)).toList();
  }

  @override
  Future<List<Activity>> getActivitiesForRange(String startDate, String endDate) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'activities',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => Activity.fromJson(m)).toList();
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    final db = await _dbService.database;
    await db.insert(
      'activities',
      activity.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteActivity(String id) async {
    final db = await _dbService.database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteActivityForHabitDate(String habitId, String dateStr) async {
    final db = await _dbService.database;
    await db.delete(
      'activities',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, dateStr],
    );
  }
}

class SqliteFocusRepository implements FocusRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<FocusSession>> getAllFocusSessions() async {
    final db = await _dbService.database;
    final maps = await db.query('focus_sessions', orderBy: 'completedAt DESC');
    return maps.map((m) => FocusSession.fromJson(m)).toList();
  }

  @override
  Future<List<FocusSession>> getFocusSessionsForDate(String dateStr) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'focus_sessions',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    return maps.map((m) => FocusSession.fromJson(m)).toList();
  }

  @override
  Future<void> saveFocusSession(FocusSession session) async {
    final db = await _dbService.database;
    await db.insert(
      'focus_sessions',
      session.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteFocusSession(String id) async {
    final db = await _dbService.database;
    await db.delete('focus_sessions', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteGoalRepository implements GoalRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<Goal>> getAllGoals() async {
    final db = await _dbService.database;
    final maps = await db.query('goals', orderBy: 'createdAt DESC');
    return maps.map((m) => Goal.fromJson(m)).toList();
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Goal.fromJson(maps.first);
  }

  @override
  Future<void> saveGoal(Goal goal) async {
    final db = await _dbService.database;
    final json = goal.toJson();
    final count = await db.update(
      'goals',
      json,
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    if (count == 0) {
      await db.insert('goals', json);
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete('goals', where: 'id = ?', whereArgs: [id]);
      await txn.delete('goal_habit_links', where: 'goalId = ?', whereArgs: [id]);
      await txn.delete('milestones', where: 'goalId = ?', whereArgs: [id]);
    });
  }

  @override
  Future<List<GoalHabitLink>> getAllGoalHabitLinks() async {
    final db = await _dbService.database;
    final maps = await db.query('goal_habit_links');
    return maps.map((m) => GoalHabitLink.fromJson(m)).toList();
  }

  @override
  Future<List<GoalHabitLink>> getLinksForGoal(String goalId) async {
    final db = await _dbService.database;
    final maps = await db.query('goal_habit_links', where: 'goalId = ?', whereArgs: [goalId]);
    return maps.map((m) => GoalHabitLink.fromJson(m)).toList();
  }

  @override
  Future<void> saveGoalHabitLink(GoalHabitLink link) async {
    final db = await _dbService.database;
    await db.insert(
      'goal_habit_links',
      link.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteGoalHabitLink(String linkId) async {
    final db = await _dbService.database;
    await db.delete('goal_habit_links', where: 'id = ?', whereArgs: [linkId]);
  }

  @override
  Future<List<Milestone>> getAllMilestones() async {
    final db = await _dbService.database;
    final maps = await db.query('milestones', orderBy: 'orderIndex ASC');
    return maps.map((m) => Milestone.fromJson(m)).toList();
  }

  @override
  Future<List<Milestone>> getMilestonesForGoal(String goalId) async {
    final db = await _dbService.database;
    final maps = await db.query('milestones', where: 'goalId = ?', whereArgs: [goalId], orderBy: 'orderIndex ASC');
    return maps.map((m) => Milestone.fromJson(m)).toList();
  }

  @override
  Future<void> saveMilestone(Milestone milestone) async {
    final db = await _dbService.database;
    await db.insert(
      'milestones',
      milestone.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteMilestone(String milestoneId) async {
    final db = await _dbService.database;
    await db.delete('milestones', where: 'id = ?', whereArgs: [milestoneId]);
  }
}

class SqliteJournalRepository implements JournalRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<JournalEntry>> getAllJournalEntries() async {
    final db = await _dbService.database;
    final maps = await db.query('journal_entries', orderBy: 'date DESC');
    return maps.map((m) => JournalEntry.fromJson(m)).toList();
  }

  @override
  Future<JournalEntry?> getEntryForDate(String dateStr) async {
    final db = await _dbService.database;
    final maps = await db.query('journal_entries', where: 'date = ?', whereArgs: [dateStr]);
    if (maps.isEmpty) return null;
    return JournalEntry.fromJson(maps.first);
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    final db = await _dbService.database;
    await db.insert(
      'journal_entries',
      entry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteEntry(String id) async {
    final db = await _dbService.database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteDailySummaryRepository implements DailySummaryRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<DailySummary>> getAllSummaries() async {
    final db = await _dbService.database;
    final maps = await db.query('daily_summaries', orderBy: 'date ASC');
    return maps.map((m) => DailySummary.fromJson(m)).toList();
  }

  @override
  Future<DailySummary?> getSummaryForDate(String dateStr) async {
    final db = await _dbService.database;
    final maps = await db.query('daily_summaries', where: 'date = ?', whereArgs: [dateStr]);
    if (maps.isEmpty) return null;
    return DailySummary.fromJson(maps.first);
  }

  @override
  Future<List<DailySummary>> getSummariesForRange(String startDate, String endDate) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'daily_summaries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => DailySummary.fromJson(m)).toList();
  }

  @override
  Future<void> saveSummary(DailySummary summary) async {
    final db = await _dbService.database;
    await db.insert(
      'daily_summaries',
      summary.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSummary(String dateStr) async {
    final db = await _dbService.database;
    await db.delete('daily_summaries', where: 'date = ?', whereArgs: [dateStr]);
  }
}

class SqlitePreferencesRepository implements PreferencesRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<UserPreferences> getPreferences() async {
    final db = await _dbService.database;
    final maps = await db.query('user_preferences');
    final Map<String, dynamic> prefsJson = {};
    for (final row in maps) {
      final key = row['key'] as String;
      final val = row['value'] as String;
      if (val == 'true') {
        prefsJson[key] = true;
      } else if (val == 'false') {
        prefsJson[key] = false;
      } else {
        prefsJson[key] = val;
      }
    }

    // Safety check for existing Phase 1-6 users:
    // If onboardingStatus is missing in user_preferences, but there is existing data in the DB,
    // default onboardingStatus to 'completed' so existing users are not interrupted.
    if (!prefsJson.containsKey('onboardingStatus')) {
      final habitsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM habits')) ?? 0;
      final activitiesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM activities')) ?? 0;
      final goalsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM goals')) ?? 0;
      final completionsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM habit_completions')) ?? 0;

      if (habitsCount > 0 || activitiesCount > 0 || goalsCount > 0 || completionsCount > 0) {
        prefsJson['onboardingStatus'] = 'completed';
      }
    }

    return UserPreferences.fromJson(prefsJson);
  }

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    final db = await _dbService.database;
    final json = preferences.toJson();
    await db.transaction((txn) async {
      for (final entry in json.entries) {
        await txn.insert(
          'user_preferences',
          {'key': entry.key, 'value': entry.value.toString()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

class SqliteAchievementRepository implements AchievementRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<Map<String, String>> getEarnedAchievementsMap() async {
    final db = await _dbService.database;
    final maps = await db.query('earned_achievements');
    final Map<String, String> res = {};
    for (final row in maps) {
      res[row['id'] as String] = row['earnedAt'] as String;
    }
    return res;
  }

  @override
  Future<void> saveEarnedAchievement(String id, String earnedAt) async {
    final db = await _dbService.database;
    await db.insert(
      'earned_achievements',
      {'id': id, 'earnedAt': earnedAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearEarnedAchievements() async {
    final db = await _dbService.database;
    await db.delete('earned_achievements');
  }
}

class SqliteBackupRepository implements BackupRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<Map<String, dynamic>> exportAllDataJson() async {
    final db = await _dbService.database;
    final habits = await db.query('habits');
    final habitCompletions = await db.query('habit_completions');
    final activities = await db.query('activities');
    final focusSessions = await db.query('focus_sessions');
    final goals = await db.query('goals');
    final goalLinks = await db.query('goal_habit_links');
    final milestones = await db.query('milestones');
    final journalEntries = await db.query('journal_entries');
    final dailySummaries = await db.query('daily_summaries');
    final prefs = await db.query('user_preferences');
    final earnedAchievements = await db.query('earned_achievements');

    final metadata = BackupMetadata(
      appVersion: '1.0.0',
      exportedAt: DateTime.now().toIso8601String(),
      totalHabits: habits.length,
      totalCompletions: habitCompletions.length,
      totalActivities: activities.length,
      totalGoals: goals.length,
      totalFocusSessions: focusSessions.length,
      totalJournalEntries: journalEntries.length,
    );

    return {
      'metadata': metadata.toJson(),
      'user_preferences': prefs,
      'habits': habits,
      'habit_completions': habitCompletions,
      'activities': activities,
      'focus_sessions': focusSessions,
      'goals': goals,
      'goal_habit_links': goalLinks,
      'milestones': milestones,
      'journal_entries': journalEntries,
      'daily_summaries': dailySummaries,
      'earned_achievements': earnedAchievements};
  }

  @override
  Future<void> importAllDataJson(Map<String, dynamic> jsonData) async {
    // 1. Structural & Type Validation BEFORE modifying database
    if (jsonData.isEmpty) {
      throw const FormatException('Backup data is empty.');
    }

    final metadataJson = jsonData['metadata'];
    if (metadataJson is! Map) {
      throw const FormatException('Backup metadata section is missing or invalid.');
    }

    final metadata = BackupMetadata.fromJson(Map<String, dynamic>.from(metadataJson));
    if (metadata.backupVersion > 1) {
      throw FormatException(
        'Unsupported backup format version: ${metadata.backupVersion}. This version of Pace supports backup format version 1.',
      );
    }

    const validTables = [
      'user_preferences',
      'habits',
      'habit_completions',
      'activities',
      'focus_sessions',
      'goals',
      'goal_habit_links',
      'milestones',
      'journal_entries',
      'daily_summaries',
      'earned_achievements',
    ];

    for (final tableKey in validTables) {
      if (jsonData.containsKey(tableKey)) {
        final val = jsonData[tableKey];
        if (val is! List) {
          throw FormatException('Backup table "$tableKey" must be a list.');
        }
        for (final row in val) {
          if (row is! Map) {
            throw FormatException('Malformed row in backup table "$tableKey".');
          }
        }
      }
    }

    // 2. Perform atomic replacement within a SQLite transaction
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Clear existing tables
      await txn.delete('user_preferences');
      await txn.delete('habits');
      await txn.delete('habit_completions');
      await txn.delete('activities');
      await txn.delete('focus_sessions');
      await txn.delete('goals');
      await txn.delete('goal_habit_links');
      await txn.delete('milestones');
      await txn.delete('journal_entries');
      await txn.delete('daily_summaries');
      await txn.delete('earned_achievements');

      void restoreTable(String tableName, String keyInJson) {
        if (jsonData[keyInJson] is List) {
          for (final row in (jsonData[keyInJson] as List)) {
            txn.insert(tableName, Map<String, dynamic>.from(row as Map),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      restoreTable('user_preferences', 'user_preferences');
      restoreTable('habits', 'habits');
      restoreTable('habit_completions', 'habit_completions');
      restoreTable('activities', 'activities');
      restoreTable('focus_sessions', 'focus_sessions');
      restoreTable('goals', 'goals');
      restoreTable('goal_habit_links', 'goal_habit_links');
      restoreTable('milestones', 'milestones');
      restoreTable('journal_entries', 'journal_entries');
      restoreTable('daily_summaries', 'daily_summaries');
      restoreTable('earned_achievements', 'earned_achievements');
    });
  }

  @override
  Future<String> exportCsvData() async {
    final db = await _dbService.database;
    final activities = await db.query('activities', orderBy: 'date DESC');
    final buffer = StringBuffer();
    buffer.writeln('ID,Date,Title,Category,DurationMinutes,Quantity,Unit,Source');
    for (final row in activities) {
      buffer.writeln(
        '${row['id']},${row['date']},"${row['title']}",${row['category']},${row['durationMinutes']},${row['quantity']},${row['unit']},${row['source']}',
      );
    }
    return buffer.toString();
  }
}
