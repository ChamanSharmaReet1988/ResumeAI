part of 'package:resume_app/core/services/resume_services.dart';

/// Minimal Profile: circular photo header, about me, dated education and
/// experience rows, a four-column skills grid, and two-column references.
const double _minimalProfileHorizontalPt = 40.0;
const double _minimalProfileTopPt = 36.0;
const double _minimalProfileBottomPt = 32.0;
const double _minimalProfileAvatarPt = 72.0;
const double _minimalProfileMetaColumnPt = 128.0;

extension _ResumePdfMinimalProfilePage on ResumePdfService {
  void _addMinimalProfileTemplatePage(
    pw.Document document,
    ResumeData resume, {
    required GaramondPdfFonts fonts,
    pw.MemoryImage? profileImage,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) {
    final titleColor = _pdfRgb(resume.minimalProfileTitleColor);
    final mutedColor = _pdfRgb(resume.minimalProfileMutedColor);
    final accent = _pdfRgb(resume.minimalProfileAccentColor);
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final textPt = bodyPt - 0.5;

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

    final nameStyle = style(ResumeFontWeight.w800, 26, titleColor);
    final jobStyle = style(ResumeFontWeight.w400, 13, mutedColor);
    final contactStyle = style(ResumeFontWeight.w400, textPt, mutedColor);
    final sectionStyle = style(ResumeFontWeight.w800, 13.5, titleColor);
    final entryTitleStyle = style(ResumeFontWeight.w700, bodyPt, titleColor);
    final bodyStyle = style(
      ResumeFontWeight.w400,
      textPt,
      mutedColor,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(textPt),
    );

    pw.Widget contactIcon(_MinimalProfileIcon kind) => pw.SizedBox(
      width: 10,
      height: 10,
      child: pw.CustomPaint(
        painter: (canvas, size) =>
            _paintMinimalProfileIcon(canvas, size, kind, mutedColor),
      ),
    );

    pw.Widget contactChip(_MinimalProfileIcon kind, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(right: 14, bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          contactIcon(kind),
          pw.SizedBox(width: 5),
          pw.Text(value, style: contactStyle),
        ],
      ),
    );

    pw.Widget sectionHeading(String label, {bool showRule = true}) {
      final heading = pw.Text(label.toUpperCase(), style: sectionStyle);
      if (!showRule) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
          child: heading,
        );
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            heading,
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(height: 1, color: titleColor),
            ),
          ],
        ),
      );
    }

    pw.Widget datedEntry({
      required String dates,
      required String organisation,
      required String title,
      String detail = '',
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 14),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: _minimalProfileMetaColumnPt,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (dates.isNotEmpty) pw.Text(dates, style: bodyStyle),
                  if (organisation.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(organisation, style: bodyStyle),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 22),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: entryTitleStyle),
                  if (detail.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(detail, style: bodyStyle),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget skillsGrid(List<String> skills) {
      final rows = <pw.Widget>[];
      for (var row = 0; row < (skills.length / 4).ceil(); row++) {
        rows.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < 4; col++)
                  pw.Expanded(
                    child: col + row * 4 < skills.length
                        ? _headerSidebarMaybeHighlight(
                            highlight: highlightedSkills.contains(
                              skills[row * 4 + col],
                            ),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('•  ', style: bodyStyle),
                                pw.Expanded(
                                  child: pw.Text(
                                    skills[row * 4 + col],
                                    style: bodyStyle,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : pw.SizedBox(),
                  ),
              ],
            ),
          ),
        );
      }
      return pw.Column(children: rows);
    }

    pw.Widget referenceColumn(_MinimalProfileReferencePdf ref) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(ref.name, style: entryTitleStyle),
          if (ref.role.isNotEmpty) pw.Text(ref.role, style: bodyStyle),
          if (ref.phone.isNotEmpty)
            pw.Text('Phone  ${ref.phone}', style: bodyStyle),
          if (ref.social.isNotEmpty)
            pw.Text('Social  ${ref.social}', style: bodyStyle),
        ],
      );
    }

    List<pw.Widget>? buildSection(String id) {
      if (id == ResumeBuilderSectionIds.education) {
        final items = resume.visibleEducation;
        if (items.isEmpty) return null;
        return [
          sectionHeading('Education'),
          for (final item in items)
            datedEntry(
              dates: educationDateRangeLabel(item.startDate, item.endDate),
              organisation: item.institution.trim(),
              title: item.degree.trim().isEmpty ? 'Degree' : item.degree.trim(),
              detail: educationScoreDisplayLabel(item),
            ),
        ];
      }
      if (id == ResumeBuilderSectionIds.work) {
        final items = resume.visibleWorkExperiences;
        if (items.isEmpty) return null;
        return [
          sectionHeading('Experience'),
          for (var i = 0; i < items.length; i++)
            _headerSidebarMaybeHighlight(
              highlight:
                  highlightedBulletsByExperience[i]?.isNotEmpty ?? false,
              child: datedEntry(
                dates: educationDateRangeLabel(
                  items[i].startDate,
                  items[i].endDate,
                ),
                organisation: items[i].company.trim(),
                title: items[i].role.trim().isEmpty
                    ? 'Role'
                    : items[i].role.trim(),
                detail: _minimalProfilePdfEntryDetail(
                  items[i].description,
                  items[i].bullets,
                ),
              ),
            ),
        ];
      }
      if (id == ResumeBuilderSectionIds.skills) {
        final skills = resume.skillsLinesForDisplay;
        if (skills.isEmpty) return null;
        return [sectionHeading('Skills'), skillsGrid(skills)];
      }
      if (id == ResumeBuilderSectionIds.projects) {
        final items = resume.visibleProjects;
        if (items.isEmpty) return null;
        return [
          sectionHeading('Projects'),
          for (final item in items)
            datedEntry(
              dates: item.subtitle.trim(),
              organisation: '',
              title: item.title.trim().isEmpty ? 'Project' : item.title.trim(),
              detail: _minimalProfilePdfEntryDetail(
                [item.overview, item.impact]
                    .where((value) => value.trim().isNotEmpty)
                    .join(' '),
                item.bullets,
              ),
            ),
        ];
      }
      final customIndex = ResumeBuilderSectionIds.customIndex(id);
      if (customIndex == null ||
          customIndex < 0 ||
          customIndex >= resume.customSections.length) {
        return null;
      }
      final section = resume.customSections[customIndex];
      if (section.isBlank) return null;
      final title = section.title.trim().isEmpty ? 'Section' : section.title.trim();
      if (_isMinimalProfileReferencesTitle(title)) {
        final refs = _minimalProfilePdfReferences(section);
        if (refs.isEmpty) return null;
        final rows = <pw.Widget>[sectionHeading(title)];
        for (var i = 0; i < refs.length; i += 2) {
          rows.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: referenceColumn(refs[i])),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    child: i + 1 < refs.length
                        ? referenceColumn(refs[i + 1])
                        : pw.SizedBox(),
                  ),
                ],
              ),
            ),
          );
        }
        return rows;
      }
      final lines = section.layoutMode == CustomSectionLayoutMode.bullets
          ? section.bullets
          : section.content.split('\n');
      return [
        sectionHeading(title),
        for (final line in lines.map((item) => item.trim()).where((item) => item.isNotEmpty))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(line, style: bodyStyle),
          ),
      ];
    }

    final contacts = <pw.Widget>[
      if (resume.phone.trim().isNotEmpty)
        contactChip(_MinimalProfileIcon.phone, resume.phone.trim()),
      if (resume.email.trim().isNotEmpty)
        contactChip(_MinimalProfileIcon.mail, resume.email.trim()),
      if (resume.website.trim().isNotEmpty)
        contactChip(_MinimalProfileIcon.web, resume.website.trim()),
      if (resume.location.trim().isNotEmpty)
        contactChip(_MinimalProfileIcon.place, resume.location.trim()),
    ];

    final summary = resume.summary.trim();
    final order = resume.isGallerySample
        ? [
            ResumeBuilderSectionIds.education,
            ResumeBuilderSectionIds.work,
            ResumeBuilderSectionIds.skills,
            ResumeBuilderSectionIds.projects,
            for (var i = 0; i < resume.customSections.length; i++)
              ResumeBuilderSectionIds.custom(i),
          ]
        : resume.effectiveBuilderSectionOrder;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          _minimalProfileHorizontalPt,
          _minimalProfileTopPt,
          _minimalProfileHorizontalPt,
          _minimalProfileBottomPt,
        ),
        build: (context) {
          final body = <pw.Widget>[];
          for (final id in order) {
            final widgets = buildSection(id);
            if (widgets != null) body.addAll(widgets);
          }
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(
                  width: _minimalProfileAvatarPt,
                  height: _minimalProfileAvatarPt,
                  child: profileImage != null
                      ? pw.ClipOval(
                          child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                        )
                      : pw.Container(
                          alignment: pw.Alignment.center,
                          decoration: const pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFE8E8E8),
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Text(
                            _resumeInitials(resume),
                            style: style(ResumeFontWeight.w700, 20, accent),
                          ),
                        ),
                ),
                pw.SizedBox(width: 22),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_displayName(resume).toUpperCase(), style: nameStyle),
                      if (resume.jobTitle.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(resume.jobTitle.trim(), style: jobStyle),
                      ],
                      if (contacts.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Wrap(children: contacts),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (summary.isNotEmpty) ...[
              sectionHeading('About me', showRule: false),
              _headerSidebarMaybeHighlight(
                highlight: highlightSummary,
                child: pw.Text(summary, style: bodyStyle),
              ),
            ],
            ...body,
          ];
        },
      ),
    );
  }
}

enum _MinimalProfileIcon { phone, mail, web, place }

void _paintMinimalProfileIcon(
  PdfGraphics canvas,
  PdfPoint size,
  _MinimalProfileIcon kind,
  PdfColor color,
) {
  final w = size.x;
  final h = size.y;
  canvas
    ..setStrokeColor(color)
    ..setFillColor(color)
    ..setLineWidth(w * 0.1);

  switch (kind) {
    case _MinimalProfileIcon.phone:
      canvas
        ..drawRect(w * 0.30, h * 0.08, w * 0.40, h * 0.84)
        ..strokePath();
      canvas
        ..drawRect(w * 0.42, h * 0.14, w * 0.16, h * 0.06)
        ..fillPath();
    case _MinimalProfileIcon.mail:
      canvas
        ..drawRect(w * 0.08, h * 0.24, w * 0.84, h * 0.52)
        ..strokePath();
      canvas
        ..moveTo(w * 0.08, h * 0.76)
        ..lineTo(w * 0.5, h * 0.42)
        ..lineTo(w * 0.92, h * 0.76)
        ..strokePath();
    case _MinimalProfileIcon.web:
      canvas
        ..drawEllipse(w * 0.5, h * 0.5, w * 0.38, h * 0.38)
        ..strokePath();
      canvas
        ..drawEllipse(w * 0.5, h * 0.5, w * 0.16, h * 0.38)
        ..strokePath();
      canvas
        ..moveTo(w * 0.12, h * 0.5)
        ..lineTo(w * 0.88, h * 0.5)
        ..strokePath();
    case _MinimalProfileIcon.place:
      canvas
        ..drawEllipse(w * 0.5, h * 0.62, w * 0.22, h * 0.22)
        ..fillPath();
      canvas
        ..moveTo(w * 0.5, h * 0.10)
        ..lineTo(w * 0.28, h * 0.58)
        ..lineTo(w * 0.72, h * 0.58)
        ..closePath()
        ..fillPath();
  }
}

class _MinimalProfileReferencePdf {
  const _MinimalProfileReferencePdf({
    required this.name,
    this.role = '',
    this.phone = '',
    this.social = '',
  });

  final String name;
  final String role;
  final String phone;
  final String social;
}

bool _isMinimalProfileReferencesTitle(String title) {
  final normalized = title.trim().toLowerCase();
  return normalized == 'references' ||
      normalized == 'referees' ||
      normalized == 'reference';
}

List<_MinimalProfileReferencePdf> _minimalProfilePdfReferences(
  CustomSectionItem section,
) {
  final raw = section.layoutMode == CustomSectionLayoutMode.bullets
      ? section.bullets
      : section.content.split(RegExp(r'\n\s*\n'));
  return raw
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) {
        final parts = line
            .split('|')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
        if (parts.isEmpty) return null;
        return _MinimalProfileReferencePdf(
          name: parts[0],
          role: parts.length > 1 ? parts[1] : '',
          phone: parts.length > 2 ? parts[2] : '',
          social: parts.length > 3 ? parts[3] : '',
        );
      })
      .whereType<_MinimalProfileReferencePdf>()
      .toList();
}

String _minimalProfilePdfEntryDetail(String description, List<String> bullets) {
  final text = description.trim();
  if (text.isNotEmpty) return text;
  return bullets.map((item) => item.trim()).where((item) => item.isNotEmpty).join(' ');
}
