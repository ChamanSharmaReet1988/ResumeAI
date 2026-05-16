part of 'package:resume_app/core/services/resume_services.dart';

extension _ResumePdfTemplatePages on ResumePdfService {
  pw.Widget _continuedPageTopGap(pw.Context context) =>
      context.pageNumber > 1 ? pw.SizedBox(height: 40) : pw.SizedBox();

  void _addCorporateTemplatePage(
    pw.Document document,
    ResumeData resume, {
    pw.MemoryImage? profileImage,
  }) {
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final headerContactFontPt = bodyPt + 1;
    final sectionTitleColor = _corporateTitlePdf(resume);
    final headerColor = _corporateHeaderPdf(resume);
    final headerOnColor = _corporateHeaderOnPdf(resume);
    final lineColor = PdfColor.fromHex('#D7DCE2');
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
                profileImage != null
                    ? pw.Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: headerOnColor,
                            width: avatarBorderWidth,
                          ),
                        ),
                        child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                      )
                    : pw.Container(
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
                          style: pw.TextStyle(
                            color: headerOnColor,
                            fontSize: 48,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                pw.SizedBox(width: 25),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 0),
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _darkHeaderNameText(
                          _displayName(resume).toUpperCase(),
                          headerOnColor,
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
                                style: pw.TextStyle(
                                  color: headerOnColor,
                                  fontSize: headerContactFontPt,
                                  lineSpacing: 1.6,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          ..._darkHeaderSummarySectionWidgets(
            resume.summary.trim(),
            lineColor,
            sectionTitleColor,
          ),
          if (resume.includeWorkInResume)
            ..._darkHeaderExperienceSectionWidgets(
              resume.visibleWorkExperiences,
              lineColor,
              sectionTitleColor,
              bodyPt,
            ),
          if (resume.includeEducationInResume)
            ..._darkHeaderEducationSectionWidgets(
              resume.visibleEducation,
              lineColor,
              sectionTitleColor,
              bodyPt,
            ),
          if (resume.includeSkillsInResume)
            ..._darkHeaderSkillsSectionWidgets(
              _skillsForDisplay(resume),
              lineColor,
              sectionTitleColor,
              bodyPt,
            ),
          if (resume.includeProjectsInResume)
            ..._darkHeaderProjectsSectionWidgets(
              resume.visibleProjects,
              lineColor,
              sectionTitleColor,
              bodyPt,
            ),
          for (final item in resume.visibleCustomSections)
            ..._darkHeaderCustomSectionWidgets(
              item,
              lineColor,
              sectionTitleColor,
            ),
        ],
      ),
    );
  }

  List<pw.Widget> _darkHeaderSectionPrefixWidgets({
    required String title,
    required PdfColor lineColor,
    required PdfColor sectionTitleColor,
  }) {
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: _darkHeaderHeadingText(
          title.toUpperCase(),
          color: sectionTitleColor,
        ),
      ),
      pw.SizedBox(height: 7),
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: pw.Container(height: 2, color: lineColor),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  List<pw.Widget> _darkHeaderSectionSuffixWidgets() {
    return [pw.SizedBox(height: ResumeTypography.sectionGapPdfPt)];
  }

  List<pw.Widget> _darkHeaderSummarySectionWidgets(
    String summary,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
  ) {
    return [
      ..._darkHeaderSectionPrefixWidgets(
        title: 'Summary',
        lineColor: lineColor,
        sectionTitleColor: sectionTitleColor,
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: pw.Text(summary),
      ),
      ..._darkHeaderSectionSuffixWidgets(),
    ];
  }

  List<pw.Widget> _darkHeaderEducationSectionWidgets(
    List<EducationItem> items,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    double bodyPt,
  ) {
    return [
      ..._darkHeaderSectionPrefixWidgets(
        title: 'Education',
        lineColor: lineColor,
        sectionTitleColor: sectionTitleColor,
      ),
      for (final item in items)
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: _buildCorporateEducation(item, bodyFontPt: bodyPt),
        ),
      ..._darkHeaderSectionSuffixWidgets(),
    ];
  }

  List<pw.Widget> _darkHeaderSkillsSectionWidgets(
    List<String> skills,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    double bodyPt,
  ) {
    return [
      ..._darkHeaderSectionPrefixWidgets(
        title: 'Skills',
        lineColor: lineColor,
        sectionTitleColor: sectionTitleColor,
      ),
      for (final row in _twoColumnBulletRows(
        skills,
        columnGap: 24,
        itemBottom: 5,
        fontSize: bodyPt,
      ))
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: row,
        ),
      ..._darkHeaderSectionSuffixWidgets(),
    ];
  }

  List<pw.Widget> _darkHeaderProjectsSectionWidgets(
    List<ProjectItem> items,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    double bodyPt,
  ) {
    return [
      ..._darkHeaderSectionPrefixWidgets(
        title: 'Projects',
        lineColor: lineColor,
        sectionTitleColor: sectionTitleColor,
      ),
      for (final item in items)
        ..._buildCompactProjectWidgets(item, bodyFontPt: bodyPt).map(
          (widget) => pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
            child: widget,
          ),
        ),
      ..._darkHeaderSectionSuffixWidgets(),
    ];
  }

  List<pw.Widget> _darkHeaderCustomSectionWidgets(
    CustomSectionItem item,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
  ) {
    return [
      ..._darkHeaderSectionPrefixWidgets(
        title: item.title.ifEmpty('Custom Section'),
        lineColor: lineColor,
        sectionTitleColor: sectionTitleColor,
      ),
      for (final widget in _pwCustomSectionBodyWidgets(item))
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: widget,
        ),
      ..._darkHeaderSectionSuffixWidgets(),
    ];
  }

  List<pw.Widget> _darkHeaderExperienceSectionWidgets(
    List<WorkExperience> items,
    PdfColor lineColor,
    PdfColor sectionTitleColor,
    double bodyPt,
  ) {
    final widgets = <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: _darkHeaderHeadingText('EXPERIENCE', color: sectionTitleColor),
      ),
      pw.SizedBox(height: 7),
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: pw.Container(height: 2, color: lineColor),
      ),
      pw.SizedBox(height: 12),
    ];

    if (items.isEmpty) {
      widgets.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
      return widgets;
    }

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final start = item.startDate.trim();
      final end = item.endDate.trim();
      final dateStr = start.isEmpty && end.isEmpty
          ? ''
          : '${start.isNotEmpty ? start : ''}'
                '${start.isNotEmpty && end.isNotEmpty ? ' - ' : ''}'
                '${end.isNotEmpty ? end : ''}';

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: _darkHeaderRoleCompanyText(
                  item.role.ifEmpty('Role'),
                  item.company.ifEmpty('Company'),
                ),
              ),
              if (dateStr.isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    dateStr,
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#666B71'),
                      fontStyle: pw.FontStyle.italic,
                      fontWeight: pw.FontWeight.normal,
                      font: pw.Font.helveticaOblique(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      widgets.add(pw.SizedBox(height: 4));

      final bullets = _workBulletLines(item);
      for (var i = 0; i < bullets.length; i++) {
        final bullet = bullets[i];
        widgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.fromLTRB(30, i == 0 ? 0 : 3, 30, 0),
            child: pw.Bullet(
              text: bullet,
              style: pw.TextStyle(color: PdfColors.black, fontSize: bodyPt),
            ),
          ),
        );
      }

      final isLast = index == items.length - 1;
      widgets.add(
        pw.SizedBox(height: isLast ? ResumeTypography.sectionGapPdfPt : 10),
      );
    }

    return widgets;
  }

  pw.Widget _darkHeaderRoleCompanyText(String role, String company) {
    final value = '$role / $company';
    final style = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 15,
      color: PdfColors.black,
    );
    return pw.Text(value, style: style);
  }

  pw.Widget _darkHeaderNameText(String value, PdfColor onColor) {
    final style = pw.TextStyle(
      color: onColor,
      fontSize: ResumeTypography.darkHeaderNamePt,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Text(value, style: style);
  }

  pw.Widget _darkHeaderHeadingText(
    String value, {
    PdfColor color = const PdfColor(0, 0, 0),
  }) {
    final style = pw.TextStyle(
      fontSize: ResumeTypography.darkHeaderSectionTitlePt,
      fontWeight: pw.FontWeight.bold,
      color: color,
      letterSpacing: 0.1,
    );
    return pw.Text(value, style: style);
  }

  void _addCreativeTemplatePage(
    pw.Document document,
    ResumeData resume, {
    pw.MemoryImage? profileImage,
  }) {
    final accentColor = _creativeSidebarAccentColorPdf(resume);
    final textColor = _creativeTitleColorPdf(resume);
    final lineColor = _creativeSidebarLineColorPdf();
    final muted = _creativeSidebarMutedColorPdf();
    final railColor = _creativeSidebarRailColorPdf(resume);
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
            profileImage: profileImage,
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
            pw.Text(
              resume.summary.trim().ifEmpty(
                'Add a short summary to position your experience and strengths.',
              ),
              style: pw.TextStyle(
                fontSize: bodyPt,
                color: muted,
                lineSpacing: 2,
              ),
              overflow: pw.TextOverflow.span,
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
            for (final item in resume.visibleWorkExperiences)
              _creativeMainColumnChild(
                _buildCreativeExperience(item, bodyFontPt: bodyPt),
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
            for (final row in _twoColumnBulletRows(
              _skillsForDisplay(resume),
              fontSize: bodyPt,
            ))
              _creativeMainColumnChild(row),
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

  void _addClassicSidebarTemplatePage(
    pw.Document document,
    ResumeData resume, {
    pw.MemoryImage? profileImage,
  }) {
    final titleColor = _classicSidebarTitleColorPdf(resume);
    final mutedColor = _classicSidebarMutedColorPdf(resume);
    final accentColor = _classicSidebarAccentColorPdf(resume);
    final dividerColor = _classicSidebarDividerColorPdf(resume);
    final borderColor = _classicSidebarSectionBorderPdf(resume);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final customSections = _classicSidebarMainCustomSections(resume);
    final sidebarPageCount = _classicSidebarPageSlices(
      resume: resume,
      bodyPt: bodyPt,
      highlightedSkills: const <String>{},
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
          profileImage: profileImage,
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
                child: pw.Text(
                  resume.summary.trim().ifEmpty(
                    'Add a short summary to position your experience and strengths.',
                  ),
                  style: pw.TextStyle(
                    color: mutedColor,
                    fontSize: bodyPt,
                    lineSpacing: 2,
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
                  child: _buildClassicSidebarExperience(
                    resume.visibleWorkExperiences[index],
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

  pw.Widget _buildClassicSidebarHeader(
    ResumeData resume, {
    required PdfColor titleColor,
    required PdfColor mutedColor,
    required PdfColor accentColor,
    required PdfColor borderColor,
    required double bodyPt,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _displayName(resume).toUpperCase(),
            style: pw.TextStyle(
              color: titleColor,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 1,
            ),
          ),
          if (resume.jobTitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              resume.jobTitle.trim(),
              style: pw.TextStyle(color: mutedColor, fontSize: bodyPt + 0.5),
            ),
          ],
          pw.SizedBox(height: 8),
          ..._classicSidebarResumeContactRows(
            resume,
            accentColor: accentColor,
            textColor: mutedColor,
            fontSize: bodyPt,
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _classicSidebarResumeContactRows(
    ResumeData resume, {
    required PdfColor accentColor,
    required PdfColor textColor,
    required double fontSize,
  }) {
    final rows = <String>[
      if (resume.email.trim().isNotEmpty) resume.email.trim(),
      if (resume.location.trim().isNotEmpty) resume.location.trim(),
      if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
      if (resume.website.trim().isNotEmpty) resume.website.trim(),
    ];

    return rows
        .map(
          (text) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 7,
                  height: 7,
                  margin: const pw.EdgeInsets.only(top: 3, right: 6),
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    borderRadius: pw.BorderRadius.circular(1.5),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(color: textColor, fontSize: fontSize),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  pw.Widget _buildClassicSidebarSection({
    required String title,
    required PdfColor titleColor,
    PdfColor? topDividerColor,
    bool showBottomBorder = true,
    required pw.Widget child,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (topDividerColor != null) ...[
          pw.Container(
            height: 1,
            width: double.infinity,
            color: topDividerColor,
          ),
          pw.SizedBox(height: 12),
        ],
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: titleColor,
            fontSize: ResumeTypography.darkHeaderSectionTitlePt,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: _classicSidebarHeadingGapPt),
        child,
        if (showBottomBorder) pw.SizedBox(height: 12),
        pw.SizedBox(height: _classicSidebarSectionBottomPt),
      ],
    );
  }

  pw.Widget _buildClassicSidebarSectionHeading({
    required String title,
    required PdfColor titleColor,
    PdfColor? topDividerColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (topDividerColor != null) ...[
          pw.Container(
            height: 1,
            width: double.infinity,
            color: topDividerColor,
          ),
          pw.SizedBox(height: 12),
        ],
        pw.Padding(
          padding: const pw.EdgeInsets.only(
            bottom: _classicSidebarHeadingGapPt,
          ),
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              color: titleColor,
              fontSize: ResumeTypography.darkHeaderSectionTitlePt,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildClassicSidebarSectionBodyBlock({
    bool showBottomBorder = true,
    required pw.Widget child,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        child,
        if (showBottomBorder) pw.SizedBox(height: 12),
        pw.SizedBox(height: _classicSidebarSectionBottomPt),
      ],
    );
  }

  pw.Widget _buildClassicSidebarExperience(
    WorkExperience item, {
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
                ),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildClassicSidebarEducation(
    EducationItem item, {
    required PdfColor titleColor,
    required PdfColor mutedColor,
    required double bodyPt,
  }) {
    final dates = [
      item.startDate.trim(),
      item.endDate.trim(),
    ].where((value) => value.isNotEmpty).join(' - ');
    final details = item.score.trim();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${item.degree.ifEmpty('Degree')}, ${item.institution.ifEmpty('Institution')}',
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
          if (details.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              details,
              style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildClassicSidebarProject(
    ProjectItem item, {
    required PdfColor titleColor,
    required PdfColor mutedColor,
    required PdfColor accentColor,
    required double bodyPt,
  }) {
    final bullets = _projectBulletLines(item);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.title.ifEmpty('Project'),
            style: pw.TextStyle(
              color: titleColor,
              fontSize: bodyPt + 1.2,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (bullets.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            for (final bullet in bullets)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: _classicBulletRow(
                  text: bullet,
                  bulletColor: accentColor,
                  textColor: mutedColor,
                  fontSize: bodyPt,
                ),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildClassicSidebarCustomSection(
    CustomSectionItem item, {
    required PdfColor mutedColor,
    required PdfColor accentColor,
    required double bodyPt,
  }) {
    if (item.layoutMode == CustomSectionLayoutMode.bullets) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final bullet in item.bullets.where((b) => b.trim().isNotEmpty))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: _classicBulletRow(
                text: bullet,
                bulletColor: accentColor,
                textColor: mutedColor,
                fontSize: bodyPt,
              ),
            ),
        ],
      );
    }
    return pw.Text(
      item.content.trim(),
      style: pw.TextStyle(color: mutedColor, fontSize: bodyPt, lineSpacing: 2),
    );
  }

  void _addDetailsSidebarTemplatePage(pw.Document document, ResumeData resume) {
    final titleColor = _detailsSidebarTitleColorPdf(resume);
    final mutedColor = _detailsSidebarMutedColorPdf(resume);
    final accentColor = _detailsSidebarAccentColorPdf(resume);
    final dividerColor = _detailsSidebarDividerColorPdf(resume);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final sidebarSlices = _detailsSidebarPageSlices(
      resume: resume,
      bodyPt: bodyPt,
      highlightedSkills: const <String>{},
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
            pw.Text(
              resume.summary.trim().ifEmpty(
                'Add a short summary to position your experience and strengths.',
              ),
              style: pw.TextStyle(
                color: mutedColor,
                fontSize: bodyPt,
                lineSpacing: 2,
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
            for (final item in resume.visibleWorkExperiences)
              _detailsSidebarMainColumnChild(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 14),
                  child: _buildDetailsSidebarExperience(
                    item,
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

  pw.Widget _buildDetailsSidebarExperience(
    WorkExperience item, {
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
              ),
            ),
        ],
      ],
    );
  }

  pw.Widget _buildDetailsSidebarEducation(
    EducationItem item, {
    required PdfColor titleColor,
    required PdfColor mutedColor,
    required double bodyPt,
  }) {
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
        if (item.degree.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            item.degree.trim(),
            style: pw.TextStyle(
              color: titleColor,
              fontSize: bodyPt + 1.1,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        if (item.institution.trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            item.institution.trim(),
            style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
          ),
        ],
        if (item.score.trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            item.score.trim(),
            style: pw.TextStyle(color: mutedColor, fontSize: bodyPt - 0.2),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildDetailsSidebarProject(
    ProjectItem item, {
    required PdfColor titleColor,
    required PdfColor mutedColor,
    required PdfColor accentColor,
    required double bodyPt,
  }) {
    final bullets = item.bullets.where((b) => b.trim().isNotEmpty).toList();
    final fallback = item.overview.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          item.title.ifEmpty('Project'),
          style: pw.TextStyle(
            color: titleColor,
            fontSize: bodyPt + 1.1,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (bullets.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          for (final bullet in bullets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: _detailsSidebarSkillRow(
                text: bullet,
                accentColor: accentColor,
                textColor: mutedColor,
                fontSize: bodyPt,
              ),
            ),
        ] else if (fallback.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            fallback,
            style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildDetailsSidebarCustomSection(
    CustomSectionItem item, {
    required PdfColor mutedColor,
    required PdfColor accentColor,
    required double bodyPt,
  }) {
    if (item.layoutMode == CustomSectionLayoutMode.bullets) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final bullet in item.bullets.where((b) => b.trim().isNotEmpty))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: _detailsSidebarSkillRow(
                text: bullet,
                accentColor: accentColor,
                textColor: mutedColor,
                fontSize: bodyPt,
              ),
            ),
        ],
      );
    }
    return pw.Text(
      item.content.trim(),
      style: pw.TextStyle(color: mutedColor, fontSize: bodyPt, lineSpacing: 2),
    );
  }
}
