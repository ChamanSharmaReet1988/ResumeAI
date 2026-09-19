import 'models/resume_models.dart';

/// Bundled placeholder photo for most gallery samples.
const String kSampleAvatarAsset = 'assets/images/sample_avatar.png';

/// Male headshot used by Corporate, Profile Sidebar, and Classic Sidebar
/// gallery samples.
const String kSampleAvatarMaleAsset = 'assets/images/sample_avatar_male.png';

/// Gallery placeholder for the given template.
String gallerySampleAvatarAsset(ResumeTemplate template) {
  return switch (template) {
    ResumeTemplate.corporate ||
    ResumeTemplate.creative ||
    ResumeTemplate.classicSidebar ||
    ResumeTemplate.minimalProfile =>
      kSampleAvatarMaleAsset,
    _ => kSampleAvatarAsset,
  };
}
