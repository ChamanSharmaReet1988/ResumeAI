import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_builder_section_order.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/features/shared/resume_preview_card.dart';

void main() {
  testWidgets(
    'blue corner preview indents skills past the left vertical line',
    (tester) async {
      final resume = ResumeData.empty(template: ResumeTemplate.blueCorner).copyWith(
        fullName: 'Priya Raman',
        jobTitle: 'Marketing Manager',
        skills: const ['Management Skills', 'Creativity'],
        workExperiences: const [
          WorkExperience(
            role: 'Manager',
            company: 'Corp',
            startDate: '2020',
            endDate: 'Present',
            description: '',
            bullets: ['Did great work'],
          ),
        ],
        education: const [
          EducationItem(
            institution: 'Univ',
            degree: 'Degree',
            startDate: '2015',
            endDate: '2019',
            score: '',
          ),
        ],
        builderSectionOrder: const [
          ResumeBuilderSectionIds.education,
          ResumeBuilderSectionIds.work,
          ResumeBuilderSectionIds.skills,
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 595.28,
                height: 841.89,
                child: ResumePreviewCard(
                  resume: resume,
                  followBuilderSectionOrder: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Blue Corner, the vertical timeline line is at _mainLeft + _dot / 2 = 258 + 4 = 262.
      // The skills must be indented past this line (x = 258 + 20 = 278).
      final skillFinder = find.text('• Management Skills');
      expect(skillFinder, findsOneWidget);

      final cardOrigin = tester.getTopLeft(find.byType(ResumePreviewCard));
      final skillOrigin = tester.getTopLeft(skillFinder);
      final relativeSkillX = skillOrigin.dx - cardOrigin.dx;

      expect(relativeSkillX, greaterThan(270));
      expect(relativeSkillX, closeTo(278, 2.0));
    },
  );

  testWidgets(
    'blue corner experience company name stays clear of the title and dates',
    (tester) async {
      await tester.runAsync(() async {
        final loader = FontLoader('Garamond')
          ..addFont(rootBundle.load('assets/fonts/garamond/Garamond-Regular.ttf'))
          ..addFont(
            rootBundle.load('assets/fonts/garamond/Garamond-SemiBold.ttf'),
          )
          ..addFont(rootBundle.load('assets/fonts/garamond/Garamond-Italic.ttf'));
        await loader.load();
      });

      final resume = ResumeData.empty(template: ResumeTemplate.blueCorner).copyWith(
        fullName: 'Priya Raman',
        jobTitle: 'Marketing Manager',
        summary: 'Marketing manager with nine years leading brand programmes.',
        workExperiences: const [
          WorkExperience(
            role: 'Product Design Manager',
            company: 'Arowwai Industries International',
            startDate: '2020',
            endDate: 'Present',
            description: '',
            bullets: ['Ran the launch calendar for three product lines.'],
          ),
        ],
        builderSectionOrder: const [ResumeBuilderSectionIds.work],
      );

      await tester.binding.setSurfaceSize(const Size(700, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 635,
                child: ResumePreviewCard(resume: resume),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final role = tester.getRect(find.text('Product Design Manager'));
      final company = tester.getRect(
        find.text('Arowwai Industries International'),
      );
      final dates = tester.getRect(find.text('2020 - Present'));

      expect(company.top, greaterThanOrEqualTo(role.bottom + 2));
      expect(company.overlaps(role), isFalse);
      expect(company.overlaps(dates), isFalse);
      expect(role.overlaps(dates), isFalse);
    },
  );
}
