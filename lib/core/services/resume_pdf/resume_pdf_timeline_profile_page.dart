part of 'package:resume_app/core/services/resume_services.dart';

/// Timeline Profile: navy header band with a circular photo, a light sidebar
/// (contact, skills, short list sections) and a main column whose sections and
/// entries sit on a vertical timeline.
const double _timelineProfileSidebarWidthPt = 200.0;
const double _timelineProfileSidebarInsetPt = 22.0;
const double _timelineProfileBandHeightPt = 150.0;
const double _timelineProfileAvatarSizePt = 126.0;
const double _timelineProfileMainLeftPt = 230.0;
const double _timelineProfileMainRightPt = 36.0;
const double _timelineProfileTopPt = 36.0;
const double _timelineProfileBottomPt = 34.0;
const double _timelineProfileBadgeSizePt = 18.0;
const double _timelineProfileDotSizePt = 7.0;
const double _timelineProfileRuleX = _timelineProfileMainLeftPt + 9;

/// Custom sections that belong in the sidebar rather than the timeline.
final RegExp _timelineProfileSidebarSectionTitle = RegExp(
  r'^(languages?|references?|referees?|awards?|certifications?|certificates?|'
  r'interests?|hobbies)$',
  caseSensitive: false,
);

extension _ResumePdfTimelineProfilePage on ResumePdfService {
  void _addTimelineProfileTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final bandColor = _pdfRgb(resume.timelineProfileBandColor);
    final sidebarColor = _pdfRgb(resume.timelineProfileSidebarColor);
    final titleColor = _pdfRgb(resume.timelineProfileTitleColor);
    final mutedColor = _pdfRgb(resume.timelineProfileMutedColor);
    final ruleColor = _pdfRgb(resume.timelineProfileRuleColor);
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

    final nameStyle = style(
      ResumeFontWeight.w700,
      26,
      PdfColors.white,
      letterSpacing: 1.2,
    );
    final headerTitleStyle = style(
      ResumeFontWeight.w400,
      13,
      PdfColor.fromInt(0xFFC9D2DE),
      letterSpacing: 2,
    );
    final sectionTitleStyle = style(
      ResumeFontWeight.w700,
      14,
      titleColor,
      letterSpacing: 1.1,
    );
    final entryTitleStyle = style(ResumeFontWeight.w600, bodyPt, titleColor);
    final metaStyle = style(ResumeFontWeight.w400, detailPt, mutedColor);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final sidebarSections = resume.visibleCustomSections
        .where(
          (item) =>
              _timelineProfileSidebarSectionTitle.hasMatch(item.title.trim()),
        )
        .toList();
    final mainSections = resume.visibleCustomSections
        .where((item) => !sidebarSections.contains(item))
        .toList();

    pw.Widget sectionTitle(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: _timelineProfileBadgeSizePt,
            height: _timelineProfileBadgeSizePt,
            decoration: pw.BoxDecoration(
              color: bandColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 13),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title.toUpperCase(), style: sectionTitleStyle),
                pw.SizedBox(height: 4),
                pw.Container(height: 1, color: ruleColor),
              ],
            ),
          ),
        ],
      ),
    );

    /// Timeline row: a dot on the rule, then the content column.
    pw.Widget onTimeline(pw.Widget child, {bool dot = false}) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 5),
        pw.Container(
          width: _timelineProfileDotSizePt,
          height: _timelineProfileDotSizePt,
          margin: const pw.EdgeInsets.only(top: 4),
          decoration: pw.BoxDecoration(
            color: dot ? bandColor : PdfColors.white,
            shape: pw.BoxShape.circle,
            border: dot ? null : pw.Border.all(color: ruleColor, width: 0.8),
          ),
        ),
        pw.SizedBox(width: 13),
        pw.Expanded(child: child),
      ],
    );

    pw.Widget bullet(String text, {bool highlight = false}) =>
        _headerSidebarMaybeHighlight(
          highlight: highlight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: 10, child: pw.Text('•', style: bodyStyle)),
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

    List<pw.Widget> entry({
      required String title,
      required String dates,
      required String subtitle,
      required List<pw.Widget> details,
    }) {
      final head = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text(title, style: entryTitleStyle)),
              if (dates.isNotEmpty) ...[
                pw.SizedBox(width: 10),
                pw.Text(dates, style: metaStyle),
              ],
            ],
          ),
          if (subtitle.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(subtitle, style: bodyStyle),
            ),
          if (details.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: details.first,
            ),
        ],
      );
      return [
        onTimeline(head),
        for (final detail in details.skip(1))
          onTimeline(detail, dot: false),
        pw.SizedBox(height: 12),
      ];
    }

    pw.Widget sidebarPanel() {
      final headingStyle = style(
        ResumeFontWeight.w700,
        13,
        titleColor,
        letterSpacing: 1.1,
      );
      final itemStyle = style(ResumeFontWeight.w400, detailPt - 0.5, mutedColor);
      final strongItemStyle = style(
        ResumeFontWeight.w600,
        detailPt,
        titleColor,
      );

      pw.Widget heading(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 7),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title.toUpperCase(), style: headingStyle),
            pw.SizedBox(height: 4),
            pw.Container(height: 1, color: ruleColor),
          ],
        ),
      );

      // [shrink] keeps a long link on one line; plain text elsewhere so every
      // bullet keeps the same baseline.
      pw.Widget item(
        String text, {
        pw.TextStyle? textStyle,
        bool shrink = false,
      }) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        // Centred: a shrunk-to-fit link is shorter than a plain line, so a
        // fixed top margin would leave the dot sitting above its text.
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 4,
              height: 4,
              margin: const pw.EdgeInsets.only(right: 7),
              decoration: pw.BoxDecoration(
                color: bandColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: shrink
                  ? pw.FittedBox(
                      fit: pw.BoxFit.scaleDown,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(text, style: textStyle ?? itemStyle),
                    )
                  : pw.Text(text, style: textStyle ?? itemStyle),
            ),
          ],
        ),
      );

      final contacts = [
        resume.phone.trim(),
        resume.email.trim(),
        resume.location.trim(),
        resume.website.trim(),
        resume.linkedinLink.trim(),
        resume.githubLink.trim(),
      ].where((value) => value.isNotEmpty).toList();
      final skills = resume.skillsLinesForDisplay.take(10).toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (contacts.isNotEmpty) ...[
            heading('Contact'),
            for (final value in contacts) item(value, shrink: true),
          ],
          if (skills.isNotEmpty) ...[
            heading('Skills'),
            for (final skill in skills)
              _headerSidebarMaybeHighlight(
                highlight: highlightedSkills.contains(skill),
                child: item(skill),
              ),
          ],
          for (final section in sidebarSections) ...[
            heading(section.title.trim()),
            for (final line in _slateSidebarRailSectionLines(section))
              item(
                line,
                textStyle: line.endsWith(':') ? strongItemStyle : itemStyle,
              ),
          ],
        ],
      );
    }

    final sidebar = sidebarPanel();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _timelineProfileMainLeftPt,
            _timelineProfileTopPt,
            _timelineProfileMainRightPt,
            _timelineProfileBottomPt,
          ),
          buildBackground: (context) {
            final firstPage = context.pageNumber == 1;
            final sidebarTop = firstPage ? _timelineProfileBandHeightPt : 0.0;
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    left: 0,
                    top: sidebarTop,
                    bottom: 0,
                    child: pw.Container(
                      width: _timelineProfileSidebarWidthPt,
                      color: sidebarColor,
                    ),
                  ),
                  if (firstPage)
                    pw.Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: pw.Container(
                        height: _timelineProfileBandHeightPt,
                        color: bandColor,
                      ),
                    ),
                  // Timeline rule behind the section badges and entry dots.
                  pw.Positioned(
                    left: _timelineProfileRuleX,
                    top: firstPage
                        ? _timelineProfileBandHeightPt + 30
                        : _timelineProfileTopPt,
                    bottom: _timelineProfileBottomPt,
                    child: pw.Container(width: 1, color: ruleColor),
                  ),
                  if (firstPage) ...[
                    pw.Positioned(
                      left:
                          _timelineProfileSidebarWidthPt / 2 -
                          _timelineProfileAvatarSizePt / 2,
                      top:
                          _timelineProfileBandHeightPt -
                          _timelineProfileAvatarSizePt / 2 - 20,
                      child: pw.Container(
                        width: _timelineProfileAvatarSizePt,
                        height: _timelineProfileAvatarSizePt,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(
                            color: PdfColors.white,
                            width: 5,
                          ),
                        ),
                        child: profileImage != null
                            ? pw.ClipOval(
                                child: pw.Image(
                                  profileImage,
                                  fit: pw.BoxFit.cover,
                                ),
                              )
                            : pw.Container(
                                alignment: pw.Alignment.center,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColor.fromInt(0xFFD6DCE4),
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Text(
                                  _resumeInitials(resume),
                                  style: style(
                                    ResumeFontWeight.w700,
                                    32,
                                    titleColor,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    pw.Positioned(
                      left: _timelineProfileMainLeftPt,
                      right: _timelineProfileMainRightPt,
                      top: 52,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _displayName(resume).toUpperCase(),
                            style: nameStyle,
                          ),
                          if (resume.jobTitle.trim().isNotEmpty) ...[
                            pw.SizedBox(height: 6),
                            pw.Text(
                              resume.jobTitle.trim().toUpperCase(),
                              style: headerTitleStyle,
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.Positioned(
                      left: _timelineProfileSidebarInsetPt,
                      top:
                          _timelineProfileBandHeightPt +
                          _timelineProfileAvatarSizePt / 2 + 6,
                      bottom: _timelineProfileBottomPt,
                      child: pw.SizedBox(
                        width:
                            _timelineProfileSidebarWidthPt -
                            _timelineProfileSidebarInsetPt * 2,
                        child: pw.ClipRect(child: sidebar),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        build: (context) => [
          // Clear the header band on the first page.
          pw.SizedBox(height: _timelineProfileBandHeightPt - 40),
          if (resume.summary.trim().isNotEmpty) ...[
            sectionTitle('Profile'),
            onTimeline(
              _headerSidebarMaybeHighlight(
                highlight: highlightSummary,
                child: pw.Text(
                  resume.summary.trim(),
                  style: bodyStyle,
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
          ],
          ..._pdfBodySectionsInBuilderOrder(
            resume,
            exclude: {ResumeBuilderSectionIds.skills},
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
                  for (final widget in _pwCustomSectionBodyWidgets(
                    item,
                    garamond: fonts,
                    bodyFontPt: detailPt,
                    accentStripGaramondBody: true,
                  ))
                    onTimeline(widget),
                  pw.SizedBox(height: 6),
                ];
              }
              switch (id) {
                case ResumeBuilderSectionIds.work:
                  if (experiences.isEmpty) return null;
                  return [
                    sectionTitle('Work Experience'),
                    for (var i = 0; i < experiences.length; i++)
                      ...entry(
                        title: experiences[i].company.trim().ifEmpty('Company'),
                        dates: educationDateRangeLabel(
                          experiences[i].startDate,
                          experiences[i].endDate,
                        ).toUpperCase(),
                        subtitle: experiences[i].role.trim(),
                        details: [
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
                    for (final item in education)
                      ...entry(
                        title: item.degree.trim().ifEmpty(
                          item.institution.trim().ifEmpty('Education'),
                        ),
                        dates: educationDateRangeLabel(
                          item.startDate,
                          item.endDate,
                        ),
                        subtitle: item.institution.trim(),
                        details: [
                          if (item.score.trim().isNotEmpty)
                            pw.Text(item.score.trim(), style: entryTitleStyle),
                        ],
                      ),
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
                        details: [
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
