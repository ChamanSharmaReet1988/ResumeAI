part of 'package:resume_app/core/services/resume_services.dart';

/// Shared single-column ATS body for the four Best Pick templates. Page chrome
/// (stripe, header band, rules) is decorative; all copy stays real text.
const PdfColor _topPickBodyColor = PdfColor.fromInt(0xFF2B2B2B);

PdfColor _topPickWash(PdfColor accent, [double amount = 0.12]) => PdfColor(
  accent.red * amount + (1 - amount),
  accent.green * amount + (1 - amount),
  accent.blue * amount + (1 - amount),
);

extension _ResumePdfTopPickPages on ResumePdfService {
  void _addTopPickAtsTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final kind = resume.template;
    final accent = _atsAccentPdf(resume);
    final wash = _topPickWash(accent);
    final softWash = _topPickWash(accent, 0.07);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final textPt = bodyPt;

    pw.TextStyle style(
      int weight,
      double size, {
      PdfColor color = PdfColors.black,
      double? lineSpacing,
      double letterSpacing = 0,
    }) {
      final base = garamondPdfTextStyle(
        fonts,
        weight,
        fontSize: size,
        color: color,
        lineSpacing: lineSpacing,
      );
      return letterSpacing == 0
          ? base
          : base.copyWith(letterSpacing: letterSpacing);
    }

    final strongStyle = style(ResumeFontWeight.w600, textPt + 0.5);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      textPt,
      color: _topPickBodyColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(textPt),
    );

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final customSections = resume.visibleCustomSections;
    final contactParts = [
      resume.email.trim(),
      resume.phone.trim(),
      resume.location.trim(),
      resume.website.trim(),
      resume.linkedinLink.trim(),
      resume.githubLink.trim(),
    ].where((item) => item.isNotEmpty).toList();
    final name = _displayName(resume);
    final title = resume.jobTitle.trim();

    pw.PageTheme pageTheme() {
      switch (kind) {
        case ResumeTemplate.modernLine:
          return pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(52, 36, 40, 36),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(width: 8, color: accent),
                  pw.Expanded(child: pw.SizedBox()),
                ],
              ),
            ),
          );
        case ResumeTemplate.typeplate:
          return pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(50, 36, 40, 36),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(width: 6, color: accent),
                  pw.Expanded(child: pw.SizedBox()),
                ],
              ),
            ),
          );
        case ResumeTemplate.splitContact:
          return const pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.fromLTRB(0, 0, 0, 36),
          );
        case ResumeTemplate.harbor:
          return pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(0, 0, 0, 36),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 7,
                    width: double.infinity,
                    color: accent,
                  ),
                  pw.Expanded(child: pw.SizedBox()),
                ],
              ),
            ),
          );
        default:
          return const pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.fromLTRB(44, 40, 44, 36),
          );
      }
    }

    pw.Widget sectionTitle(String heading) {
      switch (kind) {
        case ResumeTemplate.modernLine:
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  heading,
                  style: style(ResumeFontWeight.w700, 13, color: accent),
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Container(width: 42, height: 3, color: accent),
                    pw.Expanded(child: pw.Container(height: 1, color: wash)),
                  ],
                ),
              ],
            ),
          );
        case ResumeTemplate.splitContact:
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  heading.toUpperCase(),
                  style: style(
                    ResumeFontWeight.w700,
                    11,
                    color: accent,
                    letterSpacing: 1.4,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Container(height: 1.2, color: accent),
              ],
            ),
          );
        case ResumeTemplate.harbor:
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 7,
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: accent,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(heading, style: style(ResumeFontWeight.w700, 13)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: pw.Container(height: 1, color: accent)),
              ],
            ),
          );
        case ResumeTemplate.typeplate:
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 5, height: 16, color: accent),
                pw.SizedBox(width: 8),
                pw.Text(
                  heading.toUpperCase(),
                  style: style(
                    ResumeFontWeight.w700,
                    11,
                    letterSpacing: 1.6,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    height: 1,
                    color: const PdfColor.fromInt(0xFFD6D6D6),
                  ),
                ),
              ],
            ),
          );
        default:
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
            child: pw.Text(heading, style: style(ResumeFontWeight.w600, 13)),
          );
      }
    }

    List<pw.Widget> header() {
      switch (kind) {
        case ResumeTemplate.modernLine:
          return [
            pw.Text(name, style: style(ResumeFontWeight.w700, 28)),
            if (title.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  title,
                  style: style(ResumeFontWeight.w600, 13, color: accent),
                ),
              ),
            if (contactParts.isNotEmpty)
              pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(top: 12),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: wash,
                child: pw.Text(contactParts.join('  ·  '), style: bodyStyle),
              ),
          ];
        case ResumeTemplate.splitContact:
          return [
            pw.Container(
              color: wash,
              padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 16),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(name, style: style(ResumeFontWeight.w700, 26)),
                        if (title.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 5),
                            child: pw.Text(
                              title,
                              style: style(
                                ResumeFontWeight.w600,
                                12,
                                color: accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (contactParts.isNotEmpty)
                    pw.SizedBox(
                      width: 200,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          for (final part in contactParts)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Text(
                                part,
                                style: bodyStyle,
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            pw.Container(height: 5, color: accent),
            pw.SizedBox(height: 18),
          ];
        case ResumeTemplate.harbor:
          return [
            pw.Container(height: 7, width: double.infinity, color: accent),
            pw.Container(
              width: double.infinity,
              color: softWash,
              padding: const pw.EdgeInsets.fromLTRB(36, 34, 36, 20),
              child: pw.Column(
                children: [
                  pw.Container(width: 48, height: 3, color: accent),
                  pw.SizedBox(height: 12),
                  pw.Center(
                    child: pw.Text(
                      name,
                      style: style(ResumeFontWeight.w700, 26),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  if (title.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 5),
                      child: pw.Center(
                        child: pw.Text(
                          title,
                          style: style(
                            ResumeFontWeight.w600,
                            12,
                            color: accent,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  if (contactParts.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Container(width: 28, height: 1, color: accent),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text(
                        contactParts.join('  ·  '),
                        style: bodyStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ];
        case ResumeTemplate.typeplate:
          return [
            pw.Text(name, style: style(ResumeFontWeight.w700, 32)),
            pw.Container(
              width: 72,
              height: 5,
              margin: const pw.EdgeInsets.only(top: 8, bottom: 10),
              color: accent,
            ),
            if (title.isNotEmpty)
              pw.Text(
                title,
                style: style(ResumeFontWeight.w600, 12, color: accent),
              ),
            if (contactParts.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(contactParts.join('  ·  '), style: bodyStyle),
              ),
          ];
        default:
          return [pw.Text(name, style: style(ResumeFontWeight.w700, 24))];
      }
    }

    pw.Widget dateLabel(String dates) {
      if (dates.isEmpty) return pw.SizedBox();
      if (kind == ResumeTemplate.splitContact ||
          kind == ResumeTemplate.typeplate) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          color: wash,
          child: pw.Text(
            dates,
            style: style(ResumeFontWeight.w600, textPt, color: accent),
          ),
        );
      }
      return pw.Text(
        dates,
        style: style(ResumeFontWeight.w600, textPt, color: accent),
      );
    }

    pw.Widget inset(pw.Widget child) {
      if (kind == ResumeTemplate.splitContact ||
          kind == ResumeTemplate.harbor) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 40),
          child: child,
        );
      }
      return child;
    }

    pw.Widget bullet(String text, {bool highlight = false}) =>
        _headerSidebarMaybeHighlight(
          highlight: highlight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: 12, child: pw.Text('•', style: bodyStyle)),
                pw.Expanded(child: pw.Text(text, style: bodyStyle)),
              ],
            ),
          ),
        );

    List<pw.Widget> entry({
      required String title,
      required String dates,
      required String subtitle,
      required List<pw.Widget> bullets,
    }) {
      final useCompanyFirst = kind == ResumeTemplate.typeplate;
      final first = useCompanyFirst && subtitle.isNotEmpty ? subtitle : title;
      final second = useCompanyFirst && subtitle.isNotEmpty ? title : subtitle;
      final header = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text(first, style: strongStyle)),
              if (dates.isNotEmpty) ...[
                pw.SizedBox(width: 12),
                dateLabel(dates),
              ],
            ],
          ),
          if (second.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(second, style: bodyStyle),
            ),
          if (bullets.isNotEmpty) bullets.first,
        ],
      );
      return [header, ...bullets.skip(1), pw.SizedBox(height: 10)];
    }

    document.addPage(
      pw.MultiPage(
        pageTheme: pageTheme(),
        build: (context) => [
          ...header(),
          if (resume.summary.trim().isNotEmpty) ...[
            inset(sectionTitle('Professional Summary')),
            inset(
              _headerSidebarMaybeHighlight(
                highlight: highlightSummary,
                child: pw.Text(resume.summary.trim(), style: bodyStyle),
              ),
            ),
          ],
          ..._pdfBodySectionsInBuilderOrder(
            resume,
            buildSection: (id) {
              final customIndex = ResumeBuilderSectionIds.customIndex(id);
              if (customIndex != null) {
                if (customIndex < 0 ||
                    customIndex >= resume.customSections.length) {
                  return null;
                }
                final item = resume.customSections[customIndex];
                if (!customSections.contains(item)) return null;
                return [
                  inset(sectionTitle(item.title.ifEmpty('Custom section'))),
                  inset(
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: _pwCustomSectionBodyWidgets(
                        item,
                        garamond: fonts,
                        bodyFontPt: textPt,
                        accentStripGaramondBody: true,
                        experienceEntry: (items) => [
                          for (final work in items)
                            ...entry(
                              title: work.role.trim().ifEmpty('Role'),
                              dates: educationDateRangeLabel(
                                work.startDate,
                                work.endDate,
                              ),
                              subtitle: work.company.trim(),
                              bullets: [
                                for (final line in _workBulletLines(work))
                                  bullet(line),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ];
              }
              switch (id) {
                case ResumeBuilderSectionIds.work:
                  if (experiences.isEmpty) return null;
                  return [
                    inset(
                      sectionTitle(
                        resume.sectionHeading(
                          ResumeBuilderSectionIds.work,
                          'Work Experience',
                        ),
                      ),
                    ),
                    for (var i = 0; i < experiences.length; i++)
                      inset(
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: entry(
                            title: experiences[i].role.trim().ifEmpty('Role'),
                            dates: educationDateRangeLabel(
                              experiences[i].startDate,
                              experiences[i].endDate,
                            ),
                            subtitle: experiences[i].company.trim(),
                            bullets: [
                              for (final line
                                  in _workBulletLines(experiences[i]))
                                bullet(
                                  line,
                                  highlight:
                                      highlightedBulletsByExperience[i]
                                          ?.contains(line) ??
                                      false,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ];
                case ResumeBuilderSectionIds.education:
                  if (education.isEmpty) return null;
                  return [
                    inset(
                      sectionTitle(
                        resume.sectionHeading(
                          ResumeBuilderSectionIds.education,
                          'Education',
                        ),
                      ),
                    ),
                    for (final item in education)
                      inset(
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: entry(
                            title: item.degree.trim().ifEmpty(
                              item.institution.trim().ifEmpty('Education'),
                            ),
                            dates: educationDateRangeLabel(
                              item.startDate,
                              item.endDate,
                            ),
                            subtitle:
                                item.institution.trim().isNotEmpty &&
                                    item.degree.trim().isNotEmpty
                                ? item.institution.trim()
                                : '',
                            bullets: [
                              if (educationDetailLine(item).isNotEmpty)
                                bullet(educationDetailLine(item)),
                            ],
                          ),
                        ),
                      ),
                  ];
                case ResumeBuilderSectionIds.skills:
                  final skills = resume.skillsLinesForDisplay;
                  if (skills.isEmpty) return null;
                  return [
                    inset(
                      sectionTitle(
                        resume.sectionHeading(
                          ResumeBuilderSectionIds.skills,
                          'Skills',
                        ),
                      ),
                    ),
                    ..._pdfPaginatedSkillLines(
                      skills: skills,
                      style: bodyStyle,
                      highlightedSkills: highlightedSkills,
                    ).map(inset),
                  ];
                case ResumeBuilderSectionIds.projects:
                  if (projects.isEmpty) return null;
                  return [
                    inset(
                      sectionTitle(
                        resume.sectionHeading(
                          ResumeBuilderSectionIds.projects,
                          'Projects',
                        ),
                      ),
                    ),
                    for (final item in projects)
                      inset(
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: entry(
                            title: item.title.trim().ifEmpty('Project'),
                            dates: '',
                            subtitle: item.subtitle.trim(),
                            bullets: [
                              for (final line in _projectBulletLinesPdf(item))
                                bullet(line),
                            ],
                          ),
                        ),
                      ),
                  ];
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
