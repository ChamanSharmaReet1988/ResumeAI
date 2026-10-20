import 'package:flutter/material.dart';

import '../../core/corporate_resume_style.dart';
import '../../core/models/resume_builder_section_order.dart';
import '../../core/models/resume_models.dart';

/// On-screen page for the six Creative resume templates. Page paint sits
/// behind a single-column body so the layout stays readable.
class CreativeResumePreview extends StatelessWidget {
  const CreativeResumePreview({
    super.key,
    required this.resume,
    this.followBuilderSectionOrder = false,
  });

  final ResumeData resume;
  final bool followBuilderSectionOrder;

  static const double _pageWidth = 595.28;
  static const double _pageHeight = 841.89;

  @override
  Widget build(BuildContext context) {
    final kind = resume.template.userFacingTemplate;
    final ink = const Color(0xFF241C18);
    final muted = const Color(0xFF6B625C);
    final accent = resume.creativeAccentColor;
    final highlight = resume.paintedCreativeHighlightColor;
    final lightBand = resume.corporateColorPreset.usesLightHeader;

    TextStyle style(
      FontWeight weight,
      double size, {
      Color color = const Color(0xFF241C18),
      double letterSpacing = 0,
      double height = 1.35,
    }) => TextStyle(
      fontFamily: 'Garamond',
      fontWeight: weight,
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

    final body = style(FontWeight.w400, 11.5, color: ink);
    final meta = style(FontWeight.w400, 11, color: muted);

    Widget sectionTitle(String heading) {
      final label = switch (kind) {
        ResumeTemplate.inkPanel || ResumeTemplate.studio => heading.toUpperCase(),
        _ => heading,
      };
      final title = Text(
        label,
        style: style(
          FontWeight.w700,
          kind == ResumeTemplate.sageFrame ? 13 : 12.5,
          color: accent,
          letterSpacing: kind == ResumeTemplate.inkPanel ? 1.4 : 0.2,
        ),
      );
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: switch (kind) {
          ResumeTemplate.aurora => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 4),
              Container(width: 36, height: 3, color: accent),
            ],
          ),
          ResumeTemplate.sageFrame => Row(
            children: [
              Expanded(child: Container(height: 0.8, color: accent.withValues(alpha: 0.45))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: title,
              ),
              Expanded(child: Container(height: 0.8, color: accent.withValues(alpha: 0.45))),
            ],
          ),
          ResumeTemplate.studio => Row(
            children: [
              Container(width: 8, height: 8, color: highlight),
              const SizedBox(width: 8),
              title,
            ],
          ),
          ResumeTemplate.arc => Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              title,
            ],
          ),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 3),
              Container(height: 1, color: accent.withValues(alpha: 0.85)),
            ],
          ),
        },
      );
    }

    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: body),
          Expanded(child: Text(text, style: body)),
        ],
      ),
    );

    Widget entry(String title, String subtitle, String dates, List<String> lines) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: style(FontWeight.w700, 12, color: ink))),
                if (dates.isNotEmpty)
                  Text(dates, style: meta),
              ],
            ),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: meta),
            for (final line in lines.where((line) => line.trim().isNotEmpty))
              bullet(line.trim()),
          ],
        ),
      );
    }

    final contact = [
      resume.email,
      resume.phone,
      resume.location,
      resume.website,
      resume.linkedinLink,
      resume.githubLink,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).join('  ·  ');
    final name = resume.fullName.trim().isEmpty ? 'Your Name' : resume.fullName.trim();
    final onBand = kind == ResumeTemplate.sunset || kind == ResumeTemplate.studio;

    Widget header() {
      final bandInk = resume.corporateColorPreset.titleColor;
      final nameStyle = style(
        FontWeight.w700,
        kind == ResumeTemplate.aurora ? 28 : 26,
        color: onBand ? (lightBand ? bandInk : Colors.white) : ink,
        height: 1.05,
        letterSpacing: kind == ResumeTemplate.inkPanel ? 1.1 : 0,
      );
      final titleStyle = style(
        FontWeight.w400,
        13,
        color: onBand
            ? (lightBand ? bandInk : const Color(0xFFFFF1E6))
            : accent,
        letterSpacing: 0.4,
      );
      final contactStyle = style(
        FontWeight.w400,
        10.5,
        color: kind == ResumeTemplate.chevron
            ? accent
            : onBand
            ? (lightBand ? bandInk.withValues(alpha: 0.8) : const Color(0xFFFFF6F0))
            : muted,
        height: 1.3,
      );
      final column = Column(
        crossAxisAlignment: kind == ResumeTemplate.sageFrame
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        children: [
          Text(
            kind == ResumeTemplate.inkPanel ? name.toUpperCase() : name,
            textAlign: kind == ResumeTemplate.sageFrame ? TextAlign.center : TextAlign.start,
            style: nameStyle,
          ),
          if (resume.jobTitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              resume.jobTitle.trim(),
              textAlign: kind == ResumeTemplate.sageFrame ? TextAlign.center : TextAlign.start,
              style: titleStyle,
            ),
          ],
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              contact,
              textAlign: kind == ResumeTemplate.sageFrame ? TextAlign.center : TextAlign.start,
              style: contactStyle,
            ),
          ],
        ],
      );
      if (kind == ResumeTemplate.sunset) {
        return Container(
          width: double.infinity,
          color: accent,
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 22),
          child: column,
        );
      }
      if (kind == ResumeTemplate.studio) {
        return Container(
          width: double.infinity,
          color: accent,
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 22),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  color: highlight,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: column,
              ),
            ],
          ),
        );
      }
      return column;
    }

    List<Widget> sections() {
      return _mapCreativeSections(
        previewBodySectionOrder(
          resume,
          followOrder: followBuilderSectionOrder,
        ),
        (id) {
          switch (id) {
            case ResumeBuilderSectionIds.work:
              final items = resume.visibleWorkExperiences;
              if (items.isEmpty) return null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(resume.sectionHeading(id, 'Work Experience')),
                  for (final item in items)
                    entry(
                      item.role.trim(),
                      item.company.trim(),
                      educationDateRangeLabel(item.startDate, item.endDate),
                      [
                        if (item.description.trim().isNotEmpty) item.description.trim(),
                        ...item.bullets,
                      ],
                    ),
                ],
              );
            case ResumeBuilderSectionIds.education:
              final items = resume.visibleEducation;
              if (items.isEmpty) return null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(resume.sectionHeading(id, 'Education')),
                  for (final item in items)
                    entry(
                      item.degree.trim(),
                      item.institution.trim(),
                      educationDateRangeLabel(item.startDate, item.endDate),
                      [educationDetailLine(item)],
                    ),
                ],
              );
            case ResumeBuilderSectionIds.skills:
              if (!resume.includeSkillsInResume) return null;
              final grouped = resume.showCategorisedSkills;
              final flat = resume.skillsForResume;
              if (!grouped && flat.isEmpty) return null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(resume.sectionHeading(id, 'Skills')),
                  if (grouped)
                    for (final group in resume.skillGroupsForResume) ...[
                      if (group.heading.trim().isNotEmpty)
                        Text(group.heading.trim(), style: style(FontWeight.w700, 11.5, color: ink)),
                      for (final skill in group.skills.where((s) => s.trim().isNotEmpty))
                        bullet(skill.trim()),
                    ]
                  else
                    for (final skill in flat) bullet(skill),
                ],
              );
            case ResumeBuilderSectionIds.projects:
              final items = resume.visibleProjects;
              if (items.isEmpty) return null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(resume.sectionHeading(id, 'Projects')),
                  for (final item in items)
                    entry(
                      item.title.trim(),
                      [item.subtitle, item.overview, item.impact]
                          .map((line) => line.trim())
                          .where((line) => line.isNotEmpty)
                          .join(' · '),
                      '',
                      item.bullets,
                    ),
                ],
              );
            default:
              final index = ResumeBuilderSectionIds.customIndex(id);
              if (index == null ||
                  index < 0 ||
                  index >= resume.customSections.length) {
                return null;
              }
              final item = resume.customSections[index];
              if (item.isBlank) return null;
              final lines = <String>[
                if (customSectionMetaLine(item).isNotEmpty) customSectionMetaLine(item),
                if (!item.usesItemEntries && item.content.trim().isNotEmpty)
                  item.content.trim(),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(item.title.trim().isEmpty ? 'Section' : item.title.trim()),
                  if (item.usesItemEntries)
                    for (final entryItem in item.visibleEntries)
                      entry(
                        entryItem.name.trim(),
                        entryItem.company.trim(),
                        entryItem.period.trim().isNotEmpty
                            ? entryItem.period.trim()
                            : educationDateRangeLabel(
                                entryItem.startDate,
                                entryItem.endDate,
                              ),
                        [entryItem.summary],
                      )
                  else ...[
                    for (final line in lines) Text(line, style: body),
                    for (final line in item.bullets.where((line) => line.trim().isNotEmpty))
                      bullet(line.trim()),
                  ],
                ],
              );
          }
        },
      );
    }

    final summary = resume.summary.trim();
    // One inset for the name and the sections, so the grid cards line up
    // inside the page instead of sitting on the edge.
    final pageInset = switch (kind) {
      ResumeTemplate.sunset || ResumeTemplate.studio => EdgeInsets.zero,
      ResumeTemplate.inkPanel => const EdgeInsets.fromLTRB(36, 28, 36, 32),
      ResumeTemplate.sageFrame => const EdgeInsets.fromLTRB(32, 28, 32, 32),
      ResumeTemplate.arc => const EdgeInsets.fromLTRB(40, 28, 64, 40),
      ResumeTemplate.chevron => const EdgeInsets.fromLTRB(40, 32, 40, 36),
      ResumeTemplate.wave => const EdgeInsets.fromLTRB(40, 32, 40, 36),
      _ => const EdgeInsets.fromLTRB(40, 28, 40, 32),
    };
    final bodyInset = onBand
        ? const EdgeInsets.fromLTRB(40, 16, 40, 48)
        : const EdgeInsets.only(top: 12);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : width / (1 / 1.4142);
        return SizedBox(
          width: width,
          height: height,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _pageWidth,
                height: _pageHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _CreativePagePaint(
                        kind: kind,
                        accent: accent,
                        highlight: highlight,
                      ),
                    ),
                    Padding(
                      padding: pageInset,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header(),
                          Expanded(
                            child: Padding(
                              padding: bodyInset,
                              child: ClipRect(
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (summary.isNotEmpty)
                                        Text(summary, style: body),
                                      ...sections(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

List<Widget> _mapCreativeSections(
  List<String> order,
  Widget? Function(String sectionId) buildSection,
) {
  final widgets = <Widget>[];
  for (final id in order) {
    final widget = buildSection(id);
    if (widget != null) widgets.add(widget);
  }
  return widgets;
}

class _CreativePagePaint extends StatelessWidget {
  const _CreativePagePaint({
    required this.kind,
    required this.accent,
    required this.highlight,
  });

  final ResumeTemplate kind;
  final Color accent;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      ResumeTemplate.aurora => const Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: Color(0xFFFFF4EC))),
          Positioned(right: -160, top: -170, child: _Blob(size: 200, color: Color(0xFFF6C7A4))),
          Positioned(left: -140, bottom: -50, child: _Blob(size: 180, color: Color(0xFFE5D4F8))),
          Positioned(right: -16, bottom: -8, child: _Blob(size: 52, color: Color(0xFFF3D2BE))),
        ],
      ),
      ResumeTemplate.inkPanel => Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF7F1E8))),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 16,
            child: ColoredBox(color: accent),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: 8,
            child: ColoredBox(color: accent),
          ),
          const Positioned(right: -70, bottom: -30, child: _Blob(size: 110, color: Color(0xFFE7D3C4))),
        ],
      ),
      ResumeTemplate.sunset => const Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: Color(0xFFFFF8F4))),
          Positioned(right: -36, top: 168, child: _Blob(size: 72, color: Color(0xFFF6D3B0))),
          Positioned(left: -40, bottom: -16, child: _Blob(size: 80, color: Color(0xFFF8CDB8))),
        ],
      ),
      ResumeTemplate.sageFrame => Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFE6EFE4))),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.fromBorderSide(
                    BorderSide(color: accent, width: 1.2),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: accent, width: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ResumeTemplate.studio => Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF7F4EF))),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 22,
            child: ColoredBox(color: accent),
          ),
          Positioned(left: 16, bottom: 30, child: _Blob(size: 22, color: highlight)),
        ],
      ),
      ResumeTemplate.chevron => const _ChevronPage(),
      ResumeTemplate.wave => const _WavePage(),
      ResumeTemplate.arc => Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF4FBFA))),
          Positioned(right: -130, top: -130, child: _Blob(size: 180, color: accent)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 18,
            child: ColoredBox(color: accent),
          ),
          const Positioned(left: 18, bottom: 28, child: _Blob(size: 22, color: Color(0xFFB7E0DC))),
        ],
      ),
      _ => const ColoredBox(color: Colors.white),
    };
  }
}

class _ChevronPage extends StatelessWidget {
  const _ChevronPage();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _ChevronPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    const band = 250.0;
    const span = 340.0;
    final triangle = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width - span, 0)
      ..lineTo(size.width, band)
      ..close();
    canvas.drawPath(triangle, Paint()..color = const Color(0xFFF7FBF9));
    canvas.save();
    canvas.clipPath(triangle);
    final stroke = Paint()
      ..color = const Color(0xFFC5D2CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeJoin = StrokeJoin.round;
    const pitch = 36.0;
    const row = 22.0;
    const depth = 10.0;
    for (var r = 0; r * row < band + row; r++) {
      final path = Path();
      final y0 = r * row;
      path.moveTo(size.width - span - pitch, y0);
      var x = size.width - span - pitch;
      var up = r.isEven;
      while (x < size.width + pitch) {
        final next = x + pitch / 2;
        path.lineTo(next, y0 + (up ? depth : -depth));
        up = !up;
        x = next;
      }
      canvas.drawPath(path, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePage extends StatelessWidget {
  const _WavePage();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _WavePainter(),
      child: SizedBox.expand(),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    const band = 250.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, band),
      Paint()..color = const Color(0xFFD7E7F6),
    );
    final line = Paint()
      ..color = const Color(0xF2FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    void curve(double y, double amp) {
      final path = Path()..moveTo(-12, y);
      path.cubicTo(
        size.width * 0.28,
        y - amp,
        size.width * 0.62,
        y + amp,
        size.width + 12,
        y - amp * 0.35,
      );
      canvas.drawPath(path, line);
    }

    curve(48, 18);
    curve(96, 12);
    final wave = Path()
      ..moveTo(0, band)
      ..lineTo(0, band - 78)
      ..cubicTo(
        size.width * 0.24,
        band - 130,
        size.width * 0.58,
        band - 18,
        size.width,
        band - 88,
      )
      ..lineTo(size.width, band)
      ..close();
    canvas.drawPath(wave, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
