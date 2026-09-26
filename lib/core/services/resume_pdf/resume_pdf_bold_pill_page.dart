part of 'package:resume_app/core/services/resume_services.dart';

/// Bold Pill: black photo header band, pill-shaped sidebar headings, a dotted
/// timeline down the main column, and a black footer bar.
const double _boldPillHeaderHeightPt = 168.0;
const double _boldPillSideWidthPt = 196.0;
const double _boldPillSideInsetPt = 34.0;
const double _boldPillTimelineXPt = 246.0;
const double _boldPillTimelineGapPt = 26.0;
const double _boldPillMainLeftPt =
    _boldPillTimelineXPt + _boldPillTimelineGapPt;
const double _boldPillMainRightPt = 44.0;
const double _boldPillPageTopPt = _boldPillHeaderHeightPt + 34.0;
const double _boldPillPageBottomPt = 56.0;
const double _boldPillAvatarPt = 118.0;
const double _boldPillFooterHeightPt = 26.0;
const double _boldPillTimelineDotPt = 11.0;

extension _ResumePdfBoldPillPage on ResumePdfService {
  void _addBoldPillTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _pdfRgb(resume.boldPillAccentColor);
    final onAccent = _pdfRgb(resume.boldPillOnAccentColor);
    final titleColor = _pdfRgb(resume.boldPillTitleColor);
    final mutedColor = _pdfRgb(resume.boldPillMutedColor);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final detailPt = bodyPt - 0.5;

    pw.TextStyle style(
      int weight,
      double size,
      PdfColor color, {
      double? lineSpacing,
    }) => garamondPdfTextStyle(
      fonts,
      weight,
      fontSize: size,
      color: color,
      lineSpacing: lineSpacing,
    );

    final nameStyle = style(ResumeFontWeight.w800, 27, onAccent);
    final jobStyle = style(ResumeFontWeight.w400, 14, onAccent);
    final pillStyle = style(ResumeFontWeight.w700, 12.5, onAccent);
    final sectionStyle = style(ResumeFontWeight.w800, 15, titleColor);
    final entryTitleStyle = style(ResumeFontWeight.w700, bodyPt, titleColor);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );
    final sideItemStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      titleColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );

    /// Black rounded heading used down the left column.
    pw.Widget pill(String label) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 22, bottom: 10),
      child: pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(16, 6, 16, 7),
        decoration: pw.BoxDecoration(
          color: accent,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Text(label.toUpperCase(), style: pillStyle),
      ),
    );

    pw.Widget bulletLine(String text, pw.TextStyle textStyle) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('•  ', style: textStyle),
          pw.Expanded(child: pw.Text(text, style: textStyle)),
        ],
      ),
    );

    /// Main-column heading: a filled dot on the timeline rule, then the title.
    pw.Widget timelineHeading(String label) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: _boldPillTimelineDotPt,
            height: _boldPillTimelineDotPt,
            margin: const pw.EdgeInsets.only(
              left:
                  -_boldPillTimelineGapPt - _boldPillTimelineDotPt / 2 - 0.75,
              right: _boldPillTimelineGapPt - _boldPillTimelineDotPt / 2 + 1,
            ),
            decoration: pw.BoxDecoration(
              color: accent,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Text(label.toUpperCase(), style: sectionStyle),
        ],
      ),
    );

    final contacts = <(_MinimalProfileIcon, String)>[
      if (resume.phone.trim().isNotEmpty)
        (_MinimalProfileIcon.phone, resume.phone.trim()),
      if (resume.website.trim().isNotEmpty)
        (_MinimalProfileIcon.web, resume.website.trim()),
      if (resume.email.trim().isNotEmpty)
        (_MinimalProfileIcon.mail, resume.email.trim()),
      if (resume.location.trim().isNotEmpty)
        (_MinimalProfileIcon.place, resume.location.trim()),
      if (resume.linkedinLink.trim().isNotEmpty)
        (_MinimalProfileIcon.web, resume.linkedinLink.trim()),
    ];

    final sideSections = resume.customSections
        .where((item) => !item.isBlank && _slateSidebarIsRailSection(item))
        .toList();
    final mainCustomSections = resume.customSections
        .where((item) => !sideSections.contains(item))
        .toSet();
    final skills = resume.skillsLinesForDisplay;

    final side = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (contacts.isNotEmpty) ...[
          pill('Contact'),
          for (final (icon, value) in contacts)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 13,
                    height: 13,
                    margin: const pw.EdgeInsets.only(top: 1),
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: accent,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.SizedBox(
                      width: 7,
                      height: 7,
                      child: pw.CustomPaint(
                        painter: (canvas, size) => _paintMinimalProfileIcon(
                          canvas,
                          size,
                          icon,
                          onAccent,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(value, style: sideItemStyle)),
                ],
              ),
            ),
        ],
        if (skills.isNotEmpty) ...[
          pill('Skills'),
          for (final skill in skills)
            _headerSidebarMaybeHighlight(
              highlight: highlightedSkills.contains(skill),
              child: bulletLine(skill, sideItemStyle),
            ),
        ],
        for (final section in sideSections) ...[
          pill(section.title.trim()),
          for (final line in _slateSidebarRailSectionLines(section))
            bulletLine(line, sideItemStyle),
        ],
      ],
    );

    final summary = resume.summary.trim();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _boldPillMainLeftPt,
            _boldPillPageTopPt,
            _boldPillMainRightPt,
            _boldPillPageBottomPt,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                if (context.pageNumber == 1) ...[
                  pw.Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: pw.Container(
                      height: _boldPillHeaderHeightPt,
                      decoration: pw.BoxDecoration(
                        color: accent,
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(26),
                          bottomRight: pw.Radius.circular(26),
                        ),
                      ),
                      padding: const pw.EdgeInsets.fromLTRB(44, 0, 44, 0),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: _boldPillAvatarPt,
                            height: _boldPillAvatarPt,
                            decoration: pw.BoxDecoration(
                              color: _pdfMix(accent, PdfColors.white, 0.75),
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(
                                color: onAccent,
                                width: 2.5,
                              ),
                            ),
                            alignment: pw.Alignment.center,
                            child: profileImage != null
                                ? pw.ClipOval(
                                    child: pw.SizedBox(
                                      width: _boldPillAvatarPt,
                                      height: _boldPillAvatarPt,
                                      child: pw.Image(
                                        profileImage,
                                        fit: pw.BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : pw.Text(
                                    _resumeInitials(resume),
                                    style: style(
                                      ResumeFontWeight.w700,
                                      28,
                                      accent,
                                    ),
                                  ),
                          ),
                          pw.SizedBox(width: 26),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  _displayName(resume).toUpperCase(),
                                  style: nameStyle,
                                ),
                                if (resume.jobTitle.trim().isNotEmpty) ...[
                                  pw.SizedBox(height: 5),
                                  pw.Text(
                                    resume.jobTitle.trim(),
                                    style: jobStyle,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Positioned(
                    left: _boldPillSideInsetPt,
                    top: _boldPillPageTopPt,
                    bottom: _boldPillPageBottomPt + _boldPillFooterHeightPt,
                    child: pw.SizedBox(
                      width: _boldPillSideWidthPt - _boldPillSideInsetPt,
                      child: pw.ClipRect(child: side),
                    ),
                  ),
                ],
                // Timeline rule behind the main column headings.
                pw.Positioned(
                  left: _boldPillTimelineXPt,
                  top: context.pageNumber == 1
                      ? _boldPillHeaderHeightPt + 40
                      : _boldPillPageTopPt,
                  bottom: _boldPillPageBottomPt + _boldPillFooterHeightPt,
                  child: pw.Container(width: 1.5, color: accent),
                ),
                pw.Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: pw.Container(
                    height: _boldPillFooterHeightPt,
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(26),
                        topRight: pw.Radius.circular(26),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        build: (context) => [
          if (summary.isNotEmpty) ...[
            timelineHeading('About Me'),
            _headerSidebarMaybeHighlight(
              highlight: highlightSummary,
              child: pw.Text(
                summary,
                style: bodyStyle,
                textAlign: pw.TextAlign.justify,
              ),
            ),
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
                if (!mainCustomSections.contains(item)) return null;
                return [
                  timelineHeading(item.title.ifEmpty('Custom section')),
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
                  final items = resume.visibleWorkExperiences;
                  if (items.isEmpty) return null;
                  return [
                    timelineHeading('Work Experience'),
                    for (var i = 0; i < items.length; i++)
                      _headerSidebarMaybeHighlight(
                        highlight:
                            highlightedBulletsByExperience[i]?.isNotEmpty ??
                            false,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      items[i].role.trim().ifEmpty('Role'),
                                      style: entryTitleStyle,
                                    ),
                                  ),
                                  pw.SizedBox(width: 10),
                                  pw.Text(
                                    educationDateRangeLabel(
                                      items[i].startDate,
                                      items[i].endDate,
                                    ),
                                    style: entryTitleStyle,
                                  ),
                                ],
                              ),
                              if (items[i].company.trim().isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  items[i].company.trim(),
                                  style: bodyStyle,
                                ),
                              ],
                              pw.SizedBox(height: 4),
                              for (final line in _workBulletLines(items[i]))
                                bulletLine(line, bodyStyle),
                            ],
                          ),
                        ),
                      ),
                  ];
                case ResumeBuilderSectionIds.education:
                  final items = resume.visibleEducation;
                  if (items.isEmpty) return null;
                  return [
                    timelineHeading('Education'),
                    for (final item in items)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    item.institution.trim().ifEmpty(
                                      'Institution',
                                    ),
                                    style: entryTitleStyle,
                                  ),
                                  if (item.degree.trim().isNotEmpty)
                                    pw.Text(
                                      item.degree.trim(),
                                      style: bodyStyle,
                                    ),
                                  if (educationScoreDisplayLabel(
                                    item,
                                  ).isNotEmpty)
                                    pw.Text(
                                      educationScoreDisplayLabel(item),
                                      style: bodyStyle,
                                    ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Text(
                              educationDateRangeLabel(
                                item.startDate,
                                item.endDate,
                              ),
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ),
                  ];
                case ResumeBuilderSectionIds.projects:
                  final items = resume.visibleProjects;
                  if (items.isEmpty) return null;
                  return [
                    timelineHeading('Projects'),
                    for (final item in items)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.title.trim().ifEmpty('Project'),
                              style: entryTitleStyle,
                            ),
                            if (item.subtitle.trim().isNotEmpty)
                              pw.Text(item.subtitle.trim(), style: bodyStyle),
                            for (final line in [
                              item.overview.trim(),
                              item.impact.trim(),
                              ...item.bullets.map((bullet) => bullet.trim()),
                            ].where((line) => line.isNotEmpty))
                              bulletLine(line, bodyStyle),
                          ],
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
