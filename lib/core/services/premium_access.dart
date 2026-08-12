import '../models/resume_models.dart';

/// What requires [PremiumPurchaseService.isPremium] vs what stays free.
///
/// Professional resume layouts are free. ATS resume layouts require Pro.
abstract final class PremiumAccess {
  static const Set<String> freeProfessionalTemplateTileIds = {
    'dark-header',
    'profile-sidebar',
    'classic-sidebar',
    'accent-strip',
  };

  static const Set<String> atsTemplateTileIds = {
    'ats-structured',
    'ats-latex-classic',
    'ats-modern-flow',
    'ats-executive',
    'ats-center-classic',
    'ats-professional-blue',
  };

  static const String freeCoverLetterTemplateTileId = 'executive-note';

  static const Set<String> coverLetterTemplateTileIds = {
    'executive-note',
    'minimal-letter',
    'sidebar-letter',
    'classic-business-letter',
  };

  /// AI "Create ATS resume" requires Pro (same product surface as ATS templates).
  static const bool atsAiCreateRequiresPremium = true;

  static bool templateTileRequiresPremium(String tileId) {
    if (freeProfessionalTemplateTileIds.contains(tileId)) {
      return false;
    }
    if (atsTemplateTileIds.contains(tileId)) {
      return true;
    }
    if (coverLetterTemplateTileIds.contains(tileId)) {
      return coverLetterTemplateTileRequiresPremium(tileId);
    }
    // Unknown resume tiles default to free professional behavior.
    return false;
  }

  static bool resumeTemplateRequiresPremium(ResumeTemplate template) {
    return switch (template.userFacingTemplate) {
      ResumeTemplate.corporate ||
      ResumeTemplate.creative ||
      ResumeTemplate.classicSidebar ||
      ResumeTemplate.detailsSidebar ||
      ResumeTemplate.accentStrip => false,
      ResumeTemplate.atsStructured ||
      ResumeTemplate.atsSerifRules ||
      ResumeTemplate.atsModernFlow ||
      ResumeTemplate.atsExecutive ||
      ResumeTemplate.atsCenterClassic ||
      ResumeTemplate.atsProfessionalBlue ||
      ResumeTemplate.atsLatexClassic => true,
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
  static const bool googleDriveBackupRequiresPremium = true;
}
