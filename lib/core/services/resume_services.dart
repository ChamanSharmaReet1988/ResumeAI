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
    final document = pw.Document(theme: _resumeDocumentTheme);

    switch (resume.template.userFacingTemplate) {
      case ResumeTemplate.modern:
      case ResumeTemplate.corporate:
        _addCorporateTemplatePage(document, resume);
        break;
      case ResumeTemplate.minimal:
        _addMinimalTemplatePage(document, resume);
        break;
      case ResumeTemplate.creative:
        _addCreativeTemplatePage(document, resume);
        break;
      case ResumeTemplate.copperSerif:
        _addCopperSerifTemplatePage(document, resume);
        break;
      case ResumeTemplate.splitBanner:
        _addSplitBannerTemplatePage(document, resume);
        break;
      case ResumeTemplate.monogramSidebar:
        _addMonogramSidebarTemplatePage(document, resume);
        break;
    }

    return document.save();
  }

  static final pw.ThemeData _resumeDocumentTheme = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    italic: pw.Font.helveticaOblique(),
    boldItalic: pw.Font.helveticaBoldOblique(),
  );

  void _addCorporateTemplatePage(pw.Document document, ResumeData resume) {
    final headerColor = PdfColor.fromHex('#3B4046');
    final lineColor = PdfColor.fromHex('#D7DCE2');

    document.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Container(
            color: headerColor,
            padding: const pw.EdgeInsets.fromLTRB(30, 28, 30, 22),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 48,
                  height: 48,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.white, width: 1.4),
                  ),
                  child: pw.Text(
                    _resumeInitials(resume),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _displayName(resume).toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        _resumeContactItems(resume).join('  /  '),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          if (resume.summary.trim().isNotEmpty)
            _corporateSection(
              title: 'Summary',
              lineColor: lineColor,
              child: pw.Text(resume.summary.trim()),
            ),
          _corporateSection(
            title: 'Skills',
            lineColor: lineColor,
            child: _twoColumnBulletList(_skillsForDisplay(resume)),
          ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _corporateSection(
              title: 'Experience',
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleWorkExperiences)
                    _buildCorporateExperience(item),
                ],
              ),
            ),
          if (resume.visibleEducation.isNotEmpty)
            _corporateSection(
              title: 'Education and Training',
              lineColor: lineColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final item in resume.visibleEducation)
                    _buildCorporateEducation(item),
                ],
              ),
            ),
          if (resume.visibleProjects.isNotEmpty)
            _corporateSection(
              title: 'Projects',
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleProjects)
                    _buildCompactProject(item),
                ],
              ),
            ),
          for (final item in resume.visibleCustomSections)
            _corporateSection(
              title: item.title.ifEmpty('Custom Section'),
              lineColor: lineColor,
              child: pw.Text(item.content.trim()),
            ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  void _addMinimalTemplatePage(pw.Document document, ResumeData resume) {
    final lineColor = PdfColor.fromHex('#D7DCE2');
    final textMuted = PdfColor.fromHex('#5E6369');

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 28),
        build: (context) => [
          pw.Center(
            child: pw.Container(
              width: 44,
              height: 44,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PdfColors.grey700, width: 1),
              ),
              child: pw.Text(
                _resumeInitials(resume),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              _displayName(resume).toUpperCase(),
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              _resumeContactItems(resume).join('  |  '),
              style: pw.TextStyle(fontSize: 9, color: textMuted),
            ),
          ),
          pw.SizedBox(height: 18),
          if (resume.summary.trim().isNotEmpty)
            _minimalSection(
              title: 'Summary',
              lineColor: lineColor,
              child: pw.Text(resume.summary.trim()),
            ),
          _minimalSection(
            title: 'Skills',
            lineColor: lineColor,
            child: _twoColumnBulletList(_skillsForDisplay(resume)),
          ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _minimalSection(
              title: 'Experience',
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleWorkExperiences)
                    _buildMinimalExperience(item),
                ],
              ),
            ),
          if (resume.visibleEducation.isNotEmpty)
            _minimalSection(
              title: 'Education and Training',
              lineColor: lineColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final item in resume.visibleEducation)
                    _buildCorporateEducation(item),
                ],
              ),
            ),
          if (resume.visibleProjects.isNotEmpty)
            _minimalSection(
              title: 'Projects',
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleProjects)
                    _buildCompactProject(item),
                ],
              ),
            ),
          for (final item in resume.visibleCustomSections)
            _minimalSection(
              title: item.title.ifEmpty('Custom Section'),
              lineColor: lineColor,
              child: pw.Text(item.content.trim()),
            ),
        ],
      ),
    );
  }

  void _addCreativeTemplatePage(pw.Document document, ResumeData resume) {
    final dark = PdfColor.fromHex('#353A40');
    final lineColor = PdfColor.fromHex('#B8BEC6');
    final muted = PdfColor.fromHex('#5D6268');

    document.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Container(height: 18, color: dark),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(28, 22, 28, 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 68,
                      height: 84,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#EED7BF'),
                        border: pw.Border.all(color: lineColor),
                      ),
                      child: pw.Text(
                        _resumeInitials(resume),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: dark,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _displayName(resume).toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 23,
                              fontWeight: pw.FontWeight.bold,
                              color: dark,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          for (final item in _resumeContactItems(resume))
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text(
                                item,
                                style: pw.TextStyle(fontSize: 9, color: muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                if (resume.summary.trim().isNotEmpty)
                  _creativeSection(
                    title: 'Summary',
                    lineColor: lineColor,
                    child: pw.Text(resume.summary.trim()),
                  ),
                _creativeSection(
                  title: 'Skills',
                  lineColor: lineColor,
                  child: _twoColumnBulletList(_skillsForDisplay(resume)),
                ),
                if (resume.visibleWorkExperiences.isNotEmpty)
                  _creativeSection(
                    title: 'Experience',
                    lineColor: lineColor,
                    child: pw.Column(
                      children: [
                        for (final item in resume.visibleWorkExperiences)
                          _buildCreativeExperience(item),
                      ],
                    ),
                  ),
                if (resume.visibleEducation.isNotEmpty)
                  _creativeSection(
                    title: 'Education and Training',
                    lineColor: lineColor,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        for (final item in resume.visibleEducation)
                          _buildCorporateEducation(item),
                      ],
                    ),
                  ),
                if (resume.visibleProjects.isNotEmpty)
                  _creativeSection(
                    title: 'Projects',
                    lineColor: lineColor,
                    child: pw.Column(
                      children: [
                        for (final item in resume.visibleProjects)
                          _buildCompactProject(item),
                      ],
                    ),
                  ),
                for (final item in resume.visibleCustomSections)
                  _creativeSection(
                    title: item.title.ifEmpty('Custom Section'),
                    lineColor: lineColor,
                    child: pw.Text(item.content.trim()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addCopperSerifTemplatePage(pw.Document document, ResumeData resume) {
    final copper = PdfColor.fromHex('#E7A055');
    final lineColor = PdfColor.fromHex('#D5D9DE');
    final muted = PdfColor.fromHex('#6A7076');

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              _displayName(resume).toUpperCase(),
              style: pw.TextStyle(
                fontSize: 25,
                color: copper,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              _resumeContactItems(resume).join('   |   '),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 9, color: muted),
            ),
          ),
          pw.SizedBox(height: 18),
          if (resume.summary.trim().isNotEmpty)
            _centeredAccentSection(
              title: 'Summary',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Text(
                resume.summary.trim(),
                textAlign: pw.TextAlign.center,
              ),
            ),
          _centeredAccentSection(
            title: 'Skills',
            accentColor: copper,
            lineColor: lineColor,
            child: _twoColumnBulletList(_skillsForDisplay(resume)),
          ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _centeredAccentSection(
              title: 'Experience',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleWorkExperiences)
                    _buildMinimalExperience(item),
                ],
              ),
            ),
          if (resume.visibleEducation.isNotEmpty)
            _centeredAccentSection(
              title: 'Education and Training',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  for (final item in resume.visibleEducation)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            item.degree.ifEmpty('Degree'),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            [
                              item.institution.trim(),
                              item.year.trim(),
                              item.score.trim(),
                              item.details.trim(),
                            ].where((part) => part.isNotEmpty).join('   |   '),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (resume.visibleProjects.isNotEmpty)
            _centeredAccentSection(
              title: 'Projects',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleProjects)
                    _buildCompactProject(item),
                ],
              ),
            ),
          for (final item in resume.visibleCustomSections)
            _centeredAccentSection(
              title: item.title.ifEmpty('Custom Section'),
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Text(item.content.trim()),
            ),
        ],
      ),
    );
  }

  void _addSplitBannerTemplatePage(pw.Document document, ResumeData resume) {
    final copper = PdfColor.fromHex('#EE9938');
    final lineColor = PdfColor.fromHex('#D7DBE0');

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 28),
        build: (context) => [
          pw.Container(
            color: copper,
            padding: const pw.EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    _displayName(resume).toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    for (final item in _resumeContactItems(resume))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          item,
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          if (resume.summary.trim().isNotEmpty)
            _splitBannerSection(
              title: 'Summary',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Text(resume.summary.trim()),
            ),
          _splitBannerSection(
            title: 'Skills',
            accentColor: copper,
            lineColor: lineColor,
            child: _twoColumnBulletList(_skillsForDisplay(resume)),
          ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _splitBannerSection(
              title: 'Experience',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleWorkExperiences)
                    _buildMinimalExperience(item),
                ],
              ),
            ),
          if (resume.visibleEducation.isNotEmpty)
            _splitBannerSection(
              title: 'Education',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final item in resume.visibleEducation)
                    _buildCorporateEducation(item),
                ],
              ),
            ),
          if (resume.visibleProjects.isNotEmpty)
            _splitBannerSection(
              title: 'Projects',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleProjects)
                    _buildCompactProject(item),
                ],
              ),
            ),
          for (final item in resume.visibleCustomSections)
            _splitBannerSection(
              title: item.title.ifEmpty('Custom'),
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Text(item.content.trim()),
            ),
          pw.SizedBox(height: 8),
          pw.Container(height: 3, color: copper),
        ],
      ),
    );
  }

  void _addMonogramSidebarTemplatePage(
    pw.Document document,
    ResumeData resume,
  ) {
    final copper = PdfColor.fromHex('#E39A3A');
    final dark = PdfColor.fromHex('#17181A');
    final lineColor = PdfColor.fromHex('#D5D9DE');
    final muted = PdfColor.fromHex('#666B71');

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 28),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 100,
                padding: const pw.EdgeInsets.only(right: 16),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(color: lineColor, width: 1),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: 48,
                      height: 48,
                      alignment: pw.Alignment.center,
                      color: dark,
                      child: pw.Text(
                        _resumeInitials(resume),
                        style: pw.TextStyle(
                          color: copper,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      _displayName(resume),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: copper,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    for (final item in _resumeContactItems(resume))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          item,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 8.5, color: muted),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (resume.summary.trim().isNotEmpty)
                      _monogramSidebarSection(
                        title: 'Summary',
                        child: pw.Text(resume.summary.trim()),
                      ),
                    _monogramSidebarSection(
                      title: 'Skills',
                      child: _twoColumnBulletList(_skillsForDisplay(resume)),
                    ),
                    if (resume.visibleWorkExperiences.isNotEmpty)
                      _monogramSidebarSection(
                        title: 'Experience',
                        child: pw.Column(
                          children: [
                            for (final item in resume.visibleWorkExperiences)
                              _buildMinimalExperience(item),
                          ],
                        ),
                      ),
                    if (resume.visibleEducation.isNotEmpty)
                      _monogramSidebarSection(
                        title: 'Education and Training',
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            for (final item in resume.visibleEducation)
                              _buildCorporateEducation(item),
                          ],
                        ),
                      ),
                    if (resume.visibleProjects.isNotEmpty)
                      _monogramSidebarSection(
                        title: 'Projects',
                        child: pw.Column(
                          children: [
                            for (final item in resume.visibleProjects)
                              _buildCompactProject(item),
                          ],
                        ),
                      ),
                    for (final item in resume.visibleCustomSections)
                      _monogramSidebarSection(
                        title: item.title.ifEmpty('Custom Section'),
                        child: pw.Text(item.content.trim()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayName(ResumeData resume) =>
      resume.fullName.trim().isEmpty ? 'Your Name' : resume.fullName.trim();

  String _resumeInitials(ResumeData resume) {
    final words = _displayName(
      resume,
    ).split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
    if (words.isEmpty) {
      return 'DA';
    }
    return words.map((part) => part[0].toUpperCase()).join();
  }

  List<String> _resumeContactItems(ResumeData resume) {
    return [
      resume.location.trim(),
      resume.email.trim(),
      resume.phone.trim(),
      resume.website.trim(),
      resume.githubLink.trim(),
      resume.linkedinLink.trim(),
    ].where((item) => item.isNotEmpty).toList();
  }

  List<String> _skillsForDisplay(ResumeData resume) {
    if (resume.skills.isNotEmpty) {
      return resume.skills;
    }
    return const ['Communication', 'Collaboration', 'Documentation'];
  }

  pw.Widget _corporateSection({
    required String title,
    required PdfColor lineColor,
    required pw.Widget child,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#50555C'),
            ),
          ),
          pw.SizedBox(height: 6),
          child,
          pw.SizedBox(height: 10),
          pw.Container(height: 1, color: lineColor),
        ],
      ),
    );
  }

  pw.Widget _minimalSection({
    required String title,
    required PdfColor lineColor,
    required pw.Widget child,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.Container(height: 1, color: lineColor)),
            ],
          ),
          pw.SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  pw.Widget _centeredAccentSection({
    required String title,
    required PdfColor accentColor,
    required PdfColor lineColor,
    required pw.Widget child,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(child: pw.Container(height: 1, color: lineColor)),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.Container(height: 1, color: lineColor)),
            ],
          ),
          pw.SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  pw.Widget _splitBannerSection({
    required String title,
    required PdfColor accentColor,
    required PdfColor lineColor,
    required pw.Widget child,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 78,
            padding: const pw.EdgeInsets.only(top: 2, right: 10),
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          pw.Container(width: 1, height: 42, color: lineColor),
          pw.SizedBox(width: 12),
          pw.Expanded(child: child),
        ],
      ),
    );
  }

  pw.Widget _creativeSection({
    required String title,
    required PdfColor lineColor,
    required pw.Widget child,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 104,
            padding: const pw.EdgeInsets.only(right: 12, top: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  height: 3,
                  width: 86,
                  color: PdfColor.fromHex('#353A40'),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                child,
                pw.SizedBox(height: 8),
                pw.Container(height: 1, color: lineColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _monogramSidebarSection({
    required String title,
    required pw.Widget child,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  pw.Widget _twoColumnBulletList(List<String> items) {
    final midpoint = (items.length / 2).ceil();
    final left = items.take(midpoint).toList();
    final right = items.skip(midpoint).toList();

    pw.Widget buildColumn(List<String> columnItems) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final item in columnItems)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('•  '),
                  pw.Expanded(child: pw.Text(item)),
                ],
              ),
            ),
        ],
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: buildColumn(left)),
        pw.SizedBox(width: 20),
        pw.Expanded(child: buildColumn(right)),
      ],
    );
  }

  pw.Widget _buildCorporateExperience(WorkExperience item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: item.role.ifEmpty('Role'),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text: ' / ${item.company.ifEmpty('Company')}',
                      ),
                    ],
                  ),
                ),
              ),
              if (item.startDate.trim().isNotEmpty ||
                  item.endDate.trim().isNotEmpty)
                pw.Text(
                  '${item.startDate.trim()}${item.startDate.trim().isNotEmpty && item.endDate.trim().isNotEmpty ? ' - ' : ''}${item.endDate.trim()}',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#666B71'),
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
            ],
          ),
          if (item.description.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(item.description.trim()),
          ],
          for (final bullet in item.bullets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('•  '),
                  pw.Expanded(child: pw.Text(bullet)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildMinimalExperience(WorkExperience item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.company.ifEmpty('Company'),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#4B4F55'),
            ),
          ),
          pw.Text(
            '${item.role.ifEmpty('Role')}${item.startDate.trim().isNotEmpty || item.endDate.trim().isNotEmpty ? '  ${item.startDate.trim()}${item.startDate.trim().isNotEmpty && item.endDate.trim().isNotEmpty ? ' - ' : ''}${item.endDate.trim()}' : ''}',
            style: pw.TextStyle(
              color: PdfColor.fromHex('#666B71'),
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          if (item.description.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(item.description.trim()),
          ],
          for (final bullet in item.bullets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('•  '),
                  pw.Expanded(child: pw.Text(bullet)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCreativeExperience(WorkExperience item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${item.role.ifEmpty('Role').toUpperCase()} ${item.startDate.trim().isNotEmpty || item.endDate.trim().isNotEmpty ? '${item.startDate.trim()}${item.startDate.trim().isNotEmpty && item.endDate.trim().isNotEmpty ? ' - ' : ''}${item.endDate.trim()}' : ''}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            item.company.ifEmpty('Company'),
            style: pw.TextStyle(
              color: PdfColor.fromHex('#555B61'),
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          if (item.description.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(item.description.trim()),
          ],
          for (final bullet in item.bullets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('•  '),
                  pw.Expanded(child: pw.Text(bullet)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCorporateEducation(EducationItem item) {
    final details = [
      item.institution.trim(),
      item.year.trim(),
      item.score.trim(),
      item.details.trim(),
    ].where((part) => part.isNotEmpty).join('  ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.degree.ifEmpty('Degree'),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (details.isNotEmpty) pw.Text(details),
        ],
      ),
    );
  }

  pw.Widget _buildCompactProject(ProjectItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.title.ifEmpty('Project'),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (item.overview.trim().isNotEmpty) pw.Text(item.overview.trim()),
          if (item.impact.trim().isNotEmpty) pw.Text(item.impact.trim()),
        ],
      ),
    );
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
