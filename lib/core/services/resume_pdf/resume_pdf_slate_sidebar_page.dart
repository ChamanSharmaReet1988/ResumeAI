part of 'package:resume_app/core/services/resume_services.dart';

/// Slate Sidebar: dark full-height left rail (photo, contact, expertise and
/// short list sections) with a large nameplate and dated two-column rows in
/// the main column.
const double _slateSidebarRailWidthPt = 196.0;
const double _slateSidebarRailInsetPt = 24.0;
const double _slateSidebarMainLeftPt = _slateSidebarRailWidthPt + 28.0;
const double _slateSidebarMainRightPt = 34.0;
const double _slateSidebarPageTopPt = 40.0;
const double _slateSidebarPageBottomPt = 36.0;
const double _slateSidebarAvatarSizePt = 104.0;
const double _slateSidebarMetaColumnPt = 104.0;
const double _slateSidebarColumnGapPt = 14.0;
const int _slateSidebarMaxRailSkills = 14;

/// Custom sections with these titles are short lists that read best in the
/// rail, like the Language and Awards blocks of the reference design.
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
    const onRail = PdfColors.white;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final detailPt = bodyPt - 1.5;

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
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final languageSection = _classicSidebarLanguagesSection(resume);
    final languageLines = _classicSidebarLanguageLines(resume);
    final mainCustomSections = resume.visibleCustomSections
        .where(
          (item) =>
              !_slateSidebarIsRailSection(item) &&
              !identical(item, languageSection),
        )
        .toList();

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

    pw.Widget railPanel() {
      final railHeading = style(ResumeFontWeight.w700, 15, onRail);
      final railLabel = style(ResumeFontWeight.w700, detailPt, onRail);
      final railValue = style(ResumeFontWeight.w400, detailPt - 0.5, onRail);
      final railItem = style(ResumeFontWeight.w400, detailPt, onRail);

      // Heading rule runs to the rail's right edge, like the reference.
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

      final contacts = <(String, String)>[
        ('Phone', resume.phone.trim()),
        ('Email', resume.email.trim()),
        ('Address', resume.location.trim()),
        ('Website', resume.website.trim()),
        ('LinkedIn', resume.linkedinLink.trim()),
        ('GitHub', resume.githubLink.trim()),
      ].where((entry) => entry.$2.isNotEmpty).toList();

      final skills = resume.skillsLinesForDisplay
          .take(_slateSidebarMaxRailSkills)
          .toList();
      final railSections = resume.visibleCustomSections
          .where(_slateSidebarIsRailSection)
          .where((item) => !identical(item, languageSection))
          .toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // The rail column runs to the rail's right edge (so heading rules
          // do too); pad the photo by the left inset to centre it in the rail.
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: _slateSidebarRailInsetPt),
            child: pw.Center(child: avatar()),
          ),
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
          if (languageLines.isNotEmpty) ...[
            heading(
              languageSection?.title.trim().isNotEmpty == true
                  ? languageSection!.title.trim()
                  : 'Languages',
            ),
            for (final line in languageLines)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Text(line, style: railItem),
              ),
          ],
          if (skills.isNotEmpty) ...[
            heading('Expertise'),
            for (final skill in skills)
              _headerSidebarMaybeHighlight(
                highlight: highlightedSkills.contains(skill),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(skill, style: railItem),
                ),
              ),
          ],
          for (final section in railSections) ...[
            heading(section.title.trim()),
            for (final line in _slateSidebarRailSectionLines(section))
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Text(line, style: railItem),
              ),
          ],
        ],
      );
    }

    final rail = railPanel();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _slateSidebarMainLeftPt,
            _slateSidebarPageTopPt,
            _slateSidebarMainRightPt,
            _slateSidebarPageBottomPt,
          ),
          buildBackground: (context) => pw.FullPage(
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
                // Rail content only on the first page; later pages keep the
                // colored band so the layout reads as one document.
                if (context.pageNumber == 1)
                  pw.Positioned(
                    left: _slateSidebarRailInsetPt,
                    top: _slateSidebarPageTopPt,
                    bottom: _slateSidebarPageBottomPt,
                    child: pw.SizedBox(
                      width: _slateSidebarRailWidthPt - _slateSidebarRailInsetPt,
                      child: pw.ClipRect(child: rail),
                    ),
                  ),
              ],
            ),
          ),
        ),
        build: (context) => [
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
                  mutedColor,
                  lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
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
                if (!mainCustomSections.contains(item)) {
                  return null;
                }
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
                                  highlightedBulletsByExperience[i]?.contains(
                                    bullet,
                                  ) ??
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
                          if (item.score.trim().isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3),
                              child: pw.Text(
                                item.score.trim(),
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
        ],
      ),
    );
  }
}
