import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../features/journal/journal_editor_sheet.dart';
import 'item_note_dialog.dart';

class DayDetailModal extends ConsumerWidget {
  final DateTime date;
  final DailySummary? summary;

  const DayDetailModal({
    super.key,
    required this.date,
    this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paceAppProvider);
    final dateStr = PaceDateUtils.toIsoDateString(date);

    final dayActivities = state.activities.where((a) => a.date == dateStr).toList();
    final dayCompletions = state.completions.where((c) => c.date == dateStr).toList();
    final dayFocus = state.focusSessions.where((f) => f.date == dateStr).toList();
    final journalEntry = state.journalEntries.cast<JournalEntry?>().firstWhere(
          (j) => j?.date == dateStr,
          orElse: () => null,
        );


    final habitsCompletedCount = dayCompletions.where((c) => c.isCompleted).length;
    final totalFocusMins = dayFocus.fold<int>(0, (sum, f) => sum + f.actualDurationMinutes);
    final completionPct = summary?.completionPercentage ?? 0.0;
    final contributionLevel = summary?.contributionLevel ?? 0;

    return Semantics(
      label: '${PaceDateUtils.formatFullDate(date)}. ${dayActivities.length} activities logged. $habitsCompletedCount habits completed. ${totalFocusMins}m focused. Contribution level $contributionLevel.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: PaceColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PaceDateUtils.formatFullDate(date),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                      Text(
                        PaceDateUtils.formatRelativeDate(date),
                        style: TextStyle(
                          fontSize: 13,
                          color: PaceColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Metric Chips Row
              Row(
                children: [
                  _buildStatBadge(
                    context,
                    label: 'Completion',
                    value: '${completionPct.toInt()}%',
                    icon: Icons.donut_large_rounded,
                    color: PaceColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatBadge(
                    context,
                    label: 'Habits Done',
                    value: '$habitsCompletedCount',
                    icon: Icons.check_circle_rounded,
                    color: PaceColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildStatBadge(
                    context,
                    label: 'Focus',
                    value: '${totalFocusMins}m',
                    icon: Icons.timer_rounded,
                    color: PaceColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatBadge(
                    context,
                    label: 'Contribution',
                    value: 'Lvl $contributionLevel',
                    icon: Icons.local_fire_department_rounded,
                    color: PaceColors.accentGold,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Activity Log Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Timeline',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${dayActivities.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      color: PaceColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dayActivities.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No activities logged for this day.',
                      style: TextStyle(
                        color: PaceColors.lightTextMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: dayActivities.map((act) {
                    final hasNote = act.notes.isNotEmpty;
                    final itemTitle = act.source == 'focus'
                        ? 'Focus Session'
                        : (act.source == 'habit' ? 'Habit Completion' : 'Activity');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PaceColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: PaceColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                act.source == 'focus'
                                    ? Icons.timer_rounded
                                    : (act.source == 'habit'
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.directions_run_rounded),
                                size: 20,
                                color: PaceColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      act.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    if (act.durationMinutes > 0)
                                      Text(
                                        '${act.durationMinutes} minutes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: PaceColors.lightTextMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final newNote = await ItemNoteDialog.show(
                                    context,
                                    title: '$itemTitle Note',
                                    initialNote: act.notes,
                                    hintText: 'Add note for ${act.title}...',
                                  );
                                  if (newNote != null) {
                                    await ref.read(paceAppProvider.notifier).updateActivityNote(act.id, newNote);
                                  }
                                },
                                icon: Icon(hasNote ? Icons.edit_note_rounded : Icons.add_comment_rounded, size: 20),
                                color: PaceColors.primary,
                                tooltip: hasNote ? 'Edit note' : 'Add note',
                              ),
                            ],
                          ),
                          if (hasNote) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: PaceColors.lightSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: PaceColors.lightBorder),
                              ),
                              child: Text(
                                act.notes,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: PaceColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Daily Note Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Note',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => JournalEditorSheet(
                          date: date,
                          existingEntry: journalEntry,
                        ),
                      );
                    },
                    icon: Icon(journalEntry == null ? Icons.add_rounded : Icons.edit_rounded, size: 16),
                    label: Text(journalEntry == null ? 'Add a note' : 'Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (journalEntry != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PaceColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PaceColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            journalEntry.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: PaceColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              journalEntry.mood.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: PaceColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        journalEntry.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: PaceColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'No note for this day.',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaceColors.lightTextMuted,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
