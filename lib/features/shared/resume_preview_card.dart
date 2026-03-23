import 'package:flutter/material.dart';

import '../../core/models/resume_models.dart';

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

    return AnimatedContainer(
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
          BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: switch (resume.template) {
        ResumeTemplate.modern => _ModernPreview(
          resume: resume,
          isCompact: isCompact,
        ),
        ResumeTemplate.minimal => _MinimalPreview(
          resume: resume,
          isCompact: isCompact,
        ),
        ResumeTemplate.corporate => _CorporatePreview(
          resume: resume,
          isCompact: isCompact,
        ),
        ResumeTemplate.creative => _CreativePreview(
          resume: resume,
          isCompact: isCompact,
        ),
      },
    );
  }
}

class _ModernPreview extends StatelessWidget {
  const _ModernPreview({required this.resume, required this.isCompact});

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isCompact ? 42 : 56,
              height: isCompact ? 42 : 56,
              decoration: BoxDecoration(
                color: resume.template.accentColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: isCompact ? 22 : 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _HeaderText(resume: resume, isCompact: isCompact),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SummaryBlock(resume: resume, isCompact: isCompact),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resume.skills.take(isCompact ? 4 : 6).map((skill) {
            return Chip(
              label: Text(skill),
              backgroundColor: resume.template.tintColor,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 10),
        ...resume.visibleWorkExperiences.take(2).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BulletPreview(
              title:
                  '${item.role.ifBlank('Role')} • ${item.company.ifBlank('Company')}',
              body: item.bullets.isNotEmpty
                  ? item.bullets.first
                  : item.description.ifBlank(
                      'Add impact bullets to preview your strongest wins.',
                    ),
            ),
          );
        }),
      ],
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
      ],
    );
  }
}

class _CorporatePreview extends StatelessWidget {
  const _CorporatePreview({required this.resume, required this.isCompact});

  final ResumeData resume;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: resume.template.tintColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _HeaderText(resume: resume, isCompact: isCompact),
        ),
        const SizedBox(height: 16),
        _PreviewSectionLabel(
          label: 'Executive Summary',
          color: resume.template.accentColor,
        ),
        const SizedBox(height: 8),
        _SummaryBlock(resume: resume, isCompact: isCompact),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: 'ATS',
                value: '${(resume.completionRatio * 100).round()}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                title: 'Skills',
                value: '${resume.skills.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                title: 'Projects',
                value: '${resume.visibleProjects.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _PreviewSectionLabel(
          label: 'Professional Highlights',
          color: resume.template.accentColor,
        ),
        const SizedBox(height: 8),
        ...resume.visibleWorkExperiences.take(2).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BulletPreview(
              title:
                  '${item.company.ifBlank('Company')} • ${item.startDate.ifBlank('Dates')}',
              body: item.bullets.isNotEmpty
                  ? item.bullets.first
                  : item.description.ifBlank(
                      'Add a concise, metric-driven highlight here.',
                    ),
            ),
          );
        }),
        if (resume.visibleProjects.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            resume.visibleProjects.first.title.ifBlank('Featured project'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resume.visibleProjects.first.overview.ifBlank(
              'Add a featured project to showcase leadership and delivery.',
            ),
          ),
        ],
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
            fontSize: isCompact ? 22 : 28,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
