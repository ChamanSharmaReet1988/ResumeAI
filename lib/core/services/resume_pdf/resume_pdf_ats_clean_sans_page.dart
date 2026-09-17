part of 'package:resume_app/core/services/resume_services.dart';

/// Clean Sans ATS: uppercase name, right-aligned title and contact line under
/// a light rule, single-column sections with role/date rows, a two-column
/// education grid and two-column skill bullets.
const double _atsCleanSansHorizontalPt = 44.0;
const double _atsCleanSansTopPt = 40.0;
const double _atsCleanSansBottomPt = 36.0;
const PdfColor _atsCleanSansRuleColor = PdfColor.fromInt(0xFFE3E5E8);
const PdfColor _atsCleanSansBodyColor = PdfColor.fromInt(0xFF2B2B2B);

extension _ResumePdfAtsCleanSansPage on ResumePdfService {
  void _addAtsCleanSansTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _atsAccentPdf(resume);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final textPt = bodyPt - 1;

    pw.TextStyle style(
      int weight,
      double size, {
      PdfColor color = PdfColors.black,
      double? lineSpacing,
    }) => garamondPdfTextStyle(
      fonts,
      weight,
      fontSize: size,
      color: color,
      lineSpacing: lineSpacing,
    );

    final nameStyle = style(ResumeFontWeight.w700, 28);
    final jobTitleStyle = style(ResumeFontWeight.w600, 13);
    final sectionTitleStyle = style(ResumeFontWeight.w600, 14, color: accent);
    final strongStyle = style(ResumeFontWeight.w600, textPt + 0.5);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      textPt,
      color: _atsCleanSansBodyColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(textPt),
    );

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final customSections = resume.visibleCustomSections;
    final contact = [
      resume.email.trim(),
      resume.phone.trim(),
      resume.location.trim(),
      resume.website.trim(),
      resume.linkedinLink.trim(),
      resume.githubLink.trim(),
    ].where((item) => item.isNotEmpty).join(' | ');

    pw.Widget sectionTitle(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
      child: pw.Text(title.toUpperCase(), style: sectionTitleStyle),
    );

    pw.Widget bullet(String text, {bool highlight = false}) =>
        _headerSidebarMaybeHighlight(
          highlight: highlight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, top: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: 12, child: pw.Text('•', style: bodyStyle)),
                pw.Expanded(
                  child: pw.Text(
                    text,
                    style: bodyStyle,
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        );

    // Title (and dates) plus the first detail line travel together so a
    // heading is never stranded at the foot of a page.
    List<pw.Widget> entry({
      required String title,
      required String dates,
      required String subtitle,
      required List<pw.Widget> bullets,
    }) {
      final header = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text(title, style: strongStyle)),
              if (dates.isNotEmpty) ...[
                pw.SizedBox(width: 12),
                pw.Text(dates, style: strongStyle),
              ],
            ],
          ),
          if (subtitle.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(subtitle, style: bodyStyle),
            ),
          if (bullets.isNotEmpty) bullets.first,
        ],
      );
      return [
        header,
        ...bullets.skip(1),
        pw.SizedBox(height: 10),
      ];
    }

    List<pw.Widget> twoColumnRows<T>(
      List<T> items,
      pw.Widget Function(T item) build, {
      double rowGap = 10,
    }) => [
      for (var i = 0; i < items.length; i += 2)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: rowGap),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: build(items[i])),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: i + 1 < items.length
                    ? build(items[i + 1])
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),
    ];

    pw.Widget skillBullet(String skill) => _headerSidebarMaybeHighlight(
      highlight: highlightedSkills.contains(skill),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 12, child: pw.Text('•', style: bodyStyle)),
          pw.Expanded(child: pw.Text(skill, style: bodyStyle)),
        ],
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          _atsCleanSansHorizontalPt,
          _atsCleanSansTopPt,
          _atsCleanSansHorizontalPt,
          _atsCleanSansBottomPt,
        ),
        build: (context) => [
          pw.Text(_displayName(resume).toUpperCase(), style: nameStyle),
          if (resume.jobTitle.trim().isNotEmpty)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(resume.jobTitle.trim(), style: jobTitleStyle),
            ),
          pw.Container(
            height: 3,
            margin: const pw.EdgeInsets.only(top: 4, bottom: 6),
            color: _atsCleanSansRuleColor,
          ),
          if (contact.isNotEmpty)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                contact,
                style: bodyStyle,
                textAlign: pw.TextAlign.right,
              ),
            ),
          if (resume.summary.trim().isNotEmpty) ...[
            sectionTitle('Professional Summary'),
            _headerSidebarMaybeHighlight(
              highlight: highlightSummary,
              child: pw.Text(
                resume.summary.trim(),
                style: bodyStyle,
                textAlign: pw.TextAlign.justify,
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
                  sectionTitle(item.title.ifEmpty('Custom section')),
                  ..._pwCustomSectionBodyWidgets(
                    item,
                    garamond: fonts,
                    bodyFontPt: textPt,
                    accentStripGaramondBody: true,
                  ),
                ];
              }
              switch (id) {
                case ResumeBuilderSectionIds.work:
                  if (experiences.isEmpty) return null;
                  return [
                    sectionTitle('Work Experience'),
                    for (var i = 0; i < experiences.length; i++)
                      ...entry(
                        title: experiences[i].role.trim().ifEmpty('Role'),
                        dates: educationDateRangeLabel(
                          experiences[i].startDate,
                          experiences[i].endDate,
                        ),
                        subtitle: experiences[i].company.trim(),
                        bullets: [
                          for (final line in _workBulletLines(experiences[i]))
                            bullet(
                              line,
                              highlight:
                                  highlightedBulletsByExperience[i]?.contains(
                                    line,
                                  ) ??
                                  false,
                            ),
                        ],
                      ),
                  ];
                case ResumeBuilderSectionIds.education:
                  if (education.isEmpty) return null;
                  return [
                    sectionTitle('Education'),
                    ...twoColumnRows(
                      education,
                      (item) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.degree.trim().ifEmpty(
                              item.institution.trim().ifEmpty('Education'),
                            ),
                            style: strongStyle,
                          ),
                          if (item.institution.trim().isNotEmpty &&
                              item.degree.trim().isNotEmpty)
                            pw.Text(item.institution.trim(), style: bodyStyle),
                          if (item.score.trim().isNotEmpty)
                            skillBullet(item.score.trim()),
                          if (educationDateRangeLabel(
                            item.startDate,
                            item.endDate,
                          ).isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3),
                              child: pw.Text(
                                educationDateRangeLabel(
                                  item.startDate,
                                  item.endDate,
                                ),
                                style: strongStyle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ];
                case ResumeBuilderSectionIds.skills:
                  if (resume.showCategorisedSkills) {
                    final groups = resume.skillGroupsForResume;
                    if (groups.isEmpty) return null;
                    return [
                      sectionTitle('Skills'),
                      for (final group in groups) ...[
                        if (group.heading.trim().isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 3),
                            child: pw.Text(
                              group.heading.trim(),
                              style: strongStyle,
                            ),
                          ),
                        ...twoColumnRows(
                          group.skills
                              .map((skill) => skill.trim())
                              .where((skill) => skill.isNotEmpty)
                              .toList(),
                          skillBullet,
                          rowGap: 2,
                        ),
                        pw.SizedBox(height: 6),
                      ],
                    ];
                  }
                  final skills = resume.skillsLinesForDisplay;
                  if (skills.isEmpty) return null;
                  return [
                    sectionTitle('Skills'),
                    ...twoColumnRows(skills, skillBullet, rowGap: 2),
                  ];
                case ResumeBuilderSectionIds.projects:
                  if (projects.isEmpty) return null;
                  return [
                    sectionTitle('Projects'),
                    for (final item in projects)
                      ...entry(
                        title: item.title.trim().ifEmpty('Project'),
                        dates: '',
                        subtitle: item.subtitle.trim(),
                        bullets: [
                          for (final line in _projectBulletLinesPdf(item))
                            bullet(line),
                        ],
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
