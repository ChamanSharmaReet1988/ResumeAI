import 'package:resume_app/core/models/resume_models.dart';

/// Bullet lines shown in optimized PDF previews (matches [ResumePdfService]).
List<String> resumeExperienceBulletLines(WorkExperience item) {
  final nonEmptyBullets =
      item.bullets.where((bullet) => bullet.trim().isNotEmpty).toList();
  if (nonEmptyBullets.isNotEmpty) {
    return nonEmptyBullets;
  }
  final legacyDescription = item.description.trim();
  if (legacyDescription.isNotEmpty) {
    return [legacyDescription];
  }
  return const <String>[];
}

Set<String> changedResumeExperienceBulletLines({
  required WorkExperience before,
  required WorkExperience after,
}) {
  final beforeLines = resumeExperienceBulletLines(before);
  final afterLines = resumeExperienceBulletLines(after);
  final changed = <String>{};
  for (var index = 0; index < afterLines.length; index++) {
    final line = afterLines[index];
    if (index >= beforeLines.length || beforeLines[index] != line) {
      changed.add(line);
    }
  }
  return changed;
}

class ResumeOptimizeHighlightData {
  const ResumeOptimizeHighlightData({
    required this.beforeResume,
    required this.afterResume,
    required this.highlightSummary,
    required this.highlightedSkills,
    required this.highlightedBulletsByExperience,
  });

  final ResumeData beforeResume;
  final ResumeData afterResume;
  final bool highlightSummary;
  final Set<String> highlightedSkills;
  final Map<int, Set<String>> highlightedBulletsByExperience;
}

ResumeOptimizeHighlightData buildResumeOptimizeHighlightData({
  required ResumeData beforeResume,
  required ResumeData afterResume,
}) {
  final beforeSummary = beforeResume.summary.trim();
  final afterSummary = afterResume.summary.trim();

  final beforeSkills = beforeResume.skillsForResume.toSet();
  final highlightedSkills = afterResume.skillsForResume
      .where((skill) => !beforeSkills.contains(skill))
      .toSet();

  final highlightedBulletsByExperience = <int, Set<String>>{};
  final beforeVisible = beforeResume.visibleWorkExperiences;
  final afterVisible = afterResume.visibleWorkExperiences;
  for (var index = 0; index < afterVisible.length; index++) {
    final beforeExperience = index < beforeVisible.length
        ? beforeVisible[index]
        : const WorkExperience.empty();
    final changed = changedResumeExperienceBulletLines(
      before: beforeExperience,
      after: afterVisible[index],
    );
    if (changed.isNotEmpty) {
      highlightedBulletsByExperience[index] = changed;
    }
  }

  return ResumeOptimizeHighlightData(
    beforeResume: beforeResume,
    afterResume: afterResume,
    highlightSummary: beforeSummary != afterSummary,
    highlightedSkills: highlightedSkills,
    highlightedBulletsByExperience: highlightedBulletsByExperience,
  );
}
