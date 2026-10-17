import '../models/resume_models.dart';
import 'platform_monetization.dart';

/// What requires [PremiumPurchaseService.isPremium] vs what stays free.
///
/// In Professional, ATS, and Best Pick, the first two templates stay free.
/// The rest need the $1.99 one-time Pro unlock, which also removes ads.
/// Cover letters stay free. AI Resume stays free on Android.
abstract final class PremiumAccess {
  static const Set<String> coverLetterTemplateTileIds = {
    'executive-note',
    'minimal-letter',
    'sidebar-letter',
    'classic-business-letter',
    'accent-bar-letter',
    'ruled-letterhead',
  };

  static const Set<String> freeResumeTileIds = {
    'dark-header',
    'accent-strip',
    'ats-structured',
    'ats-latex-classic',
    'modern-line',
    'split-contact',
  };

  static const Set<ResumeTemplate> freeResumeTemplates = {
    ResumeTemplate.corporate,
    ResumeTemplate.accentStrip,
    ResumeTemplate.atsStructured,
    ResumeTemplate.atsLatexClassic,
    ResumeTemplate.modernLine,
    ResumeTemplate.splitContact,
  };

  /// AI Resume tab (and Create ATS) requires Pro on iOS only.
  static bool get atsAiCreateRequiresPremium => PlatformMonetization.isIos;

  static bool templateTileRequiresPremium(String tileId) {
    if (freeResumeTileIds.contains(tileId)) {
      return false;
    }
    if (coverLetterTemplateTileIds.contains(tileId) ||
        tileId.endsWith('-letter') ||
        tileId.contains('letter')) {
      return false;
    }
    return true;
  }

  static bool resumeTemplateRequiresPremium(ResumeTemplate template) {
    return !freeResumeTemplates.contains(template.userFacingTemplate);
  }

  static bool coverLetterTemplateRequiresPremium(CoverLetterTemplate template) {
    return false;
  }

  static bool coverLetterTemplateTileRequiresPremium(String tileId) {
    return false;
  }

  static bool get iCloudBackupRequiresPremium =>
      PlatformMonetization.isIapEnabled;

  static bool get googleDriveBackupRequiresPremium =>
      PlatformMonetization.isIapEnabled;
}
