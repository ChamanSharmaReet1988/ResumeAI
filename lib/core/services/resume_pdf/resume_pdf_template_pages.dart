part of 'package:resume_app/core/services/resume_services.dart';

extension _ResumePdfTemplatePages on ResumePdfService {
  pw.Widget _continuedPageTopGap(pw.Context context) =>
      context.pageNumber > 1 ? pw.SizedBox(height: 40) : pw.SizedBox();

  void _addCorporateTemplatePage(
    pw.Document document,
    ResumeData resume, {
    pw.MemoryImage? profileImage,
  }) {
    final headerColor = PdfColor.fromHex('#3B4046');
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
                            width: 1.4,
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
                            width: 1.4,
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
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: ResumeTypography.bodyPt,
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
          if (resume.summary.trim().isNotEmpty)
            _darkHeaderSection(
              title: 'Summary',
              lineColor: lineColor,
              child: pw.Text(resume.summary.trim()),
            ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            ..._darkHeaderExperienceSectionWidgets(
              resume.visibleWorkExperiences,
              lineColor,
            ),
          if (resume.visibleEducation.isNotEmpty)
            _darkHeaderSection(
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
          if (resume.includeSkillsInResume)
            _darkHeaderSection(
              title: 'Skills',
              lineColor: lineColor,
              child: _twoColumnBulletList(
                _skillsForDisplay(resume),
                columnGap: 24,
                itemBottom: 5,
              ),
            ),
          if (resume.visibleProjects.isNotEmpty)
            _darkHeaderSection(
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
            _darkHeaderSection(
              title: item.title.ifEmpty('Custom Section'),
              lineColor: lineColor,
              child: _pwCustomSectionBody(item),
            ),
        ],
      ),
    );
  }

  pw.Widget _darkHeaderSection({
    required String title,
    required PdfColor lineColor,
    required pw.Widget child,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: _darkHeaderHeadingText(title.toUpperCase()),
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
  ) {
    final widgets = <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: _darkHeaderHeadingText('EXPERIENCE'),
      ),
      pw.SizedBox(height: 7),
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: pw.Container(height: 2, color: lineColor),
      ),
      pw.SizedBox(height: 12),
    ];

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
                fontSize: ResumeTypography.bodyPt,
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
      fontSize: 27,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Text(value, style: style);
  }


  pw.Widget _darkHeaderHeadingText(String value) {
    final style = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: const PdfColor(0, 0, 0),
      letterSpacing: 0.1,
    );
    return pw.Text(value, style: style);
  }

  void _addMinimalTemplatePage(
    pw.Document document,
    ResumeData resume, {
    pw.MemoryImage? profileImage,
  }) {
    final lineColor = PdfColor.fromHex('#D7DCE2');
    final textMuted = PdfColor.fromHex('#5E6369');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 0, 28, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Center(
            child: profileImage != null
                ? pw.ClipOval(
                    child: pw.SizedBox(
                      width: 48,
                      height: 48,
                      child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                    ),
                  )
                : pw.Container(
                    width: 44,
                    height: 44,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.grey700, width: 1),
                    ),
                    child: pw.Text(
                      _resumeInitials(resume),
                      style: pw.TextStyle(
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              _displayName(resume).toUpperCase(),
              style: pw.TextStyle(
                fontSize: ResumeTypography.namePt,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              _resumeContactItems(resume).join('  |  '),
              style: pw.TextStyle(
                fontSize: ResumeTypography.bodyPt,
                color: textMuted,
              ),
            ),
          ),
          pw.SizedBox(height: 18),
          if (resume.summary.trim().isNotEmpty)
            _minimalSection(
              title: 'Summary',
              lineColor: lineColor,
              child: pw.Text(resume.summary.trim()),
            ),
          if (resume.includeSkillsInResume)
            _minimalSection(
              title: 'Skills',
              lineColor: lineColor,
              child: _twoColumnBulletList(_skillsForDisplay(resume)),
            ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _minimalSection(
              title: 'Experience',
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleWorkExperiences)
                    _buildMinimalExperience(item),
                ],
              ),
            ),
          if (resume.visibleEducation.isNotEmpty)
            _minimalSection(
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
            _minimalSection(
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
            _minimalSection(
              title: item.title.ifEmpty('Custom Section'),
              lineColor: lineColor,
              child: _pwCustomSectionBody(item),
            ),
        ],
      ),
    );
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
                if (resume.summary.trim().isNotEmpty)
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
                if (resume.visibleWorkExperiences.isNotEmpty)
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

  void _addCopperSerifTemplatePage(
    pw.Document document,
    ResumeData resume, {
    pw.MemoryImage? profileImage,
  }) {
    final copper = PdfColor.fromHex('#E7A055');
    final lineColor = PdfColor.fromHex('#D5D9DE');
    final muted = PdfColor.fromHex('#6A7076');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 0, 28, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          if (profileImage != null) ...[
            pw.Center(
              child: pw.ClipOval(
                child: pw.SizedBox(
                  width: 52,
                  height: 52,
                  child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          pw.Center(
            child: pw.Text(
              _displayName(resume).toUpperCase(),
              style: pw.TextStyle(
                fontSize: ResumeTypography.namePt,
                color: copper,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              _resumeContactItems(resume).join('   |   '),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: ResumeTypography.bodyPt,
                color: muted,
              ),
            ),
          ),
          pw.SizedBox(height: 18),
          if (resume.summary.trim().isNotEmpty)
            _centeredAccentSection(
              title: 'Summary',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Text(
                resume.summary.trim(),
                textAlign: pw.TextAlign.center,
              ),
            ),
          if (resume.includeSkillsInResume)
            _centeredAccentSection(
              title: 'Skills',
              accentColor: copper,
              lineColor: lineColor,
              child: _twoColumnBulletList(_skillsForDisplay(resume)),
            ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _centeredAccentSection(
              title: 'Experience',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleWorkExperiences)
                    _buildMinimalExperience(item),
                ],
              ),
            ),
          if (resume.visibleEducation.isNotEmpty)
            _centeredAccentSection(
              title: 'Education and Training',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  for (final item in resume.visibleEducation)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            item.degree.ifEmpty('Degree'),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            [
                              item.institution.trim(),
                              [
                                item.startDate.trim(),
                                item.endDate.trim(),
                              ].where((part) => part.isNotEmpty).join(' - '),
                            ].where((part) => part.isNotEmpty).join('   |   '),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (resume.visibleProjects.isNotEmpty)
            _centeredAccentSection(
              title: 'Projects',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleProjects)
                    _buildCompactProject(item),
                ],
              ),
            ),
          for (final item in resume.visibleCustomSections)
            _centeredAccentSection(
              title: item.title.ifEmpty('Custom Section'),
              accentColor: copper,
              lineColor: lineColor,
              child: _pwCustomSectionBody(item),
            ),
        ],
      ),
    );
  }

  void _addSplitBannerTemplatePage(
    pw.Document document,
    ResumeData resume, {
    pw.MemoryImage? profileImage,
  }) {
    final copper = PdfColor.fromHex('#EE9938');
    final lineColor = PdfColor.fromHex('#D7DBE0');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 0, 24, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Container(
            color: copper,
            padding: const pw.EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    _displayName(resume).toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: ResumeTypography.namePt,
                      fontWeight: pw.FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (profileImage != null) ...[
                      pw.ClipOval(
                        child: pw.SizedBox(
                          width: 34,
                          height: 34,
                          child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                    ],
                    for (final item in _resumeContactItems(resume))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          item,
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: ResumeTypography.bodyPt,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          if (resume.summary.trim().isNotEmpty)
            _splitBannerSection(
              title: 'Summary',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Text(resume.summary.trim()),
            ),
          if (resume.includeSkillsInResume)
            _splitBannerSection(
              title: 'Skills',
              accentColor: copper,
              lineColor: lineColor,
              child: _twoColumnBulletList(_skillsForDisplay(resume)),
            ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _splitBannerSection(
              title: 'Experience',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleWorkExperiences)
                    _buildMinimalExperience(item),
                ],
              ),
            ),
          if (resume.visibleEducation.isNotEmpty)
            _splitBannerSection(
              title: 'Education',
              accentColor: copper,
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
            _splitBannerSection(
              title: 'Projects',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (final item in resume.visibleProjects)
                    _buildCompactProject(item),
                ],
              ),
            ),
          for (final item in resume.visibleCustomSections)
            _splitBannerSection(
              title: item.title.ifEmpty('Custom'),
              accentColor: copper,
              lineColor: lineColor,
              child: _pwCustomSectionBody(item),
            ),
          pw.SizedBox(height: 8),
          pw.Container(height: 3, color: copper),
        ],
      ),
    );
  }

  void _addMonogramSidebarTemplatePage(
    pw.Document document,
    ResumeData resume, {
    pw.MemoryImage? profileImage,
  }) {
    final copper = PdfColor.fromHex('#E39A3A');
    final dark = PdfColor.fromHex('#17181A');
    final lineColor = PdfColor.fromHex('#D5D9DE');
    final muted = PdfColor.fromHex('#666B71');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 0, 28, 30),
        header: _continuedPageTopGap,
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 100,
                padding: const pw.EdgeInsets.only(right: 16),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(color: lineColor, width: 1),
                  ),
                ),
                child: pw.Column(
                  children: [
                    profileImage != null
                        ? pw.SizedBox(
                            width: 48,
                            height: 48,
                            child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                          )
                        : pw.Container(
                            width: 48,
                            height: 48,
                            alignment: pw.Alignment.center,
                            color: dark,
                            child: pw.Text(
                              _resumeInitials(resume),
                              style: pw.TextStyle(
                                color: copper,
                                fontSize: 25,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      _displayName(resume),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: copper,
                        fontSize: ResumeTypography.namePt,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    for (final item in _resumeContactItems(resume))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          item,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: ResumeTypography.bodyPt,
                            color: muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (resume.summary.trim().isNotEmpty)
                      _monogramSidebarSection(
                        title: 'Summary',
                        child: pw.Text(resume.summary.trim()),
                      ),
                    if (resume.includeSkillsInResume)
                      _monogramSidebarSection(
                        title: 'Skills',
                        child: _twoColumnBulletList(_skillsForDisplay(resume)),
                      ),
                    if (resume.visibleWorkExperiences.isNotEmpty)
                      _monogramSidebarSection(
                        title: 'Experience',
                        child: pw.Column(
                          children: [
                            for (final item in resume.visibleWorkExperiences)
                              _buildMinimalExperience(item),
                          ],
                        ),
                      ),
                    if (resume.visibleEducation.isNotEmpty)
                      _monogramSidebarSection(
                        title: 'Education and Training',
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            for (final item in resume.visibleEducation)
                              _buildCorporateEducation(item),
                          ],
                        ),
                      ),
                    if (resume.visibleProjects.isNotEmpty)
                      _monogramSidebarSection(
                        title: 'Projects',
                        child: pw.Column(
                          children: [
                            for (final item in resume.visibleProjects)
                              _buildCompactProject(item),
                          ],
                        ),
                      ),
                    for (final item in resume.visibleCustomSections)
                      _monogramSidebarSection(
                        title: item.title.ifEmpty('Custom Section'),
                        child: _pwCustomSectionBody(item),
                      ),
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
