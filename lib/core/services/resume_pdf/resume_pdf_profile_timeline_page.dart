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
const double _profileTimelineContinuationTopPt = 44.0;
const double _profileTimelinePageBottomPt = 40.0;
const double _profileTimelineAvatarPt = 118.0;
const double _profileTimelineRingPt = 8.0;
const double _profileTimelineFullWidthLeftPt = _profileTimelinePageLeftPt;
const double _profileTimelineContentInsetPt =
    _profileTimelineMainLeftPt - _profileTimelineFullWidthLeftPt;

/// Indent that clears the timeline rule: everything in the main column except
/// the entry markers themselves starts to the right of it.
const double _profileTimelineGutterPt = _profileTimelineRingPt + 14.0;

class _ProfileTimelineSidebarSlice {
  const _ProfileTimelineSidebarSlice(this.blocks);
  final List<pw.Widget> blocks;
}

bool _profileTimelineIsLanguageSection(CustomSectionItem item) {
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
    // Body copy is black on every template; greys stay for dates and rails.
    final bodyInk = _pdfRgb(ResumeTypography.atsStructuredBodyTextColor);
    final ruleColor = _pdfRgb(resume.profileTimelineRuleColor);
    final chipColor = _pdfRgb(resume.profileTimelineChipColor);
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
      bodyInk,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );
    final chipStyle = garamondPdfTextStyle(
      fonts,
      ResumeFontWeight.w600,
      fontSize: detailPt - 1,
      color: titleColor,
      fontStyle: pw.FontStyle.italic,
    );

    pw.Widget sectionHeading(String label, {bool indent = false}) {
      if (indent) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 18, bottom: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: _profileTimelineRingPt,
                height: _profileTimelineRingPt,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: accent,
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Text(label, style: sectionStyle),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Container(height: 1, color: ruleColor)),
            ],
          ),
        );
      }
      return pw.Padding(
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
    }

    /// Experience entry: hollow ring on the rule, role, company, date chip.
    /// An entry as a list of widgets rather than one Row: a Row cannot break
    /// across pages, so a tall entry used to jump to the next page whole and
    /// leave the rest of the page empty. Split this way the entry flows, and
    /// only the parts that do not fit move on.
    List<pw.Widget> timelineEntry({
      required String title,
      required String meta,
      required String dates,
      required List<String> details,
      bool last = false,
    }) {
      pw.Widget indented(pw.Widget child) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: _profileTimelineGutterPt),
        child: child,
      );

      return [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: _profileTimelineRingPt,
              height: _profileTimelineRingPt,
              margin: const pw.EdgeInsets.only(top: 3, right: 14),
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: accent, width: 1.4),
              ),
            ),
            pw.Expanded(
              child: pw.Row(
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
            ),
          ],
        ),
        if (meta.isNotEmpty)
          indented(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(meta, style: bodyStyle),
            ),
          ),
        for (final line in details)
          indented(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('\u2022  ', style: bodyStyle),
                  pw.Expanded(
                    child: pw.Text(
                      line,
                      style: bodyStyle,
                      textAlign: pw.TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!last) pw.SizedBox(height: 14),
      ];
    }

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
            color: accent,
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

    final languageSections = resume.customSections
        .where(
          (item) => !item.isBlank && _profileTimelineIsLanguageSection(item),
        )
        .toList();
    final mainCustomSections = resume.customSections
        .where((item) => !languageSections.contains(item))
        .toSet();
    final summary = resume.summary.trim();

    final sideInnerWidth = _profileTimelineSideWidthPt;
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

    final leftBlocks = <({pw.Widget widget, double height})>[];
    if (summary.isNotEmpty) {
      leftBlocks.add((
        widget: sectionHeading('About Me'),
        height: 43.0,
      ));
      final lines = wrappedLines(summary, sideInnerWidth);
      leftBlocks.add((
        widget: _headerSidebarMaybeHighlight(
          highlight: highlightSummary,
          child: pw.Text(summary, style: bodyStyle),
        ),
        height: lines * lineHeight + 8,
      ));
    }
    if (resume.visibleEducation.isNotEmpty) {
      leftBlocks.add((
        widget: sectionHeading('Education'),
        height: 43.0,
      ));
      for (final item in resume.visibleEducation) {
        var h = 0.0;
        final degree = item.degree.trim().ifEmpty('Degree');
        final degreeLines = wrappedLines(degree, sideInnerWidth);
        h += degreeLines * (bodyPt * ResumeTypography.bodyTextLineHeight);
        if (item.institution.trim().isNotEmpty) {
          final instLines =
              wrappedLines(item.institution.trim(), sideInnerWidth);
          h += instLines * lineHeight;
        }
        final dateLabel =
            educationDateRangeLabel(item.startDate, item.endDate);
        if (dateLabel.isNotEmpty) {
          h += lineHeight;
        }
        final scoreLabel = educationDetailLine(item);
        if (scoreLabel.isNotEmpty) {
          h += lineHeight;
        }
        h += 10.0;
        leftBlocks.add((
          widget: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(degree, style: entryTitleStyle),
                if (item.institution.trim().isNotEmpty)
                  pw.Text(item.institution.trim(), style: bodyStyle),
                if (dateLabel.isNotEmpty)
                  pw.Text(dateLabel, style: bodyStyle),
                if (scoreLabel.isNotEmpty)
                  pw.Text(scoreLabel, style: bodyStyle),
              ],
            ),
          ),
          height: h,
        ));
      }
    }
    for (final section in languageSections) {
      leftBlocks.add((
        widget: sectionHeading(section.title.trim()),
        height: 43.0,
      ));
      for (final line in _slateSidebarRailSectionLines(section)) {
        final lines = wrappedLines(line, sideInnerWidth - 16);
        leftBlocks.add((
          widget: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('•  ', style: bodyStyle),
                pw.Expanded(child: pw.Text(line, style: bodyStyle)),
              ],
            ),
          ),
          height: lines * lineHeight + 5,
        ));
      }
    }

    final page1LeftBudget = PdfPageFormat.a4.height -
        _profileTimelinePageTopPt -
        _profileTimelinePageBottomPt;
    final continuationLeftBudget = PdfPageFormat.a4.height -
        _profileTimelineContinuationTopPt -
        _profileTimelinePageBottomPt;

    final sidebarSlices = <_ProfileTimelineSidebarSlice>[];
    if (leftBlocks.isNotEmpty) {
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
        sidebarSlices.add(_ProfileTimelineSidebarSlice(chunk));
        isFirstSlice = false;
      }
    }

    final sidebarPageCount = sidebarSlices.length;

    bool usesSideColumn(int pageNumber) =>
        sidebarPageCount > 0 && pageNumber <= sidebarPageCount;

    pw.Widget mainWrap(pw.Widget child) => pw.DelayedWidget(
      build: (context) => pw.Padding(
        padding: pw.EdgeInsets.only(
          left: usesSideColumn(context.pageNumber)
              ? _profileTimelineContentInsetPt
              : 0,
        ),
        child: child,
      ),
    );

    pw.Widget skillLine(String skill) => _headerSidebarMaybeHighlight(
      highlight: highlightedSkills.contains(skill),
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('• ', style: bodyStyle),
            pw.Expanded(child: pw.Text(skill, style: bodyStyle)),
          ],
        ),
      ),
    );

    List<pw.Widget> skillsBody(List<String> skills) {
      if (skills.isEmpty) return const [];
      final rows = <pw.Widget>[];
      for (var i = 0; i < skills.length; i += 2) {
        final first = skills[i];
        final second = i + 1 < skills.length ? skills[i + 1] : null;
        rows.add(
          pw.DelayedWidget(
            build: (context) {
              final besideSidebar = usesSideColumn(context.pageNumber);
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
                  left: (besideSidebar ? _profileTimelineContentInsetPt : 0) +
                      _profileTimelineGutterPt,
                ),
                child: pw.Inseparable(child: child),
              );
            },
          ),
        );
      }
      return rows;
    }

    pw.Widget pageBackground(int pageNumber) {
      final firstPage = pageNumber == 1;
      final showSidebar = usesSideColumn(pageNumber);
      final timelineX = showSidebar
          ? _profileTimelineMainLeftPt + _profileTimelineRingPt / 2
          : _profileTimelineFullWidthLeftPt + _profileTimelineRingPt / 2;

      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            if (firstPage)
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
            if (showSidebar)
              pw.Positioned(
                left: _profileTimelinePageLeftPt,
                top: firstPage
                    ? _profileTimelinePageTopPt
                    : _profileTimelineContinuationTopPt,
                bottom: _profileTimelinePageBottomPt,
                child: pw.SizedBox(
                  width: _profileTimelineSideWidthPt,
                  child: pw.ClipRect(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: sidebarSlices[pageNumber - 1].blocks,
                    ),
                  ),
                ),
              ),
            pw.Positioned(
              left: timelineX,
              top: firstPage
                  ? _profileTimelinePageTopPt + 40
                  : _profileTimelineContinuationTopPt,
              bottom: _profileTimelinePageBottomPt,
              child: pw.Container(width: 1, color: ruleColor),
            ),
          ],
        ),
      );
    }

    /// Heading plus the item under it as one unbreakable block, so a heading
    /// never sits alone at the bottom of a page with its content overleaf.
    pw.Widget keepWithNext(List<pw.Widget> children) => pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _profileTimelineFullWidthLeftPt,
            _profileTimelineContinuationTopPt,
            _profileTimelineMainRightPt,
            _profileTimelinePageBottomPt,
          ),
          buildBackground: (context) => pageBackground(context.pageNumber),
        ),
        build: (context) => [
          pw.SizedBox(
            height:
                _profileTimelinePageTopPt - _profileTimelineContinuationTopPt,
          ),
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
                if (!mainCustomSections.contains(item)) return null;
                return [
                  mainWrap(
                    sectionHeading(
                      item.title.ifEmpty('Custom section'),
                      indent: true,
                    ),
                  ),
                  for (final widget in _pwCustomSectionBodyWidgets(
                    item,
                    garamond: fonts,
                    bodyFontPt: detailPt,
                    accentStripGaramondBody: true,
                  ))
                    mainWrap(
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(
                          left: _profileTimelineGutterPt,
                        ),
                        child: widget,
                      ),
                    ),
                ];
              }
              switch (id) {
                case ResumeBuilderSectionIds.skills:
                  if (resume.showCategorisedSkills) {
                    return [
                      mainWrap(sectionHeading('Skills', indent: true)),
                      ..._categorisedSkillsPdfWidgets(
                        resume,
                        bodyStyle: bodyStyle,
                        categoryStyle: entryTitleStyle,
                      ).map(
                        (w) => mainWrap(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(
                              left: _profileTimelineGutterPt,
                            ),
                            child: w,
                          ),
                        ),
                      ),
                    ];
                  }
                  final skills = resume.skillsLinesForDisplay;
                  if (skills.isEmpty) return null;
                  final skillRows = skillsBody(skills);
                  return [
                    keepWithNext([
                      mainWrap(sectionHeading('Skills', indent: true)),
                      if (skillRows.isNotEmpty) skillRows.first,
                    ]),
                    ...skillRows.skip(1),
                  ];
                case ResumeBuilderSectionIds.work:
                  final items = resume.visibleWorkExperiences;
                  if (items.isEmpty) return null;
                  final experienceWidgets = <pw.Widget>[
                    for (var i = 0; i < items.length; i++)
                      ...timelineEntry(
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
                        last: i == items.length - 1,
                      ),
                  ];
                  return [
                    mainWrap(
                      keepWithNext([
                        sectionHeading('Experience', indent: true),
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
                        meta: items[i].subtitle.trim(),
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
                        sectionHeading('Projects', indent: true),
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
  }
}
