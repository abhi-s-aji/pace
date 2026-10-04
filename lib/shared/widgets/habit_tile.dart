import 'package:flutter/material.dart';
import '../../core/domain/models/models.dart';
import '../../core/theme/pace_colors.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final HabitCompletion? completion;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const HabitTile({
    super.key,
    required this.habit,
    this.completion,
    required this.onToggle,
    this.onTap,
    this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final isCompleted = completion?.isCompleted ?? false;
    final currentValue = completion?.value ?? 0.0;
    final targetValue = habit.targetValue;
    final habitColor = PaceColors.primary;

    return Semantics(
      label: '${habit.name}, category ${habit.category}',
      value: isCompleted ? 'Completed' : 'Not completed',
      checked: isCompleted,
      hint: 'Double tap checkbox to toggle habit completion',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 1. Completion Checkbox (LEFT side, minimum 48x48 touch target)
                Semantics(
                  label: isCompleted ? 'Uncomplete habit' : 'Complete habit',
                  button: true,
                  child: GestureDetector(
                    onTap: onToggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isCompleted ? habitColor : PaceColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCompleted ? habitColor : PaceColors.lightBorder,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 2. Habit Icon (Does NOT trigger completion)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: habitColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconData(habit.icon),
                      size: 18,
                      color: habitColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 3. Task Name & Supporting Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted
                              ? PaceColors.lightTextMuted
                              : PaceColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: habitColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            habit.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: PaceColors.lightTextMuted,
                            ),
                          ),
                          if (habit.habitType != HabitType.binary) ...[
                            const SizedBox(width: 8),
                            Text(
                              '•  ${currentValue.toInt()} / ${targetValue.toInt()} ${habit.targetUnit}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: PaceColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Habit Target Indicator for non-binary habits
                if (habit.habitType != HabitType.binary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: habitColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${targetValue.toInt()} ${habit.targetUnit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: habitColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'book':
        return Icons.menu_book_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'fitness':
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'pencil':
      case 'write':
        return Icons.edit_note_rounded;
      case 'brain':
      case 'study':
        return Icons.psychology_rounded;
      case 'check_circle':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}
