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

  test(
    'improveResumeForAts rewrites existing summary and work bullets from the pasted job description',
    () async {
      final service = LocalAiResumeService();
      final resume = ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
        fullName: 'Alex Johnson',
        title: 'Mobile Resume',
        jobTitle: 'Flutter Developer',
        summary:
            'Builds mobile features for consumer apps and helps support releases.',
        skills: const ['Flutter', 'Dart'],
        workExperiences: const [
          WorkExperience(
            role: 'Flutter Developer',
            company: 'Acme',
            startDate: 'Jan 2024',
            endDate: 'Present',
            description:
                'Built onboarding flows for a consumer app. Improved analytics instrumentation and partnered with product stakeholders to streamline releases.',
            bullets: ['Maintained mobile app features and bug fixes.'],
          ),
        ],
      );

      final result = await service.improveResumeForAts(
        resume: resume,
        jobDescription:
            'Hiring a Flutter developer with Firebase, analytics, REST APIs, and stakeholder communication experience.',
      );

      expect(result.resume.summary, isNot(equals(resume.summary)));
      expect(
        result.resume.summary,
        contains('Well aligned to opportunities requiring'),
      );
      expect(
        result.resume.summary,
        anyOf(
          contains('Firebase'),
          contains('analytics'),
          contains('REST'),
          contains('stakeholder'),
        ),
      );
      expect(
        result.resume.workExperiences.first.bullets.join(' '),
        anyOf(
          contains('Firebase'),
          contains('analytics'),
          contains('REST'),
          contains('stakeholder'),
        ),
      );
      expect(
        result.appliedChanges,
        contains(
          'Tailored the summary to match the pasted job description more directly.',
        ),
      );
      expect(
        result.appliedChanges,
        contains(
          'Rewrote work experience bullets to reflect the target job description more directly.',
        ),
      );
    },
  );

  test(
    'improveResumeForAts avoids repeating the same keyword boilerplate on every role',
    () async {
      final service = LocalAiResumeService();
      const jobDescription =
          'Hiring a Flutter developer with Firebase, analytics, REST APIs, and stakeholder communication experience.';
      final resume = ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
        jobTitle: 'Flutter Developer',
        workExperiences: const [
          WorkExperience(
            role: 'Flutter Developer',
            company: 'Acme',
            startDate: '2022',
            endDate: '2024',
            description:
                'Built onboarding flows and analytics dashboards for a consumer app.',
            bullets: ['Shipped Flutter features for iOS and Android releases.'],
          ),
          WorkExperience(
            role: 'Junior Developer',
            company: 'Beta Labs',
            startDate: '2020',
            endDate: '2022',
            description:
                'Supported API integrations and internal tooling for operations teams.',
            bullets: ['Maintained REST endpoints and unit tests for backend services.'],
          ),
        ],
      );

      final result = await service.improveResumeForAts(
        resume: resume,
        jobDescription: jobDescription,
      );

      final firstBullets = result.resume.workExperiences[0].bullets.join(' ');
      final secondBullets = result.resume.workExperiences[1].bullets.join(' ');

      expect(firstBullets, isNot(equals(secondBullets)));
      expect(
        firstBullets.toLowerCase(),
        isNot(contains('applied firebase and analytics in')),
      );
      expect(
        secondBullets.toLowerCase(),
        isNot(contains('applied firebase and analytics in')),
      );
      expect(
        secondBullets.toLowerCase(),
        isNot(contains('improved alignment with firebase')),
      );
    },
  );

  test('generateSummary uses resume identity and role context', () async {
    final service = LocalAiResumeService();
    final resume = ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
      fullName: 'Jane Doe',
      jobTitle: 'Product Manager',
      skills: const ['Roadmapping', 'Analytics'],
      workExperiences: const [
        WorkExperience(
          role: 'Product Manager',
          company: 'Acme',
          startDate: 'Jan 2020',
          endDate: 'Present',
          description: 'Led product launches.',
          bullets: ['Shipped roadmap items on schedule.'],
        ),
      ],
    );

    final summary = await service.generateSummary(resume);

    expect(summary.trim(), isNotEmpty);
    expect(summary, contains('Jane Doe'));
    expect(summary, contains('Product Manager'));
    final lineCount = summary
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .length;
    expect(lineCount, greaterThanOrEqualTo(4));
    expect(lineCount, lessThanOrEqualTo(5));
  });

  test(
    'generateSummary regenerate uses alternate phrasing',
    () async {
      final service = LocalAiResumeService();
      final resume = ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
        fullName: 'Jane Doe',
        jobTitle: 'Product Manager',
        skills: const ['Roadmapping', 'Analytics'],
        workExperiences: const [
          WorkExperience(
            role: 'Product Manager',
            company: 'Acme',
            startDate: 'Jan 2020',
            endDate: 'Present',
            description: 'Led product launches.',
            bullets: ['Shipped roadmap items on schedule.'],
          ),
        ],
      );

      final first = await service.generateSummary(resume);
      final second = await service.generateSummary(
        resume,
        regenerate: true,
        attemptIndex: 1,
      );

      expect(second.trim(), isNotEmpty);
      expect(second, isNot(equals(first)));
      expect(second, contains('Jane Doe'));
      expect(second, contains('Product Manager'));
    },
  );

  test('generateCoverLetter uses resume contact details and job context', () async {
    final service = LocalAiResumeService();
    final resume = ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
      fullName: 'Avery Lee',
      jobTitle: 'Product Designer',
      email: 'avery@example.com',
      phone: '+1 555 0100',
      location: 'San Francisco, CA',
      skills: const ['UX research', 'Prototyping'],
      workExperiences: const [
        WorkExperience(
          role: 'Product Designer',
          company: 'North Studio',
          startDate: '2023',
          endDate: 'Present',
          description:
              'Led cross-functional design work for web and mobile products.',
          bullets: const [
            'Partnered with engineers to improve onboarding flows.',
          ],
        ),
      ],
    );

    final letter = await service.generateCoverLetter(
      resume: resume,
      company: 'Acme Labs',
      role: 'Senior Product Designer',
      skillToHighlight: 'UX research, Prototyping',
    );

    expect(letter, contains('Avery Lee'));
    expect(letter, contains('avery@example.com'));
    expect(letter, contains('Acme Labs'));
    expect(letter, contains('Senior Product Designer'));
    expect(letter, contains('UX research'));
    expect(letter, contains('North Studio'));
    expect(letter, isNot(contains('[Your Name]')));
    expect(letter, isNot(contains('Dekh Company')));
  });

  test('generateCoverLetter regenerate rotates opening and closing', () async {
    final service = LocalAiResumeService();
    final resume = ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
      fullName: 'Jordan Kim',
      jobTitle: 'Software Engineer',
      skills: const ['Flutter', 'Dart'],
    );

    final first = await service.generateCoverLetter(
      resume: resume,
      company: 'River Tech',
      role: 'Mobile Engineer',
    );
    final second = await service.generateCoverLetter(
      resume: resume,
      company: 'River Tech',
      role: 'Mobile Engineer',
      regenerate: true,
      attemptIndex: 1,
    );

    expect(second, isNot(equals(first)));
    expect(second, contains('Jordan Kim'));
    expect(second, contains('River Tech'));
    expect(second, contains('Mobile Engineer'));
  });
}
