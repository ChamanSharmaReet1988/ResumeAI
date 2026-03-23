import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';

void main() {
  test('suggestSkills uses work experience context before job title', () async {
    final service = LocalAiResumeService();

    final mobileResume = ResumeData.empty(template: ResumeTemplate.modern).copyWith(
      jobTitle: 'Engineer',
      workExperiences: const [
        WorkExperience(
          role: 'Mobile Engineer',
          company: 'Acme',
          startDate: 'Jan 2024',
          endDate: 'Present',
          description:
              'Built Flutter mobile apps, integrated REST APIs, managed state with Provider, and shipped releases to iOS and Android.',
          bullets: [
            'Added Firebase analytics and widget testing coverage for core app flows.',
          ],
        ),
      ],
    );

    final analyticsResume = ResumeData.empty(template: ResumeTemplate.modern).copyWith(
      jobTitle: 'Engineer',
      workExperiences: const [
        WorkExperience(
          role: 'Growth Analyst',
          company: 'Beta',
          startDate: 'Jan 2024',
          endDate: 'Present',
          description:
              'Built SQL dashboards, tracked KPIs, and ran A/B tests with product stakeholders to improve conversions.',
          bullets: [
            'Created analytics reports and experiment readouts for leadership.',
          ],
        ),
      ],
    );

    final mobileSkills = await service.suggestSkills(resume: mobileResume);
    final analyticsSkills = await service.suggestSkills(
      resume: analyticsResume,
    );

    expect(mobileSkills, containsAll(['Flutter', 'Dart', 'REST APIs']));
    expect(
      mobileSkills,
      isNot(containsAll(['SQL', 'Analytics', 'A/B Testing'])),
    );

    expect(analyticsSkills, containsAll(['SQL', 'Analytics', 'A/B Testing']));
    expect(analyticsSkills, isNot(contains('Flutter')));

    expect(mobileSkills, isNot(equals(analyticsSkills)));
  });

  test('suggestSkills uses the resume title as part of the context', () async {
    final service = LocalAiResumeService();
    final resume = ResumeData.empty(
      template: ResumeTemplate.modern,
    ).copyWith(title: 'Product Designer Resume');

    final suggestions = await service.suggestSkills(resume: resume);

    expect(suggestions, containsAll(['Figma', 'Design Systems']));
  });

  test(
    'suggestSkills falls back to target job title when work history is empty',
    () async {
      final service = LocalAiResumeService();
      final resume = ResumeData.empty(template: ResumeTemplate.modern);

      final suggestions = await service.suggestSkills(
        resume: resume,
        targetJobTitle: 'Flutter Developer',
      );

      expect(suggestions, containsAll(['Flutter', 'Dart', 'REST APIs']));
    },
  );
}
