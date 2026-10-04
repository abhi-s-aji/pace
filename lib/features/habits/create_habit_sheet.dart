import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';

const _uuid = Uuid();

class CreateHabitSheet extends ConsumerStatefulWidget {
  final Habit? initialHabit;

  const CreateHabitSheet({super.key, this.initialHabit});

  @override
  ConsumerState<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<CreateHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _targetController;
  late final TextEditingController _unitController;

  late String _category;
  late String _icon;
  late int _colorValue;
  late HabitType _habitType;
  late HabitFrequency _frequency;
  late List<int> _selectedWeekdays;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;

  static const _categories = [
    'General',
    'Learning',
    'Health',
    'Fitness',
    'Reading',
    'Work',
    'Creative',
    'Mindfulness',
  ];

  static const _iconOptions = [
    ('check_circle', Icons.check_circle_outline_rounded),
    ('book', Icons.menu_book_rounded),
    ('code', Icons.code_rounded),
    ('fitness', Icons.fitness_center_rounded),
    ('water', Icons.water_drop_rounded),
    ('write', Icons.edit_note_rounded),
    ('study', Icons.psychology_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final habit = widget.initialHabit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _descController = TextEditingController(text: habit?.description ?? '');
    _targetController = TextEditingController(text: habit != null ? habit.targetValue.toInt().toString() : '1');
    _unitController = TextEditingController(text: habit?.targetUnit ?? '');

    _category = habit?.category ?? 'General';
    _icon = habit?.icon ?? 'check_circle';
    _colorValue = habit?.colorValue ?? PaceColors.primary.toARGB32();
    _habitType = habit?.habitType ?? HabitType.binary;
    _frequency = habit?.frequency ?? HabitFrequency.daily;
    _selectedWeekdays = habit != null ? List<int>.from(habit.selectedWeekdays) : [1, 2, 3, 4, 5, 6, 7];

    if (habit?.reminderTime != null && habit!.reminderTime!.isNotEmpty) {
      _reminderEnabled = true;
      final parts = habit.reminderTime!.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 20,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      } else {
        _reminderTime = const TimeOfDay(hour: 20, minute: 0);
      }
    } else {
      _reminderEnabled = false;
      _reminderTime = const TimeOfDay(hour: 20, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialHabit != null;

    return Container(
      decoration: BoxDecoration(
        color: PaceColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _formKey,
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

              // Title
              Text(
                isEditing ? 'Edit Habit' : 'New Habit',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: PaceColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Name
              _buildLabel('Habit Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Study JavaScript'),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel('Description (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(hintText: 'Brief description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Category
              _buildLabel('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: PaceColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? PaceColors.primary
                          : (PaceColors.lightTextSecondary),
                    ),
                    side: BorderSide(
                      color: selected
                          ? PaceColors.primary.withValues(alpha: 0.5)
                          : (PaceColors.lightBorder),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Icon Picker
              _buildLabel('Icon'),
              const SizedBox(height: 8),
              Row(
                children: _iconOptions.map((opt) {
                  final selected = _icon == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _icon = opt.$1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? PaceColors.primary.withValues(alpha: 0.15)
                              : (PaceColors.lightSurfaceElevated),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? PaceColors.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            opt.$2,
                            size: 20,
                            color: selected
                                ? PaceColors.primary
                                : (PaceColors.lightTextMuted),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Habit Type
              _buildLabel('Target Type'),
              const SizedBox(height: 8),
              SegmentedButton<HabitType>(
                segments: HabitType.values.map((t) {
                  return ButtonSegment(
                    value: t,
                    label: Text(t.label, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                selected: {_habitType},
                onSelectionChanged: (val) {
                  setState(() {
                    _habitType = val.first;
                    if (_habitType == HabitType.binary) {
                      _targetController.text = '1';
                    }
                  });
                },
                style: ButtonStyle(
                  side: WidgetStateProperty.all(
                    BorderSide(color: PaceColors.lightBorder),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Target Value & Unit (only for non-binary)
              if (_habitType != HabitType.binary) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Target Value'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _targetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'e.g. 45'),
                            validator: (val) {
                              if (_habitType != HabitType.binary) {
                                final n = double.tryParse(val ?? '');
                                if (n == null || n <= 0) return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Unit'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _unitController,
                            decoration: InputDecoration(
                              hintText: _habitType == HabitType.duration
                                  ? 'minutes'
                                  : (_habitType == HabitType.count
                                      ? 'problems'
                                      : 'pages'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Frequency
              _buildLabel('Frequency'),
              const SizedBox(height: 8),
              SegmentedButton<HabitFrequency>(
                segments: const [
                  ButtonSegment(value: HabitFrequency.daily, label: Text('Daily', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: HabitFrequency.weekdays, label: Text('Weekdays', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: HabitFrequency.weeklyDays, label: Text('Custom', style: TextStyle(fontSize: 12))),
                ],
                selected: {_frequency},
                onSelectionChanged: (val) => setState(() => _frequency = val.first),
                style: ButtonStyle(
                  side: WidgetStateProperty.all(
                    BorderSide(color: PaceColors.lightBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Custom Day Picker (for weeklyDays frequency)
              if (_frequency == HabitFrequency.weeklyDays) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (idx) {
                    final day = idx + 1;
                    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    final selected = _selectedWeekdays.contains(day);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedWeekdays.remove(day);
                          } else {
                            _selectedWeekdays.add(day);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected
                              ? PaceColors.primary.withValues(alpha: 0.2)
                              : (PaceColors.lightSurfaceElevated),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? PaceColors.primary : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            labels[idx],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: selected
                                  ? PaceColors.primary
                                  : (PaceColors.lightTextMuted),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Reminder Section (Phase 5)
              _buildLabel('Reminder'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Switch(
                    value: _reminderEnabled,
                    onChanged: (val) => setState(() => _reminderEnabled = val),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _reminderEnabled ? 'Reminder ON' : 'No Reminder',
                    style: TextStyle(
                      fontSize: 14,
                      color: PaceColors.lightTextSecondary,
                    ),
                  ),
                  if (_reminderEnabled) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                        );
                        if (picked != null) {
                          setState(() => _reminderTime = picked);
                        }
                      },
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(
                        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Create/Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submitHabit,
                  style: FilledButton.styleFrom(
                    backgroundColor: PaceColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create Habit',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: PaceColors.lightTextSecondary,
      ),
    );
  }

  void _submitHabit() {
    if (!_formKey.currentState!.validate()) return;

    final nowIso = DateTime.now().toIso8601String();
    final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());

    final targetVal = _habitType == HabitType.binary
        ? 1.0
        : (double.tryParse(_targetController.text) ?? 1.0);

    final unit = _habitType == HabitType.binary
        ? ''
        : (_unitController.text.trim().isNotEmpty
            ? _unitController.text.trim()
            : (_habitType == HabitType.duration ? 'min' : ''));

    final reminderStr = _reminderEnabled
        ? '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
        : null;

    final existing = widget.initialHabit;

    if (existing != null) {
      final updated = existing.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        icon: _icon,
        colorValue: _colorValue,
        habitType: _habitType,
        targetValue: targetVal,
        targetUnit: unit,
        frequency: _frequency,
        selectedWeekdays: _frequency == HabitFrequency.weeklyDays
            ? List<int>.from(_selectedWeekdays)
            : [1, 2, 3, 4, 5, 6, 7],
        reminderTime: reminderStr,
        updatedAt: nowIso,
      );
      ref.read(paceAppProvider.notifier).updateHabit(updated);
    } else {
      final habit = Habit(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        icon: _icon,
        colorValue: _colorValue,
        habitType: _habitType,
        targetValue: targetVal,
        targetUnit: unit,
        frequency: _frequency,
        selectedWeekdays: _frequency == HabitFrequency.weeklyDays
            ? List<int>.from(_selectedWeekdays)
            : [1, 2, 3, 4, 5, 6, 7],
        reminderTime: reminderStr,
        startDate: todayStr,
        createdAt: nowIso,
        updatedAt: nowIso,
      );
      ref.read(paceAppProvider.notifier).createHabit(habit);
    }

    Navigator.of(context).pop();
  }
}
