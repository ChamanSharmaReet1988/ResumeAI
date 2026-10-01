part of 'package:resume_app/core/services/resume_services.dart';

/// Slate Sidebar: dark left rail (photo, contact, expertise) with a large
/// nameplate and dated two-column rows in the main column. Expertise paginates
/// across sidebar pages until every skill is shown; after that, later pages
/// use the full page width with no rail.
const double _slateSidebarRailWidthPt = 196.0;
const double _slateSidebarRailInsetPt = 24.0;
/// Gap between rail text and the white main column.
const double _slateSidebarRailRightInsetPt = 32.0;
const double _slateSidebarMainLeftPt = _slateSidebarRailWidthPt + 28.0;
const double _slateSidebarMainRightPt = 34.0;
/// Extra left inset while the rail is present so body text clears it.
const double _slateSidebarRailContentInsetPt =
    _slateSidebarMainLeftPt - _slateSidebarMainRightPt;
const double _slateSidebarPageTopPt = 40.0;
const double _slateSidebarPageBottomPt = 36.0;
const double _slateSidebarAvatarSizePt = 104.0;
const double _slateSidebarMetaColumnPt = 104.0;
const double _slateSidebarColumnGapPt = 14.0;

/// One page of rail content: identity (avatar + contact) and/or a skill chunk.
class _SlateSidebarPageSlice {
  const _SlateSidebarPageSlice({
    required this.showIdentity,
    required this.showExpertiseHeading,
    required this.skills,
  });

  final bool showIdentity;
  final bool showExpertiseHeading;
  final List<String> skills;
}

/// Pads main-column widgets beside the rail while skill/contact pages remain;
/// later pages use the full width.
pw.Widget _slateSidebarMainPad(
  pw.Widget child, {
  required int sidebarPageCount,
}) => pw.DelayedWidget(
  build: (context) => pw.Padding(
    padding: pw.EdgeInsets.only(
      left: context.pageNumber <= sidebarPageCount
          ? _slateSidebarRailContentInsetPt
          : 0,
    ),
    child: child,
  ),
);

int _slateSidebarEstimatedSkillLines(
  String text,
  double fontSize,
  double usableWidth,
) {
  final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return 1;
  final maxCharsPerLine = math.max(
    8,
    (usableWidth / (fontSize * 0.56)).floor(),
  );
  var currentLineLength = 0;
  var lineCount = 1;
  for (final word in normalized.split(' ')) {
    final wordLength = word.length;
    if (currentLineLength == 0) {
      currentLineLength = wordLength;
      continue;
    }
    if (currentLineLength + 1 + wordLength > maxCharsPerLine) {
      lineCount++;
      currentLineLength = wordLength;
    } else {
      currentLineLength += 1 + wordLength;
    }
  }
  return lineCount;
}

/// Marks a rail line as a skill category heading rather than a skill.
const String _slateSidebarCategoryMark = '\u241F';

/// Rail lines for the expertise block: plain skills, or a heading line and a
/// comma-separated line per category when categorised skills are on.
List<String> _slateSidebarSkillLines(ResumeData resume) {
  if (!resume.showCategorisedSkills) {
    return resume.skillsLinesForDisplay;
  }
  return [
    for (final group in resume.skillGroupsForResume) ...[
      if (group.heading.trim().isNotEmpty)
        '$_slateSidebarCategoryMark${group.heading.trim()}',
      group.skillsCommaSeparated,
    ],
  ];
}

/// Splits contact + expertise across pages so every skill fits in the rail.
List<_SlateSidebarPageSlice> _slateSidebarPageSlices({
  required List<String> skills,
  required int contactCount,
  required double detailPt,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) {
  final availableHeight =
      pageFormat.height - _slateSidebarPageTopPt - _slateSidebarPageBottomPt;
  final railTextWidth =
      _slateSidebarRailWidthPt -
      _slateSidebarRailInsetPt -
      _slateSidebarRailRightInsetPt;

  // Avatar + gap, then Contact heading, then contact rows.
  // Pad identity so we never over-fill page 1 (ClipRect would hide skills).
  const headingBlock = 22.0 + 12.0 + 6.0 + 16.0;
  final avatarBlock = _slateSidebarAvatarSizePt + 6.0;
  final contactEntryHeight =
      (detailPt * ResumeTypography.bodyTextLineHeight) * 2 + 1 + 9;
  final contactBodyHeight = contactCount == 0
      ? detailPt * ResumeTypography.bodyTextLineHeight
      : contactCount * contactEntryHeight;
  final identityHeight =
      avatarBlock + headingBlock + contactBodyHeight + 28;

  double skillHeight(String item) {
    final lines = _slateSidebarEstimatedSkillLines(
      item,
      detailPt,
      railTextWidth,
    );
    // Slightly tall so wrapped labels are not clipped off page 1.
    return (lines * detailPt * ResumeTypography.bodyTextLineHeight) + 9;
  }

  List<String> takeChunk(Iterable<String> source, double maxHeight) {
    final chunk = <String>[];
    var used = 0.0;
    for (final item in source) {
      final height = skillHeight(item);
      if (chunk.isNotEmpty && used + height > maxHeight) break;
      if (chunk.isEmpty && height > maxHeight) {
        chunk.add(item);
        break;
      }
      chunk.add(item);
      used += height;
    }
    return chunk;
  }

  if (skills.isEmpty) {
    return const [
      _SlateSidebarPageSlice(
        showIdentity: true,
        showExpertiseHeading: false,
        skills: <String>[],
      ),
    ];
  }

  final firstPageSkillsAvailable =
      availableHeight - identityHeight - headingBlock;
  final continuedPageSkillsAvailable = availableHeight - headingBlock;

  final slices = <_SlateSidebarPageSlice>[];
  var index = 0;

  final firstChunk = takeChunk(
    skills.skip(index),
    firstPageSkillsAvailable > 0 ? firstPageSkillsAvailable : 0,
  );
  index += firstChunk.length;
  slices.add(
    _SlateSidebarPageSlice(
      showIdentity: true,
      showExpertiseHeading: firstChunk.isNotEmpty,
      skills: firstChunk,
    ),
  );

  while (index < skills.length) {
    final chunk = takeChunk(
      skills.skip(index),
      continuedPageSkillsAvailable > 0 ? continuedPageSkillsAvailable : 0,
    );
    if (chunk.isEmpty) break;
    index += chunk.length;
    slices.add(
      _SlateSidebarPageSlice(
        showIdentity: false,
        showExpertiseHeading: true,
        skills: chunk,
      ),
    );
  }

  return slices;
}

/// Custom sections with these titles used to live in the rail; they now flow
/// in the main column with every other non-sidebar section.
final RegExp _slateSidebarRailSectionTitle = RegExp(
  r'^(languages?|awards?|certifications?|certificates?|interests?|hobbies)$',
  caseSensitive: false,
);

bool _slateSidebarIsRailSection(CustomSectionItem item) =>
    _slateSidebarRailSectionTitle.hasMatch(item.title.trim()) ||
    _isClassicSidebarLanguagesTitle(item.title);

List<String> _slateSidebarRailSectionLines(CustomSectionItem item) {
  return item.displayLines(splitInlineItems: true);
}

extension _ResumePdfSlateSidebarPage on ResumePdfService {
  void _addSlateSidebarTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final railColor = _pdfRgb(resume.slateSidebarRailColor);
    final titleColor = _pdfRgb(resume.slateSidebarTitleColor);
    final mutedColor = _pdfRgb(resume.slateSidebarMutedColor);
    // Body copy is black on every template; greys stay for dates and rails.
    final bodyInk = _pdfRgb(ResumeTypography.atsStructuredBodyTextColor);
    const onRail = PdfColors.white;
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

    final nameStyle = style(ResumeFontWeight.w700, 30, titleColor);
    final jobTitleStyle = style(
      ResumeFontWeight.w400,
      13,
      titleColor,
    ).copyWith(letterSpacing: 1.2);
    final sectionTitleStyle = style(ResumeFontWeight.w700, 16, titleColor);
    final roleStyle = style(ResumeFontWeight.w600, bodyPt - 0.5, titleColor);
    final metaStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );
    final detailStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      bodyInk,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final skills = _slateSidebarSkillLines(resume);

    pw.Widget sectionTitle(String title) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 22, bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: titleColor, width: 0.8),
        ),
      ),
      child: pw.Text(title, style: sectionTitleStyle),
    );

    pw.Widget bulletLine(String text, {bool highlight = false}) =>
        _headerSidebarMaybeHighlight(
          highlight: highlight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('•  ', style: detailStyle),
                pw.Expanded(child: pw.Text(text, style: detailStyle)),
              ],
            ),
          ),
        );

    // One dated entry: meta (dates + organisation) on the left, title on the
    // right. Detail lines follow as separate widgets under the right column
    // so a page break can fall between them.
    List<pw.Widget> datedEntry({
      required String dates,
      required String organisation,
      required String title,
      required List<pw.Widget> details,
    }) {
      // Nothing to show on the left (e.g. a project): use the full width.
      if (dates.isEmpty && organisation.isEmpty) {
        return [
          pw.Text(title, style: roleStyle),
          ...details,
          pw.SizedBox(height: 14),
        ];
      }
      pw.Widget indent(pw.Widget child) => pw.Padding(
        padding: const pw.EdgeInsets.only(
          left: _slateSidebarMetaColumnPt + _slateSidebarColumnGapPt,
        ),
        child: child,
      );
      return [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: _slateSidebarMetaColumnPt,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (dates.isNotEmpty) pw.Text(dates, style: metaStyle),
                  if (organisation.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(organisation, style: metaStyle),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: _slateSidebarColumnGapPt),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: roleStyle),
                  if (details.isNotEmpty) details.first,
                ],
              ),
            ),
          ],
        ),
        for (final detail in details.skip(1)) indent(detail),
        pw.SizedBox(height: 14),
      ];
    }

    pw.Widget avatar() {
      if (profileImage != null) {
        return pw.ClipOval(
          child: pw.SizedBox(
            width: _slateSidebarAvatarSizePt,
            height: _slateSidebarAvatarSizePt,
            child: pw.Image(profileImage, fit: pw.BoxFit.cover),
          ),
        );
      }
      return pw.Container(
        width: _slateSidebarAvatarSizePt,
        height: _slateSidebarAvatarSizePt,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#D6DCE4'),
          shape: pw.BoxShape.circle,
        ),
        child: pw.Text(
          _resumeInitials(resume),
          style: style(ResumeFontWeight.w700, 30, titleColor),
        ),
      );
    }

    final contacts = <(String, String)>[
      ('Phone', resume.phone.trim()),
      ('Email', resume.email.trim()),
      ('Address', resume.location.trim()),
      ('Website', resume.website.trim()),
      ('LinkedIn', resume.linkedinLink.trim()),
      ('GitHub', resume.githubLink.trim()),
    ].where((entry) => entry.$2.isNotEmpty).toList();

    /// Rail content for one page slice (identity and/or skill chunk).
    pw.Widget railPanel(_SlateSidebarPageSlice slice) {
      final railHeading = style(ResumeFontWeight.w700, 15, onRail);
      final railLabel = style(ResumeFontWeight.w700, detailPt, onRail);
      final railValue = style(ResumeFontWeight.w400, detailPt - 0.5, onRail);
      final railItem = style(ResumeFontWeight.w400, detailPt, onRail);

      pw.Widget heading(String title) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 22, bottom: 12),
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: onRail, width: 0.8),
          ),
        ),
        child: pw.Text(title, style: railHeading),
      );

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (slice.showIdentity) ...[
            pw.Center(child: avatar()),
            pw.SizedBox(height: 6),
            heading('Contact'),
            if (contacts.isEmpty)
              pw.Text('Add contact details', style: railValue)
            else
              for (final (label, value) in contacts) ...[
                pw.Text(label, style: railLabel),
                pw.SizedBox(height: 1),
                pw.Text(value, style: railValue),
                pw.SizedBox(height: 9),
              ],
          ],
          if (slice.showExpertiseHeading) heading('Expertise'),
          for (final skill in slice.skills)
            if (skill.startsWith(_slateSidebarCategoryMark))
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3, bottom: 3),
                child: pw.Text(
                  skill.substring(_slateSidebarCategoryMark.length),
                  style: railLabel,
                ),
              )
            else
              _headerSidebarMaybeHighlight(
                highlight: highlightedSkills.contains(skill),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Text(
                    resume.showCategorisedSkills ? skill : '\u2022 $skill',
                    style: railItem,
                  ),
                ),
              ),
        ],
      );
    }

    final sidebarSlices = _slateSidebarPageSlices(
      skills: skills,
      contactCount: contacts.isEmpty ? 1 : contacts.length,
      detailPt: detailPt,
    );
    final sidebarPageCount = sidebarSlices.length;

    pw.Widget railBackground(_SlateSidebarPageSlice slice) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: pw.Container(
              width: _slateSidebarRailWidthPt,
              color: railColor,
            ),
          ),
          pw.Positioned(
            left: _slateSidebarRailInsetPt,
            top: _slateSidebarPageTopPt,
            bottom: _slateSidebarPageBottomPt,
            child: pw.SizedBox(
              width:
                  _slateSidebarRailWidthPt -
                  _slateSidebarRailInsetPt -
                  _slateSidebarRailRightInsetPt,
              child: pw.ClipRect(child: railPanel(slice)),
            ),
          ),
        ],
      ),
    );

    final pagesBefore = document.document.pdfPageList.pages.length;

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          // Equal side margins; body is inset via [_slateSidebarMainPad] while
          // rail pages remain. After skills are covered, full width is used.
          margin: const pw.EdgeInsets.fromLTRB(
            _slateSidebarMainRightPt,
            _slateSidebarPageTopPt,
            _slateSidebarMainRightPt,
            _slateSidebarPageBottomPt,
          ),
          buildBackground: (context) {
            if (context.pageNumber > sidebarPageCount) {
              return pw.SizedBox();
            }
            return railBackground(sidebarSlices[context.pageNumber - 1]);
          },
        ),
        build: (context) {
          final body = <pw.Widget>[
            pw.Text(_displayName(resume), style: nameStyle),
            if (resume.jobTitle.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(resume.jobTitle.trim(), style: jobTitleStyle),
            ],
            pw.SizedBox(height: 6),
            if (resume.summary.trim().isNotEmpty) ...[
              sectionTitle('Profile'),
              _headerSidebarMaybeHighlight(
                highlight: highlightSummary,
                child: pw.Text(
                  resume.summary.trim(),
                  style: style(
                    ResumeFontWeight.w400,
                    detailPt,
                    bodyInk,
                    lineSpacing:
                        ResumeTypography.bodyPdfLineSpacingFor(detailPt),
                  ),
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
                  if (item.isBlank) return null;
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
                      sectionTitle('Experience'),
                      for (var i = 0; i < experiences.length; i++)
                        ...datedEntry(
                          dates: educationDateRangeLabel(
                            experiences[i].startDate,
                            experiences[i].endDate,
                          ),
                          organisation: experiences[i].company.trim(),
                          title: experiences[i].role.trim().ifEmpty('Role'),
                          details: [
                            for (final bullet in _workBulletLines(
                              experiences[i],
                            ))
                              bulletLine(
                                bullet,
                                highlight:
                                    highlightedBulletsByExperience[i]
                                        ?.contains(bullet) ??
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
                        ...datedEntry(
                          dates: educationDateRangeLabel(
                            item.startDate,
                            item.endDate,
                          ),
                          organisation: item.institution.trim(),
                          title: item.degree.trim().ifEmpty(
                            item.institution.trim().ifEmpty('Education'),
                          ),
                          details: [
                            if (educationDetailLine(item).isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 3),
                                child: pw.Text(
                                  educationDetailLine(item),
                                  style: detailStyle,
                                ),
                              ),
                          ],
                        ),
                    ];
                  case ResumeBuilderSectionIds.projects:
                    if (projects.isEmpty) return null;
                    return [
                      sectionTitle('Projects'),
                      for (final item in projects)
                        ...datedEntry(
                          dates: '',
                          organisation: item.subtitle.trim(),
                          title: item.title.trim().ifEmpty('Project'),
                          details: [
                            for (final line in _projectBulletLinesPdf(item))
                              bulletLine(line),
                          ],
                        ),
                    ];
                }
                return null;
              },
            ),
          ];

          return [
            for (final widget in body)
              _slateSidebarMainPad(
                widget,
                sidebarPageCount: sidebarPageCount,
              ),
          ];
        },
      ),
    );

    // MultiPage only creates pages for main-column content. If expertise still
    // needs more sidebar pages, append them here (avoids trailing blank pages
    // from unconditional NewPage after a long body).
    final multiPageCount =
        document.document.pdfPageList.pages.length - pagesBefore;
    for (var i = multiPageCount; i < sidebarPageCount; i++) {
      final slice = sidebarSlices[i];
      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(
              _slateSidebarMainLeftPt,
              _slateSidebarPageTopPt,
              _slateSidebarMainRightPt,
              _slateSidebarPageBottomPt,
            ),
            buildBackground: (context) => railBackground(slice),
          ),
          build: (context) => pw.SizedBox(),
        ),
      );
    }
  }
}
