import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/corporate_resume_style.dart';
import '../../core/models/resume_builder_section_order.dart';
import '../../core/models/resume_models.dart';
import '../../core/resume_page_art.dart';
import '../../core/resume_text_font.dart';
import '../../core/sample_avatar.dart';

/// On-screen page for Summit, Folio, Beacon and Vertex. Laid out on an A4 point
/// canvas with the same metrics as the PDF page, then scaled to the width.
class ProfessionalResumePreview extends StatelessWidget {
  const ProfessionalResumePreview({
    super.key,
    required this.resume,
    this.followBuilderSectionOrder = false,
  });

  final ResumeData resume;
  final bool followBuilderSectionOrder;

  @override
  Widget build(BuildContext context) {
    final kind = resume.template.userFacingTemplate;
    final accent = resume.creativeAccentColor;
    final onBand = resume.corporateColorPreset.headerOnColor;
    final wash = Color.lerp(Colors.white, accent, 0.1) ?? accent;
    final softRule = Color.lerp(Colors.white, accent, 0.3) ?? accent;
    const bodyInk = ResumeTypography.atsStructuredBodyTextColor;
    const muted = Color(0xFF5B6168);
    final family = resume.usesOutfitResumeFont
        ? ResumeTextFont.outfit.flutterFontFamily
        : ResumeTextFont.garamond.flutterFontFamily;
    final bodyPt = resume.effectiveBodyFontPt.toDouble();
    final hasRail =
        kind == ResumeTemplate.beacon || kind == ResumeTemplate.vertex;

    TextStyle style(
      FontWeight weight,
      double size,
      Color color, {
      double letterSpacing = 0,
    }) => TextStyle(
      fontFamily: family,
      fontWeight: weight,
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      height: ResumeTypography.bodyTextLineHeight,
    );

    final bodyStyle = style(FontWeight.w400, bodyPt, bodyInk);
    final metaStyle = style(FontWeight.w400, bodyPt - 0.5, muted);
    final roleStyle = style(FontWeight.w700, bodyPt + 0.5, bodyInk);

    final name = resume.fullName.trim().isEmpty
        ? 'Your Name'
        : resume.fullName.trim();
    final jobTitle = resume.jobTitle.trim();
    final contactLine = [
      resume.email,
      resume.phone,
      resume.location,
      resume.website,
      resume.linkedinLink,
      resume.githubLink,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).join('  ·  ');

    final avatarPath = resume.profileImagePath.trim();
    final hasProfileImage =
        avatarPath.isNotEmpty && File(avatarPath).existsSync();
    // No placeholder when there is no photo: the header closes up instead.
    final showPhoto = hasProfileImage || resume.isGallerySample;

    Widget photo(double size, {bool rounded = false, double ring = 0}) {
      final image = hasProfileImage
          ? Image.file(File(avatarPath), fit: BoxFit.cover)
          : Image.asset(
              gallerySampleAvatarAsset(resume.template),
              fit: BoxFit.cover,
            );
      final clipped = SizedBox(
        width: size,
        height: size,
        child: rounded
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: image)
            : ClipOval(child: image),
      );
      if (ring == 0) return clipped;
      return Container(
        width: size + ring * 2,
        height: size + ring * 2,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: clipped,
      );
    }

    Widget sectionTitle(String heading) {
      return switch (kind) {
        ResumeTemplate.summit => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 7),
          child: Row(
            children: [
              Text(heading, style: style(FontWeight.w700, 14, accent)),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 1, color: softRule)),
            ],
          ),
        ),
        ResumeTemplate.beacon => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 7),
          child: Row(
            children: [
              Container(width: 9, height: 9, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  heading.toUpperCase(),
                  style: style(
                    FontWeight.w700,
                    11.5,
                    bodyInk,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        _ => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(heading, style: style(FontWeight.w700, 14, accent)),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(width: 30, height: 2.4, color: accent),
                  Expanded(child: Container(height: 0.6, color: softRule)),
                ],
              ),
            ],
          ),
        ),
      };
    }

    Widget folioRow(Widget child, {String? label}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: kFolioLabelPt,
          child: label == null
              ? null
              : Text(
                  label.toUpperCase(),
                  style: style(
                    FontWeight.w700,
                    9.5,
                    accent,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
        const SizedBox(width: kFolioGutterPt),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: kFolioGutterPt),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: softRule, width: 0.8)),
            ),
            child: child,
          ),
        ),
      ],
    );

    List<Widget> section(String heading, List<Widget> blocks) {
      if (blocks.isEmpty) return const [];
      if (kind != ResumeTemplate.folio) {
        return [sectionTitle(heading), ...blocks];
      }
      return [
        const SizedBox(height: 14),
        for (var i = 0; i < blocks.length; i++)
          folioRow(blocks[i], label: i == 0 ? heading : null),
      ];
    }

    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 11, child: Text('•', style: bodyStyle)),
          Expanded(child: Text(text, style: bodyStyle)),
        ],
      ),
    );

    Widget entry({
      required String title,
      required String organisation,
      required String dates,
      required List<Widget> details,
    }) {
      final dateStyle = style(
        FontWeight.w600,
        bodyPt - 0.5,
        kind == ResumeTemplate.beacon ? muted : accent,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: roleStyle)),
                if (dates.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(dates, style: dateStyle),
                ],
              ],
            ),
            if (organisation.isNotEmpty) Text(organisation, style: metaStyle),
            ...details,
          ],
        ),
      );
    }

    Widget chips(Iterable<String> labels) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final label in labels)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: wash,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(label, style: bodyStyle),
            ),
        ],
      ),
    );

    List<Widget> flowSkills() {
      if (!resume.showCategorisedSkills) {
        final skills = resume.skillsLinesForDisplay;
        return skills.isEmpty ? const [] : [chips(skills)];
      }
      return [
        for (final group in resume.skillGroupsForResume) ...[
          if (group.heading.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(group.heading.trim(), style: roleStyle),
            ),
          chips(
            group.skills
                .map((skill) => skill.trim())
                .where((skill) => skill.isNotEmpty),
          ),
        ],
      ];
    }

    List<Widget> bodySections() {
      final widgets = <Widget>[];
      for (final id in previewBodySectionOrder(
        resume,
        followOrder: followBuilderSectionOrder,
        exclude: hasRail ? {ResumeBuilderSectionIds.skills} : const {},
      )) {
        final customIndex = ResumeBuilderSectionIds.customIndex(id);
        if (customIndex != null) {
          if (customIndex < 0 || customIndex >= resume.customSections.length) {
            continue;
          }
          final item = resume.customSections[customIndex];
          if (item.isBlank) continue;
          final title = item.title.trim().isEmpty
              ? 'Custom section'
              : item.title.trim();
          final meta = customSectionMetaLine(item);
          widgets.addAll(
            section(title, [
              if (meta.isNotEmpty) Text(meta, style: metaStyle),
              if (item.usesItemEntries)
                for (final work in item.visibleEntries.map(
                  (entryItem) => entryItem.toWorkExperience(),
                ))
                  entry(
                    title: work.role.trim(),
                    organisation: work.company.trim(),
                    dates: educationDateRangeLabel(
                      work.startDate,
                      work.endDate,
                    ),
                    details: [
                      for (final line in _workLines(work)) bullet(line),
                    ],
                  )
              else ...[
                if (item.content.trim().isNotEmpty)
                  Text(item.content.trim(), style: bodyStyle),
                for (final line in item.bullets.where(
                  (line) => line.trim().isNotEmpty,
                ))
                  bullet(line.trim()),
              ],
            ]),
          );
          continue;
        }
        switch (id) {
          case ResumeBuilderSectionIds.work:
            widgets.addAll(
              section(resume.sectionHeading(id, 'Work Experience'), [
                for (final item in resume.visibleWorkExperiences)
                  entry(
                    title: item.role.trim().isEmpty ? 'Role' : item.role.trim(),
                    organisation: item.company.trim(),
                    dates: educationDateRangeLabel(
                      item.startDate,
                      item.endDate,
                    ),
                    details: [
                      for (final line in _workLines(item)) bullet(line),
                    ],
                  ),
              ]),
            );
          case ResumeBuilderSectionIds.education:
            widgets.addAll(
              section(resume.sectionHeading(id, 'Education'), [
                for (final item in resume.visibleEducation)
                  entry(
                    title: item.degree.trim().isNotEmpty
                        ? item.degree.trim()
                        : item.institution.trim(),
                    organisation: item.degree.trim().isEmpty
                        ? ''
                        : item.institution.trim(),
                    dates: educationDateRangeLabel(
                      item.startDate,
                      item.endDate,
                    ),
                    details: [
                      if (educationDetailLine(item).isNotEmpty)
                        Text(educationDetailLine(item), style: bodyStyle),
                    ],
                  ),
              ]),
            );
          case ResumeBuilderSectionIds.skills:
            widgets.addAll(
              section(resume.sectionHeading(id, 'Skills'), flowSkills()),
            );
          case ResumeBuilderSectionIds.projects:
            widgets.addAll(
              section(resume.sectionHeading(id, 'Projects'), [
                for (final item in resume.visibleProjects)
                  entry(
                    title: item.title.trim().isEmpty
                        ? 'Project'
                        : item.title.trim(),
                    organisation: item.subtitle.trim(),
                    dates: '',
                    details: [
                      for (final line in _projectLines(item)) bullet(line),
                    ],
                  ),
              ]),
            );
        }
      }
      return widgets;
    }

    final summary = resume.summary.trim();
    final summaryBlocks = summary.isEmpty
        ? const <Widget>[]
        : section('Profile', [Text(summary, style: bodyStyle)]);

    Widget nameBlock(Color nameColor, Color titleColor) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: style(FontWeight.w700, 28, nameColor)),
        if (jobTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              jobTitle,
              style: style(FontWeight.w400, 13, titleColor),
            ),
          ),
      ],
    );

    Widget railPanel() {
      final railLabel = style(FontWeight.w700, bodyPt - 1, bodyInk);
      final railValue = style(FontWeight.w400, bodyPt - 1, bodyInk);
      final contacts = <(String, String)>[
        ('Phone', resume.phone.trim()),
        ('Email', resume.email.trim()),
        ('Address', resume.location.trim()),
        ('Website', resume.website.trim()),
        ('LinkedIn', resume.linkedinLink.trim()),
        ('GitHub', resume.githubLink.trim()),
      ].where((entry) => entry.$2.isNotEmpty).toList();
      Widget heading(String title) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 22, bottom: 12),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: accent, width: 0.8)),
        ),
        child: Text(title, style: style(FontWeight.w700, 13, accent)),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kind == ResumeTemplate.beacon && showPhoto)
            Center(child: photo(kBeaconPhotoPt)),
          heading('Contact'),
          if (contacts.isEmpty)
            Text('Add contact details', style: railValue)
          else
            for (final (label, value) in contacts) ...[
              Text(label, style: railLabel),
              const SizedBox(height: 1),
              Text(value, style: railValue),
              const SizedBox(height: 7),
            ],
          if (resume.includeSkillsInResume &&
              (resume.showCategorisedSkills ||
                  resume.skillsLinesForDisplay.isNotEmpty)) ...[
            heading(
              resume.sectionHeading(ResumeBuilderSectionIds.skills, 'Skills'),
            ),
            if (resume.showCategorisedSkills)
              for (final group in resume.skillGroupsForResume) ...[
                if (group.heading.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 3),
                    child: Text(group.heading.trim(), style: railLabel),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(group.skillsCommaSeparated, style: railValue),
                ),
              ]
            else
              for (final skill in resume.skillsLinesForDisplay)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $skill', style: railValue),
                ),
          ],
        ],
      );
    }

    Widget clippedColumn(List<Widget> children) => ClipRect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );

    List<Widget> page() {
      switch (kind) {
        case ResumeTemplate.summit:
          return [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: kSummitBandPt,
              child: ColoredBox(color: accent),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: kSummitBandPt,
              height: kSummitStripPt,
              child: ColoredBox(color: wash),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, kSummitPageTopPt, 40, 36),
              child: clippedColumn([
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kSummitBandPt - kSummitPageTopPt,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showPhoto)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: photo(kSummitPhotoPt - 4, ring: 2),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: nameBlock(onBand, onBand),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: kSummitStripPt,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      contactLine,
                      style: style(FontWeight.w400, 9.5, bodyInk),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                ...summaryBlocks,
                ...bodySections(),
              ]),
            ),
          ];
        case ResumeTemplate.folio:
          return [
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
              child: clippedColumn([
                Row(
                  children: [
                    Expanded(child: nameBlock(bodyInk, accent)),
                    if (showPhoto) ...[
                      const SizedBox(width: 14),
                      photo(kFolioPhotoPt, rounded: true),
                    ],
                  ],
                ),
                const SizedBox(height: 9),
                Container(height: 2.2, color: accent),
                if (contactLine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      contactLine,
                      style: style(FontWeight.w400, 9.5, bodyInk),
                    ),
                  ),
                ...summaryBlocks,
                ...bodySections(),
              ]),
            ),
          ];
        case ResumeTemplate.beacon:
          return [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: kBeaconRailPt,
              child: ColoredBox(color: wash),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 6,
              child: ColoredBox(color: accent),
            ),
            Positioned(
              right: kBeaconRailInsetPt,
              top: kProfessionalPageTopPt,
              bottom: kProfessionalPageBottomPt,
              width: kBeaconRailPt - kBeaconRailInsetPt * 2,
              child: clippedColumn([railPanel()]),
            ),
            Positioned(
              left: kProfessionalPageSidePt,
              right: kBeaconRailPt + kProfessionalColumnGapPt,
              top: kProfessionalPageTopPt,
              bottom: kProfessionalPageBottomPt,
              child: clippedColumn([
                nameBlock(bodyInk, accent),
                ...summaryBlocks,
                ...bodySections(),
              ]),
            ),
          ];
        default:
          return [
            Positioned.fill(
              child: CustomPaint(
                painter: _VertexWedgePainter(accent),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: kProfessionalPageSidePt,
              right: kProfessionalPageSidePt,
              top: kProfessionalPageTopPt,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nameBlock(onBand, onBand)),
                  if (showPhoto) ...[
                    const SizedBox(width: 14),
                    photo(kVertexPhotoPt - 4, ring: 2),
                  ],
                ],
              ),
            ),
            Positioned(
              right: kProfessionalPageSidePt,
              top: kVertexBodyTopPt,
              bottom: kProfessionalPageBottomPt,
              width: kVertexSidePt,
              child: clippedColumn([railPanel()]),
            ),
            Positioned(
              left: kProfessionalPageSidePt,
              right:
                  kProfessionalPageSidePt +
                  kVertexSidePt +
                  kProfessionalColumnGapPt,
              top: kVertexBodyTopPt,
              bottom: kProfessionalPageBottomPt,
              child: clippedColumn([...summaryBlocks, ...bodySections()]),
            ),
          ];
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : width / (kResumePageWidthPt / kResumePageHeightPt);
        return SizedBox(
          width: width,
          height: height,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: Container(
                width: kResumePageWidthPt,
                height: kResumePageHeightPt,
                color: Colors.white,
                child: Stack(children: page()),
              ),
            ),
          ),
        );
      },
    );
  }
}

List<String> _workLines(WorkExperience item) {
  final bullets = item.bullets
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (bullets.isNotEmpty) return bullets;
  final description = item.description.trim();
  return description.isEmpty ? const [] : [description];
}

List<String> _projectLines(ProjectItem item) {
  final bullets = item.bullets
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (bullets.isNotEmpty) return bullets;
  return [
    item.overview.trim(),
    item.impact.trim(),
  ].where((part) => part.isNotEmpty).toList();
}

class _VertexWedgePainter extends CustomPainter {
  const _VertexWedgePainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    for (final facet in kVertexWedgeFacets) {
      final path = Path();
      final (startX, startY) = facet.points.first;
      path.moveTo(startX, startY);
      for (final (x, y) in facet.points.skip(1)) {
        path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = Color.lerp(Colors.white, accent, facet.tint) ?? accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VertexWedgePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
