import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/corporate_resume_style.dart';
import '../../core/models/resume_models.dart';
import '../../core/resume_text_font.dart';

class ResumePreviewCard extends StatelessWidget {
  const ResumePreviewCard({
    super.key,
    required this.resume,
  });

  final ResumeData resume;
  static const double _a4AspectRatio = 1 / 1.4142;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadow = theme.colorScheme.shadow.withValues(alpha: 0.08);
    final previewTemplate = resume.template.userFacingTemplate;
    final base = theme.textTheme;
    final ff = ResumeTextFont.calibri.flutterFontFamily;
    final onSurface = theme.colorScheme.onSurface;
    final bodyPx = previewTemplate == ResumeTemplate.corporate
        ? resume.effectiveBodyFontPt.toDouble()
        : ResumeTypography.bodyPt.toDouble();
    final resumeBodyTheme = theme.copyWith(
      textTheme: base
          .apply(fontFamily: ff, bodyColor: onSurface, displayColor: onSurface)
          .copyWith(
            bodyLarge: base.bodyLarge?.copyWith(
              fontFamily: ff,
              fontSize: bodyPx,
              height: ResumeTypography.textLineHeight,
            ),
            bodyMedium: base.bodyMedium?.copyWith(
              fontFamily: ff,
              fontSize: bodyPx,
              height: ResumeTypography.textLineHeight,
            ),
            bodySmall: base.bodySmall?.copyWith(
              fontFamily: ff,
              fontSize: bodyPx,
              height: ResumeTypography.textLineHeight,
            ),
            titleSmall: base.titleSmall?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
              height: ResumeTypography.textLineHeight,
            ),
            titleMedium: base.titleMedium?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
              height: ResumeTypography.textLineHeight,
            ),
            titleLarge: base.titleLarge?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
              height: ResumeTypography.textLineHeight,
            ),
            headlineSmall: base.headlineSmall?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
              height: ResumeTypography.textLineHeight,
            ),
            headlineMedium: base.headlineMedium?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
              height: ResumeTypography.textLineHeight,
            ),
            labelLarge: base.labelLarge?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
              height: ResumeTypography.textLineHeight,
            ),
          ),
    );

    return Theme(
      data: resumeBodyTheme,
      child: AspectRatio(
        aspectRatio: _a4AspectRatio,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: resume.template.accentColor.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: switch (previewTemplate) {
                  ResumeTemplate.corporate => _DarkHeaderPreview(resume: resume),
                  ResumeTemplate.creative => _CreativePreview(resume: resume),
                },
              ),
              if (kDebugMode)
                Positioned(
                  right: 10,
                  top: 10,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'Font: $ff',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _CorporatePdfMetrics {
  static const lineColor = Color(0xFFD7DCE2);
  static const dateMutedColor = Color(0xFF666B71);

  static const bodyHeight = ResumeTypography.textLineHeight;

  static double headerAvatar() => 75;

  static double headerNameSize() => ResumeTypography.darkHeaderNamePt;

  static const headerAfterAvatar = 25.0;
  static const afterHeader = 18.0;

  /// Keep this aligned with [ResumeTypography.sectionGapPreviewPx].
  static EdgeInsets sectionOuter() => const EdgeInsets.fromLTRB(
        30,
        0,
        30,
        ResumeTypography.sectionGapPreviewPx,
      );

  /// [_twoColumnBulletList] column gap.
  static const skillsColumnGap = 24.0;
  static const bulletItemBottom = 5.0;

  static const experienceBlockBottom = 10.0;
  static const descAfterTitle = 4.0;
  static const bulletTop = 3.0;
  static const educationBlockBottom = 8.0;
  static const projectBlockBottom = 8.0;
}

class _DarkHeaderPreview extends StatelessWidget {
  const _DarkHeaderPreview({required this.resume});

  final ResumeData resume;
  static const double _darkHeaderExtraLineSpacingPx = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _pdfAlignedDisplayName(resume);
    final contactItems = _pdfAlignedContactItems(resume);
    final skills = _pdfAlignedSkills(resume);
    final onSurface = theme.colorScheme.onSurface;
    final bodyFontPx = resume.effectiveBodyFontPt.toDouble();
    final preset = resume.corporateColorPreset;
    final bodyLineHeight =
        _CorporatePdfMetrics.bodyHeight +
        (_darkHeaderExtraLineSpacingPx / bodyFontPx);
    final nameLineHeight =
        1.05 +
        (_darkHeaderExtraLineSpacingPx /
            _CorporatePdfMetrics.headerNameSize());
    final bodyStyle = TextStyle(
      fontSize: bodyFontPx,
      height: bodyLineHeight,
      color: onSurface,
    );

    const headerPadding = EdgeInsets.fromLTRB(30, 30, 30, 30);
    final avatarTopOffset = 0.0;
    final nameLabelTopOffset = 0.0;
    final nameToContactSpacing = 10.0;
    const defaultTextLineHeight = ResumeTypography.textLineHeight;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: preset.headerColor,
          child: Padding(
            padding: headerPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: avatarTopOffset),
                  child: SizedBox(
                    width: _CorporatePdfMetrics.headerAvatar(),
                    height: _CorporatePdfMetrics.headerAvatar(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                      child: Center(
                        child: Text(
                          _pdfAlignedInitials(resume),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            height: ResumeTypography.textLineHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _CorporatePdfMetrics.headerAfterAvatar),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: nameLabelTopOffset),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _CorporatePdfMetrics.headerNameSize(),
                            fontWeight: FontWeight.w900,
                            height: nameLineHeight,
                            letterSpacing: 0.15,
                          ),
                        ),
                        if (contactItems.isNotEmpty) ...[
                          SizedBox(height: nameToContactSpacing),
                          Text(
                            contactItems.join(' | '),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: bodyFontPx,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: _CorporatePdfMetrics.afterHeader),
        _CorporatePdfLikeSection(
          outerPadding: _CorporatePdfMetrics.sectionOuter(),
          title: 'SUMMARY',
          titleColor: preset.titleColor,
          lineColor: _CorporatePdfMetrics.lineColor,
          hasContent: resume.summary.trim().isNotEmpty,
          child: resume.summary.trim().isNotEmpty
              ? Text(resume.summary.trim(), style: bodyStyle)
              : const SizedBox.shrink(),
        ),
        if (resume.includeWorkInResume)
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(),
            title: 'EXPERIENCE',
            titleColor: preset.titleColor,
            lineColor: _CorporatePdfMetrics.lineColor,
            hasContent: resume.visibleWorkExperiences.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in resume.visibleWorkExperiences.take(3))
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: _CorporatePdfMetrics.experienceBlockBottom,
                    ),
                    child: _CorporateExperienceBlock(
                      item: item,
                      dateColor: _CorporatePdfMetrics.dateMutedColor,
                      bodyStyle: bodyStyle,
                    ),
                  ),
              ],
            ),
          ),
        if (resume.includeEducationInResume)
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(),
            title: 'EDUCATION',
            titleColor: preset.titleColor,
            lineColor: _CorporatePdfMetrics.lineColor,
            hasContent: resume.visibleEducation.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in resume.visibleEducation.take(2))
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: _CorporatePdfMetrics.educationBlockBottom,
                    ),
                    child: _CorporateEducationBlock(
                      item: item,
                      bodyStyle: bodyStyle,
                    ),
                  ),
              ],
            ),
          ),
        _CorporatePdfLikeSection(
          outerPadding: _CorporatePdfMetrics.sectionOuter(),
          title: 'SKILLS',
          titleColor: preset.titleColor,
          lineColor: _CorporatePdfMetrics.lineColor,
          hasContent: skills.isNotEmpty,
          child: _CorporateSkillsColumns(skills: skills, bodyStyle: bodyStyle),
        ),
        if (resume.includeProjectsInResume)
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(),
            title: 'PROJECTS',
            titleColor: preset.titleColor,
            lineColor: _CorporatePdfMetrics.lineColor,
            hasContent: resume.visibleProjects.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in resume.visibleProjects.take(2))
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: _CorporatePdfMetrics.projectBlockBottom,
                    ),
                    child: _CorporateProjectBlock(
                      item: item,
                      bodyStyle: bodyStyle,
                    ),
                  ),
              ],
            ),
          ),
        for (final item in resume.visibleCustomSections.take(2))
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(),
            title: item.title.ifBlank('Custom section').toUpperCase(),
            titleColor: preset.titleColor,
            lineColor: _CorporatePdfMetrics.lineColor,
            child: _corporateCustomSectionBody(item, bodyStyle),
          ),
        // [_addCorporateTemplatePage] ends with `pw.SizedBox(height: 10)`.
        const SizedBox(height: 10),
      ],
    );

    return DefaultTextStyle.merge(
      style: TextStyle(height: defaultTextLineHeight),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: content,
      ),
    );
  }
}

class _CorporatePdfLikeSection extends StatelessWidget {
  const _CorporatePdfLikeSection({
    required this.outerPadding,
    required this.title,
    required this.titleColor,
    required this.lineColor,
    required this.child,
    this.hasContent = true,
  });

  /// Matches [_corporateSection] horizontal inset and bottom margin.
  final EdgeInsets outerPadding;
  final String title;
  final Color titleColor;
  final Color lineColor;
  final Widget child;
  final bool hasContent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: outerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: ResumeTypography.darkHeaderSectionTitlePt,
              fontWeight: FontWeight.w900,
              height: ResumeTypography.textLineHeight,
              color: titleColor,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 7),
          Container(height: 2, color: lineColor),
          if (hasContent) ...[
            const SizedBox(height: 12),
            child,
          ] else ...[
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CorporateSkillsColumns extends StatelessWidget {
  const _CorporateSkillsColumns({
    required this.skills,
    required this.bodyStyle,
  });

  final List<String> skills;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final midpoint = (skills.length / 2).ceil();
    final left = skills.take(midpoint).toList();
    final right = skills.skip(midpoint).toList();

    Widget column(List<String> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(
                bottom: _CorporatePdfMetrics.bulletItemBottom,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: bodyStyle.copyWith(
                      height: _CorporatePdfMetrics.bodyHeight,
                    ),
                  ),
                  Expanded(child: Text(item, style: bodyStyle)),
                ],
              ),
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(left)),
        const SizedBox(width: _CorporatePdfMetrics.skillsColumnGap),
        Expanded(child: column(right)),
      ],
    );
  }
}

class _CorporateExperienceBlock extends StatelessWidget {
  const _CorporateExperienceBlock({
    required this.item,
    required this.dateColor,
    required this.bodyStyle,
  });

  final WorkExperience item;
  final Color dateColor;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final start = item.startDate.trim();
    final end = item.endDate.trim();
    final dateStr = start.isEmpty && end.isEmpty
        ? ''
        : '${start.isNotEmpty ? start : ''}'
              '${start.isNotEmpty && end.isNotEmpty ? ' - ' : ''}'
              '${end.isNotEmpty ? end : ''}';

    final dateStyle = bodyStyle.copyWith(
      color: dateColor,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      fontSize: bodyStyle.fontSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${item.role.ifBlank('Role')} / ${item.company.ifBlank('Company')}',
                style: bodyStyle.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            if (dateStr.isNotEmpty)
              Center(
                child: Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.skewX(-0.22),
                  child: Text(
                    dateStr,
                    style: dateStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_workSummaryText(item).isNotEmpty) ...[
          SizedBox(height: _CorporatePdfMetrics.descAfterTitle),
          Text(_workSummaryText(item), style: bodyStyle),
        ],
        ...(() {
          final bullets = _workBulletLines(item);
          return bullets.asMap().entries.map((entry) {
            final index = entry.key;
            final bullet = entry.value;
            final top = index == 0
                ? (_CorporatePdfMetrics.bulletTop - 3)
                : _CorporatePdfMetrics.bulletTop;
            return Padding(
              padding: EdgeInsets.only(top: top),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: bodyStyle),
                  Expanded(child: Text(bullet, style: bodyStyle)),
                ],
              ),
            );
          });
        })(),
      ],
    );
  }
}

class _CorporateEducationBlock extends StatelessWidget {
  const _CorporateEducationBlock({required this.item, required this.bodyStyle});

  final EducationItem item;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    // Same line as template card: `Institution  |  2014 - 2018`
    final titleLine = corporateEducationTitleLine(
      item.institution,
      item.startDate,
      item.endDate,
      institutionFallback: 'Institution',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleLine,
          style: bodyStyle.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.0,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(item.degree.ifBlank('Degree'), style: bodyStyle),
      ],
    );
  }
}

class _CorporateProjectBlock extends StatelessWidget {
  const _CorporateProjectBlock({required this.item, required this.bodyStyle});

  final ProjectItem item;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title.ifBlank('Project'),
          style: bodyStyle.copyWith(fontWeight: FontWeight.w900, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        ...(() {
          final bullets = _projectBulletLines(item);
          return bullets.asMap().entries.map((entry) {
            final index = entry.key;
            final bullet = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 2 : 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: bodyStyle),
                  Expanded(child: Text(bullet, style: bodyStyle)),
                ],
              ),
            );
          });
        })(),
      ],
    );
  }
}

Widget _corporateCustomSectionBody(CustomSectionItem item, TextStyle bodyStyle) {
  if (item.layoutMode == CustomSectionLayoutMode.summary) {
    return Text(item.content.trim(), style: bodyStyle);
  }
  final bullets = item.bullets.where((b) => b.trim().isNotEmpty).toList();
  if (bullets.isEmpty) {
    return const SizedBox.shrink();
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: bullets.asMap().entries.map((entry) {
      final index = entry.key;
      final bullet = entry.value;
      return Padding(
        padding: EdgeInsets.only(top: index == 0 ? 2 : 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: bodyStyle),
            Expanded(child: Text(bullet, style: bodyStyle)),
          ],
        ),
      );
    }).toList(),
  );
}

class _CreativePreview extends StatelessWidget {
  const _CreativePreview({required this.resume});

  final ResumeData resume;

  @override
  Widget build(BuildContext context) {
    final dark = resume.corporateColorPreset.headerColor;
    final textColor = resume.corporateColorPreset.titleColor;
    final mutedColor = textColor.withValues(alpha: 0.72);
    final lineColor = textColor.withValues(alpha: 0.34);
    final bodyStyle = TextStyle(
      color: textColor,
      fontSize: resume.effectiveBodyFontPt.toDouble(),
      height: ResumeTypography.textLineHeight,
    );
    final summary = resume.summary.trim();
    final skills = resume.skillsForResume;
    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final contacts = <String>[
      resume.location.trim(),
      resume.phone.trim(),
      resume.email.trim(),
    ].where((item) => item.isNotEmpty).toList();
    final midpoint = (skills.length / 2).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 24,
          decoration: BoxDecoration(color: dark),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 96,
                    height: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE7D0B2), Color(0xFFF7ECDD)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, 9),
                          child: Text(
                            _pdfAlignedDisplayName(resume).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle.copyWith(
                              fontSize: ResumeTypography.darkHeaderNamePt,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 0),
                        Transform.translate(
                          offset: const Offset(0, -6),
                          child: Column(
                            children: [
                              for (final line in contacts.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(right: 6),
                                        color: mutedColor,
                                      ),
                                      Expanded(
                                        child: Text(
                                          line,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: bodyStyle.copyWith(
                                            color: mutedColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _CreativeSidebarHeading(title: 'SUMMARY', lineColor: lineColor),
              const SizedBox(height: 6),
              Text(
                summary.ifBlank(
                  'Add a short summary to position your experience and strengths.',
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle.copyWith(color: mutedColor),
              ),
              const SizedBox(height: 10),
              _CreativeSidebarHeading(title: 'SKILLS', lineColor: lineColor),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CreativeBulletColumn(
                      items: skills.take(midpoint).toList(),
                      bodyStyle: bodyStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CreativeBulletColumn(
                      items: skills.skip(midpoint).toList(),
                      bodyStyle: bodyStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _CreativeSidebarHeading(title: 'EXPERIENCE', lineColor: lineColor),
              const SizedBox(height: 6),
              if (experiences.isNotEmpty)
                ...experiences.take(2).map((item) {
                  final title = [
                    item.role.trim(),
                    item.startDate.trim(),
                    item.endDate.trim(),
                  ].where((s) => s.isNotEmpty).join(', ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.ifBlank('Role'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          item.company.ifBlank('Company'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle.copyWith(
                            color: mutedColor,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _CreativeBulletColumn(
                          items: _workBulletLines(item).take(1).toList(),
                          bodyStyle: bodyStyle,
                        ),
                      ],
                    ),
                  );
                })
              else
                Text(
                  'Add your work experience details.',
                  style: bodyStyle.copyWith(color: mutedColor),
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CreativeSidebarHeading(
                          title: 'EDUCATION',
                          lineColor: lineColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          education.isNotEmpty
                              ? education.first.degree.ifBlank('Degree')
                              : 'Add education',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CreativeSidebarHeading(
                          title: 'PROJECTS',
                          lineColor: lineColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          projects.isNotEmpty
                              ? projects.first.title.ifBlank('Project')
                              : 'Add projects',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreativeSidebarHeading extends StatelessWidget {
  const _CreativeSidebarHeading({required this.title, required this.lineColor});

  final String title;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 123,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: ResumeTypography.darkHeaderSectionTitlePt,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(child: Container(height: 1.1, color: lineColor)),
      ],
    );
  }
}

class _CreativeBulletColumn extends StatelessWidget {
  const _CreativeBulletColumn({required this.items, required this.bodyStyle});

  final List<String> items;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('• Add skills', style: bodyStyle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '• ${item.trim()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle,
            ),
          ),
      ],
    );
  }
}

/// Same naming rules as [ResumePdfService._displayName].
String _pdfAlignedDisplayName(ResumeData resume) {
  final name = resume.fullName.trim();
  return name.isEmpty ? 'Your Name' : name;
}

/// Same initials rules as [ResumePdfService._resumeInitials].
String _pdfAlignedInitials(ResumeData resume) {
  final words = _pdfAlignedDisplayName(
    resume,
  ).split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
  if (words.isEmpty) {
    return 'DA';
  }
  return words.map((part) => part[0].toUpperCase()).join();
}

/// Same contact order as [ResumePdfService._resumeContactItems].
List<String> _pdfAlignedContactItems(ResumeData resume) {
  return [
    resume.location.trim(),
    resume.phone.trim(),
    resume.website.trim(),
    resume.githubLink.trim(),
    resume.linkedinLink.trim(),
  ].where((item) => item.isNotEmpty).toList();
}

/// Same fallback skills as [ResumePdfService._skillsForDisplay].
List<String> _pdfAlignedSkills(ResumeData resume) {
  if (resume.skills.isNotEmpty) {
    return resume.skills;
  }
  return const <String>[];
}

String _workSummaryText(WorkExperience item) {
  return '';
}

List<String> _workBulletLines(WorkExperience item) {
  final nonEmptyBullets = item.bullets
      .where((b) => b.trim().isNotEmpty)
      .toList();
  if (nonEmptyBullets.isNotEmpty) {
    return nonEmptyBullets;
  }
  final legacyDescription = item.description.trim();
  if (legacyDescription.isNotEmpty) {
    return [legacyDescription];
  }
  return const <String>[];
}

List<String> _projectBulletLines(ProjectItem item) {
  final nonEmptyBullets = item.bullets
      .where((b) => b.trim().isNotEmpty)
      .toList();
  if (nonEmptyBullets.isNotEmpty) {
    return nonEmptyBullets;
  }
  final legacy = [item.overview.trim(), item.impact.trim()]
      .where((part) => part.isNotEmpty)
      .toList();
  return legacy;
}


extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
