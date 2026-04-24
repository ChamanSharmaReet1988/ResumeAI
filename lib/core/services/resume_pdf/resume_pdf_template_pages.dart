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
    final headerContactFontPt = bodyPt + 2;
    final sectionTitleColor = _corporateTitlePdf(resume);
    final headerColor = _corporateHeaderPdf(resume);
    final lineColor = PdfColor.fromHex('#D7DCE2');
    final headerContactItems = _resumeContactItems(resume);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(0, 0, 0, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Container(
            color: headerColor,
            padding: const pw.EdgeInsets.fromLTRB(30, 36, 30, 30),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                profileImage != null
                    ? pw.Container(
                        width: 48,
                        height: 48,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.white,
                            width: 1.9,
                          ),
                        ),
                        child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                      )
                    : pw.Container(
                        width: 48,
                        height: 48,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.white,
                            width: 1.9,
                          ),
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
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 0),
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _darkHeaderNameText(
                          _displayName(resume).toUpperCase(),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          headerContactItems.join(' | '),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: headerContactFontPt,
                            lineSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          _darkHeaderSection(
            title: 'Summary',
            lineColor: lineColor,
            sectionTitleColor: sectionTitleColor,
            child: pw.Text(resume.summary.trim()),
          ),
          if (resume.includeWorkInResume)
            ..._darkHeaderExperienceSectionWidgets(
              resume.visibleWorkExperiences,
              lineColor,
              sectionTitleColor,
              bodyPt,
            ),
          if (resume.includeEducationInResume)
            _darkHeaderSection(
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
            _darkHeaderSection(
              title: 'Skills',
              lineColor: lineColor,
              sectionTitleColor: sectionTitleColor,
              child: _twoColumnBulletList(
                _skillsForDisplay(resume),
                columnGap: 24,
                itemBottom: 5,
                fontSize: bodyPt,
              ),
            ),
          if (resume.includeProjectsInResume)
            _darkHeaderSection(
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
            _darkHeaderSection(
              title: item.title.ifEmpty('Custom Section'),
              lineColor: lineColor,
              sectionTitleColor: sectionTitleColor,
              child: _pwCustomSectionBody(item),
            ),
        ],
      ),
    );
  }

  pw.Widget _darkHeaderSection({
    required String title,
    required PdfColor lineColor,
    required PdfColor sectionTitleColor,
    required pw.Widget child,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(
            30,
            0,
            30,
            ResumeTypography.sectionGapPdfPt,
          ),
          child: child,
        ),
      ],
    );
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
        child: _darkHeaderHeadingText(
          'EXPERIENCE',
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
              style: pw.TextStyle(
                color: PdfColors.black,
                fontSize: bodyPt,
              ),
            ),
          ),
        );
      }

      final isLast = index == items.length - 1;
      widgets.add(
        pw.SizedBox(
          height: isLast ? ResumeTypography.sectionGapPdfPt : 10,
        ),
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

  pw.Widget _darkHeaderNameText(String value) {
    final style = pw.TextStyle(
      color: PdfColors.white,
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
    final dark = PdfColor.fromHex('#353A40');
    final lineColor = PdfColor.fromHex('#B8BEC6');
    final muted = PdfColor.fromHex('#5D6268');

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
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    profileImage != null
                        ? pw.Container(
                            width: 68,
                            height: 84,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: lineColor),
                            ),
                            child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                          )
                        : pw.Container(
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
                _creativeSection(
                  title: 'Summary',
                  lineColor: lineColor,
                  child: pw.Text(resume.summary.trim()),
                ),
                if (resume.includeSkillsInResume)
                  _creativeSection(
                    title: 'Skills',
                    lineColor: lineColor,
                    child: _twoColumnBulletList(_skillsForDisplay(resume)),
                  ),
                if (resume.includeWorkInResume)
                  _creativeSection(
                    title: 'Experience',
                    lineColor: lineColor,
                    child: pw.Column(
                      children: [
                        for (final item in resume.visibleWorkExperiences)
                          _buildCreativeExperience(item),
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
                          _buildCorporateEducation(item),
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
