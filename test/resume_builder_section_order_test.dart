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
    final result = canonicalizeBuilderSectionOrder(
      ['skills', 'custom:1', 'work', 'custom:0', 'education', 'projects'],
      customs,
    );
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
}
