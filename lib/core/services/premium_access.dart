import '../models/resume_models.dart';

/// What requires [PremiumPurchaseService.isPremium] vs what stays free.
///
/// Pro unlocks the premium resume templates: in every template section the
/// first half is free and the second half needs Pro. Cover letters, AI Resume,
/// and cloud backup stay free.
abstract final class PremiumAccess {
  static bool get atsAiCreateRequiresPremium => false;

  /// Second half of each Templates section (top picks, creative,
  /// professional, ATS), in the order the tiles are shown.
  static const premiumResumeTemplates = <ResumeTemplate>{
    // Top picks
    ResumeTemplate.harbor,
    ResumeTemplate.typeplate,
    // Creative
    ResumeTemplate.studio,
    ResumeTemplate.arc,
    ResumeTemplate.chevron,
    ResumeTemplate.wave,
    // Professional
    ResumeTemplate.softHeader,
    ResumeTemplate.blueDiagonal,
    ResumeTemplate.minimalProfile,
    ResumeTemplate.charcoalCurve,
    ResumeTemplate.boldPill,
    ResumeTemplate.blueCorner,
    ResumeTemplate.profileTimeline,
    // ATS
    ResumeTemplate.atsCenterClassic,
    ResumeTemplate.atsProfessionalBlue,
    ResumeTemplate.atsClassicCv,
    ResumeTemplate.atsCleanSans,
  };

  /// Template tile ids for [premiumResumeTemplates].
  static const premiumTemplateTileIds = <String>{
    'harbor',
    'typeplate',
    'creative-studio',
    'creative-arc',
    'creative-chevron',
    'creative-wave',
    'soft-header',
    'blue-diagonal',
    'minimal-profile',
    'charcoal-curve',
    'bold-pill',
    'blue-corner',
    'profile-timeline',
    'ats-center-classic',
    'ats-professional-blue',
    'ats-classic-cv',
    'ats-clean-sans',
  };

  static bool templateTileRequiresPremium(String tileId) {
    return premiumTemplateTileIds.contains(tileId);
  }

  static bool resumeTemplateRequiresPremium(ResumeTemplate template) {
    return premiumResumeTemplates.contains(template.userFacingTemplate);
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
