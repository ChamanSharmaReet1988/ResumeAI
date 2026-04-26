import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/corporate_resume_style.dart';
import '../../core/models/resume_models.dart';
import '../../core/resume_text_font.dart';

class ResumePreviewCard extends StatelessWidget {
  const ResumePreviewCard({
    super.key,
    required this.resume,
    this.showDebugLabel = kDebugMode,
  });

  final ResumeData resume;
  final bool showDebugLabel;
  static const double _a4AspectRatio = 1 / 1.4142;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadow = theme.colorScheme.shadow.withValues(alpha: 0.08);

    return AspectRatio(
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
        child: ResumePreviewCanvas(
          resume: resume,
          showDebugLabel: showDebugLabel,
        ),
      ),
    );
  }
}

class ResumePreviewCanvas extends StatelessWidget {
  const ResumePreviewCanvas({
    super.key,
    required this.resume,
    this.showDebugLabel = false,
  });

  final ResumeData resume;
  final bool showDebugLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      child: Stack(
        children: [
          Positioned.fill(
            child: switch (previewTemplate) {
              ResumeTemplate.corporate => _DarkHeaderPreview(resume: resume),
              ResumeTemplate.creative => _CreativePreview(resume: resume),
              ResumeTemplate.classicSidebar => _ClassicSidebarPreview(
                resume: resume,
              ),
            },
          ),
          if (showDebugLabel)
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
        (_darkHeaderExtraLineSpacingPx / _CorporatePdfMetrics.headerNameSize());
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

Widget _corporateCustomSectionBody(
  CustomSectionItem item,
  TextStyle bodyStyle,
) {
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
  static const double _avatarBackgroundOpacity = 0.4;
  static const double _avatarWidth = 94.6;
  static const double _avatarHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    final railColor = resume.creativeRailColor;
    final accentColor = resume.creativeAccentColor;
    final avatarBackgroundColor = resume.creativeAvatarBackgroundColor;
    final textColor = resume.creativeTitleColor;
    final mutedColor = resume.creativeMutedColor;
    final lineColor = resume.creativeLineColor;
    final bodyStyle = TextStyle(
      fontFamily: 'Calibri',
      color: textColor,
      fontSize: resume.effectiveBodyFontPt.toDouble(),
      height: ResumeTypography.textLineHeight,
    );
    final summary = resume.summary.trim();
    final skills = resume.skillsForResume;
    final experiences = resume.visibleWorkExperiences;
    final education = resume.visibleEducation;
    final projects = resume.visibleProjects;
    final contacts = _pdfAlignedContactItems(resume).take(4).toList();
    final midpoint = (skills.length / 2).ceil();
    const sectionGap = 20.0;
    const headingGap = 6.0;
    const sidebarDividerGap = 20.0;
    const sidebarRailWidth = 125.0;
    const sidebarContentWidth = 101.0;
    const mainContentInset = 123.0;
    const nameFontSize = 30.0;
    final firstProjectLine = projects.isNotEmpty
        ? (_projectBulletLines(projects.first).isNotEmpty
              ? _projectBulletLines(projects.first).first
              : 'Add project details.')
        : '';

    return DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: 'Calibri'),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                Container(width: sidebarRailWidth, color: railColor),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: SizedBox(
              width: sidebarContentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: _avatarWidth,
                    height: _avatarHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: avatarBackgroundColor.withValues(
                        alpha: _avatarBackgroundOpacity,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _pdfAlignedInitials(resume),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 28.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (contacts.isNotEmpty) ...[
                    const SizedBox(height: sectionGap),
                    Container(height: 1.1, color: lineColor),
                    const SizedBox(height: sidebarDividerGap),
                    ...contacts.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _CreativeSidebarMetaItem(
                          text: line,
                          iconColor: accentColor,
                          style: bodyStyle.copyWith(
                            color: mutedColor,
                            fontSize: bodyStyle.fontSize! - 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: mainContentInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pdfAlignedDisplayName(resume).toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle.copyWith(
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (resume.jobTitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        resume.jobTitle.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle.copyWith(
                          color: mutedColor,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: sectionGap),
                    _CreativeSidebarHeading(
                      title: 'SUMMARY',
                      lineColor: lineColor,
                    ),
                    const SizedBox(height: headingGap),
                    Text(
                      summary.ifBlank(
                        'Add a short summary to position your experience and strengths.',
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle.copyWith(color: mutedColor),
                    ),
                    const SizedBox(height: sectionGap),
                    _CreativeSidebarHeading(
                      title: 'EXPERIENCE',
                      lineColor: lineColor,
                    ),
                    const SizedBox(height: headingGap),
                    if (experiences.isNotEmpty)
                      ...experiences.take(2).map((item) {
                        final title = [
                          item.role.trim(),
                          item.startDate.trim(),
                          item.endDate.trim(),
                        ].where((s) => s.isNotEmpty).join(' • ');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.ifBlank('Role'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
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
                    if (education.isNotEmpty) ...[
                      const SizedBox(height: sectionGap),
                      _CreativeSidebarHeading(
                        title: 'EDUCATION',
                        lineColor: lineColor,
                      ),
                      const SizedBox(height: headingGap),
                      ...education
                          .take(2)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.degree.ifBlank('Degree'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: bodyStyle.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    item.institution.ifBlank('Institution'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: bodyStyle.copyWith(
                                      color: mutedColor,
                                      fontSize: bodyStyle.fontSize! - 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    const SizedBox(height: sectionGap),
                    _CreativeSidebarHeading(
                      title: 'SKILLS',
                      lineColor: lineColor,
                    ),
                    const SizedBox(height: headingGap),
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
                    const SizedBox(height: sectionGap),
                    _CreativeSidebarHeading(
                      title: 'PROJECTS',
                      lineColor: lineColor,
                    ),
                    const SizedBox(height: headingGap),
                    Text(
                      projects.isNotEmpty
                          ? projects.first.title.ifBlank('Project')
                          : 'Add projects',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (projects.isNotEmpty)
                      Text(
                        firstProjectLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle.copyWith(color: mutedColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

class _ClassicSidebarPreview extends StatelessWidget {
  const _ClassicSidebarPreview({required this.resume});

  final ResumeData resume;

  static const double _sidebarWidth = 96;
  static const double _avatarSize = 74;
  static const double _sectionGap = 18;
  static const double _contentSectionGap = 16;
  static const double _sectionHeadingGap = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 190 || constraints.maxHeight < 250;
        final railColor = resume.classicSidebarRailColor;
        final accentColor = resume.classicSidebarAccentColor;
        final titleColor = resume.classicSidebarTitleColor;
        final mutedColor = resume.classicSidebarMutedColor;
        final dividerColor = resume.classicSidebarDividerColor;
        final sectionBorderColor = resume.classicSidebarSectionBorderColor;
        final sidebarWidth = compact ? 74.0 : _sidebarWidth;
        final avatarSize = compact ? 54.0 : _avatarSize;
        final bodySize = compact
            ? (resume.effectiveBodyFontPt * 0.74).clamp(6.4, 9.2).toDouble()
            : resume.effectiveBodyFontPt.toDouble();
        final bodyStyle = TextStyle(
          color: titleColor,
          fontSize: bodySize,
          height: compact ? 1.18 : ResumeTypography.textLineHeight,
        );
        final experiences = resume.visibleWorkExperiences
            .take(compact ? 1 : 2)
            .toList();
        final education = resume.visibleEducation
            .take(compact ? 1 : 2)
            .toList();
        final projects = resume.visibleProjects.take(compact ? 1 : 2).toList();
        final skills = _pdfAlignedSkills(resume).take(compact ? 3 : 5).toList();
        final languages = _classicSidebarLanguages(
          resume,
        ).take(compact ? 2 : 4).toList();
        final remainingCustomSections = _classicSidebarMainCustomSections(
          resume,
        );
        final avatarPath = resume.profileImagePath.trim();
        final hasProfileImage =
            avatarPath.isNotEmpty && File(avatarPath).existsSync();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: sidebarWidth,
              color: railColor,
              padding: EdgeInsets.fromLTRB(
                compact ? 7 : 10,
                compact ? 10 : 14,
                compact ? 7 : 10,
                compact ? 10 : 14,
              ),
              child: DefaultTextStyle(
                style: bodyStyle.copyWith(fontSize: bodyStyle.fontSize! - 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipOval(
                        child: SizedBox(
                          width: avatarSize,
                          height: avatarSize,
                          child: hasProfileImage
                              ? Image.file(
                                  File(avatarPath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _ClassicSidebarAvatarPlaceholder(
                                        resume: resume,
                                        fontSize: compact ? 16 : 22,
                                      ),
                                )
                              : _ClassicSidebarAvatarPlaceholder(
                                  resume: resume,
                                  fontSize: compact ? 16 : 22,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : _sectionGap),
                    Container(height: 1.1, color: dividerColor),
                    SizedBox(height: compact ? 6 : 10),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ClassicSidebarListSection(
                              title: 'SKILLS',
                              items: skills,
                              bulletColor: accentColor,
                              textStyle: bodyStyle.copyWith(
                                fontSize: bodyStyle.fontSize! - 0.2,
                              ),
                              maxLines: compact ? 1 : 2,
                            ),
                            if (languages.isNotEmpty) ...[
                              SizedBox(height: compact ? 10 : _sectionGap),
                              Container(height: 1.1, color: dividerColor),
                              SizedBox(height: compact ? 6 : 10),
                              _ClassicSidebarListSection(
                                title: 'LANGUAGES',
                                items: languages,
                                bulletColor: accentColor,
                                textStyle: bodyStyle.copyWith(
                                  fontSize: bodyStyle.fontSize! - 0.2,
                                ),
                                maxLines: 1,
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
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 8 : 12,
                  compact ? 10 : 14,
                  compact ? 8 : 12,
                  compact ? 10 : 14,
                ),
                child: DefaultTextStyle(
                  style: bodyStyle,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pdfAlignedDisplayName(resume).toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle.copyWith(
                            fontSize: compact ? 12 : 18,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (resume.jobTitle.trim().isNotEmpty) ...[
                          SizedBox(height: compact ? 3 : 5),
                          Text(
                            resume.jobTitle.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle.copyWith(
                              color: mutedColor,
                              fontSize: compact
                                  ? bodyStyle.fontSize
                                  : bodyStyle.fontSize! + 0.2,
                            ),
                          ),
                        ],
                        SizedBox(height: compact ? 5 : 7),
                        ..._classicSidebarContactRows(
                          resume,
                          mutedColor: mutedColor,
                          iconColor: titleColor,
                          baseStyle: bodyStyle.copyWith(
                            fontSize: bodyStyle.fontSize! - 0.2,
                          ),
                          maxItems: compact ? 3 : 4,
                        ),
                        SizedBox(height: compact ? 7 : 10),
                        Container(height: 1.1, color: sectionBorderColor),
                        SizedBox(height: compact ? 8 : _contentSectionGap),
                        _ClassicContentSection(
                          title: 'SUMMARY',
                          borderColor: sectionBorderColor,
                          child: Text(
                            resume.summary.trim().ifBlank(
                              'Add a short summary to position your experience and strengths.',
                            ),
                            maxLines: compact ? 3 : 4,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle.copyWith(color: mutedColor),
                          ),
                        ),
                        _ClassicContentSection(
                          title: 'EXPERIENCE',
                          borderColor: sectionBorderColor,
                          child: experiences.isEmpty
                              ? Text(
                                  'Add your work experience details.',
                                  style: bodyStyle.copyWith(color: mutedColor),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final item in experiences)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: compact ? 6 : 10,
                                        ),
                                        child: _ClassicExperienceBlock(
                                          item: item,
                                          bodyStyle: bodyStyle,
                                          mutedColor: mutedColor,
                                          bulletColor: titleColor,
                                          maxBulletLines: compact ? 1 : 2,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        _ClassicContentSection(
                          title: 'EDUCATION',
                          borderColor: sectionBorderColor,
                          child: education.isEmpty
                              ? Text(
                                  'Add your education details.',
                                  style: bodyStyle.copyWith(color: mutedColor),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final item in education)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: compact ? 6 : 8,
                                        ),
                                        child: _ClassicEducationBlock(
                                          item: item,
                                          bodyStyle: bodyStyle,
                                          mutedColor: mutedColor,
                                          compact: compact,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        if (!compact && projects.isNotEmpty)
                          _ClassicContentSection(
                            title: 'PROJECTS',
                            borderColor: sectionBorderColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final item in projects)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _ClassicProjectBlock(
                                      item: item,
                                      bodyStyle: bodyStyle,
                                      mutedColor: mutedColor,
                                      bulletColor: titleColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (!compact)
                          for (final section in remainingCustomSections.take(2))
                            _ClassicContentSection(
                              title: section.title.trim().toUpperCase(),
                              borderColor: sectionBorderColor,
                              child: _ClassicCustomSectionBlock(
                                item: section,
                                bodyStyle: bodyStyle,
                                mutedColor: mutedColor,
                                bulletColor: titleColor,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClassicSidebarAvatarPlaceholder extends StatelessWidget {
  const _ClassicSidebarAvatarPlaceholder({
    required this.resume,
    required this.fontSize,
  });

  final ResumeData resume;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: resume.classicSidebarAvatarFillColor),
      child: Center(
        child: Text(
          _pdfAlignedInitials(resume),
          style: TextStyle(
            color: resume.classicSidebarTitleColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ClassicSidebarListSection extends StatelessWidget {
  const _ClassicSidebarListSection({
    required this.title,
    required this.items,
    required this.bulletColor,
    required this.textStyle,
    this.maxLines = 2,
  });

  final String title;
  final List<String> items;
  final Color bulletColor;
  final TextStyle textStyle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textStyle.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (visibleItems.isEmpty)
          Text('Add items', style: textStyle)
        else
          for (final item in visibleItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: textStyle.copyWith(
                      color: bulletColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _ClassicContentSection extends StatelessWidget {
  const _ClassicContentSection({
    required this.title,
    required this.borderColor,
    required this.child,
  });

  final String title;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: ResumeTypography.darkHeaderSectionTitlePt,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: _ClassicSidebarPreview._sectionHeadingGap),
            child,
          ],
        ),
      ),
    );
  }
}

class _ClassicExperienceBlock extends StatelessWidget {
  const _ClassicExperienceBlock({
    required this.item,
    required this.bodyStyle,
    required this.mutedColor,
    required this.bulletColor,
    this.maxBulletLines = 2,
  });

  final WorkExperience item;
  final TextStyle bodyStyle;
  final Color mutedColor;
  final Color bulletColor;
  final int maxBulletLines;

  @override
  Widget build(BuildContext context) {
    final bullets = _workBulletLines(item).take(2).toList();
    final dates = [
      item.startDate.trim(),
      item.endDate.trim(),
    ].where((value) => value.isNotEmpty).join(' - ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.role.ifBlank('Role')}, ${item.company.ifBlank('Company')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
        ),
        if (dates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(dates, style: bodyStyle.copyWith(color: mutedColor)),
          ),
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 5),
          _ClassicBulletList(
            items: bullets,
            textStyle: bodyStyle.copyWith(color: bodyStyle.color),
            bulletColor: bulletColor,
            maxLines: maxBulletLines,
          ),
        ],
      ],
    );
  }
}

class _ClassicEducationBlock extends StatelessWidget {
  const _ClassicEducationBlock({
    required this.item,
    required this.bodyStyle,
    required this.mutedColor,
    this.compact = false,
  });

  final EducationItem item;
  final TextStyle bodyStyle;
  final Color mutedColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dates = [
      item.startDate.trim(),
      item.endDate.trim(),
    ].where((value) => value.isNotEmpty).join(' - ');
    final details = item.score.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.degree.ifBlank('Degree')}, ${item.institution.ifBlank('Institution')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
        ),
        if (dates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(dates, style: bodyStyle.copyWith(color: mutedColor)),
          ),
        if (details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              details,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle.copyWith(color: mutedColor),
            ),
          ),
      ],
    );
  }
}

class _ClassicProjectBlock extends StatelessWidget {
  const _ClassicProjectBlock({
    required this.item,
    required this.bodyStyle,
    required this.mutedColor,
    required this.bulletColor,
  });

  final ProjectItem item;
  final TextStyle bodyStyle;
  final Color mutedColor;
  final Color bulletColor;

  @override
  Widget build(BuildContext context) {
    final bullets = _projectBulletLines(item).take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title.ifBlank('Project'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
        ),
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 4),
          _ClassicBulletList(
            items: bullets,
            textStyle: bodyStyle.copyWith(color: mutedColor),
            bulletColor: bulletColor,
          ),
        ],
      ],
    );
  }
}

class _ClassicCustomSectionBlock extends StatelessWidget {
  const _ClassicCustomSectionBlock({
    required this.item,
    required this.bodyStyle,
    required this.mutedColor,
    required this.bulletColor,
  });

  final CustomSectionItem item;
  final TextStyle bodyStyle;
  final Color mutedColor;
  final Color bulletColor;

  @override
  Widget build(BuildContext context) {
    if (item.layoutMode == CustomSectionLayoutMode.bullets) {
      return _ClassicBulletList(
        items: item.bullets.take(3).toList(),
        textStyle: bodyStyle.copyWith(color: mutedColor),
        bulletColor: bulletColor,
      );
    }
    return Text(
      item.content.trim().ifBlank('Add content'),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: bodyStyle.copyWith(color: mutedColor),
    );
  }
}

class _ClassicBulletList extends StatelessWidget {
  const _ClassicBulletList({
    required this.items,
    required this.textStyle,
    required this.bulletColor,
    this.maxLines = 2,
  });

  final List<String> items;
  final TextStyle textStyle;
  final Color bulletColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in visibleItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: textStyle.copyWith(
                    color: bulletColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

List<Widget> _classicSidebarContactRows(
  ResumeData resume, {
  required Color mutedColor,
  required Color iconColor,
  required TextStyle baseStyle,
  int maxItems = 4,
}) {
  final rows = <({IconData icon, String text})>[
    if (resume.email.trim().isNotEmpty)
      (icon: Icons.email_rounded, text: resume.email.trim()),
    if (resume.location.trim().isNotEmpty)
      (icon: Icons.place_rounded, text: resume.location.trim()),
    if (resume.phone.trim().isNotEmpty)
      (icon: Icons.call_rounded, text: resume.phone.trim()),
    if (resume.website.trim().isNotEmpty)
      (icon: Icons.language_rounded, text: resume.website.trim()),
  ];

  return rows
      .take(maxItems)
      .map(
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(row.icon, size: 11, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  row.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: baseStyle.copyWith(color: mutedColor),
                ),
              ),
            ],
          ),
        ),
      )
      .toList();
}

CustomSectionItem? _classicSidebarLanguagesSection(ResumeData resume) {
  for (final item in resume.visibleCustomSections) {
    if (item.title.trim().toLowerCase() == 'languages') {
      return item;
    }
  }
  return null;
}

List<String> _classicSidebarLanguages(ResumeData resume) {
  final section = _classicSidebarLanguagesSection(resume);
  if (section == null) {
    return const <String>[];
  }
  if (section.layoutMode == CustomSectionLayoutMode.bullets) {
    return section.bullets.where((item) => item.trim().isNotEmpty).toList();
  }
  return section.content
      .split(RegExp(r'[\n,]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<CustomSectionItem> _classicSidebarMainCustomSections(ResumeData resume) {
  final languages = _classicSidebarLanguagesSection(resume);
  var skippedLanguages = false;
  return resume.visibleCustomSections.where((item) {
    if (!skippedLanguages && identical(item, languages)) {
      skippedLanguages = true;
      return false;
    }
    return true;
  }).toList();
}

class _CreativeSidebarHeading extends StatelessWidget {
  const _CreativeSidebarHeading({required this.title, required this.lineColor});

  final String title;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
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
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1.1, color: lineColor)),
      ],
    );
  }
}

class _CreativeSidebarMetaItem extends StatelessWidget {
  const _CreativeSidebarMetaItem({
    required this.text,
    required this.iconColor,
    required this.style,
  });

  final String text;
  final Color iconColor;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 4, right: 6),
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
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
  final legacy = [
    item.overview.trim(),
    item.impact.trim(),
  ].where((part) => part.isNotEmpty).toList();
  return legacy;
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
