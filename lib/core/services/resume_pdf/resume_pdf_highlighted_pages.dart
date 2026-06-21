part of 'package:resume_app/core/services/resume_services.dart';

extension _ResumePdfHighlightedTemplatePages on ResumePdfService {
  pw.Widget _continuedPageTopGap(pw.Context context) =>
      context.pageNumber > 1 ? pw.SizedBox(height: 40) : pw.SizedBox();

  void _addHighlightedCorporateTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final headerContactFontPt = bodyPt;
    final sectionTitleColor = _corporateTitlePdf(resume);
    final headerColor = _corporateHeaderPdf(resume);
    final headerOnColor = _corporateHeaderOnPdf(resume);
    final lineColor = PdfColor.fromHex('#D7DCE2');
    final highlightColor = PdfColor.fromHex('#FFE67A');
    final headerContactLines = _corporateHeaderContactLines(
      _resumeContactItems(resume),
    );
    const avatarSize = 95.0;
    const avatarBorderWidth = 2.1;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(0, 0, 0, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Container(
            color: headerColor,
            padding: pw.EdgeInsets.fromLTRB(
              ResumeTypography.corporateHeaderHorizontalInset,
              28,
              ResumeTypography.corporateHeaderHorizontalInset,
              26,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: avatarSize,
                  height: avatarSize,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: headerOnColor,
                      width: avatarBorderWidth,
                    ),
                  ),
                  child: pw.Text(
                    _resumeInitials(resume),
                    style: darkHeaderInitialsGaramondPdfStyle(
                      garamond,
                      headerOnColor,
                    ),
                  ),
                ),
                pw.SizedBox(width: 25),
                pw.Expanded(
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _highlightedCorporateNameText(
                        _displayName(resume).toUpperCase(),
                        headerOnColor,
                        garamond,
                      ),
                      if (headerContactLines.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        for (
                          var index = 0;
                          index < headerContactLines.length;
                          index++
                        )
                          pw.Padding(
                            padding: pw.EdgeInsets.only(
                              top: index == 0 ? 0 : 3,
                            ),
                            child: _pdfContactText(
                              headerContactLines[index],
                              style: garamondPdfTextStyle(
                                garamond,
                                ResumeTypography.darkHeaderContactWeight,
                                fontSize: headerContactFontPt,
                                color: headerOnColor,
                                lineSpacing: ResumeTypography
                                    .darkHeaderContactPdfLineSpacingFor(
                                  headerContactFontPt,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          ..._highlightedCorporateSummarySectionWidgets(
            resume.summary.trim(),
            lineColor,
            sectionTitleColor,
            highlightColor,
            garamond,
            bodyPt,
            highlightSummary: highlightSummary,
          ),
          if (resume.includeWorkInResume)
            ..._highlightedCorporateExperienceSectionWidgets(
              resume.visibleWorkExperiences,
              highlightedBulletsByExperience,
              lineColor,
              sectionTitleColor,
              highlightColor,
              garamond,
              bodyPt,
            ),
          if (resume.includeEducationInResume)
            ..._highlightedCorporateEducationSectionWidgets(
              resume.visibleEducation,
              lineColor,
              sectionTitleColor,
              garamond,
              bodyPt,
            ),
          if (resume.includeSkillsInResume)
            ..._highlightedCorporateSkillsSectionWidgets(
              _skillsForDisplay(resume),
              highlightedSkills,
              lineColor,
              sectionTitleColor,
              highlightColor,
              garamond,
              bodyPt,
            ),
          if (resume.includeProjectsInResume)
            ..._highlightedCorporateProjectsSectionWidgets(
              resume.visibleProjects,
              lineColor,
              sectionTitleColor,
              garamond,
              bodyPt,
            ),
          for (final item in resume.visibleCustomSections)
            ..._highlightedCorporateCustomSectionWidgets(
              item,
              lineColor,
              sectionTitleColor,
              garamond,
              bodyPt,
            ),
        ],
      ),
    );
  }

  pw.Widget _highlightedCorporateNameText(
    String value,
    PdfColor onColor,
    GaramondPdfFonts garamond,
  ) {
    return pw.Text(
      value,
      style: garamondPdfTextStyle(
        garamond,
        ResumeTypography.darkHeaderNameWeight,
        fontSize: ResumeTypography.darkHeaderNamePt,
        color: onColor,
      ),
    );
  }

  List<pw.Widget> _highlightedCorporateSectionPrefixWidgets({
    required String title,
    required PdfColor sectionTitleColor,
    required GaramondPdfFonts garamond,
  }) {
    return [
      pw.Padding(
        padding: pw.EdgeInsets.fromLTRB(
          ResumeTypography.corporateBodyHorizontalInset,
          0,
          ResumeTypography.corporateBodyHorizontalInset,
          0,
        ),
        child: _corporateHeadingText(
          title.toUpperCase(),
          color: sectionTitleColor,
          garamond: garamond,
        ),
      ),
      pw.SizedBox(height: 8),
    ];
  }

  List<pw.Widget> _highlightedCorporateSectionSuffixWidgets(
    PdfColor lineColor,
  ) {
    return [
      pw.SizedBox(height: 10),
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(
          30,
          0,
          30,
          ResumeTypography.darkHeaderSectionGapPdfPt,
        ),
        child: pw.Container(height: 2, color: lineColor),
      ),
    ];
  }

  List<pw.Widget> _highlightedCorporateSummarySectionWidgets(
    String summary,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    PdfColor highlightColor,
    GaramondPdfFonts garamond,
    double bodyPt, {
    required bool highlightSummary,
  }) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Summary',
        sectionTitleColor: sectionTitleColor,
        garamond: garamond,
      ),
      pw.Padding(
        padding: pw.EdgeInsets.fromLTRB(
          ResumeTypography.corporateBodyHorizontalInset,
          0,
          ResumeTypography.corporateBodyHorizontalInset,
          0,
        ),
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: highlightSummary ? highlightColor : PdfColors.white,
          child: pw.Text(
            summary,
            style: corporateBodyPdfTextStyle(garamond, bodyPt),
          ),
        ),
      ),
      ..._highlightedCorporateSectionSuffixWidgets(lineColor),
    ];
  }

  List<pw.Widget> _highlightedCorporateExperienceSectionWidgets(
    List<WorkExperience> items,
    Map<int, Set<String>> highlightedBulletsByExperience,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    PdfColor highlightColor,
    GaramondPdfFonts garamond,
    double bodyPt,
  ) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Experience',
        sectionTitleColor: sectionTitleColor,
        garamond: garamond,
      ),
      for (var index = 0; index < items.length; index++)
        pw.Padding(
          padding: pw.EdgeInsets.fromLTRB(
          ResumeTypography.corporateBodyHorizontalInset,
          0,
          ResumeTypography.corporateBodyHorizontalInset,
          0,
        ),
          child: _buildHighlightedCorporateExperience(
            items[index],
            highlightedBulletsByExperience[index] ?? const <String>{},
            highlightColor,
            garamond: garamond,
            bodyFontPt: bodyPt,
          ),
        ),
      ..._highlightedCorporateSectionSuffixWidgets(lineColor),
    ];
  }

  List<pw.Widget> _highlightedCorporateEducationSectionWidgets(
    List<EducationItem> items,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    GaramondPdfFonts garamond,
    double bodyPt,
  ) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Education',
        sectionTitleColor: sectionTitleColor,
        garamond: garamond,
      ),
      for (final item in items)
        pw.Padding(
          padding: pw.EdgeInsets.fromLTRB(
          ResumeTypography.corporateBodyHorizontalInset,
          0,
          ResumeTypography.corporateBodyHorizontalInset,
          0,
        ),
          child: _buildCorporateEducation(
            item,
            garamond: garamond,
            bodyFontPt: bodyPt,
          ),
        ),
      ..._highlightedCorporateSectionSuffixWidgets(lineColor),
    ];
  }

  List<pw.Widget> _highlightedCorporateSkillsSectionWidgets(
    List<String> skills,
    Set<String> highlightedSkills,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    PdfColor highlightColor,
    GaramondPdfFonts garamond,
    double bodyPt,
  ) {
    final bulletStyle = corporateBodyPdfTextStyle(garamond, bodyPt);
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Skills',
        sectionTitleColor: sectionTitleColor,
        garamond: garamond,
      ),
      for (final row in _twoColumnBulletRowsWithHighlights(
        skills,
        highlightedSkills,
        highlightColor,
        fontSize: bodyPt,
        bulletStyle: bulletStyle,
      ))
        pw.Padding(
          padding: pw.EdgeInsets.fromLTRB(
          ResumeTypography.corporateBodyHorizontalInset,
          0,
          ResumeTypography.corporateBodyHorizontalInset,
          0,
        ),
          child: row,
        ),
      ..._highlightedCorporateSectionSuffixWidgets(lineColor),
    ];
  }

  List<pw.Widget> _highlightedCorporateProjectsSectionWidgets(
    List<ProjectItem> items,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    GaramondPdfFonts garamond,
    double bodyPt,
  ) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Projects',
        sectionTitleColor: sectionTitleColor,
        garamond: garamond,
      ),
      for (final item in items)
        ..._buildCompactProjectWidgets(
          item,
          garamond: garamond,
          bodyFontPt: bodyPt,
        ).map(
          (widget) => pw.Padding(
            padding: pw.EdgeInsets.fromLTRB(
          ResumeTypography.corporateBodyHorizontalInset,
          0,
          ResumeTypography.corporateBodyHorizontalInset,
          0,
        ),
            child: widget,
          ),
        ),
      ..._highlightedCorporateSectionSuffixWidgets(lineColor),
    ];
  }

  List<pw.Widget> _highlightedCorporateCustomSectionWidgets(
    CustomSectionItem item,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    GaramondPdfFonts garamond,
    double bodyPt,
  ) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: item.title.ifEmpty('Custom Section'),
        sectionTitleColor: sectionTitleColor,
        garamond: garamond,
      ),
      for (final widget in _pwCustomSectionBodyWidgets(
        item,
        garamond: garamond,
        bodyFontPt: bodyPt,
      ))
        pw.Padding(
          padding: pw.EdgeInsets.fromLTRB(
          ResumeTypography.corporateBodyHorizontalInset,
          0,
          ResumeTypography.corporateBodyHorizontalInset,
          0,
        ),
          child: widget,
        ),
      ..._highlightedCorporateSectionSuffixWidgets(lineColor),
    ];
  }

  void _addHighlightedCreativeTemplatePage(
    pw.Document document,
    ResumeData resume, {
    GaramondPdfFonts? garamond,
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final accentColor = _creativeSidebarAccentColorPdf(resume);
    final textColor = _creativeTitleColorPdf(resume);
    final lineColor = _creativeSidebarLineColorPdf();
    final bodyColor = _creativeBodyTextColorPdf();
    final railColor = _creativeSidebarRailColorPdf(resume);
    final highlightColor = PdfColor.fromHex('#FFE67A');
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final namePt = resume.creativeScaledPt(ResumeTypography.creativeNamePt);
    final subtitlePt =
        resume.creativeScaledPt(ResumeTypography.creativeSubtitlePt);
    final sectionTitlePt =
        resume.creativeScaledPt(ResumeTypography.creativeSectionTitlePt);
    final bodyTextStyle = garamond != null
        ? accentStripBodyPdfTextStyle(
            garamond,
            bodyPt,
            color: bodyColor,
          )
        : pw.TextStyle(
            fontSize: bodyPt,
            color: bodyColor,
            lineSpacing: ResumeTypography.creativeBodyPdfLineSpacingFor(bodyPt),
          );
    final contactItems = _resumeContactItems(resume);
    final allSkills = _skillsForDisplay(resume);
    final template2Skills = allSkills.length > 2
        ? allSkills.sublist(0, allSkills.length - 2)
        : const <String>[];
    final educationItems = resume.includeEducationInResume
        ? resume.visibleEducation
        : const <EducationItem>[];

    document.addPage(
      pw.MultiPage(
        pageTheme: _creativeSidebarPageTheme(
          railColor: railColor,
          firstPageSidebar: _creativeFirstPageSidebar(
            resume: resume,
            contactItems: contactItems,
            accentColor: accentColor,
            lineColor: lineColor,
            mutedColor: bodyColor,
            garamond: garamond,
            bodyPt: bodyPt,
          ),
        ),
        header: _creativeContinuedPageTopGap,
        build: (context) => [
          _creativeMainColumnChild(
            pw.Text(
              _displayName(resume).toUpperCase(),
              style: garamond != null
                  ? garamondPdfTextStyle(
                      garamond,
                      ResumeTypography.creativeNameWeight,
                      fontSize: namePt,
                      color: textColor,
                    ).copyWith(lineSpacing: 1)
                  : pw.TextStyle(
                      color: textColor,
                      fontSize: namePt,
                      lineSpacing: 1,
                    ),
            ),
          ),
          if (resume.jobTitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _creativeMainColumnChild(
              pw.Text(
                resume.jobTitle.trim(),
                style: garamond != null
                    ? garamondPdfTextStyle(
                        garamond,
                        ResumeTypography.creativeSubtitleWeight,
                        fontSize: subtitlePt,
                        color: bodyColor,
                        fontStyle: pw.FontStyle.italic,
                      )
                    : pw.TextStyle(
                        color: bodyColor,
                        fontSize: subtitlePt,
                        fontStyle: pw.FontStyle.italic,
                      ),
              ),
            ),
          ],
          pw.SizedBox(height: _creativeSectionGapPt),
          _creativeMainColumnChild(
            _creativeSectionHeadingRow(
              title: 'Summary',
              titleColor: textColor,
              lineColor: lineColor,
              garamond: garamond,
              sectionTitlePt: sectionTitlePt,
            ),
          ),
          pw.SizedBox(height: _creativeHeadingBodyGapPt),
          _creativeMainColumnChild(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              color: highlightSummary ? highlightColor : PdfColors.white,
              child: pw.Text(
                resume.summary.trim().ifEmpty(
                  'Add a short summary to position your experience and strengths.',
                ),
                style: bodyTextStyle,
              ),
            ),
          ),
          if (resume.includeWorkInResume) ...[
            pw.SizedBox(height: _creativeSectionGapPt),
            _creativeMainColumnChild(
              _creativeSectionHeadingRow(
                title: 'Experience',
                titleColor: textColor,
                lineColor: lineColor,
                garamond: garamond,
                sectionTitlePt: sectionTitlePt,
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            for (
              var index = 0;
              index < resume.visibleWorkExperiences.length;
              index++
            )
              _creativeMainColumnChild(
                _buildHighlightedCreativeExperience(
                  resume.visibleWorkExperiences[index],
                  highlightedBulletsByExperience[index] ?? const <String>{},
                  highlightColor,
                  garamond: garamond,
                  bodyPt: bodyPt,
                  subtitlePt: subtitlePt,
                ),
              ),
          ],
          if (educationItems.isNotEmpty) ...[
            pw.SizedBox(height: _creativeSectionGapPt),
            _creativeMainColumnChild(
              _creativeSectionHeadingRow(
                title: 'Education',
                titleColor: textColor,
                lineColor: lineColor,
                garamond: garamond,
                sectionTitlePt: sectionTitlePt,
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            for (final item in educationItems)
              _creativeMainColumnChild(
                _creativeSidebarEducationEntry(
                  item,
                  titleColor: textColor,
                  mutedColor: bodyColor,
                  garamond: garamond,
                  bodyPt: bodyPt,
                  subtitlePt: subtitlePt,
                ),
              ),
          ],
          if (resume.includeSkillsInResume && template2Skills.isNotEmpty) ...[
            pw.SizedBox(height: _creativeSectionGapPt),
            _creativeMainColumnChild(
              _creativeSectionHeadingRow(
                title: 'Skills',
                titleColor: textColor,
                lineColor: lineColor,
                garamond: garamond,
                sectionTitlePt: sectionTitlePt,
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            _creativeMainColumnChild(
              _twoColumnBulletListWithHighlights(
                template2Skills,
                highlightedSkills,
                highlightColor,
                fontSize: bodyPt,
                bulletStyle: bodyTextStyle,
              ),
            ),
          ],
          if (resume.includeProjectsInResume) ...[
            pw.SizedBox(height: _creativeSectionGapPt),
            _creativeMainColumnChild(
              _creativeSectionHeadingRow(
                title: 'Projects',
                titleColor: textColor,
                lineColor: lineColor,
                garamond: garamond,
                sectionTitlePt: sectionTitlePt,
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            for (final item in resume.visibleProjects)
              _creativeMainColumnChild(
                _buildCreativeProject(
                  item,
                  garamond: garamond,
                  mutedColor: bodyColor,
                  bodyPt: bodyPt,
                  subtitlePt: subtitlePt,
                ),
              ),
          ],
          for (final item in resume.visibleCustomSections) ...[
            pw.SizedBox(height: _creativeSectionGapPt),
            _creativeMainColumnChild(
              _creativeSectionHeadingRow(
                title: item.title.ifEmpty('Custom Section'),
                titleColor: textColor,
                lineColor: lineColor,
                garamond: garamond,
                sectionTitlePt: sectionTitlePt,
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            for (final widget in _pwCustomSectionBodyWidgets(
              item,
              garamond: garamond,
              bodyFontPt: bodyPt,
            ))
              _creativeMainColumnChild(widget),
          ],
        ],
      ),
    );
  }

  void _addHighlightedClassicSidebarTemplatePage(
    pw.Document document,
    ResumeData resume, {
    GaramondPdfFonts? garamond,
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final titleColor = _classicSidebarTitleColorPdf(resume);
    final mutedColor = _classicSidebarMutedColorPdf(resume);
    final accentColor = _classicSidebarAccentColorPdf(resume);
    final dividerColor = _classicSidebarDividerColorPdf(resume);
    final borderColor = _classicSidebarSectionBorderPdf(resume);
    final highlightColor = PdfColor.fromHex('#FFE67A');
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final namePt =
        resume.classicSidebarScaledPt(ResumeTypography.classicSidebarNamePt);
    final subtitlePt =
        resume.classicSidebarScaledPt(ResumeTypography.classicSidebarSubtitlePt);
    final sectionTitlePt = resume.classicSidebarScaledPt(
      ResumeTypography.classicSidebarSectionTitlePt,
    );
    final customSections = _classicSidebarMainCustomSections(resume);
    final sidebarPageCount = _classicSidebarPageSlices(
      resume: resume,
      bodyPt: bodyPt,
      sectionTitlePt: sectionTitlePt,
      highlightedSkills: highlightedSkills,
      pageFormat: PdfPageFormat.a4,
    ).length;
    pw.Widget sidebarWrap(pw.Widget child) => _classicSidebarMainColumnChild(
      child,
      sidebarPageCount: sidebarPageCount,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: _classicSidebarPageTheme(
          resume: resume,
          railColor: _classicSidebarRailColorPdf(resume),
          dividerColor: dividerColor,
          accentColor: accentColor,
          titleColor: titleColor,
          mutedColor: mutedColor,
          bodyPt: bodyPt,
          sectionTitlePt: sectionTitlePt,
          garamond: garamond,
          highlightedSkills: highlightedSkills,
          highlightColor: highlightColor,
        ),
        header: _continuedPageTopGap,
        footer: _classicSidebarFirstPageBottomSpacer,
        build: (context) => [
          sidebarWrap(
            pw.Padding(
              padding: const pw.EdgeInsets.only(
                top: _classicSidebarFirstPageMainTopGapPt,
              ),
              child: _buildClassicSidebarHeader(
                resume,
                titleColor: titleColor,
                mutedColor: mutedColor,
                accentColor: accentColor,
                bodyPt: bodyPt,
                namePt: namePt,
                subtitlePt: subtitlePt,
                garamond: garamond,
              ),
            ),
          ),
          sidebarWrap(
            _buildClassicSidebarSection(
              title: 'Summary',
              titleColor: titleColor,
              sectionTitlePt: sectionTitlePt,
              garamond: garamond,
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                color: highlightSummary ? highlightColor : PdfColors.white,
                child: pw.Text(
                  resume.summary.trim().ifEmpty(
                    'Add a short summary to position your experience and strengths.',
                  ),
                  style: _classicSidebarPdfTextStyle(
                    garamond,
                    ResumeTypography.classicSidebarBodyWeight,
                    bodyPt,
                    color: titleColor,
                  ).copyWith(
                    lineSpacing:
                        ResumeTypography.classicSidebarBodyPdfLineSpacingFor(
                      bodyPt,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (resume.includeWorkInResume &&
              resume.visibleWorkExperiences.isEmpty)
            sidebarWrap(
              _buildClassicSidebarSection(
                title: 'Experience',
                titleColor: titleColor,
                topDividerColor: borderColor,
                sectionTitlePt: sectionTitlePt,
                garamond: garamond,
                child: pw.Text(
                  'Add your work experience details.',
                  style: _classicSidebarPdfTextStyle(
                    garamond,
                    ResumeTypography.classicSidebarBodyWeight,
                    bodyPt,
                    color: mutedColor,
                  ),
                ),
              ),
            ),
          if (resume.includeWorkInResume &&
              resume.visibleWorkExperiences.isNotEmpty) ...[
            sidebarWrap(
              _buildClassicSidebarSectionHeading(
                title: 'Experience',
                titleColor: titleColor,
                topDividerColor: borderColor,
                sectionTitlePt: sectionTitlePt,
                garamond: garamond,
              ),
            ),
            ..._classicSidebarPaginatedExperienceSidebarBlocks(
              experiences: resume.visibleWorkExperiences,
              wrap: sidebarWrap,
              titleColor: titleColor,
              accentColor: accentColor,
              bodyPt: bodyPt,
              subtitlePt: subtitlePt,
              garamond: garamond,
              highlightedBulletsByExperience: highlightedBulletsByExperience,
              bulletHighlightColor: highlightColor,
            ),
          ],
          if (resume.includeEducationInResume &&
              resume.visibleEducation.isEmpty)
            sidebarWrap(
              _buildClassicSidebarSection(
                title: 'Education',
                titleColor: titleColor,
                topDividerColor: borderColor,
                sectionTitlePt: sectionTitlePt,
                garamond: garamond,
                child: pw.Text(
                  'Add your education details.',
                  style: _classicSidebarPdfTextStyle(
                    garamond,
                    ResumeTypography.classicSidebarBodyWeight,
                    bodyPt,
                    color: mutedColor,
                  ),
                ),
              ),
            ),
          if (resume.includeEducationInResume &&
              resume.visibleEducation.isNotEmpty) ...[
            sidebarWrap(
              _buildClassicSidebarSectionHeading(
                title: 'Education',
                titleColor: titleColor,
                topDividerColor: borderColor,
                sectionTitlePt: sectionTitlePt,
                garamond: garamond,
              ),
            ),
            ..._classicSidebarPaginatedEducationSidebarBlocks(
              education: resume.visibleEducation,
              wrap: sidebarWrap,
              titleColor: titleColor,
              mutedColor: mutedColor,
              bodyPt: bodyPt,
              subtitlePt: subtitlePt,
              garamond: garamond,
            ),
          ],
          if (resume.includeProjectsInResume &&
              resume.visibleProjects.isNotEmpty) ...[
            sidebarWrap(
              _buildClassicSidebarSectionHeading(
                title: 'Projects',
                titleColor: titleColor,
                topDividerColor: borderColor,
                sectionTitlePt: sectionTitlePt,
                garamond: garamond,
              ),
            ),
            ..._classicSidebarPaginatedProjectSidebarBlocks(
              projects: resume.visibleProjects,
              wrap: sidebarWrap,
              titleColor: titleColor,
              mutedColor: mutedColor,
              accentColor: accentColor,
              bodyPt: bodyPt,
              subtitlePt: subtitlePt,
              garamond: garamond,
            ),
          ],
          for (var index = 0; index < customSections.length; index++) ...[
            sidebarWrap(
              _buildClassicSidebarSectionHeading(
                title: customSections[index].title.ifEmpty('Custom Section'),
                titleColor: titleColor,
                topDividerColor: borderColor,
                sectionTitlePt: sectionTitlePt,
                garamond: garamond,
              ),
            ),
            if (customSections[index].layoutMode ==
                CustomSectionLayoutMode.bullets)
              for (
                var bulletIndex = 0;
                bulletIndex <
                    customSections[index].bullets
                        .where((bullet) => bullet.trim().isNotEmpty)
                        .length;
                bulletIndex++
              )
                sidebarWrap(
                  _classicSidebarSectionBodyBlock(
                    showBottomBorder:
                        bulletIndex ==
                        customSections[index].bullets
                                .where((bullet) => bullet.trim().isNotEmpty)
                                .length -
                            1,
                    child: _classicBulletRow(
                      text: customSections[index].bullets
                          .where((bullet) => bullet.trim().isNotEmpty)
                          .elementAt(bulletIndex),
                      bulletColor: accentColor,
                      textColor: mutedColor,
                      fontSize: bodyPt,
                      garamond: garamond,
                    ),
                  ),
                )
            else
              sidebarWrap(
                _classicSidebarSectionBodyBlock(
                  showBottomBorder: true,
                  child: _buildClassicSidebarCustomSection(
                    customSections[index],
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    bodyPt: bodyPt,
                    garamond: garamond,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _addHighlightedDetailsSidebarTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final titleColor = _detailsSidebarTitleColorPdf(resume);
    final mutedColor = _detailsSidebarMutedColorPdf(resume);
    final accentColor = _detailsSidebarAccentColorPdf(resume);
    final dividerColor = _detailsSidebarDividerColorPdf(resume);
    final highlightColor = PdfColor.fromHex('#FFE67A');
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final sidebarSlices = _detailsSidebarPageSlices(
      resume: resume,
      bodyPt: bodyPt,
      highlightedSkills: highlightedSkills,
      pageFormat: PdfPageFormat.a4,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: _detailsSidebarPageTheme(
          resume: resume,
          railColor: _detailsSidebarRailColorPdf(resume),
          accentColor: accentColor,
          titleColor: titleColor,
          mutedColor: mutedColor,
          dividerColor: dividerColor,
          bodyPt: bodyPt,
          sidebarSlices: sidebarSlices,
          highlightColor: highlightColor,
        ),
        header: _continuedPageTopGap,
        build: (context) => [
          _detailsSidebarMainColumnChild(
            _detailsSidebarHeadingRow(
              title: 'SUMMARY',
              titleColor: titleColor,
              dividerColor: dividerColor,
            ),
          ),
          pw.SizedBox(height: _detailsSidebarHeadingGapPt),
          _detailsSidebarMainColumnChild(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              color: highlightSummary ? highlightColor : PdfColors.white,
              child: pw.Text(
                resume.summary.trim().ifEmpty(
                  'Add a short summary to position your experience and strengths.',
                ),
                style: pw.TextStyle(
                  color: mutedColor,
                  fontSize: bodyPt,
                  lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
                ),
              ),
            ),
          ),
          pw.SizedBox(height: _detailsSidebarSectionGapPt),
          _detailsSidebarMainColumnChild(
            _detailsSidebarHeadingRow(
              title: 'EXPERIENCE',
              titleColor: titleColor,
              dividerColor: dividerColor,
            ),
          ),
          pw.SizedBox(height: _detailsSidebarHeadingGapPt),
          if (resume.includeWorkInResume &&
              resume.visibleWorkExperiences.isNotEmpty)
            for (
              var index = 0;
              index < resume.visibleWorkExperiences.length;
              index++
            )
              _detailsSidebarMainColumnChild(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 14),
                  child: _buildHighlightedDetailsSidebarExperience(
                    resume.visibleWorkExperiences[index],
                    highlightedBulletsByExperience[index] ?? const <String>{},
                    highlightColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    bodyPt: bodyPt,
                  ),
                ),
              )
          else
            _detailsSidebarMainColumnChild(
              pw.Text(
                'Add your work experience details.',
                style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
              ),
            ),
          if (resume.includeEducationInResume) ...[
            pw.SizedBox(height: _detailsSidebarSectionGapPt),
            _detailsSidebarMainColumnChild(
              _detailsSidebarHeadingRow(
                title: 'EDUCATION',
                titleColor: titleColor,
                dividerColor: dividerColor,
              ),
            ),
            pw.SizedBox(height: _detailsSidebarHeadingGapPt),
            if (resume.visibleEducation.isNotEmpty)
              for (final item in resume.visibleEducation)
                _detailsSidebarMainColumnChild(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: _buildDetailsSidebarEducation(
                      item,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      bodyPt: bodyPt,
                    ),
                  ),
                )
            else
              _detailsSidebarMainColumnChild(
                pw.Text(
                  'Add your education details.',
                  style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
                ),
              ),
          ],
          if (resume.includeProjectsInResume &&
              resume.visibleProjects.isNotEmpty) ...[
            pw.SizedBox(height: _detailsSidebarSectionGapPt),
            _detailsSidebarMainColumnChild(
              _detailsSidebarHeadingRow(
                title: 'PROJECTS',
                titleColor: titleColor,
                dividerColor: dividerColor,
              ),
            ),
            pw.SizedBox(height: _detailsSidebarHeadingGapPt),
            for (final item in resume.visibleProjects)
              _detailsSidebarMainColumnChild(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: _buildDetailsSidebarProject(
                    item,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    bodyPt: bodyPt,
                  ),
                ),
              ),
          ],
          for (final item in resume.visibleCustomSections) ...[
            pw.SizedBox(height: _detailsSidebarSectionGapPt),
            _detailsSidebarMainColumnChild(
              _detailsSidebarHeadingRow(
                title: item.title.ifEmpty('CUSTOM SECTION').toUpperCase(),
                titleColor: titleColor,
                dividerColor: dividerColor,
              ),
            ),
            pw.SizedBox(height: _detailsSidebarHeadingGapPt),
            _detailsSidebarMainColumnChild(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: _buildDetailsSidebarCustomSection(
                  item,
                  mutedColor: mutedColor,
                  accentColor: accentColor,
                  bodyPt: bodyPt,
                ),
              ),
            ),
          ],
          for (var i = 1; i < sidebarSlices.length; i++) pw.NewPage(),
        ],
      ),
    );
  }

  pw.Widget _buildHighlightedDetailsSidebarExperience(
    WorkExperience item,
    Set<String> highlightedBullets,
    PdfColor highlightColor, {
    required PdfColor titleColor,
    required PdfColor mutedColor,
    required PdfColor accentColor,
    required double bodyPt,
  }) {
    final bullets = _workBulletLines(item);
    final dates = [
      item.startDate.trim(),
      item.endDate.trim(),
    ].where((value) => value.isNotEmpty).join(' — ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (dates.isNotEmpty)
          pw.Text(
            dates,
            style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
          ),
        if (item.role.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            item.role.trim(),
            style: pw.TextStyle(
              color: titleColor,
              fontSize: bodyPt + 1.3,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        if (item.company.trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            item.company.trim(),
            style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
          ),
        ],
        if (bullets.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          for (final bullet in bullets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: _detailsSidebarSkillRow(
                text: bullet,
                accentColor: accentColor,
                textColor: mutedColor,
                fontSize: bodyPt,
                backgroundColor: highlightedBullets.contains(bullet)
                    ? highlightColor
                    : null,
              ),
            ),
        ],
      ],
    );
  }
}
