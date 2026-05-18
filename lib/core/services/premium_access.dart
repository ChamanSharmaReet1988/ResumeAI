import '../models/resume_models.dart';

/// What requires [PremiumPurchaseService.isPremium] vs what stays free.
abstract final class PremiumAccess {
  static const String freeProfessionalTemplateTileId = 'dark-header';
  static const String freeAtsTemplateTileId = 'ats-structured';
  static const String freeCoverLetterTemplateTileId = 'executive-note';

  static const Set<String> coverLetterTemplateTileIds = {
    'executive-note',
    'minimal-letter',
    'sidebar-letter',
    'classic-business-letter',
  };

  static bool templateTileRequiresPremium(String tileId) {
    if (tileId == freeProfessionalTemplateTileId ||
        tileId == freeAtsTemplateTileId) {
      return false;
    }
    if (coverLetterTemplateTileIds.contains(tileId)) {
      return coverLetterTemplateTileRequiresPremium(tileId);
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

  static bool coverLetterTemplateRequiresPremium(CoverLetterTemplate template) {
    return switch (template) {
      CoverLetterTemplate.executiveNote => false,
      _ => true,
    };
  }

  static bool coverLetterTemplateTileRequiresPremium(String tileId) {
    return tileId != freeCoverLetterTemplateTileId;
  }

  static const bool iCloudBackupRequiresPremium = true;
}
