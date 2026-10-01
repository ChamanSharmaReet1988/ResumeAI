import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_builder_section_order.dart';
import 'package:resume_app/core/models/resume_models.dart';

void main() {
  test('normalizeBuilderSectionOrder fills defaults and customs', () {
    final order = normalizeBuilderSectionOrder(null, 2);
    expect(order, [
      'work',
      'education',
      'skills',
      'projects',
      'custom:0',
      'custom:1',
    ]);
  });

  test('canonicalizeBuilderSectionOrder remaps custom indexes', () {
    final customs = [
      const CustomSectionItem(title: 'A', content: 'a'),
      const CustomSectionItem(title: 'B', content: 'b'),
    ];
    final result = canonicalizeBuilderSectionOrder([
      'skills',
      'custom:1',
      'work',
      'custom:0',
      'education',
      'projects',
    ], customs);
    expect(result.order, [
      'skills',
      'custom:0',
      'work',
      'custom:1',
      'education',
      'projects',
    ]);
    expect(result.customSections.map((item) => item.title), ['B', 'A']);
  });
  group('projects is the one optional section', () {
    test('a stored order without projects stays without it', () {
      expect(normalizeBuilderSectionOrder(['work', 'education', 'skills'], 0), [
        'work',
        'education',
        'skills',
      ]);
      expect(
        normalizeBuilderSectionOrder([
          'skills',
          'work',
          'custom:0',
          'education',
        ], 1),
        ['skills', 'work', 'custom:0', 'education'],
      );
    });

    test('no stored order at all still gets every section', () {
      expect(normalizeBuilderSectionOrder(null, 0), [
        'work',
        'education',
        'skills',
        'projects',
      ]);
    });

    test('an empty stored order stays empty', () {
      expect(normalizeBuilderSectionOrder(const [], 0), isEmpty);
    });

    test('a removed built-in section stays removed', () {
      expect(normalizeBuilderSectionOrder(['skills'], 0), ['skills']);
    });

    test('reordering does not bring projects back', () {
      final result = canonicalizeBuilderSectionOrder([
        'skills',
        'work',
        'education',
      ], const []);
      expect(result.order, ['skills', 'work', 'education']);
    });

    test('a resume saved with projects keeps it', () {
      final saved = ResumeData.empty(
        template: ResumeTemplate.corporate,
      ).copyWith(builderSectionOrder: ResumeBuilderSectionIds.bodyDefaults);
      final restored = ResumeData.fromJson(saved.toJson());
      expect(restored.effectiveBuilderSectionOrder, contains('projects'));
    });

    test('a resume saved before section order existed keeps it', () {
      final json = ResumeData.empty(template: ResumeTemplate.corporate).toJson()
        ..remove('builderSectionOrder');
      expect(
        ResumeData.fromJson(json).effectiveBuilderSectionOrder,
        contains('projects'),
      );
    });

    test('an existing projects section stays listed and included', () {
      final saved = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(
            includeProjectsInResume: false,
            builderSectionOrder: ResumeBuilderSectionIds.bodyDefaults,
            projects: const [ProjectItem(title: 'Billing portal')],
          );
      final restored = ResumeData.fromJson(saved.toJson());
      expect(
        restored.effectiveBuilderSectionOrder,
        contains(ResumeBuilderSectionIds.projects),
      );
      expect(restored.includeProjectsInResume, isTrue);
    });

    test('project entries on an older resume bring the section back on', () {
      final saved = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(
            includeProjectsInResume: true,
            builderSectionOrder: ResumeBuilderSectionIds.newResumeDefaults,
            projects: const [ProjectItem(title: 'Billing portal')],
          );
      final restored = ResumeData.fromJson(saved.toJson());
      expect(restored.builderSectionOrder, [
        'work',
        'education',
        'skills',
        'projects',
        'custom:0',
        'custom:1',
      ]);
      expect(restored.includeProjectsInResume, isTrue);
    });

    test('a new resume starts without projects', () {
      final resume = ResumeData.empty(template: ResumeTemplate.corporate);
      expect(resume.effectiveBuilderSectionOrder, [
        'custom:0',
        'work',
        'custom:1',
        'education',
        'skills',
      ]);
      expect(resume.customSections.map((item) => item.title), [
        'Objective',
        'References',
      ]);
      expect(
        resume.customSections.every((item) => !item.showEntryDetails),
        isTrue,
      );
      // ...and keeps that through a save and reload.
      expect(
        ResumeData.fromJson(resume.toJson()).effectiveBuilderSectionOrder,
        ['custom:0', 'work', 'custom:1', 'education', 'skills'],
      );
    });
  });
}
