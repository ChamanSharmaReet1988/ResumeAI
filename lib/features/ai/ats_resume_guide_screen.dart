import 'package:flutter/material.dart';
import 'package:resume_app/l10n/app_localizations.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

/// Read-only guide on writing a resume that applicant tracking systems parse
/// correctly. Opened from the AI Resume tab.
class AtsResumeGuideScreen extends StatelessWidget {
  const AtsResumeGuideScreen({super.key});

  static List<(IconData, String, String)> _sections(AppLocalizations l10n) => [
    (Icons.fact_check_outlined, l10n.atsGuideMythTitle, l10n.atsGuideMythBody),
    (
      Icons.view_agenda_outlined,
      l10n.atsGuideLayoutTitle,
      l10n.atsGuideLayoutBody,
    ),
    (
      Icons.title_rounded,
      l10n.atsGuideHeadingsTitle,
      l10n.atsGuideHeadingsBody,
    ),
    (Icons.badge_outlined, l10n.atsGuideContactTitle, l10n.atsGuideContactBody),
    (
      Icons.manage_search_rounded,
      l10n.atsGuideKeywordsTitle,
      l10n.atsGuideKeywordsBody,
    ),
    (
      Icons.trending_up_rounded,
      l10n.atsGuideBulletsTitle,
      l10n.atsGuideBulletsBody,
    ),
    (Icons.build_outlined, l10n.atsGuideSkillsTitle, l10n.atsGuideSkillsBody),
    (Icons.description_outlined, l10n.atsGuideFileTitle, l10n.atsGuideFileBody),
    (Icons.checklist_rounded, l10n.atsGuideCheckTitle, l10n.atsGuideCheckBody),
    (Icons.auto_awesome_rounded, l10n.atsGuideAppTitle, l10n.atsGuideAppBody),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = _sections(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.atsGuideTitle)),
      body: ListView(
        key: const Key('ats-guide-list'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _GuideBody(
            text: l10n.atsGuideIntro,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < sections.length; i++)
            _GuideSection(
              number: i + 1,
              icon: sections[i].$1,
              title: sections[i].$2,
              body: sections[i].$3,
            ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$number. $title',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _GuideBody(text: body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Renders lines starting with "• " as bullet rows and other lines as
/// paragraphs.
class _GuideBody extends StatelessWidget {
  const _GuideBody({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final lineStyle = style?.copyWith(height: 1.45);
    final bulletColor = Theme.of(context).colorScheme.primary;
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: line.startsWith('• ')
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        style: lineStyle?.copyWith(
                          color: bulletColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(line.substring(2), style: lineStyle),
                      ),
                    ],
                  )
                : Text(line, style: lineStyle),
          ),
      ],
    );
  }
}
