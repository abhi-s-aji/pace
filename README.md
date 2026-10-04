# Pace — Personal Consistency & Progress App

> **Small actions. Real progress.**

Pace is a calm, minimal, local-first mobile application designed to help individuals build consistency, focus on intentional habits, achieve evidence-based goals, and record long-term progress.

---

## 🌟 Product Principles

1. **Local-First & Offline**: All user data is stored locally in an SQLite database. Pace operates completely offline without requiring accounts, cloud subscriptions, or network connectivity.
2. **Privacy-Focused**: Zero telemetry, zero analytics SDKs, zero advertising trackers. Your habit completions, focus sessions, and journal entries remain strictly on your device.
3. **Evidence-Based Progress**: Goal progress and achievement badges derive from factual records (completed habits, logged focus minutes, and verified milestones) rather than arbitrary manual percentage sliders or pressure tactics.
4. **Calm & Non-Manipulative**: No streak pressure, no gamified coins/XP, no social feed mechanics, and no manipulative push notifications.

---

## 🏗️ Technical Architecture

Pace follows a strict single-source-of-truth architecture powered by Flutter and Riverpod:

```text
UI (Views & Bottom Sheets)
  ↓
PaceAppNotifier (Riverpod Master Notifier)
  ↓
Domain Repositories (SqliteRepositories)
  ↓
SQLite Local Database (DatabaseService with foreign keys enabled)
  ↓
Derived State Engines (ConsistencyEngine, StatisticsEngine, GoalEngine, AchievementEngine)
  ↓
Reactive UI Rebuilds
```

* **Persistence Layer**: SQLite database (`sqflite` on Android/iOS, `sqflite_common_ffi` on Linux/macOS/Windows desktop).
* **State Management**: Riverpod (`flutter_riverpod`).
* **Charts & Visualizations**: `fl_chart` responsive canvas widgets and custom GitHub-style `ContributionCalendarWidget`.
* **Notifications**: `flutter_local_notifications` for local Android/iOS reminder scheduling.

---

## 🔒 Backup & Restore Format

Pace supports full JSON backup export and import:
* **Format Version**: `backupVersion: 1`
* **Transactional Safety**: Imports are validated for structural integrity and JSON type safety before wiping local tables. If validation fails, the transaction rolls back cleanly, preserving existing user data.
* **Device Independence**: System OS notification IDs and volatile UI states are stripped during export and re-derived on restore.

---

## 🚀 Building and Running Pace

### Prerequisites
* Flutter SDK (`^3.12.0` or later)
* Android SDK (for Android builds) or C/C++ build tools (for Linux desktop builds)

### 1. Run Automated Tests
```bash
flutter test
```

### 2. Run Static Analyzer
```bash
flutter analyze
```

### 3. Build Android Release APK
```bash
flutter build apk --release
```

### 4. Build Linux Desktop Release
```bash
flutter build linux --release
```

---

## 📋 Definition of Verification

```text
flutter test   -> 41 tests passing (100% coverage across domain engines, SQLite transactions, backups, notifications, and widget semantics)
flutter analyze -> 0 errors, 0 warnings, 0 infos
```

---

## ⚠️ Known Platform Limitations

1. **System Notification Schedules**: Local Android notification delivery requires exact alarm permissions (`SCHEDULE_EXACT_ALARM`) and post-notification permissions (`POST_NOTIFICATIONS`) on Android 13+. Disabling system notification permissions in OS settings pauses reminders without breaking core local app usage.
2. **Timezone Travel**: Daily summaries and contribution calendars bucket activities according to local midnight (`YYYY-MM-DD`). Changing device timezones across international date lines mid-day will categorize activities under the local date key active when recorded.
