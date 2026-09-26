import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/services/app_preferences.dart';
import '../../core/services/platform_monetization.dart';
import '../premium/premium_gate.dart';
import '../settings/google_drive_backup_screen.dart';
import '../settings/icloud_backup_screen.dart';

/// One-time alert after the first share: offer cloud backup so users keep
/// resumes if they uninstall or change phones.
Future<void> showPostShareBackupPromptIfNeeded(BuildContext context) async {
  if (kIsWeb) {
    return;
  }
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  final prefs = context.read<AppPreferences>();
  if (prefs.postShareBackupPromptDismissed) {
    return;
  }

  final isIos = PlatformMonetization.isIos;
  if (isIos && prefs.iCloudAutoSyncEnabled) {
    await prefs.setPostShareBackupPromptDismissed(true);
    return;
  }
  if (!isIos && prefs.googleDriveAutoSyncEnabled) {
    await prefs.setPostShareBackupPromptDismissed(true);
    return;
  }

  final l10n = context.l10n;
  final goSync = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.keepResumeSafeTitle),
        content: Text(
          isIos ? l10n.keepResumeSafeBodyIcloud : l10n.keepResumeSafeBodyDrive,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.maybeLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              isIos ? l10n.syncToIcloud : l10n.syncToGoogleDrive,
            ),
          ),
        ],
      );
    },
  );

  await prefs.setPostShareBackupPromptDismissed(true);
  if (!context.mounted || goSync != true) {
    return;
  }

  if (isIos) {
    final allowed = await ensurePremiumForICloudBackup(context);
    if (!allowed || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ICloudBackupScreen()),
    );
    return;
  }

  final allowed = await ensurePremiumForGoogleDriveBackup(context);
  if (!allowed || !context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const GoogleDriveBackupScreen()),
  );
}
