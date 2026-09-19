import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';

/// Round-trips the sample through every template and scores how many fields
/// survive, so parser work can be measured instead of guessed.
ResumeData _sample(ResumeTemplate template) =>
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final report = StringBuffer();
  var totalChecks = 0;
  var totalPassed = 0;

  tearDownAll(() {
    // ignore: avoid_print
    print(
      '$report\nTOTAL ${(totalPassed / totalChecks * 100).toStringAsFixed(1)}% '
      '($totalPassed/$totalChecks)',
    );
  });

  for (final template in ResumeTemplate.values) {
    test('accuracy ${template.name}', () async {
      final original = _sample(template);
      final bytes = await ResumePdfService().buildPdf(original);
      final imported = await const ResumeImportService().importPlatformFile(
        PlatformFile(name: 'r.pdf', size: bytes.length, bytes: bytes),
      );
      final parsed = LocalAiResumeService().parseImportedResumeText(
        resumeText: imported.resumeText,
        candidateResumeTexts: imported.candidateResumeTexts,
        template: ResumeTemplate.corporate,
        sourceTitle: imported.suggestedTitle,
      );

      final jobs = parsed.visibleWorkExperiences;
      final checks = <String, bool>{
        'name': parsed.fullName == original.fullName,
        'email': parsed.email == original.email,
        'phone': parsed.phone.replaceAll(RegExp(r'\s'), '').contains(
          '9820011223',
        ),
        'linkedin': parsed.linkedinLink.contains('rohankapoor'),
        'summary': parsed.summary.contains('7 years of experience'),
        'jobCount': jobs.length == 2,
        'job1Role': jobs.isNotEmpty && jobs.first.role == 'Senior Android Developer',
        'job1Company': jobs.isNotEmpty && jobs.first.company == 'PhonePe',
        'job1Bullets': jobs.isNotEmpty && jobs.first.bullets.length == 2,
        'job2Role': jobs.length > 1 && jobs[1].role == 'Android Developer',
        'job2Company': jobs.length > 1 && jobs[1].company == 'Flipkart',
        'education': parsed.visibleEducation.isNotEmpty &&
            parsed.visibleEducation.first.institution.contains(
              'College of Engineering',
            ),
        'skills': ['Kotlin', 'Java', 'Jetpack Compose', 'Coroutines']
            .every((skill) => parsed.skills.contains(skill)),
      };
      final failed = checks.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();
      totalChecks += checks.length;
      totalPassed += checks.length - failed.length;
      report.writeln(
        '${template.name.padRight(22)} '
        '${checks.length - failed.length}/${checks.length}'
        '${failed.isEmpty ? '' : '  failed: ${failed.join(', ')}'}',
      );
    });
  }
}
