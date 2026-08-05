import 'package:flutter/material.dart';
import 'package:resume_app/l10n/app_localizations.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/services/premium_products.dart';

/// Success dialog after a successful purchase or restore.
Future<void> showPremiumWelcomeDialog(
  BuildContext context, {
  required String planLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return PremiumWelcomeDialog(planLabel: planLabel);
    },
  );
}

class PremiumWelcomeDialog extends StatelessWidget {
  const PremiumWelcomeDialog({super.key, required this.planLabel});

  final String planLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final horizontalInset = size.width < 380 ? 18.0 : 28.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalInset),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.premiumWelcomeCongratulations,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.premiumWelcomeBody(
                    planLabel,
                    PremiumProducts.backupSyncBenefit(l10n),
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.continueAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String premiumWelcomePlanLabel(String? productId, AppLocalizations l10n) {
  return PremiumProducts.planLabelFor(productId, l10n);
}
