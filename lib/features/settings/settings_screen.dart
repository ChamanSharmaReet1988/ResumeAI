import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:resume_app/l10n/app_localizations.dart';
import 'package:resume_app/l10n/l10n_ext.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'google_drive_backup_screen.dart';
import 'icloud_backup_screen.dart';
import 'legal_web_view_screen.dart';
import '../premium/go_premium_screen.dart';
import '../premium/premium_gate.dart';
import '../shared/view_models.dart';
import '../../core/app_locale_option.dart';
import '../../core/services/firebase_app_services.dart';
import '../../core/services/platform_monetization.dart';
import '../../core/services/premium_purchase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appStoreId = '6768385894';
  static const String _androidPackageId = 'com.quickresume';
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://reetinfotech.com/apps/resume-builder/privacy-policy/',
  );
  static final Uri _termsOfUseUri = Uri.parse(
    'https://reetinfotech.com/apps/resume-builder/terms-of-use/',
  );
  static final Uri _appStoreUri = Uri.parse(
    'https://apps.apple.com/us/app/resume-builder/id6768385894',
  );
  static final Uri _playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$_androidPackageId',
  );
  bool _isCheckingPremiumStatus = false;

  Uri get _storeListingUri =>
      defaultTargetPlatform == TargetPlatform.iOS ? _appStoreUri : _playStoreUri;

  Uri _buildFeedbackMailtoUri(BuildContext context) {
    final subject = Uri.encodeComponent(context.l10n.feedbackEmailSubject);
    return Uri.parse('mailto:hello@reetinfotech.com?subject=$subject');
  }

  Future<void> _openFeedbackComposer(BuildContext context) async {
    final l10n = context.l10n;
    final mailUri = _buildFeedbackMailtoUri(context);
    final canLaunch = await canLaunchUrl(mailUri);
    if (!context.mounted) {
      return;
    }
    if (!canLaunch) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noMailAppFound)));
      return;
    }

    final launched = await launchUrl(mailUri, mode: LaunchMode.platformDefault);
    if (!context.mounted) {
      return;
    }
    if (!launched) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenMailApp)));
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    final review = InAppReview.instance;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await review.openStoreListing(appStoreId: _appStoreId);
      } else {
        await review.openStoreListing();
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      await _openExternalUrl(context, _storeListingUri);
    }
  }

  Future<void> _openExternalUrl(BuildContext context, Uri uri) async {
    final l10n = context.l10n;
    final canLaunch = await canLaunchUrl(uri);
    if (!context.mounted) {
      return;
    }
    if (!canLaunch) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenLink)));
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!context.mounted) {
      return;
    }
    if (!launched) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenLink)));
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    final l10n = context.l10n;
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    // iPad / macOS require a non-zero anchor for the share sheet popover.
    final origin = Rect.fromCenter(
      center: Offset(
        padding.left + size.width / 2,
        padding.top + size.height / 2,
      ),
      width: 2,
      height: 2,
    );
    await Share.share(
      l10n.shareAppMessage(_storeListingUri.toString()),
      subject: l10n.shareAppSubject,
      sharePositionOrigin: origin,
    );
  }

  Future<void> _openGoPremium(BuildContext context) async {
    if (_isCheckingPremiumStatus) {
      return;
    }
    final premium = context.read<PremiumPurchaseService>();
    setState(() => _isCheckingPremiumStatus = true);
    try {
      await premium.syncPremiumWithStore(
        silent: true,
        reason: 'settings_go_premium_tap',
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingPremiumStatus = false);
      }
    }
    if (!context.mounted) {
      return;
    }
    if (premium.hasConfirmedPremiumStatus) {
      await _showActivePremiumSheet(context, premium);
      return;
    }

    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const GoPremiumScreen()),
    );

    if (!context.mounted) {
      return;
    }
    if (unlocked == true || premium.isPremium) {
      await _showActivePremiumSheet(context, premium);
    }
  }

  Future<void> _showActivePremiumSheet(
    BuildContext context,
    PremiumPurchaseService premium,
  ) async {
    if (premium.debugPremiumOverrideEnabled) {
      await _presentActivePremiumSheet(context, premium);
      return;
    }

    await _presentActivePremiumSheet(context, premium);
  }

  Future<void> _presentActivePremiumSheet(
    BuildContext context,
    PremiumPurchaseService premium,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final planLabel = premium.activeSubscriptionPlanLabel(l10n);
    final sheetTitle = premium.debugPremiumOverrideEnabled
        ? 'Pro access enabled'
        : l10n.alreadySubscribedTitle;
    final sheetHeadline = premium.debugPremiumOverrideEnabled
        ? 'Developer Pro override'
        : l10n.youreOnPlan(planLabel);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sheetTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sheetHeadline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  premium.alreadySubscribedMessage(
                    AppLocalizations.of(sheetContext),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(AppLocalizations.of(sheetContext).ok),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBackup(BuildContext context) async {
    if (!context.mounted) {
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
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

  Future<void> _openLegalPage(
    BuildContext context, {
    required String title,
    required Uri uri,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalWebViewScreen(title: title, url: uri.toString()),
      ),
    );
  }

  // TEMPORARY: dev screen reachable from release builds for internal testing.
  Future<void> _openDeveloperTools(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const _DeveloperToolsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsViewModel, PremiumPurchaseService>(
      builder: (context, settings, premium, _) {
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isIos = defaultTargetPlatform == TargetPlatform.iOS;
        final backupLabel = isIos ? l10n.iCloudBackup : l10n.googleDriveBackup;
        final backupIcon = isIos
            ? Icons.cloud_done_outlined
            : Icons.cloud_queue_outlined;
        final showBackupPremiumIcon =
            PlatformMonetization.isIapEnabled &&
            !premium.hasConfirmedPremiumStatus;
        final rowLabelStyle = theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
        );

        String languageLabel(String code) => switch (code) {
          AppLocaleOption.english => l10n.languageEnglish,
          AppLocaleOption.spanish => l10n.languageSpanish,
          AppLocaleOption.portugueseBrazil => l10n.languagePortugueseBrazil,
          AppLocaleOption.indonesian => l10n.languageIndonesian,
          _ => l10n.languageSystemDefault,
        };

        return Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 20.0;
                const topPadding = 20.0;
                const bottomPadding = 24.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - topPadding - bottomPadding,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.palette_outlined,
                                    size: 22,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.appearance,
                                      style: rowLabelStyle,
                                    ),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: Theme(
                                      data: theme.copyWith(
                                        shadowColor: colorScheme.shadow
                                            .withValues(alpha: 0.24),
                                      ),
                                      child: DropdownButton<ThemeMode>(
                                        value: settings.themeMode,
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        borderRadius: BorderRadius.circular(12),
                                        elevation: 16,
                                        dropdownColor: theme.cardColor,
                                        iconEnabledColor: colorScheme.primary,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w400,
                                            ),
                                        onChanged: (value) {
                                          if (value != null) {
                                            settings.updateThemeMode(value);
                                          }
                                        },
                                        items: [
                                          DropdownMenuItem(
                                            value: ThemeMode.system,
                                            alignment:
                                                AlignmentDirectional.centerEnd,
                                            child: Text(l10n.themeSystem),
                                          ),
                                          DropdownMenuItem(
                                            value: ThemeMode.light,
                                            alignment:
                                                AlignmentDirectional.centerEnd,
                                            child: Text(l10n.themeLight),
                                          ),
                                          DropdownMenuItem(
                                            value: ThemeMode.dark,
                                            alignment:
                                                AlignmentDirectional.centerEnd,
                                            child: Text(l10n.themeDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.language_outlined,
                                    size: 22,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.appLanguage,
                                      style: rowLabelStyle,
                                    ),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: Theme(
                                      data: theme.copyWith(
                                        shadowColor: colorScheme.shadow
                                            .withValues(alpha: 0.24),
                                      ),
                                      child: DropdownButton<String>(
                                        value: settings.appLocaleCode,
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        borderRadius: BorderRadius.circular(12),
                                        elevation: 16,
                                        dropdownColor: theme.cardColor,
                                        iconEnabledColor: colorScheme.primary,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w400,
                                            ),
                                        onChanged: (value) {
                                          if (value != null) {
                                            settings.updateAppLocaleCode(value);
                                          }
                                        },
                                        selectedItemBuilder: (context) {
                                          return [
                                            for (final code
                                                in AppLocaleOption
                                                    .supportedPreferenceCodes)
                                              Align(
                                                alignment: AlignmentDirectional
                                                    .centerEnd,
                                                child: Text(
                                                  languageLabel(code),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ];
                                        },
                                        items: [
                                          for (final code
                                              in AppLocaleOption
                                                  .supportedPreferenceCodes)
                                            DropdownMenuItem(
                                              value: code,
                                              alignment: AlignmentDirectional
                                                  .centerEnd,
                                              child: Text(languageLabel(code)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openBackup(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      backupIcon,
                                      size: 22,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        backupLabel,
                                        style: rowLabelStyle,
                                      ),
                                    ),
                                    if (showBackupPremiumIcon) ...[
                                      const Icon(
                                        Icons.lock_rounded,
                                        size: 18,
                                        color: Color(0xFFC98910),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (PlatformMonetization.isIapEnabled) ...[
                            Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _isCheckingPremiumStatus
                                    ? null
                                    : () => _openGoPremium(context),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.workspace_premium_outlined,
                                        size: 22,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          premium.hasConfirmedPremiumStatus
                                              ? l10n.youAreProUser
                                              : l10n.goPremium,
                                          style: rowLabelStyle,
                                        ),
                                      ),
                                      if (!_isCheckingPremiumStatus) ...[
                                        if (premium
                                            .hasConfirmedPremiumStatus) ...[
                                          const Icon(
                                            Icons.workspace_premium_rounded,
                                            size: 18,
                                            color: Color(0xFFC98910),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openFeedbackComposer(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.feedback_outlined,
                                      size: 22,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l10n.feedback,
                                        style: rowLabelStyle,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _rateApp(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star_outline_rounded,
                                      size: 22,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l10n.rateApp,
                                        style: rowLabelStyle,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openLegalPage(
                                context,
                                title: l10n.privacyPolicy,
                                uri: _privacyPolicyUri,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.privacy_tip_outlined,
                                      size: 22,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l10n.privacyPolicy,
                                        style: rowLabelStyle,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openLegalPage(
                                context,
                                title: l10n.termsOfUse,
                                uri: _termsOfUseUri,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 22,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l10n.termsOfUse,
                                        style: rowLabelStyle,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _shareApp(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.ios_share,
                                      size: 22,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l10n.shareApp,
                                        style: rowLabelStyle,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // TEMPORARY: show version in all builds for internal testing.
                          // const SizedBox(height: 20),
                          // _SettingsVersionFooter(
                          //   onTap: () => _openDeveloperTools(context),
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_isCheckingPremiumStatus)
              Positioned.fill(
                child: ColoredBox(
                  color: colorScheme.surface.withValues(alpha: 0.72),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SettingsVersionFooter extends StatefulWidget {
  const _SettingsVersionFooter({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_SettingsVersionFooter> createState() => _SettingsVersionFooterState();
}

class _SettingsVersionFooterState extends State<_SettingsVersionFooter> {
  late final Future<PackageInfo?> _packageInfoFuture = _loadPackageInfo();

  Future<PackageInfo?> _loadPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<PackageInfo?>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final packageInfo = snapshot.data;
        final versionLabel = packageInfo == null
            ? AppLocalizations.of(context).versionLabel
            : AppLocalizations.of(
                context,
              ).versionWithBuild(packageInfo.version, packageInfo.buildNumber);
        final text = Text(
          versionLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        );

        if (widget.onTap == null) {
          return text;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: text,
          ),
        );
      },
    );
  }
}

class _DeveloperToolsScreen extends StatefulWidget {
  const _DeveloperToolsScreen();

  @override
  State<_DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<_DeveloperToolsScreen> {
  late final Future<PackageInfo?> _packageInfoFuture = _loadPackageInfo();

  Future<PackageInfo?> _loadPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  String _buildModeLabel() {
    if (kReleaseMode) {
      return 'Release';
    }
    if (kProfileMode) {
      return 'Profile';
    }
    return 'Debug';
  }

  String _platformLabel() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  String _firebaseProjectLabel(FirebaseAppServices firebase) {
    if (!firebase.isEnabled) {
      return 'Not configured';
    }
    try {
      return Firebase.app().options.projectId;
    } catch (_) {
      return 'Unavailable';
    }
  }

  String _premiumStatusLabel(PremiumPurchaseService premium) {
    if (premium.debugPremiumOverrideEnabled) {
      return 'Pro (dev override)';
    }
    if (premium.hasConfirmedPremiumStatus) {
      return 'Pro (subscribed)';
    }
    if (premium.isPremium) {
      return 'Pro';
    }
    return 'Free';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final firebase = context.watch<FirebaseAppServices>();

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: SafeArea(
        child: FutureBuilder<PackageInfo?>(
          future: _packageInfoFuture,
          builder: (context, snapshot) {
            final packageInfo = snapshot.data;

            return Consumer<PremiumPurchaseService>(
              builder: (context, premium, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'App info',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _DevInfoRow(
                              label: 'Version',
                              value: packageInfo?.version ?? '—',
                            ),
                            _DevInfoRow(
                              label: 'Build',
                              value: packageInfo?.buildNumber ?? '—',
                            ),
                            _DevInfoRow(
                              label: 'Package',
                              value: packageInfo?.packageName ?? '—',
                            ),
                            _DevInfoRow(
                              label: 'Platform',
                              value: _platformLabel(),
                            ),
                            _DevInfoRow(
                              label: 'Build mode',
                              value: _buildModeLabel(),
                            ),
                            _DevInfoRow(
                              label: 'Premium',
                              value: _premiumStatusLabel(premium),
                            ),
                            _DevInfoRow(
                              label: 'Firebase',
                              value: _firebaseProjectLabel(firebase),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: SwitchListTile(
                        value: premium.isPremium,
                        onChanged: (value) async {
                          await premium.setDeveloperProAccessEnabled(value);
                        },
                        title: Text(
                          'Enable Pro feature',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          premium.isPremium
                              ? 'Pro access is on. Turn off to test the free experience.'
                              : 'Turn on to enable Pro templates and features for testing.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DevInfoRow extends StatelessWidget {
  const _DevInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
