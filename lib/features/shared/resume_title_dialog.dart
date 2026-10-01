import 'package:flutter/material.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

/// Asks for a resume title. Used for both Rename and Duplicate; pops the typed
/// text, or null when cancelled.
class ResumeTitleDialog extends StatefulWidget {
  const ResumeTitleDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.initialTitle,
    required this.fieldKey,
  });

  final String title;
  final String actionLabel;
  final String initialTitle;
  final Key fieldKey;

  @override
  State<ResumeTitleDialog> createState() => _ResumeTitleDialogState();
}

class _ResumeTitleDialogState extends State<ResumeTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.resumeTitle,
          hintText: l10n.enterResumeTitle,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}
