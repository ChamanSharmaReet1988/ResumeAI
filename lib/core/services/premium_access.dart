import '../models/resume_models.dart';

/// What requires [PremiumPurchaseService.isPremium] vs what stays free.
abstract final class PremiumAccess {
  static const String freeProfessionalTemplateTileId = 'dark-header';
  static const String freeAtsTemplateTileId = 'ats-structured';

  static bool templateTileRequiresPremium(String tileId) {
    if (tileId == freeProfessionalTemplateTileId ||
        tileId == freeAtsTemplateTileId) {
      return false;
    }
    return true;
  }

  static bool resumeTemplateRequiresPremium(ResumeTemplate template) {
    return switch (template.userFacingTemplate) {
      ResumeTemplate.corporate => false,
      ResumeTemplate.atsStructured => false,
      _ => true,
    };
  }

  /// Cover letters, PDF export, AI, and most app features stay free.
  static bool coverLetterTemplateRequiresPremium(CoverLetterTemplate template) =>
      false;

  static const bool iCloudBackupRequiresPremium = true;
}
