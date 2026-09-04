import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

/// Returns `true` when the user chooses to rate.
Future<bool> showRateAppPromptDialog(BuildContext context) async {
  final l10n = context.l10n;
  final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

  final result = isCupertino
      ? await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return CupertinoAlertDialog(
              title: Text(l10n.ratePromptTitle),
              content: Text(l10n.ratePromptBody),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.maybeLater),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.rateApp),
                ),
              ],
            );
          },
        )
      : await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(l10n.ratePromptTitle),
              content: Text(l10n.ratePromptBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.maybeLater),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.rateApp),
                ),
              ],
            );
          },
        );

  return result == true;
}
