import 'package:flutter/material.dart';
import '../../core/domain/models/models.dart';
import '../../core/theme/pace_colors.dart';

IconData getAchievementIconData(String iconName) {
  switch (iconName) {
    case 'flag':
      return Icons.flag_rounded;
    case 'timer':
      return Icons.timer_rounded;
    case 'target':
      return Icons.track_changes_rounded;
    case 'calendar':
      return Icons.calendar_today_rounded;
    case 'calendar_check':
      return Icons.edit_calendar_rounded;
    case 'flame':
      return Icons.local_fire_department_rounded;
    case 'shield_check':
      return Icons.verified_user_rounded;
    case 'check_circle':
      return Icons.check_circle_rounded;
    case 'award':
      return Icons.workspace_premium_rounded;
    case 'layout':
      return Icons.grid_view_rounded;
    case 'clock':
      return Icons.schedule_rounded;
    case 'zap':
      return Icons.bolt_rounded;
    case 'check_square':
      return Icons.fact_check_rounded;
    case 'trophy':
      return Icons.emoji_events_rounded;
    case 'book_open':
      return Icons.auto_stories_rounded;
    case 'timeline':
      return Icons.show_chart_rounded;
    case 'sparkles':
      return Icons.auto_awesome_rounded;
    case 'edit_note':
      return Icons.edit_note_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'psychology':
      return Icons.psychology_rounded;
    default:
      return Icons.stars_rounded;
  }
}

class AchievementDetailSheet extends StatelessWidget {
  final Achievement achievement;

  const AchievementDetailSheet({
    super.key,
    required this.achievement,
    });

  @override
  Widget build(BuildContext context) {
    final isEarned = achievement.isEarned;
    final progressPct = (achievement.progress * 100).toInt().clamp(0, 100);
    final iconData = getAchievementIconData(achievement.icon);

    final semanticLabel = isEarned
        ? '${achievement.title}. Earned achievement in category ${achievement.category}. ${achievement.description} ${achievement.evidenceText}'
        : '${achievement.title}. In progress achievement in category ${achievement.category}. $progressPct percent complete. ${achievement.description} ${achievement.evidenceText}';

    return Semantics(
      label: semanticLabel,
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
              // Handle
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

              // Header Row: Category & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PaceColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          achievement.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PaceColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? PaceColors.success.withValues(alpha: 0.15)
                              : PaceColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isEarned ? 'EARNED' : 'IN PROGRESS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isEarned ? PaceColors.success : PaceColors.secondary,
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
              const SizedBox(height: 16),

              // Icon & Title
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isEarned
                          ? PaceColors.secondary.withValues(alpha: 0.15)
                          : (PaceColors.lightSurfaceElevated),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEarned ? PaceColors.secondary : (PaceColors.lightBorder),
                      ),
                    ),
                    child: Icon(
                      iconData,
                      size: 26,
                      color: isEarned
                          ? PaceColors.secondary
                          : (PaceColors.lightTextMuted),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: PaceColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          achievement.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: PaceColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Evidence Box
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Factual Evidence',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            achievement.unit == 'hours'
                                ? '${achievement.currentValue.toStringAsFixed(1)} / ${achievement.targetValue.toInt()} ${achievement.unit}'
                                : '${achievement.currentValue.toInt()} / ${achievement.targetValue.toInt()} ${achievement.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isEarned ? PaceColors.success : PaceColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: achievement.progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: PaceColors.lightSurfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isEarned ? PaceColors.success : PaceColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isEarned ? Icons.verified_rounded : Icons.info_outline_rounded,
                            size: 16,
                            color: isEarned ? PaceColors.success : PaceColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              achievement.evidenceText,
                              style: TextStyle(
                                fontSize: 12,
                                color: PaceColors.lightTextSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
