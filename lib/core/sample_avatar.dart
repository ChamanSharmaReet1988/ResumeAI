import 'models/resume_models.dart';

/// Bundled flat/dummy placeholder (legacy). Prefer male/female photo assets.
const String kSampleAvatarAsset = 'assets/images/sample_avatar.png';

/// Real male headshot used by Corporate, Profile Sidebar, Classic Sidebar,
/// and Minimal Profile gallery samples.
const String kSampleAvatarMaleAsset = 'assets/images/sample_avatar_male.png';

/// Real female headshot used by Charcoal Curve gallery samples.
const String kSampleAvatarFemaleAsset = 'assets/images/sample_avatar_female.png';

/// Gallery placeholder for the given template.
String gallerySampleAvatarAsset(ResumeTemplate template) {
  return switch (template) {
    ResumeTemplate.corporate ||
    ResumeTemplate.creative ||
    ResumeTemplate.classicSidebar ||
    ResumeTemplate.minimalProfile =>
      kSampleAvatarMaleAsset,
    ResumeTemplate.charcoalCurve => kSampleAvatarFemaleAsset,
    _ => kSampleAvatarAsset,
  };
}
