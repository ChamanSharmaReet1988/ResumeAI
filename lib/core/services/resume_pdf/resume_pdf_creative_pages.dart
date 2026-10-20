part of 'package:resume_app/core/services/resume_services.dart';

/// Creative templates: painted page backgrounds with a single-column body.
extension _ResumePdfCreativePages on ResumePdfService {
  void _addPaintedCreativeTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final kind = resume.template.userFacingTemplate;
    final ink = PdfColor.fromInt(0xFF241C18);
    final muted = PdfColor.fromInt(0xFF6B625C);
    final accent = _pdfRgb(resume.creativeAccentColor);
    final highlight = _pdfRgb(resume.paintedCreativeHighlightColor);
    final lightBand = resume.corporateColorPreset.usesLightHeader;
    final bandInk = _pdfRgb(resume.corporateColorPreset.titleColor);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();

    pw.TextStyle style(
      int weight,
      double size,
      PdfColor color, {
      double? lineSpacing,
      double letterSpacing = 0,
    }) => garamondPdfTextStyle(
      fonts,
      weight,
      fontSize: size,
      color: color,
      lineSpacing: lineSpacing,
    ).copyWith(letterSpacing: letterSpacing);

    final bodyStyle = style(
      ResumeFontWeight.w400,
      bodyPt,
      ink,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
    );
    final metaStyle = style(ResumeFontWeight.w400, bodyPt - 0.5, muted);
    final strongStyle = style(ResumeFontWeight.w700, bodyPt + 0.5, ink);
    final onBand = kind == ResumeTemplate.sunset || kind == ResumeTemplate.studio;

    pw.Widget sectionTitle(String heading) {
      final label = switch (kind) {
        ResumeTemplate.inkPanel || ResumeTemplate.studio => heading.toUpperCase(),
        _ => heading,
      };
      final title = pw.Text(
        label,
        style: style(
          ResumeFontWeight.w700,
          kind == ResumeTemplate.sageFrame ? 13 : 12.5,
          accent,
          letterSpacing: kind == ResumeTemplate.inkPanel ? 1.4 : 0.2,
        ),
      );
      final rule = pw.Container(height: 1, color: accent);
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: switch (kind) {
          ResumeTemplate.aurora => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              title,
              pw.SizedBox(height: 3),
              pw.Container(width: 36, height: 3, color: accent),
            ],
          ),
          ResumeTemplate.sageFrame => pw.Row(
            children: [
              pw.Expanded(child: rule),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                child: title,
              ),
              pw.Expanded(child: rule),
            ],
          ),
          ResumeTemplate.studio => pw.Row(
            children: [
              pw.Container(width: 8, height: 8, color: highlight),
              pw.SizedBox(width: 8),
              title,
            ],
          ),
          ResumeTemplate.arc => pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: accent,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              title,
            ],
          ),
          _ => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              title,
              pw.SizedBox(height: 3),
              rule,
            ],
          ),
        },
      );
    }

    pw.Widget bullet(String text, {bool highlight = false}) =>
        _headerSidebarMaybeHighlight(
          highlight: highlight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('•  ', style: bodyStyle),
                pw.Expanded(child: pw.Text(text, style: bodyStyle)),
              ],
            ),
          ),
        );

    List<pw.Widget> entry({
      required String title,
      required String subtitle,
      required String dates,
      required List<String> lines,
      Set<String> highlighted = const {},
    }) {
      return [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: pw.Text(title, style: strongStyle)),
            if (dates.isNotEmpty) pw.Text(dates, style: metaStyle),
          ],
        ),
        if (subtitle.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(subtitle, style: metaStyle),
          ),
        for (final line in lines.where((line) => line.trim().isNotEmpty))
          bullet(line.trim(), highlight: highlighted.contains(line.trim())),
        pw.SizedBox(height: 8),
      ];
    }

    final contact = [
      resume.email,
      resume.phone,
      resume.location,
      resume.website,
      resume.linkedinLink,
      resume.githubLink,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).join('  ·  ');
    final name = _displayName(resume);
    final nameStyle = style(
      ResumeFontWeight.w700,
      kind == ResumeTemplate.aurora ? 26 : 24,
      onBand ? (lightBand ? bandInk : PdfColors.white) : ink,
      letterSpacing: kind == ResumeTemplate.inkPanel ? 1.1 : 0,
    );
    final titleStyle = style(
      ResumeFontWeight.w400,
      12.5,
      onBand ? (lightBand ? bandInk : PdfColor.fromInt(0xFFFFF1E6)) : accent,
    );
    final contactStyle = style(
      ResumeFontWeight.w400,
      10,
      kind == ResumeTemplate.chevron
          ? accent
          : onBand
          ? (lightBand ? bandInk : PdfColor.fromInt(0xFFFFF6F0))
          : muted,
    );
    final headerColumn = pw.Column(
      crossAxisAlignment: kind == ResumeTemplate.sageFrame
          ? pw.CrossAxisAlignment.stretch
          : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          kind == ResumeTemplate.inkPanel ? name.toUpperCase() : name,
          textAlign: kind == ResumeTemplate.sageFrame
              ? pw.TextAlign.center
              : pw.TextAlign.left,
          style: nameStyle,
        ),
        if (resume.jobTitle.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            resume.jobTitle.trim(),
            textAlign: kind == ResumeTemplate.sageFrame
                ? pw.TextAlign.center
                : pw.TextAlign.left,
            style: titleStyle,
          ),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            contact,
            textAlign: kind == ResumeTemplate.sageFrame
                ? pw.TextAlign.center
                : pw.TextAlign.left,
            style: contactStyle,
          ),
        ],
      ],
    );
    final header = switch (kind) {
      ResumeTemplate.sunset => pw.Container(
        color: accent,
        padding: const pw.EdgeInsets.fromLTRB(40, 28, 40, 18),
        child: headerColumn,
      ),
      ResumeTemplate.studio => pw.Container(
        color: accent,
        padding: const pw.EdgeInsets.fromLTRB(40, 26, 40, 18),
        child: pw.Stack(
          children: [
            pw.Positioned(
              right: 0,
              top: 0,
              child: pw.Container(
                width: 22,
                height: 22,
                color: highlight,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 36),
              child: headerColumn,
            ),
          ],
        ),
      ),
      _ => headerColumn,
    };

    final margin = switch (kind) {
      ResumeTemplate.sunset || ResumeTemplate.studio => pw.EdgeInsets.zero,
      ResumeTemplate.inkPanel => const pw.EdgeInsets.fromLTRB(36, 28, 36, 32),
      ResumeTemplate.sageFrame => const pw.EdgeInsets.fromLTRB(32, 28, 32, 32),
      ResumeTemplate.arc => const pw.EdgeInsets.fromLTRB(40, 28, 64, 40),
      ResumeTemplate.chevron ||
      ResumeTemplate.wave => const pw.EdgeInsets.fromLTRB(40, 32, 40, 36),
      _ => const pw.EdgeInsets.fromLTRB(40, 28, 40, 32),
    };
    final bodyPad = kind == ResumeTemplate.sunset || kind == ResumeTemplate.studio
        ? const pw.EdgeInsets.fromLTRB(40, 16, 40, 48)
        : const pw.EdgeInsets.only(top: 12);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: margin,
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _creativePdfBackground(kind, accent: accent, highlight: highlight),
          ),
        ),
        build: (context) => [
          header,
          pw.Padding(
            padding: bodyPad,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (resume.summary.trim().isNotEmpty)
                  _headerSidebarMaybeHighlight(
                    highlight: highlightSummary,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(resume.summary.trim(), style: bodyStyle),
                    ),
                  ),
                ..._pdfBodySectionsInBuilderOrder(
                  resume,
                  buildSection: (id) {
                    switch (id) {
                      case ResumeBuilderSectionIds.work:
                        final items = resume.visibleWorkExperiences;
                        if (items.isEmpty) return null;
                        return [
                          sectionTitle(resume.sectionHeading(id, 'Work Experience')),
                          for (var index = 0; index < items.length; index++)
                            ...entry(
                              title: items[index].role.trim(),
                              subtitle: items[index].company.trim(),
                              dates: educationDateRangeLabel(
                                items[index].startDate,
                                items[index].endDate,
                              ),
                              lines: [
                                if (items[index].description.trim().isNotEmpty)
                                  items[index].description.trim(),
                                ...items[index].bullets,
                              ],
                              highlighted:
                                  highlightedBulletsByExperience[index] ??
                                  const {},
                            ),
                        ];
                      case ResumeBuilderSectionIds.education:
                        final items = resume.visibleEducation;
                        if (items.isEmpty) return null;
                        return [
                          sectionTitle(resume.sectionHeading(id, 'Education')),
                          for (final item in items)
                            ...entry(
                              title: item.degree.trim(),
                              subtitle: item.institution.trim(),
                              dates: educationDateRangeLabel(
                                item.startDate,
                                item.endDate,
                              ),
                              lines: [educationDetailLine(item)],
                            ),
                        ];
                      case ResumeBuilderSectionIds.skills:
                        if (!resume.includeSkillsInResume) return null;
                        final grouped = resume.showCategorisedSkills;
                        final flat = resume.skillsForResume;
                        if (!grouped && flat.isEmpty) return null;
                        return [
                          sectionTitle(resume.sectionHeading(id, 'Skills')),
                          if (grouped)
                            for (final group in resume.skillGroupsForResume) ...[
                              if (group.heading.trim().isNotEmpty)
                                pw.Text(group.heading.trim(), style: strongStyle),
                              for (final skill in group.skills.where(
                                (skill) => skill.trim().isNotEmpty,
                              ))
                                bullet(
                                  skill.trim(),
                                  highlight: highlightedSkills.contains(skill.trim()),
                                ),
                            ]
                          else
                            for (final skill in flat)
                              bullet(
                                skill,
                                highlight: highlightedSkills.contains(skill),
                              ),
                        ];
                      case ResumeBuilderSectionIds.projects:
                        final items = resume.visibleProjects;
                        if (items.isEmpty) return null;
                        return [
                          sectionTitle(resume.sectionHeading(id, 'Projects')),
                          for (final item in items)
                            ...entry(
                              title: item.title.trim(),
                              subtitle: [
                                item.subtitle,
                                item.overview,
                                item.impact,
                              ].map((line) => line.trim()).where((line) => line.isNotEmpty).join(' · '),
                              dates: '',
                              lines: item.bullets,
                            ),
                        ];
                      default:
                        final index = ResumeBuilderSectionIds.customIndex(id);
                        if (index == null ||
                            index < 0 ||
                            index >= resume.customSections.length) {
                          return null;
                        }
                        final item = resume.customSections[index];
                        if (item.isBlank) return null;
                        return [
                          sectionTitle(
                            item.title.trim().isEmpty ? 'Section' : item.title.trim(),
                          ),
                          if (customSectionMetaLine(item).isNotEmpty)
                            pw.Text(customSectionMetaLine(item), style: metaStyle),
                          if (item.usesItemEntries)
                            for (final entryItem in item.visibleEntries)
                              ...entry(
                                title: entryItem.name.trim(),
                                subtitle: entryItem.company.trim(),
                                dates: entryItem.period.trim().isNotEmpty
                                    ? entryItem.period.trim()
                                    : educationDateRangeLabel(
                                        entryItem.startDate,
                                        entryItem.endDate,
                                      ),
                                lines: [entryItem.summary],
                              )
                          else ...[
                            if (item.content.trim().isNotEmpty)
                              pw.Text(item.content.trim(), style: bodyStyle),
                            for (final line in item.bullets.where(
                              (line) => line.trim().isNotEmpty,
                            ))
                              bullet(line.trim()),
                          ],
                        ];
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

pw.Widget _creativePdfBackground(
  ResumeTemplate kind, {
  required PdfColor accent,
  required PdfColor highlight,
}) {
  pw.Widget blob(double size, PdfColor color) => pw.Container(
    width: size,
    height: size,
    decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
  );

  return switch (kind) {
    ResumeTemplate.aurora => pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Container(color: PdfColor.fromInt(0xFFFFF4EC)),
        ),
        pw.Positioned(right: -160, top: -170, child: blob(200, PdfColor.fromInt(0xFFF6C7A4))),
        pw.Positioned(left: -140, bottom: -50, child: blob(180, PdfColor.fromInt(0xFFE5D4F8))),
        pw.Positioned(right: -16, bottom: -8, child: blob(52, PdfColor.fromInt(0xFFF3D2BE))),
      ],
    ),
    ResumeTemplate.inkPanel => pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Container(color: PdfColor.fromInt(0xFFF7F1E8)),
        ),
        pw.Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: pw.Container(width: 16, color: accent),
        ),
        pw.Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: pw.Container(height: 8, color: accent),
        ),
        pw.Positioned(right: -70, bottom: -30, child: blob(110, PdfColor.fromInt(0xFFE7D3C4))),
      ],
    ),
    ResumeTemplate.sunset => pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Container(color: PdfColor.fromInt(0xFFFFF8F4)),
        ),
        pw.Positioned(right: -36, top: 168, child: blob(72, PdfColor.fromInt(0xFFF6D3B0))),
        pw.Positioned(left: -40, bottom: -16, child: blob(80, PdfColor.fromInt(0xFFF8CDB8))),
      ],
    ),
    ResumeTemplate.sageFrame => pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Container(color: PdfColor.fromInt(0xFFE6EFE4)),
        ),
        pw.Positioned.fill(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(
                  color: accent,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
        pw.Positioned.fill(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(18),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: accent,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    ResumeTemplate.studio => pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Container(color: PdfColor.fromInt(0xFFF7F4EF)),
        ),
        pw.Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: pw.Container(height: 22, color: accent),
        ),
        pw.Positioned(left: 16, bottom: 30, child: blob(22, highlight)),
      ],
    ),
    ResumeTemplate.chevron => pw.CustomPaint(
      size: const PdfPoint(595.28, 841.89),
      painter: _paintChevronPage,
    ),
    ResumeTemplate.wave => pw.CustomPaint(
      size: const PdfPoint(595.28, 841.89),
      painter: _paintWavePage,
    ),
    ResumeTemplate.arc => pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Container(color: PdfColor.fromInt(0xFFF4FBFA)),
        ),
        pw.Positioned(right: -130, top: -130, child: blob(180, accent)),
        pw.Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: pw.Container(height: 18, color: accent),
        ),
        pw.Positioned(left: 18, bottom: 28, child: blob(22, PdfColor.fromInt(0xFFB7E0DC))),
      ],
    ),
    _ => pw.Container(color: PdfColors.white),
  };
}

void _paintChevronPage(PdfGraphics canvas, PdfPoint size) {
  const band = 250.0;
  const span = 340.0;
  canvas
    ..setFillColor(PdfColors.white)
    ..drawRect(0, 0, size.x, size.y)
    ..fillPath()
    ..setFillColor(PdfColor.fromInt(0xFFF7FBF9))
    ..moveTo(size.x, size.y)
    ..lineTo(size.x - span, size.y)
    ..lineTo(size.x, size.y - band)
    ..closePath()
    ..fillPath()
    ..saveContext()
    ..moveTo(size.x, size.y)
    ..lineTo(size.x - span, size.y)
    ..lineTo(size.x, size.y - band)
    ..closePath()
    ..clipPath()
    ..setStrokeColor(PdfColor.fromInt(0xFFC5D2CC))
    ..setLineWidth(1.15);
  const pitch = 36.0;
  const row = 22.0;
  const depth = 10.0;
  final top = size.y - band;
  for (var r = 0;; r++) {
    final y0 = top + depth + r * row;
    if (y0 > size.y - depth) break;
    canvas.moveTo(size.x - span - pitch, y0);
    var x = size.x - span - pitch;
    var up = r.isEven;
    while (x < size.x + pitch) {
      final next = x + pitch / 2;
      canvas.lineTo(next, y0 + (up ? depth : -depth));
      up = !up;
      x = next;
    }
    canvas.strokePath();
  }
  canvas.restoreContext();
}

void _paintWavePage(PdfGraphics canvas, PdfPoint size) {
  const band = 250.0;
  final base = size.y - band;
  canvas
    ..setFillColor(PdfColors.white)
    ..drawRect(0, 0, size.x, size.y)
    ..fillPath()
    ..setFillColor(PdfColor.fromInt(0xFFD7E7F6))
    ..drawRect(0, base, size.x, band)
    ..fillPath()
    ..setStrokeColor(PdfColors.white)
    ..setLineWidth(1.5);
  void curve(double y, double amp) {
    canvas
      ..moveTo(-12, y)
      ..curveTo(
        size.x * 0.28,
        y + amp,
        size.x * 0.62,
        y - amp,
        size.x + 12,
        y + amp * 0.35,
      )
      ..strokePath();
  }

  curve(size.y - 48, 18);
  curve(size.y - 96, 12);
  canvas
    ..setFillColor(PdfColors.white)
    ..moveTo(0, base)
    ..lineTo(0, base + 78)
    ..curveTo(
      size.x * 0.24,
      base + 130,
      size.x * 0.58,
      base + 18,
      size.x,
      base + 88,
    )
    ..lineTo(size.x, base)
    ..closePath()
    ..fillPath();
}
