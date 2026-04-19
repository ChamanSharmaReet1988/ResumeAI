import 'package:flutter/material.dart';

import '../../core/models/resume_models.dart';
import '../../core/resume_text_font.dart';

class ResumePreviewCard extends StatelessWidget {
  const ResumePreviewCard({
    super.key,
    required this.resume,
    this.isCompact = false,
  });

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadow = theme.colorScheme.shadow.withValues(alpha: 0.08);
    final previewTemplate = resume.template.userFacingTemplate;
    final base = theme.textTheme;
    final ff = resume.resumeTextFont.flutterFontFamily;
    final onSurface = theme.colorScheme.onSurface;
    final resumeBodyTheme = theme.copyWith(
      textTheme: base
          .apply(fontFamily: ff, bodyColor: onSurface, displayColor: onSurface)
          .copyWith(
            bodyLarge: base.bodyLarge?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.bodyPt,
            ),
            bodyMedium: base.bodyMedium?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.bodyPt,
            ),
            bodySmall: base.bodySmall?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.bodyPt,
            ),
            titleSmall: base.titleSmall?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
            ),
            titleMedium: base.titleMedium?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
            ),
            titleLarge: base.titleLarge?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
            ),
            headlineSmall: base.headlineSmall?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
            ),
            headlineMedium: base.headlineMedium?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.namePt,
            ),
            labelLarge: base.labelLarge?.copyWith(
              fontFamily: ff,
              fontSize: ResumeTypography.headingPt,
            ),
          ),
    );

    return Theme(
      data: resumeBodyTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(isCompact ? 16 : 20),
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
        child: switch (previewTemplate) {
          ResumeTemplate.corporate || ResumeTemplate.modern =>
            _CorporatePreview(resume: resume, isCompact: isCompact),
          ResumeTemplate.minimal => _MinimalPreview(
            resume: resume,
            isCompact: isCompact,
          ),
          ResumeTemplate.creative => _CreativePreview(
            resume: resume,
            isCompact: isCompact,
          ),
          ResumeTemplate.copperSerif => _CopperSerifPreview(
            resume: resume,
            isCompact: isCompact,
          ),
          ResumeTemplate.splitBanner => _SplitBannerPreview(
            resume: resume,
            isCompact: isCompact,
          ),
          ResumeTemplate.monogramSidebar => _MonogramSidebarPreview(
            resume: resume,
            isCompact: isCompact,
          ),
        },
      ),
    );
  }
}

class _MinimalPreview extends StatelessWidget {
  const _MinimalPreview({required this.resume, required this.isCompact});

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderText(resume: resume, isCompact: isCompact),
        const SizedBox(height: 12),
        Container(
          height: 2,
          width: isCompact ? 72 : 96,
          color: theme.colorScheme.onSurface,
        ),
        const SizedBox(height: 14),
        _SummaryBlock(resume: resume, isCompact: isCompact),
        const SizedBox(height: 14),
        Text(
          'Skills',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          resume.skills.isEmpty
              ? 'Communication • Strategy • Collaboration'
              : resume.skills.take(isCompact ? 5 : 8).join(' • '),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Text(
          'Experience',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...resume.visibleWorkExperiences.take(2).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BulletPreview(
              title: item.role.ifBlank('Role'),
              body: item.description.ifBlank(
                'Describe your responsibilities and the measurable outcomes you created.',
              ),
            ),
          );
        }),
        if (resume.visibleCustomSections.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CustomSectionPreview(
            item: resume.visibleCustomSections.first,
            isCompact: isCompact,
          ),
        ],
      ],
    );
  }
}

/// Spacing and type sizes aligned with [ResumePdfService._addCorporateTemplatePage],
/// [_corporateSection], [_twoColumnBulletList], and [_buildCorporateExperience].
abstract final class _CorporatePdfMetrics {
  static const headerColor = Color(0xFF3B4046);
  static const lineColor = Color(0xFFD7DCE2);
  static const sectionTitleColor = Color(0xFF50555C);
  static const dateMutedColor = Color(0xFF666B71);

  static const bodyFontSize = ResumeTypography.bodyPt;
  static const bodyHeight = 1.25;

  static EdgeInsets headerPadding(bool compact) => compact
      ? const EdgeInsets.fromLTRB(18, 22, 18, 20)
      : const EdgeInsets.fromLTRB(30, 36, 30, 30);

  static double headerAvatar(bool compact) => compact ? 42 : 48;

  static double headerNameSize(bool compact) =>
      ResumeTypography.nameSizePreview(compact);

  static const headerAfterAvatar = 14.0;
  static const headerNameToContact = 6.0;
  static const afterHeader = 18.0;

  /// [_corporateSection] uses `fromLTRB(30, 0, 30, 16)`.
  static EdgeInsets sectionOuter(bool compact) => compact
      ? const EdgeInsets.fromLTRB(14, 0, 14, 16)
      : const EdgeInsets.fromLTRB(30, 0, 30, 16);

  static const titleToContent = 6.0;
  static const contentToRule = 10.0;
  static const sectionTitleSize = ResumeTypography.headingPt;

  /// [_twoColumnBulletList] column gap.
  static const skillsColumnGap = 20.0;
  static const bulletItemBottom = 3.0;

  static const experienceBlockBottom = 10.0;
  static const descAfterTitle = 4.0;
  static const bulletTop = 3.0;
  static const educationBlockBottom = 8.0;
  static const projectBlockBottom = 8.0;
}

class _CorporatePreview extends StatelessWidget {
  const _CorporatePreview({required this.resume, required this.isCompact});

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _pdfAlignedDisplayName(resume);
    final contactLine = _pdfAlignedContactItems(resume).join('  /  ');
    final skills = _pdfAlignedSkills(resume);
    final onSurface = theme.colorScheme.onSurface;
    final bodyStyle = TextStyle(
      fontSize: _CorporatePdfMetrics.bodyFontSize,
      height: _CorporatePdfMetrics.bodyHeight,
      color: onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: _CorporatePdfMetrics.headerColor,
          child: Padding(
            padding: _CorporatePdfMetrics.headerPadding(isCompact),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _CorporatePdfMetrics.headerAvatar(isCompact),
                  height: _CorporatePdfMetrics.headerAvatar(isCompact),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: Center(
                      child: Text(
                        _pdfAlignedInitials(resume),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _CorporatePdfMetrics.headerAfterAvatar),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _CorporatePdfMetrics.headerNameSize(
                            isCompact,
                          ),
                          fontWeight: FontWeight.bold,
                          height: 1.05,
                          letterSpacing: 0.15,
                        ),
                      ),
                      if (contactLine.isNotEmpty) ...[
                        SizedBox(
                          height: _CorporatePdfMetrics.headerNameToContact,
                        ),
                        Text(
                          contactLine,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: ResumeTypography.bodyPt,
                            height: 1.28,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: _CorporatePdfMetrics.afterHeader),
        if (resume.summary.trim().isNotEmpty)
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(isCompact),
            title: 'SUMMARY',
            lineColor: _CorporatePdfMetrics.lineColor,
            titleColor: _CorporatePdfMetrics.sectionTitleColor,
            child: Text(resume.summary.trim(), style: bodyStyle),
          ),
        _CorporatePdfLikeSection(
          outerPadding: _CorporatePdfMetrics.sectionOuter(isCompact),
          title: 'SKILLS',
          lineColor: _CorporatePdfMetrics.lineColor,
          titleColor: _CorporatePdfMetrics.sectionTitleColor,
          child: _CorporateSkillsColumns(skills: skills, bodyStyle: bodyStyle),
        ),
        if (resume.visibleWorkExperiences.isNotEmpty)
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(isCompact),
            title: 'EXPERIENCE',
            lineColor: _CorporatePdfMetrics.lineColor,
            titleColor: _CorporatePdfMetrics.sectionTitleColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in resume.visibleWorkExperiences.take(
                  isCompact ? 2 : 3,
                ))
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
        if (resume.visibleEducation.isNotEmpty)
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(isCompact),
            title: 'EDUCATION AND TRAINING',
            lineColor: _CorporatePdfMetrics.lineColor,
            titleColor: _CorporatePdfMetrics.sectionTitleColor,
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
        if (resume.visibleProjects.isNotEmpty)
          _CorporatePdfLikeSection(
            outerPadding: _CorporatePdfMetrics.sectionOuter(isCompact),
            title: 'PROJECTS',
            lineColor: _CorporatePdfMetrics.lineColor,
            titleColor: _CorporatePdfMetrics.sectionTitleColor,
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
            outerPadding: _CorporatePdfMetrics.sectionOuter(isCompact),
            title: item.title.ifBlank('Custom section').toUpperCase(),
            lineColor: _CorporatePdfMetrics.lineColor,
            titleColor: _CorporatePdfMetrics.sectionTitleColor,
            child: Text(item.content.trim(), style: bodyStyle),
          ),
        // [_addCorporateTemplatePage] ends with `pw.SizedBox(height: 10)`.
        const SizedBox(height: 10),
      ],
    );
  }
}

class _CorporatePdfLikeSection extends StatelessWidget {
  const _CorporatePdfLikeSection({
    required this.outerPadding,
    required this.title,
    required this.lineColor,
    required this.titleColor,
    required this.child,
  });

  /// Matches [_corporateSection] horizontal inset and bottom margin.
  final EdgeInsets outerPadding;
  final String title;
  final Color lineColor;
  final Color titleColor;
  final Widget child;

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
              fontSize: _CorporatePdfMetrics.sectionTitleSize,
              fontWeight: FontWeight.bold,
              height: 1.0,
              color: titleColor,
            ),
          ),
          SizedBox(height: _CorporatePdfMetrics.titleToContent),
          child,
          SizedBox(height: _CorporatePdfMetrics.contentToRule),
          Container(height: 1, color: lineColor),
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
      fontSize: bodyStyle.fontSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: bodyStyle.copyWith(color: onSurface),
                  children: [
                    TextSpan(
                      text: item.role.ifBlank('Role'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' / ${item.company.ifBlank('Company')}'),
                  ],
                ),
              ),
            ),
            if (dateStr.isNotEmpty)
              Text(dateStr, style: dateStyle, textAlign: TextAlign.right),
          ],
        ),
        if (item.description.trim().isNotEmpty) ...[
          SizedBox(height: _CorporatePdfMetrics.descAfterTitle),
          Text(item.description.trim(), style: bodyStyle),
        ],
        for (final bullet in item.bullets)
          Padding(
            padding: const EdgeInsets.only(top: _CorporatePdfMetrics.bulletTop),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: bodyStyle),
                Expanded(child: Text(bullet, style: bodyStyle)),
              ],
            ),
          ),
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
    final details = [
      item.institution.trim(),
      item.year.trim(),
      item.score.trim(),
      item.details.trim(),
    ].where((part) => part.isNotEmpty).join('  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.degree.ifBlank('Degree'),
          style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        if (details.isNotEmpty) Text(details, style: bodyStyle),
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
          style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        if (item.overview.trim().isNotEmpty)
          Text(item.overview.trim(), style: bodyStyle),
        if (item.impact.trim().isNotEmpty)
          Text(item.impact.trim(), style: bodyStyle),
      ],
    );
  }
}

class _CreativePreview extends StatelessWidget {
  const _CreativePreview({required this.resume, required this.isCompact});

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                resume.template.accentColor,
                resume.template.accentColor.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: _HeaderText(
              resume: resume,
              isCompact: isCompact,
              titleColor: Colors.white,
              subtitleColor: Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SummaryBlock(resume: resume, isCompact: isCompact),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resume.visibleProjects.take(3).map((project) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: resume.template.tintColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title.ifBlank('Project'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.impact.ifBlank(
                        'Add a tangible creative outcome or showcase result.',
                      ),
                      maxLines: isCompact ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (resume.visibleCustomSections.isNotEmpty) ...[
          const SizedBox(height: 16),
          _CustomSectionPreview(
            item: resume.visibleCustomSections.first,
            isCompact: isCompact,
          ),
        ],
      ],
    );
  }
}

class _CopperSerifPreview extends StatelessWidget {
  const _CopperSerifPreview({required this.resume, required this.isCompact});

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          resume.fullName.ifBlank('Your Name').toUpperCase(),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: ResumeTypography.nameSizePreview(isCompact),
            letterSpacing: 0.3,
            color: resume.template.accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [resume.email, resume.phone, resume.location]
              .where((item) => item.trim().isNotEmpty)
              .join('   |   ')
              .ifBlank(
                'email@example.com   |   +1 555 0100   |   City, Country',
              ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        _CenteredPreviewDivider(
          label: 'Summary',
          color: resume.template.accentColor,
        ),
        const SizedBox(height: 8),
        _SummaryBlock(resume: resume, isCompact: isCompact),
        const SizedBox(height: 14),
        _CenteredPreviewDivider(
          label: 'Skills',
          color: resume.template.accentColor,
        ),
        const SizedBox(height: 8),
        Text(
          resume.skills.isEmpty
              ? 'Customer support • Training • Sales • Teamwork'
              : resume.skills.take(isCompact ? 6 : 8).join(' • '),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        _CenteredPreviewDivider(
          label: 'Experience',
          color: resume.template.accentColor,
        ),
        const SizedBox(height: 8),
        ...resume.visibleWorkExperiences.take(2).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BulletPreview(
              title: item.role.ifBlank('Role'),
              body: item.bullets.isNotEmpty
                  ? item.bullets.first
                  : item.description.ifBlank(
                      'Add a short accomplishment that shows measurable impact.',
                    ),
            ),
          );
        }),
      ],
    );
  }
}

class _SplitBannerPreview extends StatelessWidget {
  const _SplitBannerPreview({required this.resume, required this.isCompact});

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: BoxDecoration(
            color: resume.template.accentColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  resume.fullName.ifBlank('Your Name').toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: ResumeTypography.nameSizePreview(isCompact),
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  [resume.email, resume.phone, resume.location]
                      .where((item) => item.trim().isNotEmpty)
                      .join('\n')
                      .ifBlank('email@example.com\n+1 555 0100\nCity, Country'),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _LabeledPreviewSection(
          label: 'Summary',
          color: resume.template.accentColor,
          child: _SummaryBlock(resume: resume, isCompact: isCompact),
        ),
        const SizedBox(height: 12),
        _LabeledPreviewSection(
          label: 'Skills',
          color: resume.template.accentColor,
          child: Text(
            resume.skills.isEmpty
                ? 'Store operations • Coaching • Register accuracy • Reporting'
                : resume.skills.take(isCompact ? 6 : 8).join(' • '),
          ),
        ),
        const SizedBox(height: 12),
        _LabeledPreviewSection(
          label: 'Experience',
          color: resume.template.accentColor,
          child: Column(
            children: resume.visibleWorkExperiences.take(2).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BulletPreview(
                  title: item.role.ifBlank('Role'),
                  body: item.bullets.isNotEmpty
                      ? item.bullets.first
                      : item.description.ifBlank(
                          'Add a short accomplishment that shows measurable impact.',
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MonogramSidebarPreview extends StatelessWidget {
  const _MonogramSidebarPreview({
    required this.resume,
    required this.isCompact,
  });

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isCompact ? 88 : 120,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: isCompact ? 44 : 56,
                height: isCompact ? 44 : 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _initials(resume),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: resume.template.accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                resume.fullName.ifBlank('Your Name'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: resume.template.accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: ResumeTypography.nameSizePreview(isCompact),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                [resume.phone, resume.email, resume.location]
                    .where((item) => item.trim().isNotEmpty)
                    .join('\n')
                    .ifBlank('+1 555 0100\nemail@example.com\nCity, Country'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewSectionLabel(label: 'Summary', color: Colors.black),
              const SizedBox(height: 6),
              _SummaryBlock(resume: resume, isCompact: isCompact),
              const SizedBox(height: 12),
              _PreviewSectionLabel(label: 'Skills', color: Colors.black),
              const SizedBox(height: 6),
              Text(
                resume.skills.isEmpty
                    ? 'Coordination • Admin support • Communication • Follow-up'
                    : resume.skills.take(isCompact ? 5 : 7).join(' • '),
              ),
              const SizedBox(height: 12),
              _PreviewSectionLabel(label: 'Experience', color: Colors.black),
              const SizedBox(height: 6),
              ...resume.visibleWorkExperiences.take(2).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BulletPreview(
                    title: item.role.ifBlank('Role'),
                    body: item.bullets.isNotEmpty
                        ? item.bullets.first
                        : item.description.ifBlank(
                            'Add a short accomplishment that shows measurable impact.',
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.resume,
    required this.isCompact,
    this.titleColor,
    this.subtitleColor,
  });

  final ResumeData resume;
  final bool isCompact;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resume.fullName.ifBlank('Your Name'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: ResumeTypography.nameSizePreview(isCompact),
            color: titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          resume.jobTitle.ifBlank('Target job title'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [
                resume.location,
                resume.email,
                resume.phone,
                resume.githubLink,
                resume.linkedinLink,
              ]
              .where((item) => item.trim().isNotEmpty)
              .join('  •  ')
              .ifBlank('Location • Email • Phone • GitHub • LinkedIn'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.resume, required this.isCompact});

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      resume.summary.ifBlank(
        'Add a short AI-generated summary to position your experience and strengths clearly.',
      ),
      maxLines: isCompact ? 4 : 5,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.45,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _BulletPreview extends StatelessWidget {
  const _BulletPreview({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomSectionPreview extends StatelessWidget {
  const _CustomSectionPreview({required this.item, required this.isCompact});

  final CustomSectionItem item;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title.ifBlank('Custom section'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        if (item.layoutMode == CustomSectionLayoutMode.summary)
          Text(
            item.content.ifBlank('Add custom content to preview it here.'),
            maxLines: isCompact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else if (item.bullets.any((b) => b.trim().isNotEmpty))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in item.bullets.where((b) => b.trim().isNotEmpty))
                Text(
                  '• ${line.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          )
        else
          Text(
            'Add bullet points to preview them here.',
            maxLines: isCompact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _PreviewSectionLabel extends StatelessWidget {
  const _PreviewSectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _CenteredPreviewDivider extends StatelessWidget {
  const _CenteredPreviewDivider({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            thickness: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _LabeledPreviewSection extends StatelessWidget {
  const _LabeledPreviewSection({
    required this.label,
    required this.color,
    required this.child,
  });

  final String label;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        Expanded(child: child),
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
    resume.email.trim(),
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
  return const ['Communication', 'Collaboration', 'Documentation'];
}

String _initials(ResumeData resume) {
  final parts = resume.fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return 'YN';
  }
  return parts.map((part) => part[0].toUpperCase()).join();
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
