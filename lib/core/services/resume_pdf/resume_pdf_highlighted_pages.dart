part of 'package:resume_app/core/services/resume_services.dart';

extension _ResumePdfHighlightedTemplatePages on ResumePdfService {
  void _addHighlightedCorporateTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final headerColor = PdfColor.fromHex('#243447');
    final lineColor = PdfColor.fromHex('#D7DCE2');
    final highlightColor = PdfColor.fromHex('#FFF0A8');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
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
                    border: pw.Border.all(color: PdfColors.white, width: 1.4),
                  ),
                  child: pw.Text(
                    _resumeInitials(resume),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 18),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _highlightedCorporateNameText(
                        _displayName(resume).toUpperCase(),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        _resumeContactItems(resume).join('  /  '),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: ResumeTypography.bodyPt,
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
          if (resume.includeSkillsInResume)
            _corporateSection(
              title: 'Skills',
              lineColor: lineColor,
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
          if (resume.visibleWorkExperiences.isNotEmpty)
            _corporateSection(
              title: 'Experience',
              lineColor: lineColor,
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
                    ),
                ],
              ),
            ),
          if (resume.visibleEducation.isNotEmpty)
            _corporateSection(
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
          if (resume.visibleProjects.isNotEmpty)
            _corporateSection(
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
            _corporateSection(
              title: item.title.ifEmpty('Custom Section'),
              lineColor: lineColor,
              child: _pwCustomSectionBody(item),
            ),
        ],
      ),
    );
  }

  void _addHighlightedMinimalTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final lineColor = PdfColor.fromHex('#D7DCE2');
    final textMuted = PdfColor.fromHex('#5E6369');
    final highlightColor = PdfColor.fromHex('#FFF0A8');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 28),
        build: (context) => [
          _highlightedAtsNoticeBar(highlightColor),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Container(
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
                  fontSize: 16,
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
          _minimalSection(
            title: 'Skills',
            lineColor: lineColor,
            child: _twoColumnBulletListWithHighlights(
              _skillsForDisplay(resume),
              highlightedSkills,
              highlightColor,
            ),
          ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _minimalSection(
              title: 'Experience',
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (
                    var index = 0;
                    index < resume.visibleWorkExperiences.length;
                    index++
                  )
                    _buildHighlightedMinimalExperience(
                      resume.visibleWorkExperiences[index],
                      highlightedBulletsByExperience[index] ?? const <String>{},
                      highlightColor,
                    ),
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

  pw.Widget _highlightedCorporateNameText(String value) {
    final style = pw.TextStyle(
      color: PdfColors.white,
      fontSize: ResumeTypography.namePt,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Stack(
      children: [
        pw.Text(value, style: style),
        pw.Positioned(left: 0.25, top: 0, child: pw.Text(value, style: style)),
        pw.Positioned(left: 0.5, top: 0, child: pw.Text(value, style: style)),
      ],
    );
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
        margin: pw.EdgeInsets.zero,
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
                          fontSize: 22,
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

  void _addHighlightedCopperSerifTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final copper = PdfColor.fromHex('#E7A055');
    final lineColor = PdfColor.fromHex('#D5D9DE');
    final muted = PdfColor.fromHex('#6A7076');
    final highlightColor = PdfColor.fromHex('#FFF0A8');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        build: (context) => [
          _highlightedAtsNoticeBar(highlightColor),
          pw.SizedBox(height: 12),
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
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                color: highlightSummary ? highlightColor : PdfColors.white,
                child: pw.Text(
                  resume.summary.trim(),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          _centeredAccentSection(
            title: 'Skills',
            accentColor: copper,
            lineColor: lineColor,
            child: _twoColumnBulletListWithHighlights(
              _skillsForDisplay(resume),
              highlightedSkills,
              highlightColor,
            ),
          ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _centeredAccentSection(
              title: 'Experience',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (
                    var index = 0;
                    index < resume.visibleWorkExperiences.length;
                    index++
                  )
                    _buildHighlightedMinimalExperience(
                      resume.visibleWorkExperiences[index],
                      highlightedBulletsByExperience[index] ?? const <String>{},
                      highlightColor,
                    ),
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
                              item.year.trim(),
                              item.score.trim(),
                              item.details.trim(),
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

  void _addHighlightedSplitBannerTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final copper = PdfColor.fromHex('#EE9938');
    final lineColor = PdfColor.fromHex('#D7DBE0');
    final highlightColor = PdfColor.fromHex('#FFF0A8');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 28),
        build: (context) => [
          pw.Container(
            color: copper,
            padding: const pw.EdgeInsets.fromLTRB(22, 16, 22, 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _highlightedAtsNoticeBar(highlightColor),
                pw.SizedBox(height: 10),
                pw.Row(
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
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          if (resume.summary.trim().isNotEmpty)
            _splitBannerSection(
              title: 'Summary',
              accentColor: copper,
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
          _splitBannerSection(
            title: 'Skills',
            accentColor: copper,
            lineColor: lineColor,
            child: _twoColumnBulletListWithHighlights(
              _skillsForDisplay(resume),
              highlightedSkills,
              highlightColor,
            ),
          ),
          if (resume.visibleWorkExperiences.isNotEmpty)
            _splitBannerSection(
              title: 'Experience',
              accentColor: copper,
              lineColor: lineColor,
              child: pw.Column(
                children: [
                  for (
                    var index = 0;
                    index < resume.visibleWorkExperiences.length;
                    index++
                  )
                    _buildHighlightedMinimalExperience(
                      resume.visibleWorkExperiences[index],
                      highlightedBulletsByExperience[index] ?? const <String>{},
                      highlightColor,
                    ),
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

  void _addHighlightedMonogramSidebarTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required bool highlightSummary,
    required Set<String> highlightedSkills,
    required Map<int, Set<String>> highlightedBulletsByExperience,
  }) {
    final copper = PdfColor.fromHex('#E39A3A');
    final dark = PdfColor.fromHex('#17181A');
    final lineColor = PdfColor.fromHex('#D5D9DE');
    final muted = PdfColor.fromHex('#666B71');
    final highlightColor = PdfColor.fromHex('#FFF0A8');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 28),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _highlightedAtsNoticeBar(highlightColor),
              pw.SizedBox(height: 12),
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
                        pw.Container(
                          width: 48,
                          height: 48,
                          alignment: pw.Alignment.center,
                          color: dark,
                          child: pw.Text(
                            _resumeInitials(resume),
                            style: pw.TextStyle(
                              color: copper,
                              fontSize: 22,
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
                            child: pw.Container(
                              width: double.infinity,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              color: highlightSummary
                                  ? highlightColor
                                  : PdfColors.white,
                              child: pw.Text(resume.summary.trim()),
                            ),
                          ),
                        _monogramSidebarSection(
                          title: 'Skills',
                          child: _twoColumnBulletListWithHighlights(
                            _skillsForDisplay(resume),
                            highlightedSkills,
                            highlightColor,
                          ),
                        ),
                        if (resume.visibleWorkExperiences.isNotEmpty)
                          _monogramSidebarSection(
                            title: 'Experience',
                            child: pw.Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < resume.visibleWorkExperiences.length;
                                  index++
                                )
                                  _buildHighlightedMinimalExperience(
                                    resume.visibleWorkExperiences[index],
                                    highlightedBulletsByExperience[index] ??
                                        const <String>{},
                                    highlightColor,
                                  ),
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
        ],
      ),
    );
  }
}
