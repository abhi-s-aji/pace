import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/item_note_dialog.dart';

class ActivityHistoryPage extends ConsumerStatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  ConsumerState<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends ConsumerState<ActivityHistoryPage> {
  String _selectedSource = 'all'; // 'all', 'habit', 'focus', 'manual'
  String _selectedTimeFrame = 'all'; // 'today', 'week', 'month', 'all'

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paceAppProvider);
    final today = PaceDateUtils.today();

    // Apply filters on authoritative activities list
    final filteredActivities = state.activities.where((act) {
      if (_selectedSource != 'all' && act.source != _selectedSource) {
        return false;
      }

      if (_selectedTimeFrame != 'all') {
        final actDate = PaceDateUtils.parseIsoDateString(act.date);
        final diffDays = today.difference(actDate).inDays;

        if (_selectedTimeFrame == 'today' && diffDays != 0) return false;
        if (_selectedTimeFrame == 'week' && diffDays > 7) return false;
        if (_selectedTimeFrame == 'month' && diffDays > 30) return false;
      }

      return true;
    }).toList();

    // Group activities by date
    final Map<String, List<Activity>> grouped = {};
    for (final act in filteredActivities) {
      grouped.putIfAbsent(act.date, () => []).add(act);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Activity History',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                    color: PaceColors.primary,
                  ),
                ),
              ),
            ),

            // Source Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Activities'),
                    const SizedBox(width: 8),
                    _buildFilterChip('habit', 'Habits', icon: Icons.check_circle_outline_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('focus', 'Focus', icon: Icons.timer_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('manual', 'Manual', icon: Icons.edit_note_rounded),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // Timeframe Filter Segmented Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTimeChip('today', 'Today'),
                    const SizedBox(width: 6),
                    _buildTimeChip('week', '7 Days'),
                    const SizedBox(width: 6),
                    _buildTimeChip('month', '30 Days'),
                    const SizedBox(width: 6),
                    _buildTimeChip('all', 'All Time'),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Activity Feed Grouped by Date
            if (filteredActivities.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No activity found',
                    message: 'Complete habits, finish focus sessions, or log manual activities to build your history.',
                    ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, dateIndex) {
                    final dateStr = sortedDates[dateIndex];
                    final date = PaceDateUtils.parseIsoDateString(dateStr);
                    final dayActs = grouped[dateStr]!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              children: [
                                Text(
                                  PaceDateUtils.formatFullDate(date),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                    color: PaceColors.lightTextSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  PaceDateUtils.formatRelativeDate(date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: PaceColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Day's activity tiles
                          ...dayActs.map((act) => _buildActivityTile(context, act)),
                        ],
                      ),
                    );
                  },
                  childCount: sortedDates.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, {IconData? icon}) {
    final selected = _selectedSource == value;
    return ChoiceChip(
      showCheckmark: false,
      avatar: icon != null ? Icon(icon, size: 16, color: selected ? Colors.white : PaceColors.primary) : null,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? Colors.white : (PaceColors.lightTextSecondary),
        ),
      ),
      selected: selected,
      selectedColor: PaceColors.primary,
      backgroundColor: PaceColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? PaceColors.primary : (PaceColors.lightBorder),
        ),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedSource = value);
      },
    );
  }

  Widget _buildTimeChip(String value, String label) {
    final selected = _selectedTimeFrame == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTimeFrame = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? PaceColors.primary.withValues(alpha: 0.15)
                : (PaceColors.lightSurface),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? PaceColors.primary : (PaceColors.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? PaceColors.primary : (PaceColors.lightTextMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, Activity act) {
    IconData icon;
    Color iconColor;

    switch (act.source) {
      case 'focus':
        icon = Icons.timer_rounded;
        iconColor = PaceColors.secondary;
        break;
      case 'habit':
        icon = Icons.check_circle_rounded;
        iconColor = PaceColors.primary;
        break;
      case 'manual':
      default:
        icon = Icons.directions_run_rounded;
        iconColor = PaceColors.accentGold;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaceColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PaceColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: PaceColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        act.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: PaceColors.lightTextMuted,
                        ),
                      ),
                    ),
                    if (act.notes.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          act.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: PaceColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (act.durationMinutes > 0)
            Text(
              '${act.durationMinutes}m',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            )
          else if (act.quantity > 0)
            Text(
              '${act.quantity} ${act.unit}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          IconButton(
            icon: Icon(
              act.notes.isNotEmpty ? Icons.edit_note_rounded : Icons.add_comment_rounded,
              size: 18,
              color: PaceColors.primary,
            ),
            tooltip: act.notes.isNotEmpty ? 'Edit note' : 'Add note',
            onPressed: () async {
              final newNote = await ItemNoteDialog.show(
                context,
                title: '${act.title} Note',
                initialNote: act.notes,
                hintText: 'Add a note for this activity...',
              );
              if (newNote != null) {
                ref.read(paceAppProvider.notifier).updateActivityNote(act.id, newNote);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: PaceColors.darkTextMuted),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Activity?'),
                  content: Text('Delete "${act.title}" from history?'),
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
              if (confirmed == true) {
                ref.read(paceAppProvider.notifier).deleteActivity(act.id);
              }
            },
          ),
        ],
      ),
    );
  }
}
