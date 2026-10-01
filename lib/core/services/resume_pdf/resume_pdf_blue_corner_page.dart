part of 'package:resume_app/core/services/resume_services.dart';

/// Blue Corner: a blue wedge in the top-left behind a circular photo, a light
/// contact sidebar, and dotted timeline entries. Contact and languages stay in
/// the sidebar until they are fully shown. Page 1 keeps the photo column;
/// later pages use the full width once that sidebar content is finished, with
/// skills in two columns on those pages.
const double _blueCornerSideWidthPt = 214.0;
const double _blueCornerSideInsetPt = 34.0;
const double _blueCornerWedgePt = 250.0;
const double _blueCornerAvatarPt = 138.0;
const double _blueCornerHeaderBottomPt = 300.0;
const double _blueCornerMainLeftPt = 258.0;
const double _blueCornerMainRightPt = 42.0;

/// Left margin once the sidebar is finished, matching the right margin.
const double _blueCornerFullWidthLeftPt = _blueCornerMainRightPt;

/// Extra left inset while the photo column or sidebar is still on the page.
const double _blueCornerContentInsetPt =
    _blueCornerMainLeftPt - _blueCornerFullWidthLeftPt;
const double _blueCornerPageTopPt = 46.0;
const double _blueCornerPageBottomPt = 42.0;
const double _blueCornerTimelineDotPt = 8.0;

/// One page of Blue Corner sidebar content (contact, then languages).
class _BlueCornerSidebarSlice {
  const _BlueCornerSidebarSlice(this.blocks);

  final List<pw.Widget> blocks;
}

bool _blueCornerIsLanguageSection(CustomSectionItem item) {
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
    // Body copy is black on every template; greys stay for dates and rails.
    final bodyInk = _pdfRgb(ResumeTypography.atsStructuredBodyTextColor);
    final ruleColor = _pdfRgb(resume.blueCornerRuleColor);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    // Body copy renders at the slider size; only dated/rail lines step down.
    final detailPt = bodyPt;

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
      bodyInk,
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
    /// An entry as a list of widgets rather than one Row: a Row cannot break
    /// across pages, so a tall entry used to jump to the next page whole and
    /// leave the rest of the page empty. Split this way only the part that
    /// does not fit moves on.
    List<pw.Widget> timelineEntry({
      required String title,
      required String organisation,
      required String dates,
      required List<String> details,
      bool last = false,
    }) {
      const detailIndent = _blueCornerTimelineDotPt + 12;
      pw.Widget indented(pw.Widget child) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: detailIndent),
        child: child,
      );

      return [
        pw.Row(
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
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text(title, style: entryTitleStyle)),
                  if (dates.isNotEmpty) ...[
                    pw.SizedBox(width: 10),
                    pw.Text(dates, style: bodyStyle),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (organisation.isNotEmpty)
          indented(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(organisation, style: entrySubStyle),
            ),
          ),
        for (final line in details)
          indented(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                line,
                style: bodyStyle,
                textAlign: pw.TextAlign.left,
              ),
            ),
          ),
        if (!last) pw.SizedBox(height: 14),
      ];
    }

    /// Heading plus the widget under it as one unbreakable block, so a heading
    /// never sits alone at the bottom of a page.
    pw.Widget keepWithNext(List<pw.Widget> children) => pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
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

    final languageSections = resume.customSections
        .where((item) => !item.isBlank && _blueCornerIsLanguageSection(item))
        .toList();
    final mainCustomSections = resume.customSections
        .where((item) => !languageSections.contains(item))
        .toSet();
    final summary = resume.summary.trim();

    pw.Widget contactRow(_MinimalProfileIcon icon, String value) => pw.Padding(
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
    );

    pw.Widget sideBullet(String line) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('•  ', style: bodyStyle),
          pw.Expanded(child: pw.Text(line, style: bodyStyle)),
        ],
      ),
    );

    final sideInnerWidth = _blueCornerSideWidthPt - _blueCornerSideInsetPt * 2;
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

    const headingHeight = 58.0;
    final contactTextWidth = sideInnerWidth - 11 - 8;
    final bulletTextWidth = sideInnerWidth - 16;
    final leftBlocks = <({pw.Widget widget, double height})>[];
    if (contacts.isNotEmpty) {
      leftBlocks.add((
        widget: sectionHeading('Contact', icon: _MinimalProfileIcon.phone),
        height: headingHeight,
      ));
      for (final (icon, value) in contacts) {
        final lines = wrappedLines(value, contactTextWidth);
        leftBlocks.add((
          widget: contactRow(icon, value),
          height: math.max(11, lines * lineHeight) + 11,
        ));
      }
    }
    for (final section in languageSections) {
      leftBlocks.add((
        widget: sectionHeading(section.title.trim()),
        height: headingHeight,
      ));
      for (final line in _slateSidebarRailSectionLines(section)) {
        final lines = wrappedLines(line, bulletTextWidth);
        leftBlocks.add((
          widget: sideBullet(line),
          height: lines * lineHeight + 9,
        ));
      }
    }

    final page1LeftBudget =
        PdfPageFormat.a4.height -
        _blueCornerHeaderBottomPt -
        _blueCornerPageBottomPt;
    final continuationLeftBudget =
        PdfPageFormat.a4.height -
        _blueCornerPageTopPt -
        _blueCornerPageBottomPt;
    final sidebarSlices = <_BlueCornerSidebarSlice>[];
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
      sidebarSlices.add(_BlueCornerSidebarSlice(chunk));
      isFirstSlice = false;
    }

    final sidebarPageCount = sidebarSlices.length;

    bool usesSideColumn(int pageNumber) =>
        pageNumber == 1 || pageNumber <= sidebarPageCount;

    pw.Widget mainWrap(
      pw.Widget child, {
      bool indentTimeline = false,
    }) => pw.DelayedWidget(
      build: (context) => pw.Padding(
        padding: pw.EdgeInsets.only(
          left: (usesSideColumn(context.pageNumber)
                  ? _blueCornerContentInsetPt
                  : 0) +
              (indentTimeline ? _blueCornerTimelineDotPt + 12 : 0),
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

    /// One column beside the photo or sidebar; two columns on a full-width page.
    List<pw.Widget> skillsBody(List<String> skills) {
      if (skills.isEmpty) return const [];
      final rows = <pw.Widget>[];
      for (var i = 0; i < skills.length; i += 2) {
        final first = skills[i];
        final second = i + 1 < skills.length ? skills[i + 1] : null;
        rows.add(
          pw.DelayedWidget(
            build: (context) {
              final beside = usesSideColumn(context.pageNumber);
              final child = beside
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
                  left: (beside ? _blueCornerContentInsetPt : 0) +
                      _blueCornerTimelineDotPt +
                      12,
                ),
                child: pw.Inseparable(child: child),
              );
            },
          ),
        );
      }
      return rows;
    }

    pw.Widget pageBackground(int pageNumber) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          if (pageNumber == 1) ...[
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
              left: _blueCornerSideWidthPt / 2 - _blueCornerAvatarPt / 2,
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
                          child: pw.Image(profileImage, fit: pw.BoxFit.cover),
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
          ],
          if (sidebarPageCount > 0 && pageNumber <= sidebarPageCount)
            pw.Positioned(
              left: _blueCornerSideInsetPt,
              top: pageNumber == 1
                  ? _blueCornerHeaderBottomPt
                  : _blueCornerPageTopPt,
              bottom: _blueCornerPageBottomPt,
              child: pw.SizedBox(
                width: _blueCornerSideWidthPt - _blueCornerSideInsetPt * 2,
                child: pw.ClipRect(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: sidebarSlices[pageNumber - 1].blocks,
                  ),
                ),
              ),
            ),
          // Timeline rule the entry dots sit on.
          pw.Positioned(
            left:
                (usesSideColumn(pageNumber)
                    ? _blueCornerMainLeftPt
                    : _blueCornerFullWidthLeftPt) +
                _blueCornerTimelineDotPt / 2,
            top: pageNumber == 1
                ? _blueCornerPageTopPt + 40
                : _blueCornerPageTopPt,
            bottom: _blueCornerPageBottomPt,
            child: pw.Container(width: 1, color: ruleColor),
          ),
        ],
      ),
    );

    final pagesBefore = document.document.pdfPageList.pages.length;

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _blueCornerFullWidthLeftPt,
            _blueCornerPageTopPt,
            _blueCornerMainRightPt,
            _blueCornerPageBottomPt,
          ),
          buildBackground: (context) => pageBackground(context.pageNumber),
        ),
        build: (context) => [
          if (summary.isNotEmpty) ...[
            mainWrap(
              sectionHeading('About Me', icon: _MinimalProfileIcon.person),
            ),
            mainWrap(
              _headerSidebarMaybeHighlight(
                highlight: highlightSummary,
                child: pw.Text(
                  summary,
                  style: bodyStyle,
                  textAlign: pw.TextAlign.left,
                ),
              ),
              indentTimeline: true,
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
                    sectionHeading(
                      item.title.ifEmpty('Custom section'),
                      icon: _MinimalProfileIcon.article,
                    ),
                  ),
                  ..._pwCustomSectionBodyWidgets(
                    item,
                    garamond: fonts,
                    bodyFontPt: detailPt,
                    accentStripGaramondBody: true,
                  ).map((w) => mainWrap(w, indentTimeline: true)),
                ];
              }
              switch (id) {
                case ResumeBuilderSectionIds.skills:
                  // Categorised skills keep their headings instead of being
                  // flattened into the plain list.
                  if (resume.showCategorisedSkills) {
                    return [
                      mainWrap(
                        sectionHeading(
                          resume.sectionHeading(ResumeBuilderSectionIds.skills, 'Skills'),
                          icon: _MinimalProfileIcon.puzzle,
                        ),
                      ),
                      ..._categorisedSkillsPdfWidgets(
                        resume,
                        bodyStyle: bodyStyle,
                        categoryStyle: entryTitleStyle,
                      ).map((widget) => mainWrap(widget, indentTimeline: true)),
                    ];
                  }
                  final skills = resume.skillsLinesForDisplay;
                  if (skills.isEmpty) return null;
                  return [
                    mainWrap(
                      sectionHeading(
                        resume.sectionHeading(ResumeBuilderSectionIds.skills, 'Skills'),
                        icon: _MinimalProfileIcon.puzzle,
                      ),
                    ),
                    ...skillsBody(skills),
                  ];
                case ResumeBuilderSectionIds.education:
                  final items = resume.visibleEducation;
                  if (items.isEmpty) return null;
                  final educationWidgets = <pw.Widget>[
                    for (var i = 0; i < items.length; i++)
                      ...timelineEntry(
                        title: items[i].degree.trim().ifEmpty('Degree'),
                        organisation: items[i].institution.trim(),
                        dates: educationDateRangeLabel(
                          items[i].startDate,
                          items[i].endDate,
                        ),
                        details: [
                          if (educationDetailLine(items[i]).isNotEmpty)
                            educationDetailLine(items[i]),
                        ],
                        last: i == items.length - 1,
                      ),
                  ];
                  return [
                    mainWrap(
                      keepWithNext([
                        sectionHeading(
                          resume.sectionHeading(ResumeBuilderSectionIds.education, 'Education'),
                          icon: _MinimalProfileIcon.school,
                        ),
                        educationWidgets.first,
                      ]),
                    ),
                    ...educationWidgets.skip(1).map(mainWrap),
                  ];
                case ResumeBuilderSectionIds.work:
                  final items = resume.visibleWorkExperiences;
                  if (items.isEmpty) return null;
                  final experienceWidgets = <pw.Widget>[
                    for (var i = 0; i < items.length; i++)
                      ...timelineEntry(
                        title: items[i].role.trim().ifEmpty('Role'),
                        organisation: items[i].company.trim(),
                        dates: educationDateRangeLabel(
                          items[i].startDate,
                          items[i].endDate,
                        ),
                        details: _workBulletLines(items[i]),
                        last: i == items.length - 1,
                      ),
                  ];
                  return [
                    mainWrap(
                      keepWithNext([
                        sectionHeading(
                          resume.sectionHeading(ResumeBuilderSectionIds.work, 'Experience'),
                          icon: _MinimalProfileIcon.work,
                        ),
                        experienceWidgets.first,
                      ]),
                    ),
                    ...experienceWidgets.skip(1).map(mainWrap),
                  ];
                case ResumeBuilderSectionIds.projects:
                  final items = resume.visibleProjects;
                  if (items.isEmpty) return null;
                  final projectWidgets = <pw.Widget>[
                    for (var i = 0; i < items.length; i++)
                      ...timelineEntry(
                        title: items[i].title.trim().ifEmpty('Project'),
                        organisation: items[i].subtitle.trim(),
                        dates: '',
                        details: [
                          items[i].overview.trim(),
                          items[i].impact.trim(),
                          ...items[i].bullets.map((bullet) => bullet.trim()),
                        ].where((line) => line.isNotEmpty).toList(),
                        last: i == items.length - 1,
                      ),
                  ];
                  return [
                    mainWrap(
                      keepWithNext([
                        sectionHeading(
                          resume.sectionHeading(ResumeBuilderSectionIds.projects, 'Projects'),
                          icon: _MinimalProfileIcon.folder,
                        ),
                        projectWidgets.first,
                      ]),
                    ),
                    ...projectWidgets.skip(1).map(mainWrap),
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
              _blueCornerFullWidthLeftPt,
              _blueCornerPageTopPt,
              _blueCornerMainRightPt,
              _blueCornerPageBottomPt,
            ),
            buildBackground: (context) => pageBackground(i + 1),
          ),
          build: (context) => pw.SizedBox(),
        ),
      );
    }
  }
}
