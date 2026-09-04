import '../models/resume_models.dart';
import 'platform_monetization.dart';

/// What requires [PremiumPurchaseService.isPremium] vs what stays free.
///
/// All resume and cover letter templates are free on every platform.
/// On iOS, AI Resume (ATS create) and cloud backup require Pro.
/// On Android, everything is free (ads monetization).
abstract final class PremiumAccess {
  static const Set<String> coverLetterTemplateTileIds = {
    'executive-note',
    'minimal-letter',
    'sidebar-letter',
    'classic-business-letter',
  };

  /// AI Resume tab — "Create ATS resume" requires Pro on iOS only.
  static bool get atsAiCreateRequiresPremium =>
      PlatformMonetization.isIapEnabled;

  static bool templateTileRequiresPremium(String tileId) {
    return false;
  }

  static bool resumeTemplateRequiresPremium(ResumeTemplate template) {
    return false;
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
