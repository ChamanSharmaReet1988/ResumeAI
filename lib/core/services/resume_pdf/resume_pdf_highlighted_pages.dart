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
    final dark = _corporateHeaderPdf(resume);
    final textColor = _corporateTitlePdf(resume);
    final lineColor = PdfColor.fromHex('#B8BEC6');
    final muted = PdfColor.fromHex('#5D6268');
    final highlightColor = PdfColor.fromHex('#FFF0A8');
    final bodyPt = resume.effectiveBodyFontPt.toDouble();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(0, 0, 0, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Container(height: 24, color: dark),
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
                    _creativeAvatarIconPlaceholder(),
                    pw.SizedBox(width: 26),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Transform.translate(
                            offset: const PdfPoint(0, 9),
                            child: pw.Text(
                              _displayName(resume).toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: ResumeTypography.darkHeaderNamePt,
                                fontWeight: pw.FontWeight.bold,
                                lineSpacing: 0,
                                color: textColor,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 0),
                          pw.Transform.translate(
                            offset: const PdfPoint(0, -6),
                            child: pw.Column(
                              children: [
                                for (final item in _resumeContactItems(resume))
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(bottom: 3),
                                    child: pw.Row(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                          width: 10,
                                          height: 10,
                                          margin: const pw.EdgeInsets.only(
                                            right: 6,
                                            top: 2,
                                          ),
                                          color: muted,
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(
                                            item,
                                            style: pw.TextStyle(
                                              fontSize: bodyPt,
                                              color: muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
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
                if (resume.includeWorkInResume)
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
                            bodyFontPt: bodyPt,
                          ),
                      ],
                    ),
                  ),
                if (resume.includeEducationInResume)
                  _creativeSection(
                    title: 'Education',
                    lineColor: lineColor,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        for (final item in resume.visibleEducation)
                          _buildCorporateEducation(
                            item,
                            bodyFontPt: bodyPt,
                          ),
                      ],
                    ),
                  ),
                if (resume.includeProjectsInResume)
                  _creativeSection(
                    title: 'Projects',
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
