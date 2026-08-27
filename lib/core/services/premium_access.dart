import '../models/resume_models.dart';

/// What requires [PremiumPurchaseService.isPremium] vs what stays free.
///
/// All resume and cover letter templates are free.
/// AI Resume (ATS create) and cloud backup require Pro.
abstract final class PremiumAccess {
  static const Set<String> coverLetterTemplateTileIds = {
    'executive-note',
    'minimal-letter',
    'sidebar-letter',
    'classic-business-letter',
  };

  /// AI Resume tab — "Create ATS resume" requires Pro.
  static const bool atsAiCreateRequiresPremium = true;

  static bool templateTileRequiresPremium(String tileId) {
    // All resume + cover letter templates are free.
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

  static const bool iCloudBackupRequiresPremium = true;
  static const bool googleDriveBackupRequiresPremium = true;
}
