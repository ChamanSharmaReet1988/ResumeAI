import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/resume_text_font.dart';
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

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
    ResumeTemplate.atsCleanSans,
    ResumeTemplate.meridian,
    ResumeTemplate.ledger,
    ResumeTemplate.keystone,
    ResumeTemplate.cadence,
    ResumeTemplate.terrazzo,
    ResumeTemplate.dotfield,
    ResumeTemplate.orbit,
    ResumeTemplate.prism,
    ResumeTemplate.summit,
    ResumeTemplate.folio,
    ResumeTemplate.beacon,
    ResumeTemplate.vertex,
    ResumeTemplate.atsBoldRule,
    ResumeTemplate.atsCompact,
    ResumeTemplate.atsFocus,
    ResumeTemplate.atsDoubleRule,
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

  // A resume long enough to wrap bullets and the summary, with two degrees.
  // Some of these PDFs also make the PDF library's line reader crash.
  ResumeData longResume(ResumeTemplate template) =>
      ResumeData.empty(template: template).copyWith(
        fullName: 'Rohan Kapoor',
        jobTitle: 'Senior Android Developer',
        email: 'rohan.kapoor@gmail.com',
        phone: '+91 98200 11223',
        location: 'Pune, India',
        summary:
            'Android developer with 7 years of experience building fintech and e-commerce apps used by millions of customers across India. Led mobile teams of up to eight engineers and shipped releases on a two week cadence with strong crash free rates. Comfortable working with product, design and backend teams to move difficult projects from idea to launch while keeping quality and performance high for every customer on every device.',
        workExperiences: const [
          WorkExperience(
            role: 'Senior Android Developer',
            company: 'PhonePe',
            startDate: 'Mar 2021',
            endDate: 'Present',
            description: '',
            bullets: [
              'Led the Kotlin migration of the payments module across twelve teams and four release trains, cutting the crash rate by 38% within two quarters of the rollout.',
              'Built offline-first transaction history used by 20M monthly users on low end devices with poor connectivity across rural regions of the country',
            ],
          ),
          WorkExperience(
            role: 'Android Developer',
            company: 'Flipkart',
            startDate: 'Jul 2017',
            endDate: 'Dec 2020',
            description: '',
            bullets: ['Shipped the checkout redesign that improved conversion by 12%.'],
          ),
        ],
        education: const [
          EducationItem(
            institution: 'Indian Institute of Technology Bombay',
            degree: 'M.Tech, Computer Science',
            startDate: '2015',
            endDate: '2017',
            score: '',
          ),
          EducationItem(
            institution: 'College of Engineering Pune',
            degree: 'B.Tech, Computer Engineering',
            startDate: '2011',
            endDate: '2015',
            score: '',
          ),
        ],
        skills: const ['Kotlin', 'Java', 'Jetpack Compose', 'Coroutines'],
      );

  // Upload under a name that says nothing, so the resume's own text is tested.
  Future<ImportedResumeFile> upload(Uint8List bytes) =>
      const ResumeImportService().importPlatformFile(
        PlatformFile(name: 'upload.pdf', size: bytes.length, bytes: bytes),
      );

  String printedText(Uint8List bytes) {
    final document = sfpdf.PdfDocument(inputBytes: bytes);
    final text = sfpdf.PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  String squashed(String text) => text.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
    '',
  );
  String sameCase(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  // The source resume as far as the PDF prints it: a field a template leaves
  // out cannot come back, and must stay empty rather than be guessed.
  void expectSameResume(ResumeData parsed, ResumeData source, Uint8List bytes) {
    final printed = squashed(printedText(bytes));
    String want(String value) =>
        printed.contains(squashed(value)) ? sameCase(value) : '';
    String dates(String start, String end) =>
        printed.contains(squashed('$start$end')) ||
            printed.contains(squashed('$start - $end'))
        ? sameCase('$start-$end')
        : '-';

    expect(sameCase(parsed.fullName), want(source.fullName));
    expect(sameCase(parsed.jobTitle), want(source.jobTitle));
    expect(parsed.email, source.email);
    expect(sameCase(parsed.location), want(source.location));
    expect(sameCase(parsed.summary), want(source.summary));
    expect(
      parsed.visibleWorkExperiences.map(
        (w) => [
          sameCase(w.role),
          sameCase(w.company),
          sameCase('${w.startDate}-${w.endDate}'),
          w.description,
          w.bullets.map(sameCase),
        ].toString(),
      ),
      source.visibleWorkExperiences.map(
        (w) => [
          want(w.role),
          want(w.company),
          dates(w.startDate, w.endDate),
          w.description,
          w.bullets.map(sameCase),
        ].toString(),
      ),
    );
    expect(
      parsed.visibleEducation.map(
        (e) => [
          sameCase(e.degree),
          sameCase(e.institution),
          sameCase('${e.startDate}-${e.endDate}'),
        ].toString(),
      ),
      source.visibleEducation.map(
        (e) => [
          want(e.degree),
          want(e.institution),
          dates(e.startDate, e.endDate),
        ].toString(),
      ),
    );
    expect(parsed.skills.toSet(), source.skills.toSet());
  }

  for (final (name, resume) in [
    ('short', _sampleResume),
    ('long', longResume),
  ]) {
    group('Re-uploading a $name resume PDF', () {
      for (final template in ResumeTemplate.values) {
        test('${template.name} reads back from its pages alone', () async {
          final source = resume(template);
          final bytes = await ResumePdfService().buildPdf(source);
          final imported = await upload(bytes);
          final parsed = LocalAiResumeService().parseImportedResumeText(
            resumeText: imported.resumeText,
            candidateResumeTexts: imported.candidateResumeTexts,
            template: ResumeTemplate.corporate,
            sourceTitle: imported.suggestedTitle,
          );
          expectSameResume(parsed, source, bytes);
        });

        test('${template.name} restores from its stored copy', () async {
          final source = resume(template);
          final bytes = await ResumePdfService().buildPdf(source);
          final imported = await upload(bytes);
          expect(imported.exportedResumeJson, isNotNull);
          final parsed = await const ResumeImportService().parseInBackground(
            imported,
            template: ResumeTemplate.aurora,
          );
          expectSameResume(parsed, source, bytes);
          expect(parsed.template, ResumeTemplate.aurora);
        });
      }
    });
  }

  group('The copy stored in an exported PDF', () {
    Future<Uint8List> export(ResumeData resume) =>
        ResumePdfService().buildPdf(resume);
    String? storedText(Uint8List bytes) {
      final block = RegExp(
        r'<resumeai:resume>([^<]*)',
      ).firstMatch(latin1.decode(bytes))?.group(1);
      return block == null ? null : utf8.decode(base64.decode(block));
    }

    test('never holds what the page does not print', () async {
      final stored = storedText(
        await export(
          _sampleResume(ResumeTemplate.modernLine).copyWith(
            includeProjectsInResume: false,
            projects: const [
              ProjectItem(
                title: 'SECRET project',
                subtitle: '',
                overview: 'SECRET overview',
                impact: '',
                bullets: ['SECRET bullet'],
              ),
            ],
            includeEducationInResume: false,
            education: const [
              EducationItem(
                institution: 'SECRET college',
                degree: 'SECRET degree',
                startDate: '2001',
                endDate: '2002',
                score: '',
              ),
            ],
            includeSkillsInResume: false,
            skills: const ['SECRET skill'],
          ),
        ),
      );
      expect(stored, isNotNull);
      expect(stored, isNot(contains('SECRET')));
    });

    test('keeps the photo path and look out', () async {
      final stored = storedText(
        await export(
          _sampleResume(
            ResumeTemplate.modernLine,
          ).copyWith(profileImagePath: 'photos/private.png'),
        ),
      );
      expect(stored, isNot(contains('private.png')));
      expect(stored, isNot(contains('corporateColorPresetIndex')));
    });

    test('is ignored once the PDF has been edited', () async {
      final document = sfpdf.PdfDocument(
        inputBytes: await export(_sampleResume(ResumeTemplate.modernLine)),
      );
      document.pages[0].graphics.drawString(
        'Added job at Google',
        sfpdf.PdfStandardFont(sfpdf.PdfFontFamily.helvetica, 10),
        bounds: const Rect.fromLTWH(40, 780, 300, 20),
      );
      final edited = Uint8List.fromList(document.saveSync());
      document.dispose();
      expect((await upload(edited)).exportedResumeJson, isNull);
    });

    test('survives another tool saving the PDF unchanged', () async {
      final document = sfpdf.PdfDocument(
        inputBytes: await export(_sampleResume(ResumeTemplate.modernLine)),
      );
      final saved = Uint8List.fromList(document.saveSync());
      document.dispose();
      expect((await upload(saved)).exportedResumeJson, isNotNull);
    });

    test('is left out when the name cannot be read from the page', () async {
      final bytes = await export(
        _sampleResume(ResumeTemplate.modernLine).copyWith(fullName: 'रोहन कपूर'),
      );
      expect((await upload(bytes)).exportedResumeJson, isNull);
    });

    test('a damaged copy falls back to reading the pages', () async {
      final parsed = LocalAiResumeService().parseImportedResumeText(
        resumeText: 'Priya Raman\npriya@gmail.com',
        exportedResumeJson: '{"fullName": 7}',
        template: ResumeTemplate.corporate,
      );
      expect(parsed.fullName, 'Priya Raman');
    });

    test('restores projects, added sections and renamed headings', () async {
      final source = _sampleResume(ResumeTemplate.modernLine).copyWith(
        includeProjectsInResume: true,
        projects: const [
          ProjectItem(
            title: 'Payments SDK',
            subtitle: 'Open source',
            overview: 'A small library for UPI payments.',
            impact: '',
            bullets: ['Used by 40 apps.'],
          ),
        ],
        builderSectionOrder: const ['work', 'education', 'projects', 'skills'],
        customSections: const [
          CustomSectionItem(title: 'Languages', content: 'Hindi, English'),
        ],
        sectionTitles: const {'work': 'Employment'},
      );
      final imported = await upload(await export(source));
      final parsed = await const ResumeImportService().parseInBackground(
        imported,
        template: ResumeTemplate.corporate,
      );
      expect(parsed.visibleProjects.single.title, 'Payments SDK');
      expect(parsed.visibleProjects.single.bullets, ['Used by 40 apps.']);
      expect(parsed.includeProjectsInResume, isTrue);
      expect(parsed.visibleCustomSections.single.content, 'Hindi, English');
      expect(parsed.sectionTitles, {'work': 'Employment'});
      expect(
        parsed.builderSectionOrder.where((id) => !id.startsWith('custom:')),
        ['work', 'education', 'projects', 'skills'],
      );
    });
  });

  group('Reading resume text', () {
    ResumeData parse(String text) =>
        LocalAiResumeService().parseImportedResumeText(
          resumeText: text,
          template: ResumeTemplate.corporate,
        );

    test('never uses a job line as the summary', () {
      final parsed = parse('''
Priya Raman
Product Designer
priya@gmail.com
Experience
Product Designer | Jan 2020 - Present
Figma
- Designed the mobile onboarding flow used by every new customer of the app.
''');
      expect(parsed.summary, isEmpty);
    });

    test('takes a summary with no heading from above the first section', () {
      final parsed = parse('''
Priya Raman
Product Designer
priya@gmail.com
Designer with nine years of experience shaping mobile products for large
consumer brands.
Experience
Product Designer | Jan 2020 - Present
Figma
- Designed the mobile onboarding flow.
''');
      expect(
        parsed.summary,
        'Designer with nine years of experience shaping mobile products for large consumer brands.',
      );
      expect(parsed.jobTitle, 'Product Designer');
    });

    test('dates above an entry belong to that entry', () {
      final jobs = parse('''
Priya Raman
Experience
Jan 2020 - Present
Product Designer
Figma
- Designed the onboarding flow.
Jul 2017 - Dec 2019
UX Designer
Canva
- Built the design system.
''').visibleWorkExperiences;
      expect(
        jobs.map((w) => [w.role, w.company, w.startDate, w.endDate]),
        [
          ['Product Designer', 'Figma', 'Jan 2020', 'Present'],
          ['UX Designer', 'Canva', 'Jul 2017', 'Dec 2019'],
        ],
      );
    });

    test('keeps a title with dates below it apart from the next job', () {
      final jobs = parse('''
Priya Raman
Experience
Product Designer
Jan 2020 - Present
UX Designer
Jul 2017 - Dec 2019
''').visibleWorkExperiences;
      expect(jobs.map((w) => w.role), ['Product Designer', 'UX Designer']);
    });

    test('a short form inside a word is not a degree', () {
      final education = parse('''
Priya Raman
Education
M.Tech, Computer Science | 2015 - 2017
Indian Institute of Technology Bombay
''').visibleEducation;
      expect(education.single.degree, 'M.Tech, Computer Science');
      expect(education.single.institution, 'Indian Institute of Technology Bombay');
    });

    test('a degree of two letters is kept, an avatar monogram is not', () {
      final education = parse('''
Rohan Kapoor
Education
Stanford University | 2015 - 2017
MS
Pune University | 2011 - 2015
BE
RK
''').visibleEducation;
      expect(education.map((e) => e.degree), ['MS', 'BE']);
    });

    test('reads a company set before its dates and the role below it', () {
      final job = parse('''
Priya Raman
Experience
Figma | Jan 2020 - Present
Product Designer
- Designed the onboarding flow.
''').visibleWorkExperiences.single;
      expect([job.role, job.company], ['Product Designer', 'Figma']);
    });

    test('leaves role and company as they are when unsure', () {
      final job = parse('''
Priya Raman
Experience
Barista | Jan 2020 - Present
Starbucks
- Trained new staff.
''').visibleWorkExperiences.single;
      expect([job.role, job.company], ['Barista', 'Starbucks']);
    });

    test('keeps words like "to" that are not part of a date range', () {
      final job = parse('''
Priya Raman
Experience
Designer | Head to Toe Inc | Jan 2020 to Present
- Designed things.
''').visibleWorkExperiences.single;
      expect(job.company, 'Head to Toe Inc');
      expect([job.startDate, job.endDate], ['Jan 2020', 'Present']);
    });

    test('a wrapped sentence is not a new job', () {
      final jobs = parse('''
Priya Raman
Experience
Product Designer
Figma | Jan 2020 - Present
Led the redesign of the onboarding flow for
every new customer of the app.
UX Designer
Canva | Jul 2017 - Dec 2019
''').visibleWorkExperiences;
      expect(jobs.map((w) => w.role), ['Product Designer', 'UX Designer']);
      expect(jobs.first.bullets.single, contains('every new customer'));
    });

    test('finds the location among other contact details', () {
      for (final line in [
        'priya@gmail.com · Pune, India · linkedin.com/in/priya',
        'Pune, India, +91 98200 11223, priya@gmail.com',
        '+91 98200 11223 priya@gmail.com Pune, India',
      ]) {
        expect(parse('Priya Raman\n$line').location, 'Pune, India');
      }
    });

    test('a job title set above the name does not become the name', () {
      final parsed = parse('''
SENIOR ANDROID DEVELOPER
Rohan Kapoor
rohan@gmail.com
''');
      expect(parsed.fullName, 'Rohan Kapoor');
      expect(parsed.jobTitle, 'SENIOR ANDROID DEVELOPER');
    });

    test('reads a bracketed phone number and leaves date ranges alone', () {
      expect(parse('Sarah Mitchell\n(415) 555-0132').phone, '(415) 555-0132');
      expect(parse('Sarah Mitchell\n415.555.0132').phone, '415.555.0132');
      expect(
        parse('Sarah Mitchell\nEducation\nBA | 2013 - 2017').phone,
        isEmpty,
      );
    });

    test('rejoins a date wrapped onto the next line', () {
      final jobs = parse('''
Sarah Mitchell
Experience
Marketing Manager, Acme Software Inc., San Francisco, CA | January
2019 - Present
- Grew pipeline by 45%.
Content Strategist, Bright Media LLC, Oakland, CA | June 2015 -
December 2018
- Launched the blog.
''').visibleWorkExperiences;
      expect(
        jobs.map((w) => [w.role, w.company, w.startDate, w.endDate]),
        [
          ['Marketing Manager', 'Acme Software Inc.', 'January 2019', 'Present'],
          ['Content Strategist', 'Bright Media LLC', 'June 2015', 'December 2018'],
        ],
      );
    });

    test('an employer above the title is read as the employer', () {
      final job = parse('''
David Chen
Work History
Starbucks \u2014 Portland, OR
Shift Supervisor, 03/2021 to Present
\u2022 Trained 12 new baristas.
''').visibleWorkExperiences.single;
      expect([job.role, job.company], ['Shift Supervisor', 'Starbucks']);
      expect([job.startDate, job.endDate], ['03/2021', 'Present']);
    });

    test('splits a name and title sharing the top line', () {
      final parsed = parse('''
Rohan Kapoor | Senior Android Developer
rohan@gmail.com
''');
      expect(parsed.fullName, 'Rohan Kapoor');
      expect(parsed.jobTitle, 'Senior Android Developer');
    });
  });

  test('Outfit font choice exports readable text', () async {
    final parsed = await _uploadExportedPdf(
      ResumeTemplate.atsStructured,
      font: ResumeTextFont.outfit,
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

  test('PDF sanitizer strips leftover 龱 list markers', () {
    const service = ResumeImportService();
    expect(
      service.sanitizePdfExtractedText('• \u9FB1 Lead a team of 8 iOS developers.'),
      '- Lead a team of 8 iOS developers.',
    );
    expect(
      service.sanitizePdfExtractedText('\u9FB1\nManage day-to-day engineering operations.'),
      'Manage day-to-day engineering operations.',
    );
    expect(
      service.sanitizePdfExtractedText('• \u9FB1Led and motivated a technical team.'),
      '- Led and motivated a technical team.',
    );
    expect(
      service.sanitizePdfExtractedText('Xavier Young\nMac OS X'),
      'Xavier Young\nMac OS X',
    );
  });

  test('splits glued skill lines and drops leftover glyphs', () {
    final parsed = LocalAiResumeService().parseImportedResumeText(
      resumeText: '''
Rohan Kapoor
Senior Android Developer
Skills
Kotlin Java Jetpack Compose
\u9FB1 Coroutines
Flutter
''',
      template: ResumeTemplate.corporate,
    );
    expect(
      parsed.skills,
      containsAll(['Kotlin', 'Java', 'Jetpack Compose', 'Coroutines', 'Flutter']),
    );
    for (final skill in parsed.skills) {
      expect(skill, isNot(contains(kPdfListMarkerLeftover)));
      expect(skill.split(RegExp(r'\s+')).length, lessThanOrEqualTo(4));
    }
  });

  test('saved skills drop leftover 龱 on load', () {
    final resume = ResumeData.fromJson({
      'id': 'skill-cleanup',
      'title': 'Resume',
      'template': ResumeTemplate.corporate.name,
      'fullName': 'Rohan Kapoor',
      'skills': ['\u9FB1 Kotlin', 'Java', '\u9FB1'],
    });
    expect(resume.skills, ['Kotlin', 'Java']);
  });

  test('saved work bullets drop leftover 龱 on load', () {
    final item = WorkExperience.fromJson({
      'role': 'iOS Tech Lead',
      'company': 'Anviam',
      'startDate': 'Sep 2016',
      'endDate': 'Nov 2022',
      'description': '',
      'bullets': [
        '\u9FB1 Led and motivated a technical team.',
        '\u9FB1',
        'Applied strong interpersonal skills.',
      ],
    });
    expect(item.bullets, [
      'Led and motivated a technical team.',
      'Applied strong interpersonal skills.',
    ]);
  });
  test('parseInBackground matches parsing in place', () async {
    const file = ImportedResumeFile(
      fileName: 'Priya Raman.txt',
      resumeText:
          'Priya Raman\nMarketing Manager\npriya@email.com\n+1 415 555 0142\n\n'
          'EXPERIENCE\nMarketing Manager at Northstar Labs\n2019 - Present\n'
          '- Grew qualified pipeline across three regions.\n\n'
          'SKILLS\nCampaign strategy, Lifecycle marketing',
    );
    final inPlace = LocalAiResumeService().parseImportedResumeText(
      resumeText: file.resumeText,
      candidateResumeTexts: file.candidateResumeTexts,
      template: ResumeTemplate.corporate,
      sourceTitle: file.suggestedTitle,
    );
    final background = await const ResumeImportService().parseInBackground(
      file,
      template: ResumeTemplate.corporate,
    );

    expect(background.fullName, inPlace.fullName);
    expect(background.email, inPlace.email);
    expect(background.skills, inPlace.skills);
    expect(
      background.workExperiences.map((e) => e.role),
      inPlace.workExperiences.map((e) => e.role),
    );
    expect(background.fullName, 'Priya Raman');
  });
  group('imported projects', () {
    const withProjects =
        'Priya Raman\nMarketing Manager\npriya@email.com\n\n'
        'EXPERIENCE\nMarketing Manager at Northstar Labs\n2019 - Present\n\n'
        'PROJECTS\nResume Platform\n- Shipped the editor.\n- Cut export time in half.';
    const withoutProjects =
        'Priya Raman\nMarketing Manager\npriya@email.com\n\n'
        'EXPERIENCE\nMarketing Manager at Northstar Labs\n2019 - Present';

    ResumeData parse(String text) => LocalAiResumeService().parseImportedResumeText(
      resumeText: text,
      candidateResumeTexts: const [],
      template: ResumeTemplate.corporate,
      sourceTitle: 'Priya',
    );

    test('an uploaded resume that has projects shows them', () {
      final resume = parse(withProjects);
      expect(resume.projects.where((p) => !p.isBlank), isNotEmpty);
      expect(resume.includeProjectsInResume, isTrue);
      expect(resume.effectiveBuilderSectionOrder, contains('projects'));
    });

    test('an uploaded resume without projects leaves the section off', () {
      final resume = parse(withoutProjects);
      expect(resume.includeProjectsInResume, isFalse);
      expect(resume.effectiveBuilderSectionOrder, isNot(contains('projects')));
    });
  });
}
