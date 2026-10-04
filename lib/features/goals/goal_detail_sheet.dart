import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/calculators/goal_engine.dart';
import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';

class GoalDetailSheet extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalDetailSheet({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends ConsumerState<GoalDetailSheet> {
  final _newMilestoneController = TextEditingController();

  @override
  void dispose() {
    _newMilestoneController.dispose();
    super.dispose();
  }

  String _formatDeadline(String targetDateStr) {
    final target = PaceDateUtils.parseIsoDateString(targetDateStr);
    final today = PaceDateUtils.today();
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Past target date (${diff.abs()} day${diff.abs() == 1 ? '' : 's'} ago)';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days ($targetDateStr)';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paceAppProvider);

    // Get current updated goal from state
    final goal = state.goals.cast<Goal?>().firstWhere(
          (g) => g?.id == widget.goal.id,
          orElse: () => widget.goal,
        )!;

    // Get goal habit links
    final links = state.goalHabitLinks.where((l) => l.goalId == goal.id).toList();

    // Query milestones from state
    final milestones = state.milestones.where((m) => m.goalId == goal.id).toList();

    // Calculate detailed progress & explanation
    final explanation = GoalEngine.explainGoalProgress(
      goal: goal,
      links: links,
      completions: state.completions,
      milestones: milestones,
      focusSessions: state.focusSessions,
      activities: state.activities,
    );

    final progressPct = explanation.progressPercentage.clamp(0.0, 100.0);
    final deadlineText = _formatDeadline(goal.targetDate);
    final isPast = deadlineText.startsWith('Past');

    // Contributing activities for this goal or linked habits
    final linkedHabitIds = links.map((l) => l.habitId).toSet();
    final contributingActivities = state.activities.where((a) {
      if (a.habitId != null && linkedHabitIds.contains(a.habitId)) return true;
      return false;
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: PaceColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category, Status, Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PaceColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        goal.category.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PaceColors.secondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: goal.isArchived
                            ? Colors.grey.withValues(alpha: 0.2)
                            : (goal.isCompleted ? PaceColors.success.withValues(alpha: 0.15) : PaceColors.primary.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        goal.isArchived ? 'ARCHIVED' : (goal.isCompleted ? 'COMPLETED' : 'ACTIVE'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: goal.isArchived ? Colors.grey : (goal.isCompleted ? PaceColors.success : PaceColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Description
            Text(
              goal.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: PaceColors.lightTextPrimary,
              ),
            ),
            if (goal.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                goal.description,
                style: TextStyle(
                  fontSize: 14,
                  color: PaceColors.lightTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Temporal Deadline Context
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isPast ? PaceColors.accentGold : (PaceColors.lightTextMuted),
                ),
                const SizedBox(width: 6),
                Text(
                  deadlineText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isPast ? FontWeight.w600 : FontWeight.normal,
                    color: isPast ? PaceColors.accentGold : (PaceColors.lightTextMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Card with Explicit Explanation
            Semantics(
              label: '${goal.title}. ${progressPct.toInt()} percent complete. $deadlineText.',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Progress Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            '${progressPct.toInt()}%',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: PaceColors.secondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPct / 100.0,
                          minHeight: 8,
                          backgroundColor: PaceColors.lightSurfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(PaceColors.secondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Bullet explanation list
                      ...explanation.explanationBullets.map((bullet) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 14, color: PaceColors.secondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: PaceColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Goal Reminder Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 20, color: PaceColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Goal Reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            goal.reminderEnabled
                                ? 'Daily at ${goal.reminderTime ?? "09:00"}'
                                : 'Gentle daily reminder off',
                            style: TextStyle(
                              fontSize: 12,
                              color: PaceColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (goal.reminderEnabled)
                      IconButton(
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        onPressed: () async {
                          final parts = (goal.reminderTime ?? '09:00').split(':');
                          final initTime = TimeOfDay(
                            hour: parts.length == 2 ? int.tryParse(parts[0]) ?? 9 : 9,
                            minute: parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0,
                          );
                          final picked = await showTimePicker(context: context, initialTime: initTime);
                          if (picked != null) {
                            final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            final updated = goal.copyWith(reminderTime: formatted);
                            ref.read(paceAppProvider.notifier).updateGoal(updated);
                          }
                        },
                      ),
                    Switch(
                      value: goal.reminderEnabled,
                      onChanged: (val) {
                        final timeStr = goal.reminderTime ?? '09:00';
                        final updated = goal.copyWith(reminderEnabled: val, reminderTime: timeStr);
                        ref.read(paceAppProvider.notifier).updateGoal(updated);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Milestones Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Milestones (${explanation.completedMilestonesCount}/${explanation.totalMilestonesCount})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: PaceColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Inline Add Milestone Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newMilestoneController,
                    decoration: const InputDecoration(
                      hintText: 'Add new milestone...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  style: IconButton.styleFrom(backgroundColor: PaceColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    final text = _newMilestoneController.text.trim();
                    if (text.isNotEmpty) {
                      await ref.read(paceAppProvider.notifier).addMilestone(
                            goalId: goal.id,
                            title: text,
                            targetDate: goal.targetDate,
                          );
                      _newMilestoneController.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Milestones List
            if (milestones.isNotEmpty) ...[
              ...milestones.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: PaceColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PaceColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: m.isCompleted,
                        onChanged: (_) {
                          ref.read(paceAppProvider.notifier).toggleMilestone(m);
                        },
                      ),
                      Expanded(
                        child: Text(
                          m.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: m.isCompleted ? TextDecoration.lineThrough : null,
                            color: m.isCompleted ? PaceColors.lightTextMuted : PaceColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: PaceColors.lightTextMuted),
                        onPressed: () {
                          ref.read(paceAppProvider.notifier).deleteMilestone(m.id);
                        },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Recent Contributing Activity History
            if (contributingActivities.isNotEmpty) ...[
              Text(
                'Contributing History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: PaceColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...contributingActivities.take(5).map((act) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PaceColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PaceColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        act.source == 'focus' ? Icons.timer_rounded : Icons.check_circle_rounded,
                        size: 16,
                        color: PaceColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          act.title,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                      Text(
                        act.date,
                        style: TextStyle(fontSize: 11, color: PaceColors.lightTextMuted),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Action Buttons: Archive & Delete
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(paceAppProvider.notifier).archiveGoal(goal.id, !goal.isArchived);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: Icon(goal.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded, size: 18),
                    label: Text(goal.isArchived ? 'Unarchive' : 'Archive Goal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Goal?'),
                          content: const Text('Goal relationships will be removed. Your habits, completions, and activity history will NOT be deleted.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: TextButton.styleFrom(foregroundColor: PaceColors.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref.read(paceAppProvider.notifier).deleteGoal(goal.id);
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: PaceColors.error),
                    label: const Text('Delete', style: TextStyle(color: PaceColors.error)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: PaceColors.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
