part of 'package:resume_app/core/services/resume_services.dart';

extension _ResumePdfHighlightedTemplatePages on ResumePdfService {
  pw.Widget _continuedPageTopGap(pw.Context context) =>
      context.pageNumber > 1 ? pw.SizedBox(height: 40) : pw.SizedBox();

  void _addHighlightedCorporateTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final headerContactFontPt = bodyPt + 2;
    final sectionTitleColor = _corporateTitlePdf(resume);
    final headerColor = _corporateHeaderPdf(resume);
    final lineColor = PdfColor.fromHex('#D7DCE2');
    final highlightColor = PdfColor.fromHex('#FFF0A8');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(0, 0, 0, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Container(
            color: headerColor,
            padding: const pw.EdgeInsets.fromLTRB(30, 28, 30, 22),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 75,
                  height: 75,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.white, width: 1.9),
                  ),
                  child: pw.Text(
                    _resumeInitials(resume),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 25),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _highlightedCorporateNameText(
                        _displayName(resume).toUpperCase(),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        _resumeContactItems(resume).join(' | '),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: headerContactFontPt,
                          lineSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _highlightedAtsNoticeBar(highlightColor),
          pw.SizedBox(height: 18),
          _corporateSection(
            title: 'Summary',
            lineColor: lineColor,
            sectionTitleColor: sectionTitleColor,
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              color: highlightSummary ? highlightColor : PdfColors.white,
              child: pw.Text(resume.summary.trim()),
            ),
          ),
          if (resume.includeWorkInResume)
            _corporateSection(
              title: 'Experience',
              lineColor: lineColor,
              sectionTitleColor: sectionTitleColor,
              child: pw.Column(
                children: [
                  for (
                    var index = 0;
                    index < resume.visibleWorkExperiences.length;
                    index++
                  )
                    _buildHighlightedCorporateExperience(
                      resume.visibleWorkExperiences[index],
                      highlightedBulletsByExperience[index] ?? const <String>{},
                      highlightColor,
                      bodyFontPt: bodyPt,
                    ),
                ],
              ),
            ),
          if (resume.includeEducationInResume)
            _corporateSection(
              title: 'Education',
              lineColor: lineColor,
              sectionTitleColor: sectionTitleColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final item in resume.visibleEducation)
                    _buildCorporateEducation(item, bodyFontPt: bodyPt),
                ],
              ),
            ),
          if (resume.includeSkillsInResume)
            _corporateSection(
              title: 'Skills',
              lineColor: lineColor,
              sectionTitleColor: sectionTitleColor,
              child: pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _skillsForDisplay(resume)
                    .map(
                      (skill) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: pw.BoxDecoration(
                          color: highlightedSkills.contains(skill)
                              ? highlightColor
                              : PdfColor.fromHex('#F4F6F8'),
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          skill,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (resume.includeProjectsInResume)
            _corporateSection(
              title: 'Projects',
              lineColor: lineColor,
              sectionTitleColor: sectionTitleColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleProjects)
                    _buildCompactProject(item, bodyFontPt: bodyPt),
                ],
              ),
            ),
          for (final item in resume.visibleCustomSections)
            _corporateSection(
              title: item.title.ifEmpty('Custom Section'),
              lineColor: lineColor,
              sectionTitleColor: sectionTitleColor,
              child: _pwCustomSectionBody(item),
            ),
        ],
      ),
    );
  }


  pw.Widget _highlightedCorporateNameText(String value) {
    final style = pw.TextStyle(
      color: PdfColors.white,
      fontSize: ResumeTypography.darkHeaderNamePt,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Text(value, style: style);
  }

  void _addHighlightedCreativeTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final accentColor = _corporateHeaderPdf(resume);
    final textColor = _corporateTitlePdf(resume);
    final lineColor = _creativeSidebarLineColorPdf();
    final muted = _creativeSidebarMutedColorPdf();
    final railColor = _creativeSidebarRailColorPdf();
    final highlightColor = PdfColor.fromHex('#FFF0A8');
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final contactItems = _resumeContactItems(resume);
    final educationItems = resume.includeEducationInResume
        ? resume.visibleEducation
        : const <EducationItem>[];

    document.addPage(
      pw.MultiPage(
        pageTheme: _creativeSidebarPageTheme(railColor: railColor),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: _creativeSidebarContentWidthPt,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _creativeAvatarIconPlaceholder(width: 88, height: 104),
                    pw.SizedBox(height: 14),
                    pw.Text(
                      _displayName(resume).toUpperCase(),
                      style: pw.TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                        lineSpacing: 1,
                      ),
                    ),
                    if (resume.jobTitle.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        resume.jobTitle.trim(),
                        style: pw.TextStyle(
                          color: muted,
                          fontSize: bodyPt,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                    if (contactItems.isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      pw.Container(height: 1.2, color: lineColor),
                      pw.SizedBox(height: 10),
                      for (final item in contactItems)
                        _creativeSidebarContactRow(
                          item,
                          iconColor: accentColor,
                          textColor: muted,
                          fontSize: bodyPt,
                        ),
                    ],
                    if (educationItems.isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      _creativeSectionHeadingRow(
                        title: 'Education',
                        titleColor: textColor,
                        lineColor: lineColor,
                      ),
                      pw.SizedBox(height: 8),
                      for (final item in educationItems)
                        _creativeSidebarEducationEntry(
                          item,
                          titleColor: textColor,
                          mutedColor: muted,
                          bodyFontPt: bodyPt,
                        ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: _creativeSidebarGapPt),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _creativeMainSection(
                      title: 'Summary',
                      titleColor: textColor,
                      lineColor: lineColor,
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
                            fontSize: bodyPt,
                            color: muted,
                            lineSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _highlightedAtsNoticeBar(highlightColor),
                    if (resume.includeWorkInResume) ...[
                      pw.SizedBox(height: 10),
                      _creativeMainSection(
                        title: 'Experience',
                        titleColor: textColor,
                        lineColor: lineColor,
                        child: pw.Column(
                          children: [
                            for (
                              var index = 0;
                              index < resume.visibleWorkExperiences.length;
                              index++
                            )
                              _buildHighlightedCreativeExperience(
                                resume.visibleWorkExperiences[index],
                                highlightedBulletsByExperience[index] ??
                                    const <String>{},
                                highlightColor,
                                bodyFontPt: bodyPt,
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (resume.includeSkillsInResume) ...[
                      pw.SizedBox(height: 6),
                      _creativeMainSection(
                        title: 'Skills',
                        titleColor: textColor,
                        lineColor: lineColor,
                        child: _twoColumnBulletListWithHighlights(
                          _skillsForDisplay(resume),
                          highlightedSkills,
                          highlightColor,
                          fontSize: bodyPt,
                        ),
                      ),
                    ],
                    if (resume.includeProjectsInResume) ...[
                      pw.SizedBox(height: 6),
                      _creativeMainSection(
                        title: 'Projects',
                        titleColor: textColor,
                        lineColor: lineColor,
                        child: pw.Column(
                          children: [
                            for (final item in resume.visibleProjects)
                              _buildCompactProject(
                                item,
                                bodyFontPt: bodyPt,
                              ),
                          ],
                        ),
                      ),
                    ],
                    for (final item in resume.visibleCustomSections) ...[
                      pw.SizedBox(height: 6),
                      _creativeMainSection(
                        title: item.title.ifEmpty('Custom Section'),
                        titleColor: textColor,
                        lineColor: lineColor,
                        child: _pwCustomSectionBody(item),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



}
