part of 'package:resume_app/core/services/resume_services.dart';

/// Blue Diagonal: diagonal colour corners, a grey photo column on the left
/// (about, contact, skills, languages) and timeline-marked education and
/// experience on the right.
const double _blueDiagonalColumnWidthPt = 250.0;
const double _blueDiagonalColumnInsetPt = 30.0;
const double _blueDiagonalMainLeftPt = 282.0;
const double _blueDiagonalMainRightPt = 40.0;
const double _blueDiagonalTopPt = 34.0;
const double _blueDiagonalBottomPt = 46.0;
const double _blueDiagonalAvatarSizePt = 176.0;
const double _blueDiagonalHeaderHeightPt = 255.0;

/// Custom sections that belong in the left column.
final RegExp _blueDiagonalLeftSectionTitle = RegExp(
  r'^(languages?|references?|referees?|awards?|certifications?|certificates?|'
  r'interests?|hobbies)$',
  caseSensitive: false,
);

extension _ResumePdfBlueDiagonalPage on ResumePdfService {
  void _addBlueDiagonalTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final accent = _pdfRgb(resume.blueDiagonalAccentColor);
    final accentDark = _pdfRgb(resume.blueDiagonalDeepColor);
    final columnColor = _pdfRgb(resume.blueDiagonalColumnColor);
    final titleColor = _pdfRgb(resume.blueDiagonalTitleColor);
    final mutedColor = _pdfRgb(resume.blueDiagonalMutedColor);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final detailPt = bodyPt - 1.5;

    pw.TextStyle style(
      int weight,
      double size,
      PdfColor color, {
      double? lineSpacing,
    }) => garamondPdfTextStyle(
      fonts,
      weight,
      fontSize: size,
      color: color,
      lineSpacing: lineSpacing,
    );

    final sectionTitleStyle = style(ResumeFontWeight.w700, 17, titleColor);
    final entryDateStyle = style(ResumeFontWeight.w700, bodyPt, titleColor);
    final entryTitleStyle = style(ResumeFontWeight.w700, detailPt, titleColor);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      detailPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(detailPt),
    );

    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final leftSections = resume.visibleCustomSections
        .where((item) => _blueDiagonalLeftSectionTitle.hasMatch(item.title.trim()))
        .toList();
    final mainSections = resume.visibleCustomSections
        .where((item) => !leftSections.contains(item))
        .toList();

    pw.Widget icon(_BlueDiagonalIcon kind, double size, PdfColor color) =>
        pw.SizedBox(
          width: size,
          height: size,
          child: pw.CustomPaint(
            painter: (canvas, area) =>
                _paintBlueDiagonalIcon(canvas, area, kind, color),
          ),
        );

    pw.Widget sectionTitle(String title, _BlueDiagonalIcon kind) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          icon(kind, 19, titleColor),
          pw.SizedBox(width: 10),
          pw.Text(title, style: sectionTitleStyle),
        ],
      ),
    );

    pw.Widget bullet(String text, {bool highlight = false}) =>
        _headerSidebarMaybeHighlight(
          highlight: highlight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 3,
                  height: 3,
                  margin: const pw.EdgeInsets.only(top: 5, right: 8),
                  decoration: pw.BoxDecoration(
                    color: mutedColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(child: pw.Text(text, style: bodyStyle)),
              ],
            ),
          ),
        );

    /// Entry on the right column's timeline: a capped line, then the text.
    List<pw.Widget> timelineEntry({
      required String dates,
      required String title,
      required String subtitle,
      required List<pw.Widget> details,
    }) {
      pw.Widget dot() => pw.Container(
        width: 7,
        height: 7,
        decoration: pw.BoxDecoration(
          color: titleColor,
          shape: pw.BoxShape.circle,
        ),
      );
      return [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 7,
              margin: const pw.EdgeInsets.only(top: 3, right: 14),
              child: pw.Column(
                children: [
                  dot(),
                  pw.Container(
                    width: 1,
                    height: 30 + details.length * 12,
                    color: titleColor,
                  ),
                  dot(),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (dates.isNotEmpty)
                    pw.Text('($dates)', style: entryDateStyle),
                  pw.Text(title.toUpperCase(), style: entryTitleStyle),
                  if (subtitle.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 1),
                      child: pw.Text(subtitle, style: bodyStyle),
                    ),
                  if (details.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: details,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 14),
      ];
    }

    pw.Widget leftColumn() {
      final contacts = <(_BlueDiagonalIcon, String)>[
        (_BlueDiagonalIcon.phone, resume.phone.trim()),
        (_BlueDiagonalIcon.mail, resume.email.trim()),
        (_BlueDiagonalIcon.place, resume.location.trim()),
        (_BlueDiagonalIcon.link, resume.website.trim()),
        (_BlueDiagonalIcon.link, resume.linkedinLink.trim()),
        (_BlueDiagonalIcon.link, resume.githubLink.trim()),
      ].where((entry) => entry.$2.isNotEmpty).toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (resume.summary.trim().isNotEmpty) ...[
            sectionTitle('About Me', _BlueDiagonalIcon.person),
            _headerSidebarMaybeHighlight(
              highlight: highlightSummary,
              child: pw.Text(
                resume.summary.trim(),
                style: bodyStyle,
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
          if (contacts.isNotEmpty) ...[
            sectionTitle('Contact', _BlueDiagonalIcon.contact),
            for (final (kind, value) in contacts)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    icon(kind, 12, titleColor),
                    pw.SizedBox(width: 9),
                    pw.Expanded(
                      child: pw.FittedBox(
                        fit: pw.BoxFit.scaleDown,
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Text(value, style: bodyStyle),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (resume.skillsLinesForDisplay.isNotEmpty) ...[
            sectionTitle('Skills', _BlueDiagonalIcon.skills),
            for (final skill in resume.skillsLinesForDisplay.take(10))
              bullet(skill, highlight: highlightedSkills.contains(skill)),
          ],
          for (final section in leftSections) ...[
            sectionTitle(section.title.trim(), _BlueDiagonalIcon.language),
            for (final line in _slateSidebarRailSectionLines(section))
              bullet(line),
          ],
        ],
      );
    }

    final left = leftColumn();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _blueDiagonalMainLeftPt,
            _blueDiagonalTopPt,
            _blueDiagonalMainRightPt,
            _blueDiagonalBottomPt,
          ),
          buildBackground: (context) {
            final firstPage = context.pageNumber == 1;
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: pw.Container(
                      width: _blueDiagonalColumnWidthPt,
                      color: columnColor,
                    ),
                  ),
                  pw.Positioned.fill(
                    child: pw.CustomPaint(
                      painter: (canvas, size) => _paintBlueDiagonals(
                        canvas,
                        size,
                        accent: accent,
                        accentDark: accentDark,
                        drawTop: firstPage,
                      ),
                    ),
                  ),
                  if (firstPage) ...[
                    pw.Positioned(
                      left:
                          _blueDiagonalColumnWidthPt / 2 -
                          _blueDiagonalAvatarSizePt / 2,
                      top: 56,
                      child: pw.Container(
                        width: _blueDiagonalAvatarSizePt,
                        height: _blueDiagonalAvatarSizePt,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                        padding: const pw.EdgeInsets.all(7),
                        child: profileImage != null
                            ? pw.ClipOval(
                                child: pw.Image(
                                  profileImage,
                                  fit: pw.BoxFit.cover,
                                ),
                              )
                            : pw.Container(
                                alignment: pw.Alignment.center,
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#D6DCE4'),
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Text(
                                  _resumeInitials(resume),
                                  style: style(
                                    ResumeFontWeight.w700,
                                    42,
                                    titleColor,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    pw.Positioned(
                      left: _blueDiagonalColumnInsetPt,
                      top: 56 + _blueDiagonalAvatarSizePt + 14,
                      bottom: _blueDiagonalBottomPt,
                      child: pw.SizedBox(
                        width:
                            _blueDiagonalColumnWidthPt -
                            _blueDiagonalColumnInsetPt * 2,
                        child: pw.ClipRect(child: left),
                      ),
                    ),
                    pw.Positioned(
                      left: _blueDiagonalMainLeftPt,
                      // Keeps the name clear of the corner diagonals.
                      right: 150,
                      top: 120,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _displayName(resume),
                            style: style(ResumeFontWeight.w700, 34, titleColor),
                          ),
                          if (resume.jobTitle.trim().isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              resume.jobTitle.trim(),
                              style: style(
                                ResumeFontWeight.w400,
                                16,
                                mutedColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        build: (context) => [
          pw.SizedBox(height: _blueDiagonalHeaderHeightPt - _blueDiagonalTopPt),
          ..._pdfBodySectionsInBuilderOrder(
            resume,
            exclude: {ResumeBuilderSectionIds.skills},
            buildSection: (id) {
              final customIndex = ResumeBuilderSectionIds.customIndex(id);
              if (customIndex != null) {
                if (customIndex < 0 ||
                    customIndex >= resume.customSections.length) {
                  return null;
                }
                final item = resume.customSections[customIndex];
                if (!mainSections.contains(item)) return null;
                return [
                  sectionTitle(item.title.ifEmpty('Custom section'), _BlueDiagonalIcon.article),
                  ..._pwCustomSectionBodyWidgets(
                    item,
                    garamond: fonts,
                    bodyFontPt: detailPt,
                    accentStripGaramondBody: true,
                  ),
                ];
              }
              switch (id) {
                case ResumeBuilderSectionIds.education:
                  if (education.isEmpty) return null;
                  return [
                    sectionTitle('Education', _BlueDiagonalIcon.education),
                    for (final item in education)
                      ...timelineEntry(
                        dates: educationDateRangeLabel(
                          item.startDate,
                          item.endDate,
                        ),
                        title: item.institution.trim().ifEmpty('Institution'),
                        subtitle: item.degree.trim(),
                        details: [
                          if (item.score.trim().isNotEmpty)
                            pw.Text(item.score.trim(), style: bodyStyle),
                        ],
                      ),
                  ];
                case ResumeBuilderSectionIds.work:
                  if (experiences.isEmpty) return null;
                  return [
                    sectionTitle('Experience', _BlueDiagonalIcon.work),
                    for (var i = 0; i < experiences.length; i++)
                      ...timelineEntry(
                        dates: educationDateRangeLabel(
                          experiences[i].startDate,
                          experiences[i].endDate,
                        ),
                        title: experiences[i].role.trim().ifEmpty('Role'),
                        subtitle: experiences[i].company.trim(),
                        details: [
                          for (final line in _workBulletLines(experiences[i]))
                            bullet(
                              line,
                              highlight:
                                  highlightedBulletsByExperience[i]?.contains(
                                    line,
                                  ) ??
                                  false,
                            ),
                        ],
                      ),
                  ];
                case ResumeBuilderSectionIds.projects:
                  if (projects.isEmpty) return null;
                  return [
                    sectionTitle('Projects', _BlueDiagonalIcon.article),
                    for (final item in projects)
                      ...timelineEntry(
                        dates: '',
                        title: item.title.trim().ifEmpty('Project'),
                        subtitle: item.subtitle.trim(),
                        details: [
                          for (final line in _projectBulletLinesPdf(item))
                            bullet(line),
                        ],
                      ),
                  ];
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

/// Diagonal colour blocks: two bands across the top corners and one along the
/// bottom edge, as in the reference art.
void _paintBlueDiagonals(
  PdfGraphics canvas,
  PdfPoint size, {
  required PdfColor accent,
  required PdfColor accentDark,
  required bool drawTop,
}) {
  void polygon(List<List<double>> points, PdfColor color) {
    canvas.setFillColor(color);
    canvas.moveTo(points.first[0], points.first[1]);
    for (final point in points.skip(1)) {
      canvas.lineTo(point[0], point[1]);
    }
    canvas.closePath();
    canvas.fillPath();
  }

  final w = size.x;
  final h = size.y;
  if (drawTop) {
    // Top-left wedge over the grey column.
    polygon(
      [
        [0, h],
        [_blueDiagonalColumnWidthPt, h],
        [0, h - 150],
      ],
      accent,
    );
    // Top-right diagonal bands.
    polygon(
      [
        [w - 185, h],
        [w, h],
        [w, h - 185],
      ],
      accent,
    );
    polygon(
      [
        [w - 185, h],
        [w - 125, h],
        [w, h - 125],
        [w, h - 185],
      ],
      accentDark,
    );
  }
  // Bottom band.
  polygon(
    [
      [0, 0],
      [w, 0],
      [w, 62],
      [0, 26],
    ],
    accent,
  );
  polygon(
    [
      [0, 0],
      [w, 0],
      [w, 26],
      [0, 8],
    ],
    accentDark,
  );
}

/// Section and contact glyphs, drawn as simple shapes so no icon font is
/// needed in the PDF.
enum _BlueDiagonalIcon {
  person,
  contact,
  skills,
  language,
  education,
  work,
  article,
  phone,
  mail,
  place,
  link,
}

void _paintBlueDiagonalIcon(
  PdfGraphics canvas,
  PdfPoint size,
  _BlueDiagonalIcon kind,
  PdfColor color,
) {
  final w = size.x;
  final h = size.y;
  canvas.setFillColor(color);
  canvas.setStrokeColor(color);
  canvas.setLineWidth(w * 0.09);

  void circle(double cx, double cy, double r, {bool fill = true}) {
    canvas.drawEllipse(cx, cy, r, r);
    fill ? canvas.fillPath() : canvas.strokePath();
  }

  void rect(double x, double y, double rw, double rh, {bool fill = true}) {
    canvas.drawRect(x, y, rw, rh);
    fill ? canvas.fillPath() : canvas.strokePath();
  }

  void polygon(List<List<double>> points) {
    canvas.moveTo(points.first[0], points.first[1]);
    for (final point in points.skip(1)) {
      canvas.lineTo(point[0], point[1]);
    }
    canvas.closePath();
    canvas.fillPath();
  }

  switch (kind) {
    case _BlueDiagonalIcon.person:
      circle(w * 0.5, h * 0.72, w * 0.20);
      polygon([
        [w * 0.16, h * 0.10],
        [w * 0.84, h * 0.10],
        [w * 0.72, h * 0.44],
        [w * 0.28, h * 0.44],
      ]);
    case _BlueDiagonalIcon.contact:
      rect(w * 0.10, h * 0.18, w * 0.80, h * 0.64, fill: false);
      circle(w * 0.36, h * 0.58, w * 0.11);
      rect(w * 0.56, h * 0.56, w * 0.26, h * 0.07);
      rect(w * 0.56, h * 0.38, w * 0.26, h * 0.07);
    case _BlueDiagonalIcon.skills:
      circle(w * 0.5, h * 0.5, w * 0.34, fill: false);
      circle(w * 0.5, h * 0.5, w * 0.12);
    case _BlueDiagonalIcon.language:
      circle(w * 0.5, h * 0.5, w * 0.36, fill: false);
      canvas
        ..drawEllipse(w * 0.5, h * 0.5, w * 0.15, h * 0.36)
        ..strokePath();
      canvas
        ..moveTo(w * 0.14, h * 0.5)
        ..lineTo(w * 0.86, h * 0.5)
        ..strokePath();
    case _BlueDiagonalIcon.education:
      polygon([
        [w * 0.5, h * 0.82],
        [w * 0.92, h * 0.58],
        [w * 0.5, h * 0.34],
        [w * 0.08, h * 0.58],
      ]);
      rect(w * 0.26, h * 0.20, w * 0.48, h * 0.22, fill: false);
    case _BlueDiagonalIcon.work:
      rect(w * 0.10, h * 0.20, w * 0.80, h * 0.48);
      rect(w * 0.36, h * 0.68, w * 0.28, h * 0.14, fill: false);
    case _BlueDiagonalIcon.article:
      rect(w * 0.16, h * 0.14, w * 0.68, h * 0.72, fill: false);
      rect(w * 0.28, h * 0.60, w * 0.44, h * 0.07);
      rect(w * 0.28, h * 0.44, w * 0.44, h * 0.07);
    case _BlueDiagonalIcon.phone:
      rect(w * 0.28, h * 0.10, w * 0.44, h * 0.80, fill: false);
      rect(w * 0.42, h * 0.16, w * 0.16, h * 0.06);
    case _BlueDiagonalIcon.mail:
      rect(w * 0.10, h * 0.26, w * 0.80, h * 0.48, fill: false);
      canvas
        ..moveTo(w * 0.10, h * 0.74)
        ..lineTo(w * 0.5, h * 0.44)
        ..lineTo(w * 0.90, h * 0.74)
        ..strokePath();
    case _BlueDiagonalIcon.place:
      circle(w * 0.5, h * 0.62, w * 0.26);
      polygon([
        [w * 0.5, h * 0.10],
        [w * 0.30, h * 0.58],
        [w * 0.70, h * 0.58],
      ]);
    case _BlueDiagonalIcon.link:
      canvas
        ..drawEllipse(w * 0.34, h * 0.5, w * 0.22, h * 0.16)
        ..strokePath();
      canvas
        ..drawEllipse(w * 0.66, h * 0.5, w * 0.22, h * 0.16)
        ..strokePath();
  }
}
