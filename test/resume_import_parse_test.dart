import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/resume_text_font.dart';
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';

/// Round-trips resumes through the app's own PDF export and the Upload resume
/// import, so auto-fill is checked against real extracted PDF text.
ResumeData _sampleResume(ResumeTemplate template) =>
    ResumeData.empty(template: template).copyWith(
      fullName: 'Rohan Kapoor',
      jobTitle: 'Senior Android Developer',
      email: 'rohan.kapoor@gmail.com',
      phone: '+91 98200 11223',
      location: 'Pune, India',
      linkedinLink: 'linkedin.com/in/rohankapoor',
      summary:
          'Android developer with 7 years of experience building fintech and e-commerce apps used by millions of customers.',
      workExperiences: const [
        WorkExperience(
          role: 'Senior Android Developer',
          company: 'PhonePe',
          startDate: 'Jan 2021',
          endDate: 'Present',
          description: '',
          bullets: [
            'Led the Kotlin migration of the payments module, cutting crash rate by 38%.',
            'Built offline-first transaction history used by 20M monthly users.',
          ],
        ),
        WorkExperience(
          role: 'Android Developer',
          company: 'Flipkart',
          startDate: 'Jul 2017',
          endDate: 'Dec 2020',
          description: '',
          bullets: [
            'Shipped the checkout redesign that improved conversion by 12%.',
          ],
        ),
      ],
      education: const [
        EducationItem(
          institution: 'College of Engineering Pune',
          degree: 'B.Tech, Computer Engineering',
          startDate: '2013',
          endDate: '2017',
          score: '',
        ),
      ],
      skills: const ['Kotlin', 'Java', 'Jetpack Compose', 'Coroutines'],
    );

Future<ResumeData> _uploadExportedPdf(ResumeTemplate template, {
  ResumeTextFont font = ResumeTextFont.inter,
}) async {
  final bytes = await ResumePdfService().buildPdf(
    _sampleResume(template).copyWith(resumeTextFont: font),
  );
  final imported = await const ResumeImportService().importPlatformFile(
    PlatformFile(name: 'Rohan_Kapoor_Resume.pdf', size: bytes.length, bytes: bytes),
  );
  return LocalAiResumeService().parseImportedResumeText(
    resumeText: imported.resumeText,
    candidateResumeTexts: imported.candidateResumeTexts,
    template: ResumeTemplate.corporate,
    sourceTitle: imported.suggestedTitle,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final template in [
    ResumeTemplate.atsStructured,
    ResumeTemplate.corporate,
    ResumeTemplate.classicSidebar,
    ResumeTemplate.headerSidebar,
  ]) {
    group('Upload resume auto-fill from ${template.name} PDF', () {
      late ResumeData parsed;
      setUpAll(() async => parsed = await _uploadExportedPdf(template));

      test('fills in identity and contact details', () {
        expect(parsed.fullName, 'Rohan Kapoor');
        expect(parsed.email, 'rohan.kapoor@gmail.com');
        expect(parsed.phone.replaceAll(RegExp(r'\s'), ''), contains('9820011223'));
        expect(parsed.linkedinLink, contains('linkedin.com/in/rohankapoor'));
      });

      test('never turns the text into one-word fake jobs', () {
        final roles = parsed.visibleWorkExperiences.map((w) => w.role).toList();
        expect(roles.length, lessThanOrEqualTo(4), reason: 'roles: $roles');
        for (final role in roles) {
          expect(role.trim().split(RegExp(r'\s+')).length, greaterThan(1),
              reason: 'fragment role "$role" in $roles');
        }
      });

      test('keeps the full summary', () {
        expect(parsed.summary, contains('7 years of experience'));
      });
    });
  }

  test('Inter font choice exports readable text', () async {
    final parsed = await _uploadExportedPdf(
      ResumeTemplate.atsStructured,
      font: ResumeTextFont.sharpInter,
    );
    expect(parsed.fullName, 'Rohan Kapoor');
    expect(parsed.email, 'rohan.kapoor@gmail.com');
    expect(parsed.visibleWorkExperiences.length, 2);
  });

  group('Upload resume auto-fill from structured ATS PDF', () {
    late ResumeData parsed;
    setUpAll(() async => parsed = await _uploadExportedPdf(ResumeTemplate.atsStructured));

    test('reads the job title and location from the header', () {
      expect(parsed.jobTitle, 'Senior Android Developer');
      expect(parsed.location, 'Pune, India');
    });

    test('splits both jobs into role, company, and dates', () {
      final jobs = parsed.visibleWorkExperiences;
      expect(jobs.length, 2, reason: jobs.map((j) => '${j.role} @ ${j.company}').toString());
      expect(jobs[0].role, 'Senior Android Developer');
      expect(jobs[0].company, 'PhonePe');
      expect(jobs[0].startDate, 'Jan 2021');
      expect(jobs[0].endDate, 'Present');
      expect(jobs[0].bullets.length, 2);
      expect(jobs[1].role, 'Android Developer');
      expect(jobs[1].company, 'Flipkart');
    });

    test('cleans list markers and dates out of education', () {
      final school = parsed.visibleEducation.single;
      expect(school.institution, 'College of Engineering Pune');
      expect(school.degree, 'B.Tech, Computer Engineering');
      expect(school.startDate, '2013');
      expect(school.endDate, '2017');
    });

    test('reads a two-column skills grid as separate skills', () {
      expect(
        parsed.skills,
        containsAll(['Kotlin', 'Java', 'Jetpack Compose', 'Coroutines']),
      );
      for (final skill in parsed.skills) {
        expect(skill, isNot(contains('Kotlin Jetpack')), reason: skill);
        expect(skill, isNot(contains('Java Coroutines')), reason: skill);
      }
    });
  });
}
