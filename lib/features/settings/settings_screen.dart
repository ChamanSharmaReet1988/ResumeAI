import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../shell/app_shell_scope.dart';
import '../shared/view_models.dart';
import '../../core/services/premium_purchase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appStoreId = '6768385894';
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://sites.google.com/mindplexapp.com/resumeapp/privacy-policy',
  );
  static final Uri _termsOfUseUri = Uri.parse(
    'https://sites.google.com/mindplexapp.com/resumeapp/terms',
  );
  static final Uri _appStoreUri = Uri.parse(
    'https://apps.apple.com/us/app/resume-builder/id6768385894',
  );
  static const String _shareSubject = 'ResumeApp';
  static String get _shareMessage =>
      'Check out ResumeApp to create, optimize, and share professional resumes on iPhone. '
      'Get it on the App Store: ${_appStoreUri.toString()}';
  bool _isCheckingPremiumStatus = false;

  Uri _buildFeedbackMailtoUri() {
    final subject = Uri.encodeComponent('ResumeApp Feedback');
    return Uri.parse('mailto:hello@mindplexapp.com?subject=$subject');
  }

  Future<void> _openFeedbackComposer(BuildContext context) async {
    final mailUri = _buildFeedbackMailtoUri();
    final canLaunch = await canLaunchUrl(mailUri);
    if (!context.mounted) {
      return;
    }
    if (!canLaunch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No mail app found. Please configure a mail app.'),
        ),
      );
      return;
    }

    final launched = await launchUrl(mailUri, mode: LaunchMode.platformDefault);
    if (!context.mounted) {
      return;
    }
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open mail app. Please try again.'),
        ),
      );
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    final review = InAppReview.instance;
    try {
      await review.openStoreListing(appStoreId: _appStoreId);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      await _openExternalUrl(context, _appStoreUri);
    }
  }

  Future<void> _openExternalUrl(BuildContext context, Uri uri) async {
    final canLaunch = await canLaunchUrl(uri);
    if (!context.mounted) {
      return;
    }
    if (!canLaunch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link right now.')),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!context.mounted) {
      return;
    }
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link right now.')),
      );
    }
  }

  Future<void> _shareApp(BuildContext context) async {
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
      _shareMessage,
      subject: _shareSubject,
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
    if (premium.isPremium) {
      await _showActivePremiumSheet(context, premium);
      return;
    }

    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const GoPremiumScreen(),
      ),
    );

    if (!context.mounted) {
      return;
    }
    if (unlocked == true || premium.isPremium) {
      AppShellScope.goToSettings(context);
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
    final planLabel = premium.activeSubscriptionPlanLabel;
    final sheetTitle = premium.debugPremiumOverrideEnabled
        ? 'Pro access enabled'
        : 'Already subscribed';
    final sheetHeadline = premium.debugPremiumOverrideEnabled
        ? 'Developer Pro override'
        : 'You\'re on the $planLabel';

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
                  premium.alreadySubscribedMessage(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('OK'),
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GoogleDriveBackupScreen(),
      ),
    );
  }

  Future<void> _openLegalPage(
    BuildContext context, {
    required String title,
    required Uri uri,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalWebViewScreen(
          title: title,
          url: uri.toString(),
        ),
      ),
    );
  }

  Future<void> _openDeveloperTools(BuildContext context) async {
    if (!kDebugMode) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _DeveloperToolsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsViewModel, PremiumPurchaseService>(
      builder: (context, settings, premium, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isIos = defaultTargetPlatform == TargetPlatform.iOS;
        final backupLabel =
            isIos ? 'iCloud Backup' : 'Google Drive Backup';
        final backupIcon =
            isIos ? Icons.cloud_done_outlined : Icons.cloud_queue_outlined;
        final rowLabelStyle = theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
        );

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
                      Expanded(child: Text('Appearance', style: rowLabelStyle)),
                      DropdownButtonHideUnderline(
                        child: Theme(
                          data: theme.copyWith(
                            shadowColor: colorScheme.shadow.withValues(
                              alpha: 0.24,
                            ),
                          ),
                          child: DropdownButton<ThemeMode>(
                            value: settings.themeMode,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 16,
                            dropdownColor: theme.cardColor,
                            iconEnabledColor: colorScheme.primary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w400,
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                settings.updateThemeMode(value);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('System'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Light'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Dark'),
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
                          child: Text(backupLabel, style: rowLabelStyle),
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
                            premium.isPremium
                                ? 'You are a Pro user'
                                : 'Go Premium',
                            style: rowLabelStyle,
                          ),
                        ),
                        if (!_isCheckingPremiumStatus) ...[
                          if (premium.isPremium) ...[
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
                        Expanded(child: Text('Feedback', style: rowLabelStyle)),
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
                        Expanded(child: Text('Rate app', style: rowLabelStyle)),
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
                    title: 'Privacy Policy',
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
                          child: Text('Privacy Policy', style: rowLabelStyle),
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
                    title: 'Terms of Use',
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
                          child: Text('Terms of Use', style: rowLabelStyle),
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
                        Expanded(child: Text('Share', style: rowLabelStyle)),
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
                      if (kDebugMode) ...[
                        const SizedBox(height: 20),
                        _SettingsVersionFooter(
                          onTap: () => _openDeveloperTools(context),
                        ),
                      ],
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
            ? 'Version'
            : 'Version ${packageInfo.version} (${packageInfo.buildNumber})';
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

class _DeveloperToolsScreen extends StatelessWidget {
  const _DeveloperToolsScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: SafeArea(
        child: Consumer<PremiumPurchaseService>(
          builder: (context, premium, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
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
        ),
      ),
    );
  }
}
