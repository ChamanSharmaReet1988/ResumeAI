import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';

/// Regression tests for the built-in (offline) ATS rewrite: it must not make a
/// strong resume worse — no copied job-ad phrases, junk keywords, doubled
/// verbs, or boilerplate tails appended to bullets.
const _jobDescription =
    'We are hiring a Senior Product Manager for our payments platform. You will own the roadmap, work with engineering on API products, use SQL and experimentation to drive growth, and partner with compliance on KYC and fraud prevention.';

ResumeData _strongResume({String jobTitle = 'Senior Product Manager'}) =>
    ResumeData.empty(template: ResumeTemplate.atsStructured).copyWith(
      fullName: 'Priya Mehta',
      jobTitle: jobTitle,
      email: 'priya.mehta@gmail.com',
      summary:
          'Product manager with 8 years of experience leading B2C fintech and SaaS products. Shipped payments features used by 12M users and grew activation 34% through data-driven experimentation.',
      workExperiences: const [
        WorkExperience(
          role: 'Senior Product Manager',
          company: 'Razorpay',
          startDate: 'Mar 2021',
          endDate: 'Present',
          description: '',
          bullets: [
            'Led a 14-person squad to launch UPI AutoPay, reaching 2.1M mandates in the first 6 months.',
            'Cut checkout drop-off 18% by redesigning the payment flow using funnel analysis and A/B tests.',
            'Defined quarterly OKRs with engineering and design; delivered 92% of roadmap commitments.',
          ],
        ),
        WorkExperience(
          role: 'Product Manager',
          company: 'Freshworks',
          startDate: 'Jun 2018',
          endDate: 'Feb 2021',
          description: '',
          bullets: [
            'Owned the onboarding experience for Freshdesk, improving 30-day activation from 41% to 55%.',
            'Launched an in-app analytics dashboard adopted by 9,000 SMB customers.',
          ],
        ),
      ],
      education: const [
        EducationItem(
          institution: 'IIM Ahmedabad',
          degree: 'MBA',
          startDate: '2016',
          endDate: '2018',
          score: '',
        ),
      ],
      skills: const [
        'Product Strategy',
        'Roadmapping',
        'A/B Testing',
        'SQL',
        'Amplitude',
        'Jira',
        'Stakeholder Management',
        'User Research',
      ],
      includeProjectsInResume: true,
      projects: const [
        ProjectItem(
          title: 'Merchant Risk Scoring',
          bullets: ['Built a rules + ML risk score that reduced chargebacks 22%.'],
        ),
      ],
    );

const _boilerplateTails = [
  ', applying ',
  'to improve outcomes',
  'with demonstrated experience in',
  'in production delivery',
];

const _junkSkills = {
  'senior',
  'product',
  'products',
  'platform',
  'growth',
  'payments',
  'engineering',
  'roadmap',
  'our',
};

void _expectBulletsNotDamaged(ResumeData result) {
  final bullets = result.workExperiences.expand((w) => w.bullets).toList();
  for (final bullet in bullets) {
    for (final tail in _boilerplateTails) {
      expect(bullet, isNot(contains(tail)), reason: 'boilerplate in: $bullet');
    }
    expect(
      bullet,
      isNot(matches(RegExp(r'^(Led|Delivered) (cut|owned|defined|led|launched)\b'))),
      reason: 'doubled verb in: $bullet',
    );
  }
  final joined = bullets.join(' ');
  for (final metric in ['2.1M mandates', '18%', '92%', '41% to 55%', '9,000']) {
    expect(joined, contains(metric), reason: 'lost metric $metric');
  }
}

void _expectNoJunkSkills(ResumeData result) {
  for (final skill in result.skills) {
    expect(
      _junkSkills.contains(skill.trim().toLowerCase()),
      isFalse,
      reason: 'junk skill "$skill"',
    );
  }
  expect(result.skills, containsAll(['SQL', 'A/B Testing', 'Product Strategy']));
}

void _expectSummaryNotStuffed(String summary) {
  expect(summary, isNot(contains('for our payments platform')));
  expect(summary.toLowerCase(), isNot(contains('senior, product')));
  expect(summary, isNot(contains('keywords recruiters')));
  expect(summary, isNot(contains('applicant tracking systems scan')));
  expect(summary, isNot(contains('Well positioned for roles emphasizing')));
  expect(summary, isNot(contains('Well aligned to opportunities requiring')));
}

void main() {
  final service = LocalAiResumeService();

  group('createAtsResumeWithAi (what the AI Resume screen uses)', () {
    test('keeps the candidate title instead of the job-ad sentence', () async {
      final result = await service.createAtsResumeWithAi(
        sourceResume: _strongResume(),
        jobDescription: _jobDescription,
      );
      expect(result.resume.jobTitle, 'Senior Product Manager');
      _expectSummaryNotStuffed(result.resume.summary);
      expect(result.resume.summary, contains('Senior Product Manager'));
    });

    test('does not damage strong bullets', () async {
      for (final pass in [0, 1, 2]) {
        final result = await service.createAtsResumeWithAi(
          sourceResume: _strongResume(),
          jobDescription: _jobDescription,
          attemptIndex: pass,
        );
        _expectBulletsNotDamaged(result.resume);
        final changes = result.appliedChanges.join(' ');
        expect(changes, isNot(contains('denser keywords')), reason: 'pass $pass');
        expect(changes, isNot(contains('strengthened experience bullets')), reason: 'pass $pass');
        for (final bullet in result.resume.workExperiences.expand((w) => w.bullets)) {
          expect(bullet, isNot(matches(RegExp(r' using (platform|growth|Senior|Product|payments)\.$'))));
        }
      }
    });

    test('adds no junk skills and keeps real ones', () async {
      final withJd = await service.createAtsResumeWithAi(
        sourceResume: _strongResume(),
        jobDescription: _jobDescription,
      );
      _expectNoJunkSkills(withJd.resume);

      final withoutJd = await service.createAtsResumeWithAi(
        sourceResume: _strongResume(),
      );
      _expectNoJunkSkills(withoutJd.resume);
      _expectBulletsNotDamaged(withoutJd.resume);
    });

    test('suggests missing job-ad skills without inventing them', () async {
      final result = await service.createAtsResumeWithAi(
        sourceResume: _strongResume(),
        jobDescription: _jobDescription,
      );
      expect(result.resume.skills, isNot(contains('KYC')));
      expect(
        result.appliedChanges.join(' '),
        contains('KYC'),
        reason: 'job-ad skills the resume lacks should be suggested, not added',
      );
    });

    test('uses the posting title only when the resume has none', () async {
      final result = await service.createAtsResumeWithAi(
        sourceResume: _strongResume(jobTitle: ''),
        jobDescription: _jobDescription,
      );
      expect(result.resume.jobTitle, 'Senior Product Manager');
    });
  });

  test('createAtsResumeWithAi never invents project bullets', () async {
    final result = await service.createAtsResumeWithAi(
      sourceResume: _strongResume(),
      jobDescription: _jobDescription,
    );
    final bullets = result.resume.projects.single.bullets;
    expect(bullets, ['Built a rules + ML risk score that reduced chargebacks 22%.']);
  });

  group('improveResumeForAts', () {
    test('does not damage a strong resume', () async {
      final result = await service.improveResumeForAts(
        resume: _strongResume(),
        jobDescription: _jobDescription,
      );
      expect(result.resume.jobTitle, 'Senior Product Manager');
      _expectSummaryNotStuffed(result.resume.summary);
      _expectBulletsNotDamaged(result.resume);
      _expectNoJunkSkills(result.resume);
    });
  });

  group('generateSummary', () {
    test('uses the right article before the title', () async {
      for (final attempt in [0, 1, 2, 3]) {
        final summary = await service.generateSummary(
          _strongResume(),
          regenerate: attempt > 0,
          attemptIndex: attempt,
        );
        expect(summary, isNot(contains('an Senior')));
        expect(summary, isNot(contains(RegExp(r'\ban [B-DF-GJ-NP-TV-Zb-df-gj-np-tv-z][a-z]'))));
      }
      final engineer = await service.generateSummary(
        _strongResume(jobTitle: 'Engineering Manager'),
      );
      expect(engineer, isNot(contains('a Engineering')));
    });
  });

  group('weak resume', () {
    ResumeData weakResume() =>
        ResumeData.empty(template: ResumeTemplate.atsStructured).copyWith(
          fullName: 'Rahul Verma',
          jobTitle: 'Flutter Developer',
          skills: const ['Flutter', 'Dart'],
          workExperiences: const [
            WorkExperience(
              role: 'Flutter Developer',
              company: 'Acme',
              startDate: '2023',
              endDate: 'Present',
              description:
                  'Worked on the company mobile app. Builds new screens for the checkout flow.',
              bullets: [
                'Maintained mobile app features.',
                'Responsible for code reviews.',
              ],
            ),
          ],
        );
    const flutterJobAd =
        'Hiring a Flutter developer with Firebase, REST APIs and unit testing experience.';

    test('rewrites weak openers without overclaiming or broken grammar', () async {
      final result = await service.createAtsResumeWithAi(
        sourceResume: weakResume(),
      );
      final bullets = result.resume.workExperiences.single.bullets;
      for (final bullet in bullets) {
        expect(bullet, isNot(startsWith('Delivered the')), reason: bullet);
        expect(bullet, isNot(matches(RegExp(r'^Delivered [a-z]+s\b'))), reason: bullet);
      }
      expect(bullets, contains('Contributed to the company mobile app.'));
      expect(bullets, contains('Built new screens for the checkout flow.'));
      expect(bullets, contains('Managed code reviews.'));
    });

    test('lists only skills the resume shows and suggests the rest', () async {
      for (final jobAd in ['', flutterJobAd]) {
        final result = await service.createAtsResumeWithAi(
          sourceResume: weakResume(),
          jobDescription: jobAd,
        );
        expect(result.resume.skills, containsAll(['Flutter', 'Dart']));
        for (final invented in ['Firebase', 'REST APIs', 'Unit Testing', 'CI/CD', 'State Management']) {
          expect(result.resume.skills, isNot(contains(invented)), reason: 'jobAd="$jobAd"');
        }
      }
      final withAd = await service.createAtsResumeWithAi(
        sourceResume: weakResume(),
        jobDescription: flutterJobAd,
      );
      expect(withAd.appliedChanges.join(' '), contains('Firebase'));
    });
  });
}
