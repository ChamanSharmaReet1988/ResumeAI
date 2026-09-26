import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/l10n_ext.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/in_app_review_prompt_service.dart';

enum RetentionFeedbackAction { sendFeedback, rateApp, keepUsing, later }

/// Soft retention dialog: ask for feedback instead of uninstalling.
Future<RetentionFeedbackAction?> showRetentionFeedbackDialog(
  BuildContext context,
) {
  final l10n = context.l10n;
  return showDialog<RetentionFeedbackAction>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.retentionFeedbackTitle),
        content: Text(l10n.retentionFeedbackBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              RetentionFeedbackAction.later,
            ),
            child: Text(l10n.maybeLater),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              RetentionFeedbackAction.keepUsing,
            ),
            child: Text(l10n.keepUsingApp),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              RetentionFeedbackAction.rateApp,
            ),
            child: Text(l10n.rateApp),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              RetentionFeedbackAction.sendFeedback,
            ),
            child: Text(l10n.sendFeedback),
          ),
        ],
      );
    },
  );
}

Uri retentionFeedbackMailtoUri(String subject) {
  final encoded = Uri.encodeComponent(subject);
  return Uri.parse('mailto:hello@reetinfotech.com?subject=$encoded');
}

/// Shows the retention dialog and handles feedback / rate / dismiss.
Future<void> presentRetentionFeedbackPrompt(BuildContext context) async {
  final review = context.read<InAppReviewPromptService>();
  final action = await showRetentionFeedbackDialog(context);
  if (!context.mounted) {
    return;
  }

  switch (action) {
    case RetentionFeedbackAction.sendFeedback:
      await review.markRatingCompleted();
      if (!context.mounted) {
        return;
      }
      final uri = retentionFeedbackMailtoUri(context.l10n.feedbackEmailSubject);
      final opened = await canLaunchUrl(uri) &&
          await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotOpenLink)),
        );
      }
    case RetentionFeedbackAction.rateApp:
      await review.markRatingCompleted();
      await review.requestNativeReview();
    case RetentionFeedbackAction.keepUsing:
      await review.markRatingCompleted();
    case RetentionFeedbackAction.later:
    case null:
      review.deferUntilNextHomeVisit();
  }
}
