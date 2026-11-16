part of 'package:resume_app/core/services/resume_services.dart';

/// Summit, Folio, Beacon and Vertex: one body, four page layouts.
///
/// Summit and Folio flow in a single column. Beacon and Vertex keep contact and
/// skills in a side column that paginates like Slate Sidebar's rail: the column
/// is drawn with the page background, the body stays clear of it while it has
/// content, and later pages use the full width.
extension _ResumePdfProfessionalPages on ResumePdfService {
  void _addProfessionalTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final kind = resume.template.userFacingTemplate;
    final accent = _pdfRgb(resume.creativeAccentColor);
    final onBand = _pdfRgb(resume.corporateColorPreset.headerOnColor);
    final wash = _topPickWash(accent, 0.1);
    final softRule = _topPickWash(accent, 0.3);
    // Body copy is black on every template; greys stay for dates and rails.
    final bodyInk = _pdfRgb(ResumeTypography.atsStructuredBodyTextColor);
    const muted = PdfColor.fromInt(0xFF5B6168);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final hasRail =
        kind == ResumeTemplate.beacon || kind == ResumeTemplate.vertex;

    pw.TextStyle style(
      int weight,
      double size,
      PdfColor color, {
      double? lineSpacing,
      double letterSpacing = 0,
    }) {
      final base = garamondPdfTextStyle(
        fonts,
        weight,
        fontSize: size,
        color: color,
        lineSpacing: lineSpacing,
      );
      return letterSpacing == 0
          ? base
          : base.copyWith(letterSpacing: letterSpacing);
    }

    final bodyStyle = style(
      ResumeFontWeight.w400,
      bodyPt,
      bodyInk,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
    );
    final metaStyle = style(ResumeFontWeight.w400, bodyPt - 0.5, muted);
    final roleStyle = style(ResumeFontWeight.w700, bodyPt + 0.5, bodyInk);

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final name = _displayName(resume);
    final jobTitle = resume.jobTitle.trim();
    final contactLine = [
      resume.email,
      resume.phone,
      resume.location,
      resume.website,
      resume.linkedinLink,
      resume.githubLink,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).join('  ·  ');

    // No placeholder when there is no photo: the header closes up instead.
    pw.Widget photo(
      pw.MemoryImage source,
      double size, {
      bool rounded = false,
      double ring = 0,
    }) {
      final image = pw.Image(source, fit: pw.BoxFit.cover);
      final clipped = pw.SizedBox(
        width: size,
        height: size,
        child: rounded
            ? pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: image,
              )
            : pw.ClipOval(child: image),
      );
      if (ring == 0) return clipped;
      return pw.Container(
        width: size + ring * 2,
        height: size + ring * 2,
        alignment: pw.Alignment.center,
        decoration: const pw.BoxDecoration(
          color: PdfColors.white,
          shape: pw.BoxShape.circle,
        ),
        child: clipped,
      );
    }

    pw.Widget sectionTitle(String heading) {
      return switch (kind) {
        ResumeTemplate.summit => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 7),
          child: pw.Row(
            children: [
              pw.Text(heading, style: style(ResumeFontWeight.w700, 14, accent)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: pw.Container(height: 1, color: softRule)),
            ],
          ),
        ),
        ResumeTemplate.beacon => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 7),
          child: pw.Row(
            children: [
              pw.Container(width: 9, height: 9, color: accent),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  heading.toUpperCase(),
                  style: style(
                    ResumeFontWeight.w700,
                    11.5,
                    bodyInk,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        _ => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 7),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(heading, style: style(ResumeFontWeight.w700, 14, accent)),
              pw.SizedBox(height: 3),
              pw.Row(
                children: [
                  pw.Container(width: 30, height: 2.4, color: accent),
                  pw.Expanded(
                    child: pw.Container(height: 0.6, color: softRule),
                  ),
                ],
              ),
            ],
          ),
        ),
      };
    }

    /// Folio sets each block beside the margin label; the label sits on the
    /// first block only, so a page break can fall between blocks.
    pw.Widget folioRow(pw.Widget child, {String? label}) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: kFolioLabelPt,
          child: label == null
              ? pw.SizedBox()
              : pw.Text(
                  label.toUpperCase(),
                  style: style(
                    ResumeFontWeight.w700,
                    9.5,
                    accent,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
        pw.SizedBox(width: kFolioGutterPt),
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.only(left: kFolioGutterPt),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: softRule, width: 0.8),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );

    List<pw.Widget> section(String heading, List<pw.Widget> blocks) {
      if (blocks.isEmpty) return const [];
      if (kind != ResumeTemplate.folio) {
        return _keepHeadingWithFirstBlock([sectionTitle(heading), ...blocks]);
      }
      return [
        pw.SizedBox(height: 14),
        for (var i = 0; i < blocks.length; i++)
          folioRow(blocks[i], label: i == 0 ? heading : null),
      ];
    }

    pw.Widget bullet(String text, {bool highlight = false}) =>
        _headerSidebarMaybeHighlight(
          highlight: highlight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: 11, child: pw.Text('•', style: bodyStyle)),
                pw.Expanded(child: pw.Text(text, style: bodyStyle)),
              ],
            ),
          ),
        );

    /// One entry as separate blocks, so a page can break between its bullets.
    List<pw.Widget> entry({
      required String title,
      required String organisation,
      required String dates,
      required List<pw.Widget> details,
    }) {
      final dateStyle = style(
        ResumeFontWeight.w600,
        bodyPt - 0.5,
        kind == ResumeTemplate.beacon ? muted : accent,
      );
      return [
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text(title, style: roleStyle)),
                  if (dates.isNotEmpty) ...[
                    pw.SizedBox(width: 10),
                    pw.Text(dates, style: dateStyle),
                  ],
                ],
              ),
              if (organisation.isNotEmpty)
                pw.Text(organisation, style: metaStyle),
              if (details.isNotEmpty) details.first,
            ],
          ),
        ),
        ...details.skip(1),
        pw.SizedBox(height: 9),
      ];
    }

    pw.Widget chip(String label) => _headerSidebarMaybeHighlight(
      highlight: highlightedSkills.contains(label),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
          color: wash,
          borderRadius: pw.BorderRadius.circular(9),
        ),
        child: pw.Text(label, style: bodyStyle),
      ),
    );

    /// Summit and Folio skills: chips, in small groups so they can break.
    List<pw.Widget> flowSkills() {
      pw.Widget chips(Iterable<String> labels) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [for (final label in labels) chip(label)],
        ),
      );
      List<pw.Widget> chunked(List<String> labels) => [
        for (var i = 0; i < labels.length; i += 12)
          chips(labels.skip(i).take(12)),
      ];
      if (!resume.showCategorisedSkills) {
        return chunked(resume.skillsLinesForDisplay);
      }
      return [
        for (final group in resume.skillGroupsForResume) ...[
          if (group.heading.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(group.heading.trim(), style: roleStyle),
            ),
          ...chunked(
            group.skills
                .map((skill) => skill.trim())
                .where((skill) => skill.isNotEmpty)
                .toList(),
          ),
        ],
      ];
    }

    List<pw.Widget> summaryBlocks() {
      final summary = resume.summary.trim();
      if (summary.isEmpty) return const [];
      return section('Profile', [
        _headerSidebarMaybeHighlight(
          highlight: highlightSummary,
          child: pw.Text(summary, style: bodyStyle),
        ),
      ]);
    }

    List<pw.Widget> bodySections() => _pdfBodySectionsInBuilderOrder(
      resume,
      exclude: hasRail ? {ResumeBuilderSectionIds.skills} : const {},
      buildSection: (id) {
        final customIndex = ResumeBuilderSectionIds.customIndex(id);
        if (customIndex != null) {
          if (customIndex < 0 || customIndex >= resume.customSections.length) {
            return null;
          }
          final item = resume.customSections[customIndex];
          if (item.isBlank) return null;
          return section(
            item.title.ifEmpty('Custom section'),
            _pwCustomSectionBodyWidgets(
              item,
              garamond: fonts,
              bodyFontPt: bodyPt,
              accentStripGaramondBody: true,
              experienceEntry: (items) => [
                for (final work in items)
                  ...entry(
                    title: work.role.trim().ifEmpty('Role'),
                    organisation: work.company.trim(),
                    dates: educationDateRangeLabel(
                      work.startDate,
                      work.endDate,
                    ),
                    details: [
                      for (final line in _workBulletLines(work)) bullet(line),
                    ],
                  ),
              ],
            ),
          );
        }
        switch (id) {
          case ResumeBuilderSectionIds.work:
            return section(
              resume.sectionHeading(id, 'Work Experience'),
              [
                for (var i = 0; i < experiences.length; i++)
                  ...entry(
                    title: experiences[i].role.trim().ifEmpty('Role'),
                    organisation: experiences[i].company.trim(),
                    dates: educationDateRangeLabel(
                      experiences[i].startDate,
                      experiences[i].endDate,
                    ),
                    details: [
                      for (final line in _workBulletLines(experiences[i]))
                        bullet(
                          line,
                          highlight:
                              highlightedBulletsByExperience[i]?.contains(
                                line,
                              ) ??
                              false,
                        ),
                    ],
                  ),
              ],
            );
          case ResumeBuilderSectionIds.education:
            return section(resume.sectionHeading(id, 'Education'), [
              for (final item in education)
                ...entry(
                  title: item.degree.trim().ifEmpty(
                    item.institution.trim().ifEmpty('Education'),
                  ),
                  organisation: item.degree.trim().isEmpty
                      ? ''
                      : item.institution.trim(),
                  dates: educationDateRangeLabel(item.startDate, item.endDate),
                  details: [
                    if (educationDetailLine(item).isNotEmpty)
                      pw.Text(educationDetailLine(item), style: bodyStyle),
                  ],
                ),
            ]);
          case ResumeBuilderSectionIds.skills:
            return section(
              resume.sectionHeading(id, 'Skills'),
              flowSkills(),
            );
          case ResumeBuilderSectionIds.projects:
            return section(resume.sectionHeading(id, 'Projects'), [
              for (final item in projects)
                ...entry(
                  title: item.title.trim().ifEmpty('Project'),
                  organisation: item.subtitle.trim(),
                  dates: '',
                  details: [
                    for (final line in _projectBulletLinesPdf(item))
                      bullet(line),
                  ],
                ),
            ]);
        }
        return null;
      },
    );

    pw.Widget nameBlock(PdfColor nameColor, PdfColor titleColor) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(name, style: style(ResumeFontWeight.w700, 28, nameColor)),
        if (jobTitle.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              jobTitle,
              style: style(ResumeFontWeight.w400, 13, titleColor),
            ),
          ),
      ],
    );

    if (!hasRail) {
      final isSummit = kind == ResumeTemplate.summit;
      document.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: isSummit
                ? const pw.EdgeInsets.fromLTRB(40, kSummitPageTopPt, 40, 36)
                : const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
            buildBackground: isSummit
                ? (context) => pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Column(
                      children: [
                        pw.Container(
                          height: context.pageNumber == 1 ? kSummitBandPt : 6,
                          width: double.infinity,
                          color: accent,
                        ),
                        if (context.pageNumber == 1)
                          pw.Container(
                            height: kSummitStripPt,
                            width: double.infinity,
                            color: wash,
                          ),
                        pw.Expanded(child: pw.SizedBox()),
                      ],
                    ),
                  )
                : null,
          ),
          build: (context) => [
            if (isSummit) ...[
              pw.SizedBox(
                height: kSummitBandPt - kSummitPageTopPt,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (profileImage != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 16),
                        child: photo(profileImage, kSummitPhotoPt - 4, ring: 2),
                      ),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 8),
                        child: nameBlock(onBand, onBand),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(
                height: kSummitStripPt,
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    contactLine,
                    style: style(ResumeFontWeight.w400, 9.5, bodyInk),
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
            ] else ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(child: nameBlock(bodyInk, accent)),
                  if (profileImage != null) ...[
                    pw.SizedBox(width: 14),
                    photo(profileImage, kFolioPhotoPt, rounded: true),
                  ],
                ],
              ),
              pw.SizedBox(height: 9),
              pw.Container(height: 2.2, color: accent),
              if (contactLine.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text(
                    contactLine,
                    style: style(ResumeFontWeight.w400, 9.5, bodyInk),
                  ),
                ),
            ],
            ...summaryBlocks(),
            ...bodySections(),
          ],
        ),
      );
      return;
    }

    // Beacon and Vertex: contact and skills in the side column.
    final isBeacon = kind == ResumeTemplate.beacon;
    final railTextWidth = isBeacon
        ? kBeaconRailPt - kBeaconRailInsetPt * 2
        : kVertexSidePt;
    final railLeft = isBeacon
        ? kResumePageWidthPt - kBeaconRailPt + kBeaconRailInsetPt
        : kResumePageWidthPt - kProfessionalPageSidePt - kVertexSidePt;
    final bodyRightInset = isBeacon
        ? kBeaconRailPt + kProfessionalColumnGapPt - kProfessionalPageSidePt
        : kVertexSidePt + kProfessionalColumnGapPt;
    final skills = _slateSidebarSkillLines(resume);
    final contacts = <(String, String)>[
      ('Phone', resume.phone.trim()),
      ('Email', resume.email.trim()),
      ('Address', resume.location.trim()),
      ('Website', resume.website.trim()),
      ('LinkedIn', resume.linkedinLink.trim()),
      ('GitHub', resume.githubLink.trim()),
    ].where((entry) => entry.$2.isNotEmpty).toList();
    final slices = _slateSidebarPageSlices(
      skills: skills,
      contactCount: contacts.isEmpty ? 1 : contacts.length,
      detailPt: bodyPt,
      railTextWidth: railTextWidth,
      avatarSizePt: isBeacon && profileImage != null ? kBeaconPhotoPt : 0,
      firstPageReservedPt: isBeacon ? 0 : kVertexBodyTopPt - kProfessionalPageTopPt,
    );

    pw.Widget railHeading(String title) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 22, bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accent, width: 0.8)),
      ),
      child: pw.Text(title, style: style(ResumeFontWeight.w700, 13, accent)),
    );

    pw.Widget railPanel(_SlateSidebarPageSlice slice) {
      final railLabel = style(ResumeFontWeight.w700, bodyPt - 1, bodyInk);
      final railValue = style(ResumeFontWeight.w400, bodyPt - 1, bodyInk);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (slice.showIdentity) ...[
            if (isBeacon && profileImage != null)
              pw.Center(child: photo(profileImage, kBeaconPhotoPt)),
            railHeading('Contact'),
            if (contacts.isEmpty)
              pw.Text('Add contact details', style: railValue)
            else
              for (final (label, value) in contacts) ...[
                pw.Text(label, style: railLabel),
                pw.SizedBox(height: 1),
                pw.Text(value, style: railValue),
                pw.SizedBox(height: 7),
              ],
          ],
          if (slice.showExpertiseHeading)
            railHeading(
              resume.sectionHeading(ResumeBuilderSectionIds.skills, 'Skills'),
            ),
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
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    resume.showCategorisedSkills ? skill : '• $skill',
                    style: railValue,
                  ),
                ),
              ),
        ],
      );
    }

    pw.Widget pageArt(int pageNumber, _SlateSidebarPageSlice? slice) =>
        pw.FullPage(
          ignoreMargins: true,
          child: pw.Stack(
            children: [
              if (isBeacon) ...[
                if (slice != null)
                  pw.Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: pw.Container(width: kBeaconRailPt, color: wash),
                  ),
                pw.Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: pw.Container(height: 6, color: accent),
                ),
              ] else if (pageNumber == 1)
                pw.Positioned.fill(
                  child: pw.CustomPaint(
                    size: const PdfPoint(
                      kResumePageWidthPt,
                      kResumePageHeightPt,
                    ),
                    painter: (canvas, size) => _paintPageArtFacets(
                      canvas,
                      size,
                      kVertexWedgeFacets,
                      accent,
                    ),
                  ),
                )
              else
                pw.Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: pw.Container(height: 6, color: accent),
                ),
              if (slice != null)
                pw.Positioned(
                  left: railLeft,
                  top: pageNumber == 1 && !isBeacon
                      ? kVertexBodyTopPt
                      : kProfessionalPageTopPt,
                  bottom: kProfessionalPageBottomPt,
                  child: pw.SizedBox(
                    width: railTextWidth,
                    child: pw.ClipRect(child: railPanel(slice)),
                  ),
                ),
            ],
          ),
        );

    pw.Widget bodyPad(pw.Widget child) => pw.DelayedWidget(
      build: (context) => pw.Padding(
        padding: pw.EdgeInsets.only(
          right: context.pageNumber <= slices.length ? bodyRightInset : 0,
        ),
        child: child,
      ),
    );

    final pagesBefore = document.document.pdfPageList.pages.length;
    const pageMargin = pw.EdgeInsets.fromLTRB(
      kProfessionalPageSidePt,
      kProfessionalPageTopPt,
      kProfessionalPageSidePt,
      kProfessionalPageBottomPt,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pageMargin,
          buildBackground: (context) => pageArt(
            context.pageNumber,
            context.pageNumber <= slices.length
                ? slices[context.pageNumber - 1]
                : null,
          ),
        ),
        build: (context) => [
          if (isBeacon)
            bodyPad(nameBlock(bodyInk, accent))
          else
            pw.SizedBox(
              height: kVertexBodyTopPt - kProfessionalPageTopPt,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: nameBlock(onBand, onBand)),
                  if (profileImage != null) ...[
                    pw.SizedBox(width: 14),
                    photo(profileImage, kVertexPhotoPt - 4, ring: 2),
                  ],
                ],
              ),
            ),
          for (final widget in [...summaryBlocks(), ...bodySections()])
            bodyPad(widget),
        ],
      ),
    );

    // MultiPage only makes pages for body content. If skills need more of the
    // side column than the body has pages, add them here.
    final multiPageCount =
        document.document.pdfPageList.pages.length - pagesBefore;
    for (var i = multiPageCount; i < slices.length; i++) {
      final slice = slices[i];
      final pageNumber = i + 1;
      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: pageMargin,
            buildBackground: (context) => pageArt(pageNumber, slice),
          ),
          build: (context) => pw.SizedBox(),
        ),
      );
    }
  }
}
