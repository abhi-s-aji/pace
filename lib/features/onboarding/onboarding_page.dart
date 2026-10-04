import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';

const _uuid = Uuid();

class OnboardingPage extends ConsumerStatefulWidget {
  final bool isRevisit;

  const OnboardingPage({
    super.key,
    this.isRevisit = false});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Username creation state
  late TextEditingController _nameController;

  // Habit creation state
  final TextEditingController _habitNameController = TextEditingController();
  HabitFrequency _habitFrequency = HabitFrequency.daily;
  bool _habitCreated = false;

  // Goal creation state
  final TextEditingController _goalTitleController = TextEditingController();
  String _goalCategory = 'Learning';
  DateTime _goalTargetDate = DateTime.now().add(const Duration(days: 30));
  bool _goalCreated = false;

  static const List<String> _habitSuggestions = [
    'Read',
    'Study',
    'Exercise',
    'Practice coding',
    'Write',
    'Walk',
    'Meditate',
  ];

  @override
  void initState() {
    super.initState();
    final initialName = ref.read(paceAppProvider).preferences.userName;
    _nameController = TextEditingController(text: initialName == 'User' ? '' : initialName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _habitNameController.dispose();
    _goalTitleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6 && _pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _skipOnboarding() async {
    final prefs = ref.read(paceAppProvider).preferences;
    final name = _nameController.text.trim();
    await ref.read(paceAppProvider.notifier).updatePreferences(
          prefs.copyWith(
            onboardingStatus: 'skipped',
            userName: name.isNotEmpty ? name : prefs.userName,
          ),
        );
    if (widget.isRevisit && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(paceAppProvider).preferences;
    final name = _nameController.text.trim();
    await ref.read(paceAppProvider.notifier).updatePreferences(
          prefs.copyWith(
            onboardingStatus: 'completed',
            userName: name.isNotEmpty ? name : prefs.userName,
          ),
        );
    if (widget.isRevisit && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCreateHabit() async {
    final name = _habitNameController.text.trim();
    if (name.isEmpty) return;

    final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
    final nowIso = DateTime.now().toIso8601String();

    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      category: 'General',
      frequency: _habitFrequency,
      startDate: todayStr,
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    await ref.read(paceAppProvider.notifier).createHabit(habit);
    setState(() => _habitCreated = true);
  }

  Future<void> _handleCreateGoal() async {
    final title = _goalTitleController.text.trim();
    if (title.isEmpty) return;

    final targetDateStr = PaceDateUtils.toIsoDateString(_goalTargetDate);

    await ref.read(paceAppProvider.notifier).createGoal(
          title: title,
          description: '',
          targetDate: targetDateStr,
          category: _goalCategory,
        );

    setState(() => _goalCreated = true);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Skip & Revisit Close)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.isRevisit)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    )
                  else
                    const SizedBox(width: 48),
                  // Step Indicator Dots
                  Row(
                    children: List.generate(7, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isSelected ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? PaceColors.primary
                              : (PaceColors.lightBorder),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  if (_currentPage < 6)
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PaceColors.lightTextMuted,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Main Slide Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildWelcomeSlide(),
                  _buildUsernameSlide(),
                  _buildCoreLoopSlide(),
                  _buildDataPrivacySlide(),
                  _buildFirstHabitSlide(),
                  _buildFirstGoalSlide(),
                  _buildReadySlide(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SLIDE 1: WELCOME ---
  Widget _buildWelcomeSlide() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PaceColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.speed_rounded,
              size: 56,
              color: PaceColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Pace',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              color: PaceColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Small actions. Real progress.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PaceColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pace helps you choose what matters, build intentional habits, take daily action, and record your consistency over time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: PaceColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: PaceColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SLIDE 2: USERNAME SETUP ---
  Widget _buildUsernameSlide() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PaceColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 48,
              color: PaceColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'What should Pace call you?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: PaceColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This name will appear on your dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: PaceColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                _nextPage();
              },
              style: FilledButton.styleFrom(
                backgroundColor: PaceColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SLIDE 2: HOW PACE WORKS ---
  Widget _buildCoreLoopSlide() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How Pace Works',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: PaceColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pace keeps a record of the things you actually do, so you can understand your consistency over time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: PaceColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Core Loop Steps Visual
          _buildLoopStep(
            icon: Icons.check_circle_outline_rounded,
            title: '1. Build Habits',
            subtitle: 'Choose what you want to do regularly',
            color: PaceColors.primary,
            ),
          const SizedBox(height: 12),
          _buildLoopStep(
            icon: Icons.play_arrow_rounded,
            title: '2. Take Action',
            subtitle: 'Complete habits or start focus sessions',
            color: PaceColors.secondary,
            ),
          const SizedBox(height: 12),
          _buildLoopStep(
            icon: Icons.insights_rounded,
            title: '3. Record Progress',
            subtitle: 'Track factual streaks & achievements',
            color: PaceColors.accentGold,
            ),
          const SizedBox(height: 12),
          _buildLoopStep(
            icon: Icons.history_rounded,
            title: '4. Build History',
            subtitle: 'See long-term patterns without pressure',
            color: PaceColors.info,
            ),

          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: PaceColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoopStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: PaceColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SLIDE 3: YOUR DATA ---
  Widget _buildDataPrivacySlide() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PaceColors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storage_rounded,
              size: 48,
              color: PaceColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Progress Stays With You',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: PaceColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pace works offline and stores all your data locally on your device in an SQLite database.\n\nNo account required. No cloud sync required. You can export or back up your data anytime from Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: PaceColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: PaceColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SLIDE 4: OPTIONAL FIRST HABIT ---
  Widget _buildFirstHabitSlide() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start With One Thing',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: PaceColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What is something you want to do consistently?',
            style: TextStyle(
              fontSize: 14,
              color: PaceColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Suggestion Chips
          Text(
            'Suggestions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: PaceColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _habitSuggestions.map((sug) {
              return ActionChip(
                label: Text(sug),
                backgroundColor: PaceColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: PaceColors.lightBorder,
                  ),
                ),
                onPressed: () {
                  _habitNameController.text = sug;
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Habit Name Field
          TextField(
            controller: _habitNameController,
            decoration: const InputDecoration(
              labelText: 'Habit Name',
              hintText: 'e.g. Read 15 minutes',
              prefixIcon: Icon(Icons.check_circle_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),

          // Frequency Dropdown
          DropdownButtonFormField<HabitFrequency>(
            initialValue: _habitFrequency,
            decoration: const InputDecoration(
              labelText: 'Schedule',
              prefixIcon: Icon(Icons.repeat_rounded),
            ),
            items: const [
              DropdownMenuItem(value: HabitFrequency.daily, child: Text('Every day')),
              DropdownMenuItem(value: HabitFrequency.weekdays, child: Text('Weekdays (Mon-Fri)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _habitFrequency = val);
            },
          ),
          const SizedBox(height: 24),

          if (_habitCreated) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PaceColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: PaceColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Habit created! You can track it on your Dashboard.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: PaceColors.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              if (!_habitCreated) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _nextPage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Skip for now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await _handleCreateHabit();
                      _nextPage();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Habit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else
                Expanded(
                  child: FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Next Step', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SLIDE 5: OPTIONAL FIRST GOAL ---
  Widget _buildFirstGoalSlide() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set a Direction',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: PaceColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Want to work toward something specific? (Optional)',
            style: TextStyle(
              fontSize: 14,
              color: PaceColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _goalTitleController,
            decoration: const InputDecoration(
              labelText: 'Goal Title',
              hintText: 'e.g. Complete Flutter Course',
              prefixIcon: Icon(Icons.flag_rounded),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _goalCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            items: ['Learning', 'Health', 'Career', 'Personal', 'General'].map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _goalCategory = val);
            },
          ),
          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Target Deadline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(PaceDateUtils.toIsoDateString(_goalTargetDate)),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _goalTargetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) {
                setState(() => _goalTargetDate = picked);
              }
            },
          ),
          const SizedBox(height: 24),

          if (_goalCreated) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PaceColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: PaceColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Goal created!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: PaceColors.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              if (!_goalCreated) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _nextPage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await _handleCreateGoal();
                      _nextPage();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else
                Expanded(
                  child: FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Next Step', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SLIDE 6: READY ---
  Widget _buildReadySlide() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PaceColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: PaceColors.success,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re ready.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
              color: PaceColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pace will help you build a record of your progress, one action at a time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: PaceColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _completeOnboarding,
              style: FilledButton.styleFrom(
                backgroundColor: PaceColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
