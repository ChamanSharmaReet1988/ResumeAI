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
    final highlightColor = PdfColor.fromHex('#FFE67A');

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
    final accentColor = _creativeSidebarAccentColorPdf(resume);
    final textColor = _creativeTitleColorPdf(resume);
    final lineColor = _creativeSidebarLineColorPdf();
    final muted = _creativeSidebarMutedColorPdf();
    final railColor = _creativeSidebarRailColorPdf(resume);
    final highlightColor = PdfColor.fromHex('#FFE67A');
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final contactItems = _resumeContactItems(resume);
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
                  lineSpacing: 2,
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
          if (resume.includeSkillsInResume) ...[
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
                _skillsForDisplay(resume),
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
              padding: const pw.EdgeInsets.only(top: _classicSidebarSectionBottomPt),
              child: _buildClassicSidebarSection(
                title: 'Summary',
                titleColor: titleColor,
                borderColor: borderColor,
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
                      lineSpacing: 2,
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
                borderColor: borderColor,
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
              ),
            ),
            for (
              var index = 0;
              index < resume.visibleWorkExperiences.length;
              index++
            )
              sidebarWrap(
                _buildClassicSidebarSectionBodyBlock(
                  borderColor: borderColor,
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
                borderColor: borderColor,
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
              ),
            ),
            for (var index = 0; index < resume.visibleEducation.length; index++)
              sidebarWrap(
                _buildClassicSidebarSectionBodyBlock(
                  borderColor: borderColor,
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
              ),
            ),
            sidebarWrap(
              _buildClassicSidebarSectionBodyBlock(
                borderColor: borderColor,
                showBottomBorder: customSections.isNotEmpty,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < resume.visibleProjects.length; i++) ...[
                      if (i > 0)
                        pw.SizedBox(height: _classicSidebarSectionBottomPt),
                      _buildClassicSidebarProject(
                        resume.visibleProjects[i],
                        titleColor: titleColor,
                        mutedColor: mutedColor,
                        accentColor: accentColor,
                        bodyPt: bodyPt,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          for (var index = 0; index < customSections.length; index++) ...[
            sidebarWrap(
              _buildClassicSidebarSectionHeading(
                title: customSections[index].title.ifEmpty('Custom Section'),
                titleColor: titleColor,
              ),
            ),
            sidebarWrap(
              _buildClassicSidebarSectionBodyBlock(
                borderColor: borderColor,
                showBottomBorder: index < customSections.length - 1,
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
}
