import 'package:flutter/material.dart';
import '../../core/theme/pace_colors.dart';

class ItemNoteDialog extends StatefulWidget {
  final String title;
  final String initialNote;
  final String hintText;

  const ItemNoteDialog({
    super.key,
    required this.title,
    this.initialNote = '',
    this.hintText = 'Add your note or reflection...',
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String initialNote = '',
    String hintText = 'Add your note or reflection...',
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => ItemNoteDialog(
        title: title,
        initialNote: initialNote,
        hintText: hintText,
      ),
    );
  }

  @override
  State<ItemNoteDialog> createState() => _ItemNoteDialogState();
}

class _ItemNoteDialogState extends State<ItemNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasInitialNote = widget.initialNote.trim().isNotEmpty;

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        if (hasInitialNote)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''), // clear/delete note
            style: TextButton.styleFrom(foregroundColor: PaceColors.error),
            child: const Text('Delete Note'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: PaceColors.primary),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
