import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database Service providing local persistent SQLite storage
/// with table migrations, transactions, and desktop/mobile support.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Linux / Windows / macOS desktop
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'pace_database.db';
    } else {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        path = join(docsDir.path, 'pace_app_v1.db');
      } catch (_) {
        path = inMemoryDatabasePath;
      }
    }

    return await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. User Preferences
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 2. Habits
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        icon TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        habitType TEXT NOT NULL,
        targetValue REAL NOT NULL,
        targetUnit TEXT,
        frequency TEXT NOT NULL,
        selectedWeekdays TEXT NOT NULL,
        reminderTime TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT,
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_habits_archived ON habits(isArchived);');

    // 3. Habit Completions
    await db.execute('''
      CREATE TABLE habit_completions (
        id TEXT PRIMARY KEY,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        value REAL NOT NULL,
        targetValue REAL NOT NULL,
        isCompleted INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_completions_habit_date ON habit_completions(habitId, date);');
    await db.execute('CREATE INDEX idx_completions_date ON habit_completions(date);');

    // 4. Activities
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        habitId TEXT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL DEFAULT 0,
        quantity REAL NOT NULL DEFAULT 0,
        unit TEXT,
        date TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        notes TEXT,
        source TEXT NOT NULL DEFAULT 'manual'
      )
    ''');
    await db.execute('CREATE INDEX idx_activities_date ON activities(date);');

    // 5. Focus Sessions
    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        habitId TEXT,
        title TEXT NOT NULL,
        targetDurationMinutes INTEGER NOT NULL,
        actualDurationMinutes INTEGER NOT NULL,
        date TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_focus_date ON focus_sessions(date);');

    // 6. Goals
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        startDate TEXT,
        targetDate TEXT NOT NULL,
        category TEXT NOT NULL,
        targetValue REAL NOT NULL DEFAULT 0.0,
        targetUnit TEXT DEFAULT '',
        isCompleted INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0,
        calculatedProgress REAL NOT NULL DEFAULT 0.0,
        reminderEnabled INTEGER NOT NULL DEFAULT 0,
        reminderTime TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 7. Goal Habit Links
    await db.execute('''
      CREATE TABLE goal_habit_links (
        id TEXT PRIMARY KEY,
        goalId TEXT NOT NULL,
        habitId TEXT NOT NULL,
        weight REAL NOT NULL DEFAULT 1.0,
        FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
        FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // 8. Milestones
    await db.execute('''
      CREATE TABLE milestones (
        id TEXT PRIMARY KEY,
        goalId TEXT NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        targetDate TEXT NOT NULL,
        orderIndex INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    // 9. Journal Entries
    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        date TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        mood TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_journal_date ON journal_entries(date);');

    // 10. Daily Summaries
    await db.execute('''
      CREATE TABLE daily_summaries (
        date TEXT PRIMARY KEY,
        totalActivities INTEGER NOT NULL DEFAULT 0,
        habitsCompleted INTEGER NOT NULL DEFAULT 0,
        totalHabitsScheduled INTEGER NOT NULL DEFAULT 0,
        totalFocusMinutes INTEGER NOT NULL DEFAULT 0,
        completionPercentage REAL NOT NULL DEFAULT 0.0,
        contributionScore REAL NOT NULL DEFAULT 0.0,
        contributionLevel INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT NOT NULL
      )
    ''');

    // 11. Earned Achievements
    await db.execute('''
      CREATE TABLE earned_achievements (
        id TEXT PRIMARY KEY,
        earnedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE goals ADD COLUMN startDate TEXT DEFAULT '';");
      await db.execute("ALTER TABLE goals ADD COLUMN targetValue REAL NOT NULL DEFAULT 0.0;");
      await db.execute("ALTER TABLE goals ADD COLUMN targetUnit TEXT DEFAULT '';");
      await db.execute("ALTER TABLE goals ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0;");
      await db.execute("ALTER TABLE milestones ADD COLUMN orderIndex INTEGER NOT NULL DEFAULT 0;");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE goals ADD COLUMN reminderEnabled INTEGER NOT NULL DEFAULT 0;");
      await db.execute("ALTER TABLE goals ADD COLUMN reminderTime TEXT;");
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS earned_achievements (
          id TEXT PRIMARY KEY,
          earnedAt TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> clearAllTables() async {
    final db = await database;
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
      await txn.delete('user_preferences');
      await txn.delete('earned_achievements');
    });
  }
}
