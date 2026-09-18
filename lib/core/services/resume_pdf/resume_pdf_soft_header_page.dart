part of 'package:resume_app/core/services/resume_services.dart';

/// Soft Header: tinted header band with a centred nameplate, then two columns
/// split by a dotted divider — contact, education, skills and short lists on
/// the left, profile and experience on the right.
const double _softHeaderBandHeightPt = 150.0;
const double _softHeaderSidePt = 40.0;
const double _softHeaderLeftColumnWidthPt = 196.0;
const double _softHeaderDividerXPt =
    _softHeaderSidePt + _softHeaderLeftColumnWidthPt + 18;
const double _softHeaderMainLeftPt = _softHeaderDividerXPt + 24;
const double _softHeaderTopPt = 30.0;
const double _softHeaderBottomPt = 34.0;

/// Custom sections that read best in the left column.
final RegExp _softHeaderLeftSectionTitle = RegExp(
  r'^(languages?|references?|referees?|awards?|certifications?|certificates?|'
  r'interests?|hobbies)$',
  caseSensitive: false,
);

extension _ResumePdfSoftHeaderPage on ResumePdfService {
  void _addSoftHeaderTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final bandColor = _pdfRgb(resume.softHeaderBandColor);
    final accent = _pdfRgb(resume.softHeaderAccentColor);
    final titleColor = _pdfRgb(resume.softHeaderTitleColor);
    final mutedColor = _pdfRgb(resume.softHeaderMutedColor);
    final ruleColor = _pdfRgb(resume.softHeaderRuleColor);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final detailPt = bodyPt - 1.5;

    pw.TextStyle style(
      int weight,
      double size,
      PdfColor color, {
      double? lineSpacing,
      double? letterSpacing,
    }) => garamondPdfTextStyle(
      fonts,
      weight,
      fontSize: size,
      color: color,
      lineSpacing: lineSpacing,
    ).copyWith(letterSpacing: letterSpacing);

    final sectionTitleStyle = style(
      ResumeFontWeight.w700,
      15,
      titleColor,
      letterSpacing: 2.2,
    );
    final entryTitleStyle = style(ResumeFontWeight.w600, bodyPt, titleColor);
    final metaStyle = style(ResumeFontWeight.w400, detailPt, mutedColor);
    final strongMetaStyle = style(ResumeFontWeight.w600, detailPt, titleColor);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final leftSections = resume.visibleCustomSections
        .where((item) => _softHeaderLeftSectionTitle.hasMatch(item.title.trim()))
        .toList();
    final mainSections = resume.visibleCustomSections
        .where((item) => !leftSections.contains(item))
        .toList();

    /// Section title with a tinted circle behind its first letter.
    pw.Widget sectionTitle(String title) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 18, bottom: 10),
      child: pw.Stack(
        alignment: pw.Alignment.centerLeft,
        children: [
          pw.Container(
            width: 24,
            height: 24,
            margin: const pw.EdgeInsets.only(left: -4),
            decoration: pw.BoxDecoration(
              color: bandColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Text(title.toUpperCase(), style: sectionTitleStyle),
        ],
      ),
    );

    pw.Widget bullet(
      String text, {
      bool highlight = false,
      pw.TextStyle? textStyle,
      bool justify = false,
    }) => _headerSidebarMaybeHighlight(
      highlight: highlight,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 3,
              height: 3,
              margin: const pw.EdgeInsets.only(top: 5, right: 8),
              decoration: pw.BoxDecoration(
                color: mutedColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                text,
                style: textStyle ?? bodyStyle,
                textAlign: justify ? pw.TextAlign.justify : pw.TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );

    List<pw.Widget> experienceEntry(WorkExperience item, int index) => [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              item.company.trim().ifEmpty('Company'),
              style: entryTitleStyle,
            ),
          ),
          if (educationDateRangeLabel(
            item.startDate,
            item.endDate,
          ).isNotEmpty) ...[
            pw.SizedBox(width: 10),
            pw.Text(
              educationDateRangeLabel(
                item.startDate,
                item.endDate,
              ).toUpperCase(),
              style: metaStyle,
            ),
          ],
        ],
      ),
      if (item.role.trim().isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1),
          child: pw.Text(item.role.trim(), style: bodyStyle),
        ),
      pw.SizedBox(height: 5),
      for (final line in _workBulletLines(item))
        bullet(
          line,
          justify: true,
          highlight:
              highlightedBulletsByExperience[index]?.contains(line) ?? false,
        ),
      pw.SizedBox(height: 12),
    ];

    pw.Widget leftColumn() {
      final contacts = [
        resume.phone.trim(),
        resume.email.trim(),
        resume.location.trim(),
        resume.website.trim(),
        resume.linkedinLink.trim(),
        resume.githubLink.trim(),
      ].where((value) => value.isNotEmpty).toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (contacts.isNotEmpty) ...[
            sectionTitle('Contact'),
            for (final value in contacts)
              bullet(value, textStyle: metaStyle),
          ],
          if (education.isNotEmpty) ...[
            sectionTitle('Education'),
            for (final item in education) ...[
              if (educationDateRangeLabel(
                item.startDate,
                item.endDate,
              ).isNotEmpty)
                pw.Text(
                  educationDateRangeLabel(item.startDate, item.endDate),
                  style: strongMetaStyle,
                ),
              pw.Text(
                item.institution.trim().toUpperCase(),
                style: style(ResumeFontWeight.w700, detailPt, titleColor),
              ),
              pw.SizedBox(height: 3),
              if (item.degree.trim().isNotEmpty) bullet(item.degree.trim()),
              if (item.score.trim().isNotEmpty) bullet(item.score.trim()),
              pw.SizedBox(height: 9),
            ],
          ],
          if (resume.skillsLinesForDisplay.isNotEmpty) ...[
            sectionTitle('Skills'),
            for (final skill in resume.skillsLinesForDisplay.take(12))
              bullet(skill, highlight: highlightedSkills.contains(skill)),
          ],
          for (final section in leftSections) ...[
            sectionTitle(section.title.trim()),
            for (final line in _slateSidebarRailSectionLines(section))
              bullet(line),
          ],
        ],
      );
    }

    final left = leftColumn();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _softHeaderMainLeftPt,
            _softHeaderTopPt,
            _softHeaderSidePt,
            _softHeaderBottomPt,
          ),
          buildBackground: (context) {
            final firstPage = context.pageNumber == 1;
            final columnsTop = firstPage
                ? _softHeaderBandHeightPt + 16
                : _softHeaderTopPt;
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Stack(
                children: [
                  if (firstPage)
                    pw.Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: pw.Container(
                        height: _softHeaderBandHeightPt,
                        color: bandColor,
                        alignment: pw.Alignment.center,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.SizedBox(width: _softHeaderSidePt),
                            pw.Expanded(child: _softHeaderRule(accent)),
                            pw.SizedBox(width: 18),
                            pw.Column(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text(
                                  _displayName(resume).toUpperCase(),
                                  style: style(
                                    ResumeFontWeight.w700,
                                    26,
                                    titleColor,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                if (resume.jobTitle.trim().isNotEmpty) ...[
                                  pw.SizedBox(height: 6),
                                  pw.Text(
                                    resume.jobTitle.trim(),
                                    style: style(
                                      ResumeFontWeight.w400,
                                      14,
                                      mutedColor,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            pw.SizedBox(width: 18),
                            pw.Expanded(
                              child: _softHeaderRule(accent, mirrored: true),
                            ),
                            pw.SizedBox(width: _softHeaderSidePt),
                          ],
                        ),
                      ),
                    ),
                  // Divider between the columns, with a dot at the top.
                  pw.Positioned(
                    left: _softHeaderDividerXPt,
                    top: columnsTop,
                    bottom: _softHeaderBottomPt,
                    child: pw.Container(width: 0.8, color: ruleColor),
                  ),
                  pw.Positioned(
                    left: _softHeaderDividerXPt - 3,
                    top: columnsTop + 60,
                    child: pw.Container(
                      width: 7,
                      height: 7,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: accent, width: 1),
                      ),
                    ),
                  ),
                  if (firstPage)
                    pw.Positioned(
                      left: _softHeaderSidePt,
                      top: columnsTop,
                      bottom: _softHeaderBottomPt,
                      child: pw.SizedBox(
                        width: _softHeaderLeftColumnWidthPt,
                        child: pw.ClipRect(child: left),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        build: (context) => [
          pw.SizedBox(height: _softHeaderBandHeightPt - _softHeaderTopPt + 4),
          if (resume.summary.trim().isNotEmpty) ...[
            sectionTitle('Profile Summary'),
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
            exclude: {
              ResumeBuilderSectionIds.skills,
              ResumeBuilderSectionIds.education,
            },
            buildSection: (id) {
              final customIndex = ResumeBuilderSectionIds.customIndex(id);
              if (customIndex != null) {
                if (customIndex < 0 ||
                    customIndex >= resume.customSections.length) {
                  return null;
                }
                final item = resume.customSections[customIndex];
                if (!mainSections.contains(item)) return null;
                return [
                  sectionTitle(item.title.ifEmpty('Custom section')),
                  ..._pwCustomSectionBodyWidgets(
                    item,
                    garamond: fonts,
                    bodyFontPt: detailPt,
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
                      ...experienceEntry(experiences[i], i),
                  ];
                case ResumeBuilderSectionIds.projects:
                  if (projects.isEmpty) return null;
                  return [
                    sectionTitle('Projects'),
                    for (final item in projects) ...[
                      pw.Text(
                        item.title.trim().ifEmpty('Project'),
                        style: entryTitleStyle,
                      ),
                      if (item.subtitle.trim().isNotEmpty)
                        pw.Text(item.subtitle.trim(), style: bodyStyle),
                      pw.SizedBox(height: 5),
                      for (final line in _projectBulletLinesPdf(item))
                        bullet(line, justify: true),
                      pw.SizedBox(height: 12),
                    ],
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

/// Thin rule that ends in a small ring, as on both sides of the nameplate.
pw.Widget _softHeaderRule(PdfColor color, {bool mirrored = false}) {
  final ring = pw.Container(
    width: 7,
    height: 7,
    decoration: pw.BoxDecoration(
      shape: pw.BoxShape.circle,
      border: pw.Border.all(color: color, width: 1),
    ),
  );
  final line = pw.Expanded(child: pw.Container(height: 0.8, color: color));
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: mirrored ? [ring, line] : [line, ring],
  );
}
