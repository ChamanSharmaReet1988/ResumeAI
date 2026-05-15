import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/features/ai/resume_optimize_highlight.dart';

void main() {
  test('maps changed bullets to visible experience indices', () {
    const before = WorkExperience(
      role: 'Engineer',
      company: 'Acme',
      startDate: '2020',
      endDate: '2022',
      description: '',
      bullets: ['Kept bullet'],
    );
    const after = WorkExperience(
      role: 'Engineer',
      company: 'Acme',
      startDate: '2020',
      endDate: '2022',
      description: '',
      bullets: ['Rewritten bullet'],
    );

    final data = buildResumeOptimizeHighlightData(
      beforeResume: ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
        workExperiences: const [WorkExperience.empty(), before],
      ),
      afterResume: ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
        workExperiences: const [WorkExperience.empty(), after],
      ),
    );

    expect(data.highlightedBulletsByExperience[0], {'Rewritten bullet'});
    expect(data.highlightedBulletsByExperience[1], isNull);
  });

  test('detects rewritten bullets at the same index', () {
    const before = WorkExperience(
      role: 'Engineer',
      company: 'Acme',
      startDate: '2020',
      endDate: '2022',
      description: '',
      bullets: ['Old bullet'],
    );
    const after = WorkExperience(
      role: 'Engineer',
      company: 'Acme',
      startDate: '2020',
      endDate: '2022',
      description: '',
      bullets: ['New bullet'],
    );

    expect(
      changedResumeExperienceBulletLines(before: before, after: after),
      {'New bullet'},
    );
  });
}
