import '../models/resume_models.dart';

/// What requires [PremiumPurchaseService.isPremium] vs what stays free.
///
/// Pro only removes ads. Templates, AI Resume, and cloud backup stay free.
abstract final class PremiumAccess {
  static bool get atsAiCreateRequiresPremium => false;

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

  static bool get iCloudBackupRequiresPremium => false;

  static bool get googleDriveBackupRequiresPremium => false;
}
