part of 'package:resume_app/core/services/resume_services.dart';

/// Blue Corner: a blue wedge in the top-left behind a circular photo, a light
/// contact sidebar, and dotted timeline education and experience entries.
const double _blueCornerSideWidthPt = 214.0;
const double _blueCornerSideInsetPt = 34.0;
const double _blueCornerWedgePt = 250.0;
const double _blueCornerAvatarPt = 138.0;
const double _blueCornerHeaderBottomPt = 300.0;
const double _blueCornerMainLeftPt = 258.0;
const double _blueCornerMainRightPt = 42.0;
const double _blueCornerPageTopPt = 46.0;
const double _blueCornerPageBottomPt = 42.0;
const double _blueCornerTimelineDotPt = 8.0;

extension _ResumePdfBlueCornerPage on ResumePdfService {
  void _addBlueCornerTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _pdfRgb(resume.blueCornerAccentColor);
    final titleColor = _pdfRgb(resume.blueCornerTitleColor);
    final mutedColor = _pdfRgb(resume.blueCornerMutedColor);
    final ruleColor = _pdfRgb(resume.blueCornerRuleColor);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final detailPt = bodyPt - 1;

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

    final nameStyle = style(ResumeFontWeight.w400, 30, accent);
    final jobStyle = style(ResumeFontWeight.w400, 13, mutedColor);
    final sectionStyle = style(ResumeFontWeight.w600, 15, titleColor);
    final entryTitleStyle = style(ResumeFontWeight.w600, bodyPt, titleColor);
    final entrySubStyle = garamondPdfTextStyle(
      fonts,
      ResumeFontWeight.w400,
      fontSize: detailPt,
      color: mutedColor,
      fontStyle: pw.FontStyle.italic,
    );
    final bodyStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );

    /// Section heading: icon, label, then a rule that runs to the edge.
    pw.Widget sectionHeading(
      String label, {
      _MinimalProfileIcon? icon,
      bool rule = true,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                pw.SizedBox(
                  width: 13,
                  height: 13,
                  child: pw.CustomPaint(
                    painter: (canvas, size) => _paintMinimalProfileIcon(
                      canvas,
                      size,
                      icon,
                      titleColor,
                    ),
                  ),
                ),
                pw.SizedBox(width: 9),
              ],
              pw.Text(label, style: sectionStyle),
            ],
          ),
          if (rule) ...[
            pw.SizedBox(height: 6),
            pw.Container(height: 1, color: ruleColor),
          ],
        ],
      ),
    );

    /// Timeline entry: dot on the rule, title, italic organisation, dates on
    /// the right, then the detail lines.
    pw.Widget timelineEntry({
      required String title,
      required String organisation,
      required String dates,
      required List<String> details,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: _blueCornerTimelineDotPt,
            height: _blueCornerTimelineDotPt,
            margin: const pw.EdgeInsets.only(top: 3, right: 12),
            decoration: pw.BoxDecoration(
              color: accent,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: pw.Text(title, style: entryTitleStyle)),
                    if (dates.isNotEmpty) ...[
                      pw.SizedBox(width: 10),
                      pw.Text(dates, style: bodyStyle),
                    ],
                  ],
                ),
                if (organisation.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(organisation, style: entrySubStyle),
                ],
                for (final line in details) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    line,
                    style: bodyStyle,
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final contacts = <(_MinimalProfileIcon, String)>[
      if (resume.phone.trim().isNotEmpty)
        (_MinimalProfileIcon.phone, resume.phone.trim()),
      if (resume.email.trim().isNotEmpty)
        (_MinimalProfileIcon.mail, resume.email.trim()),
      if (resume.location.trim().isNotEmpty)
        (_MinimalProfileIcon.place, resume.location.trim()),
      if (resume.website.trim().isNotEmpty)
        (_MinimalProfileIcon.web, resume.website.trim()),
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
    final summary = resume.summary.trim();

    final side = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (contacts.isNotEmpty) ...[
          sectionHeading('Contact', icon: _MinimalProfileIcon.phone),
          for (final (icon, value) in contacts)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 11,
                    height: 11,
                    child: pw.CustomPaint(
                      painter: (canvas, size) =>
                          _paintMinimalProfileIcon(canvas, size, icon, accent),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(value, style: bodyStyle)),
                ],
              ),
            ),
        ],
        if (summary.isNotEmpty) ...[
          sectionHeading('About Me', icon: _MinimalProfileIcon.person),
          _headerSidebarMaybeHighlight(
            highlight: highlightSummary,
            child: pw.Text(
              summary,
              style: bodyStyle,
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
        if (skills.isNotEmpty) ...[
          sectionHeading('Skills', icon: _MinimalProfileIcon.puzzle),
          for (final skill in skills)
            _headerSidebarMaybeHighlight(
              highlight: highlightedSkills.contains(skill),
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ', style: bodyStyle),
                    pw.Expanded(child: pw.Text(skill, style: bodyStyle)),
                  ],
                ),
              ),
            ),
        ],
        for (final section in sideSections) ...[
          sectionHeading(section.title.trim()),
          for (final line in _slateSidebarRailSectionLines(section))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('•  ', style: bodyStyle),
                  pw.Expanded(child: pw.Text(line, style: bodyStyle)),
                ],
              ),
            ),
        ],
      ],
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _blueCornerMainLeftPt,
            _blueCornerPageTopPt,
            _blueCornerMainRightPt,
            _blueCornerPageBottomPt,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                if (context.pageNumber == 1) ...[
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    child: pw.SizedBox(
                      width: _blueCornerWedgePt,
                      height: _blueCornerWedgePt,
                      child: pw.CustomPaint(
                        painter: (canvas, size) {
                          canvas
                            ..setFillColor(accent)
                            ..moveTo(0, size.y)
                            ..lineTo(size.x, size.y)
                            ..lineTo(0, 0)
                            ..closePath()
                            ..fillPath();
                        },
                      ),
                    ),
                  ),
                  pw.Positioned(
                    left:
                        _blueCornerSideWidthPt / 2 - _blueCornerAvatarPt / 2,
                    top: 56,
                    child: pw.Container(
                      width: _blueCornerAvatarPt,
                      height: _blueCornerAvatarPt,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.white, width: 5),
                      ),
                      alignment: pw.Alignment.center,
                      child: profileImage != null
                          ? pw.ClipOval(
                              child: pw.SizedBox(
                                width: _blueCornerAvatarPt,
                                height: _blueCornerAvatarPt,
                                child: pw.Image(
                                  profileImage,
                                  fit: pw.BoxFit.cover,
                                ),
                              ),
                            )
                          : pw.Text(
                              _resumeInitials(resume),
                              style: style(ResumeFontWeight.w700, 30, accent),
                            ),
                    ),
                  ),
                  pw.Positioned(
                    left: _blueCornerSideInsetPt,
                    top: _blueCornerAvatarPt + 72,
                    child: pw.SizedBox(
                      width: _blueCornerSideWidthPt - _blueCornerSideInsetPt * 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_displayName(resume), style: nameStyle),
                          if (resume.jobTitle.trim().isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            pw.Text(resume.jobTitle.trim(), style: jobStyle),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.Positioned(
                    left: _blueCornerSideInsetPt,
                    top: _blueCornerHeaderBottomPt,
                    bottom: _blueCornerPageBottomPt,
                    child: pw.SizedBox(
                      width: _blueCornerSideWidthPt - _blueCornerSideInsetPt * 2,
                      child: pw.ClipRect(child: side),
                    ),
                  ),
                ],
                // Timeline rule the entry dots sit on.
                pw.Positioned(
                  left: _blueCornerMainLeftPt + _blueCornerTimelineDotPt / 2,
                  top: _blueCornerPageTopPt + 40,
                  bottom: _blueCornerPageBottomPt,
                  child: pw.Container(width: 1, color: ruleColor),
                ),
              ],
            ),
          ),
        ),
        build: (context) => [
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
                  sectionHeading(item.title.ifEmpty('Custom section')),
                  ..._pwCustomSectionBodyWidgets(
                    item,
                    garamond: fonts,
                    bodyFontPt: detailPt,
                    accentStripGaramondBody: true,
                  ),
                ];
              }
              switch (id) {
                case ResumeBuilderSectionIds.education:
                  final items = resume.visibleEducation;
                  if (items.isEmpty) return null;
                  return [
                    sectionHeading(
                      'Education',
                      icon: _MinimalProfileIcon.school,
                    ),
                    for (final item in items)
                      timelineEntry(
                        title: item.degree.trim().ifEmpty('Degree'),
                        organisation: item.institution.trim(),
                        dates: educationDateRangeLabel(
                          item.startDate,
                          item.endDate,
                        ),
                        details: [
                          if (educationScoreDisplayLabel(item).isNotEmpty)
                            educationScoreDisplayLabel(item),
                        ],
                      ),
                  ];
                case ResumeBuilderSectionIds.work:
                  final items = resume.visibleWorkExperiences;
                  if (items.isEmpty) return null;
                  return [
                    sectionHeading(
                      'Experience',
                      icon: _MinimalProfileIcon.work,
                    ),
                    for (var i = 0; i < items.length; i++)
                      _headerSidebarMaybeHighlight(
                        highlight:
                            highlightedBulletsByExperience[i]?.isNotEmpty ??
                            false,
                        child: timelineEntry(
                          title: items[i].role.trim().ifEmpty('Role'),
                          organisation: items[i].company.trim(),
                          dates: educationDateRangeLabel(
                            items[i].startDate,
                            items[i].endDate,
                          ),
                          details: _workBulletLines(items[i]),
                        ),
                      ),
                  ];
                case ResumeBuilderSectionIds.projects:
                  final items = resume.visibleProjects;
                  if (items.isEmpty) return null;
                  return [
                    sectionHeading('Projects'),
                    for (final item in items)
                      timelineEntry(
                        title: item.title.trim().ifEmpty('Project'),
                        organisation: item.subtitle.trim(),
                        dates: '',
                        details: [
                          item.overview.trim(),
                          item.impact.trim(),
                          ...item.bullets.map((bullet) => bullet.trim()),
                        ].where((line) => line.isNotEmpty).toList(),
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
