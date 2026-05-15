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
  final style = pw.TextStyle(fontSize: bodyPt, lineSpacing: 2);
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
}
