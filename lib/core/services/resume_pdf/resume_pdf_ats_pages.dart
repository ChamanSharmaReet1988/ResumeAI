part of 'package:resume_app/core/services/resume_services.dart';

pw.Widget _atsMultiPageHeaderGap(pw.Context context) =>
    context.pageNumber > 1 ? pw.SizedBox(height: 40) : pw.SizedBox();

pw.Widget _atsSerifRulesMultiPageHeaderGap(pw.Context context) =>
    context.pageNumber > 1
    ? pw.SizedBox(
        height: ResumeTypography.atsSerifRulesContinuationPageTopGapPt,
      )
    : pw.SizedBox();

/// Slightly smaller than body text so keyword lists read lighter than paragraphs.
double _atsPdfSkillsBodyPt(double bodyPt) => math.max(9.0, bodyPt - 1.35);

pw.Widget _atsHighlightedSummaryText(
  String summary, {
  required double bodyPt,
  required bool highlightSummary,
  required PdfColor highlightColor,
  pw.TextStyle? textStyle,
}) {
  final resolvedStyle =
      textStyle ??
      pw.TextStyle(
        fontSize: bodyPt,
        lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
      );
  if (!highlightSummary) {
    return pw.Text(summary, style: resolvedStyle);
  }
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    color: highlightColor,
    child: pw.Text(summary, style: resolvedStyle),
  );
}

pw.Widget _atsHighlightedBulletLine(
  String text, {
  required pw.TextStyle style,
  required bool isHighlighted,
  required PdfColor highlightColor,
}) {
  if (!isHighlighted) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Text(text, style: style),
    );
  }
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 2),
    child: pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: highlightColor,
      child: pw.Text(text, style: style),
    ),
  );
}

/// Single-column ATS PDF layouts (no sidebars, minimal decoration).
extension _ResumePdfAtsPages on ResumePdfService {
  PdfColor get _atsMuted => PdfColor.fromHex('#5C5C5C');

  String _atsWorkDateRange(WorkExperience item) {
    final start = item.startDate.trim();
    final end = item.endDate.trim();
    if (start.isEmpty && end.isEmpty) {
      return '';
    }
    return '${start.isNotEmpty ? start : ''}'
        '${start.isNotEmpty && end.isNotEmpty ? ' — ' : ''}'
        '${end.isNotEmpty ? end : ''}';
  }

  List<String> _atsHeaderContactLines(ResumeData resume) =>
      resume.atsStructuredHeaderContactLines();

  pw.Widget _atsSolidRule({PdfColor color = PdfColors.black}) {
    return pw.Container(height: 1, color: color);
  }

  PdfColor _atsAccentPdf(ResumeData resume) => _pdfRgb(resume.atsAccentColor);

  pw.Widget _atsGraySectionTitle(
    String title,
    GaramondPdfFonts garamond,
    PdfColor accent,
    PdfColor band,
  ) {
    return pw.Container(
      width: double.infinity,
      color: band,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: pw.Center(
        child: pw.Text(
          title.toUpperCase(),
          style: garamondPdfTextStyle(
            garamond,
            ResumeTypography.atsStructuredTitleWeight,
            fontSize: ResumeTypography.atsStructuredSectionTitlePt,
            color: accent,
          ).copyWith(decoration: pw.TextDecoration.underline),
        ),
      ),
    );
  }

  static final PdfColor _atsHighlightColor = PdfColor.fromHex('#FFE67A');

  List<pw.Widget> _atsExperienceEntries(
    List<WorkExperience> items,
    double bodyPt, {
    bool usePipeRoleCompany = false,
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
    PdfColor? highlightColor,
    GaramondPdfFonts? garamond,
    bool atsExecutiveGaramondBody = false,
  }) {
    final subtitleStyle = garamond != null
        ? garamondPdfTextStyle(
            garamond,
            ResumeTypography.atsStructuredSubtitleWeight,
            fontSize: ResumeTypography.atsStructuredSubtitlePt,
            color: PdfColors.black,
          )
        : pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: bodyPt,
            color: PdfColors.black,
          );
    final bodyStyle = garamond != null
        ? (atsExecutiveGaramondBody
              ? atsExecutiveBodyPdfTextStyle(garamond, bodyPt)
              : atsStructuredBodyPdfTextStyle(garamond, bodyPt))
        : pw.TextStyle(color: PdfColors.black, fontSize: bodyPt);
    final mutedDateStyle = garamond != null
        ? (atsExecutiveGaramondBody
              ? atsExecutiveBodyPdfTextStyle(
                  garamond,
                  bodyPt,
                  color: _atsMuted,
                  fontStyle: pw.FontStyle.italic,
                )
              : atsStructuredBodyPdfTextStyle(
                  garamond,
                  bodyPt,
                  color: _atsMuted,
                  fontStyle: pw.FontStyle.italic,
                ))
        : pw.TextStyle(
            fontSize: bodyPt,
            color: _atsMuted,
            fontStyle: pw.FontStyle.italic,
          );
    final out = <pw.Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final dateStr = _atsWorkDateRange(item);
      if (usePipeRoleCompany) {
        final top = dateStr.isEmpty
            ? item.role.ifEmpty('Role').toUpperCase()
            : '${item.role.ifEmpty('Role').toUpperCase()} | $dateStr';
        out.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [pw.Expanded(child: pw.Text(top, style: subtitleStyle))],
          ),
        );
        out.add(pw.SizedBox(height: 2));
        out.add(pw.Text(item.company.ifEmpty('Company'), style: bodyStyle));
      } else {
        out.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '* ${item.role.ifEmpty('Role')}, ${item.company.ifEmpty('Company')}',
                  style: subtitleStyle,
                ),
              ),
              if (dateStr.isNotEmpty) pw.Text(dateStr, style: mutedDateStyle),
            ],
          ),
        );
      }
      out.add(pw.SizedBox(height: 4));
      final highlightedBullets =
          highlightedBulletsByExperience[i] ?? const <String>{};
      for (final b in _workBulletLines(item)) {
        final lineStyle = bodyStyle;
        final isHighlighted =
            highlightColor != null && highlightedBullets.contains(b);
        out.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 2, top: 2),
            child: isHighlighted
                ? pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    color: highlightColor,
                    child: pw.Text(b, style: lineStyle),
                  )
                : pw.Text(b, style: lineStyle),
          ),
        );
      }
      if (i < items.length - 1) {
        out.add(pw.SizedBox(height: 10));
      }
    }
    return out;
  }

  void _addAtsStructuredTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final bodyStyle = atsStructuredBodyPdfTextStyle(garamond, bodyPt);
    final contactStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredContactWeight,
      fontSize: bodyPt,
      color: PdfColors.black,
    );
    final name = _displayName(resume).toUpperCase();
    final job = resume.jobTitle.trim();
    final contact = _atsHeaderContactLines(resume);
    final skills = _skillsForDisplay(resume);
    final accent = _atsAccentPdf(resume);
    final band = _pdfRgb(resume.atsStructuredSectionBandColor);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
        header: _atsMultiPageHeaderGap,
        build: (context) {
          final w = <pw.Widget>[
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    name,
                    textAlign: pw.TextAlign.center,
                    style: garamondPdfTextStyle(
                      garamond,
                      ResumeTypography.atsStructuredNameWeight,
                      fontSize: ResumeTypography.atsStructuredNamePt,
                      color: PdfColors.black,
                    ),
                  ),
                  if (job.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      job,
                      textAlign: pw.TextAlign.center,
                      style: garamondPdfTextStyle(
                        garamond,
                        ResumeTypography.atsStructuredTitleWeight,
                        fontSize: ResumeTypography.atsStructuredJobTitlePt,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                  if (contact.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    for (var i = 0; i < contact.length; i++)
                      pw.Padding(
                        padding: pw.EdgeInsets.only(top: i == 0 ? 0 : 2),
                        child: _pdfContactText(
                          contact[i],
                          textAlign: pw.TextAlign.center,
                          style: contactStyle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            _atsSolidRule(),
            pw.SizedBox(height: 12),
            _atsGraySectionTitle('Summary', garamond, accent, band),
            pw.SizedBox(height: 6),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Add a concise summary aligned to your target roles.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
              textStyle: bodyStyle,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
          ];

          w.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              buildSection: (id) {
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.add(
                    _atsGraySectionTitle(
                      section.title.ifEmpty('Additional'),
                      garamond,
                      accent,
                      band,
                    ),
                  );
                  out.add(pw.SizedBox(height: 6));
                  out.addAll(
                    _pwCustomSectionBodyWidgets(
                      section,
                      garamond: garamond,
                      bodyFontPt: bodyPt,
                    ),
                  );
                  out.add(
                    pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    out.add(
                      _atsGraySectionTitle(
                        'Experience',
                        garamond,
                        accent,
                        band,
                      ),
                    );
                    out.add(pw.SizedBox(height: 6));
                    final items = resume.visibleWorkExperiences;
                    if (items.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add your professional experience.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      out.addAll(
                        _atsExperienceEntries(
                          items,
                          bodyPt,
                          highlightedBulletsByExperience:
                              highlightedBulletsByExperience,
                          highlightColor: highlightColor,
                          garamond: garamond,
                        ),
                      );
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    out.add(
                      _atsGraySectionTitle(
                        'Education',
                        garamond,
                        accent,
                        band,
                      ),
                    );
                    out.add(pw.SizedBox(height: 6));
                    final edu = resume.visibleEducation;
                    if (edu.isEmpty) {
                      out.add(pw.Text('Add your education.', style: bodyStyle));
                    } else {
                      for (final item in edu) {
                        out.add(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  '* ${item.institution.ifEmpty('School')}',
                                  style: garamondPdfTextStyle(
                                    garamond,
                                    ResumeTypography
                                        .atsStructuredSubtitleWeight,
                                    fontSize: ResumeTypography
                                        .atsStructuredSubtitlePt,
                                    color: PdfColors.black,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Expanded(
                                      child: pw.Text(
                                        item.degree.ifEmpty('Degree'),
                                        style: atsStructuredBodyPdfTextStyle(
                                          garamond,
                                          bodyPt,
                                          fontStyle: pw.FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    pw.Text(
                                      educationDateRangeLabel(
                                        item.startDate,
                                        item.endDate,
                                      ),
                                      style: atsStructuredBodyPdfTextStyle(
                                        garamond,
                                        bodyPt,
                                        color: _atsMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    if (!resume.includeSkillsInResume) return null;
                    out.add(
                      _atsGraySectionTitle('Skills', garamond, accent, band),
                    );
                    out.add(pw.SizedBox(height: 6));
                    final skillsBodyStyle = atsStructuredBodyPdfTextStyle(
                      garamond,
                      _atsPdfSkillsBodyPt(bodyPt),
                    );
                    if (resume.showCategorisedSkills) {
                      out.addAll(
                        _categorisedSkillsPdfWidgets(
                          resume,
                          bodyStyle: skillsBodyStyle,
                          categoryStyle: _skillCategorySubtitlePdfStyle(
                            garamond,
                            weight:
                                ResumeTypography.atsStructuredSubtitleWeight,
                            fontSize:
                                ResumeTypography.atsStructuredSubtitlePt,
                          ),
                        ),
                      );
                    } else if (skills.isEmpty) {
                      out.add(
                        pw.Text(
                          'List relevant tools and competencies.',
                          style: bodyStyle,
                        ),
                      );
                    } else if (highlightedSkills.isNotEmpty) {
                      out.add(
                        _twoColumnBulletListWithHighlights(
                          skills,
                          highlightedSkills,
                          highlightColor,
                          fontSize: _atsPdfSkillsBodyPt(bodyPt),
                          bulletStyle: skillsBodyStyle,
                        ),
                      );
                    } else {
                      for (final row in _twoColumnBulletRows(
                        skills,
                        columnGap: 22,
                        itemBottom: 4,
                        fontSize: _atsPdfSkillsBodyPt(bodyPt),
                        bulletStyle: skillsBodyStyle,
                      )) {
                        out.add(row);
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume) return null;
                    out.add(
                      _atsGraySectionTitle(
                        'Projects',
                        garamond,
                        accent,
                        band,
                      ),
                    );
                    out.add(pw.SizedBox(height: 6));
                    final projects = resume.visibleProjects;
                    if (projects.isEmpty) {
                      out.add(
                        pw.Text(
                          'Highlight measurable outcomes.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      for (final p in projects) {
                        out.addAll(
                          _buildCompactProjectWidgets(
                            p,
                            bodyFontPt: bodyPt,
                            garamond: garamond,
                            atsGaramondBody: true,
                          ),
                        );
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

          return w;
        },
      ),
    );
  }

  void _addAtsSerifRulesTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final accent = _atsAccentPdf(resume);
    final bodyStyle = atsStructuredBodyPdfTextStyle(garamond, bodyPt);
    final contactStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredContactWeight,
      fontSize: bodyPt,
      color: PdfColors.black,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
    );
    final sectionTitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredSectionTitlePt,
      color: accent,
    );
    final subtitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: ResumeTypography.atsStructuredSubtitlePt,
      color: PdfColors.black,
    );
    final nameStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredNameWeight,
      fontSize: ResumeTypography.atsStructuredNamePt,
      color: PdfColors.black,
    );
    final jobStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredJobTitlePt,
      color: PdfColors.black,
    );
    final bodyItalicStyle = atsStructuredBodyPdfTextStyle(
      garamond,
      bodyPt,
      fontStyle: pw.FontStyle.italic,
    );
    final bodyItalicMutedStyle = atsStructuredBodyPdfTextStyle(
      garamond,
      bodyPt,
      color: _atsMuted,
      fontStyle: pw.FontStyle.italic,
    );
    final skillsBodyStyle = atsStructuredBodyPdfTextStyle(
      garamond,
      _atsPdfSkillsBodyPt(bodyPt),
    );
    final name = resume.serifRulesDisplayName;
    final job = resume.jobTitle.trim();
    final phone = resume.phone.trim();
    final loc = resume.location.trim();
    final rightContacts = resume.atsSerifRulesRightContactLines();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          ResumeTypography.atsSerifRulesPageHorizontalInsetPt,
          40,
          ResumeTypography.atsSerifRulesPageHorizontalInsetPt,
          40,
        ),
        header: _atsSerifRulesMultiPageHeaderGap,
        build: (context) {
          final w = <pw.Widget>[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(name, style: nameStyle),
                      if (job.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(job, style: jobStyle),
                      ],
                      pw.SizedBox(height: 5),
                      if (loc.isNotEmpty) pw.Text(loc, style: contactStyle),
                      if (phone.isNotEmpty) pw.Text(phone, style: contactStyle),
                    ],
                  ),
                ),
                if (rightContacts.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < rightContacts.length; i++)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(top: i == 0 ? 0 : 2),
                          child: pw.Text(
                            rightContacts[i],
                            textAlign: pw.TextAlign.right,
                            style: bodyItalicStyle,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(
              height: ResumeTypography.atsSerifRulesSectionLeadGapPt + 4,
            ),
            pw.Text('Summary', style: sectionTitleStyle),
            pw.SizedBox(
              height: ResumeTypography.atsSerifRulesSectionTitleToRuleGapPt,
            ),
            _atsSolidRule(),
            pw.SizedBox(
              height: ResumeTypography.atsSerifRulesSectionContentTopGapPt,
            ),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Summarize impact and scope in two to four sentences.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
              textStyle: bodyStyle,
            ),
            pw.SizedBox(height: ResumeTypography.atsSerifRulesSectionGapPt),
          ];

          w.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              buildSection: (id) {
                List<pw.Widget> sectionHead(String title) => [
                      pw.Text(title, style: sectionTitleStyle),
                      pw.SizedBox(
                        height: ResumeTypography
                            .atsSerifRulesSectionTitleToRuleGapPt,
                      ),
                      _atsSolidRule(),
                      pw.SizedBox(
                        height: ResumeTypography
                            .atsSerifRulesSectionContentTopGapPt,
                      ),
                    ];
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.addAll(sectionHead(section.title.ifEmpty('Additional')));
                  out.addAll(
                    _pwCustomSectionBodyWidgets(
                      section,
                      garamond: garamond,
                      bodyFontPt: bodyPt,
                    ),
                  );
                  out.add(
                    pw.SizedBox(
                      height: ResumeTypography.atsSerifRulesSectionGapPt,
                    ),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    out.addAll(sectionHead('Experience'));
                    final items = resume.visibleWorkExperiences;
                    if (items.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add roles with measurable achievements.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      for (var i = 0; i < items.length; i++) {
                        final item = items[i];
                        final dates = _atsWorkDateRange(item);
                        out.add(
                          pw.Text(
                            item.role.ifEmpty('Role'),
                            style: subtitleStyle,
                          ),
                        );
                        out.add(pw.SizedBox(height: 3));
                        out.add(
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  item.company.ifEmpty('Company'),
                                  style: bodyItalicStyle,
                                ),
                              ),
                              if (dates.isNotEmpty)
                                pw.Text(dates, style: bodyItalicMutedStyle),
                            ],
                          ),
                        );
                        out.add(pw.SizedBox(height: 4));
                        final highlightedBullets =
                            highlightedBulletsByExperience[i] ??
                                const <String>{};
                        for (final b in _workBulletLines(item)) {
                          out.add(
                            _atsHighlightedBulletLine(
                              b,
                              style: bodyStyle,
                              isHighlighted: highlightedBullets.contains(b),
                              highlightColor: highlightColor,
                            ),
                          );
                        }
                        if (i < items.length - 1) {
                          out.add(pw.SizedBox(height: 8));
                        }
                      }
                    }
                    out.add(
                      pw.SizedBox(
                        height: ResumeTypography.atsSerifRulesSectionGapPt,
                      ),
                    );
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    out.addAll(sectionHead('Education'));
                    final edu = resume.visibleEducation;
                    if (edu.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add your degrees and certifications.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      for (final item in edu) {
                        final range = educationDateRangeLabel(
                          item.startDate,
                          item.endDate,
                        );
                        out.add(
                          pw.Text(
                            '${item.degree.ifEmpty('Degree')}'
                            '${range.isNotEmpty ? '  ·  $range' : ''}',
                            style: subtitleStyle,
                          ),
                        );
                        out.add(pw.SizedBox(height: 3));
                        out.add(
                          pw.Text(
                            item.institution.ifEmpty('Institution'),
                            style: bodyStyle,
                          ),
                        );
                        out.add(pw.SizedBox(height: 6));
                      }
                    }
                    out.add(
                      pw.SizedBox(
                        height: ResumeTypography.atsSerifRulesSectionGapPt,
                      ),
                    );
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    if (!resume.includeSkillsInResume) return null;
                    out.addAll(sectionHead('Skills'));
                    final skills = _skillsForDisplay(resume);
                    if (resume.showCategorisedSkills) {
                      out.addAll(
                        _categorisedSkillsPdfWidgets(
                          resume,
                          bodyStyle: skillsBodyStyle,
                          categoryStyle: _skillCategorySubtitlePdfStyle(
                            garamond,
                            weight:
                                ResumeTypography.atsStructuredSubtitleWeight,
                            fontSize:
                                ResumeTypography.atsStructuredSubtitlePt,
                          ),
                        ),
                      );
                    } else if (skills.isEmpty) {
                      out.add(
                        pw.Text('Add targeted skills.', style: bodyStyle),
                      );
                    } else if (highlightedSkills.isNotEmpty) {
                      out.add(
                        _twoColumnBulletListWithHighlights(
                          skills,
                          highlightedSkills,
                          highlightColor,
                          bulletStyle: skillsBodyStyle,
                        ),
                      );
                    } else {
                      out.addAll(
                        _twoColumnBulletRows(
                          skills,
                          columnGap: 20,
                          itemBottom: 3,
                          fontSize: _atsPdfSkillsBodyPt(bodyPt),
                          bulletStyle: skillsBodyStyle,
                        ),
                      );
                    }
                    out.add(
                      pw.SizedBox(
                        height: ResumeTypography.atsSerifRulesSectionGapPt,
                      ),
                    );
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume) return null;
                    out.addAll(sectionHead('Projects'));
                    for (final p in resume.visibleProjects) {
                      out.addAll(
                        _buildCompactProjectWidgets(
                          p,
                          bodyFontPt: bodyPt,
                          garamond: garamond,
                          atsGaramondBody: true,
                        ),
                      );
                    }
                    out.add(
                      pw.SizedBox(
                        height: ResumeTypography.atsSerifRulesSectionGapPt,
                      ),
                    );
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

          return w;
        },
      ),
    );
  }

  void _addAtsModernFlowTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final accent = _atsAccentPdf(resume);
    final bodyStyle = atsModernFlowBodyPdfTextStyle(garamond, bodyPt);
    final contactStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredContactWeight,
      fontSize: bodyPt,
      color: PdfColors.black,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
    );
    final sectionTitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredSectionTitlePt,
      color: accent,
    );
    final subtitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: ResumeTypography.atsStructuredSubtitlePt,
      color: PdfColors.black,
    );
    final nameStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredNameWeight,
      fontSize: ResumeTypography.atsStructuredNamePt,
      color: PdfColors.black,
    );
    final jobStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredJobTitlePt,
      color: PdfColors.black,
    );
    final skillsBodyStyle = atsModernFlowBodyPdfTextStyle(
      garamond,
      _atsPdfSkillsBodyPt(bodyPt),
    );
    final name = _displayName(resume);
    final job = resume.jobTitle.trim();
    final contact = _atsHeaderContactLines(resume);
    final skills = _skillsForDisplay(resume);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 40, 42, 40),
        header: _atsMultiPageHeaderGap,
        build: (context) {
          final w = <pw.Widget>[
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    name,
                    textAlign: pw.TextAlign.center,
                    style: nameStyle,
                  ),
                  if (job.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      job,
                      textAlign: pw.TextAlign.center,
                      style: jobStyle,
                    ),
                  ],
                  if (contact.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    for (var i = 0; i < contact.length; i++)
                      pw.Padding(
                        padding: pw.EdgeInsets.only(top: i == 0 ? 0 : 2),
                        child: _pdfContactText(
                          contact[i],
                          textAlign: pw.TextAlign.center,
                          style: contactStyle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            _atsSolidRule(),
            pw.SizedBox(height: 12),
            pw.Text('Professional Summary', style: sectionTitleStyle),
            pw.SizedBox(height: 6),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Describe strengths and focus areas clearly.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
              textStyle: bodyStyle,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
            _atsSolidRule(color: PdfColor.fromHex('#CCCCCC')),
            pw.SizedBox(height: 12),
          ];

          w.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              buildSection: (id) {
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.add(_atsSolidRule(color: PdfColor.fromHex('#CCCCCC')));
                  out.add(pw.SizedBox(height: 10));
                  out.add(
                    pw.Text(
                      section.title.ifEmpty('Additional'),
                      style: sectionTitleStyle,
                    ),
                  );
                  out.add(pw.SizedBox(height: 6));
                  out.addAll(
                    _pwCustomSectionBodyWidgets(
                      section,
                      garamond: garamond,
                      bodyFontPt: bodyPt,
                      atsModernFlowGaramondBody: true,
                    ),
                  );
                  out.add(
                    pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    out.add(pw.Text('Experience', style: sectionTitleStyle));
                    out.add(pw.SizedBox(height: 6));
                    final items = resume.visibleWorkExperiences;
                    if (items.isEmpty) {
                      out.add(
                        pw.Text('Add roles with outcomes.', style: bodyStyle),
                      );
                    } else {
                      for (var i = 0; i < items.length; i++) {
                        final item = items[i];
                        out.add(
                          pw.Text(
                            '${item.role.ifEmpty('Role')} — ${item.company.ifEmpty('Company')}',
                            style: subtitleStyle,
                          ),
                        );
                        final dr = _atsWorkDateRange(item);
                        if (dr.isNotEmpty) {
                          out.add(pw.Text(dr, style: bodyStyle));
                        }
                        final highlightedBullets =
                            highlightedBulletsByExperience[i] ??
                                const <String>{};
                        for (final b in _workBulletLines(item)) {
                          out.add(
                            _atsHighlightedBulletLine(
                              b,
                              style: bodyStyle,
                              isHighlighted: highlightedBullets.contains(b),
                              highlightColor: highlightColor,
                            ),
                          );
                        }
                        if (i < items.length - 1) {
                          out.add(pw.SizedBox(height: 10));
                        }
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    out.add(
                      _atsSolidRule(color: PdfColor.fromHex('#CCCCCC')),
                    );
                    out.add(pw.SizedBox(height: 12));
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    out.add(pw.Text('Education', style: sectionTitleStyle));
                    out.add(pw.SizedBox(height: 6));
                    final edu = resume.visibleEducation;
                    if (edu.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add schools and programs.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      for (final item in edu) {
                        out.add(
                          pw.Text(
                            item.degree.ifEmpty('Program'),
                            style: subtitleStyle,
                          ),
                        );
                        final range = educationDateRangeLabel(
                          item.startDate,
                          item.endDate,
                        );
                        final line =
                            '${item.institution.ifEmpty('School')}'
                            '${range.isNotEmpty ? '  |  Graduated: $range' : ''}';
                        out.add(pw.SizedBox(height: 2));
                        out.add(pw.Text(line, style: bodyStyle));
                        final scoreLabel = educationScoreDisplayLabel(item);
                        if (scoreLabel.isNotEmpty) {
                          out.add(pw.Text(scoreLabel, style: bodyStyle));
                        }
                        out.add(pw.SizedBox(height: 8));
                      }
                    }
                    out.add(pw.SizedBox(height: 8));
                    out.add(
                      _atsSolidRule(color: PdfColor.fromHex('#CCCCCC')),
                    );
                    out.add(pw.SizedBox(height: 12));
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    if (!resume.includeSkillsInResume) return null;
                    out.add(pw.Text('Skills', style: sectionTitleStyle));
                    out.add(pw.SizedBox(height: 6));
                    if (resume.showCategorisedSkills) {
                      out.addAll(
                        _categorisedSkillsPdfWidgets(
                          resume,
                          bodyStyle: skillsBodyStyle,
                          categoryStyle: _skillCategorySubtitlePdfStyle(
                            garamond,
                            weight: ResumeTypography
                                .atsStructuredSubtitleWeight,
                            fontSize:
                                ResumeTypography.atsStructuredSubtitlePt,
                          ),
                        ),
                      );
                    } else if (skills.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add skills that mirror job postings.',
                          style: bodyStyle,
                        ),
                      );
                    } else if (highlightedSkills.isNotEmpty) {
                      out.add(
                        _twoColumnBulletListWithHighlights(
                          skills,
                          highlightedSkills,
                          highlightColor,
                          bulletStyle: skillsBodyStyle,
                        ),
                      );
                    } else {
                      for (final row in _twoColumnBulletRows(
                        skills,
                        columnGap: 22,
                        itemBottom: 3,
                        fontSize: _atsPdfSkillsBodyPt(bodyPt),
                        bulletStyle: skillsBodyStyle,
                      )) {
                        out.add(row);
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    out.add(
                      _atsSolidRule(color: PdfColor.fromHex('#CCCCCC')),
                    );
                    out.add(pw.SizedBox(height: 12));
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume) return null;
                    out.add(pw.Text('Projects', style: sectionTitleStyle));
                    out.add(pw.SizedBox(height: 6));
                    for (final p in resume.visibleProjects) {
                      out.addAll(
                        _buildCompactProjectWidgets(
                          p,
                          garamond: garamond,
                          bodyFontPt: bodyPt,
                          atsGaramondBody: true,
                          atsModernFlowGaramondBody: true,
                        ),
                      );
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

          return w;
        },
      ),
    );
  }

  pw.Widget _atsLatexSectionTitle(String title, pw.TextStyle style) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(title.toUpperCase(), style: style),
        pw.SizedBox(height: 2),
        _atsSolidRule(color: PdfColor.fromHex('#666666')),
        pw.SizedBox(height: 7),
      ],
    );
  }

  List<pw.Widget> _atsLatexEducationEntries(
    ResumeData resume, {
    required pw.TextStyle bodyStyle,
    required pw.TextStyle subtitleStyle,
    required pw.TextStyle italicStyle,
  }) {
    final items = resume.visibleEducation;
    if (items.isEmpty) {
      return [pw.Text('Add your education.', style: bodyStyle)];
    }
    return [
      for (final item in items)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '•${item.degree.ifEmpty('Degree')}',
                      style: subtitleStyle,
                    ),
                  ),
                  pw.Text(
                    educationDateRangeLabel(item.startDate, item.endDate),
                    style: italicStyle,
                  ),
                ],
              ),
              pw.Text(
                item.institution.ifEmpty('Institution'),
                style: italicStyle,
              ),
              if (educationScoreDisplayLabel(item).isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    educationScoreDisplayLabel(item),
                    style: bodyStyle,
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  List<pw.Widget> _atsLatexProjectEntries(
    ResumeData resume, {
    required pw.TextStyle bodyStyle,
    required pw.TextStyle subtitleStyle,
    required pw.TextStyle italicStyle,
  }) {
    return [
      for (final project in resume.visibleProjects)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '•${project.title.ifEmpty('Project')}',
                style: subtitleStyle,
              ),
              if (project.overview.trim().isNotEmpty)
                pw.Text(project.overview.trim(), style: italicStyle),
              for (final bullet in _projectBulletLines(project))
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, top: 2),
                  child: pw.Text('– $bullet', style: bodyStyle),
                ),
            ],
          ),
        ),
    ];
  }

  List<pw.Widget> _atsLatexExperienceEntries(
    ResumeData resume, {
    required pw.TextStyle bodyStyle,
    required pw.TextStyle subtitleStyle,
    required pw.TextStyle italicStyle,
    required Map<int, Set<String>> highlightedBulletsByExperience,
    required PdfColor highlightColor,
  }) {
    final items = resume.visibleWorkExperiences;
    if (items.isEmpty) {
      return [pw.Text('Add roles with measurable outcomes.', style: bodyStyle)];
    }
    final out = <pw.Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final highlighted = highlightedBulletsByExperience[i] ?? const <String>{};
      out.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '•${item.role.ifEmpty('Role')}',
                      style: subtitleStyle,
                    ),
                  ),
                  pw.Text(_atsWorkDateRange(item), style: italicStyle),
                ],
              ),
              pw.Text(item.company.ifEmpty('Company'), style: italicStyle),
              for (final bullet in _workBulletLines(item))
                _atsHighlightedBulletLine(
                  '– $bullet',
                  style: bodyStyle,
                  isHighlighted: highlighted.contains(bullet),
                  highlightColor: highlightColor,
                ),
            ],
          ),
        ),
      );
    }
    return out;
  }

  pw.Widget _atsLatexSkillsBlock(
    List<String> skills, {
    required GaramondPdfFonts garamond,
    required pw.TextStyle bodyStyle,
    required Set<String> highlightedSkills,
    required PdfColor highlightColor,
    required double bodyPt,
    ResumeData? resume,
  }) {
    final skillsBodyStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: _atsPdfSkillsBodyPt(bodyPt),
      color: PdfColors.black,
      lineSpacing: bodyPt * 0.1,
    );
    if (resume != null && resume.showCategorisedSkills) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: _categorisedSkillsPdfWidgets(
          resume,
          bodyStyle: skillsBodyStyle,
          categoryStyle: _skillCategorySubtitlePdfStyle(
            garamond,
            weight: ResumeTypography.atsStructuredSubtitleWeight,
            fontSize: ResumeTypography.atsStructuredSubtitlePt,
          ),
        ),
      );
    }
    if (skills.isEmpty) {
      return pw.Text('Add targeted skills.', style: bodyStyle);
    }
    if (highlightedSkills.isNotEmpty) {
      return _twoColumnBulletListWithHighlights(
        skills,
        highlightedSkills,
        highlightColor,
        fontSize: _atsPdfSkillsBodyPt(bodyPt),
        bulletStyle: skillsBodyStyle,
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _twoColumnBulletRows(
        skills,
        columnGap: 16,
        itemBottom: 3,
        fontSize: _atsPdfSkillsBodyPt(bodyPt),
        bulletStyle: skillsBodyStyle,
      ),
    );
  }

  void _addAtsLatexClassicTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final accent = _atsAccentPdf(resume);
    final bodyStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: bodyPt,
      color: PdfColors.black,
      lineSpacing: bodyPt * 0.1,
    );
    final subtitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: bodyPt + 0.6,
      color: PdfColors.black,
      lineSpacing: bodyPt * 0.12,
    );
    final italicStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: bodyPt,
      color: PdfColors.black,
      fontStyle: pw.FontStyle.italic,
      lineSpacing: bodyPt * 0.08,
    );
    final sectionTitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: bodyPt + 5.5,
      color: accent,
    ).copyWith(letterSpacing: 1.1);
    final nameStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredNameWeight,
      fontSize: bodyPt + 8,
      color: PdfColors.black,
    );
    final contactStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: bodyPt,
      color: PdfColors.black,
      lineSpacing: bodyPt * 0.12,
    );
    final contactItems = [
      if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
      if (resume.email.trim().isNotEmpty) resume.email.trim(),
      if (resume.githubLink.trim().isNotEmpty) resume.githubLink.trim(),
      if (resume.linkedinLink.trim().isNotEmpty) resume.linkedinLink.trim(),
      if (resume.website.trim().isNotEmpty) resume.website.trim(),
    ];

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 36, 38, 34),
        header: _atsMultiPageHeaderGap,
        build: (context) {
          final w = <pw.Widget>[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_displayName(resume), style: nameStyle),
                      if (resume.jobTitle.trim().isNotEmpty)
                        pw.Text(resume.jobTitle.trim(), style: bodyStyle),
                      if (resume.location.trim().isNotEmpty)
                        pw.Text(resume.location.trim(), style: bodyStyle),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      for (final item in contactItems)
                        _pdfContactText(
                          item,
                          textAlign: pw.TextAlign.right,
                          style: contactStyle,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ];

          if (resume.summary.trim().isNotEmpty) {
            w.add(pw.SizedBox(height: 18));
            w.add(_atsLatexSectionTitle('Summary', sectionTitleStyle));
            w.add(
              _atsHighlightedSummaryText(
                resume.summary.trim(),
                bodyPt: bodyPt,
                highlightSummary: highlightSummary,
                highlightColor: highlightColor,
                textStyle: bodyStyle,
              ),
            );
          }

          w.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              buildSection: (id) {
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.add(pw.SizedBox(height: 12));
                  out.add(
                    _atsLatexSectionTitle(
                      section.title.ifEmpty('Additional'),
                      sectionTitleStyle,
                    ),
                  );
                  out.addAll(
                    _pwCustomSectionBodyWidgets(
                      section,
                      garamond: garamond,
                      bodyFontPt: bodyPt,
                    ),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    out.add(pw.SizedBox(height: 12));
                    out.add(
                      _atsLatexSectionTitle('Experience', sectionTitleStyle),
                    );
                    out.addAll(
                      _atsLatexExperienceEntries(
                        resume,
                        bodyStyle: bodyStyle,
                        subtitleStyle: subtitleStyle,
                        italicStyle: italicStyle,
                        highlightedBulletsByExperience:
                            highlightedBulletsByExperience,
                        highlightColor: highlightColor,
                      ),
                    );
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    out.add(pw.SizedBox(height: 14));
                    out.add(
                      _atsLatexSectionTitle('Education', sectionTitleStyle),
                    );
                    out.addAll(
                      _atsLatexEducationEntries(
                        resume,
                        bodyStyle: bodyStyle,
                        subtitleStyle: subtitleStyle,
                        italicStyle: italicStyle,
                      ),
                    );
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    if (!resume.includeSkillsInResume) return null;
                    out.add(pw.SizedBox(height: 12));
                    out.add(_atsLatexSectionTitle('Skills', sectionTitleStyle));
                    out.add(
                      _atsLatexSkillsBlock(
                        _skillsForDisplay(resume),
                        garamond: garamond,
                        bodyStyle: bodyStyle,
                        highlightedSkills: highlightedSkills,
                        highlightColor: highlightColor,
                        bodyPt: bodyPt,
                        resume: resume,
                      ),
                    );
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume ||
                        resume.visibleProjects.isEmpty) {
                      return null;
                    }
                    out.add(pw.SizedBox(height: 12));
                    out.add(
                      _atsLatexSectionTitle('Projects', sectionTitleStyle),
                    );
                    out.addAll(
                      _atsLatexProjectEntries(
                        resume,
                        bodyStyle: bodyStyle,
                        subtitleStyle: subtitleStyle,
                        italicStyle: italicStyle,
                      ),
                    );
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

          return w;
        },
      ),
    );
  }

  void _addAtsExecutiveTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final accent = _atsAccentPdf(resume);
    final bodyStyle = atsExecutiveBodyPdfTextStyle(garamond, bodyPt);
    final contactStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredContactWeight,
      fontSize: bodyPt,
      color: PdfColors.black,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
    );
    final sectionTitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredSectionTitlePt,
      color: accent,
    );
    final subtitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: ResumeTypography.atsStructuredSubtitlePt,
      color: PdfColors.black,
    );
    final nameStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredNameWeight,
      fontSize: ResumeTypography.atsStructuredNamePt,
      color: PdfColors.black,
    );
    final jobStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredJobTitlePt,
      color: PdfColors.black,
    );
    final skillsBodyStyle = atsExecutiveBodyPdfTextStyle(
      garamond,
      _atsPdfSkillsBodyPt(bodyPt),
    );
    final job = resume.jobTitle.trim();
    final name = _displayName(resume);
    final loc = resume.location.trim();
    final email = resume.email.trim();
    final phone = resume.phone.trim();
    final skills = _skillsForDisplay(resume);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(30, 40, 30, 40),
        header: _atsMultiPageHeaderGap,
        build: (context) {
          final w = <pw.Widget>[
            pw.Center(
              child: pw.Column(
                children: [
                  if (job.isNotEmpty)
                    pw.Text(
                      job.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: jobStyle,
                    ),
                  if (job.isNotEmpty) pw.SizedBox(height: 4),
                  pw.Text(
                    name,
                    textAlign: pw.TextAlign.center,
                    style: nameStyle,
                  ),
                  if (loc.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      loc,
                      textAlign: pw.TextAlign.center,
                      style: contactStyle,
                    ),
                  ],
                  if (email.isNotEmpty || phone.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      [email, phone].where((e) => e.isNotEmpty).join('   '),
                      textAlign: pw.TextAlign.center,
                      style: contactStyle,
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            _atsSolidRule(),
            pw.SizedBox(height: 12),
            pw.Text('SUMMARY', style: sectionTitleStyle),
            pw.SizedBox(height: 6),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Lead with scope, domains, and measurable outcomes.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
              textStyle: bodyStyle,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
          ];

          w.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              buildSection: (id) {
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.add(
                    pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                  );
                  out.add(
                    pw.Text(
                      section.title.ifEmpty('Additional').toUpperCase(),
                      style: sectionTitleStyle,
                    ),
                  );
                  out.add(pw.SizedBox(height: 6));
                  out.addAll(
                    _pwCustomSectionBodyWidgets(
                      section,
                      garamond: garamond,
                      bodyFontPt: bodyPt,
                      atsExecutiveGaramondBody: true,
                    ),
                  );
                  out.add(
                    pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    out.add(pw.Text('EXPERIENCE', style: sectionTitleStyle));
                    out.add(pw.SizedBox(height: 6));
                    final items = resume.visibleWorkExperiences;
                    if (items.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add leadership and core responsibilities.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      out.addAll(
                        _atsExperienceEntries(
                          items,
                          bodyPt,
                          usePipeRoleCompany: true,
                          highlightedBulletsByExperience:
                              highlightedBulletsByExperience,
                          highlightColor: highlightColor,
                          garamond: garamond,
                          atsExecutiveGaramondBody: true,
                        ),
                      );
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    out.add(pw.Text('EDUCATION', style: sectionTitleStyle));
                    out.add(pw.SizedBox(height: 6));
                    final edu = resume.visibleEducation;
                    if (edu.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add degree and institution.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      for (final item in edu) {
                        final range = educationDateRangeLabel(
                          item.startDate,
                          item.endDate,
                        );
                        out.add(
                          pw.Text(
                            '${item.institution.ifEmpty('University')} | ${item.degree.ifEmpty('Degree')}',
                            style: subtitleStyle,
                          ),
                        );
                        if (range.isNotEmpty) {
                          out.add(pw.SizedBox(height: 3));
                          out.add(pw.Text(range, style: bodyStyle));
                        }
                        out.add(pw.SizedBox(height: 8));
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    out.add(pw.Text('SKILLS', style: sectionTitleStyle));
                    out.add(pw.SizedBox(height: 6));
                    if (resume.includeSkillsInResume &&
                        resume.showCategorisedSkills) {
                      out.addAll(
                        _categorisedSkillsPdfWidgets(
                          resume,
                          bodyStyle: skillsBodyStyle,
                          categoryStyle: _skillCategorySubtitlePdfStyle(
                            garamond,
                            weight: ResumeTypography
                                .atsStructuredSubtitleWeight,
                            fontSize:
                                ResumeTypography.atsStructuredSubtitlePt,
                          ),
                        ),
                      );
                    } else if (resume.includeSkillsInResume &&
                        skills.isNotEmpty) {
                      if (highlightedSkills.isNotEmpty) {
                        out.add(
                          _twoColumnBulletListWithHighlights(
                            skills,
                            highlightedSkills,
                            highlightColor,
                            bulletStyle: skillsBodyStyle,
                          ),
                        );
                      } else {
                        for (final row in _twoColumnBulletRows(
                          skills,
                          columnGap: 18,
                          itemBottom: 3,
                          fontSize: _atsPdfSkillsBodyPt(bodyPt),
                          bulletStyle: skillsBodyStyle,
                        )) {
                          out.add(row);
                        }
                      }
                    } else {
                      out.add(
                        pw.Text(
                          'Add keywords from target job descriptions.',
                          style: bodyStyle,
                        ),
                      );
                    }
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume ||
                        resume.visibleProjects.isEmpty) {
                      return null;
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    out.add(pw.Text('PROJECTS', style: sectionTitleStyle));
                    out.add(pw.SizedBox(height: 6));
                    for (final p in resume.visibleProjects) {
                      out.addAll(
                        _buildCompactProjectWidgets(
                          p,
                          garamond: garamond,
                          bodyFontPt: bodyPt,
                          atsGaramondBody: true,
                          atsExecutiveGaramondBody: true,
                        ),
                      );
                    }
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

          return w;
        },
      ),
    );
  }

  List<String> _atsCenterClassicTaglineParts(ResumeData resume) {
    final job = resume.jobTitle.trim();
    final skillTags = _skillsForDisplay(resume).take(4).toList();
    return [if (job.isNotEmpty) job, ...skillTags];
  }

  String _atsCenterClassicContactPipe(ResumeData resume) {
    final parts = <String>[
      if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
      if (resume.email.trim().isNotEmpty) resume.email.trim(),
      if (resume.linkedinLink.trim().isNotEmpty) resume.linkedinLink.trim(),
      if (resume.website.trim().isNotEmpty) resume.website.trim(),
      if (resume.location.trim().isNotEmpty) resume.location.trim(),
    ];
    return parts.join(' | ');
  }

  pw.Widget _atsCenterClassicSectionTitle(
    String title,
    pw.TextStyle sectionTitleStyle,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _atsSolidRule(color: PdfColor.fromHex('#CCCCCC')),
        pw.SizedBox(height: 10),
        pw.Text(title.toUpperCase(), style: sectionTitleStyle),
        pw.SizedBox(height: 6),
      ],
    );
  }

  List<pw.Widget> _atsCenterClassicExperienceEntries(
    List<WorkExperience> items, {
    required pw.TextStyle bodyStyle,
    required pw.TextStyle companyStyle,
    required pw.TextStyle mutedDateStyle,
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
    PdfColor? highlightColor,
  }) {
    final out = <pw.Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final dateStr = _atsWorkDateRange(item);
      out.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                item.company.ifEmpty('Company'),
                style: companyStyle,
              ),
            ),
            if (dateStr.isNotEmpty) pw.Text(dateStr, style: mutedDateStyle),
          ],
        ),
      );
      out.add(pw.SizedBox(height: 2));
      out.add(pw.Text(item.role.ifEmpty('Role'), style: bodyStyle));
      out.add(pw.SizedBox(height: 4));
      final highlightedBullets =
          highlightedBulletsByExperience[i] ?? const <String>{};
      for (final b in _workBulletLines(item)) {
        out.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(
              left: ResumeTypography.atsCenterClassicBulletIndentPt,
              top: 2,
            ),
            child: _atsHighlightedBulletLine(
              '• $b',
              style: bodyStyle,
              isHighlighted:
                  highlightColor != null && highlightedBullets.contains(b),
              highlightColor: highlightColor ?? _atsHighlightColor,
            ),
          ),
        );
      }
      if (i < items.length - 1) {
        out.add(pw.SizedBox(height: 10));
      }
    }
    return out;
  }

  void _addAtsCenterClassicTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _pdfRgb(resume.atsCenterClassicAccentColor);
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final bodyStyle = atsCenterClassicBodyPdfTextStyle(garamond, bodyPt);
    final contactStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredContactWeight,
      fontSize: bodyPt,
      color: PdfColors.black,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
    );
    final taglineStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: ResumeTypography.atsStructuredSubtitlePt,
      color: PdfColors.black,
    );
    final sectionTitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredSectionTitlePt,
      color: PdfColors.black,
    );
    final sectionSubtitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: ResumeTypography.atsStructuredSubtitlePt,
      color: accent,
    );
    final highlightStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: ResumeTypography.atsStructuredSubtitlePt,
      color: accent,
      fontStyle: pw.FontStyle.italic,
    );
    final nameStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredNameWeight,
      fontSize: ResumeTypography.atsStructuredNamePt,
      color: PdfColors.black,
    );
    final name = _displayName(resume);
    final tagline = _atsCenterClassicTaglineParts(resume).join(' | ');
    final contactPipe = _atsCenterClassicContactPipe(resume);
    final skills = _skillsForDisplay(resume);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(30, 56, 30, 56),
        header: _atsMultiPageHeaderGap,
        build: (context) {
          final w = <pw.Widget>[
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    name,
                    textAlign: pw.TextAlign.center,
                    style: nameStyle,
                  ),
                  if (tagline.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      tagline,
                      textAlign: pw.TextAlign.center,
                      style: taglineStyle,
                    ),
                  ],
                  if (contactPipe.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    _pdfContactText(
                      contactPipe,
                      textAlign: pw.TextAlign.center,
                      style: contactStyle,
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            _atsCenterClassicSectionTitle('Summary', sectionTitleStyle),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Concise overview of experience, domains, and impact.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
              textStyle: bodyStyle,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
          ];

          w.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              buildSection: (id) {
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.add(
                    _atsCenterClassicSectionTitle(
                      section.title.ifEmpty('Additional'),
                      sectionTitleStyle,
                    ),
                  );
                  out.addAll(
                    _pwCustomSectionBodyWidgets(
                      section,
                      garamond: garamond,
                      bodyFontPt: bodyPt,
                      atsCenterClassicGaramondBody: true,
                    ),
                  );
                  out.add(
                    pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    out.add(
                      _atsCenterClassicSectionTitle(
                        'Experience',
                        sectionTitleStyle,
                      ),
                    );
                    final items = resume.visibleWorkExperiences;
                    if (items.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add roles with measurable outcomes.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      out.addAll(
                        _atsCenterClassicExperienceEntries(
                          items,
                          bodyStyle: bodyStyle,
                          companyStyle: highlightStyle,
                          mutedDateStyle: sectionSubtitleStyle,
                          highlightedBulletsByExperience:
                              highlightedBulletsByExperience,
                          highlightColor: highlightColor,
                        ),
                      );
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    out.add(
                      _atsCenterClassicSectionTitle(
                        'Education',
                        sectionTitleStyle,
                      ),
                    );
                    final edu = resume.visibleEducation;
                    if (edu.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add degree and institution.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      for (final item in edu) {
                        final range = educationDateRangeLabel(
                          item.startDate,
                          item.endDate,
                        );
                        out.add(
                          pw.Text(
                            item.degree.ifEmpty('Degree'),
                            style: highlightStyle,
                          ),
                        );
                        out.add(pw.SizedBox(height: 2));
                        out.add(
                          pw.Text(
                            '${item.institution.ifEmpty('School')}'
                            '${range.isNotEmpty ? ' ($range)' : ''}',
                            style: highlightStyle,
                          ),
                        );
                        out.add(pw.SizedBox(height: 8));
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    if (!resume.includeSkillsInResume) return null;
                    out.add(
                      _atsCenterClassicSectionTitle(
                        'Skills',
                        sectionTitleStyle,
                      ),
                    );
                    if (resume.showCategorisedSkills) {
                      out.addAll(
                        _categorisedSkillsPdfWidgets(
                          resume,
                          bodyStyle: bodyStyle,
                          categoryStyle: sectionSubtitleStyle,
                        ),
                      );
                    } else if (skills.isEmpty) {
                      out.add(
                        pw.Text(
                          'List tools and competencies.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      out.add(pw.Text(skills.join(', '), style: bodyStyle));
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume ||
                        resume.visibleProjects.isEmpty) {
                      return null;
                    }
                    out.add(
                      _atsCenterClassicSectionTitle(
                        'Projects',
                        sectionTitleStyle,
                      ),
                    );
                    for (final p in resume.visibleProjects) {
                      out.add(
                        pw.Text(
                          p.title.ifEmpty('Course'),
                          style: highlightStyle,
                        ),
                      );
                      final companyLine = p.subtitle.trim().isNotEmpty
                          ? p.subtitle.trim()
                          : p.overview.trim();
                      if (companyLine.isNotEmpty) {
                        out.add(pw.SizedBox(height: 2));
                        out.add(pw.Text(companyLine, style: highlightStyle));
                      }
                      for (final b
                          in p.bullets.where((e) => e.trim().isNotEmpty)) {
                        out.add(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(
                              left: ResumeTypography
                                  .atsCenterClassicBulletIndentPt,
                              top: 2,
                            ),
                            child: pw.Text('• $b', style: bodyStyle),
                          ),
                        );
                      }
                      out.add(pw.SizedBox(height: 8));
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

          return w;
        },
      ),
    );
  }

  pw.Widget _atsProfessionalBlueSectionTitle(
    String title,
    pw.TextStyle sectionTitleStyle, {
    required PdfColor ruleColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(title, style: sectionTitleStyle),
        pw.SizedBox(height: 4),
        _atsSolidRule(color: ruleColor),
        pw.SizedBox(height: 6),
      ],
    );
  }

  void _addAtsProfessionalBlueTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _pdfRgb(resume.atsProfessionalBlueAccentColor);
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final bodyStyle = atsProfessionalBlueBodyPdfTextStyle(garamond, bodyPt);
    final contactStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredContactWeight,
      fontSize: bodyPt,
      color: accent,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
    );
    final sectionTitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredSectionTitlePt,
      color: accent,
    );
    final subtitleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: ResumeTypography.atsStructuredSubtitlePt,
      color: accent,
    );
    final nameStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredNameWeight,
      fontSize: ResumeTypography.atsStructuredNamePt,
      color: accent,
    );
    final jobStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: ResumeTypography.atsStructuredJobTitlePt,
      color: accent,
    );
    final skillsBodyStyle = atsProfessionalBlueBodyPdfTextStyle(
      garamond,
      _atsPdfSkillsBodyPt(bodyPt),
    );
    final name = _displayName(resume);
    final job = resume.jobTitle.trim();
    final email = resume.email.trim();
    final phone = resume.phone.trim();
    final loc = resume.location.trim();
    final github = resume.githubLink.trim();
    final linkedin = resume.linkedinLink.trim();
    final skills = _skillsForDisplay(resume);
    final contactLines = <String>[
      if (email.isNotEmpty) email,
      if (phone.isNotEmpty) phone,
      if (loc.isNotEmpty) loc,
      if (github.isNotEmpty) github,
      if (linkedin.isNotEmpty) linkedin,
    ];

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.fromLTRB(
          ResumeTypography.atsStructuredPageInsetPt,
          ResumeTypography.atsStructuredPageInsetPt +
              ResumeTypography.atsProfessionalBlueExtraTopPaddingPt,
          ResumeTypography.atsStructuredPageInsetPt,
          ResumeTypography.atsStructuredPageInsetPt,
        ),
        header: _atsMultiPageHeaderGap,
        build: (context) {
          final w = <pw.Widget>[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(name, style: nameStyle),
                      if (job.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(job, style: jobStyle),
                      ],
                    ],
                  ),
                ),
                if (contactLines.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      for (final line in contactLines)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: _pdfContactText(
                            line,
                            textAlign: pw.TextAlign.right,
                            style: contactStyle,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Brief overview of leadership, scope, and results.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
              textStyle: bodyStyle,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
          ];

          w.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              buildSection: (id) {
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.add(
                    pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                  );
                  out.add(
                    _atsProfessionalBlueSectionTitle(
                      section.title.ifEmpty('Additional'),
                      sectionTitleStyle,
                      ruleColor: accent,
                    ),
                  );
                  out.addAll(
                    _pwCustomSectionBodyWidgets(
                      section,
                      garamond: garamond,
                      bodyFontPt: bodyPt,
                      atsProfessionalBlueGaramondBody: true,
                    ),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    out.add(
                      _atsProfessionalBlueSectionTitle(
                        'Professional Experience',
                        sectionTitleStyle,
                        ruleColor: accent,
                      ),
                    );
                    final items = resume.visibleWorkExperiences;
                    if (items.isEmpty) {
                      out.add(
                        pw.Text('Add roles with outcomes.', style: bodyStyle),
                      );
                    } else {
                      for (var i = 0; i < items.length; i++) {
                        final item = items[i];
                        final dateStr = _atsWorkDateRange(item);
                        out.add(
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  item.company.ifEmpty('Company'),
                                  style: subtitleStyle,
                                ),
                              ),
                              if (dateStr.isNotEmpty)
                                pw.Text(dateStr, style: subtitleStyle),
                            ],
                          ),
                        );
                        out.add(pw.SizedBox(height: 2));
                        out.add(
                          pw.Text(item.role.ifEmpty('Role'), style: bodyStyle),
                        );
                        out.add(pw.SizedBox(height: 4));
                        final highlightedBullets =
                            highlightedBulletsByExperience[i] ??
                                const <String>{};
                        for (final b in _workBulletLines(item)) {
                          out.add(
                            _atsHighlightedBulletLine(
                              '• $b',
                              style: bodyStyle,
                              isHighlighted: highlightedBullets.contains(b),
                              highlightColor: highlightColor,
                            ),
                          );
                        }
                        if (i < items.length - 1) {
                          out.add(pw.SizedBox(height: 10));
                        }
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    out.add(
                      _atsProfessionalBlueSectionTitle(
                        'Education',
                        sectionTitleStyle,
                        ruleColor: accent,
                      ),
                    );
                    final edu = resume.visibleEducation;
                    if (edu.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add schools and programs.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      for (final item in edu) {
                        out.add(
                          pw.Text(
                            item.degree.ifEmpty('Program'),
                            style: subtitleStyle,
                          ),
                        );
                        out.add(pw.SizedBox(height: 2));
                        out.add(
                          pw.Text(
                            item.institution.ifEmpty('School'),
                            style: bodyStyle,
                          ),
                        );
                        out.add(pw.SizedBox(height: 8));
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    if (!resume.includeSkillsInResume) return null;
                    out.add(
                      _atsProfessionalBlueSectionTitle(
                        'Areas of Expertise',
                        sectionTitleStyle,
                        ruleColor: accent,
                      ),
                    );
                    if (resume.showCategorisedSkills) {
                      out.addAll(
                        _categorisedSkillsPdfWidgets(
                          resume,
                          bodyStyle: skillsBodyStyle,
                          categoryStyle: subtitleStyle,
                        ),
                      );
                    } else if (skills.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add skills aligned to your target roles.',
                          style: bodyStyle,
                        ),
                      );
                    } else {
                      final cleaned =
                          skills.where((s) => s.trim().isNotEmpty).toList();
                      final columns = <List<String>>[[], [], []];
                      for (var i = 0; i < cleaned.length; i++) {
                        columns[i % 3].add(cleaned[i]);
                      }
                      final rowCount = columns
                          .map((c) => c.length)
                          .fold<int>(0, (a, b) => a > b ? a : b);
                      for (var r = 0; r < rowCount; r++) {
                        out.add(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 3),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                for (var c = 0; c < 3; c++)
                                  pw.Expanded(
                                    child: r < columns[c].length
                                        ? pw.Row(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                              pw.Container(
                                                width: 5,
                                                height: 5,
                                                margin:
                                                    const pw.EdgeInsets.only(
                                                  top: 3,
                                                  right: 5,
                                                ),
                                                decoration: pw.BoxDecoration(
                                                  color: accent,
                                                  shape: pw.BoxShape.circle,
                                                ),
                                              ),
                                              pw.Expanded(
                                                child: highlightedSkills
                                                        .contains(
                                                      columns[c][r],
                                                    )
                                                    ? pw.Container(
                                                        padding:
                                                            const pw.EdgeInsets
                                                                .symmetric(
                                                          horizontal: 4,
                                                          vertical: 2,
                                                        ),
                                                        color: highlightColor,
                                                        child: pw.Text(
                                                          columns[c][r],
                                                          style:
                                                              skillsBodyStyle,
                                                        ),
                                                      )
                                                    : pw.Text(
                                                        columns[c][r],
                                                        style:
                                                            skillsBodyStyle,
                                                      ),
                                              ),
                                            ],
                                          )
                                        : pw.SizedBox(),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                    out.add(
                      pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
                    );
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume ||
                        resume.visibleProjects.isEmpty) {
                      return null;
                    }
                    out.add(
                      _atsProfessionalBlueSectionTitle(
                        'Projects',
                        sectionTitleStyle,
                        ruleColor: accent,
                      ),
                    );
                    for (final p in resume.visibleProjects) {
                      out.add(
                        pw.Text(
                          p.title.ifEmpty('Project'),
                          style: subtitleStyle,
                        ),
                      );
                      final overview = p.overview.trim();
                      if (overview.isNotEmpty) {
                        out.add(pw.SizedBox(height: 2));
                        out.add(pw.Text(overview, style: bodyStyle));
                      }
                      for (final b
                          in p.bullets.where((e) => e.trim().isNotEmpty)) {
                        out.add(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text('• $b', style: bodyStyle),
                          ),
                        );
                      }
                      out.add(pw.SizedBox(height: 8));
                    }
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

                    return w;
        },
      ),
    );
  }

  pw.Widget _accentStripSectionTitle(
    String title, {
    required GaramondPdfFonts garamond,
    required PdfColor accent,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: garamondPdfTextStyle(
          garamond,
          ResumeTypography.accentStripTitleWeight,
          fontSize: ResumeTypography.accentStripSectionTitlePt,
          color: accent,
        ).copyWith(letterSpacing: 0.2),
      ),
    );
  }

  pw.TextStyle _accentStripBodyPdfStyle(
    GaramondPdfFonts garamond,
    double bodyPt,
  ) => accentStripBodyPdfTextStyle(garamond, bodyPt);

  pw.TextStyle _accentStripSubsectionPdfStyle(GaramondPdfFonts garamond) =>
      garamondPdfTextStyle(
        garamond,
        ResumeTypography.accentStripSubtitleWeight,
        fontSize: ResumeTypography.accentStripSubsectionPt,
      );

  void _addAccentStripTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required CalibriPdfFonts calibri,
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _pdfRgb(resume.corporateColorPreset.headerColor);
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final name = _displayName(resume).toUpperCase();
    final contactLine = _resumeContactItems(resume).join(' | ');
    final summary = resume.summary.trim();
    final skills = _skillsForDisplay(resume);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(96, 36, 34, 34),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(width: 24),
                pw.Container(width: 40, color: accent),
                pw.Expanded(child: pw.SizedBox()),
              ],
            ),
          ),
        ),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              name,
              style: garamondPdfTextStyle(
                garamond,
                ResumeTypography.accentStripNameWeight,
                fontSize: ResumeTypography.accentStripNamePt,
                color: accent,
              ).copyWith(letterSpacing: 0.4),
            ),
            if (contactLine.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _pdfContactText(
                contactLine,
                style: garamondPdfTextStyle(
                  garamond,
                  ResumeTypography.accentStripContactWeight,
                  fontSize: bodyPt,
                ),
              ),
            ],
            if (summary.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              _atsHighlightedSummaryText(
                summary,
                bodyPt: bodyPt,
                highlightSummary: highlightSummary,
                highlightColor: highlightColor,
                textStyle: _accentStripBodyPdfStyle(garamond, bodyPt),
              ),
            ],
          ];

          widgets.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              buildSection: (id) {
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.add(pw.SizedBox(height: 18));
                  out.add(
                    _accentStripSectionTitle(
                      section.title.trim().ifEmpty('ADDITIONAL').toUpperCase(),
                      garamond: garamond,
                      accent: accent,
                    ),
                  );
                  out.addAll(
                    _pwCustomSectionBodyWidgets(
                      section,
                      garamond: garamond,
                      bodyFontPt: bodyPt,
                      accentStripGaramondBody: true,
                    ),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    out.add(pw.SizedBox(height: 28));
                    out.add(
                      _accentStripSectionTitle(
                        'EXPERIENCE',
                        garamond: garamond,
                        accent: accent,
                      ),
                    );
                    final items = resume.visibleWorkExperiences;
                    if (items.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add experience entries with dates, roles, and outcomes.',
                          style: _accentStripBodyPdfStyle(garamond, bodyPt),
                        ),
                      );
                    } else {
                      for (var index = 0; index < items.length; index++) {
                        final item = items[index];
                        final dateLabel = _atsWorkDateRange(item);
                        final roleLine = [
                          item.role.trim(),
                          item.company.trim(),
                        ].where((value) => value.isNotEmpty).join(' | ');
                        final bullets = _workBulletLines(item);
                        final highlightedBullets =
                            highlightedBulletsByExperience[index] ??
                                const <String>{};

                        if (dateLabel.isNotEmpty) {
                          out.add(
                            pw.Text(
                              dateLabel,
                              style: _accentStripSubsectionPdfStyle(garamond),
                            ),
                          );
                        }
                        if (roleLine.isNotEmpty) {
                          out.add(pw.SizedBox(height: 4));
                          out.add(
                            pw.Text(
                              roleLine,
                              style: _accentStripSubsectionPdfStyle(garamond),
                            ),
                          );
                        }

                        if (bullets.isNotEmpty) {
                          out.add(pw.SizedBox(height: 6));
                          for (final bullet in bullets) {
                            out.add(
                              _atsHighlightedBulletLine(
                                bullet,
                                style: _accentStripBodyPdfStyle(garamond, bodyPt),
                                isHighlighted:
                                    highlightedBullets.contains(bullet),
                                highlightColor: highlightColor,
                              ),
                            );
                          }
                        } else if (item.description.trim().isNotEmpty) {
                          out.add(pw.SizedBox(height: 6));
                          out.add(
                            pw.Text(
                              item.description.trim(),
                              style: _accentStripBodyPdfStyle(garamond, bodyPt),
                            ),
                          );
                        }

                        if (index < items.length - 1) {
                          out.add(pw.SizedBox(height: 18));
                        }
                      }
                    }
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    out.add(pw.SizedBox(height: 22));
                    out.add(
                      _accentStripSectionTitle(
                        'EDUCATION',
                        garamond: garamond,
                        accent: accent,
                      ),
                    );
                    final eduItems = resume.visibleEducation;
                    if (eduItems.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add education details.',
                          style: _accentStripBodyPdfStyle(garamond, bodyPt),
                        ),
                      );
                    } else {
                      for (final item in eduItems) {
                        final dates = [
                          item.startDate.trim(),
                          item.endDate.trim(),
                        ].where((value) => value.isNotEmpty).join(' – ');
                        out.add(
                          pw.Text(
                            item.degree.trim().ifEmpty('Degree'),
                            style: _accentStripSubsectionPdfStyle(garamond),
                          ),
                        );
                        out.add(pw.SizedBox(height: 3));
                        out.add(
                          pw.Text(
                            [
                              item.institution.trim().ifEmpty('Institution'),
                              if (dates.isNotEmpty) dates,
                            ].join(' | '),
                            style: _accentStripBodyPdfStyle(garamond, bodyPt),
                          ),
                        );
                        out.add(pw.SizedBox(height: 10));
                      }
                    }
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    if (!resume.includeSkillsInResume) return null;
                    out.add(pw.SizedBox(height: 18));
                    out.add(
                      _accentStripSectionTitle(
                        'SKILLS',
                        garamond: garamond,
                        accent: accent,
                      ),
                    );
                    if (resume.showCategorisedSkills) {
                      out.addAll(
                        _categorisedSkillsPdfWidgets(
                          resume,
                          bodyStyle: _accentStripBodyPdfStyle(garamond, bodyPt),
                          categoryStyle:
                              _accentStripSubsectionPdfStyle(garamond),
                        ),
                      );
                    } else if (skills.isEmpty) {
                      out.add(
                        pw.Text(
                          'Add skills aligned to the target role.',
                          style: _accentStripBodyPdfStyle(garamond, bodyPt),
                        ),
                      );
                    } else {
                      final rows = <pw.Widget>[];
                      for (final skill in skills) {
                        final skillStyle =
                            _accentStripBodyPdfStyle(garamond, bodyPt);
                        final text = highlightedSkills.contains(skill)
                            ? pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                color: highlightColor,
                                child: pw.Text('• $skill', style: skillStyle),
                              )
                            : pw.Text('• $skill', style: skillStyle);
                        rows.add(text);
                      }
                      out.add(
                        pw.Wrap(spacing: 18, runSpacing: 6, children: rows),
                      );
                    }
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume) return null;
                    final items = resume.visibleProjects;
                    if (items.isEmpty) return null;
                    out.add(pw.SizedBox(height: 18));
                    out.add(
                      _accentStripSectionTitle(
                        'PROJECTS',
                        garamond: garamond,
                        accent: accent,
                      ),
                    );
                    for (final item in items) {
                      out.add(
                        pw.Text(
                          item.title.trim().ifEmpty('Project'),
                          style: _accentStripSubsectionPdfStyle(garamond),
                        ),
                      );
                      final lines = _projectBulletLines(item);
                      final content = lines.isNotEmpty
                          ? lines.join(' ')
                          : [
                              item.overview.trim(),
                              item.impact.trim(),
                            ].where((value) => value.isNotEmpty).join(' | ');
                      if (content.isNotEmpty) {
                        out.add(pw.SizedBox(height: 4));
                        out.add(
                          pw.Text(
                            content,
                            style: _accentStripBodyPdfStyle(garamond, bodyPt),
                          ),
                        );
                      }
                      out.add(pw.SizedBox(height: 10));
                    }
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

          return widgets;
        },
      ),
    );
  }

  pw.Widget _classicCvRule() =>
      _atsSolidRule(color: _pdfRgb(ResumeTypography.atsClassicCvRuleColor));

  pw.Widget _classicCvLeftRail({
    required String left,
    required pw.Widget content,
    required pw.TextStyle leftStyle,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: ResumeTypography.atsClassicCvLabelColumnPt,
          child: left.trim().isEmpty
              ? pw.SizedBox()
              : pw.Text(left, style: leftStyle),
        ),
        pw.SizedBox(width: ResumeTypography.atsClassicCvLabelGapPt),
        pw.Expanded(child: content),
      ],
    );
  }

  pw.Widget _classicCvPersonalGrid(
    List<({String label, String value})> rows, {
    required pw.TextStyle labelStyle,
    required pw.TextStyle valueStyle,
  }) {
    pw.Widget pair(
      ({String label, String value}) row, {
      pw.TextAlign valueAlign = pw.TextAlign.left,
    }) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 4, child: pw.Text(row.label, style: labelStyle)),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              row.value,
              style: valueStyle,
              textAlign: valueAlign,
            ),
          ),
        ],
      );
    }

    if (rows.length == 1) {
      return pair(rows.first, valueAlign: pw.TextAlign.right);
    }
    final left = rows.take((rows.length + 1) ~/ 2).toList();
    final right = rows.skip(left.length).toList();
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            children: [
              for (var i = 0; i < left.length; i++) ...[
                if (i > 0) pw.SizedBox(height: 3),
                pair(left[i]),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            children: [
              for (var i = 0; i < right.length; i++) ...[
                if (i > 0) pw.SizedBox(height: 3),
                pair(right[i], valueAlign: pw.TextAlign.right),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _classicCvRoleLocationRow({
    required String role,
    required String company,
    required String location,
    required pw.TextStyle boldStyle,
    required pw.TextStyle bodyStyle,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: role, style: boldStyle),
                if (company.isNotEmpty)
                  pw.TextSpan(text: ' — $company', style: bodyStyle),
              ],
            ),
          ),
        ),
        if (location.isNotEmpty) pw.Text(location, style: bodyStyle),
      ],
    );
  }

  String _classicCvEnDashRange(String start, String end) =>
      educationDateRangeLabel(start, end)
          .replaceAll(' - ', ' – ')
          .replaceAll(' — ', ' – ');

  List<String> _classicCvScoreLines(EducationItem item) => item.score
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  void _addAtsClassicCvTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts garamond,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final ink = PdfColors.black;
    final bodyStyle = atsClassicCvBodyPdfTextStyle(garamond, bodyPt, color: ink);
    final boldStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredSubtitleWeight,
      fontSize: bodyPt,
      color: ink,
      lineSpacing: ResumeTypography.atsClassicCvBodyPdfLineSpacingFor(bodyPt),
    );
    final labelStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredTitleWeight,
      fontSize: bodyPt,
      color: ink,
    );
    final nameStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredNameWeight,
      fontSize: ResumeTypography.atsClassicCvNamePt,
      color: ink,
    );
    final titleStyle = garamondPdfTextStyle(
      garamond,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: ResumeTypography.atsClassicCvNamePt,
      color: ink,
    );
    final name = _displayName(resume);
    final job = resume.jobTitle.trim();
    final contactLines = resume.classicCvContactLines;
    final personalRows = resume.classicCvPersonalRows;
    final languages = resume.classicCvLanguagePairs;
    final personalSection = resume.classicCvPersonalSection;
    final languagesSection = resume.classicCvLanguagesSection;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          ResumeTypography.atsClassicCvPageInsetPt,
          ResumeTypography.atsClassicCvContinuationVerticalInsetPt,
          ResumeTypography.atsClassicCvPageInsetPt,
          ResumeTypography.atsClassicCvContinuationVerticalInsetPt,
        ),
        build: (context) {
          const firstPageExtraTop =
              ResumeTypography.atsClassicCvPageTopPdfPt -
              ResumeTypography.atsClassicCvContinuationVerticalInsetPt;
          final w = <pw.Widget>[
            if (firstPageExtraTop > 0) pw.SizedBox(height: firstPageExtraTop),
            pw.Center(
              child: pw.RichText(
                textAlign: pw.TextAlign.center,
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: name, style: nameStyle),
                    if (job.isNotEmpty)
                      pw.TextSpan(text: ', $job', style: titleStyle),
                  ],
                ),
              ),
            ),
            if (contactLines.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              for (final line in contactLines)
                pw.Text(
                  line,
                  textAlign: pw.TextAlign.center,
                  style: bodyStyle,
                ),
            ],
            pw.SizedBox(height: 10),
            _classicCvRule(),
            if (personalRows.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              _classicCvPersonalGrid(
                personalRows,
                labelStyle: bodyStyle,
                valueStyle: boldStyle,
              ),
              pw.SizedBox(height: 8),
              _classicCvRule(),
            ],
            pw.SizedBox(height: 10),
            _classicCvLeftRail(
              left: 'PROFILE',
              leftStyle: labelStyle,
              content: _atsHighlightedSummaryText(
                resume.summary.trim().ifEmpty(
                  'Concise overview of experience, domains, and impact.',
                ),
                bodyPt: bodyPt,
                highlightSummary: highlightSummary,
                highlightColor: highlightColor,
                textStyle: bodyStyle,
              ),
            ),
          ];

          w.addAll(
            _pdfBodySectionsInBuilderOrder(
              resume,
              exclude: {
                if (personalSection != null)
                  ResumeBuilderSectionIds.custom(
                    resume.customSections.indexOf(personalSection),
                  ),
                if (languagesSection != null)
                  ResumeBuilderSectionIds.custom(
                    resume.customSections.indexOf(languagesSection),
                  ),
              },
              buildSection: (id) {
                final out = <pw.Widget>[];
                final customIndex = ResumeBuilderSectionIds.customIndex(id);
                if (customIndex != null) {
                  if (customIndex < 0 ||
                      customIndex >= resume.customSections.length) {
                    return null;
                  }
                  final section = resume.customSections[customIndex];
                  if (section.isBlank) return null;
                  out.add(pw.SizedBox(height: 10));
                  out.add(_classicCvRule());
                  out.add(pw.SizedBox(height: 10));
                  out.add(
                    _classicCvLeftRail(
                      left: section.title.ifEmpty('Additional').toUpperCase(),
                      leftStyle: labelStyle,
                      content: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: _pwCustomSectionBodyWidgets(
                          section,
                          garamond: garamond,
                          bodyFontPt: bodyPt,
                        ),
                      ),
                    ),
                  );
                  return out;
                }
                switch (id) {
                  case ResumeBuilderSectionIds.work:
                    if (!resume.includeWorkInResume) return null;
                    final items = resume.visibleWorkExperiences;
                    out.add(pw.SizedBox(height: 10));
                    out.add(_classicCvRule());
                    out.add(pw.SizedBox(height: 10));
                    if (items.isEmpty) {
                      out.add(
                        _classicCvLeftRail(
                          left: 'EXPERIENCE',
                          leftStyle: labelStyle,
                          content: pw.Text(
                            'Add roles with measurable outcomes.',
                            style: bodyStyle,
                          ),
                        ),
                      );
                      return out;
                    }
                    for (var i = 0; i < items.length; i++) {
                      final item = items[i];
                      final split = splitTrailingEmDash(item.company);
                      final dateStr = _classicCvEnDashRange(
                        item.startDate,
                        item.endDate,
                      );
                      if (i > 0) out.add(pw.SizedBox(height: 8));
                      out.add(
                        _classicCvLeftRail(
                          left: i == 0 ? 'EXPERIENCE' : dateStr,
                          leftStyle: i == 0 ? labelStyle : bodyStyle,
                          content: _classicCvRoleLocationRow(
                            role: item.role.trim().ifEmpty('Role'),
                            company: split.head,
                            location: split.tail,
                            boldStyle: boldStyle,
                            bodyStyle: bodyStyle,
                          ),
                        ),
                      );
                      final bullets = _workBulletLines(item);
                      final highlighted =
                          highlightedBulletsByExperience[i] ?? const <String>{};
                      if (bullets.isEmpty &&
                          i == 0 &&
                          dateStr.isNotEmpty) {
                        out.add(pw.SizedBox(height: 2));
                        out.add(
                          _classicCvLeftRail(
                            left: dateStr,
                            leftStyle: bodyStyle,
                            content: pw.SizedBox(),
                          ),
                        );
                      }
                      for (var b = 0; b < bullets.length; b++) {
                        out.add(pw.SizedBox(height: b == 0 ? 2 : 1));
                        out.add(
                          _classicCvLeftRail(
                            left: i == 0 && b == 0 ? dateStr : '',
                            leftStyle: bodyStyle,
                            content: _atsHighlightedBulletLine(
                              '• ${bullets[b]}',
                              style: bodyStyle,
                              isHighlighted: highlighted.contains(bullets[b]),
                              highlightColor: highlightColor,
                            ),
                          ),
                        );
                      }
                    }
                    return out;
                  case ResumeBuilderSectionIds.education:
                    if (!resume.includeEducationInResume) return null;
                    final items = resume.visibleEducation;
                    out.add(pw.SizedBox(height: 10));
                    out.add(_classicCvRule());
                    out.add(pw.SizedBox(height: 10));
                    if (items.isEmpty) {
                      out.add(
                        _classicCvLeftRail(
                          left: 'EDUCATION',
                          leftStyle: labelStyle,
                          content: pw.Text('Add education.', style: bodyStyle),
                        ),
                      );
                      return out;
                    }
                    for (var i = 0; i < items.length; i++) {
                      final item = items[i];
                      final split = splitTrailingEmDash(item.institution);
                      final school = [
                        split.head,
                        if (split.tail.isNotEmpty) split.tail,
                      ].join(' — ');
                      final range = _classicCvEnDashRange(
                        item.startDate,
                        item.endDate,
                      );
                      final extras = _classicCvScoreLines(item);
                      if (i > 0) out.add(pw.SizedBox(height: 8));
                      out.add(
                        _classicCvLeftRail(
                          left: i == 0 ? 'EDUCATION' : range,
                          leftStyle: i == 0 ? labelStyle : bodyStyle,
                          content: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  item.degree.trim().ifEmpty('Degree'),
                                  style: boldStyle,
                                ),
                              ),
                              if (school.isNotEmpty)
                                pw.Text(school, style: bodyStyle),
                            ],
                          ),
                        ),
                      );
                      if (extras.isNotEmpty || (i == 0 && range.isNotEmpty)) {
                        if (extras.isEmpty) {
                          out.add(pw.SizedBox(height: 2));
                          out.add(
                            _classicCvLeftRail(
                              left: i == 0 ? range : '',
                              leftStyle: bodyStyle,
                              content: pw.SizedBox(),
                            ),
                          );
                        } else {
                          for (var e = 0; e < extras.length; e++) {
                            out.add(pw.SizedBox(height: e == 0 ? 2 : 1));
                            out.add(
                              _classicCvLeftRail(
                                left: i == 0 && e == 0 ? range : '',
                                leftStyle: bodyStyle,
                                content: pw.Text(
                                  '• ${extras[e]}',
                                  style: bodyStyle,
                                ),
                              ),
                            );
                          }
                        }
                      }
                    }
                    return out;
                  case ResumeBuilderSectionIds.skills:
                    if (!resume.includeSkillsInResume) return null;
                    out.add(pw.SizedBox(height: 10));
                    out.add(_classicCvRule());
                    out.add(pw.SizedBox(height: 10));
                    pw.Widget skillLine({
                      required String heading,
                      required String skillsText,
                      required bool highlighted,
                    }) {
                      final line = pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            if (heading.isNotEmpty)
                              pw.TextSpan(
                                text: '${heading.toUpperCase()}: ',
                                style: boldStyle,
                              ),
                            pw.TextSpan(text: skillsText, style: bodyStyle),
                          ],
                        ),
                      );
                      if (!highlighted) {
                        return line;
                      }
                      return pw.Container(
                        width: double.infinity,
                        color: highlightColor,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        child: line,
                      );
                    }

                    final skillLines = <pw.Widget>[];
                    if (resume.showCategorisedSkills) {
                      for (final group in resume.skillGroupsForResume) {
                        skillLines.add(
                          skillLine(
                            heading: group.heading.trim(),
                            skillsText: group.skillsCommaSeparated,
                            highlighted: group.skills.any(
                              highlightedSkills.contains,
                            ),
                          ),
                        );
                      }
                    } else {
                      final skills = _skillsForDisplay(resume);
                      if (skills.isEmpty) {
                        skillLines.add(
                          pw.Text(
                            'Add skills that mirror job postings.',
                            style: bodyStyle,
                          ),
                        );
                      } else {
                        skillLines.add(
                          skillLine(
                            heading: '',
                            skillsText: skills.join(', '),
                            highlighted: skills.any(
                              highlightedSkills.contains,
                            ),
                          ),
                        );
                      }
                    }
                    if (skillLines.isEmpty) {
                      out.add(
                        _classicCvLeftRail(
                          left: 'SKILLS',
                          leftStyle: labelStyle,
                          content: pw.Text(
                            'Add skills that mirror job postings.',
                            style: bodyStyle,
                          ),
                        ),
                      );
                    } else {
                      for (var i = 0; i < skillLines.length; i++) {
                        if (i > 0) out.add(pw.SizedBox(height: 2));
                        out.add(
                          _classicCvLeftRail(
                            left: i == 0 ? 'SKILLS' : '',
                            leftStyle: labelStyle,
                            content: skillLines[i],
                          ),
                        );
                      }
                    }
                    return out;
                  case ResumeBuilderSectionIds.projects:
                    if (!resume.includeProjectsInResume) return null;
                    final items = resume.visibleProjects;
                    if (items.isEmpty) return null;
                    out.add(pw.SizedBox(height: 10));
                    out.add(_classicCvRule());
                    out.add(pw.SizedBox(height: 10));
                    for (var i = 0; i < items.length; i++) {
                      final item = items[i];
                      if (i > 0) out.add(pw.SizedBox(height: 6));
                      out.add(
                        _classicCvLeftRail(
                          left: i == 0 ? 'PROJECTS' : '',
                          leftStyle: labelStyle,
                          content: pw.Text(
                            item.title.trim().ifEmpty('Project'),
                            style: boldStyle,
                          ),
                        ),
                      );
                      final bullets = _projectBulletLinesPdf(item);
                      for (var b = 0; b < bullets.length; b++) {
                        out.add(pw.SizedBox(height: 2));
                        out.add(
                          _classicCvLeftRail(
                            left: '',
                            leftStyle: bodyStyle,
                            content: pw.Text('• ${bullets[b]}', style: bodyStyle),
                          ),
                        );
                      }
                    }
                    return out;
                  default:
                    return null;
                }
              },
            ),
          );

          if (languages.isNotEmpty) {
            w.add(pw.SizedBox(height: 10));
            w.add(_classicCvRule());
            w.add(pw.SizedBox(height: 10));
            final mid = (languages.length + 1) ~/ 2;
            pw.Widget langCell(({String name, String level}) item) {
              return pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(item.name, style: bodyStyle)),
                  if (item.level.isNotEmpty)
                    pw.Text(item.level, style: bodyStyle),
                ],
              );
            }
            w.add(
              _classicCvLeftRail(
                left: 'LANGUAGES',
                leftStyle: labelStyle,
                content: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          for (final item in languages.take(mid)) langCell(item),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          for (final item in languages.skip(mid)) langCell(item),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return w;
        },
      ),
    );
  }
}
