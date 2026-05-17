part of 'package:resume_app/core/services/resume_services.dart';

pw.Widget _atsMultiPageHeaderGap(pw.Context context) =>
    context.pageNumber > 1 ? pw.SizedBox(height: 40) : pw.SizedBox();

/// Slightly smaller than body text so keyword lists read lighter than paragraphs.
double _atsPdfSkillsBodyPt(double bodyPt) => math.max(9.0, bodyPt - 1.35);

pw.Widget _atsHighlightedSummaryText(
  String summary, {
  required double bodyPt,
  required bool highlightSummary,
  required PdfColor highlightColor,
}) {
  final style = pw.TextStyle(
    fontSize: bodyPt,
    lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
  );
  if (!highlightSummary) {
    return pw.Text(summary, style: style);
  }
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    color: highlightColor,
    child: pw.Text(summary, style: style),
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
  PdfColor get _atsGrayBand => PdfColor.fromHex('#E6E6E6');
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

  List<String> _atsHeaderContactLines(ResumeData resume) {
    final email = resume.email.trim();
    final phone = resume.phone.trim();
    final loc = resume.location.trim();
    final web = resume.website.trim();
    final lines = <String>[];
    if (loc.isNotEmpty) {
      lines.add(loc);
    }
    if (email.isNotEmpty && phone.isNotEmpty) {
      lines.add('$email    $phone');
    } else if (email.isNotEmpty) {
      lines.add(email);
    } else if (phone.isNotEmpty) {
      lines.add(phone);
    }
    if (web.isNotEmpty) {
      lines.add(web);
    }
    return lines;
  }

  pw.Widget _atsSolidRule({PdfColor color = PdfColors.black}) {
    return pw.Container(height: 1, color: color);
  }

  pw.Widget _atsGraySectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      color: _atsGrayBand,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: pw.Center(
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline,
            color: PdfColors.black,
          ),
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
  }) {
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
            children: [
              pw.Expanded(
                child: pw.Text(
                  top,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: bodyPt,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
        );
        out.add(pw.SizedBox(height: 2));
        out.add(
          pw.Text(
            item.company.ifEmpty('Company'),
            style: pw.TextStyle(fontSize: bodyPt, color: PdfColors.black),
          ),
        );
      } else {
        out.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '* ${item.role.ifEmpty('Role')}, ${item.company.ifEmpty('Company')}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: bodyPt,
                    color: PdfColors.black,
                  ),
                ),
              ),
              if (dateStr.isNotEmpty)
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(
                    fontSize: bodyPt,
                    color: _atsMuted,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
            ],
          ),
        );
      }
      out.add(pw.SizedBox(height: 4));
      final highlightedBullets =
          highlightedBulletsByExperience[i] ?? const <String>{};
      for (final b in _workBulletLines(item)) {
        final lineStyle = pw.TextStyle(color: PdfColors.black, fontSize: bodyPt);
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
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final name = _displayName(resume).toUpperCase();
    final job = resume.jobTitle.trim();
    final contact = _atsHeaderContactLines(resume);
    final skills = _skillsForDisplay(resume);

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
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  if (job.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      job,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: bodyPt),
                    ),
                  ],
                  if (contact.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    for (var i = 0; i < contact.length; i++)
                      pw.Padding(
                        padding: pw.EdgeInsets.only(top: i == 0 ? 0 : 2),
                        child: pw.Text(
                          contact[i],
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: bodyPt - 0.5),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            _atsSolidRule(),
            pw.SizedBox(height: 12),
            _atsGraySectionTitle('Summary'),
            pw.SizedBox(height: 6),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Add a concise summary aligned to your target roles.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
          ];

          if (resume.includeWorkInResume) {
            w.add(_atsGraySectionTitle('Experience'));
            w.add(pw.SizedBox(height: 6));
            final items = resume.visibleWorkExperiences;
            if (items.isEmpty) {
              w.add(pw.Text('Add your professional experience.'));
            } else {
              w.addAll(
                _atsExperienceEntries(
                  items,
                  bodyPt,
                  highlightedBulletsByExperience:
                      highlightedBulletsByExperience,
                  highlightColor: highlightColor,
                ),
              );
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeEducationInResume) {
            w.add(_atsGraySectionTitle('Education'));
            w.add(pw.SizedBox(height: 6));
            final edu = resume.visibleEducation;
            if (edu.isEmpty) {
              w.add(pw.Text('Add your education.'));
            } else {
              for (final item in edu) {
                w.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '* ${item.institution.ifEmpty('School')}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: bodyPt,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                item.degree.ifEmpty('Degree'),
                                style: pw.TextStyle(
                                  fontStyle: pw.FontStyle.italic,
                                  fontSize: bodyPt,
                                ),
                              ),
                            ),
                            pw.Text(
                              educationDateRangeLabel(
                                item.startDate,
                                item.endDate,
                              ),
                              style: pw.TextStyle(
                                fontSize: bodyPt,
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
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeSkillsInResume) {
            w.add(_atsGraySectionTitle('Skills'));
            w.add(pw.SizedBox(height: 6));
            if (skills.isEmpty) {
              w.add(pw.Text('List relevant tools and competencies.'));
            } else if (highlightedSkills.isNotEmpty) {
              w.add(
                _twoColumnBulletListWithHighlights(
                  skills,
                  highlightedSkills,
                  highlightColor,
                  fontSize: _atsPdfSkillsBodyPt(bodyPt),
                ),
              );
            } else {
              for (final row in _twoColumnBulletRows(
                skills,
                columnGap: 22,
                itemBottom: 4,
                fontSize: _atsPdfSkillsBodyPt(bodyPt),
              )) {
                w.add(row);
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeProjectsInResume) {
            w.add(_atsGraySectionTitle('Projects'));
            w.add(pw.SizedBox(height: 6));
            final projects = resume.visibleProjects;
            if (projects.isEmpty) {
              w.add(pw.Text('Highlight measurable outcomes.'));
            } else {
              for (final p in projects) {
                w.addAll([
                  ..._buildCompactProjectWidgets(p, bodyFontPt: bodyPt),
                ]);
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          for (final section in resume.visibleCustomSections) {
            w.add(_atsGraySectionTitle(section.title.ifEmpty('Additional')));
            w.add(pw.SizedBox(height: 6));
            for (final widget in _pwCustomSectionBodyWidgets(section)) {
              w.add(widget);
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          return w;
        },
      ),
    );
  }

  void _addAtsSerifRulesTemplatePage(
    pw.Document document,
    ResumeData resume, {
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final name = _displayName(resume);
    final job = resume.jobTitle.trim();
    final email = resume.email.trim();
    final phone = resume.phone.trim();
    final loc = resume.location.trim();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 40, 44, 40),
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
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (job.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          job,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: bodyPt,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 5),
                      if (loc.isNotEmpty)
                        pw.Text(loc, style: pw.TextStyle(fontSize: bodyPt)),
                      if (phone.isNotEmpty)
                        pw.Text(phone, style: pw.TextStyle(fontSize: bodyPt)),
                    ],
                  ),
                ),
                if (email.isNotEmpty)
                  pw.Text(
                    email,
                    style: pw.TextStyle(
                      fontSize: bodyPt,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Summary',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: bodyPt + 1,
              ),
            ),
            pw.SizedBox(height: 4),
            _atsSolidRule(),
            pw.SizedBox(height: 8),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Summarize impact and scope in two to four sentences.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
          ];

          if (resume.includeWorkInResume) {
            w.add(
              pw.Text(
                'Experience',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 1,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 4));
            w.add(_atsSolidRule());
            w.add(pw.SizedBox(height: 8));
            final items = resume.visibleWorkExperiences;
            if (items.isEmpty) {
              w.add(pw.Text('Add roles with measurable achievements.'));
            } else {
              for (var i = 0; i < items.length; i++) {
                final item = items[i];
                final dates = _atsWorkDateRange(item);
                w.add(
                  pw.Text(
                    item.role.ifEmpty('Role'),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyPt + 0.5,
                    ),
                  ),
                );
                w.add(pw.SizedBox(height: 3));
                w.add(
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          item.company.ifEmpty('Company'),
                          style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            fontSize: bodyPt,
                          ),
                        ),
                      ),
                      if (dates.isNotEmpty)
                        pw.Text(
                          dates,
                          style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            fontSize: bodyPt,
                            color: _atsMuted,
                          ),
                        ),
                    ],
                  ),
                );
                w.add(pw.SizedBox(height: 4));
                final highlightedBullets =
                    highlightedBulletsByExperience[i] ?? const <String>{};
                for (final b in _workBulletLines(item)) {
                  w.add(
                    _atsHighlightedBulletLine(
                      b,
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: bodyPt,
                      ),
                      isHighlighted: highlightedBullets.contains(b),
                      highlightColor: highlightColor,
                    ),
                  );
                }
                if (i < items.length - 1) {
                  w.add(pw.SizedBox(height: 12));
                }
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeEducationInResume) {
            w.add(
              pw.Text(
                'Education',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 1,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 4));
            w.add(_atsSolidRule());
            w.add(pw.SizedBox(height: 8));
            final edu = resume.visibleEducation;
            if (edu.isEmpty) {
              w.add(pw.Text('Add your degrees and certifications.'));
            } else {
              for (final item in edu) {
                final range = educationDateRangeLabel(
                  item.startDate,
                  item.endDate,
                );
                w.add(
                  pw.Text(
                    '${item.degree.ifEmpty('Degree')}'
                    '${range.isNotEmpty ? '  ·  $range' : ''}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyPt,
                    ),
                  ),
                );
                w.add(pw.SizedBox(height: 3));
                w.add(
                  pw.Text(
                    item.institution.ifEmpty('Institution'),
                    style: pw.TextStyle(fontSize: bodyPt),
                  ),
                );
                w.add(pw.SizedBox(height: 8));
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeSkillsInResume) {
            w.add(
              pw.Text(
                'Skills',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 1,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 4));
            w.add(_atsSolidRule());
            w.add(pw.SizedBox(height: 8));
            final skills = _skillsForDisplay(resume);
            if (skills.isEmpty) {
              w.add(pw.Text('Add targeted skills.'));
            } else if (highlightedSkills.isNotEmpty) {
              w.add(
                _twoColumnBulletListWithHighlights(
                  skills,
                  highlightedSkills,
                  highlightColor,
                  fontSize: _atsPdfSkillsBodyPt(bodyPt),
                ),
              );
            } else {
              for (final s in skills) {
                w.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      s,
                      style: pw.TextStyle(
                        fontSize: _atsPdfSkillsBodyPt(bodyPt),
                      ),
                    ),
                  ),
                );
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeProjectsInResume) {
            w.add(
              pw.Text(
                'Projects',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 1,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 4));
            w.add(_atsSolidRule());
            w.add(pw.SizedBox(height: 8));
            for (final p in resume.visibleProjects) {
              w.addAll(_buildCompactProjectWidgets(p, bodyFontPt: bodyPt));
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          for (final section in resume.visibleCustomSections) {
            w.add(
              pw.Text(
                section.title.ifEmpty('Additional'),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 1,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 4));
            w.add(_atsSolidRule());
            w.add(pw.SizedBox(height: 8));
            for (final widget in _pwCustomSectionBodyWidgets(section)) {
              w.add(widget);
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          return w;
        },
      ),
    );
  }

  void _addAtsModernFlowTemplatePage(
    pw.Document document,
    ResumeData resume, {
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final name = _displayName(resume);
    final email = resume.email.trim();
    final phone = resume.phone.trim();
    final loc = resume.location.trim();
    final parts = <String>[];
    if (loc.isNotEmpty) {
      parts.add(loc);
    }
    if (email.isNotEmpty) {
      parts.add(email);
    }
    if (phone.isNotEmpty) {
      parts.add(phone);
    }
    final contactLine = parts.join('  |  ');
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
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (contactLine.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      contactLine,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: bodyPt - 0.5),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            _atsSolidRule(),
            pw.SizedBox(height: 12),
            pw.Text(
              'Professional Summary',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: bodyPt + 0.5,
              ),
            ),
            pw.SizedBox(height: 6),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Describe strengths and focus areas clearly.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
            _atsSolidRule(color: PdfColor.fromHex('#CCCCCC')),
            pw.SizedBox(height: 12),
          ];

          if (resume.includeEducationInResume) {
            w.add(
              pw.Text(
                'Education',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 0.5,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 6));
            final edu = resume.visibleEducation;
            if (edu.isEmpty) {
              w.add(pw.Text('Add schools and programs.'));
            } else {
              for (final item in edu) {
                w.add(
                  pw.Text(
                    item.degree.ifEmpty('Program'),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyPt,
                    ),
                  ),
                );
                final range = educationDateRangeLabel(
                  item.startDate,
                  item.endDate,
                );
                final line =
                    '${item.institution.ifEmpty('School')}'
                    '${range.isNotEmpty ? '  |  Graduated: $range' : ''}';
                w.add(pw.SizedBox(height: 2));
                w.add(pw.Text(line, style: pw.TextStyle(fontSize: bodyPt)));
                if (item.score.trim().isNotEmpty) {
                  w.add(
                    pw.Text(item.score, style: pw.TextStyle(fontSize: bodyPt)),
                  );
                }
                w.add(pw.SizedBox(height: 8));
              }
            }
            w.add(pw.SizedBox(height: 8));
            w.add(_atsSolidRule(color: PdfColor.fromHex('#CCCCCC')));
            w.add(pw.SizedBox(height: 12));
          }

          if (resume.includeSkillsInResume) {
            w.add(
              pw.Text(
                'Skills',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 0.5,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 6));
            if (skills.isEmpty) {
              w.add(pw.Text('Add skills that mirror job postings.'));
            } else if (highlightedSkills.isNotEmpty) {
              w.add(
                _twoColumnBulletListWithHighlights(
                  skills,
                  highlightedSkills,
                  highlightColor,
                  fontSize: _atsPdfSkillsBodyPt(bodyPt),
                ),
              );
            } else {
              for (final s in skills) {
                w.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      s,
                      style: pw.TextStyle(
                        fontSize: _atsPdfSkillsBodyPt(bodyPt),
                      ),
                    ),
                  ),
                );
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
            w.add(_atsSolidRule(color: PdfColor.fromHex('#CCCCCC')));
            w.add(pw.SizedBox(height: 12));
          }

          if (resume.includeWorkInResume) {
            w.add(
              pw.Text(
                'Experience',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 0.5,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 6));
            final items = resume.visibleWorkExperiences;
            if (items.isEmpty) {
              w.add(pw.Text('Add roles with outcomes.'));
            } else {
              for (var i = 0; i < items.length; i++) {
                final item = items[i];
                w.add(
                  pw.Text(
                    '${item.role.ifEmpty('Role')} — ${item.company.ifEmpty('Company')}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyPt,
                    ),
                  ),
                );
                final dr = _atsWorkDateRange(item);
                if (dr.isNotEmpty) {
                  w.add(pw.Text(dr, style: pw.TextStyle(fontSize: bodyPt)));
                }
                final highlightedBullets =
                    highlightedBulletsByExperience[i] ?? const <String>{};
                for (final b in _workBulletLines(item)) {
                  w.add(
                    _atsHighlightedBulletLine(
                      b,
                      style: pw.TextStyle(fontSize: bodyPt),
                      isHighlighted: highlightedBullets.contains(b),
                      highlightColor: highlightColor,
                    ),
                  );
                }
                if (i < items.length - 1) {
                  w.add(pw.SizedBox(height: 10));
                }
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
            w.add(_atsSolidRule(color: PdfColor.fromHex('#CCCCCC')));
            w.add(pw.SizedBox(height: 12));
          }

          if (resume.includeProjectsInResume) {
            w.add(
              pw.Text(
                'Projects',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 0.5,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 6));
            for (final p in resume.visibleProjects) {
              w.addAll(_buildCompactProjectWidgets(p, bodyFontPt: bodyPt));
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          for (final section in resume.visibleCustomSections) {
            w.add(_atsSolidRule(color: PdfColor.fromHex('#CCCCCC')));
            w.add(pw.SizedBox(height: 10));
            w.add(
              pw.Text(
                section.title.ifEmpty('Additional'),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 0.5,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 6));
            for (final widget in _pwCustomSectionBodyWidgets(section)) {
              w.add(widget);
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          return w;
        },
      ),
    );
  }

  void _addAtsExecutiveTemplatePage(
    pw.Document document,
    ResumeData resume, {
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final job = resume.jobTitle.trim();
    final name = _displayName(resume);
    final loc = resume.location.trim();
    final email = resume.email.trim();
    final phone = resume.phone.trim();
    final skills = _skillsForDisplay(resume);

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
                  if (job.isNotEmpty)
                    pw.Text(
                      job.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: bodyPt,
                      ),
                    ),
                  if (job.isNotEmpty) pw.SizedBox(height: 4),
                  pw.Text(
                    name,
                    style: pw.TextStyle(
                      fontSize: 19,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (loc.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(loc, style: pw.TextStyle(fontSize: bodyPt)),
                  ],
                  if (email.isNotEmpty || phone.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      [email, phone].where((e) => e.isNotEmpty).join('   '),
                      style: pw.TextStyle(fontSize: bodyPt),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            _atsSolidRule(),
            pw.SizedBox(height: 12),
            pw.Text(
              'SUMMARY',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: bodyPt + 0.5,
              ),
            ),
            pw.SizedBox(height: 6),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Lead with scope, domains, and measurable outcomes.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
            pw.Text(
              'EXPERIENCE',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: bodyPt + 0.5,
              ),
            ),
            pw.SizedBox(height: 6),
          ];

          if (resume.includeWorkInResume) {
            final items = resume.visibleWorkExperiences;
            if (items.isEmpty) {
              w.add(pw.Text('Add leadership and core responsibilities.'));
            } else {
              w.addAll(
                _atsExperienceEntries(
                  items,
                  bodyPt,
                  usePipeRoleCompany: true,
                  highlightedBulletsByExperience:
                      highlightedBulletsByExperience,
                  highlightColor: highlightColor,
                ),
              );
            }
          }
          w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));

          w.add(
            pw.Text(
              'EDUCATION',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: bodyPt + 0.5,
              ),
            ),
          );
          w.add(pw.SizedBox(height: 6));
          if (resume.includeEducationInResume) {
            final edu = resume.visibleEducation;
            if (edu.isEmpty) {
              w.add(pw.Text('Add degree and institution.'));
            } else {
              for (final item in edu) {
                final range = educationDateRangeLabel(
                  item.startDate,
                  item.endDate,
                );
                w.add(
                  pw.Text(
                    '${item.institution.ifEmpty('University')} | ${item.degree.ifEmpty('Degree')}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyPt,
                    ),
                  ),
                );
                w.add(pw.SizedBox(height: 3));
                final detailLine = [
                  if (item.score.trim().isNotEmpty) item.score.trim(),
                  if (range.isNotEmpty) range,
                ].join(' | ');
                if (detailLine.isNotEmpty) {
                  w.add(
                    pw.Text(detailLine, style: pw.TextStyle(fontSize: bodyPt)),
                  );
                }
                w.add(pw.SizedBox(height: 8));
              }
            }
          }
          w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));

          w.add(
            pw.Text(
              'SKILLS',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: bodyPt + 0.5,
              ),
            ),
          );
          w.add(pw.SizedBox(height: 6));
          if (resume.includeSkillsInResume && skills.isNotEmpty) {
            if (highlightedSkills.isNotEmpty) {
              w.add(
                _twoColumnBulletListWithHighlights(
                  skills,
                  highlightedSkills,
                  highlightColor,
                  fontSize: _atsPdfSkillsBodyPt(bodyPt),
                ),
              );
            } else {
              for (final row in _twoColumnBulletRows(
                skills,
                columnGap: 18,
                itemBottom: 3,
                fontSize: _atsPdfSkillsBodyPt(bodyPt),
              )) {
                w.add(row);
              }
            }
          } else {
            w.add(pw.Text('Add keywords from target job descriptions.'));
          }

          if (resume.includeProjectsInResume &&
              resume.visibleProjects.isNotEmpty) {
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
            w.add(
              pw.Text(
                'PROJECTS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt + 0.5,
                ),
              ),
            );
            w.add(pw.SizedBox(height: 6));
            for (final p in resume.visibleProjects) {
              w.addAll(_buildCompactProjectWidgets(p, bodyFontPt: bodyPt));
            }
          }

          return w;
        },
      ),
    );
  }

  List<String> _atsCenterClassicTaglineParts(ResumeData resume) {
    final job = resume.jobTitle.trim();
    final skillTags = _skillsForDisplay(resume).take(4).toList();
    return [
      if (job.isNotEmpty) job,
      ...skillTags,
    ];
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

  pw.Widget _atsCenterClassicSectionTitle(String title, double bodyPt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _atsSolidRule(color: PdfColor.fromHex('#CCCCCC')),
        pw.SizedBox(height: 10),
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: bodyPt + 0.5,
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  List<pw.Widget> _atsCenterClassicExperienceEntries(
    List<WorkExperience> items,
    double bodyPt, {
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
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: bodyPt,
                ),
              ),
            ),
            if (dateStr.isNotEmpty)
              pw.Text(
                dateStr,
                style: pw.TextStyle(fontSize: bodyPt, color: _atsMuted),
              ),
          ],
        ),
      );
      out.add(pw.SizedBox(height: 2));
      out.add(
        pw.Text(
          item.role.ifEmpty('Role'),
          style: pw.TextStyle(fontSize: bodyPt),
        ),
      );
      out.add(pw.SizedBox(height: 4));
      final highlightedBullets =
          highlightedBulletsByExperience[i] ?? const <String>{};
      for (final b in _workBulletLines(item)) {
        out.add(
          _atsHighlightedBulletLine(
            '• $b',
            style: pw.TextStyle(fontSize: bodyPt),
            isHighlighted:
                highlightColor != null && highlightedBullets.contains(b),
            highlightColor: highlightColor ?? _atsHighlightColor,
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
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final name = _displayName(resume);
    final tagline = _atsCenterClassicTaglineParts(resume).join(' | ');
    final contactPipe = _atsCenterClassicContactPipe(resume);
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
                    style: pw.TextStyle(
                      fontSize: 21,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (tagline.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      tagline,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: bodyPt - 0.25),
                    ),
                  ],
                  if (contactPipe.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      contactPipe,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: bodyPt - 0.5),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            _atsCenterClassicSectionTitle('Summary', bodyPt),
            _atsHighlightedSummaryText(
              resume.summary.trim().ifEmpty(
                'Concise overview of experience, domains, and impact.',
              ),
              bodyPt: bodyPt,
              highlightSummary: highlightSummary,
              highlightColor: highlightColor,
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
          ];

          if (resume.includeWorkInResume) {
            w.add(_atsCenterClassicSectionTitle('Experience', bodyPt));
            final items = resume.visibleWorkExperiences;
            if (items.isEmpty) {
              w.add(pw.Text('Add roles with measurable outcomes.'));
            } else {
              w.addAll(
                _atsCenterClassicExperienceEntries(
                  items,
                  bodyPt,
                  highlightedBulletsByExperience:
                      highlightedBulletsByExperience,
                  highlightColor: highlightColor,
                ),
              );
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeSkillsInResume) {
            w.add(_atsCenterClassicSectionTitle('Skills', bodyPt));
            if (skills.isEmpty) {
              w.add(pw.Text('List tools and competencies.'));
            } else {
              w.add(
                pw.Text(
                  skills.join(', '),
                  style: pw.TextStyle(fontSize: bodyPt),
                ),
              );
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeProjectsInResume &&
              resume.visibleProjects.isNotEmpty) {
            w.add(
              _atsCenterClassicSectionTitle('Training / Courses', bodyPt),
            );
            for (final p in resume.visibleProjects) {
              w.add(
                pw.Text(
                  p.title.ifEmpty('Course'),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: bodyPt,
                  ),
                ),
              );
              final overview = p.overview.trim();
              if (overview.isNotEmpty) {
                w.add(pw.SizedBox(height: 2));
                w.add(pw.Text(overview, style: pw.TextStyle(fontSize: bodyPt)));
              }
              for (final b in p.bullets.where((e) => e.trim().isNotEmpty)) {
                w.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      '• $b',
                      style: pw.TextStyle(fontSize: bodyPt),
                    ),
                  ),
                );
              }
              w.add(pw.SizedBox(height: 8));
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeEducationInResume) {
            w.add(_atsCenterClassicSectionTitle('Education', bodyPt));
            final edu = resume.visibleEducation;
            if (edu.isEmpty) {
              w.add(pw.Text('Add degree and institution.'));
            } else {
              for (final item in edu) {
                final range = educationDateRangeLabel(
                  item.startDate,
                  item.endDate,
                );
                w.add(
                  pw.Text(
                    item.degree.ifEmpty('Degree'),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyPt,
                    ),
                  ),
                );
                w.add(pw.SizedBox(height: 2));
                w.add(
                  pw.Text(
                    '${item.institution.ifEmpty('School')}'
                    '${range.isNotEmpty ? ' ($range)' : ''}',
                    style: pw.TextStyle(fontSize: bodyPt),
                  ),
                );
                w.add(pw.SizedBox(height: 8));
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          for (final section in resume.visibleCustomSections) {
            w.add(
              _atsCenterClassicSectionTitle(
                section.title.ifEmpty('Additional'),
                bodyPt,
              ),
            );
            for (final widget in _pwCustomSectionBodyWidgets(section)) {
              w.add(widget);
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          return w;
        },
      ),
    );
  }

  static final PdfColor _atsProfessionalBlue = PdfColor.fromHex('#4A90C4');

  pw.Widget _atsProfessionalBlueSectionTitle(String title, double bodyPt) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _atsProfessionalBlue,
          fontWeight: pw.FontWeight.bold,
          fontSize: bodyPt + 2.5,
        ),
      ),
    );
  }

  void _addAtsProfessionalBlueTemplatePage(
    pw.Document document,
    ResumeData resume, {
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final highlightColor = _atsHighlightColor;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final name = _displayName(resume);
    final job = resume.jobTitle.trim();
    final email = resume.email.trim();
    final phone = resume.phone.trim();
    final loc = resume.location.trim();
    final skills = _skillsForDisplay(resume);
    final contactLines = <String>[
      if (email.isNotEmpty) email,
      if (phone.isNotEmpty) phone,
      if (loc.isNotEmpty) loc,
    ];

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 40, 44, 40),
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
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          color: _atsProfessionalBlue,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (job.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          job,
                          style: pw.TextStyle(
                            color: _atsProfessionalBlue,
                            fontSize: bodyPt + 1,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
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
                          child: pw.Text(
                            line,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              color: _atsProfessionalBlue,
                              fontSize: bodyPt - 0.25,
                            ),
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
            ),
            pw.SizedBox(height: ResumeTypography.sectionGapPdfPt),
          ];

          if (resume.includeWorkInResume) {
            w.add(_atsProfessionalBlueSectionTitle('Professional Experience', bodyPt));
            final items = resume.visibleWorkExperiences;
            if (items.isEmpty) {
              w.add(pw.Text('Add roles with outcomes.'));
            } else {
              for (var i = 0; i < items.length; i++) {
                final item = items[i];
                final dateStr = _atsWorkDateRange(item);
                w.add(
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          item.company.ifEmpty('Company'),
                          style: pw.TextStyle(
                            color: _atsProfessionalBlue,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: bodyPt,
                          ),
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        pw.Text(
                          dateStr,
                          style: pw.TextStyle(
                            color: _atsProfessionalBlue,
                            fontSize: bodyPt,
                          ),
                        ),
                    ],
                  ),
                );
                w.add(pw.SizedBox(height: 2));
                w.add(
                  pw.Text(
                    item.role.ifEmpty('Role'),
                    style: pw.TextStyle(
                      color: _atsProfessionalBlue,
                      fontSize: bodyPt,
                    ),
                  ),
                );
                w.add(pw.SizedBox(height: 4));
                final highlightedBullets =
                    highlightedBulletsByExperience[i] ?? const <String>{};
                for (final b in _workBulletLines(item)) {
                  w.add(
                    _atsHighlightedBulletLine(
                      '• $b',
                      style: pw.TextStyle(fontSize: bodyPt),
                      isHighlighted: highlightedBullets.contains(b),
                      highlightColor: highlightColor,
                    ),
                  );
                }
                if (i < items.length - 1) {
                  w.add(pw.SizedBox(height: 10));
                }
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeEducationInResume) {
            w.add(_atsProfessionalBlueSectionTitle('Education', bodyPt));
            final edu = resume.visibleEducation;
            if (edu.isEmpty) {
              w.add(pw.Text('Add schools and programs.'));
            } else {
              for (final item in edu) {
                w.add(
                  pw.Text(
                    item.degree.ifEmpty('Program'),
                    style: pw.TextStyle(
                      color: _atsProfessionalBlue,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyPt,
                    ),
                  ),
                );
                w.add(pw.SizedBox(height: 2));
                w.add(
                  pw.Text(
                    item.institution.ifEmpty('School'),
                    style: pw.TextStyle(fontSize: bodyPt),
                  ),
                );
                w.add(pw.SizedBox(height: 8));
              }
            }
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
          }

          if (resume.includeSkillsInResume) {
            w.add(
              _atsProfessionalBlueSectionTitle('Areas of Expertise', bodyPt),
            );
            if (skills.isEmpty) {
              w.add(pw.Text('Add skills aligned to your target roles.'));
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
              final skillPt = _atsPdfSkillsBodyPt(bodyPt);
              for (var r = 0; r < rowCount; r++) {
                w.add(
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
                                        margin: const pw.EdgeInsets.only(
                                          top: 3,
                                          right: 5,
                                        ),
                                        decoration: pw.BoxDecoration(
                                          color: _atsProfessionalBlue,
                                          shape: pw.BoxShape.circle,
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: highlightedSkills.contains(
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
                                                  style: pw.TextStyle(
                                                    fontSize: skillPt,
                                                  ),
                                                ),
                                              )
                                            : pw.Text(
                                                columns[c][r],
                                                style: pw.TextStyle(
                                                  fontSize: skillPt,
                                                ),
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
          }

          for (final section in resume.visibleCustomSections) {
            w.add(pw.SizedBox(height: ResumeTypography.sectionGapPdfPt));
            w.add(
              _atsProfessionalBlueSectionTitle(
                section.title.ifEmpty('Additional'),
                bodyPt,
              ),
            );
            for (final widget in _pwCustomSectionBodyWidgets(section)) {
              w.add(widget);
            }
          }

          return w;
        },
      ),
    );
  }

  pw.Widget _accentStripSectionTitle(
    String title,
    double bodyPt, {
    required GaramondPdfFonts garamond,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: garamondPdfTextStyle(
          garamond,
          ResumeFontWeight.w700,
          fontSize: bodyPt + 6,
        ).copyWith(letterSpacing: 0.2),
      ),
    );
  }

  pw.TextStyle _accentStripBodyPdfStyle(
    CalibriPdfFonts calibri,
    double bodyPt, {
    int weight = ResumeFontWeight.w400,
  }) =>
      calibriBodyPdfTextStyle(
        calibri,
        bodyPt,
        weight: weight,
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
    final bodyPt = resume.effectiveBodyFontPt.toDouble() + 0.4;
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
                ResumeFontWeight.w700,
                fontSize: 33,
              ).copyWith(letterSpacing: 0.4),
            ),
            if (contactLine.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text(
                contactLine,
                style: _accentStripBodyPdfStyle(
                  calibri,
                  bodyPt + 1,
                  weight: ResumeFontWeight.w700,
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
              ),
            ],
          ];

          if (resume.includeWorkInResume) {
            widgets.add(pw.SizedBox(height: 28));
            widgets.add(
              _accentStripSectionTitle(
                'EXPERIENCE',
                bodyPt,
                garamond: garamond,
              ),
            );
            final items = resume.visibleWorkExperiences;
            if (items.isEmpty) {
              widgets.add(
                pw.Text(
                  'Add experience entries with dates, roles, and outcomes.',
                  style: _accentStripBodyPdfStyle(calibri, bodyPt),
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
                    highlightedBulletsByExperience[index] ?? const <String>{};

                if (dateLabel.isNotEmpty) {
                  widgets.add(
                    pw.Text(
                      dateLabel,
                      style: _accentStripBodyPdfStyle(
                        calibri,
                        bodyPt + 2.2,
                        weight: ResumeFontWeight.w700,
                      ),
                    ),
                  );
                }
                if (roleLine.isNotEmpty) {
                  widgets.add(pw.SizedBox(height: 4));
                  widgets.add(
                    pw.Text(
                      roleLine,
                      style: _accentStripBodyPdfStyle(
                        calibri,
                        bodyPt + 0.8,
                        weight: ResumeFontWeight.w700,
                      ),
                    ),
                  );
                }

                if (bullets.isNotEmpty) {
                  widgets.add(pw.SizedBox(height: 6));
                  for (final bullet in bullets) {
                    widgets.add(
                      _atsHighlightedBulletLine(
                        bullet,
                        style: _accentStripBodyPdfStyle(calibri, bodyPt),
                        isHighlighted: highlightedBullets.contains(bullet),
                        highlightColor: highlightColor,
                      ),
                    );
                  }
                } else if (item.description.trim().isNotEmpty) {
                  widgets.add(pw.SizedBox(height: 6));
                  widgets.add(
                    pw.Text(
                      item.description.trim(),
                      style: _accentStripBodyPdfStyle(calibri, bodyPt),
                    ),
                  );
                }

                if (index < items.length - 1) {
                  widgets.add(pw.SizedBox(height: 18));
                }
              }
            }
          }

          if (resume.includeEducationInResume) {
            widgets.add(pw.SizedBox(height: 22));
            widgets.add(
              _accentStripSectionTitle(
                'EDUCATION',
                bodyPt,
                garamond: garamond,
              ),
            );
            final items = resume.visibleEducation;
            if (items.isEmpty) {
              widgets.add(
                pw.Text(
                  'Add education details.',
                  style: _accentStripBodyPdfStyle(calibri, bodyPt),
                ),
              );
            } else {
              for (final item in items) {
                final dates = [
                  item.startDate.trim(),
                  item.endDate.trim(),
                ].where((value) => value.isNotEmpty).join(' – ');
                widgets.add(
                  pw.Text(
                    item.degree.trim().ifEmpty('Degree'),
                    style: _accentStripBodyPdfStyle(
                      calibri,
                      bodyPt + 0.8,
                      weight: ResumeFontWeight.w700,
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 3));
                widgets.add(
                  pw.Text(
                    [
                      item.institution.trim().ifEmpty('Institution'),
                      if (dates.isNotEmpty) dates,
                    ].join(' | '),
                    style: _accentStripBodyPdfStyle(calibri, bodyPt),
                  ),
                );
                widgets.add(pw.SizedBox(height: 10));
              }
            }
          }

          if (resume.includeSkillsInResume) {
            widgets.add(pw.SizedBox(height: 18));
            widgets.add(
              _accentStripSectionTitle(
                'SKILLS',
                bodyPt,
                garamond: garamond,
              ),
            );
            if (skills.isEmpty) {
              widgets.add(
                pw.Text(
                  'Add skills aligned to the target role.',
                  style: _accentStripBodyPdfStyle(calibri, bodyPt),
                ),
              );
            } else {
              final rows = <pw.Widget>[];
              for (final skill in skills) {
                final skillStyle = _accentStripBodyPdfStyle(calibri, bodyPt);
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
              widgets.add(
                pw.Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: rows,
                ),
              );
            }
          }

          if (resume.includeProjectsInResume) {
            final items = resume.visibleProjects;
            if (items.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 18));
              widgets.add(
                _accentStripSectionTitle(
                  'PROJECTS',
                  bodyPt,
                  garamond: garamond,
                ),
              );
              for (final item in items) {
                widgets.add(
                  pw.Text(
                    item.title.trim().ifEmpty('Project'),
                    style: _accentStripBodyPdfStyle(
                      calibri,
                      bodyPt + 0.8,
                      weight: ResumeFontWeight.w700,
                    ),
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
                  widgets.add(pw.SizedBox(height: 4));
                  widgets.add(
                    pw.Text(
                      content,
                      style: _accentStripBodyPdfStyle(calibri, bodyPt),
                    ),
                  );
                }
                widgets.add(pw.SizedBox(height: 10));
              }
            }
          }

          for (final section in resume.visibleCustomSections) {
            widgets.add(pw.SizedBox(height: 18));
            widgets.add(
              _accentStripSectionTitle(
                section.title.trim().ifEmpty('ADDITIONAL').toUpperCase(),
                bodyPt,
                garamond: garamond,
              ),
            );
            for (final widget in _pwCustomSectionBodyWidgets(section)) {
              widgets.add(widget);
            }
          }

          return widgets;
        },
      ),
    );
  }
}
