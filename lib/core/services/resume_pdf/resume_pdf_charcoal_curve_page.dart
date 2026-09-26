part of 'package:resume_app/core/services/resume_services.dart';

/// Charcoal Curve: full-height charcoal rail with a curved inner edge, a
/// rounded photo overlapping the rail's top, a dark nameplate pill in the main
/// column, and sections that finish with rated skill bars.
const double _charcoalCurveRailWidthPt = 206.0;
const double _charcoalCurveRailInsetPt = 26.0;
const double _charcoalCurveRailTopPt = 150.0;
const double _charcoalCurveAvatarPt = 140.0;
const double _charcoalCurveAvatarLeftPt = 34.0;
const double _charcoalCurveAvatarTopPt = 48.0;
const double _charcoalCurveAvatarCornerPt = 18.0;
const double _charcoalCurveAvatarCornerBottomRightPt =
    _charcoalCurveAvatarCornerPt * 3;
const double _charcoalCurveMainLeftPt = _charcoalCurveRailWidthPt + 32.0;
const double _charcoalCurveMainRightPt = 40.0;
/// Extra left inset used on page 1 so body text clears the charcoal rail.
/// From page 2 the MultiPage uses full-width side margins instead.
const double _charcoalCurvePage1ContentInsetPt =
    _charcoalCurveMainLeftPt - _charcoalCurveMainRightPt;
const double _charcoalCurvePageTopPt = 48.0;
const double _charcoalCurvePageBottomPt = 40.0;
const double _charcoalCurveMetaColumnPt = 120.0;
/// Skill name column (narrower so the bar does not dominate the row).
const double _charcoalCurveSkillLabelPt = 96.0;
/// Fixed skill-bar track width beside the rail (page 1).
const double _charcoalCurveSkillBarPt = 88.0;

/// Pads main-column widgets beside the rail on page 1; no pad from page 2 so
/// text can use the full page width.
pw.Widget _charcoalCurveMainPad(pw.Widget child) => pw.DelayedWidget(
  build: (context) => pw.Padding(
    padding: pw.EdgeInsets.only(
      left: context.pageNumber == 1 ? _charcoalCurvePage1ContentInsetPt : 0,
    ),
    child: child,
  ),
);

/// Custom sections with these titles read as a short "about" paragraph in the
/// rail instead of a main-column section.
final RegExp _charcoalCurveRailAboutTitle = RegExp(
  r'^(about( me)?|profile|objective)$',
  caseSensitive: false,
);

extension _ResumePdfCharcoalCurvePage on ResumePdfService {
  void _addCharcoalCurveTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _pdfRgb(resume.charcoalCurveAccentColor);
    final onAccent = _pdfRgb(resume.charcoalCurveOnAccentColor);
    final titleColor = _pdfRgb(resume.charcoalCurveTitleColor);
    final mutedColor = _pdfRgb(resume.charcoalCurveMutedColor);
    final ruleColor = _pdfRgb(resume.charcoalCurveRuleColor);
    final trackColor = _pdfRgb(resume.charcoalCurveTrackColor);
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

    final nameStyle = style(ResumeFontWeight.w800, 24, onAccent);
    final jobStyle = style(ResumeFontWeight.w400, 13, _pdfMix(onAccent, accent, 0.35));
    final sectionStyle = style(ResumeFontWeight.w700, 14, titleColor);
    final entryTitleStyle = style(ResumeFontWeight.w700, bodyPt, titleColor);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );
    final railHeadingStyle = style(ResumeFontWeight.w700, 12.5, onAccent);
    final railBodyStyle = style(
      ResumeFontWeight.w400,
      detailPt - 0.5,
      _pdfMix(onAccent, accent, 0.25),
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt - 0.5),
    );
    final railStrongStyle = style(ResumeFontWeight.w700, detailPt - 0.5, onAccent);

    pw.Widget sectionHeading(String label) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: sectionStyle),
          pw.SizedBox(height: 5),
          pw.Container(height: 0.8, color: ruleColor),
        ],
      ),
    );

    /// Left meta column (organisation, dates) beside the entry body, as in the
    /// reference layout's education and experience rows.
    pw.Widget splitRow({
      required List<pw.Widget> meta,
      required List<pw.Widget> detail,
      double bottom = 12,
    }) => pw.Padding(
      padding: pw.EdgeInsets.only(bottom: bottom),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: _charcoalCurveMetaColumnPt,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: meta,
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: detail,
            ),
          ),
        ],
      ),
    );

    /// Work rows split into separate widgets so a page break can fall between
    /// bullets instead of leaving a large empty band at the bottom of page 1.
    List<pw.Widget> workEntry(
      WorkExperience item, {
      bool highlight = false,
    }) {
      final bullets = _workBulletLines(item);
      final meta = <pw.Widget>[
        pw.Text(
          item.company.trim().ifEmpty('Company'),
          style: entryTitleStyle,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          educationDateRangeLabel(item.startDate, item.endDate),
          style: bodyStyle,
        ),
      ];
      pw.Widget indent(pw.Widget child) => pw.Padding(
        padding: const pw.EdgeInsets.only(
          left: _charcoalCurveMetaColumnPt + 18,
          top: 3,
        ),
        child: child,
      );
      final header = _headerSidebarMaybeHighlight(
        highlight: highlight,
        child: splitRow(
          meta: meta,
          detail: [
            pw.Text(
              item.role.trim().ifEmpty('Role'),
              style: entryTitleStyle,
            ),
            if (bullets.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(bullets.first, style: bodyStyle),
            ],
          ],
          bottom: bullets.length <= 1 ? 12 : 0,
        ),
      );
      return [
        header,
        for (final line in bullets.skip(1))
          _headerSidebarMaybeHighlight(
            highlight: highlight,
            child: indent(pw.Text(line, style: bodyStyle)),
          ),
        if (bullets.length > 1) pw.SizedBox(height: 12),
      ];
    }

    final skills = resume.skillsLinesForDisplay;

    pw.Widget skillBar(
      String skill, {
      required double barWidth,
      bool expandLabel = false,
    }) {
      final filled = (resume.proficiencyFractionForSkill(skill) * 100)
          .round()
          .clamp(8, 100);
      final label = pw.Text(skill, style: entryTitleStyle);
      final track = pw.SizedBox(
        width: barWidth,
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: filled,
              child: pw.Container(
                height: 7,
                decoration: pw.BoxDecoration(
                  color: accent,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(3.5),
                    bottomLeft: pw.Radius.circular(3.5),
                  ),
                ),
              ),
            ),
            if (filled < 100)
              pw.Expanded(
                flex: 100 - filled,
                child: pw.Container(
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: trackColor,
                    borderRadius: const pw.BorderRadius.only(
                      topRight: pw.Radius.circular(3.5),
                      bottomRight: pw.Radius.circular(3.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
      return _headerSidebarMaybeHighlight(
        highlight: highlightedSkills.contains(skill),
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (expandLabel)
                pw.Expanded(child: label)
              else
                pw.SizedBox(
                  width: _charcoalCurveSkillLabelPt,
                  child: label,
                ),
              pw.SizedBox(width: 10),
              track,
            ],
          ),
        ),
      );
    }

    /// One skill per row so MultiPage can break between skills.
    List<pw.Widget> skillsBody() {
      if (skills.isEmpty) return const [];
      return [
        for (final skill in skills)
          skillBar(
            skill,
            barWidth: _charcoalCurveSkillBarPt,
          ),
      ];
    }

    final aboutSections = resume.customSections
        .where(
          (item) =>
              !item.isBlank &&
              _charcoalCurveRailAboutTitle.hasMatch(item.title.trim()),
        )
        .toList();
    final railListSections = resume.customSections
        .where((item) => !item.isBlank && _slateSidebarIsRailSection(item))
        .toList();
    final mainCustomSections = resume.customSections
        .where(
          (item) =>
              !aboutSections.contains(item) && !railListSections.contains(item),
        )
        .toSet();

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

    pw.Widget railHeading(String label) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: railHeadingStyle),
          pw.SizedBox(height: 5),
          pw.Container(height: 0.7, color: _pdfMix(onAccent, accent, 0.55)),
        ],
      ),
    );

    /// Rail list lines read as "English | Fluent"; the level is set apart.
    pw.Widget railListLine(String line) {
      final parts = line
          .split(RegExp(r'\s*[|:–-]\s*'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.length < 2) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(line, style: railStrongStyle),
        );
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: pw.Text(parts.first, style: railStrongStyle)),
            pw.SizedBox(width: 8),
            pw.Text(parts.sublist(1).join(' '), style: railBodyStyle),
          ],
        ),
      );
    }

    final rail = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final section in aboutSections) ...[
          railHeading(section.title.trim()),
          pw.Text(
            section.displayLines().join(' '),
            style: railBodyStyle,
          ),
        ],
        if (contacts.isNotEmpty) ...[
          railHeading('Contact'),
          for (final (icon, value) in contacts)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    margin: const pw.EdgeInsets.only(top: 1),
                    child: pw.CustomPaint(
                      painter: (canvas, size) => _paintMinimalProfileIcon(
                        canvas,
                        size,
                        icon,
                        onAccent,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(value, style: railBodyStyle),
                  ),
                ],
              ),
            ),
        ],
        for (final section in railListSections) ...[
          railHeading(section.title.trim()),
          // displayLines() keeps "English | Fluent" intact; railListLine
          // splits the label from the level.
          for (final line in section.displayLines()) railListLine(line),
        ],
      ],
    );

    final summary = resume.summary.trim();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          // Full-page side margins; page 1 body is inset via
          // [_charcoalCurveMainPad] so it clears the rail. Page 2+ uses the
          // full width with no black sidebar.
          margin: const pw.EdgeInsets.fromLTRB(
            _charcoalCurveMainRightPt,
            _charcoalCurvePageTopPt,
            _charcoalCurveMainRightPt,
            _charcoalCurvePageBottomPt,
          ),
          buildBackground: (context) {
            if (context.pageNumber != 1) {
              return pw.SizedBox();
            }
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    left: 0,
                    top: _charcoalCurveRailTopPt,
                    bottom: 0,
                    child: pw.Container(
                      width: _charcoalCurveRailWidthPt,
                      decoration: pw.BoxDecoration(
                        color: accent,
                        borderRadius: const pw.BorderRadius.only(
                          topRight: pw.Radius.circular(78),
                        ),
                      ),
                    ),
                  ),
                  pw.Positioned(
                    left: _charcoalCurveAvatarLeftPt,
                    top: _charcoalCurveAvatarTopPt,
                    child: pw.Container(
                      width: _charcoalCurveAvatarPt,
                      height: _charcoalCurveAvatarPt,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: _pdfMix(accent, PdfColors.white, 0.55),
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(
                            _charcoalCurveAvatarCornerPt,
                          ),
                          topRight: pw.Radius.circular(
                            _charcoalCurveAvatarCornerPt,
                          ),
                          bottomLeft: pw.Radius.circular(
                            _charcoalCurveAvatarCornerPt,
                          ),
                          bottomRight: pw.Radius.circular(
                            _charcoalCurveAvatarCornerBottomRightPt,
                          ),
                        ),
                        image: profileImage == null
                            ? null
                            : pw.DecorationImage(
                                image: profileImage,
                                fit: pw.BoxFit.cover,
                                alignment: pw.Alignment.center,
                              ),
                      ),
                      child: profileImage != null
                          ? null
                          : pw.Text(
                              _resumeInitials(resume),
                              style: style(
                                ResumeFontWeight.w700,
                                30,
                                accent,
                              ),
                            ),
                    ),
                  ),
                  pw.Positioned(
                    left: _charcoalCurveRailInsetPt,
                    top:
                        _charcoalCurveAvatarTopPt +
                        _charcoalCurveAvatarPt +
                        18,
                    bottom: _charcoalCurvePageBottomPt,
                    child: pw.SizedBox(
                      width:
                          _charcoalCurveRailWidthPt -
                          _charcoalCurveRailInsetPt * 2,
                      child: pw.ClipRect(child: rail),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        build: (context) {
          final body = <pw.Widget>[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  bottomLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(46),
                  bottomRight: pw.Radius.circular(46),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(_displayName(resume), style: nameStyle),
                  if (resume.jobTitle.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(resume.jobTitle.trim(), style: jobStyle),
                  ],
                ],
              ),
            ),
            if (summary.isNotEmpty) ...[
              sectionHeading('Summary'),
              _headerSidebarMaybeHighlight(
                highlight: highlightSummary,
                child: pw.Text(summary, style: bodyStyle),
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
                      sectionHeading('Education'),
                      for (final item in items)
                        splitRow(
                          meta: [
                            pw.Text(
                              item.institution.trim().ifEmpty('Institution'),
                              style: entryTitleStyle,
                            ),
                            if (educationScoreDisplayLabel(
                              item,
                            ).isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                educationScoreDisplayLabel(item),
                                style: bodyStyle,
                              ),
                            ],
                          ],
                          detail: [
                            pw.Text(
                              educationDateRangeLabel(
                                item.startDate,
                                item.endDate,
                              ),
                              style: bodyStyle,
                            ),
                            if (item.degree.trim().isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(item.degree.trim(), style: bodyStyle),
                            ],
                          ],
                        ),
                    ];
                  case ResumeBuilderSectionIds.work:
                    final items = resume.visibleWorkExperiences;
                    if (items.isEmpty) return null;
                    return [
                      sectionHeading('Work Experience'),
                      for (var i = 0; i < items.length; i++)
                        ...workEntry(
                          items[i],
                          highlight:
                              highlightedBulletsByExperience[i]?.isNotEmpty ??
                              false,
                        ),
                    ];
                  case ResumeBuilderSectionIds.skills:
                    if (skills.isEmpty) return null;
                    return [
                      sectionHeading('Skills'),
                      ...skillsBody(),
                    ];
                  case ResumeBuilderSectionIds.projects:
                    final items = resume.visibleProjects;
                    if (items.isEmpty) return null;
                    return [
                      sectionHeading('Projects'),
                      for (final item in items)
                        splitRow(
                          meta: [
                            pw.Text(
                              item.title.trim().ifEmpty('Project'),
                              style: entryTitleStyle,
                            ),
                            if (item.subtitle.trim().isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(item.subtitle.trim(), style: bodyStyle),
                            ],
                          ],
                          detail: [
                            for (final line in [
                              item.overview.trim(),
                              item.impact.trim(),
                              ...item.bullets.map((bullet) => bullet.trim()),
                            ].where((line) => line.isNotEmpty)) ...[
                              pw.Text(line, style: bodyStyle),
                              pw.SizedBox(height: 3),
                            ],
                          ],
                        ),
                    ];
                }
                return null;
              },
            ),
          ];
          return [
            for (final widget in body) _charcoalCurveMainPad(widget),
          ];
        },
      ),
    );
  }
}
