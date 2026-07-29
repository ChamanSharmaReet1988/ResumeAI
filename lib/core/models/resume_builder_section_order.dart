import 'resume_models.dart';

/// Stable ids for resume builder steps after Personal Information.
abstract final class ResumeBuilderSectionIds {
  static const work = 'work';
  static const education = 'education';
  static const skills = 'skills';
  static const projects = 'projects';

  static const bodyDefaults = <String>[
    work,
    education,
    skills,
    projects,
  ];

  static String custom(int index) => 'custom:$index';

  static bool isCustom(String id) => id.startsWith('custom:');

  static int? customIndex(String id) {
    if (!isCustom(id)) {
      return null;
    }
    return int.tryParse(id.substring('custom:'.length));
  }

  static String titleFor(String id, List<CustomSectionItem> customSections) {
    switch (id) {
      case work:
        return 'Work Experience';
      case education:
        return 'Education';
      case skills:
        return 'Skills';
      case projects:
        return 'Projects';
      default:
        final index = customIndex(id);
        if (index == null ||
            index < 0 ||
            index >= customSections.length) {
          return 'Category';
        }
        final title = customSections[index].title.trim();
        if (title.isEmpty) {
          return 'Category ${index + 1}';
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

  for (final id in ResumeBuilderSectionIds.bodyDefaults) {
    if (bodySeen.add(id)) {
      result.add(id);
    }
  }
  while (nextCustom < customCount) {
    result.add(ResumeBuilderSectionIds.custom(nextCustom++));
  }
  return result;
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
    if (ResumeBuilderSectionIds.bodyDefaults.contains(id) &&
        bodySeen.add(id)) {
      result.add(id);
    }
  }

  for (final id in ResumeBuilderSectionIds.bodyDefaults) {
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
