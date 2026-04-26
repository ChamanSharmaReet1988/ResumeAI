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
                        width: 75,
                        height: 75,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.white,
                            width: 1.9,
                          ),
                        ),
                        child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                      )
                    : pw.Container(
                        width: 75,
                        height: 75,
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
                            fontSize: 30,
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
                        pw.SizedBox(height: 10),
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
    final accentColor = _creativeSidebarAccentColorPdf(resume);
    final textColor = _creativeTitleColorPdf(resume);
    final lineColor = _creativeSidebarLineColorPdf();
    final muted = _creativeSidebarMutedColorPdf();
    final railColor = _creativeSidebarRailColorPdf(resume);
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
                _buildCreativeExperience(
                  item,
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
            for (final row
                in _twoColumnBulletRows(
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
                _buildCompactProject(
                  item,
                  bodyFontPt: bodyPt,
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
              ),
            ),
            pw.SizedBox(height: _creativeHeadingBodyGapPt),
            _creativeMainColumnChild(_pwCustomSectionBody(item)),
          ],
        ],
      ),
    );
  }



}
