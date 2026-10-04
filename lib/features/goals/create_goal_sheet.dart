import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';

class CreateGoalSheet extends ConsumerStatefulWidget {
  const CreateGoalSheet({super.key});

  @override
  ConsumerState<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<CreateGoalSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _targetUnitController = TextEditingController();

  String _category = 'General';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  bool _isQuantitative = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  final List<String> _linkedHabitIds = [];
  final List<TextEditingController> _milestoneControllers = [];
  bool _isSubmitting = false;

  static const _categories = ['General', 'Career', 'Study', 'Health', 'Fitness', 'Personal'];

  @override
  void initState() {
    super.initState();
    _addMilestoneField();
  }

  void _addMilestoneField() {
    setState(() {
      _milestoneControllers.add(TextEditingController());
    });
  }

  void _removeMilestoneField(int index) {
    if (_milestoneControllers.length <= 1) return;
    setState(() {
      final ctrl = _milestoneControllers.removeAt(index);
      ctrl.dispose();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetValueController.dispose();
    _targetUnitController.dispose();
    for (final ctrl in _milestoneControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a goal title.'),
          backgroundColor: PaceColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final targetVal = _isQuantitative ? (double.tryParse(_targetValueController.text.trim()) ?? 0.0) : 0.0;
    final targetUnit = _isQuantitative ? _targetUnitController.text.trim() : '';

    final milestoneTitles = _milestoneControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final reminderStr = _reminderEnabled
        ? '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
        : null;

    await ref.read(paceAppProvider.notifier).createGoal(
          title: title,
          description: _descController.text.trim(),
          category: _category,
          startDate: PaceDateUtils.toIsoDateString(DateTime.now()),
          targetDate: PaceDateUtils.toIsoDateString(_targetDate),
          targetValue: targetVal,
          targetUnit: targetUnit,
          reminderEnabled: _reminderEnabled,
          reminderTime: reminderStr,
          linkedHabitIds: _linkedHabitIds,
          milestoneTitles: milestoneTitles,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal "$title" created!'),
          backgroundColor: PaceColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paceAppProvider);
    final habits = state.habits.where((h) => !h.isArchived).toList();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: PaceColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Long-Term Goal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: PaceColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title Input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title *',
                hintText: 'e.g. Become a React Developer, Read 12 Books',
              ),
            ),
            const SizedBox(height: 16),

            // Description Input
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Why is this goal meaningful to you?',
              ),
            ),
            const SizedBox(height: 16),

            // Category & Target Date Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) => setState(() => _category = val ?? 'General'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) setState(() => _targetDate = picked);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Target Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            PaceDateUtils.toIsoDateString(_targetDate),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Goal Measurement Type Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quantitative Target', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Track numerical target (e.g. 100 hours, 30 sessions)', style: TextStyle(fontSize: 12)),
              value: _isQuantitative,
              onChanged: (val) => setState(() => _isQuantitative = val),
            ),

            if (_isQuantitative) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetValueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Target Value',
                        hintText: 'e.g. 100',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _targetUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g. hours, books, sessions',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Goal Reminder Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Goal Reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(
                _reminderEnabled
                    ? 'Reminder at ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
                    : 'Gentle reminder for this goal',
                style: const TextStyle(fontSize: 12),
              ),
              value: _reminderEnabled,
              onChanged: (val) => setState(() => _reminderEnabled = val),
            ),
            if (_reminderEnabled) ...[
              TextButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (picked != null) setState(() => _reminderTime = picked);
                },
                icon: const Icon(Icons.access_time_rounded, size: 18),
                label: Text(
                  'Time: ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Linked Habits Section
            if (habits.isNotEmpty) ...[
              Text(
                'Link Habits',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: PaceColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: habits.map((h) {
                  final selected = _linkedHabitIds.contains(h.id);
                  return FilterChip(
                    label: Text(h.name),
                    selected: selected,
                    selectedColor: PaceColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: PaceColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: selected ? PaceColors.primary : PaceColors.darkBorder),
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _linkedHabitIds.add(h.id);
                        } else {
                          _linkedHabitIds.remove(h.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Initial Milestones Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Milestones',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: PaceColors.lightTextPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMilestoneField,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Milestone'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._milestoneControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('${idx + 1}.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Complete JavaScript basics',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    if (_milestoneControllers.length > 1)
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: PaceColors.error),
                        onPressed: () => _removeMilestoneField(idx),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: PaceColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Goal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
