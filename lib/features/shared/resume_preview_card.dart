import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/corporate_resume_style.dart';
import '../../core/models/resume_models.dart';
import '../../core/resume_font_weight.dart';
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
    this.scrollable = true,
    this.showAllContent = false,
  });

  final ResumeData resume;
  final bool showDebugLabel;

  /// When false (template thumbnails), content scales to fit instead of scrolling.
  final bool scrollable;

  /// When true, lists are not truncated for template previews.
  final bool showAllContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewTemplate = resume.template.userFacingTemplate;
    final base = theme.textTheme;
    final ff = ResumeTextFont.inter.flutterFontFamily;
    final onSurface = theme.colorScheme.onSurface;
    final bodyPx = resume.effectiveBodyFontPt.toDouble();
    final resumeBodyTheme = theme.copyWith(
      textTheme: base
          .apply(fontFamily: ff, bodyColor: onSurface, displayColor: onSurface)
          .copyWith(
            bodyLarge: base.bodyLarge?.copyWith(
              fontFamily: ff,
              fontSize: bodyPx,
              height: ResumeTypography.bodyTextLineHeight,
            ),
            bodyMedium: base.bodyMedium?.copyWith(
              fontFamily: ff,
              fontSize: bodyPx,
              height: ResumeTypography.bodyTextLineHeight,
            ),
            bodySmall: base.bodySmall?.copyWith(
              fontFamily: ff,
              fontSize: bodyPx,
              height: ResumeTypography.bodyTextLineHeight,
            ),
            titleSmall: base.titleSmall?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
              height: ResumeTypography.bodyTextLineHeight,
            ),
            titleMedium: base.titleMedium?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
              height: ResumeTypography.bodyTextLineHeight,
            ),
            titleLarge: base.titleLarge?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
              height: ResumeTypography.bodyTextLineHeight,
            ),
            headlineSmall: base.headlineSmall?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
              height: ResumeTypography.bodyTextLineHeight,
            ),
            headlineMedium: base.headlineMedium?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
              height: ResumeTypography.bodyTextLineHeight,
            ),
            labelLarge: base.labelLarge?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
              height: ResumeTypography.bodyTextLineHeight,
            ),
          ),
    );

    final preview = switch (previewTemplate) {
      ResumeTemplate.corporate => _DarkHeaderPreview(
        resume: resume,
        scrollable: scrollable,
        showAllContent: showAllContent,
      ),
      ResumeTemplate.creative => _CreativePreview(
        resume: resume,
        showAllContent: showAllContent,
      ),
      ResumeTemplate.classicSidebar => _ClassicSidebarPreview(resume: resume),
      ResumeTemplate.detailsSidebar => _DetailsSidebarPreview(
        resume: resume,
      ),
      ResumeTemplate.atsStructured => _AtsStructuredPreview(resume: resume),
      ResumeTemplate.atsSerifRules => _AtsSerifRulesPreview(resume: resume),
      ResumeTemplate.atsModernFlow => _AtsModernFlowPreview(resume: resume),
      ResumeTemplate.atsExecutive => _AtsExecutivePreview(resume: resume),
      ResumeTemplate.atsCenterClassic => _AtsCenterClassicPreview(
        resume: resume,
      ),
      ResumeTemplate.atsProfessionalBlue => _AtsProfessionalBluePreview(
        resume: resume,
      ),
    };

    // Template thumbnails only constrain width; [Positioned.fill] needs a
    // bounded height and would collapse to zero here.
    if (!scrollable) {
      return Theme(data: resumeBodyTheme, child: preview);
    }

    return Theme(
      data: resumeBodyTheme,
      child: Stack(
        children: [
          Positioned.fill(child: preview),
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

  static const bodyHeight = ResumeTypography.darkHeaderBodyLineHeight;

  static double headerAvatar() => 95;

  static double headerNameSize() => ResumeTypography.darkHeaderNamePt;

  static const String calibriFamily = 'Calibri';

  static const headerAfterAvatar = 25.0;
  static const afterHeader = 18.0;

  /// Keep this aligned with [ResumeTypography.darkHeaderSectionGapPreviewPx].
  static EdgeInsets sectionOuter() => const EdgeInsets.fromLTRB(
    ResumeTypography.corporateBodyHorizontalInset,
    0,
    ResumeTypography.corporateBodyHorizontalInset,
    ResumeTypography.darkHeaderSectionGapPreviewPx,
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
  const _DarkHeaderPreview({
    required this.resume,
    this.scrollable = true,
    this.showAllContent = false,
  });

  final ResumeData resume;
  final bool scrollable;
  final bool showAllContent;
  static const double _darkHeaderExtraLineSpacingPx = 0.0;

  /// Extra space at end of template thumbnails (not in PDF export).
  static const double _templatePreviewBottomMargin = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _pdfAlignedDisplayName(resume);
    final contactLines = _darkHeaderContactLines(
      _pdfAlignedContactItems(resume),
    );
    final skills = _pdfAlignedSkills(resume);
    final onSurface = theme.colorScheme.onSurface;
    final bodyFontPx = resume.effectiveBodyFontPt.toDouble();
    final preset = resume.corporateColorPreset;
    final headerOnColor = preset.headerOnColor;
    final headerBorderColor = preset.headerBorderColor;
    final bodyLineHeight = ResumeTypography.darkHeaderBodyLineHeight +
        (_darkHeaderExtraLineSpacingPx / bodyFontPx);
    final nameLineHeight =
        1.05 +
        (_darkHeaderExtraLineSpacingPx / ResumeTypography.darkHeaderNamePt);
    final bodyStyle = ResumeTypography.interPreviewStyle(
      weight: ResumeTypography.darkHeaderBodyWeight,
      fontSize: bodyFontPx,
      height: bodyLineHeight,
      color: onSurface,
    );
    final contactStyle = ResumeTypography.interPreviewStyle(
      weight: ResumeTypography.darkHeaderContactWeight,
      fontSize: bodyFontPx,
      color: headerOnColor,
      height: ResumeTypography.textLineHeight,
    );
    final subtitleStyle = ResumeTypography.interPreviewStyle(
      weight: ResumeTypography.darkHeaderSubtitleWeight,
      fontSize: ResumeTypography.darkHeaderSubtitlePt,
      color: ResumeTypography.darkHeaderSubtitleColor,
      height: ResumeTypography.textLineHeight,
    );

    const headerPadding = EdgeInsets.fromLTRB(
      ResumeTypography.corporateHeaderHorizontalInset,
      28,
      ResumeTypography.corporateHeaderHorizontalInset,
      26,
    );
    final avatarTopOffset = 0.0;
    final nameLabelTopOffset = 0.0;
    final nameToContactSpacing = 8.0;
    const defaultTextLineHeight = ResumeTypography.textLineHeight;

    final workExperiences = showAllContent
        ? resume.visibleWorkExperiences
        : resume.visibleWorkExperiences.take(3);
    final educationItems = showAllContent
        ? resume.visibleEducation
        : resume.visibleEducation.take(2);
    final projectItems = showAllContent
        ? resume.visibleProjects
        : resume.visibleProjects.take(2);
    final customSections = showAllContent
        ? resume.visibleCustomSections
        : resume.visibleCustomSections.take(2);

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
                        border: Border.all(
                          color: headerBorderColor,
                          width: 1.9,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _pdfAlignedInitials(resume),
                          style: ResumeTypography.interPreviewStyle(
                            weight: ResumeTypography.darkHeaderInitialsWeight,
                            fontSize: ResumeTypography.darkHeaderInitialsPt,
                            color: headerOnColor,
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
                          style: ResumeTypography.interPreviewStyle(
                            weight: ResumeTypography.darkHeaderNameWeight,
                            fontSize: ResumeTypography.darkHeaderNamePt,
                            color: headerOnColor,
                            height: nameLineHeight,
                            letterSpacing: 0.15,
                          ),
                        ),
                        if (contactLines.isNotEmpty) ...[
                          SizedBox(height: nameToContactSpacing),
                          for (
                            var index = 0;
                            index < contactLines.length;
                            index++
                          )
                            Padding(
                              padding: EdgeInsets.only(top: index == 0 ? 0 : 3),
                              child: Text(
                                contactLines[index],
                                style: contactStyle,
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
                for (final item in workExperiences)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: _CorporatePdfMetrics.experienceBlockBottom,
                    ),
                    child: _CorporateExperienceBlock(
                      item: item,
                      dateColor: _CorporatePdfMetrics.dateMutedColor,
                      bodyStyle: bodyStyle,
                      subtitleStyle: subtitleStyle,
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
                for (final item in educationItems)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: _CorporatePdfMetrics.educationBlockBottom,
                    ),
                    child: _CorporateEducationBlock(
                      item: item,
                      bodyStyle: bodyStyle,
                      subtitleStyle: subtitleStyle,
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
                for (final item in projectItems)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: _CorporatePdfMetrics.projectBlockBottom,
                    ),
                    child: _CorporateProjectBlock(
                      item: item,
                      bodyStyle: bodyStyle,
                      subtitleStyle: subtitleStyle,
                    ),
                  ),
              ],
            ),
          ),
        for (final item in customSections)
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(),
            title: item.title.ifBlank('Custom section').toUpperCase(),
            titleColor: preset.titleColor,
            lineColor: _CorporatePdfMetrics.lineColor,
            child: _corporateCustomSectionBody(item, bodyStyle),
          ),
        SizedBox(
          height: scrollable ? 10 : _templatePreviewBottomMargin,
        ),
      ],
    );

    final merged = DefaultTextStyle.merge(
      style: TextStyle(height: defaultTextLineHeight),
      child: content,
    );

    if (!scrollable) {
      return merged;
    }

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
            style: ResumeTypography.interPreviewStyle(
              weight: ResumeTypography.darkHeaderSectionTitleWeight,
              fontSize: ResumeTypography.darkHeaderSectionTitlePt,
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
    required this.subtitleStyle,
  });

  final WorkExperience item;
  final Color dateColor;
  final TextStyle bodyStyle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
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
                style: subtitleStyle,
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
  const _CorporateEducationBlock({
    required this.item,
    required this.bodyStyle,
    required this.subtitleStyle,
  });

  final EducationItem item;
  final TextStyle bodyStyle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
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
          style: subtitleStyle.copyWith(height: 1.0),
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
  const _CorporateProjectBlock({
    required this.item,
    required this.bodyStyle,
    required this.subtitleStyle,
  });

  final ProjectItem item;
  final TextStyle bodyStyle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title.ifBlank('Project'),
          style: subtitleStyle,
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
  const _CreativePreview({
    required this.resume,
    this.showAllContent = false,
  });

  final ResumeData resume;
  final bool showAllContent;
  static const double _avatarBackgroundOpacity = 0.4;
  static const double _avatarWidth = 138.0;
  static const double _avatarHeight = 161.0;

  @override
  Widget build(BuildContext context) {
    final railColor = resume.creativeRailColor;
    final accentColor = resume.creativeAccentColor;
    final avatarBackgroundColor = resume.creativeAvatarBackgroundColor;
    final textColor = resume.creativeTitleColor;
    final lineColor = resume.creativeLineColor;
    const bodyTextColor = ResumeTypography.creativeBodyTextColor;
    final bodyPt = resume.creativeScaledPt(ResumeTypography.creativeBodyPt);
    final subtitlePt =
        resume.creativeScaledPt(ResumeTypography.creativeSubtitlePt);
    final namePt = resume.creativeScaledPt(ResumeTypography.creativeNamePt);
    final sectionTitlePt =
        resume.creativeScaledPt(ResumeTypography.creativeSectionTitlePt);
    final bodyStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.creativeBodyWeight,
      fontSize: bodyPt,
      color: bodyTextColor,
      height: ResumeTypography.creativeBodyLineHeight,
    );
    final subtitleStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.creativeSubtitleWeight,
      fontSize: subtitlePt,
      color: bodyTextColor,
      height: ResumeTypography.creativeBodyLineHeight,
    );
    final sidebarStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.creativeSidebarContentWeight,
      fontSize: bodyPt,
      color: bodyTextColor,
      height: ResumeTypography.creativeBodyLineHeight,
    );
    final summary = resume.summary.trim();
    final allSkills = _pdfAlignedSkills(resume);
    final skills = allSkills.length > 2
        ? allSkills.sublist(0, allSkills.length - 2)
        : const <String>[];
    final experiences = showAllContent
        ? resume.visibleWorkExperiences
        : resume.visibleWorkExperiences.take(2).toList();
    final education = showAllContent
        ? resume.visibleEducation
        : resume.visibleEducation.take(2).toList();
    final projects = showAllContent
        ? resume.visibleProjects
        : resume.visibleProjects.take(1).toList();
    final customSections = showAllContent
        ? resume.visibleCustomSections
        : const <CustomSectionItem>[];
    final contacts = _pdfAlignedContactItems(resume).take(4).toList();
    final midpoint = (skills.length / 2).ceil();
    const sectionGap = 20.0;
    const headingGap = 6.0;
    const sidebarDividerGap = 20.0;
    const sidebarRailWidth = 160.0;
    const sidebarContentInset = (sidebarRailWidth - _avatarWidth) / 2;
    const mainContentInset =
        sidebarRailWidth + ResumeTypography.creativeSidebarBodyGap;
    final nameFontSize = namePt;
    final firstProjectLine = projects.isNotEmpty
        ? (_projectBulletLines(projects.first).isNotEmpty
              ? _projectBulletLines(projects.first).first
              : 'Add project details.')
        : '';
    final summaryMaxLines = showAllContent ? null : 5;

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
            left: 0,
            top: 0,
            child: SizedBox(
              width: sidebarRailWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: ResumeTypography.creativeSidebarImageTopPadding,
                  ),
                  Center(
                    child: _CreativeProfileAvatar(
                      resume: resume,
                      width: _avatarWidth,
                      height: _avatarHeight,
                      accentColor: accentColor,
                      backgroundColor: avatarBackgroundColor,
                      backgroundOpacity: _avatarBackgroundOpacity,
                      initialsFontSize: namePt * 1.15,
                    ),
                  ),
                  if (contacts.isNotEmpty) ...[
                    const SizedBox(height: sectionGap),
                    Center(
                      child: Container(
                        width: _avatarWidth,
                        height: 1.1,
                        color: lineColor,
                      ),
                    ),
                    const SizedBox(height: sidebarDividerGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: sidebarContentInset,
                      ),
                      child: Column(
                        children: [
                          for (final line in contacts)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _CreativeSidebarMetaItem(
                                text: line,
                                iconColor: accentColor,
                                style: sidebarStyle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: mainContentInset,
              top: ResumeTypography.creativeBodyTopMargin,
              right: ResumeTypography.creativeMainColumnRightInset,
              bottom: ResumeTypography.creativeBodyBottomMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pdfAlignedDisplayName(resume).toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle.copyWith(
                          fontSize: nameFontSize,
                          fontWeight: ResumeFontWeight.toFlutter(
                            ResumeTypography.creativeNameWeight,
                          ),
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
                          style: subtitleStyle.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: sectionGap),
                      _CreativeSidebarHeading(
                        title: 'SUMMARY',
                        lineColor: lineColor,
                        sectionTitlePt: sectionTitlePt,
                      ),
                      const SizedBox(height: headingGap),
                      Text(
                        summary.ifBlank(
                          'Add a short summary to position your experience and strengths.',
                        ),
                        maxLines: summaryMaxLines,
                        overflow: summaryMaxLines == null
                            ? null
                            : TextOverflow.ellipsis,
                        style: bodyStyle,
                      ),
                      const SizedBox(height: sectionGap),
                      _CreativeSidebarHeading(
                        title: 'EXPERIENCE',
                        lineColor: lineColor,
                        sectionTitlePt: sectionTitlePt,
                      ),
                      const SizedBox(height: headingGap),
                      if (experiences.isNotEmpty)
                        ...experiences.map((item) {
                          final bullets = _workBulletLines(item);
                          final dateLabel = _creativeExperienceDateRange(
                            item.startDate,
                            item.endDate,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: RichText(
                                        maxLines: showAllContent ? null : 2,
                                        overflow: showAllContent
                                            ? TextOverflow.clip
                                            : TextOverflow.ellipsis,
                                        text: TextSpan(
                                          style: subtitleStyle,
                                          children: [
                                            TextSpan(
                                              text: item.role
                                                  .ifBlank('Role')
                                                  .toUpperCase(),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' / ${item.company.ifBlank('Company')}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (dateLabel.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        dateLabel,
                                        maxLines: showAllContent ? null : 1,
                                        overflow: showAllContent
                                            ? null
                                            : TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                        style: bodyStyle.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                _CreativeBulletColumn(
                                  items: showAllContent
                                      ? bullets
                                      : bullets.take(1).toList(),
                                  bodyStyle: bodyStyle,
                                  maxLines: showAllContent ? null : 1,
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        Text(
                          'Add your work experience details.',
                          style: bodyStyle,
                        ),
                      if (education.isNotEmpty) ...[
                        const SizedBox(height: sectionGap),
                        _CreativeSidebarHeading(
                          title: 'EDUCATION',
                          lineColor: lineColor,
                          sectionTitlePt: sectionTitlePt,
                        ),
                        const SizedBox(height: headingGap),
                        ...education.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.degree.ifBlank('Degree'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: subtitleStyle,
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      item.institution.ifBlank('Institution'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: bodyStyle,
                                    ),
                                    if (_creativeExperienceDateRange(
                                      item.startDate,
                                      item.endDate,
                                    ).isNotEmpty) ...[
                                      const SizedBox(height: 1.5),
                                      Text(
                                        _creativeExperienceDateRange(
                                          item.startDate,
                                          item.endDate,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: bodyStyle,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: sectionGap),
                      _CreativeSidebarHeading(
                        title: 'SKILLS',
                        lineColor: lineColor,
                        sectionTitlePt: sectionTitlePt,
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
                        sectionTitlePt: sectionTitlePt,
                      ),
                      const SizedBox(height: headingGap),
                      if (projects.isEmpty)
                        Text('Add projects', style: bodyStyle)
                      else if (showAllContent)
                        ...projects.map((item) {
                          final lines = _projectBulletLines(item);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title.ifBlank('Project'),
                                  style: subtitleStyle,
                                ),
                                if (lines.isNotEmpty)
                                  _CreativeBulletColumn(
                                    items: lines,
                                    bodyStyle: bodyStyle,
                                  ),
                              ],
                            ),
                          );
                        })
                      else ...[
                        Text(
                          projects.first.title.ifBlank('Project'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle,
                        ),
                        if (firstProjectLine.isNotEmpty)
                          Text(
                            firstProjectLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle,
                          ),
                      ],
                      for (final section in customSections) ...[
                        const SizedBox(height: sectionGap),
                        _CreativeSidebarHeading(
                          title: section.title.ifBlank('Custom Section'),
                          lineColor: lineColor,
                          sectionTitlePt: sectionTitlePt,
                        ),
                        const SizedBox(height: headingGap),
                        if (section.layoutMode == CustomSectionLayoutMode.bullets)
                          _CreativeBulletColumn(
                            items: section.bullets
                                .where((b) => b.trim().isNotEmpty)
                                .toList(),
                            bodyStyle: bodyStyle,
                          )
                        else
                          Text(
                            section.content.trim(),
                            style: bodyStyle,
                          ),
                      ],
                    ],
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

  static const double _sidebarWidth = 122;
  static const double _avatarSize = 114;
  static const double _sectionGap = 12;

  /// Matches PDF `_classicSidebarSectionBottomPt` spacing before section titles.
  static const double _sectionBlockTopGap = 8;
  static const double _sectionDividerGap = 8;
  static const double _sectionHeadingGap = 6;
  static const double _mainColumnTopPadding = 22;
  static const double _mainColumnBottomPadding = 10;

  @override
  Widget build(BuildContext context) {
    final railColor = resume.classicSidebarRailColor;
    final accentColor = resume.classicSidebarAccentColor;
    final titleColor = resume.classicSidebarTitleColor;
    final mutedColor = resume.classicSidebarMutedColor;
    final dividerColor = resume.classicSidebarDividerColor;
    final sectionBorderColor = resume.classicSidebarSectionBorderColor;
    final bodyPt =
        resume.classicSidebarScaledPt(ResumeTypography.classicSidebarBodyPt);
    final subtitlePt =
        resume.classicSidebarScaledPt(ResumeTypography.classicSidebarSubtitlePt);
    final namePt =
        resume.classicSidebarScaledPt(ResumeTypography.classicSidebarNamePt);
    final sectionTitlePt = resume.classicSidebarScaledPt(
      ResumeTypography.classicSidebarSectionTitlePt,
    );
    final bodyStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.classicSidebarBodyWeight,
      fontSize: bodyPt,
      color: ResumeTypography.classicSidebarBodyTextColor,
      height: ResumeTypography.classicSidebarBodyLineHeight,
    );
    final subtitleStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.classicSidebarSubtitleWeight,
      fontSize: subtitlePt,
      color: ResumeTypography.classicSidebarBodyTextColor,
      height: ResumeTypography.classicSidebarBodyLineHeight,
    );
    final sidebarStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.classicSidebarSidebarContentWeight,
      fontSize: bodyPt,
      color: ResumeTypography.classicSidebarBodyTextColor,
      height: ResumeTypography.classicSidebarBodyLineHeight,
    );
    final sectionTitleStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.classicSidebarSectionTitleWeight,
      fontSize: sectionTitlePt,
      color: titleColor,
      height: ResumeTypography.classicSidebarBodyLineHeight,
      letterSpacing: 0.2,
    );
    final nameStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.classicSidebarNameWeight,
      fontSize: namePt,
      color: titleColor,
      height: 1,
      letterSpacing: 0.2,
    );
    final avatarInitialsPt =
        ResumeTypography.classicSidebarAvatarInitialsFontPt(namePt);
    final experiences = resume.visibleWorkExperiences.take(2).toList();
    final education = resume.visibleEducation.take(2).toList();
    final projects = resume.visibleProjects.take(2).toList();
    final skills = _pdfAlignedSkills(resume).take(5).toList();
    final languages = _classicSidebarLanguages(resume).take(4).toList();
    final remainingCustomSections = _classicSidebarMainCustomSections(resume);
    final avatarPath = resume.profileImagePath.trim();
    final hasProfileImage =
        avatarPath.isNotEmpty && File(avatarPath).existsSync();

    return DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: 'Calibri'),
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: _sidebarWidth,
          color: railColor,
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
          child: DefaultTextStyle(
            style: sidebarStyle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipOval(
                    child: SizedBox(
                      width: _avatarSize,
                      height: _avatarSize,
                      child: hasProfileImage
                          ? Image.file(
                              File(avatarPath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _ClassicSidebarAvatarPlaceholder(
                                    resume: resume,
                                    fontSize: avatarInitialsPt,
                                    textStyle: nameStyle.copyWith(
                                      color: titleColor,
                                      fontSize: avatarInitialsPt,
                                    ),
                                  ),
                            )
                          : _ClassicSidebarAvatarPlaceholder(
                              resume: resume,
                              fontSize: avatarInitialsPt,
                              textStyle: nameStyle.copyWith(
                                color: titleColor,
                                fontSize: avatarInitialsPt,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: _sectionGap),
                Container(height: 1.1, color: dividerColor),
                const SizedBox(height: 10),
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
                          titleStyle: sectionTitleStyle,
                          textStyle: bodyStyle,
                          maxLines: 2,
                          headingGap: 14,
                          itemGap: 14,
                        ),
                        if (languages.isNotEmpty) ...[
                          SizedBox(height: _sectionGap),
                          Container(height: 1.1, color: dividerColor),
                          const SizedBox(height: 10),
                          _ClassicSidebarListSection(
                            title: 'LANGUAGES',
                            items: languages,
                            bulletColor: accentColor,
                            titleStyle: sectionTitleStyle,
                            textStyle: bodyStyle,
                            maxLines: 1,
                            headingGap: 8,
                            itemGap: 8,
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
            padding: const EdgeInsets.fromLTRB(
              12,
              _mainColumnTopPadding,
              12,
              _mainColumnBottomPadding,
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
                      style: nameStyle,
                    ),
                    if (resume.jobTitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        resume.jobTitle.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle.copyWith(
                          color: mutedColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    ..._classicSidebarContactRows(
                      resume,
                      mutedColor: mutedColor,
                      iconColor: titleColor,
                      baseStyle: sidebarStyle.copyWith(color: mutedColor),
                      maxItems: 6,
                    ),
                    const SizedBox(height: 10),
                    _ClassicContentSection(
                      title: 'SUMMARY',
                      titleStyle: sectionTitleStyle,
                      child: Text(
                        resume.summary.trim().ifBlank(
                          'Add a short summary to position your experience and strengths.',
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle,
                      ),
                    ),
                    _ClassicContentSection(
                      title: 'EXPERIENCE',
                      titleStyle: sectionTitleStyle,
                      topDividerColor: sectionBorderColor,
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
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ClassicExperienceBlock(
                                      item: item,
                                      bodyStyle: bodyStyle,
                                      subtitleStyle: subtitleStyle,
                                      bulletColor: titleColor,
                                      maxBulletLines: 2,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    _ClassicContentSection(
                      title: 'EDUCATION',
                      titleStyle: sectionTitleStyle,
                      topDividerColor: sectionBorderColor,
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
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _ClassicEducationBlock(
                                      item: item,
                                      bodyStyle: bodyStyle,
                                      subtitleStyle: subtitleStyle,
                                      mutedColor: mutedColor,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    if (projects.isNotEmpty)
                      _ClassicContentSection(
                        title: 'PROJECTS',
                        titleStyle: sectionTitleStyle,
                        topDividerColor: sectionBorderColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in projects)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ClassicProjectBlock(
                                  item: item,
                                  bodyStyle: bodyStyle,
                                  subtitleStyle: subtitleStyle,
                                  mutedColor: mutedColor,
                                  bulletColor: titleColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    for (final section in remainingCustomSections.take(2))
                      _ClassicContentSection(
                        title: section.title.trim().toUpperCase(),
                        titleStyle: sectionTitleStyle,
                        topDividerColor: sectionBorderColor,
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
    ),
    );
  }
}

class _DetailsSidebarPreview extends StatelessWidget {
  const _DetailsSidebarPreview({required this.resume});

  final ResumeData resume;

  static const double _sidebarWidth = 128;
  static const double _sectionGap = 18;

  @override
  Widget build(BuildContext context) {
    final railColor = resume.detailsSidebarRailColor;
    final accentColor = resume.detailsSidebarAccentColor;
    final titleColor = resume.detailsSidebarTitleColor;
    final mutedColor = resume.detailsSidebarMutedColor;
    final dividerColor = resume.detailsSidebarDividerColor;
    final bodySize = resume.effectiveBodyFontPt.toDouble();
    final bodyStyle = TextStyle(
      color: titleColor,
      fontSize: bodySize,
      height: ResumeTypography.textLineHeight,
    );
    final skills = _pdfAlignedSkills(resume).take(7).toList();
    final projects = resume.visibleProjects.take(2).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: _sidebarWidth,
          color: railColor,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: DefaultTextStyle(
            style: bodyStyle.copyWith(color: mutedColor),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pdfAlignedDisplayName(resume).toUpperCase(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle.copyWith(
                      color: titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                    ),
                  ),
                  if (resume.jobTitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      resume.jobTitle.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle.copyWith(
                        color: titleColor,
                        fontSize: bodyStyle.fontSize! + 0.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _DetailsSidebarRailSectionHeading(
                    title: 'DETAILS',
                    titleColor: titleColor,
                    dividerColor: dividerColor,
                  ),
                  const SizedBox(height: 10),
                  ..._detailsSidebarPreviewInfoRows(
                    resume,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    baseStyle: bodyStyle.copyWith(
                      color: mutedColor,
                      fontSize: bodyStyle.fontSize! - 0.2,
                    ),
                  ),
                  SizedBox(height: _sectionGap),
                  _DetailsSidebarRailSectionHeading(
                    title: 'SKILLS',
                    titleColor: titleColor,
                    dividerColor: dividerColor,
                  ),
                  const SizedBox(height: 10),
                  if (skills.isEmpty)
                    Text(
                      'Add skills',
                      style: bodyStyle.copyWith(color: mutedColor),
                    )
                  else
                    _ClassicBulletList(
                      items: skills,
                      textStyle: bodyStyle.copyWith(color: titleColor),
                      bulletColor: accentColor,
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: DefaultTextStyle(
              style: bodyStyle.copyWith(color: mutedColor),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailsSidebarContentSection(
                      title: 'SUMMARY',
                      titleColor: titleColor,
                      dividerColor: dividerColor,
                      child: Text(
                        resume.summary.trim().ifBlank(
                          'Add a short summary to position your experience and strengths.',
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle.copyWith(color: titleColor),
                      ),
                    ),
                    _DetailsSidebarContentSection(
                      title: 'EXPERIENCE',
                      titleColor: titleColor,
                      dividerColor: dividerColor,
                      child: resume.visibleWorkExperiences.isEmpty
                          ? Text(
                              'Add your work experience details.',
                              style: bodyStyle.copyWith(color: mutedColor),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final item
                                    in resume.visibleWorkExperiences.take(2))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _DetailsSidebarExperienceBlock(
                                      item: item,
                                      bodyStyle: bodyStyle,
                                      titleColor: titleColor,
                                      mutedColor: mutedColor,
                                      bulletColor: titleColor,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    _DetailsSidebarContentSection(
                      title: 'EDUCATION',
                      titleColor: titleColor,
                      dividerColor: dividerColor,
                      child: resume.visibleEducation.isEmpty
                          ? Text(
                              'Add your education details.',
                              style: bodyStyle.copyWith(color: mutedColor),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final item in resume.visibleEducation.take(
                                  2,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _DetailsSidebarEducationBlock(
                                      item: item,
                                      bodyStyle: bodyStyle,
                                      titleColor: titleColor,
                                      mutedColor: mutedColor,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    if (projects.isNotEmpty)
                      _DetailsSidebarContentSection(
                        title: 'PROJECTS',
                        titleColor: titleColor,
                        dividerColor: dividerColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in projects)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DetailsSidebarProjectBlock(
                                  item: item,
                                  bodyStyle: bodyStyle,
                                  titleColor: titleColor,
                                  mutedColor: mutedColor,
                                  bulletColor: titleColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    for (final section in resume.visibleCustomSections.take(2))
                      _DetailsSidebarContentSection(
                        title: section.title.trim().toUpperCase(),
                        titleColor: titleColor,
                        dividerColor: dividerColor,
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
  }
}

/// Fixed type scale for ATS template previews (in-app card only).
const double _atsPreviewNameFontSize = 24;
const double _atsPreviewTitleFontSize = 18;

class _AtsStructuredPreview extends StatelessWidget {
  const _AtsStructuredPreview({required this.resume});

  final ResumeData resume;

  static const Color _band = Color(0xFFE6E6E6);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final body = resume.effectiveBodyFontPt.toDouble();
    final style = TextStyle(
      color: onSurface,
      fontSize: body,
      height: ResumeTypography.textLineHeight,
    );
    final contact = _atsPreviewContactLines(resume);

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: _CorporatePdfMetrics.sectionOuter(),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _pdfAlignedDisplayName(resume).toUpperCase(),
                textAlign: TextAlign.center,
                style: style.copyWith(
                  fontSize: _atsPreviewNameFontSize,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (resume.jobTitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  resume.jobTitle.trim(),
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                    fontSize: _atsPreviewTitleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (contact.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final line in contact)
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    style: style.copyWith(fontSize: body - 0.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
              const SizedBox(height: 8),
              Container(height: 1, color: onSurface.withValues(alpha: 0.85)),
              const SizedBox(height: 10),
              _atsBandTitle('SUMMARY'),
              const SizedBox(height: 6),
              Text(
                resume.summary.trim().ifBlank(
                  'Concise summary tailored to your target roles.',
                ),
                style: style,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _atsBandTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: _band,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _AtsSerifRulesPreview extends StatelessWidget {
  const _AtsSerifRulesPreview({required this.resume});

  final ResumeData resume;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final body = resume.effectiveBodyFontPt.toDouble();
    final style = TextStyle(
      color: onSurface,
      fontSize: body,
      height: ResumeTypography.textLineHeight,
    );

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: _CorporatePdfMetrics.sectionOuter(),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pdfAlignedDisplayName(resume),
                          style: style.copyWith(
                            fontSize: _atsPreviewNameFontSize,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (resume.jobTitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            resume.jobTitle.trim(),
                            style: style.copyWith(
                              fontSize: _atsPreviewTitleFontSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        if (resume.location.trim().isNotEmpty)
                          Text(resume.location.trim(), style: style),
                        if (resume.phone.trim().isNotEmpty)
                          Text(resume.phone.trim(), style: style),
                      ],
                    ),
                  ),
                  if (resume.email.trim().isNotEmpty)
                    Text(
                      resume.email.trim(),
                      style: style.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: body - 0.5,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Summary',
                style: style.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Container(height: 1, color: onSurface.withValues(alpha: 0.35)),
              const SizedBox(height: 6),
              Text(
                resume.summary.trim().ifBlank(
                  'Two to four sentences on scope and impact.',
                ),
                style: style,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtsModernFlowPreview extends StatelessWidget {
  const _AtsModernFlowPreview({required this.resume});

  final ResumeData resume;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final body = resume.effectiveBodyFontPt.toDouble();
    final style = TextStyle(
      color: onSurface,
      fontSize: body,
      height: ResumeTypography.textLineHeight,
    );
    final parts = <String>[
      if (resume.location.trim().isNotEmpty) resume.location.trim(),
      if (resume.email.trim().isNotEmpty) resume.email.trim(),
      if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
    ];

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: _CorporatePdfMetrics.sectionOuter(),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _pdfAlignedDisplayName(resume),
                textAlign: TextAlign.center,
                style: style.copyWith(
                  fontSize: _atsPreviewNameFontSize,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (resume.jobTitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  resume.jobTitle.trim(),
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                    fontSize: _atsPreviewTitleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (parts.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  parts.join('  |  '),
                  textAlign: TextAlign.center,
                  style: style.copyWith(fontSize: body - 0.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Container(height: 1, color: onSurface.withValues(alpha: 0.45)),
              const SizedBox(height: 10),
              Text(
                'Professional Summary',
                style: style.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                resume.summary.trim().ifBlank(
                  'Highlight strengths and domains with measurable outcomes.',
                ),
                style: style,
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtsCenterClassicPreview extends StatelessWidget {
  const _AtsCenterClassicPreview({required this.resume});

  final ResumeData resume;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final body = resume.effectiveBodyFontPt.toDouble();
    final style = TextStyle(
      color: onSurface,
      fontSize: body,
      height: ResumeTypography.textLineHeight,
    );
    final tagline = [
      if (resume.jobTitle.trim().isNotEmpty) resume.jobTitle.trim(),
      ..._pdfAlignedSkills(resume).take(3),
    ].join(' | ');
    final contact = [
      if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
      if (resume.email.trim().isNotEmpty) resume.email.trim(),
      if (resume.location.trim().isNotEmpty) resume.location.trim(),
    ].join(' | ');
    final works = resume.visibleWorkExperiences.take(2).toList();

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: _CorporatePdfMetrics.sectionOuter(),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _pdfAlignedDisplayName(resume),
                textAlign: TextAlign.center,
                style: style.copyWith(
                  fontSize: _atsPreviewNameFontSize,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Georgia',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (tagline.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  tagline,
                  textAlign: TextAlign.center,
                  style: style.copyWith(fontSize: body - 0.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (contact.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  contact,
                  textAlign: TextAlign.center,
                  style: style.copyWith(fontSize: body - 0.75),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Container(height: 1, color: onSurface.withValues(alpha: 0.35)),
              const SizedBox(height: 10),
              Text(
                'SUMMARY',
                style: style.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                resume.summary.trim().ifBlank(
                  'Concise overview of experience and impact.',
                ),
                style: style,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              if (works.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(height: 1, color: onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 10),
                Text(
                  'EXPERIENCE',
                  style: style.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                for (final item in works)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.company.trim().ifBlank('Company'),
                                style: style.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.startDate.trim().isNotEmpty ||
                                item.endDate.trim().isNotEmpty)
                              Text(
                                '${item.startDate.trim()} — ${item.endDate.trim()}',
                                style: style.copyWith(
                                  color: onSurface.withValues(alpha: 0.65),
                                  fontSize: body - 0.5,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          item.role.trim().ifBlank('Role'),
                          style: style,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AtsProfessionalBluePreview extends StatelessWidget {
  const _AtsProfessionalBluePreview({required this.resume});

  final ResumeData resume;

  static const Color _blue = Color(0xFF4A90C4);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final body = resume.effectiveBodyFontPt.toDouble();
    final style = TextStyle(
      color: onSurface,
      fontSize: body,
      height: ResumeTypography.textLineHeight,
    );
    final works = resume.visibleWorkExperiences.take(2).toList();

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: _CorporatePdfMetrics.sectionOuter(),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pdfAlignedDisplayName(resume),
                          style: style.copyWith(
                            color: _blue,
                            fontSize: _atsPreviewNameFontSize,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (resume.jobTitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            resume.jobTitle.trim(),
                            style: style.copyWith(
                              color: _blue,
                              fontWeight: FontWeight.w700,
                              fontSize: _atsPreviewTitleFontSize - 2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (resume.email.trim().isNotEmpty)
                        Text(
                          resume.email.trim(),
                          style: style.copyWith(color: _blue, fontSize: body - 0.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      if (resume.phone.trim().isNotEmpty)
                        Text(
                          resume.phone.trim(),
                          style: style.copyWith(color: _blue, fontSize: body - 0.5),
                        ),
                      if (resume.location.trim().isNotEmpty)
                        Text(
                          resume.location.trim(),
                          style: style.copyWith(color: _blue, fontSize: body - 0.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                resume.summary.trim().ifBlank(
                  'Brief overview of leadership, scope, and results.',
                ),
                style: style,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              if (works.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Professional Experience',
                  style: style.copyWith(
                    color: _blue,
                    fontSize: body + 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                for (final item in works)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.company.trim().ifBlank('Company'),
                                style: style.copyWith(
                                  color: _blue,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.startDate.trim().isNotEmpty ||
                                item.endDate.trim().isNotEmpty)
                              Text(
                                '${item.startDate.trim()} — ${item.endDate.trim()}',
                                style: style.copyWith(color: _blue),
                              ),
                          ],
                        ),
                        Text(
                          item.role.trim().ifBlank('Role'),
                          style: style.copyWith(color: _blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AtsExecutivePreview extends StatelessWidget {
  const _AtsExecutivePreview({required this.resume});

  final ResumeData resume;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final body = resume.effectiveBodyFontPt.toDouble();
    final style = TextStyle(
      color: onSurface,
      fontSize: body,
      height: ResumeTypography.textLineHeight,
    );

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: _CorporatePdfMetrics.sectionOuter(),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (resume.jobTitle.trim().isNotEmpty)
                Text(
                  resume.jobTitle.trim().toUpperCase(),
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                    fontSize: _atsPreviewTitleFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (resume.jobTitle.trim().isNotEmpty) const SizedBox(height: 4),
              Text(
                _pdfAlignedDisplayName(resume),
                textAlign: TextAlign.center,
                style: style.copyWith(
                  fontSize: _atsPreviewNameFontSize,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (resume.location.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  resume.location.trim(),
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ],
              const SizedBox(height: 8),
              Container(height: 1, color: onSurface.withValues(alpha: 0.85)),
              const SizedBox(height: 10),
              Text(
                'SUMMARY',
                style: style.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                resume.summary.trim().ifBlank(
                  'Lead with domains, scope, and measurable results.',
                ),
                style: style,
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _atsPreviewContactLines(ResumeData resume) {
  final email = resume.email.trim();
  final phone = resume.phone.trim();
  final loc = resume.location.trim();
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
  return lines;
}

class _ClassicSidebarAvatarPlaceholder extends StatelessWidget {
  const _ClassicSidebarAvatarPlaceholder({
    required this.resume,
    required this.fontSize,
    this.textStyle,
  });

  final ResumeData resume;
  final double fontSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: resume.classicSidebarAvatarFillColor),
      child: Center(
        child: Text(
          _pdfAlignedInitials(resume),
          style: textStyle ??
              ResumeTypography.calibriPreviewStyle(
                weight: ResumeTypography.classicSidebarNameWeight,
                fontSize: fontSize,
                color: resume.classicSidebarTitleColor,
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
    required this.titleStyle,
    required this.textStyle,
    this.maxLines = 2,
    this.headingGap = 8,
    this.itemGap = 8,
  });

  final String title;
  final List<String> items;
  final Color bulletColor;
  final TextStyle titleStyle;
  final TextStyle textStyle;
  final int maxLines;
  final double headingGap;
  final double itemGap;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        SizedBox(height: headingGap),
        if (visibleItems.isEmpty)
          Text('Add items', style: textStyle)
        else
          for (final item in visibleItems)
            Padding(
              padding: EdgeInsets.only(bottom: itemGap),
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
    required this.titleStyle,
    required this.child,
    this.topDividerColor,
  });

  final String title;
  final TextStyle titleStyle;
  final Widget child;
  final Color? topDividerColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: _ClassicSidebarPreview._sectionBlockTopGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topDividerColor != null) ...[
            Container(height: 1, color: topDividerColor),
            const SizedBox(height: _ClassicSidebarPreview._sectionDividerGap),
          ],
          Text(title, style: titleStyle),
          const SizedBox(height: _ClassicSidebarPreview._sectionHeadingGap),
          child,
          const SizedBox(height: _ClassicSidebarPreview._sectionDividerGap),
        ],
      ),
    );
  }
}

String _classicSidebarExperienceCompanyDatesLine(WorkExperience item) {
  final company = item.company.trim();
  final dates = [
    item.startDate.trim(),
    item.endDate.trim(),
  ].where((value) => value.isNotEmpty).join(' - ');
  if (company.isEmpty && dates.isEmpty) {
    return '';
  }
  if (company.isEmpty) {
    return dates;
  }
  if (dates.isEmpty) {
    return company;
  }
  return '$company · $dates';
}

class _ClassicExperienceBlock extends StatelessWidget {
  const _ClassicExperienceBlock({
    required this.item,
    required this.bodyStyle,
    required this.subtitleStyle,
    required this.bulletColor,
    this.maxBulletLines = 2,
  });

  final WorkExperience item;
  final TextStyle bodyStyle;
  final TextStyle subtitleStyle;
  final Color bulletColor;
  final int maxBulletLines;

  @override
  Widget build(BuildContext context) {
    final bullets = _workBulletLines(item).take(2).toList();
    final companyDatesLine = _classicSidebarExperienceCompanyDatesLine(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.role.ifBlank('Role'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: subtitleStyle,
        ),
        if (companyDatesLine.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              companyDatesLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle,
            ),
          ),
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 5),
          _ClassicBulletList(
            items: bullets,
            textStyle: bodyStyle,
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
    required this.subtitleStyle,
    required this.mutedColor,
  });

  final EducationItem item;
  final TextStyle bodyStyle;
  final TextStyle subtitleStyle;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final dates = [
      item.startDate.trim(),
      item.endDate.trim(),
    ].where((value) => value.isNotEmpty).join(' - ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.degree.ifBlank('Degree')}, ${item.institution.ifBlank('Institution')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: subtitleStyle,
        ),
        if (dates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              dates,
              style: bodyStyle.copyWith(
                color: mutedColor,
                fontStyle: FontStyle.italic,
              ),
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
    required this.subtitleStyle,
    required this.mutedColor,
    required this.bulletColor,
  });

  final ProjectItem item;
  final TextStyle bodyStyle;
  final TextStyle subtitleStyle;
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
          style: subtitleStyle,
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

class _DetailsSidebarRailSectionHeading extends StatelessWidget {
  const _DetailsSidebarRailSectionHeading({
    required this.title,
    required this.titleColor,
    required this.dividerColor,
  });

  final String title;
  final Color titleColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: dividerColor),
      ],
    );
  }
}

class _DetailsSidebarContentSection extends StatelessWidget {
  const _DetailsSidebarContentSection({
    required this.title,
    required this.titleColor,
    required this.dividerColor,
    required this.child,
  });

  final String title;
  final Color titleColor;
  final Color dividerColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 1, color: dividerColor)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailsSidebarExperienceBlock extends StatelessWidget {
  const _DetailsSidebarExperienceBlock({
    required this.item,
    required this.bodyStyle,
    required this.titleColor,
    required this.mutedColor,
    required this.bulletColor,
  });

  final WorkExperience item;
  final TextStyle bodyStyle;
  final Color titleColor;
  final Color mutedColor;
  final Color bulletColor;

  @override
  Widget build(BuildContext context) {
    final bullets = _workBulletLines(item).take(3).toList();
    final dates = [
      item.startDate.trim(),
      item.endDate.trim(),
    ].where((value) => value.isNotEmpty).join(' — ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dates.isNotEmpty)
          Text(dates, style: bodyStyle.copyWith(color: mutedColor)),
        if (item.role.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            item.role.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: bodyStyle.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (item.company.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.company.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bodyStyle.copyWith(color: mutedColor),
          ),
        ],
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 6),
          _ClassicBulletList(
            items: bullets,
            textStyle: bodyStyle.copyWith(color: titleColor),
            bulletColor: bulletColor,
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}

class _DetailsSidebarEducationBlock extends StatelessWidget {
  const _DetailsSidebarEducationBlock({
    required this.item,
    required this.bodyStyle,
    required this.titleColor,
    required this.mutedColor,
  });

  final EducationItem item;
  final TextStyle bodyStyle;
  final Color titleColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final dates = [
      item.startDate.trim(),
      item.endDate.trim(),
    ].where((value) => value.isNotEmpty).join(' — ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dates.isNotEmpty)
          Text(dates, style: bodyStyle.copyWith(color: mutedColor)),
        if (item.degree.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            item.degree.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: bodyStyle.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (item.institution.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.institution.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: bodyStyle.copyWith(color: mutedColor),
          ),
        ],
      ],
    );
  }
}

class _DetailsSidebarProjectBlock extends StatelessWidget {
  const _DetailsSidebarProjectBlock({
    required this.item,
    required this.bodyStyle,
    required this.titleColor,
    required this.mutedColor,
    required this.bulletColor,
  });

  final ProjectItem item;
  final TextStyle bodyStyle;
  final Color titleColor;
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
          style: bodyStyle.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w800,
          ),
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
    if (resume.githubLink.trim().isNotEmpty)
      (icon: Icons.code_rounded, text: resume.githubLink.trim()),
    if (resume.linkedinLink.trim().isNotEmpty)
      (icon: Icons.work_outline_rounded, text: resume.linkedinLink.trim()),
  ];

  return rows
      .take(maxItems)
      .map(
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
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

List<Widget> _detailsSidebarPreviewInfoRows(
  ResumeData resume, {
  required Color titleColor,
  required Color mutedColor,
  required TextStyle baseStyle,
}) {
  final rows = <({IconData icon, String text})>[
    if (resume.email.trim().isNotEmpty)
      (icon: Icons.email_rounded, text: resume.email.trim()),
    if (resume.phone.trim().isNotEmpty)
      (icon: Icons.phone_rounded, text: resume.phone.trim()),
    if (resume.location.trim().isNotEmpty)
      (icon: Icons.location_on_rounded, text: resume.location.trim()),
    if (resume.website.trim().isNotEmpty)
      (icon: Icons.language_rounded, text: resume.website.trim()),
  ];

  return rows
      .map(
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(row.icon, size: 12, color: titleColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  row.text,
                  maxLines: 3,
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
    final normalized = item.title.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    if (normalized == 'language' ||
        normalized == 'languages' ||
        normalized == 'langueage' ||
        normalized == 'langueages') {
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
  const _CreativeSidebarHeading({
    required this.title,
    required this.lineColor,
    required this.sectionTitlePt,
  });

  final String title;
  final Color lineColor;
  final double sectionTitlePt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ResumeTypography.calibriPreviewStyle(
              weight: ResumeTypography.creativeSectionTitleWeight,
              fontSize: sectionTitlePt,
              color: ResumeTypography.creativeBodyTextColor,
              height: ResumeTypography.creativeBodyLineHeight,
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

  static const double _squareSize = 7;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? ResumeTypography.creativeBodyPt;
    final lineHeight =
        style.height ?? ResumeTypography.creativeBodyLineHeight;
    final firstLineExtent = fontSize * lineHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: firstLineExtent,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: _squareSize,
              height: _squareSize,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
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

class _CreativeProfileAvatar extends StatelessWidget {
  const _CreativeProfileAvatar({
    required this.resume,
    required this.width,
    required this.height,
    required this.accentColor,
    required this.backgroundColor,
    required this.backgroundOpacity,
    required this.initialsFontSize,
  });

  final ResumeData resume;
  final double width;
  final double height;
  final Color accentColor;
  final Color backgroundColor;
  final double backgroundOpacity;
  final double initialsFontSize;

  static const double _cornerRadius = 2;

  @override
  Widget build(BuildContext context) {
    final path = resume.profileImagePath.trim();
    final hasImage = path.isNotEmpty && File(path).existsSync();
    final initialsStyle = TextStyle(
      color: accentColor,
      fontSize: initialsFontSize,
      fontWeight: ResumeFontWeight.toFlutter(
        ResumeTypography.creativeNameWeight,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(_cornerRadius),
      child: Container(
        width: width,
        height: height,
        color: backgroundColor.withValues(alpha: backgroundOpacity),
        alignment: Alignment.center,
        child: hasImage
            ? Image.file(
                File(path),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(
                  _pdfAlignedInitials(resume),
                  style: initialsStyle,
                ),
              )
            : Text(
                _pdfAlignedInitials(resume),
                style: initialsStyle,
              ),
      ),
    );
  }
}

String _creativeExperienceDateRange(String startDate, String endDate) {
  final start = startDate.trim();
  final end = endDate.trim();
  if (start.isEmpty && end.isEmpty) {
    return '';
  }
  if (start.isNotEmpty && end.isNotEmpty) {
    return '$start - $end';
  }
  return start.isNotEmpty ? start : end;
}

class _CreativeBulletColumn extends StatelessWidget {
  const _CreativeBulletColumn({
    required this.items,
    required this.bodyStyle,
    this.maxLines = 1,
  });

  final List<String> items;
  final TextStyle bodyStyle;
  final int? maxLines;

  static const double _bulletTextGap = 6;

  Widget _bulletRow(String item) {
    final fontSize = bodyStyle.fontSize ?? ResumeTypography.creativeBodyPt;
    final lineHeight =
        bodyStyle.height ?? ResumeTypography.creativeBodyLineHeight;
    final firstLineExtent = fontSize * lineHeight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: firstLineExtent,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '•',
                style: bodyStyle.copyWith(
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: _bulletTextGap),
          Expanded(
            child: Text(
              item.trim(),
              maxLines: maxLines,
              overflow:
                  maxLines == null ? null : TextOverflow.ellipsis,
              style: bodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _bulletRow('Add skills');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final item in items) _bulletRow(item)],
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
    resume.email.trim(),
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

List<String> _darkHeaderContactLines(List<String> items) {
  final cleaned = items.where((item) => item.trim().isNotEmpty).toList();
  if (cleaned.isEmpty) {
    return const <String>[];
  }
  if (cleaned.length <= 2) {
    return <String>[cleaned.join(' | ')];
  }
  final firstLine = cleaned.take(2).join(' | ');
  final secondLine = cleaned.skip(2).join(' | ');
  return <String>[firstLine, if (secondLine.isNotEmpty) secondLine];
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
