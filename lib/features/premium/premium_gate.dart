import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/premium_access.dart';
import '../../core/services/premium_purchase_service.dart';
import 'go_premium_screen.dart';

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
  return unlocked == true || readPremiumAccess(context);
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

Future<bool> ensurePremiumForICloudBackup(BuildContext context) async {
  if (!PremiumAccess.iCloudBackupRequiresPremium) {
    return true;
  }
  return ensurePremiumAccess(context);
}
