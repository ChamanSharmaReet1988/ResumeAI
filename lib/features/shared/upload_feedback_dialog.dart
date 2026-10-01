import 'package:flutter/material.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

/// Asks how reading an uploaded resume went.
///
/// Resolves to `true` for Good, `false` for Bad, and `null` if the user
/// dismissed it without answering — which is not counted as either.
Future<bool?> showUploadFeedbackDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        title: Text(l10n.uploadFeedbackTitle),
        content: Text(l10n.uploadFeedbackBody),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton.icon(
            key: const Key('upload-feedback-bad'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            icon: const Icon(Icons.thumb_down_outlined),
            label: Text(l10n.uploadFeedbackBad),
          ),
          FilledButton.icon(
            key: const Key('upload-feedback-good'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.thumb_up_outlined),
            label: Text(l10n.uploadFeedbackGood),
          ),
        ],
      );
    },
  );
}
