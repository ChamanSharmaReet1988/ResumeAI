part of 'package:resume_app/core/services/resume_services.dart';

/// Timeline Profile: navy header band with a circular photo, a light sidebar
/// (contact + skills) and a main column whose sections sit on a vertical
/// timeline. Skills paginate across sidebar pages until every skill is shown;
/// after that, later pages use the full page width with no sidebar.
const double _timelineProfileSidebarWidthPt = 200.0;
const double _timelineProfileSidebarInsetPt = 22.0;
const double _timelineProfileBandHeightPt = 150.0;
const double _timelineProfileAvatarSizePt = 126.0;
const double _timelineProfileMainLeftPt = 230.0;
const double _timelineProfileMainRightPt = 36.0;
/// Extra left inset while the sidebar is present so body text clears it.
const double _timelineProfileSidebarContentInsetPt =
    _timelineProfileMainLeftPt - _timelineProfileMainRightPt;
const double _timelineProfileTopPt = 36.0;
const double _timelineProfileBottomPt = 34.0;
const double _timelineProfileBadgeSizePt = 18.0;
const double _timelineProfileDotSizePt = 7.0;
const double _timelineProfileRuleX = _timelineProfileMainLeftPt + 9;
const double _timelineProfileFullWidthRuleX = _timelineProfileMainRightPt + 9;

/// One page of sidebar content: contact (page 1) and/or a skill chunk.
class _TimelineProfilePageSlice {
  const _TimelineProfilePageSlice({
    required this.showContact,
    required this.showSkillsHeading,
    required this.skills,
  });

  final bool showContact;
  final bool showSkillsHeading;
  final List<String> skills;
}

/// Pads main-column widgets beside the sidebar while skill pages remain;
/// later pages use the full width.
pw.Widget _timelineProfileMainPad(
  pw.Widget child, {
  required int sidebarPageCount,
}) => pw.DelayedWidget(
  build: (context) => pw.Padding(
    padding: pw.EdgeInsets.only(
      left: context.pageNumber <= sidebarPageCount
          ? _timelineProfileSidebarContentInsetPt
          : 0,
    ),
    child: child,
  ),
);

List<_TimelineProfilePageSlice> _timelineProfilePageSlices({
  required List<String> skills,
  required List<String> contacts,
  required double detailPt,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) {
  final railTextWidth =
      _timelineProfileSidebarWidthPt - _timelineProfileSidebarInsetPt * 2;

  // Page 1 sidebar starts below the overlapping avatar.
  final page1SidebarTop =
      _timelineProfileBandHeightPt + _timelineProfileAvatarSizePt / 2 + 6;
  final page1Available =
      pageFormat.height - page1SidebarTop - _timelineProfileBottomPt;
  final continuedAvailable =
      pageFormat.height - _timelineProfileTopPt - _timelineProfileBottomPt;

  const headingBlock = 14.0 + 7.0 + 13.0 + 4.0 + 1.0;
  final contactLineHeight =
      (detailPt - 0.5) * ResumeTypography.bodyTextLineHeight;
  // Links wrap to the next line (no shrink), so budget height per contact.
  double contactItemHeight(String value) {
    final lines = _slateSidebarEstimatedSkillLines(
      value,
      detailPt - 0.5,
      railTextWidth - 11,
    );
    return lines * contactLineHeight + 5;
  }

  final contactBlock = contacts.isEmpty
      ? 0.0
      : headingBlock +
            contacts.fold<double>(
              0,
              (sum, value) => sum + contactItemHeight(value),
            );

  double skillHeight(String item) {
    final lines = _slateSidebarEstimatedSkillLines(
      item,
      detailPt - 0.5,
      railTextWidth - 11,
    );
    return (lines * (detailPt - 0.5) * ResumeTypography.bodyTextLineHeight) +
        7;
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
      _TimelineProfilePageSlice(
        showContact: true,
        showSkillsHeading: false,
        skills: <String>[],
      ),
    ];
  }

  final firstPageSkillsAvailable =
      page1Available - contactBlock - headingBlock - 20;
  final continuedPageSkillsAvailable = continuedAvailable - headingBlock - 12;

  final slices = <_TimelineProfilePageSlice>[];
  var index = 0;

  final firstChunk = takeChunk(
    skills.skip(index),
    firstPageSkillsAvailable > 0 ? firstPageSkillsAvailable : 0,
  );
  index += firstChunk.length;
  slices.add(
    _TimelineProfilePageSlice(
      showContact: true,
      showSkillsHeading: firstChunk.isNotEmpty,
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
      _TimelineProfilePageSlice(
        showContact: false,
        showSkillsHeading: true,
        skills: chunk,
      ),
    );
  }

  return slices;
}

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
    // Body copy is black on every template; greys stay for dates and rails.
    final bodyInk = _pdfRgb(ResumeTypography.atsStructuredBodyTextColor);
    final ruleColor = _pdfRgb(resume.timelineProfileRuleColor);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    // Body copy renders at the slider size; only dated/rail lines step down.
    final detailPt = bodyPt;

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
      bodyInk,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final skills = resume.skillsLinesForDisplay;
    final contacts = [
      resume.phone.trim(),
      resume.email.trim(),
      resume.location.trim(),
      resume.website.trim(),
      resume.linkedinLink.trim(),
      resume.githubLink.trim(),
    ].where((value) => value.isNotEmpty).toList();

    final sidebarSlices = _timelineProfilePageSlices(
      skills: skills,
      contacts: contacts,
      detailPt: detailPt,
    );
    final sidebarPageCount = sidebarSlices.length;

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
                    textAlign: pw.TextAlign.left,
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
        for (final detail in details.skip(1)) onTimeline(detail, dot: false),
        pw.SizedBox(height: 12),
      ];
    }

    pw.Widget sidebarPanel(_TimelineProfilePageSlice slice) {
      final headingStyle = style(
        ResumeFontWeight.w700,
        13,
        titleColor,
        letterSpacing: 1.1,
      );
      final itemStyle = style(ResumeFontWeight.w400, detailPt - 0.5, mutedColor);

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

      pw.Widget item(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 4,
              height: 4,
              margin: const pw.EdgeInsets.only(top: 3, right: 7),
              decoration: pw.BoxDecoration(
                color: bandColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: _headerSidebarMaybeHighlight(
                highlight: highlightedSkills.contains(text),
                child: pw.Text(text, style: itemStyle),
              ),
            ),
          ],
        ),
      );

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (slice.showContact && contacts.isNotEmpty) ...[
            heading('Contact'),
            for (final value in contacts) item(value),
          ],
          if (slice.showSkillsHeading) heading('Skills'),
          for (final skill in slice.skills) item(skill),
        ],
      );
    }

    pw.Widget pageBackground({
      required bool firstPage,
      required bool hasSidebar,
      required _TimelineProfilePageSlice? slice,
    }) {
      final ruleX = hasSidebar
          ? _timelineProfileRuleX
          : _timelineProfileFullWidthRuleX;
      final sidebarTop = firstPage ? _timelineProfileBandHeightPt : 0.0;
      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            if (hasSidebar)
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
            pw.Positioned(
              left: ruleX,
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
                    _timelineProfileAvatarSizePt / 2 -
                    20,
                child: pw.Container(
                  width: _timelineProfileAvatarSizePt,
                  height: _timelineProfileAvatarSizePt,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.white, width: 5),
                  ),
                  child: profileImage != null
                      ? pw.ClipOval(
                          child: pw.Image(profileImage, fit: pw.BoxFit.cover),
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
            ],
            if (hasSidebar && slice != null)
              pw.Positioned(
                left: _timelineProfileSidebarInsetPt,
                top: firstPage
                    ? _timelineProfileBandHeightPt +
                          _timelineProfileAvatarSizePt / 2 +
                          6
                    : _timelineProfileTopPt,
                bottom: _timelineProfileBottomPt,
                child: pw.SizedBox(
                  width:
                      _timelineProfileSidebarWidthPt -
                      _timelineProfileSidebarInsetPt * 2,
                  child: pw.ClipRect(child: sidebarPanel(slice)),
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
            _timelineProfileMainRightPt,
            _timelineProfileTopPt,
            _timelineProfileMainRightPt,
            _timelineProfileBottomPt,
          ),
          buildBackground: (context) {
            final page = context.pageNumber;
            final hasSidebar = page <= sidebarPageCount;
            final slice = hasSidebar ? sidebarSlices[page - 1] : null;
            return pageBackground(
              firstPage: page == 1,
              hasSidebar: hasSidebar,
              slice: slice,
            );
          },
        ),
        build: (context) {
          final body = <pw.Widget>[
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
                    textAlign: pw.TextAlign.left,
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
                  if (item.isBlank) return null;
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
                          title: experiences[i].company.trim().ifEmpty(
                            'Company',
                          ),
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
                                    highlightedBulletsByExperience[i]
                                        ?.contains(line) ??
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
                            if (educationDetailLine(item).isNotEmpty)
                              pw.Text(
                                educationDetailLine(item),
                                style: entryTitleStyle,
                              ),
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
          ];
          return [
            for (final widget in body)
              _timelineProfileMainPad(
                widget,
                sidebarPageCount: sidebarPageCount,
              ),
          ];
        },
      ),
    );

    // Append skill-only sidebar pages when MultiPage did not create enough.
    final multiPageCount =
        document.document.pdfPageList.pages.length - pagesBefore;
    for (var i = multiPageCount; i < sidebarPageCount; i++) {
      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(
              _timelineProfileMainLeftPt,
              _timelineProfileTopPt,
              _timelineProfileMainRightPt,
              _timelineProfileBottomPt,
            ),
            buildBackground: (context) => pageBackground(
              firstPage: false,
              hasSidebar: true,
              slice: sidebarSlices[i],
            ),
          ),
          build: (context) => pw.SizedBox(),
        ),
      );
    }
  }
}
