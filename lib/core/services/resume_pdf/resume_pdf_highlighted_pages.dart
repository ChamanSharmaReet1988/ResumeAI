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
                  width: 48,
                  height: 48,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.white, width: 1.9),
                  ),
                  child: pw.Text(
                    _resumeInitials(resume),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 19,
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
                      pw.SizedBox(height: 6),
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
          if (resume.summary.trim().isNotEmpty)
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
          if (resume.visibleWorkExperiences.isNotEmpty)
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
          if (resume.visibleEducation.isNotEmpty)
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
          if (resume.visibleProjects.isNotEmpty)
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
    final dark = PdfColor.fromHex('#353A40');
    final lineColor = PdfColor.fromHex('#B8BEC6');
    final muted = PdfColor.fromHex('#5D6268');
    final highlightColor = PdfColor.fromHex('#FFF0A8');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(0, 0, 0, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Container(height: 18, color: dark),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(28, 22, 28, 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _highlightedAtsNoticeBar(highlightColor),
                pw.SizedBox(height: 14),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 68,
                      height: 84,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#EED7BF'),
                        border: pw.Border.all(color: lineColor),
                      ),
                      child: pw.Text(
                        _resumeInitials(resume),
                        style: pw.TextStyle(
                          fontSize: 25,
                          fontWeight: pw.FontWeight.bold,
                          color: dark,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _displayName(resume).toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: ResumeTypography.namePt,
                              fontWeight: pw.FontWeight.bold,
                              color: dark,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          for (final item in _resumeContactItems(resume))
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text(
                                item,
                                style: pw.TextStyle(
                                  fontSize: ResumeTypography.bodyPt,
                                  color: muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                if (resume.summary.trim().isNotEmpty)
                  _creativeSection(
                    title: 'Summary',
                    lineColor: lineColor,
                    child: pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      color: highlightSummary ? highlightColor : PdfColors.white,
                      child: pw.Text(resume.summary.trim()),
                    ),
                  ),
                _creativeSection(
                  title: 'Skills',
                  lineColor: lineColor,
                  child: _twoColumnBulletListWithHighlights(
                    _skillsForDisplay(resume),
                    highlightedSkills,
                    highlightColor,
                  ),
                ),
                if (resume.visibleWorkExperiences.isNotEmpty)
                  _creativeSection(
                    title: 'Experience',
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
                          ),
                      ],
                    ),
                  ),
                if (resume.visibleEducation.isNotEmpty)
                  _creativeSection(
                    title: 'Education and Training',
                    lineColor: lineColor,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        for (final item in resume.visibleEducation)
                          _buildCorporateEducation(item),
                      ],
                    ),
                  ),
                if (resume.visibleProjects.isNotEmpty)
                  _creativeSection(
                    title: 'Projects',
                    lineColor: lineColor,
                    child: pw.Column(
                      children: [
                        for (final item in resume.visibleProjects)
                          _buildCompactProject(item),
                      ],
                    ),
                  ),
                for (final item in resume.visibleCustomSections)
                  _creativeSection(
                    title: item.title.ifEmpty('Custom Section'),
                    lineColor: lineColor,
                    child: _pwCustomSectionBody(item),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }



}
