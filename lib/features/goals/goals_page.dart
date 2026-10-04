import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/goal_card.dart';
import 'create_goal_sheet.dart';
import 'goal_detail_sheet.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  String _selectedTab = 'active'; // 'active', 'completed', 'archived'

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paceAppProvider);

    final goals = state.goals.where((g) {
      if (_selectedTab == 'archived') return g.isArchived;
      if (_selectedTab == 'completed') return !g.isArchived && g.isCompleted;
      return !g.isArchived && !g.isCompleted; // active
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const CreateGoalSheet(),
          );
        },
        backgroundColor: PaceColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Goals & Milestones',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                    color: PaceColors.lightTextPrimary,
                  ),
                ),
              ),
            ),

            // Tab Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTabChip('active', 'Active'),
                    const SizedBox(width: 8),
                    _buildTabChip('completed', 'Completed'),
                    const SizedBox(width: 8),
                    _buildTabChip('archived', 'Archived'),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Goals List
            if (goals.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.flag_rounded,
                    title: 'No goals found',
                    message: _selectedTab == 'active'
                        ? 'Set your first long-term goal to track meaningful progress.'
                        : 'No $_selectedTab goals.',
                    ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = goals[index];
                      return _buildGoalCard(context, goal);
                    },
                    childCount: goals.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String key, String label) {
    final selected = _selectedTab == key;
    return ChoiceChip(
      showCheckmark: false,
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
        if (val) setState(() => _selectedTab = key);
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final state = ref.watch(paceAppProvider);
    final links = state.goalHabitLinks.where((l) => l.goalId == goal.id).toList();
    final milestones = state.milestones.where((m) => m.goalId == goal.id).toList();
    final completedMilestonesCount = milestones.where((m) => m.isCompleted).length;

    return GoalCard(
      goal: goal,
      linkedHabitsCount: links.length,
      milestonesCount: milestones.length,
      completedMilestonesCount: completedMilestonesCount,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => GoalDetailSheet(goal: goal),
        );
      },
    );
  }
}
