import 'package:resume_app/l10n/app_localizations.dart';

import 'resume_models.dart';

/// Stable ids for resume builder steps after Personal Information.
abstract final class ResumeBuilderSectionIds {
  static const work = 'work';
  static const education = 'education';
  static const skills = 'skills';
  static const projects = 'projects';

  static const bodyDefaults = <String>[work, education, skills, projects];

  /// Built-in sections a brand-new resume starts with. Projects is left out.
  /// Objective and References are added as normal custom sections around Work.
  static const newResumeDefaults = <String>[work, education, skills];

  /// Section list for a brand-new resume: Objective, Work Experience,
  /// References, Education, Skills.
  static List<String> get starterSectionOrder => <String>[
    custom(0),
    work,
    custom(1),
    education,
    skills,
  ];

  /// Built-in sections that stay out of the list once a resume has stored
  /// an order without them. Personal Information is not in this list; the
  /// user can remove any other section and it stays removed.
  static const optionalSections = <String>{work, education, skills, projects};

  static String custom(int index) => 'custom:$index';

  /// Preview/PDF copy whose built-in headings and empty custom titles match
  /// the section list in [l10n]. Personal information stays a header, not a
  /// section title.
  static ResumeData resumeWithSectionListTitles(
    ResumeData resume,
    AppLocalizations l10n,
  ) {
    final titles = Map<String, String>.from(resume.sectionTitles);
    void fill(String id, String label) {
      if ((titles[id]?.trim() ?? '').isEmpty) {
        titles[id] = label;
      }
    }

    fill(work, l10n.sectionWorkExperience);
    fill(education, l10n.sectionEducation);
    fill(skills, l10n.sectionSkills);
    fill(projects, l10n.sectionProjects);
    final sections = <CustomSectionItem>[
      for (var i = 0; i < resume.customSections.length; i++)
        resume.customSections[i].title.trim().isEmpty
            ? resume.customSections[i].copyWith(
                title: l10n.categoryNumber(i + 1),
              )
            : resume.customSections[i],
    ];
    return resume.copyWith(sectionTitles: titles, customSections: sections);
  }

  static bool isCustom(String id) => id.startsWith('custom:');

  static int? customIndex(String id) {
    if (!isCustom(id)) {
      return null;
    }
    return int.tryParse(id.substring('custom:'.length));
  }

  /// [sectionTitles] carries the user's renames, from [ResumeData.sectionTitles].
  static String titleFor(
    String id,
    List<CustomSectionItem> customSections,
    AppLocalizations l10n, {
    Map<String, String> sectionTitles = const <String, String>{},
  }) {
    final renamed = sectionTitles[id]?.trim() ?? '';
    if (renamed.isNotEmpty) {
      return renamed;
    }
    switch (id) {
      case work:
        return l10n.sectionWorkExperience;
      case education:
        return l10n.sectionEducation;
      case skills:
        return l10n.sectionSkills;
      case projects:
        return l10n.sectionProjects;
      default:
        final index = customIndex(id);
        if (index == null || index < 0 || index >= customSections.length) {
          return l10n.category;
        }
        final title = customSections[index].title.trim();
        if (title.isEmpty) {
          return l10n.categoryNumber(index + 1);
        }
        if (title.length > 22) {
          return '${title.substring(0, 21)}…';
        }
        return title;
    }
  }
}

/// Ensures [stored] lists every body section once and exactly [customCount]
/// custom slots (`custom:0` …).
List<String> normalizeBuilderSectionOrder(
  List<String>? stored,
  int customCount,
) {
  final result = <String>[];
  final bodySeen = <String>{};
  var nextCustom = 0;

  for (final raw in stored ?? const <String>[]) {
    final customIdx = ResumeBuilderSectionIds.customIndex(raw);
    if (customIdx != null) {
      if (nextCustom < customCount) {
        result.add(ResumeBuilderSectionIds.custom(nextCustom++));
      }
      continue;
    }
    if (ResumeBuilderSectionIds.bodyDefaults.contains(raw) &&
        bodySeen.add(raw)) {
      result.add(raw);
    }
  }

  // A missing order (very old saves) gets every section. A saved order is
  // kept as stored, including when the user has removed a section.
  final hasStoredOrder = stored != null;
  for (final id in ResumeBuilderSectionIds.bodyDefaults) {
    if (hasStoredOrder &&
        ResumeBuilderSectionIds.optionalSections.contains(id)) {
      continue;
    }
    if (bodySeen.add(id)) {
      result.add(id);
    }
  }
  while (nextCustom < customCount) {
    result.add(ResumeBuilderSectionIds.custom(nextCustom++));
  }
  return result;
}

/// Puts Projects into [order] when this resume already has that section.
///
/// A brand-new resume stores an order without Projects. An older resume that
/// lists it, or that already has project entries, keeps the section in its
/// usual place (after Skills, before any custom sections).
List<String> orderWithExistingProjectsSection(
  List<String> order, {
  required bool keepProjects,
}) {
  if (!keepProjects || order.contains(ResumeBuilderSectionIds.projects)) {
    return order;
  }
  final updated = [...order];
  final skillsIndex = updated.indexOf(ResumeBuilderSectionIds.skills);
  if (skillsIndex >= 0) {
    updated.insert(skillsIndex + 1, ResumeBuilderSectionIds.projects);
    return updated;
  }
  final customIndex = updated.indexWhere(ResumeBuilderSectionIds.isCustom);
  final index = customIndex >= 0 ? customIndex : updated.length;
  updated.insert(index, ResumeBuilderSectionIds.projects);
  return updated;
}

/// After a drag reorder, remap `custom:N` tokens to a dense sequence and
/// return custom sections in that visual order.
({List<String> order, List<CustomSectionItem> customSections})
canonicalizeBuilderSectionOrder(
  List<String> order,
  List<CustomSectionItem> customSections,
) {
  final bodySeen = <String>{};
  final usedCustomIndexes = <int>{};
  final newCustoms = <CustomSectionItem>[];
  final result = <String>[];

  for (final id in order) {
    final customIdx = ResumeBuilderSectionIds.customIndex(id);
    if (customIdx != null) {
      if (customIdx >= 0 &&
          customIdx < customSections.length &&
          usedCustomIndexes.add(customIdx)) {
        result.add(ResumeBuilderSectionIds.custom(newCustoms.length));
        newCustoms.add(customSections[customIdx]);
      }
      continue;
    }
    if (ResumeBuilderSectionIds.bodyDefaults.contains(id) && bodySeen.add(id)) {
      result.add(id);
    }
  }

  for (final id in ResumeBuilderSectionIds.bodyDefaults) {
    if (ResumeBuilderSectionIds.optionalSections.contains(id)) {
      continue;
    }
    if (bodySeen.add(id)) {
      result.add(id);
    }
  }
  for (var i = 0; i < customSections.length; i++) {
    if (usedCustomIndexes.add(i)) {
      result.add(ResumeBuilderSectionIds.custom(newCustoms.length));
      newCustoms.add(customSections[i]);
    }
  }

  return (order: result, customSections: newCustoms);
}

/// Body section ids for resume preview (after Summary / header).
///
/// When [followOrder] is true, uses the user's builder chip order.
/// When false (template gallery), uses the default Work→Education→Skills→
/// Projects→customs sequence.
List<String> previewBodySectionOrder(
  ResumeData resume, {
  required bool followOrder,
  Set<String> exclude = const {},
}) {
  final base = followOrder
      ? resume.effectiveBuilderSectionOrder
      : [
          ...ResumeBuilderSectionIds.bodyDefaults,
          for (var i = 0; i < resume.customSections.length; i++)
            ResumeBuilderSectionIds.custom(i),
        ];
  if (exclude.isEmpty) {
    return List<String>.from(base);
  }
  return base.where((id) => !exclude.contains(id)).toList();
}
