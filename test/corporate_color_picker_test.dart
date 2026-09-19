import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/corporate_resume_style.dart';
import 'package:resume_app/core/models/resume_models.dart';

void main() {
  test('resume color picker puts the template default color first', () {
    for (final template in ResumeTemplate.values) {
      final defaultIndex = defaultColorPresetIndexForTemplate(template);
      final swatches = resumeColorPickerSwatches(template);

      expect(swatches, isNotEmpty);
      expect(swatches.first.index, defaultIndex);
      expect(
        swatches.first.preset.headerColor,
        templateDefaultColorPreset(template).headerColor,
      );
      expect(swatches.map((item) => item.index).toSet().length, swatches.length);
    }
  });

  test('classic sidebar default stays first after other presets', () {
    final swatches = resumeColorPickerSwatches(ResumeTemplate.classicSidebar);

    expect(swatches.first.index, 2);
    expect(swatches.skip(1).map((item) => item.index), isNot(contains(2)));
  });
}
