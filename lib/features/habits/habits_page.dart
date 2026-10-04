import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/completion_note_dialog.dart';
import '../../shared/widgets/habit_tile.dart';
import '../../shared/widgets/empty_state.dart';
import 'create_habit_sheet.dart';

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paceAppProvider);
    final today = PaceDateUtils.today();
    final todayStr = PaceDateUtils.toIsoDateString(today);

    final activeHabits = state.habits.where((h) => !h.isArchived).toList();
    final todayCompletions = state.completions.where((c) => c.date == todayStr).toList();

    // Group by category
    final categories = <String, List<Habit>>{};
    for (final h in activeHabits) {
      categories.putIfAbsent(h.category, () => []).add(h);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Page Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habits',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.8,
                            color: PaceColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activeHabits.length} active habit${activeHabits.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: PaceColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => _showCreateHabitSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New'),
                      style: FilledButton.styleFrom(
                        backgroundColor: PaceColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Today's Date
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: PaceColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        PaceDateUtils.formatFullDate(today),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PaceColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (activeHabits.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.self_improvement_rounded,
                  title: 'Build your routine',
                  message: 'Create habits that matter to you.\nSmall actions compound into real progress.',
                  actionLabel: 'Create First Habit',
                  onAction: () => _showCreateHabitSheet(context),
                  ),
              )
            else ...[
              // Habit Categories
              ...categories.entries.map((entry) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: PaceColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        ...entry.value.map((habit) {
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
                                if (habit.habitType == HabitType.binary) {
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
                                } else {
                                  _showValueInputDialog(context, ref, habit, todayStr);
                                }
                              }
                            },
                            onTap: () => _showHabitOptionsSheet(context, ref, habit),
                            onLongPress: () => _showHabitOptionsSheet(context, ref, habit),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showCreateHabitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => const CreateHabitSheet(),
      ),
    );
  }

  void _showValueInputDialog(BuildContext context, WidgetRef ref, Habit habit, String dateStr) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Log ${habit.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: ${habit.targetValue.toInt()} ${habit.targetUnit}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter ${habit.targetUnit.isEmpty ? "value" : habit.targetUnit}',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final val = double.tryParse(controller.text);
                if (val != null && val > 0) {
                  Navigator.of(ctx).pop();
                  String? note;
                  final state = ref.read(paceAppProvider);
                  if (state.preferences.completionNotePreference == 'ask') {
                    final res = await CompletionNoteDialog.show(
                      context,
                      title: 'Complete ${habit.name}',
                    );
                    note = res?.note;
                    if (res?.dontAskAgain ?? false) {
                      await ref.read(paceAppProvider.notifier).updatePreferences(
                            state.preferences.copyWith(completionNotePreference: 'dont_ask'),
                          );
                    }
                  }
                  await ref.read(paceAppProvider.notifier).completeHabit(
                        habit.id,
                        dateStr,
                        value: val,
                        note: note,
                      );
                }
              },
              child: const Text('Log'),
            ),
          ],
        );
      },
    );
  }

  void _showHabitOptionsSheet(BuildContext context, WidgetRef ref, Habit habit) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Habit'),
                subtitle: const Text('Modify schedule, target, or reminder'),
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
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive Habit'),
                subtitle: const Text('Hide from daily list, keep history'),
                onTap: () {
                  ref.read(paceAppProvider.notifier).archiveHabit(habit.id, true);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: PaceColors.error),
                title: const Text('Delete Habit', style: TextStyle(color: PaceColors.error)),
                subtitle: const Text('Remove permanently with all data'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteHabit(context, ref, habit);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteHabit(BuildContext context, WidgetRef ref, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Habit?'),
          content: Text(
            'This will permanently delete "${habit.name}" and all its completion history. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(paceAppProvider.notifier).deleteHabit(habit.id);
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: PaceColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
