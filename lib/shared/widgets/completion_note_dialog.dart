import 'package:flutter/material.dart';
import '../../core/theme/pace_colors.dart';

class CompletionNoteResult {
  final String? note;
  final bool dontAskAgain;

  const CompletionNoteResult({this.note, this.dontAskAgain = false});
}

class CompletionNoteDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const CompletionNoteDialog({
    super.key,
    required this.title,
    this.subtitle = 'Add an optional note about your completion.',
  });

  static Future<CompletionNoteResult?> show(
    BuildContext context, {
    required String title,
    String subtitle = 'Add an optional note about your completion.',
  }) {
    return showDialog<CompletionNoteResult>(
      context: context,
      builder: (context) => CompletionNoteDialog(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<CompletionNoteDialog> createState() => _CompletionNoteDialogState();
}

class _CompletionNoteDialogState extends State<CompletionNoteDialog> {
  final _controller = TextEditingController();
  bool _dontAskAgain = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PaceColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: PaceColors.lightTextMuted,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: 2,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Notes (optional)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: PaceColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _dontAskAgain = !_dontAskAgain),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _dontAskAgain,
                      onChanged: (val) => setState(() => _dontAskAgain = val ?? false),
                      activeColor: PaceColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Don\'t ask for notes again',
                    style: TextStyle(
                      fontSize: 12,
                      color: PaceColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(CompletionNoteResult(
              note: null,
              dontAskAgain: _dontAskAgain,
            ));
          },
          child: Text(
            'Skip',
            style: TextStyle(color: PaceColors.lightTextMuted),
          ),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            Navigator.of(context).pop(CompletionNoteResult(
              note: text.isEmpty ? null : text,
              dontAskAgain: _dontAskAgain,
            ));
          },
          style: FilledButton.styleFrom(
            backgroundColor: PaceColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
