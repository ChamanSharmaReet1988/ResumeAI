import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/premium_access.dart';
import '../../core/services/premium_purchase_service.dart';
import '../shell/app_shell_scope.dart';
import 'go_premium_screen.dart';
import 'premium_welcome_dialog.dart';

bool hasPremiumAccess(BuildContext context) {
  return context.watch<PremiumPurchaseService>().isPremium;
}

bool readPremiumAccess(BuildContext context) {
  return context.read<PremiumPurchaseService>().isPremium;
}

bool templateTileRequiresPremium({required String templateTileId}) {
  return PremiumAccess.templateTileRequiresPremium(templateTileId);
}

bool resumeTemplateRequiresPremium(ResumeTemplate template) {
  return PremiumAccess.resumeTemplateRequiresPremium(template);
}

bool coverLetterTemplateRequiresPremium(CoverLetterTemplate template) {
  return PremiumAccess.coverLetterTemplateRequiresPremium(template);
}

/// Returns `true` when the user already has Premium or completes a purchase.
Future<bool> ensurePremiumAccess(BuildContext context) async {
  if (readPremiumAccess(context)) {
    return true;
  }

  final unlocked = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => const GoPremiumScreen(),
    ),
  );

  if (!context.mounted) {
    return false;
  }
  final premium = context.read<PremiumPurchaseService>();
  final hasAccess = unlocked == true || readPremiumAccess(context);
  if (hasAccess) {
    AppShellScope.goToSettings(context);
    if (premium.consumePremiumWelcomePending() && context.mounted) {
      final planLabel = premiumWelcomePlanLabel(
        premium.activeSubscriptionProductId,
      );
      unawaited(
        showPremiumWelcomeDialog(context, planLabel: planLabel),
      );
    }
  }
  return hasAccess;
}

Future<bool> ensurePremiumForTemplateTile(
  BuildContext context, {
  required String templateTileId,
}) async {
  if (!templateTileRequiresPremium(templateTileId: templateTileId)) {
    return true;
  }
  return ensurePremiumAccess(context);
}

Future<bool> ensurePremiumForResumeTemplate(
  BuildContext context,
  ResumeTemplate template,
) async {
  if (!resumeTemplateRequiresPremium(template)) {
    return true;
  }
  return ensurePremiumAccess(context);
}

Future<bool> ensurePremiumForCoverLetterTemplate(
  BuildContext context,
  CoverLetterTemplate template,
) async {
  if (!coverLetterTemplateRequiresPremium(template)) {
    return true;
  }
  return ensurePremiumAccess(context);
}

Future<bool> ensurePremiumForICloudBackup(BuildContext context) async {
  if (!PremiumAccess.iCloudBackupRequiresPremium) {
    return true;
  }
  return ensurePremiumAccess(context);
}
