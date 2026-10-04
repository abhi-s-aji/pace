import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/models/models.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';

class JournalEditorSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final JournalEntry? existingEntry;

  const JournalEditorSheet({
    super.key,
    required this.date,
    this.existingEntry});

  @override
  ConsumerState<JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends ConsumerState<JournalEditorSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = 'good';
  bool _isSaving = false;

  static const _moods = [
    {'key': 'great', 'label': 'Great', 'icon': Icons.sentiment_very_satisfied_rounded},
    {'key': 'good', 'label': 'Good', 'icon': Icons.sentiment_satisfied_rounded},
    {'key': 'neutral', 'label': 'Neutral', 'icon': Icons.sentiment_neutral_rounded},
    {'key': 'low', 'label': 'Low', 'icon': Icons.sentiment_dissatisfied_rounded},
    {'key': 'tough', 'label': 'Tough', 'icon': Icons.sentiment_very_dissatisfied_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _titleController.text = widget.existingEntry!.title;
      _contentController.text = widget.existingEntry!.content;
      _selectedMood = widget.existingEntry!.mood;
    } else {
      _titleController.text = 'Daily Reflection';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide both a title and reflection notes.'),
          backgroundColor: PaceColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dateStr = PaceDateUtils.toIsoDateString(widget.date);

    await ref.read(paceAppProvider.notifier).saveJournalEntry(
          dateStr: dateStr,
          title: title,
          content: content,
          mood: _selectedMood,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Journal entry saved.'),
          backgroundColor: PaceColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    if (widget.existingEntry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Journal Entry?'),
        content: const Text('Are you sure you want to delete this reflection? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: PaceColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(paceAppProvider.notifier).deleteJournalEntry(widget.existingEntry!.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Journal entry deleted.'),
            backgroundColor: PaceColors.darkTextSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.existingEntry == null ? 'New Journal Entry' : 'Edit Reflection',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PaceDateUtils.formatFullDate(widget.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: PaceColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                if (widget.existingEntry != null)
                  IconButton(
                    onPressed: _handleDelete,
                    icon: Icon(Icons.delete_outline_rounded, color: PaceColors.error),
                    tooltip: 'Delete Entry',
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Mood Selector
            Text(
              'How was your day?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PaceColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moods.map((m) {
                final selected = _selectedMood == m['key'];
                final label = m['label'] as String;
                return Semantics(
                  label: 'Mood $label',
                  selected: selected,
                  button: true,
                  child: InkWell(
                    onTap: () => setState(() => _selectedMood = m['key'] as String),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? PaceColors.primary.withValues(alpha: 0.15)
                            : (PaceColors.lightSurfaceElevated),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? PaceColors.primary
                              : (PaceColors.lightBorder),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            m['icon'] as IconData,
                            size: 22,
                            color: selected
                                ? PaceColors.primary
                                : (PaceColors.lightTextMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected
                                  ? PaceColors.primary
                                  : (PaceColors.lightTextMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Title Field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Focused morning, Productive day',
              ),
            ),
            const SizedBox(height: 16),

            // Content Field
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Reflection Notes',
                hintText: 'Write about what you accomplished, challenges faced, or thoughts for tomorrow...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Reflection', style: TextStyle(fontWeight: FontWeight.bold)),
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
