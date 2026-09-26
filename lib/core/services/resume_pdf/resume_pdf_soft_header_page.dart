part of 'package:resume_app/core/services/resume_services.dart';

/// Soft Header: tinted header band with a centred nameplate, then two columns
/// split by a divider — contact, education and short lists on the left; profile,
/// two-column skills and experience on the right. When the left column finishes
/// (page 1 or 2), later pages use the full page width with no divider.
const double _softHeaderBandHeightPt = 150.0;
const double _softHeaderSidePt = 40.0;
const double _softHeaderLeftColumnWidthPt = 196.0;
const double _softHeaderDividerXPt =
    _softHeaderSidePt + _softHeaderLeftColumnWidthPt + 18;
const double _softHeaderMainLeftPt = _softHeaderDividerXPt + 24;
/// Extra left inset while the left column is present so body text clears it.
const double _softHeaderContentInsetPt =
    _softHeaderMainLeftPt - _softHeaderSidePt;
const double _softHeaderTopPt = 30.0;
const double _softHeaderBottomPt = 34.0;

/// Custom sections that read best in the left column.
final RegExp _softHeaderLeftSectionTitle = RegExp(
  r'^(languages?|references?|referees?|awards?|certifications?|certificates?|'
  r'interests?|hobbies)$',
  caseSensitive: false,
);

/// One page of left-column content.
class _SoftHeaderSidebarSlice {
  const _SoftHeaderSidebarSlice(this.blocks);

  final List<pw.Widget> blocks;
}

/// Pads main-column widgets beside the left column while sidebar pages remain;
/// later pages use the full page width.
pw.Widget _softHeaderMainPad(
  pw.Widget child, {
  required int sidebarPageCount,
}) =>
    pw.DelayedWidget(
      build: (context) => pw.Padding(
        padding: pw.EdgeInsets.only(
          left: context.pageNumber <= sidebarPageCount
              ? _softHeaderContentInsetPt
              : 0,
        ),
        child: child,
      ),
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
    final lineH = ResumeTypography.bodyTextLineHeight;

    pw.TextStyle style(
      int weight,
      double size,
      PdfColor color, {
      double? lineSpacing,
      double? letterSpacing,
    }) =>
        garamondPdfTextStyle(
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
    }) =>
        _headerSidebarMaybeHighlight(
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
                    textAlign:
                        justify ? pw.TextAlign.justify : pw.TextAlign.left,
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

    /// Skills as breakable two-column rows so MultiPage can paginate between them.
    List<pw.Widget> skillsTwoColumn(List<String> skills) {
      if (skills.isEmpty) return const [];
      return [
        for (var i = 0; i < skills.length; i += 2)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: bullet(skills[i])),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: i + 1 < skills.length
                      ? bullet(skills[i + 1])
                      : pw.SizedBox(),
                ),
              ],
            ),
          ),
      ];
    }

    final contacts = [
      resume.phone.trim(),
      resume.email.trim(),
      resume.location.trim(),
      resume.website.trim(),
      resume.linkedinLink.trim(),
      resume.githubLink.trim(),
    ].where((value) => value.isNotEmpty).toList();

    // Discrete left-column blocks with estimated heights for pagination.
    final leftBlocks = <({pw.Widget widget, double height})>[];

    double sectionHeadingHeight() => 18 + 10 + 24;

    if (contacts.isNotEmpty) {
      leftBlocks.add((
        widget: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            sectionTitle('Contact'),
            for (final value in contacts) bullet(value, textStyle: metaStyle),
          ],
        ),
        height: sectionHeadingHeight() +
            contacts.length * (detailPt * lineH + 3) +
            4,
      ));
    }

    final firstEducationBlockIndex = education.isEmpty
        ? -1
        : leftBlocks.length;

    for (final item in education) {
      final dateLabel =
          educationDateRangeLabel(item.startDate, item.endDate);
      final degree = item.degree.trim();
      final score = item.score.trim();
      var h = 9.0;
      if (dateLabel.isNotEmpty) h += detailPt * lineH;
      h += detailPt * lineH + 3;
      if (degree.isNotEmpty) h += detailPt * lineH + 3;
      if (score.isNotEmpty) h += detailPt * lineH + 3;
      leftBlocks.add((
        widget: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (dateLabel.isNotEmpty)
              pw.Text(dateLabel, style: strongMetaStyle),
            pw.Text(
              item.institution.trim().toUpperCase(),
              style: style(ResumeFontWeight.w700, detailPt, titleColor),
            ),
            pw.SizedBox(height: 3),
            if (degree.isNotEmpty) bullet(degree),
            if (score.isNotEmpty) bullet(score),
            pw.SizedBox(height: 9),
          ],
        ),
        height: h,
      ));
    }

    for (final section in leftSections) {
      final lines = _slateSidebarRailSectionLines(section);
      leftBlocks.add((
        widget: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            sectionTitle(section.title.trim()),
            for (final line in lines) bullet(line),
          ],
        ),
        height: sectionHeadingHeight() +
            lines.length * (detailPt * lineH + 3) +
            4,
      ));
    }

    final page1LeftBudget = PdfPageFormat.a4.height -
        _softHeaderBandHeightPt -
        16 -
        _softHeaderBottomPt;
    final continuationLeftBudget = PdfPageFormat.a4.height -
        _softHeaderTopPt -
        _softHeaderBottomPt;

    final sidebarSlices = <_SoftHeaderSidebarSlice>[];
    if (leftBlocks.isEmpty) {
      // No left content — main always full width (no divider).
    } else {
      var index = 0;
      var isFirstSlice = true;
      while (index < leftBlocks.length) {
        final budget = isFirstSlice ? page1LeftBudget : continuationLeftBudget;
        final chunk = <pw.Widget>[];
        var used = 0.0;
        var educationHeadingAdded = false;

        // Inject Education heading once when the first education block is taken.
        while (index < leftBlocks.length) {
          final block = leftBlocks[index];
          final needsEduHeading = index == firstEducationBlockIndex &&
              firstEducationBlockIndex >= 0 &&
              !educationHeadingAdded;
          final headingExtra =
              needsEduHeading ? sectionHeadingHeight() : 0.0;
          if (chunk.isNotEmpty &&
              used + block.height + headingExtra > budget) {
            break;
          }
          if (needsEduHeading) {
            chunk.add(sectionTitle('Education'));
            used += headingExtra;
            educationHeadingAdded = true;
          }
          chunk.add(block.widget);
          used += block.height;
          index++;
        }
        if (chunk.isEmpty) break;
        sidebarSlices.add(_SoftHeaderSidebarSlice(chunk));
        isFirstSlice = false;
      }
    }

    final sidebarPageCount = sidebarSlices.length;

    pw.Widget mainWrap(pw.Widget child) =>
        _softHeaderMainPad(child, sidebarPageCount: sidebarPageCount);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          // Equal side margins; body is inset via [_softHeaderMainPad] while
          // left-column pages remain. After that, full width is used.
          margin: const pw.EdgeInsets.fromLTRB(
            _softHeaderSidePt,
            _softHeaderTopPt,
            _softHeaderSidePt,
            _softHeaderBottomPt,
          ),
          buildBackground: (context) {
            final firstPage = context.pageNumber == 1;
            final showSidebar = context.pageNumber <= sidebarPageCount;
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
                  if (showSidebar) ...[
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
                    pw.Positioned(
                      left: _softHeaderSidePt,
                      top: columnsTop,
                      bottom: _softHeaderBottomPt,
                      child: pw.SizedBox(
                        width: _softHeaderLeftColumnWidthPt,
                        child: pw.ClipRect(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children:
                                sidebarSlices[context.pageNumber - 1].blocks,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        build: (context) => [
          mainWrap(
            pw.SizedBox(
              height: _softHeaderBandHeightPt - _softHeaderTopPt + 4,
            ),
          ),
          if (resume.summary.trim().isNotEmpty) ...[
            mainWrap(sectionTitle('Profile Summary')),
            mainWrap(
              _headerSidebarMaybeHighlight(
                highlight: highlightSummary,
                child: pw.Text(
                  resume.summary.trim(),
                  style: bodyStyle,
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ),
          ],
          ..._pdfBodySectionsInBuilderOrder(
            resume,
            exclude: {
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
                  mainWrap(
                    sectionTitle(item.title.ifEmpty('Custom section')),
                  ),
                  ..._pwCustomSectionBodyWidgets(
                    item,
                    garamond: fonts,
                    bodyFontPt: detailPt,
                    accentStripGaramondBody: true,
                  ).map(mainWrap),
                ];
              }
              switch (id) {
                case ResumeBuilderSectionIds.skills:
                  final skills = resume.skillsLinesForDisplay;
                  if (skills.isEmpty) return null;
                  return [
                    mainWrap(sectionTitle('Skills')),
                    ...skillsTwoColumn(skills).map(mainWrap),
                  ];
                case ResumeBuilderSectionIds.work:
                  if (experiences.isEmpty) return null;
                  return [
                    mainWrap(sectionTitle('Work Experience')),
                    for (var i = 0; i < experiences.length; i++)
                      ...experienceEntry(experiences[i], i).map(mainWrap),
                  ];
                case ResumeBuilderSectionIds.projects:
                  if (projects.isEmpty) return null;
                  return [
                    mainWrap(sectionTitle('Projects')),
                    for (final item in projects) ...[
                      mainWrap(
                        pw.Text(
                          item.title.trim().ifEmpty('Project'),
                          style: entryTitleStyle,
                        ),
                      ),
                      if (item.subtitle.trim().isNotEmpty)
                        mainWrap(
                          pw.Text(item.subtitle.trim(), style: bodyStyle),
                        ),
                      mainWrap(pw.SizedBox(height: 5)),
                      for (final line in _projectBulletLinesPdf(item))
                        mainWrap(bullet(line, justify: true)),
                      mainWrap(pw.SizedBox(height: 12)),
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
