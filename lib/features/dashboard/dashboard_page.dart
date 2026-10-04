import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/completion_note_dialog.dart';
import '../../shared/widgets/contribution_calendar_widget.dart';
import '../../shared/widgets/day_detail_modal.dart';
import '../../shared/widgets/habit_tile.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/item_note_dialog.dart';
import '../journal/journal_editor_sheet.dart';
import '../goals/goals_page.dart';
import '../goals/goal_detail_sheet.dart';
import '../habits/create_habit_sheet.dart';
import '../settings/settings_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paceAppProvider);
    final today = PaceDateUtils.today();
    final todayStr = PaceDateUtils.toIsoDateString(today);

    final activeHabits = state.habits.where((h) => !h.isArchived && h.isScheduledForDay(today)).toList();
    final todayCompletions = state.completions.where((c) => c.date == todayStr).toList();
    final completedCount = todayCompletions.where((c) => c.isCompleted).length;
    final totalScheduled = activeHabits.length;
    final todayPct = totalScheduled > 0 ? ((completedCount / totalScheduled) * 100.0).clamp(0.0, 100.0) : 0.0;
    final stats = state.consistencyStats;

    final greeting = _buildGreeting(state.preferences.userName);

    return Scaffold(
      body: SafeArea(
        child: state.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(PaceColors.primary),
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Greeting Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: PaceColors.lightTextMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.preferences.userName,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsPage()),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PaceColors.lightSurfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: PaceColors.lightBorder),
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                size: 20,
                                color: PaceColors.lightTextSecondary,
                              ),
                            ),
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Today's Progress Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Today\'s Progress',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: PaceColors.lightTextSecondary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: todayPct >= 100
                                          ? PaceColors.success.withValues(alpha: 0.15)
                                          : PaceColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$completedCount / $totalScheduled habits',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: todayPct >= 100 ? PaceColors.success : PaceColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  // Progress Ring
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: CircularProgressIndicator(
                                            value: todayPct / 100.0,
                                            strokeWidth: 6,
                                            strokeCap: StrokeCap.round,
                                            backgroundColor: PaceColors.lightSurfaceElevated,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              todayPct >= 100 ? PaceColors.success : PaceColors.primary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${todayPct.toInt()}%',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildMiniStat(
                                          icon: Icons.repeat_rounded,
                                          label: 'Current streak',
                                          value: '${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'}',
                                          color: PaceColors.primary,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildMiniStat(
                                          icon: Icons.emoji_events_rounded,
                                          label: 'Best streak',
                                          value: '${stats.bestStreak} day${stats.bestStreak == 1 ? '' : 's'}',
                                          color: PaceColors.secondary,
                                          ),
                                        const SizedBox(height: 8),
                                        _buildMiniStat(
                                          icon: Icons.calendar_today_rounded,
                                          label: 'Active days',
                                          value: '${stats.activeDays}',
                                          color: PaceColors.primary,
                                          ),
                                      ],
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

                  // Consistency Stats Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Weekly',
                              value: '${stats.weeklyCompletionPercentage.toInt()}%',
                              subtitle: 'consistency',
                              icon: Icons.calendar_view_week_rounded,
                              iconColor: PaceColors.primary,
                              ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Monthly',
                              value: '${stats.monthlyCompletionPercentage.toInt()}%',
                              subtitle: 'consistency',
                              icon: Icons.date_range_rounded,
                              iconColor: PaceColors.secondary,
                              ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Focus',
                              value: _formatFocusTime(stats.totalFocusMinutes),
                              subtitle: 'total focused',
                              icon: Icons.timer_rounded,
                              iconColor: PaceColors.accentGold,
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Contribution Calendar
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

                  // Today's Habits Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Habits',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                              color: PaceColors.lightTextPrimary,
                            ),
                          ),
                          if (activeHabits.isNotEmpty)
                            Text(
                              '$completedCount of $totalScheduled',
                              style: TextStyle(
                                fontSize: 13,
                                color: PaceColors.lightTextMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (activeHabits.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.playlist_add_check_rounded,
                        title: 'No habits yet',
                        message: 'Create your first habit to start tracking your daily consistency.',
                        ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final habit = activeHabits[index];
                            final completion = todayCompletions.cast<HabitCompletion?>().firstWhere(
                                  (c) => c?.habitId == habit.id,
                                  orElse: () => null,
                                );

                            return HabitTile(
                              habit: habit,
                              completion: completion,
                              onToggle: () async {
                                final notifier = ref.read(paceAppProvider.notifier);
                                if (completion?.isCompleted ?? false) {
                                  await notifier.uncompleteHabit(habit.id, todayStr);
                                } else {
                                  String? note;
                                  if (state.preferences.completionNotePreference == 'ask') {
                                    final res = await CompletionNoteDialog.show(
                                      context,
                                      title: 'Complete ${habit.name}',
                                    );
                                    if (res == null) return;
                                    note = res.note;
                                    if (res.dontAskAgain) {
                                      await notifier.updatePreferences(
                                        state.preferences.copyWith(completionNotePreference: 'dont_ask'),
                                      );
                                    }
                                  }
                                  await notifier.completeHabit(habit.id, todayStr, note: note);
                                }
                              },
                              onTap: () => _showHabitDetailsModal(context, ref, habit),
                            );
                          },
                          childCount: activeHabits.length,
                        ),
                      ),
                    ),

                  // Active Goals Preview
                  if (state.goals.where((g) => !g.isCompleted && !g.isArchived).isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Goals',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: PaceColors.lightTextPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const GoalsPage()),
                                );
                              },
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final activeGoals = state.goals.where((g) => !g.isCompleted && !g.isArchived).toList();
                            final goal = activeGoals[index];
                            final progress = goal.calculatedProgress.clamp(0.0, 1.0);
                            final progressPct = (progress * 100).toInt();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => GoalDetailSheet(goal: goal),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: PaceColors.secondary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.flag_rounded, size: 18, color: PaceColors.secondary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              goal.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 5,
                                                backgroundColor: PaceColors.lightSurfaceElevated,
                                                valueColor: AlwaysStoppedAnimation<Color>(PaceColors.secondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '$progressPct%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: PaceColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: state.goals.where((g) => !g.isCompleted && !g.isArchived).length.clamp(0, 5),
                        ),
                      ),
                    ),
                  ],

                  // TODAY'S NOTE Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Note',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                              color: PaceColors.lightTextPrimary,
                            ),
                          ),
                          Builder(builder: (ctx) {
                            final todayNote = state.journalEntries.cast<JournalEntry?>().firstWhere(
                                  (j) => j?.date == todayStr,
                                  orElse: () => null,
                                );
                            return TextButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: ctx,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => JournalEditorSheet(
                                    date: today,
                                    existingEntry: todayNote,
                                  ),
                                );
                              },
                              icon: Icon(todayNote == null ? Icons.add_rounded : Icons.edit_rounded, size: 16),
                              label: Text(todayNote == null ? 'Add a note' : 'Edit'),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Builder(builder: (context) {
                        final todayNote = state.journalEntries.cast<JournalEntry?>().firstWhere(
                              (j) => j?.date == todayStr,
                              orElse: () => null,
                            );

                        return Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => JournalEditorSheet(
                                  date: today,
                                  existingEntry: todayNote,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: todayNote == null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'No note for today.',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: PaceColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Capture a thought, reflection or something you want to remember.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: PaceColors.lightTextMuted,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                todayNote.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: PaceColors.primary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                todayNote.mood.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: PaceColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          todayNote.content,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: PaceColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Bottom Padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  Widget _buildMiniStat({
    IconData? icon,
    required String label,
    required String value,
    Color? color,
    }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color ?? PaceColors.primary),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: PaceColors.lightTextMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _formatFocusTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  void _showHabitDetailsModal(BuildContext context, WidgetRef ref, Habit habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: PaceColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaceColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: PaceColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PaceColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      habit.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PaceColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Frequency: ${habit.frequency.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: PaceColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              if (habit.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  habit.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: PaceColors.lightTextSecondary,
                  ),
                ),
              ],
              Builder(builder: (cCtx) {
                final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
                final state = ref.watch(paceAppProvider);
                final completion = state.completions.cast<HabitCompletion?>().firstWhere(
                  (c) => c?.habitId == habit.id && c?.date == todayStr && c!.isCompleted,
                  orElse: () => null,
                );
                final activity = state.activities.cast<Activity?>().firstWhere(
                  (a) => a?.habitId == habit.id && a?.date == todayStr && a?.source == 'habit',
                  orElse: () => null,
                );

                if (completion == null) return const SizedBox.shrink();

                final hasNote = activity?.notes.isNotEmpty ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion Note',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: PaceColors.lightTextSecondary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final newNote = await ItemNoteDialog.show(
                              cCtx,
                              title: 'Completion Note',
                              initialNote: activity?.notes ?? '',
                              hintText: 'Add a completion note...',
                            );
                            if (newNote != null) {
                              await ref.read(paceAppProvider.notifier).updateHabitCompletionNote(
                                    habit.id,
                                    todayStr,
                                    newNote,
                                  );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            }
                          },
                          icon: Icon(hasNote ? Icons.edit_rounded : Icons.add_rounded, size: 16),
                          label: Text(hasNote ? 'Edit note' : 'Add a note'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PaceColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PaceColors.lightBorder),
                      ),
                      child: Text(
                        hasNote ? activity!.notes : 'No completion note added.',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasNote ? PaceColors.lightTextPrimary : PaceColors.lightTextMuted,
                          fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Habit'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.85,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      builder: (_, controller) => CreateHabitSheet(initialHabit: habit),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
