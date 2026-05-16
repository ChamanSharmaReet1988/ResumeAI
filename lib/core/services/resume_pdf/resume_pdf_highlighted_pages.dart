part of 'package:resume_app/core/services/resume_services.dart';

extension _ResumePdfHighlightedTemplatePages on ResumePdfService {
  pw.Widget _continuedPageTopGap(pw.Context context) =>
      context.pageNumber > 1 ? pw.SizedBox(height: 40) : pw.SizedBox();

  void _addHighlightedCorporateTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required InterPdfFonts inter,
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
            padding: const pw.EdgeInsets.fromLTRB(30, 28, 30, 26),
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
                    style: darkHeaderInitialsPdfStyle(
                      inter,
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
                        inter,
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
                            child: pw.Text(
                              headerContactLines[index],
                              style: interPdfTextStyle(
                                inter,
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
            inter,
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
              inter,
              bodyPt,
            ),
          if (resume.includeEducationInResume)
            ..._highlightedCorporateEducationSectionWidgets(
              resume.visibleEducation,
              lineColor,
              sectionTitleColor,
              inter,
              bodyPt,
            ),
          if (resume.includeSkillsInResume)
            ..._highlightedCorporateSkillsSectionWidgets(
              _skillsForDisplay(resume),
              highlightedSkills,
              lineColor,
              sectionTitleColor,
              highlightColor,
              inter,
              bodyPt,
            ),
          if (resume.includeProjectsInResume)
            ..._highlightedCorporateProjectsSectionWidgets(
              resume.visibleProjects,
              lineColor,
              sectionTitleColor,
              inter,
              bodyPt,
            ),
          for (final item in resume.visibleCustomSections)
            ..._highlightedCorporateCustomSectionWidgets(
              item,
              lineColor,
              sectionTitleColor,
              inter,
              bodyPt,
            ),
        ],
      ),
    );
  }

  pw.Widget _highlightedCorporateNameText(
    String value,
    PdfColor onColor,
    InterPdfFonts inter,
  ) {
    return pw.Text(
      value,
      style: interPdfTextStyle(
        inter,
        ResumeTypography.darkHeaderSectionTitleWeight,
        fontSize: ResumeTypography.darkHeaderNamePt,
        color: onColor,
      ),
    );
  }

  List<pw.Widget> _highlightedCorporateSectionPrefixWidgets({
    required String title,
    required PdfColor sectionTitleColor,
    required InterPdfFonts inter,
  }) {
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: _corporateHeadingText(
          title.toUpperCase(),
          color: sectionTitleColor,
          inter: inter,
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
          ResumeTypography.sectionGapPdfPt,
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
    InterPdfFonts inter,
    double bodyPt, {
    required bool highlightSummary,
  }) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Summary',
        sectionTitleColor: sectionTitleColor,
        inter: inter,
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: highlightSummary ? highlightColor : PdfColors.white,
          child: pw.Text(
            summary,
            style: interPdfTextStyle(
              inter,
              ResumeFontWeight.w400,
              fontSize: bodyPt,
            ),
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
    InterPdfFonts inter,
    double bodyPt,
  ) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Experience',
        sectionTitleColor: sectionTitleColor,
        inter: inter,
      ),
      for (var index = 0; index < items.length; index++)
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: _buildHighlightedCorporateExperience(
            items[index],
            highlightedBulletsByExperience[index] ?? const <String>{},
            highlightColor,
            inter: inter,
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
    InterPdfFonts inter,
    double bodyPt,
  ) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Education',
        sectionTitleColor: sectionTitleColor,
        inter: inter,
      ),
      for (final item in items)
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: _buildCorporateEducation(
            item,
            inter: inter,
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
    InterPdfFonts inter,
    double bodyPt,
  ) {
    final bulletStyle = interBodyPdfTextStyle(inter, bodyPt);
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Skills',
        sectionTitleColor: sectionTitleColor,
        inter: inter,
      ),
      for (final row in _twoColumnBulletRowsWithHighlights(
        skills,
        highlightedSkills,
        highlightColor,
        fontSize: bodyPt,
        bulletStyle: bulletStyle,
      ))
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: row,
        ),
      ..._highlightedCorporateSectionSuffixWidgets(lineColor),
    ];
  }

  List<pw.Widget> _highlightedCorporateProjectsSectionWidgets(
    List<ProjectItem> items,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    InterPdfFonts inter,
    double bodyPt,
  ) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: 'Projects',
        sectionTitleColor: sectionTitleColor,
        inter: inter,
      ),
      for (final item in items)
        ..._buildCompactProjectWidgets(
          item,
          inter: inter,
          bodyFontPt: bodyPt,
        ).map(
          (widget) => pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
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
    InterPdfFonts inter,
    double bodyPt,
  ) {
    return [
      ..._highlightedCorporateSectionPrefixWidgets(
        title: item.title.ifEmpty('Custom Section'),
        sectionTitleColor: sectionTitleColor,
        inter: inter,
      ),
      for (final widget in _pwCustomSectionBodyWidgets(
        item,
        inter: inter,
        bodyFontPt: bodyPt,
      ))
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: widget,
        ),
      ..._highlightedCorporateSectionSuffixWidgets(lineColor),
    ];
  }

  void _addHighlightedCreativeTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final accentColor = _creativeSidebarAccentColorPdf(resume);
    final textColor = _creativeTitleColorPdf(resume);
    final lineColor = _creativeSidebarLineColorPdf();
    final muted = _creativeSidebarMutedColorPdf();
    final railColor = _creativeSidebarRailColorPdf(resume);
    final highlightColor = PdfColor.fromHex('#FFE67A');
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
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
            mutedColor: muted,
            bodyPt: bodyPt,
          ),
        ),
        header: _continuedPageTopGap,
        build: (context) => [
          _creativeMainColumnChild(
            pw.Text(
              _displayName(resume).toUpperCase(),
              style: pw.TextStyle(
                color: textColor,
                fontSize: _creativeNameFontPt,
                fontWeight: pw.FontWeight.bold,
                lineSpacing: 1,
              ),
            ),
          ),
          if (resume.jobTitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _creativeMainColumnChild(
              pw.Text(
                resume.jobTitle.trim(),
                style: pw.TextStyle(
                  color: muted,
                  fontSize: bodyPt,
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
                style: pw.TextStyle(
                  fontSize: bodyPt,
                  color: muted,
                  lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
                ),
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
                  bodyFontPt: bodyPt,
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
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            for (final item in educationItems)
              _creativeMainColumnChild(
                _creativeSidebarEducationEntry(
                  item,
                  titleColor: textColor,
                  mutedColor: muted,
                  bodyFontPt: bodyPt,
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
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            _creativeMainColumnChild(
              _twoColumnBulletListWithHighlights(
                template2Skills,
                highlightedSkills,
                highlightColor,
                fontSize: bodyPt,
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
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            for (final item in resume.visibleProjects)
              _creativeMainColumnChild(
                _buildCompactProject(item, bodyFontPt: bodyPt),
              ),
          ],
          for (final item in resume.visibleCustomSections) ...[
            pw.SizedBox(height: _creativeSectionGapPt),
            _creativeMainColumnChild(
              _creativeSectionHeadingRow(
                title: item.title.ifEmpty('Custom Section'),
                titleColor: textColor,
                lineColor: lineColor,
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            _creativeMainColumnChild(_pwCustomSectionBody(item)),
          ],
        ],
      ),
    );
  }

  void _addHighlightedClassicSidebarTemplatePage(
    pw.Document document,
    ResumeData resume, {
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
    final customSections = _classicSidebarMainCustomSections(resume);
    final sidebarPageCount = _classicSidebarPageSlices(
      resume: resume,
      bodyPt: bodyPt,
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
          highlightedSkills: highlightedSkills,
          highlightColor: highlightColor,
        ),
        header: _continuedPageTopGap,
        build: (context) => [
          sidebarWrap(
            _buildClassicSidebarHeader(
              resume,
              titleColor: titleColor,
              mutedColor: mutedColor,
              accentColor: accentColor,
              borderColor: borderColor,
              bodyPt: bodyPt,
            ),
          ),
          sidebarWrap(
            pw.Padding(
              padding: const pw.EdgeInsets.only(
                top: _classicSidebarSectionBottomPt,
              ),
              child: _buildClassicSidebarSection(
                title: 'Summary',
                titleColor: titleColor,
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
                    style: pw.TextStyle(
                      color: mutedColor,
                      fontSize: bodyPt,
                      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
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
                child: pw.Text(
                  'Add your work experience details.',
                  style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
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
              ),
            ),
            for (
              var index = 0;
              index < resume.visibleWorkExperiences.length;
              index++
            )
              sidebarWrap(
                _buildClassicSidebarSectionBodyBlock(
                  showBottomBorder:
                      index == resume.visibleWorkExperiences.length - 1,
                  child: _buildHighlightedClassicSidebarExperience(
                    resume.visibleWorkExperiences[index],
                    highlightedBulletsByExperience[index] ?? const <String>{},
                    highlightColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    bodyPt: bodyPt,
                  ),
                ),
              ),
          ],
          if (resume.includeEducationInResume &&
              resume.visibleEducation.isEmpty)
            sidebarWrap(
              _buildClassicSidebarSection(
                title: 'Education',
                titleColor: titleColor,
                topDividerColor: borderColor,
                child: pw.Text(
                  'Add your education details.',
                  style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
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
              ),
            ),
            for (var index = 0; index < resume.visibleEducation.length; index++)
              sidebarWrap(
                _buildClassicSidebarSectionBodyBlock(
                  showBottomBorder: index == resume.visibleEducation.length - 1,
                  child: _buildClassicSidebarEducation(
                    resume.visibleEducation[index],
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    bodyPt: bodyPt,
                  ),
                ),
              ),
          ],
          if (resume.includeProjectsInResume &&
              resume.visibleProjects.isNotEmpty) ...[
            sidebarWrap(
              _buildClassicSidebarSectionHeading(
                title: 'Projects',
                titleColor: titleColor,
                topDividerColor: borderColor,
              ),
            ),
            for (var index = 0; index < resume.visibleProjects.length; index++)
              sidebarWrap(
                _buildClassicSidebarSectionBodyBlock(
                  showBottomBorder: index == resume.visibleProjects.length - 1,
                  child: _buildClassicSidebarProject(
                    resume.visibleProjects[index],
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    bodyPt: bodyPt,
                  ),
                ),
              ),
          ],
          for (var index = 0; index < customSections.length; index++) ...[
            sidebarWrap(
              _buildClassicSidebarSectionHeading(
                title: customSections[index].title.ifEmpty('Custom Section'),
                titleColor: titleColor,
                topDividerColor: borderColor,
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
                  _buildClassicSidebarSectionBodyBlock(
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
                    ),
                  ),
                )
            else
              sidebarWrap(
                _buildClassicSidebarSectionBodyBlock(
                  showBottomBorder: true,
                  child: _buildClassicSidebarCustomSection(
                    customSections[index],
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    bodyPt: bodyPt,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildHighlightedClassicSidebarExperience(
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
    ].where((value) => value.isNotEmpty).join(' - ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${item.role.ifEmpty('Role')}, ${item.company.ifEmpty('Company')}',
            style: pw.TextStyle(
              color: titleColor,
              fontSize: bodyPt + 1.2,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (dates.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              dates,
              style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
            ),
          ],
          if (bullets.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            for (final bullet in bullets)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: _classicBulletRow(
                  text: bullet,
                  bulletColor: accentColor,
                  textColor: titleColor,
                  fontSize: bodyPt,
                  backgroundColor: highlightedBullets.contains(bullet)
                      ? highlightColor
                      : null,
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
