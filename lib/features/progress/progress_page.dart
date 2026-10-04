import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/models/models.dart';
import '../../core/domain/calculators/statistics_engine.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/achievement_detail_sheet.dart';
import '../../shared/widgets/continuous_line_graph.dart';
import '../../shared/widgets/contribution_calendar_widget.dart';
import '../../shared/widgets/day_detail_modal.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/stat_card.dart';
import '../history/activity_history_page.dart';

enum ProgressViewMode { stats, trends, history, achievements }

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  DateRangeFilter _selectedRange = DateRangeFilter.thirtyDays;
  ProgressViewMode _viewMode = ProgressViewMode.stats;
  String _selectedCategory = 'All';

  static const _categories = [
    'All',
    'Getting Started',
    'Consistency',
    'Habits',
    'Focus',
    'Goals',
    'History',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paceAppProvider);

    final stats = StatisticsEngine.calculate(
      range: _selectedRange,
      habits: state.habits,
      completions: state.completions,
      activities: state.activities,
      focusSessions: state.focusSessions,
      dailySummaries: state.dailySummaries,
    );

    final allAchievements = state.achievements;
    final earnedCount = allAchievements.where((a) => a.isEarned).length;
    final totalAchCount = allAchievements.length;

    final filteredAchievements = _selectedCategory == 'All'
        ? allAchievements
        : allAchievements.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Page Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress & Stats',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.8,
                            color: PaceColors.primary,
                          ),
                        ),
                        if (_viewMode == ProgressViewMode.stats || _viewMode == ProgressViewMode.trends)
                          DropdownButton<DateRangeFilter>(
                            value: _selectedRange,
                            underline: const SizedBox(),
                            dropdownColor: PaceColors.lightSurface,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                            items: DateRangeFilter.values.map((r) {
                              return DropdownMenuItem<DateRangeFilter>(
                                value: r,
                                child: Text(
                                  r.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PaceColors.lightTextPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedRange = val);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // View Mode Switcher
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SegmentedButton<ProgressViewMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ProgressViewMode.stats,
                            label: Text('Stats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            icon: Icon(Icons.bar_chart_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ProgressViewMode.trends,
                            label: Text('Trends', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            icon: Icon(Icons.trending_up_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ProgressViewMode.history,
                            label: Text('History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            icon: Icon(Icons.history_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ProgressViewMode.achievements,
                            label: Text('Achievements', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            icon: Icon(Icons.stars_rounded, size: 16),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (val) => setState(() => _viewMode = val.first),
                        style: ButtonStyle(
                          side: WidgetStateProperty.all(
                            BorderSide(color: PaceColors.lightBorder),
                          ),
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return PaceColors.primary.withValues(alpha: 0.15);
                            }
                            return null;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return PaceColors.primary;
                            }
                            return null;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_viewMode == ProgressViewMode.stats) ...[
              // --- STATS VIEW ---
              // Consistency Stats Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Current Streak',
                              value: '${stats.currentStreak}',
                              subtitle: stats.currentStreak == 0 ? 'Start today' : 'day${stats.currentStreak == 1 ? '' : 's'} active',
                              icon: Icons.repeat_rounded,
                              iconColor: PaceColors.primary,
                              ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Best Streak',
                              value: '${stats.bestStreak}',
                              subtitle: 'day${stats.bestStreak == 1 ? '' : 's'} record',
                              icon: Icons.emoji_events_rounded,
                              iconColor: PaceColors.secondary,
                              ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Active Days',
                              value: '${stats.activeDays}',
                              subtitle: 'total active days',
                              icon: Icons.calendar_today_rounded,
                              iconColor: PaceColors.primary,
                              ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Activities',
                              value: '${stats.totalActivities}',
                              subtitle: 'meaningful actions',
                              icon: Icons.timeline_rounded,
                              iconColor: PaceColors.success,
                              ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Focus Analytics Breakdown
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Focus Analytics',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: PaceColors.lightTextPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: PaceColors.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${stats.activeFocusDays} active focus days',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: PaceColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailMetric(
                                  label: 'Total Focus',
                                  value: _formatFocusTime(stats.totalFocusMinutes),
                                  ),
                              ),
                              Expanded(
                                child: _buildDetailMetric(
                                  label: 'Total Sessions',
                                  value: '${stats.totalFocusSessions}',
                                  ),
                              ),
                              Expanded(
                                child: _buildDetailMetric(
                                  label: 'Avg Duration',
                                  value: '${stats.avgFocusSessionMinutes.toInt()}m',
                                  ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Per-Habit Breakdown Section
              if (stats.habitBreakdown.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      'Habit Performance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: PaceColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final h = stats.habitBreakdown[index];
                        final pct = h.completionRatePercentage.clamp(0.0, 100.0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: PaceColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.check_circle_rounded, size: 18, color: PaceColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      Text(
                                        '${h.completionsCount} completed (${pct.toInt()}%)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: PaceColors.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct / 100.0,
                                      minHeight: 6,
                                      backgroundColor: PaceColors.lightSurfaceElevated,
                                      valueColor: AlwaysStoppedAnimation<Color>(PaceColors.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: stats.habitBreakdown.length,
                    ),
                  ),
                ),
              ],
            ] else if (_viewMode == ProgressViewMode.trends) ...[
              // --- TRENDS VIEW ---
              // Activity Trend Visualization (Stock-Market-Style Continuous Line Graph)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Progress Graph',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: PaceColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Tap point to view day',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PaceColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ContinuousLineGraph(
                            trends: stats.dailyTrends,
                            onViewDay: (date) {
                              final dateStr = PaceDateUtils.toIsoDateString(date);
                              final summary = state.dailySummaries[dateStr] ??
                                  DailySummary(
                                    date: dateStr,
                                    updatedAt: DateTime.now().toIso8601String(),
                                  );
                              ref.read(paceAppProvider.notifier).selectDate(date);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => DraggableScrollableSheet(
                                  initialChildSize: 0.65,
                                  minChildSize: 0.4,
                                  maxChildSize: 0.9,
                                  builder: (_, controller) => DayDetailModal(
                                    date: date,
                                    summary: summary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Contribution Calendar Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: ContributionCalendarWidget(
                    dailySummaries: state.dailySummaries,
                    firstDayIsMonday: state.preferences.firstDayIsMonday,
                    selectedDate: state.selectedDate,
                    onDateSelected: (date, summary) {
                      ref.read(paceAppProvider.notifier).selectDate(date);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.65,
                          minChildSize: 0.4,
                          maxChildSize: 0.9,
                          builder: (_, controller) => DayDetailModal(
                            date: date,
                            summary: summary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else if (_viewMode == ProgressViewMode.history) ...[
              // --- HISTORY VIEW ---
              SliverFillRemaining(
                hasScrollBody: true,
                child: const ActivityHistoryPage(),
              ),
            ] else ...[
              // --- ACHIEVEMENTS VIEW ---

              // Achievements Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PaceColors.secondary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.emoji_events_rounded, size: 28, color: PaceColors.secondary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Achievements',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.4,
                                    color: PaceColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Small milestones that reflect the progress you\'ve actually made.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: PaceColors.lightTextSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: PaceColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$earnedCount of $totalAchCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: PaceColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Category Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          selectedColor: PaceColors.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? PaceColors.primary
                                : (PaceColors.lightTextSecondary),
                          ),
                          side: BorderSide(
                            color: selected
                                ? PaceColors.primary.withValues(alpha: 0.5)
                                : (PaceColors.lightBorder),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (filteredAchievements.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.stars_outlined,
                      title: 'Your progress will appear here',
                      message: 'Keep using Pace for the things that matter to you.',
                      ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ach = filteredAchievements[index];
                        final isEarned = ach.isEarned;
                        final iconData = getAchievementIconData(ach.icon);

                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: isEarned ? 1 : 0,
                          color: isEarned
                              ? PaceColors.lightSurface
                              : PaceColors.lightSurfaceElevated.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isEarned
                                  ? PaceColors.secondary.withValues(alpha: 0.4)
                                  : PaceColors.lightBorder,
                              width: isEarned ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AchievementDetailSheet(
                                  achievement: ach,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isEarned
                                          ? PaceColors.secondary.withValues(alpha: 0.15)
                                          : PaceColors.lightSurfaceElevated,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isEarned
                                            ? PaceColors.secondary
                                            : PaceColors.lightBorder,
                                        width: isEarned ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      iconData,
                                      size: 22,
                                      color: isEarned
                                          ? PaceColors.secondary
                                          : PaceColors.lightTextMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ach.title,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isEarned ? FontWeight.bold : FontWeight.w500,
                                      color: isEarned
                                          ? PaceColors.lightTextPrimary
                                          : PaceColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredAchievements.length,
                    ),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailMetric({
    required String label,
    required String value,
    }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: PaceColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: PaceColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  String _formatFocusTime(int minutes) {
    if (minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}
