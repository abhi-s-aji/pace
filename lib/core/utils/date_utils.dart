import 'package:intl/intl.dart';

/// Centralized Date and Time Domain Utilities for Pace.
/// Ensures consistent date string formatting, day boundary calculations,
/// streak day matching, and calendar generation without scattering logic.
abstract class PaceDateUtils {
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _readableMonthDay = DateFormat('MMM d');
  static final DateFormat _fullDate = DateFormat('MMMM d, yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  /// Formats a DateTime into canonical ISO 'YYYY-MM-DD' key for database and daily summaries
  static String toIsoDateString(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Parses 'YYYY-MM-DD' key back into local midnight DateTime
  static DateTime parseIsoDateString(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return normalizeDate(DateTime.now());
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Truncates time components to return local midnight (00:00:00)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns today at local midnight
  static DateTime today() {
    return normalizeDate(DateTime.now());
  }

  /// Returns true if two dates represent the exact same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if date is in the future relative to today
  static bool isFuture(DateTime date) {
    return normalizeDate(date).isAfter(today());
  }

  /// Returns relative readable label like "Today", "Yesterday", or "Oct 1"
  static String formatRelativeDate(DateTime date) {
    final norm = normalizeDate(date);
    final now = today();
    final diff = now.difference(norm).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return _readableMonthDay.format(date);
  }

  /// Returns full readable date like "September 30, 2026"
  static String formatFullDate(DateTime date) {
    return _fullDate.format(date);
  }

  /// Returns Month & Year like "October 2026"
  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  /// Gets the weekday index with Monday = 0 .. Sunday = 6
  static int getMondayBasedWeekday(DateTime date) {
    return date.weekday - 1; // DateTime.monday is 1
  }

  /// Calculates start of week (Monday or Sunday based on [firstDayIsMonday])
  static DateTime startOfWeek(DateTime date, {bool firstDayIsMonday = true}) {
    final norm = normalizeDate(date);
    final weekday = norm.weekday; // 1 = Mon, 7 = Sun
    if (firstDayIsMonday) {
      return norm.subtract(Duration(days: weekday - 1));
    } else {
      final daysToSub = weekday == 7 ? 0 : weekday;
      return norm.subtract(Duration(days: daysToSub));
    }
  }

  /// Returns a 52-week or 365-day grid range of dates for the contribution graph,
  /// ending today (or at the end of current week) and starting ~52 weeks ago.
  static List<DateTime> generateContributionDateGrid({
    DateTime? endDate,
    int weeksCount = 52,
    bool firstDayIsMonday = true}) {
    final end = normalizeDate(endDate ?? DateTime.now());
    // Align end to the end of the current week (Sunday if Mon-first, Saturday if Sun-first)
    final daysUntilEndOfWeek = firstDayIsMonday ? (7 - end.weekday) : (6 - (end.weekday % 7));
    final gridEnd = end.add(Duration(days: daysUntilEndOfWeek));
    
    // Total days = weeksCount * 7
    final totalDays = weeksCount * 7;
    final gridStart = gridEnd.subtract(Duration(days: totalDays - 1));

    final List<DateTime> dates = [];
    for (int i = 0; i < totalDays; i++) {
      dates.add(gridStart.add(Duration(days: i)));
    }
    return dates;
  }
}
