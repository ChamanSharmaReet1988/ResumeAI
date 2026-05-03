import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/view_models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://resumeai.app/privacy-policy',
  );
  static final Uri _termsOfUseUri = Uri.parse(
    'https://resumeai.app/terms-of-use',
  );
  static final Uri _backupUri = Uri.parse('https://resumeai.app/backup');
  static final Uri _goPremiumUri = Uri.parse('https://resumeai.app/premium');

  Uri _buildFeedbackMailtoUri() {
    final subject = Uri.encodeComponent('ResumeAI App Feedback');
    return Uri.parse(
      'mailto:swiftdeveloper1988@gmail.com?subject=$subject',
    );
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
    final available = await review.isAvailable();
    if (!context.mounted) {
      return;
    }
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating is not available right now.')),
      );
      return;
    }

    await review.requestReview();
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
      'Check out ResumeAI app.',
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final rowLabelStyle = theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                          'Appearance',
                          style: rowLabelStyle,
                        ),
                      ),
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
                  onTap: () => _openExternalUrl(context, _backupUri),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 22,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Backup', style: rowLabelStyle),
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
                  onTap: () => _openExternalUrl(context, _goPremiumUri),
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
                          child: Text('Go Premium', style: rowLabelStyle),
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
                          child: Text('Feedback', style: rowLabelStyle),
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
                          child: Text('Rate app', style: rowLabelStyle),
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
                  onTap: () => _openExternalUrl(context, _privacyPolicyUri),
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
                  onTap: () => _openExternalUrl(context, _termsOfUseUri),
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
                        Expanded(
                          child: Text('Share', style: rowLabelStyle),
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
            ],
          ),
        );
      },
    );
  }
}
