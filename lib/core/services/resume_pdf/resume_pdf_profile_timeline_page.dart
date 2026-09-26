part of 'package:resume_app/core/services/resume_services.dart';

/// Profile Timeline: centred photo header with a contact grid, a left column
/// of about/education/rated skills, and a right column of experience entries
/// marked with date chips on a timeline.
const double _profileTimelineHeaderHeightPt = 196.0;
const double _profileTimelineSideWidthPt = 216.0;
const double _profileTimelinePageLeftPt = 44.0;
const double _profileTimelineMainLeftPt = 284.0;
const double _profileTimelineMainRightPt = 44.0;
const double _profileTimelinePageTopPt = _profileTimelineHeaderHeightPt + 20.0;
const double _profileTimelinePageBottomPt = 40.0;
const double _profileTimelineAvatarPt = 118.0;
const double _profileTimelineRingPt = 8.0;
const double _profileTimelineSkillLabelPt = 104.0;

extension _ResumePdfProfileTimelinePage on ResumePdfService {
  void _addProfileTimelineTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _pdfRgb(resume.profileTimelineAccentColor);
    final titleColor = _pdfRgb(resume.profileTimelineTitleColor);
    final mutedColor = _pdfRgb(resume.profileTimelineMutedColor);
    final ruleColor = _pdfRgb(resume.profileTimelineRuleColor);
    final chipColor = _pdfRgb(resume.profileTimelineChipColor);
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

    // garamondPdfTextStyle has no letterSpacing, so the tracked header styles
    // set it on the returned style.
    final nameStyle = style(
      ResumeFontWeight.w800,
      30,
      titleColor,
    ).copyWith(letterSpacing: 1.5);
    final jobStyle = style(
      ResumeFontWeight.w400,
      14,
      mutedColor,
    ).copyWith(letterSpacing: 2);
    final sectionStyle = style(ResumeFontWeight.w700, 15, titleColor);
    final entryTitleStyle = style(ResumeFontWeight.w700, bodyPt, titleColor);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );
    final chipStyle = garamondPdfTextStyle(
      fonts,
      ResumeFontWeight.w600,
      fontSize: detailPt - 1,
      color: titleColor,
      fontStyle: pw.FontStyle.italic,
    );

    pw.Widget sectionHeading(String label) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label, style: sectionStyle),
          pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Container(height: 1, color: ruleColor)),
        ],
      ),
    );

    pw.Widget skillBar(String skill) {
      final filled = (resume.proficiencyFractionForSkill(skill) * 100)
          .round()
          .clamp(8, 100);
      return _headerSidebarMaybeHighlight(
        highlight: highlightedSkills.contains(skill),
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: _profileTimelineSkillLabelPt,
                child: pw.Text(skill, style: bodyStyle),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: filled,
                      child: pw.Container(
                        height: 5,
                        decoration: pw.BoxDecoration(
                          color: accent,
                          borderRadius: pw.BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    if (filled < 100)
                      pw.Expanded(
                        flex: 100 - filled,
                        child: pw.Container(
                          height: 5,
                          margin: const pw.EdgeInsets.only(left: 2),
                          decoration: pw.BoxDecoration(
                            color: chipColor,
                            borderRadius: pw.BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    /// Experience entry: hollow ring on the rule, role, company, date chip.
    pw.Widget timelineEntry({
      required String title,
      required String meta,
      required String dates,
      required List<String> details,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: _profileTimelineRingPt,
            height: _profileTimelineRingPt,
            margin: const pw.EdgeInsets.only(top: 3, right: 14),
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: titleColor, width: 1.4),
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
                      pw.Container(
                        padding: const pw.EdgeInsets.fromLTRB(9, 3, 9, 4),
                        decoration: pw.BoxDecoration(
                          color: chipColor,
                          borderRadius: pw.BorderRadius.circular(9),
                        ),
                        child: pw.Text(dates, style: chipStyle),
                      ),
                    ],
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(meta, style: bodyStyle),
                ],
                for (final line in details) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('•  ', style: bodyStyle),
                      pw.Expanded(
                        child: pw.Text(
                          line,
                          style: bodyStyle,
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                    ],
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
      if (resume.website.trim().isNotEmpty)
        (_MinimalProfileIcon.web, resume.website.trim()),
      if (resume.email.trim().isNotEmpty)
        (_MinimalProfileIcon.mail, resume.email.trim()),
      if (resume.location.trim().isNotEmpty)
        (_MinimalProfileIcon.place, resume.location.trim()),
    ];

    pw.Widget contactCell(_MinimalProfileIcon icon, String value) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 16,
          height: 16,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: titleColor,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.SizedBox(
            width: 9,
            height: 9,
            child: pw.CustomPaint(
              painter: (canvas, size) => _paintMinimalProfileIcon(
                canvas,
                size,
                icon,
                PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(child: pw.Text(value, style: bodyStyle)),
      ],
    );

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
        if (summary.isNotEmpty) ...[
          sectionHeading('About Me'),
          _headerSidebarMaybeHighlight(
            highlight: highlightSummary,
            child: pw.Text(summary, style: bodyStyle),
          ),
        ],
        if (resume.visibleEducation.isNotEmpty) ...[
          sectionHeading('Education'),
          for (final item in resume.visibleEducation)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item.degree.trim().ifEmpty('Degree'),
                    style: entryTitleStyle,
                  ),
                  if (item.institution.trim().isNotEmpty)
                    pw.Text(item.institution.trim(), style: bodyStyle),
                  pw.Text(
                    educationDateRangeLabel(item.startDate, item.endDate),
                    style: bodyStyle,
                  ),
                  if (educationScoreDisplayLabel(item).isNotEmpty)
                    pw.Text(
                      educationScoreDisplayLabel(item),
                      style: bodyStyle,
                    ),
                ],
              ),
            ),
        ],
        if (skills.isNotEmpty) ...[
          sectionHeading('Skills'),
          for (final skill in skills) skillBar(skill),
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
            _profileTimelineMainLeftPt,
            _profileTimelinePageTopPt,
            _profileTimelineMainRightPt,
            _profileTimelinePageBottomPt,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                if (context.pageNumber == 1) ...[
                  pw.Positioned(
                    left: _profileTimelinePageLeftPt,
                    right: _profileTimelineMainRightPt,
                    top: 44,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: _profileTimelineAvatarPt,
                          height: _profileTimelineAvatarPt,
                          decoration: pw.BoxDecoration(
                            color: chipColor,
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: ruleColor, width: 4),
                          ),
                          alignment: pw.Alignment.center,
                          child: profileImage != null
                              ? pw.ClipOval(
                                  child: pw.SizedBox(
                                    width: _profileTimelineAvatarPt,
                                    height: _profileTimelineAvatarPt,
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
                                    titleColor,
                                  ),
                                ),
                        ),
                        pw.SizedBox(width: 26),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(
                                _displayName(resume).toUpperCase(),
                                style: nameStyle,
                              ),
                              if (resume.jobTitle.trim().isNotEmpty) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  resume.jobTitle.trim(),
                                  style: jobStyle,
                                ),
                              ],
                              if (contacts.isNotEmpty) ...[
                                pw.SizedBox(height: 14),
                                for (var i = 0; i < contacts.length; i += 2)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(
                                      bottom: 6,
                                    ),
                                    child: pw.Row(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Expanded(
                                          child: contactCell(
                                            contacts[i].$1,
                                            contacts[i].$2,
                                          ),
                                        ),
                                        pw.SizedBox(width: 16),
                                        pw.Expanded(
                                          child: i + 1 < contacts.length
                                              ? contactCell(
                                                  contacts[i + 1].$1,
                                                  contacts[i + 1].$2,
                                                )
                                              : pw.SizedBox(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Positioned(
                    left: _profileTimelinePageLeftPt,
                    top: _profileTimelinePageTopPt,
                    bottom: _profileTimelinePageBottomPt,
                    child: pw.SizedBox(
                      width: _profileTimelineSideWidthPt,
                      child: pw.ClipRect(child: side),
                    ),
                  ),
                ],
                pw.Positioned(
                  left: _profileTimelineMainLeftPt + _profileTimelineRingPt / 2,
                  top: _profileTimelinePageTopPt + 40,
                  bottom: _profileTimelinePageBottomPt,
                  child: pw.Container(width: 1, color: ruleColor),
                ),
              ],
            ),
          ),
        ),
        build: (context) => [
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
                case ResumeBuilderSectionIds.work:
                  final items = resume.visibleWorkExperiences;
                  if (items.isEmpty) return null;
                  return [
                    sectionHeading('Experience'),
                    for (var i = 0; i < items.length; i++)
                      _headerSidebarMaybeHighlight(
                        highlight:
                            highlightedBulletsByExperience[i]?.isNotEmpty ??
                            false,
                        child: timelineEntry(
                          title: items[i].role.trim().ifEmpty('Role'),
                          meta: [
                            items[i].company.trim(),
                            resume.location.trim(),
                          ].where((part) => part.isNotEmpty).join('  |  '),
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
                        meta: item.subtitle.trim(),
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
