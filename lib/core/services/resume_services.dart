import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/resume_models.dart';

class ResumeRepository {
  ResumeRepository._(this._resumeBox, this._coverLetterBox);

  final Box<dynamic> _resumeBox;
  final Box<dynamic> _coverLetterBox;

  static Future<ResumeRepository> create() async {
    await Hive.initFlutter();
    final resumeBox = await Hive.openBox<dynamic>('resume_library');
    final coverLetterBox = await Hive.openBox<dynamic>('cover_letter_library');
    return ResumeRepository._(resumeBox, coverLetterBox);
  }

  Future<List<ResumeData>> loadResumes() async {
    final items =
        _resumeBox.values
            .whereType<Map>()
            .map((item) => ResumeData.fromJson(Map<String, dynamic>.from(item)))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> upsertResume(ResumeData resume) async {
    await _resumeBox.put(resume.id, resume.toJson());
  }

  Future<void> deleteResume(String id) async {
    await _resumeBox.delete(id);
  }

  Future<List<CoverLetterData>> loadCoverLetters() async {
    final items =
        _coverLetterBox.values
            .whereType<Map>()
            .map(
              (item) =>
                  CoverLetterData.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {
    await _coverLetterBox.put(coverLetter.id, coverLetter.toJson());
  }

  Future<void> deleteCoverLetter(String id) async {
    await _coverLetterBox.delete(id);
  }
}

class LocalAiResumeService {
  Future<String> generateSummary(ResumeData resume) async {
    return _simulate(() {
      final title = resume.jobTitle.trim().isEmpty
          ? 'professional candidate'
          : resume.jobTitle.trim();
      final primarySkills = resume.skills.take(4).join(', ');
      final experienceCount = math.max(1, resume.visibleWorkExperiences.length);

      return '${resume.fullName.trim().isEmpty ? 'Results-driven' : resume.fullName.trim()} '
          'is a $title with $experienceCount standout experience ${experienceCount == 1 ? 'entry' : 'stories'} '
          'across delivery, collaboration, and measurable execution. '
          '${primarySkills.isEmpty ? 'Combines strong communication, problem solving, and ownership to create polished outcomes.' : 'Brings $primarySkills to build polished outcomes with real business impact.'} '
          'Ready to contribute quickly in fast-moving teams.';
    });
  }

  Future<List<String>> generateJobBullets({
    required String role,
    required String company,
    required String targetJobTitle,
  }) async {
    return _simulate(() {
      final focus = _jobTitleSkillSuggestions(
        targetJobTitle,
      ).take(3).join(', ');
      final normalizedRole = role.trim().isEmpty
          ? 'team member'
          : role.trim().toLowerCase();
      final normalizedCompany = company.trim().isEmpty
          ? 'the company'
          : company.trim();

      return [
        'Led $normalizedRole initiatives at $normalizedCompany, improving delivery quality through clearer prioritization and faster stakeholder alignment.',
        'Translated business needs into repeatable workflows and documentation, helping the team move faster with fewer revision cycles.',
        'Partnered cross-functionally to launch customer-facing improvements, using $focus to strengthen outcomes and communicate impact.',
      ];
    });
  }

  Future<List<String>> suggestSkills({
    required ResumeData resume,
    String? targetJobTitle,
  }) async {
    return _simulate(
      () => _resumeSkillSuggestions(
        resume: resume,
        targetJobTitle: targetJobTitle,
      ),
    );
  }

  Future<List<String>> improveResume(ResumeData resume) async {
    return _simulate(() {
      final analysis = _buildAnalysis(resume: resume, jobDescription: '');
      final tips = <String>[
        ...analysis.improvements,
        if (resume.summary.trim().isEmpty)
          'Add a 2-3 sentence summary so recruiters understand your value immediately.',
        if (resume.visibleProjects.isEmpty)
          'Include at least one project with a measurable outcome to increase credibility.',
      ];

      return tips.toSet().take(6).toList();
    });
  }

  Future<ResumeAnalysis> analyzeResume({
    required ResumeData resume,
    String jobDescription = '',
  }) async {
    return _simulate(
      () => _buildAnalysis(resume: resume, jobDescription: jobDescription),
    );
  }

  Future<String> generateCoverLetter({
    required ResumeData resume,
    required String company,
    required String role,
  }) async {
    return _simulate(() {
      final introName = resume.fullName.trim().isEmpty
          ? 'I'
          : resume.fullName.trim();
      final highlight = resume.visibleWorkExperiences.isNotEmpty
          ? resume.visibleWorkExperiences.first.company
          : 'recent hands-on projects';
      final strengths = resume.skills.take(3).join(', ');

      return 'Dear Hiring Team,\n\n'
          'I am excited to apply for the $role position at $company. '
          '$introName has built strong experience through $highlight, focusing on execution, communication, and outcomes that matter.\n\n'
          '${strengths.isEmpty ? 'My background combines adaptability, structured thinking, and a bias toward action.' : 'My background is especially strong in $strengths, which aligns well with the needs of this role.'} '
          'I enjoy turning ambiguous goals into clear plans and reliable delivery.\n\n'
          'I would welcome the opportunity to bring that same energy to $company and contribute quickly from day one.\n\n'
          'Sincerely,\n'
          '${resume.fullName.trim().isEmpty ? 'Your Name' : resume.fullName.trim()}';
    });
  }

  Future<JobDescriptionInsights> analyzeJobDescription({
    required String jobDescription,
    required ResumeData resume,
  }) async {
    return _simulate(() {
      final keywords = _extractKeywords(jobDescription).take(8).toList();
      final haystack = [
        resume.jobTitle,
        resume.summary,
        ...resume.skills,
        ...resume.visibleWorkExperiences.expand((item) => item.bullets),
      ].join(' ').toLowerCase();

      final missing = keywords
          .where((keyword) => !haystack.contains(keyword.toLowerCase()))
          .take(5)
          .toList();

      final summary = keywords.isEmpty
          ? 'Add a job description to extract ATS keywords and compare them with your resume.'
          : 'The posting emphasizes ${keywords.take(3).join(', ')}. '
                '${missing.isEmpty ? 'Your resume already reflects the top terms well.' : 'Consider adding ${missing.take(2).join(' and ')} where it is truthful and relevant.'}';

      return JobDescriptionInsights(
        summary: summary,
        keywords: keywords,
        missingSkills: missing,
      );
    });
  }

  ResumeAnalysis _buildAnalysis({
    required ResumeData resume,
    required String jobDescription,
  }) {
    var score = 32;
    final improvements = <String>[];
    final strengths = <String>[];
    final weakDescriptions = <String>[];

    if (resume.fullName.trim().isNotEmpty) {
      score += 8;
    } else {
      improvements.add(
        'Add your full name to create a complete resume header.',
      );
    }

    if (resume.email.trim().isNotEmpty && resume.phone.trim().isNotEmpty) {
      score += 10;
      strengths.add('Includes reachable contact information.');
    } else {
      improvements.add(
        'Add both email and phone so recruiters can contact you quickly.',
      );
    }

    if (resume.summary.trim().length > 90) {
      score += 10;
      strengths.add('Summary introduces value clearly.');
    } else {
      improvements.add(
        'Strengthen the summary with 2-3 lines focused on outcomes and target role.',
      );
    }

    if (resume.visibleWorkExperiences.isNotEmpty) {
      score += 16;
      strengths.add('Work experience section is present.');
      for (final experience in resume.visibleWorkExperiences) {
        final bulletStrength = experience.bullets
            .where((item) => item.length > 45)
            .length;
        if (bulletStrength < 2 && experience.description.trim().length < 60) {
          weakDescriptions.add(
            '${experience.role.trim().isEmpty ? 'Experience entry' : experience.role.trim()} needs stronger, outcome-focused bullets.',
          );
        }
      }
    } else {
      improvements.add(
        'Add at least one work experience entry, internship, or freelance project.',
      );
    }

    if (resume.skills.length >= 6) {
      score += 10;
      strengths.add('Skill inventory is broad enough for ATS matching.');
    } else {
      improvements.add(
        'Expand the skills section with tools, methods, and domain keywords.',
      );
    }

    if (resume.visibleEducation.isNotEmpty) {
      score += 6;
    } else {
      improvements.add('Add education details to complete the profile.');
    }

    if (resume.visibleProjects.isNotEmpty) {
      score += 8;
      strengths.add('Projects add proof of execution.');
    } else {
      improvements.add(
        'Include 1-2 projects with impact metrics or user outcomes.',
      );
    }

    final keywords = _extractKeywords(jobDescription).take(10).toList();
    final resumeText = [
      resume.jobTitle,
      resume.summary,
      ...resume.skills,
      ...resume.visibleWorkExperiences.expand((item) => item.bullets),
    ].join(' ').toLowerCase();

    final missingSkills = keywords
        .where((keyword) => !resumeText.contains(keyword.toLowerCase()))
        .take(5)
        .toList();

    if (keywords.isNotEmpty) {
      if (missingSkills.isEmpty) {
        score += 12;
        strengths.add('Good alignment with the target job description.');
      } else {
        score += 5;
        improvements.add(
          'Mirror more relevant job-description keywords where they are truthful.',
        );
      }
    }

    score = score.clamp(0, 100);

    return ResumeAnalysis(
      score: score,
      atsCompatibility: score / 100,
      missingSkills: missingSkills,
      weakDescriptions: weakDescriptions,
      strengths: strengths,
      improvements: improvements.toSet().toList(),
    );
  }

  List<String> _resumeSkillSuggestions({
    required ResumeData resume,
    String? targetJobTitle,
  }) {
    final suggestions = <String>[];
    final titleSources = <String>[];
    final seenTitleSources = <String>{};

    void addTitleSource(String value, {bool ignoreDefaultTitle = false}) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      if (ignoreDefaultTitle && trimmed == ResumeData.defaultTitle) {
        return;
      }

      if (seenTitleSources.add(trimmed.toLowerCase())) {
        titleSources.add(trimmed);
      }
    }

    addTitleSource(resume.title, ignoreDefaultTitle: true);
    addTitleSource(resume.jobTitle);
    addTitleSource(targetJobTitle ?? '');

    final combinedContext = [
      ...titleSources,
      ...resume.visibleWorkExperiences.expand(
        (item) => [item.role, item.company, item.description, ...item.bullets],
      ),
    ].where((item) => item.trim().isNotEmpty).join(' ').toLowerCase();

    void addSuggestions(Iterable<String> values) {
      for (final value in values) {
        if (!suggestions.contains(value)) {
          suggestions.add(value);
        }
      }
    }

    if (_containsAny(combinedContext, ['flutter', 'dart'])) {
      addSuggestions(['Flutter', 'Dart']);
    }
    if (_containsAny(combinedContext, [
      'mobile',
      'android',
      'ios',
      'app store',
    ])) {
      addSuggestions(['Mobile App Development']);
    }
    if (_containsAny(combinedContext, [
      'rest api',
      'restful',
      'api',
      'graphql',
    ])) {
      addSuggestions(['REST APIs', 'API Integration']);
    }
    if (_containsAny(combinedContext, [
      'provider',
      'bloc',
      'riverpod',
      'state management',
    ])) {
      addSuggestions(['State Management']);
    }
    if (_containsAny(combinedContext, ['firebase'])) {
      addSuggestions(['Firebase']);
    }
    if (_containsAny(combinedContext, [
      'unit test',
      'widget test',
      'testing',
    ])) {
      addSuggestions(['Unit Testing']);
    }
    if (_containsAny(combinedContext, [
      'deploy',
      'release',
      'ci/cd',
      'pipeline',
    ])) {
      addSuggestions(['CI/CD']);
    }
    if (_containsAny(combinedContext, ['react', 'next.js', 'nextjs'])) {
      addSuggestions(['React']);
    }
    if (_containsAny(combinedContext, ['javascript'])) {
      addSuggestions(['JavaScript']);
    }
    if (_containsAny(combinedContext, ['typescript'])) {
      addSuggestions(['TypeScript']);
    }
    if (_containsAny(combinedContext, ['figma', 'wireframe', 'prototype'])) {
      addSuggestions(['Figma', 'Wireframing', 'Prototyping']);
    }
    if (_containsAny(combinedContext, [
      'design system',
      'ui kit',
      'component library',
    ])) {
      addSuggestions(['Design Systems']);
    }
    if (_containsAny(combinedContext, [
      'user research',
      'user interview',
      'usability',
    ])) {
      addSuggestions(['User Research']);
    }
    if (_containsAny(combinedContext, [
      'sql',
      'query',
      'database',
      'warehouse',
    ])) {
      addSuggestions(['SQL', 'Data Analysis']);
    }
    if (_containsAny(combinedContext, [
      'dashboard',
      'analytics',
      'metric',
      'kpi',
    ])) {
      addSuggestions(['Analytics', 'Dashboarding']);
    }
    if (_containsAny(combinedContext, ['a/b test', 'ab test', 'experiment'])) {
      addSuggestions(['A/B Testing', 'Experiment Design']);
    }
    if (_containsAny(combinedContext, [
      'roadmap',
      'product strategy',
      'backlog',
    ])) {
      addSuggestions(['Roadmapping', 'Product Strategy']);
    }
    if (_containsAny(combinedContext, [
      'stakeholder',
      'client',
      'cross-functional',
      'cross functional',
    ])) {
      addSuggestions([
        'Stakeholder Management',
        'Cross-functional Collaboration',
      ]);
    }
    if (_containsAny(combinedContext, [
      'document',
      'documentation',
      'report',
      'spec',
    ])) {
      addSuggestions(['Documentation']);
    }
    if (_containsAny(combinedContext, [
      'launch',
      'delivery',
      'deliver',
      'execution',
    ])) {
      addSuggestions(['Project Management', 'Execution']);
    }
    if (_containsAny(combinedContext, [
      'process improvement',
      'workflow',
      'automation',
      'streamline',
    ])) {
      addSuggestions(['Process Improvement']);
    }
    if (_containsAny(combinedContext, [
      'presentation',
      'presented',
      'training',
      'enablement',
    ])) {
      addSuggestions(['Presentation Skills']);
    }
    if (_containsAny(combinedContext, ['seo', 'campaign', 'content', 'crm'])) {
      addSuggestions(['SEO', 'Campaign Strategy', 'Content Planning']);
    }

    for (final titleSource in titleSources) {
      addSuggestions(_jobTitleSkillSuggestions(titleSource));
    }

    if (suggestions.isEmpty) {
      addSuggestions(const [
        'Communication',
        'Problem Solving',
        'Cross-functional Collaboration',
      ]);
    }

    return suggestions.take(8).toList();
  }

  List<String> _jobTitleSkillSuggestions(String jobTitle) {
    final normalized = jobTitle.toLowerCase();
    final suggestions = <String>{'Communication', 'Problem Solving'};

    if (normalized.contains('designer')) {
      suggestions.addAll([
        'Figma',
        'Design Systems',
        'User Research',
        'Wireframing',
        'Prototyping',
        'Accessibility',
      ]);
    } else if (normalized.contains('product')) {
      suggestions.addAll([
        'Product Strategy',
        'Stakeholder Management',
        'Roadmapping',
        'A/B Testing',
        'SQL',
        'Analytics',
        'Experiment Design',
      ]);
    } else if (normalized.contains('engineer') ||
        normalized.contains('developer')) {
      suggestions.addAll([
        'Flutter',
        'Dart',
        'REST APIs',
        'State Management',
        'CI/CD',
        'Unit Testing',
      ]);
    } else if (normalized.contains('marketing')) {
      suggestions.addAll([
        'Campaign Strategy',
        'SEO',
        'Content Planning',
        'Performance Marketing',
        'CRM',
      ]);
    } else {
      suggestions.addAll([
        'Project Management',
        'Cross-functional Collaboration',
        'Documentation',
        'Presentation Skills',
      ]);
    }

    return suggestions.toList();
  }

  bool _containsAny(String value, List<String> needles) {
    for (final needle in needles) {
      if (value.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  Iterable<String> _extractKeywords(String input) sync* {
    final commonWords = {
      'with',
      'that',
      'from',
      'this',
      'your',
      'their',
      'will',
      'have',
      'about',
      'using',
      'years',
      'ability',
      'team',
      'work',
      'role',
      'experience',
      'responsible',
      'preferred',
      'required',
    };

    final matches = RegExp(r'[A-Za-z][A-Za-z+/&-]{3,}').allMatches(input);
    final unique = <String>{};
    for (final match in matches) {
      final keyword = match.group(0)!.trim();
      final lower = keyword.toLowerCase();
      if (!commonWords.contains(lower) && unique.add(keyword)) {
        yield keyword;
      }
    }
  }

  Future<T> _simulate<T>(T Function() action) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return action();
  }
}

class ResumePdfService {
  Future<Uint8List> buildPdf(ResumeData resume) async {
    final document = pw.Document();
    final accent = PdfColor.fromInt(resume.template.accentColor.toARGB32());
    final muted = PdfColors.grey700;

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 18),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: accent, width: 2)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  resume.fullName.trim().isEmpty
                      ? 'Your Name'
                      : resume.fullName.trim(),
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  resume.jobTitle.trim().isEmpty
                      ? resume.title
                      : resume.jobTitle.trim(),
                  style: pw.TextStyle(fontSize: 16, color: muted),
                ),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (resume.email.trim().isNotEmpty)
                      pw.Text(
                        resume.email.trim(),
                        style: pw.TextStyle(color: muted),
                      ),
                    if (resume.phone.trim().isNotEmpty)
                      pw.Text(
                        resume.phone.trim(),
                        style: pw.TextStyle(color: muted),
                      ),
                    if (resume.location.trim().isNotEmpty)
                      pw.Text(
                        resume.location.trim(),
                        style: pw.TextStyle(color: muted),
                      ),
                    if (resume.website.trim().isNotEmpty)
                      pw.Text(
                        resume.website.trim(),
                        style: pw.TextStyle(color: muted),
                      ),
                    if (resume.githubLink.trim().isNotEmpty)
                      pw.Text(
                        resume.githubLink.trim(),
                        style: pw.TextStyle(color: muted),
                      ),
                    if (resume.linkedinLink.trim().isNotEmpty)
                      pw.Text(
                        resume.linkedinLink.trim(),
                        style: pw.TextStyle(color: muted),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (resume.summary.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('Professional Summary', accent),
            pw.Text(resume.summary.trim()),
          ],
          if (resume.visibleWorkExperiences.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('Work Experience', accent),
            ...resume.visibleWorkExperiences.map(_buildExperience),
          ],
          if (resume.visibleEducation.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('Education', accent),
            ...resume.visibleEducation.map(_buildEducation),
          ],
          if (resume.skills.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('Skills', accent),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in resume.skills)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(
                        resume.template.tintColor.toARGB32(),
                      ),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(skill),
                  ),
              ],
            ),
          ],
          if (resume.visibleProjects.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('Projects', accent),
            ...resume.visibleProjects.map(_buildProject),
          ],
          if (resume.visibleCustomSections.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            ...resume.visibleCustomSections.map(
              (item) => _buildCustomSection(item, accent),
            ),
          ],
        ],
      ),
    );

    return document.save();
  }

  Future<File> savePdfToDevice(ResumeData resume) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${directory.path}/exports');
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final safeName = _sanitizeFileName(
      resume.fullName.trim().isEmpty ? resume.title : resume.fullName,
    );
    final file = File(
      '${exportDirectory.path}/$safeName-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final bytes = await buildPdf(resume);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareResume(ResumeData resume) async {
    final file = await savePdfToDevice(resume);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${resume.title} resume',
      text: 'Shared from ResumeAI',
    );
  }

  Future<void> printResume(ResumeData resume) async {
    final bytes = await buildPdf(resume);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${_sanitizeFileName(resume.title)}.pdf',
      format: PdfPageFormat.a4,
    );
  }

  pw.Widget _sectionHeading(String title, PdfColor accent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: accent,
          fontWeight: pw.FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  pw.Widget _buildExperience(WorkExperience item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${item.role.trim().isEmpty ? 'Role' : item.role.trim()} · ${item.company.trim().isEmpty ? 'Company' : item.company.trim()}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (item.startDate.trim().isNotEmpty ||
                  item.endDate.trim().isNotEmpty)
                pw.Text('${item.startDate} - ${item.endDate}'),
            ],
          ),
          if (item.description.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(item.description.trim()),
          ],
          if (item.bullets.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final bullet in item.bullets.take(4))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• '),
                        pw.Expanded(child: pw.Text(bullet)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEducation(EducationItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${item.degree.trim().isEmpty ? 'Degree' : item.degree.trim()} · ${item.institution.trim().isEmpty ? 'Institution' : item.institution.trim()}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (item.year.trim().isNotEmpty ||
              item.score.trim().isNotEmpty ||
              item.details.trim().isNotEmpty)
            pw.Text(
              [
                item.year.trim(),
                item.score.trim(),
                item.details.trim(),
              ].where((part) => part.isNotEmpty).join(' · '),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildProject(ProjectItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.title.trim().isEmpty ? 'Project Title' : item.title.trim(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (item.overview.trim().isNotEmpty) pw.Text(item.overview.trim()),
          if (item.impact.trim().isNotEmpty) pw.Text(item.impact.trim()),
        ],
      ),
    );
  }

  pw.Widget _buildCustomSection(CustomSectionItem item, PdfColor accent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeading(item.title.ifEmpty('Custom Section'), accent),
          if (item.content.trim().isNotEmpty) pw.Text(item.content.trim()),
        ],
      ),
    );
  }

  String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .ifEmpty('resume');
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
