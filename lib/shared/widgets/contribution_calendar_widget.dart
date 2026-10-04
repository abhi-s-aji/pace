import 'package:flutter/material.dart';
import '../../core/domain/models/models.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';

/// GitHub-Style Contribution Calendar for Pace.
/// Renders 7 weekday rows x 52 weekly columns.
/// Fully interactive with accessibility labels, month headers,
/// level 0..4 intensity styling, today indicator, and tap handlers.
class ContributionCalendarWidget extends StatelessWidget {
  final Map<String, DailySummary> dailySummaries;
  final bool firstDayIsMonday;
  final Function(DateTime date, DailySummary? summary)? onDateSelected;
  final DateTime? selectedDate;

  const ContributionCalendarWidget({
    super.key,
    required this.dailySummaries,
    this.firstDayIsMonday = true,
    this.onDateSelected,
    this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final gridDates = PaceDateUtils.generateContributionDateGrid(
      weeksCount: 52,
      firstDayIsMonday: firstDayIsMonday,
    );

    final colors = PaceColors.contributionLevelsLight;

    // Group dates into columns (weeks of 7 days)
    final List<List<DateTime>> weeks = [];
    for (int i = 0; i < gridDates.length; i += 7) {
      weeks.add(gridDates.sublist(i, i + 7));
    }

    // Build month labels
    final List<Widget> monthHeaders = _buildMonthHeaders(weeks);

    final weekdays = firstDayIsMonday
        ? ['M', 'T', 'W', 'T', 'F', 'Sa', 'Su']
        : ['Su', 'M', 'T', 'W', 'T', 'F', 'Sa'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Title & Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.grid_on_rounded, size: 18, color: PaceColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Consistency Map',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: PaceColors.lightTextMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      tooltip: 'About Consistency Map',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('About Consistency Map'),
                            content: const Text(
                              'Each day on the map reflects the amount of real activity you recorded.\n\n'
                              '• Intensity represents total completed habits, focus time, and logged activities.\n'
                              '• Missed days remain part of your history—Pace measures overall consistency over time without pressure or penalties.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Understood'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Legend 0 .. 4
                Row(
                  children: [
                    Text(
                      'Less',
                      style: TextStyle(
                        fontSize: 10,
                        color: PaceColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ...List.generate(5, (level) {
                      return Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: colors[level],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      'More',
                      style: TextStyle(
                        fontSize: 10,
                        color: PaceColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // Scroll to end (today) by default
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Labels Row
                  Row(
                    children: [
                      const SizedBox(width: 20), // Spacer for weekday column
                      ...monthHeaders,
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Calendar Grid Row (Weekday labels + Week columns)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekday Labels Column
                      Column(
                        children: List.generate(7, (idx) {
                          return SizedBox(
                            width: 16,
                            height: 14,
                            child: Center(
                              child: Text(
                                weekdays[idx],
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: PaceColors.lightTextMuted,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 4),

                      // Weeks Grid Columns
                      ...weeks.map((week) {
                        return Column(
                          children: week.map((date) {
                            final isoStr = PaceDateUtils.toIsoDateString(date);
                            final summary = dailySummaries[isoStr];
                            final level = summary?.contributionLevel ?? 0;
                            final isFuture = PaceDateUtils.isFuture(date);
                            final isToday = PaceDateUtils.isSameDay(date, DateTime.now());
                            final isSelected = selectedDate != null &&
                                PaceDateUtils.isSameDay(date, selectedDate!);

                            Color cellColor;
                            if (isFuture) {
                              cellColor = PaceColors.lightBackground;
                            } else {
                              cellColor = colors[level];
                            }

                            final tooltipMsg = isFuture
                                ? '${PaceDateUtils.formatFullDate(date)} (Future)'
                                : '${PaceDateUtils.formatFullDate(date)}: ${summary?.totalActivities ?? 0} activities, ${summary?.habitsCompleted ?? 0} habits completed (${summary?.completionPercentage.toInt() ?? 0}%).';

                            return Tooltip(
                              message: tooltipMsg,
                              child: Semantics(
                                label: tooltipMsg,
                                button: true,
                                child: InkWell(
                                  onTap: isFuture
                                      ? null
                                      : () => onDateSelected?.call(date, summary),
                                  borderRadius: BorderRadius.circular(3),
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: cellColor,
                                      borderRadius: BorderRadius.circular(2.5),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : (isToday
                                                ? PaceColors.primaryLight
                                                : (isFuture
                                                    ? (PaceColors.lightBorder)
                                                    : Colors.transparent)),
                                        width: isSelected ? 1.5 : (isToday ? 1.2 : 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMonthHeaders(List<List<DateTime>> weeks) {
    final List<Widget> headers = [];
    String? currentMonth;
    int currentSpan = 0;

    for (int i = 0; i < weeks.length; i++) {
      final firstDayOfWeek = weeks[i].first;
      final monthName = _monthAbbrev(firstDayOfWeek.month);

      if (monthName != currentMonth) {
        if (currentMonth != null) {
          headers.add(
            SizedBox(
              width: currentSpan * 14.0,
              child: Text(
                currentMonth,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: PaceColors.lightTextMuted,
                ),
              ),
            ),
          );
        }
        currentMonth = monthName;
        currentSpan = 1;
      } else {
        currentSpan++;
      }
    }

    if (currentMonth != null) {
      headers.add(
        SizedBox(
          width: currentSpan * 14.0,
          child: Text(
            currentMonth,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: PaceColors.lightTextMuted,
            ),
          ),
        ),
      );
    }

    return headers;
  }

  String _monthAbbrev(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
