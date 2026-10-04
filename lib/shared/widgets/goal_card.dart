import 'package:flutter/material.dart';
import '../../core/domain/models/models.dart';
import '../../core/theme/pace_colors.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final int linkedHabitsCount;
  final int milestonesCount;
  final int completedMilestonesCount;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.linkedHabitsCount = 0,
    this.milestonesCount = 0,
    this.completedMilestonesCount = 0,
    this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = goal.calculatedProgress.clamp(0.0, 1.0);
    final progressPct = (progress * 100).toInt();

    return Semantics(
      label: 'Goal: ${goal.title}. Category: ${goal.category}. Progress: $progressPct%. Target date: ${goal.targetDate}. $linkedHabitsCount linked habits, $completedMilestonesCount of $milestonesCount milestones completed.',
      button: true,
      hint: 'Double tap to open goal details',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Category Chip & Target Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: PaceColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        goal.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: PaceColors.secondary,
                        ),
                      ),
                    ),
                    Text(
                      'Target: ${goal.targetDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: PaceColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title & Description
                Text(
                  goal.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                if (goal.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    goal.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: PaceColors.lightTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Dynamic Progress Bar & Percentage
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: PaceColors.lightSurfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 ? PaceColors.success : PaceColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$progressPct%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: progress >= 1.0 ? PaceColors.success : PaceColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Footer: Linked Habits & Milestones count
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 14,
                      color: PaceColors.lightTextMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$linkedHabitsCount linked habit${linkedHabitsCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: PaceColors.lightTextMuted,
                      ),
                    ),
                    if (milestonesCount > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: PaceColors.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$completedMilestonesCount / $milestonesCount milestones',
                        style: TextStyle(
                          fontSize: 12,
                          color: PaceColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
