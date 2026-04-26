import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';

void main() {
  test('suggestSkills uses work experience context before job title', () async {
    final service = LocalAiResumeService();

    final mobileResume = ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
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

    final analyticsResume = ResumeData.empty(template: ResumeTemplate.corporate)
        .copyWith(
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
      template: ResumeTemplate.corporate,
    ).copyWith(title: 'Product Designer Resume');

    final suggestions = await service.suggestSkills(resume: resume);

    expect(suggestions, containsAll(['Figma', 'Design Systems']));
  });

  test(
    'suggestSkills falls back to target job title when work history is empty',
    () async {
      final service = LocalAiResumeService();
      final resume = ResumeData.empty(template: ResumeTemplate.corporate);

      final suggestions = await service.suggestSkills(
        resume: resume,
        targetJobTitle: 'Flutter Developer',
      );

      expect(suggestions, containsAll(['Flutter', 'Dart', 'REST APIs']));
    },
  );

  test(
    'parseImportedResumeText maps uploaded resume into builder sections',
    () {
      final service = LocalAiResumeService();

      final resume = service.parseImportedResumeText(
        resumeText: '''
DIYA AGARWAL
Retail Sales Associate
d.agarwal@example.com | +91 9876543210 | New Delhi, India
github.com/diyaagarwal | linkedin.com/in/diyaagarwal

SUMMARY
Customer-focused retail sales professional with solid understanding of retail dynamics, marketing, and customer service.

SKILLS
Cash register operation, Inventory management, POS system operation, Retail merchandising expertise

EXPERIENCE
Retail Sales Associate | ZARA
02/2017 - Present
- Increased monthly sales 10% by effectively upselling and cross-selling products.
- Prevented store losses by identifying and investigating concerns.
Barista | Dunkin Donuts
03/2015 - 01/2017
- Upsold seasonal drinks and pastries, boosting average store sales.
- Managed morning rush of over 300 customers daily.

EDUCATION
Diploma in Financial Accounting
Oxford Software Institute
2016

PROJECTS
Customer Loyalty App
- Designed a retail loyalty concept to improve repeat purchases.

LANGUAGES
- Hindi: Native speaker
- English: Professional working proficiency

CERTIFICATIONS
- Retail Sales Fundamentals
''',
        template: ResumeTemplate.creative,
        sourceTitle: 'diya-retail-resume.pdf',
      );

      expect(resume.title, 'diya retail resume');
      expect(resume.fullName, 'Diya Agarwal');
      expect(resume.jobTitle, 'Retail Sales Associate');
      expect(resume.email, 'd.agarwal@example.com');
      expect(resume.phone, isNotEmpty);
      expect(resume.location, 'New Delhi, India');
      expect(resume.githubLink, contains('github.com/diyaagarwal'));
      expect(resume.linkedinLink, contains('linkedin.com/in/diyaagarwal'));
      expect(
        resume.summary,
        contains('Customer-focused retail sales professional'),
      );
      expect(
        resume.skills,
        containsAll(['Cash register operation', 'Inventory management']),
      );
      expect(resume.workExperiences.length, 2);
      expect(resume.workExperiences.first.role, 'Retail Sales Associate');
      expect(resume.workExperiences.first.company, 'ZARA');
      expect(resume.workExperiences.first.startDate, '02/2017');
      expect(resume.workExperiences.first.endDate, 'Present');
      expect(resume.workExperiences[1].role, 'Barista');
      expect(resume.education.length, 1);
      expect(resume.education.first.degree, 'Diploma in Financial Accounting');
      expect(resume.projects.length, 1);
      expect(resume.projects.first.title, 'Customer Loyalty App');
      expect(
        resume.customSections.map((item) => item.title),
        containsAll(['Languages', 'Certifications']),
      );
    },
  );

  test(
    'parseImportedResumeText handles inline section headings from uploaded files',
    () {
      final service = LocalAiResumeService();

      final resume = service.parseImportedResumeText(
        resumeText: '''
DIYA AGARWAL
Retail Sales Associate
d.agarwal@example.com | +91 9876543210 | New Delhi, India

SUMMARY: Customer-focused retail sales professional with strong customer service and merchandising experience.
SKILLS: Cash register operation, Inventory management, POS system operation, Retail merchandising expertise
EXPERIENCE: Retail Sales Associate | ZARA
02/2017 - Present
- Increased monthly sales 10% by effectively upselling and cross-selling products.
EDUCATION: Diploma in Financial Accounting
Oxford Software Institute
2016
PROJECTS: Customer Loyalty App
- Designed a retail loyalty concept to improve repeat purchases.
''',
        template: ResumeTemplate.creative,
        sourceTitle: 'uploaded-resume.pdf',
      );

      expect(
        resume.summary,
        contains('Customer-focused retail sales professional'),
      );
      expect(
        resume.skills,
        containsAll(['Cash register operation', 'Inventory management']),
      );
      expect(resume.workExperiences.first.role, 'Retail Sales Associate');
      expect(resume.workExperiences.first.company, 'ZARA');
      expect(resume.education.first.degree, 'Diploma in Financial Accounting');
      expect(resume.projects.first.title, 'Customer Loyalty App');
    },
  );

  test(
    'parseImportedResumeText chooses the best local extraction candidate',
    () {
      final service = LocalAiResumeService();

      final resume = service.parseImportedResumeText(
        resumeText: '''
DIYA AGARWAL
Retail Sales Associate
d.agarwal@example.com | +91 9876543210 | New Delhi, India
''',
        candidateResumeTexts: const [
          '''
DIYA AGARWAL
Retail Sales Associate
d.agarwal@example.com | +91 9876543210 | New Delhi, India

SUMMARY
Customer-focused retail sales professional with strong customer service and merchandising experience.

SKILLS
Cash register operation, Inventory management, POS system operation

EXPERIENCE
Retail Sales Associate | ZARA
02/2017 - Present
- Increased monthly sales 10% by effectively upselling and cross-selling products.

EDUCATION
Diploma in Financial Accounting
Oxford Software Institute
2016
''',
        ],
        template: ResumeTemplate.creative,
        sourceTitle: 'uploaded-resume.pdf',
      );

      expect(
        resume.summary,
        contains('Customer-focused retail sales professional'),
      );
      expect(resume.skills, contains('Inventory management'));
      expect(resume.workExperiences.first.company, 'ZARA');
      expect(resume.education.first.degree, 'Diploma in Financial Accounting');
    },
  );
}
