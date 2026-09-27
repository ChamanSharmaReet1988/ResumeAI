part of 'package:resume_app/core/services/resume_services.dart';

/// Bold Pill: black photo header band, pill-shaped sidebar headings, a dotted
/// timeline down the main column, and a black footer bar. Contact and
/// languages stay in the sidebar until they are fully shown; later pages use
/// the full width, with skills in two columns on those pages.
const double _boldPillHeaderHeightPt = 168.0;
const double _boldPillSideWidthPt = 196.0;
const double _boldPillSideInsetPt = 34.0;
const double _boldPillTimelineXPt = 246.0;
const double _boldPillTimelineGapPt = 26.0;
const double _boldPillMainLeftPt =
    _boldPillTimelineXPt + _boldPillTimelineGapPt;
const double _boldPillMainRightPt = 44.0;

/// Left margin once the sidebar is finished, matching the right margin.
const double _boldPillFullWidthLeftPt = _boldPillMainRightPt;

/// Extra left inset while contact and languages still occupy the sidebar.
const double _boldPillContentInsetPt =
    _boldPillMainLeftPt - _boldPillFullWidthLeftPt;
const double _boldPillPageTopPt = _boldPillHeaderHeightPt + 34.0;

/// Top of the body on pages after the photo header.
const double _boldPillContinuationTopPt = 40.0;
const double _boldPillPageBottomPt = 56.0;
const double _boldPillAvatarPt = 118.0;
const double _boldPillFooterHeightPt = 26.0;
const double _boldPillTimelineDotPt = 11.0;

/// One page of Bold Pill sidebar content (contact, then languages).
class _BoldPillSidebarSlice {
  const _BoldPillSidebarSlice(this.blocks);

  final List<pw.Widget> blocks;
}

bool _boldPillIsLanguageSection(CustomSectionItem item) {
  final normalized = item.title.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z]'),
    '',
  );
  return normalized == 'language' ||
      normalized == 'languages' ||
      normalized == 'langueage' ||
      normalized == 'langueages' ||
      normalized.endsWith('languages') ||
      normalized.endsWith('language');
}

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
              left: -_boldPillTimelineGapPt - _boldPillTimelineDotPt / 2 - 0.75,
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

    final languageSections = resume.customSections
        .where((item) => !item.isBlank && _boldPillIsLanguageSection(item))
        .toList();
    final mainCustomSections = resume.customSections
        .where((item) => !languageSections.contains(item))
        .toSet();

    pw.Widget contactRow(_MinimalProfileIcon icon, String value) => pw.Padding(
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
                painter: (canvas, size) =>
                    _paintMinimalProfileIcon(canvas, size, icon, onAccent),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(value, style: sideItemStyle)),
        ],
      ),
    );

    final sideInnerWidth = _boldPillSideWidthPt - _boldPillSideInsetPt;
    final lineHeight = detailPt * ResumeTypography.bodyTextLineHeight;

    double wrappedLines(String text, double width) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return 1;
      final perLine = (width / (detailPt * 0.48)).floor().clamp(8, 80);
      var lines = 1;
      var used = 0;
      for (final word in trimmed.split(RegExp(r'\s+'))) {
        final len = word.length;
        if (used == 0) {
          if (len <= perLine) {
            used = len;
          } else {
            lines += (len / perLine).ceil() - 1;
            final remainder = len % perLine;
            used = remainder == 0 ? perLine : remainder;
          }
        } else if (used + 1 + len <= perLine) {
          used += 1 + len;
        } else {
          lines++;
          if (len <= perLine) {
            used = len;
          } else {
            lines += (len / perLine).ceil() - 1;
            final remainder = len % perLine;
            used = remainder == 0 ? perLine : remainder;
          }
        }
      }
      return lines.toDouble();
    }

    // Pill padding plus one line of the rounded label.
    const pillHeight = 64.0;
    final contactTextWidth = sideInnerWidth - 13 - 8;
    final bulletTextWidth = sideInnerWidth - 16;

    final leftBlocks = <({pw.Widget widget, double height})>[];
    if (contacts.isNotEmpty) {
      leftBlocks.add((widget: pill('Contact'), height: pillHeight));
      for (final (icon, value) in contacts) {
        final lines = wrappedLines(value, contactTextWidth);
        leftBlocks.add((
          widget: contactRow(icon, value),
          height: math.max(13, lines * lineHeight) + 12,
        ));
      }
    }
    for (final section in languageSections) {
      leftBlocks.add((widget: pill(section.title.trim()), height: pillHeight));
      for (final line in _slateSidebarRailSectionLines(section)) {
        final lines = wrappedLines(line, bulletTextWidth);
        leftBlocks.add((
          widget: bulletLine(line, sideItemStyle),
          height: lines * lineHeight + 9,
        ));
      }
    }

    final sidebarBottom = _boldPillPageBottomPt + _boldPillFooterHeightPt;
    final page1LeftBudget =
        PdfPageFormat.a4.height - _boldPillPageTopPt - sidebarBottom;
    final continuationLeftBudget =
        PdfPageFormat.a4.height - _boldPillContinuationTopPt - sidebarBottom;

    final sidebarSlices = <_BoldPillSidebarSlice>[];
    var blockIndex = 0;
    var isFirstSlice = true;
    while (blockIndex < leftBlocks.length) {
      final budget = isFirstSlice ? page1LeftBudget : continuationLeftBudget;
      final chunk = <pw.Widget>[];
      var used = 0.0;
      while (blockIndex < leftBlocks.length) {
        final block = leftBlocks[blockIndex];
        if (chunk.isNotEmpty && used + block.height > budget) break;
        chunk.add(block.widget);
        used += block.height;
        blockIndex++;
      }
      if (chunk.isEmpty) {
        chunk.add(leftBlocks[blockIndex].widget);
        blockIndex++;
      }
      sidebarSlices.add(_BoldPillSidebarSlice(chunk));
      isFirstSlice = false;
    }

    final sidebarPageCount = sidebarSlices.length;

    pw.Widget mainWrap(pw.Widget child) => pw.DelayedWidget(
      build: (context) => pw.Padding(
        padding: pw.EdgeInsets.only(
          left: sidebarPageCount > 0 && context.pageNumber <= sidebarPageCount
              ? _boldPillContentInsetPt
              : 0,
        ),
        child: child,
      ),
    );

    pw.Widget skillLine(String skill) => _headerSidebarMaybeHighlight(
      highlight: highlightedSkills.contains(skill),
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text('• $skill', style: bodyStyle),
      ),
    );

    /// One column beside the sidebar; two columns once the page is full width.
    /// [pw.Inseparable] keeps a pair on one page so a split row cannot crash
    /// PDF generation.
    List<pw.Widget> skillsBody(List<String> skills) {
      if (skills.isEmpty) return const [];
      final rows = <pw.Widget>[];
      for (var i = 0; i < skills.length; i += 2) {
        final first = skills[i];
        final second = i + 1 < skills.length ? skills[i + 1] : null;
        rows.add(
          pw.DelayedWidget(
            build: (context) {
              final besideSidebar =
                  sidebarPageCount > 0 &&
                  context.pageNumber <= sidebarPageCount;
              final child = besideSidebar
                  ? pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        skillLine(first),
                        if (second != null) skillLine(second),
                      ],
                    )
                  : pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(child: skillLine(first)),
                        pw.SizedBox(width: 18),
                        pw.Expanded(
                          child: second == null
                              ? pw.SizedBox()
                              : skillLine(second),
                        ),
                      ],
                    );
              return pw.Padding(
                padding: pw.EdgeInsets.only(
                  left: besideSidebar ? _boldPillContentInsetPt : 0,
                ),
                child: pw.Inseparable(child: child),
              );
            },
          ),
        );
      }
      return rows;
    }

    final summary = resume.summary.trim();

    bool besideSidebar(int pageNumber) =>
        sidebarPageCount > 0 && pageNumber <= sidebarPageCount;

    pw.Widget pageBackground(int pageNumber) {
      final firstPage = pageNumber == 1;
      final showSidebar = besideSidebar(pageNumber);
      final sidebarTop = firstPage
          ? _boldPillPageTopPt
          : _boldPillContinuationTopPt;
      final timelineLeft = showSidebar
          ? _boldPillTimelineXPt
          : _boldPillFullWidthLeftPt - _boldPillTimelineGapPt;
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
                          border: pw.Border.all(color: onAccent, width: 2.5),
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
                                style: style(ResumeFontWeight.w700, 28, accent),
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
                              pw.Text(resume.jobTitle.trim(), style: jobStyle),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (showSidebar)
              pw.Positioned(
                left: _boldPillSideInsetPt,
                top: sidebarTop,
                bottom: _boldPillPageBottomPt + _boldPillFooterHeightPt,
                child: pw.SizedBox(
                  width: _boldPillSideWidthPt - _boldPillSideInsetPt,
                  child: pw.ClipRect(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: sidebarSlices[pageNumber - 1].blocks,
                    ),
                  ),
                ),
              ),
            // Timeline rule behind the main column headings.
            pw.Positioned(
              left: timelineLeft,
              top: firstPage
                  ? _boldPillHeaderHeightPt + 40
                  : _boldPillContinuationTopPt,
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
      );
    }

    final pagesBefore = document.document.pdfPageList.pages.length;

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _boldPillFullWidthLeftPt,
            _boldPillContinuationTopPt,
            _boldPillMainRightPt,
            _boldPillPageBottomPt,
          ),
          buildBackground: (context) => pageBackground(context.pageNumber),
        ),
        build: (context) => [
          pw.SizedBox(height: _boldPillPageTopPt - _boldPillContinuationTopPt),
          if (summary.isNotEmpty) ...[
            mainWrap(timelineHeading('About Me')),
            mainWrap(
              _headerSidebarMaybeHighlight(
                highlight: highlightSummary,
                child: pw.Text(
                  summary,
                  style: bodyStyle,
                  textAlign: pw.TextAlign.justify,
                ),
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
                if (!mainCustomSections.contains(item)) return null;
                return [
                  mainWrap(
                    timelineHeading(item.title.ifEmpty('Custom section')),
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
                    mainWrap(timelineHeading('Skills')),
                    ...skillsBody(skills),
                  ];
                case ResumeBuilderSectionIds.work:
                  final items = resume.visibleWorkExperiences;
                  if (items.isEmpty) return null;
                  return [
                    mainWrap(timelineHeading('Work Experience')),
                    for (var i = 0; i < items.length; i++) ...[
                      mainWrap(
                        _headerSidebarMaybeHighlight(
                          highlight:
                              highlightedBulletsByExperience[i]?.isNotEmpty ??
                              false,
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                          ),
                        ),
                      ),
                      if (items[i].company.trim().isNotEmpty)
                        mainWrap(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              items[i].company.trim(),
                              style: bodyStyle,
                            ),
                          ),
                        ),
                      mainWrap(pw.SizedBox(height: 4)),
                      for (final line in _workBulletLines(items[i]))
                        mainWrap(bulletLine(line, bodyStyle)),
                      mainWrap(pw.SizedBox(height: 8)),
                    ],
                  ];
                case ResumeBuilderSectionIds.education:
                  final items = resume.visibleEducation;
                  if (items.isEmpty) return null;
                  return [
                    mainWrap(timelineHeading('Education')),
                    for (final item in items)
                      mainWrap(
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
                      ),
                  ];
                case ResumeBuilderSectionIds.projects:
                  final items = resume.visibleProjects;
                  if (items.isEmpty) return null;
                  return [
                    mainWrap(timelineHeading('Projects')),
                    for (final item in items) ...[
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
                      for (final line in [
                        item.overview.trim(),
                        item.impact.trim(),
                        ...item.bullets.map((bullet) => bullet.trim()),
                      ].where((line) => line.isNotEmpty))
                        mainWrap(bulletLine(line, bodyStyle)),
                      mainWrap(pw.SizedBox(height: 10)),
                    ],
                  ];
              }
              return null;
            },
          ),
        ],
      ),
    );

    final multiPageCount =
        document.document.pdfPageList.pages.length - pagesBefore;
    for (var i = multiPageCount; i < sidebarPageCount; i++) {
      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(
              _boldPillFullWidthLeftPt,
              _boldPillContinuationTopPt,
              _boldPillMainRightPt,
              _boldPillPageBottomPt,
            ),
            buildBackground: (context) => pageBackground(i + 1),
          ),
          build: (context) => pw.SizedBox(),
        ),
      );
    }
  }
}
