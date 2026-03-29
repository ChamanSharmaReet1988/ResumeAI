import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../shared/view_models.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({
    super.key,
    this.onCreateResume,
    this.onTemplateSelected,
    this.selectedTemplate,
  });

  final VoidCallback? onCreateResume;
  final ValueChanged<ResumeTemplate>? onTemplateSelected;
  final ResumeTemplate? selectedTemplate;

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<ResumeLibraryViewModel?>(context);
    final isTemplatePicker = onTemplateSelected != null;
    final activeTemplate =
        (selectedTemplate ?? library?.defaultTemplate)?.userFacingTemplate;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            key: const Key('template-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _templateCards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final item = _templateCards[index];
              final selected =
                  isTemplatePicker && item.template == activeTemplate;

              return _TemplateTile(
                item: item,
                selected: selected,
                onTap: () {
                  if (onTemplateSelected != null) {
                    onTemplateSelected!(item.template);
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _TemplateDetailScreen(
                        item: item,
                        onUseTemplate: () {
                          library?.setDefaultTemplate(item.template);
                          Navigator.of(context).pop();
                          onCreateResume?.call();
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TemplateDetailScreen extends StatelessWidget {
  const _TemplateDetailScreen({required this.item, this.onUseTemplate});

  final _TemplateTileData item;
  final VoidCallback? onUseTemplate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 8,
        title: Text(item.headline),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colorScheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4EF),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: KeyedSubtree(
                            key: Key('template-detail-preview-${item.id}'),
                            child: _TemplatePreviewArt(item: item),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (onUseTemplate != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('use-template-button'),
                  onPressed: onUseTemplate,
                  child: const Text('Use template'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _TemplateTileData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final outlineColor = colorScheme.outlineVariant;
    final selectedColor = colorScheme.primary;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: ((Theme.of(context).textTheme.labelSmall?.fontSize ?? 11) - 4)
          .clamp(8, 20)
          .toDouble(),
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Material(
      key: Key('template-tile-${item.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? selectedColor : outlineColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F4EF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: KeyedSubtree(
                              key: Key('template-image-${item.id}'),
                              child: _TemplatePreviewArt(item: item),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.headline,
                        textAlign: TextAlign.center,
                        style: labelStyle,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: selectedColor,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _templateCards = <_TemplateTileData>[
  _TemplateTileData(
    id: 'dark-header',
    template: ResumeTemplate.corporate,
    headline: 'Dark Header',
    caption: 'Bold top band with compact professional sections.',
  ),
  _TemplateTileData(
    id: 'centered-classic',
    template: ResumeTemplate.minimal,
    headline: 'Centered Classic',
    caption: 'Calm centered header with timeless editorial spacing.',
  ),
  _TemplateTileData(
    id: 'profile-sidebar',
    template: ResumeTemplate.creative,
    headline: 'Profile Sidebar',
    caption: 'Profile-led layout with strong visual anchors.',
  ),
  _TemplateTileData(
    id: 'copper-serif',
    template: ResumeTemplate.copperSerif,
    headline: 'Copper Serif',
    caption: 'Centered serif-inspired layout with warm copper accents.',
  ),
  _TemplateTileData(
    id: 'split-banner',
    template: ResumeTemplate.splitBanner,
    headline: 'Split Banner',
    caption: 'Wide copper banner with crisp section labels and structure.',
  ),
  _TemplateTileData(
    id: 'monogram-sidebar',
    template: ResumeTemplate.monogramSidebar,
    headline: 'Monogram Sidebar',
    caption: 'Narrow profile rail with bold monogram and clean content stack.',
  ),
];

class _TemplateTileData {
  const _TemplateTileData({
    required this.id,
    required this.template,
    required this.headline,
    required this.caption,
  });

  final String id;
  final ResumeTemplate template;
  final String headline;
  final String caption;
}

class _TemplatePreviewArt extends StatelessWidget {
  const _TemplatePreviewArt({required this.item});

  final _TemplateTileData item;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 168,
        height: 216,
        child: switch (item.template) {
          ResumeTemplate.corporate => const _DarkHeaderTemplateArt(),
          ResumeTemplate.minimal => const _CenteredClassicTemplateArt(),
          ResumeTemplate.creative => const _ProfileSidebarTemplateArt(),
          ResumeTemplate.copperSerif => const _CopperSerifTemplateArt(),
          ResumeTemplate.splitBanner => const _SplitBannerTemplateArt(),
          ResumeTemplate.monogramSidebar => const _MonogramSidebarTemplateArt(),
          ResumeTemplate.modern => const _DarkHeaderTemplateArt(),
        },
      ),
    );
  }
}

class _DarkHeaderTemplateArt extends StatelessWidget {
  const _DarkHeaderTemplateArt();

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF2E3135);
    const header = Color(0xFF31353B);
    const line = Color(0xFFD8DDE4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                decoration: const BoxDecoration(
                  color: header,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70),
                      ),
                      child: const Text(
                        'ML',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MAYA LOPEZ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Austin, TX 78701',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 5.2,
                            ),
                          ),
                          Text(
                            'maya.lopez@mail.com  |  +1 512 555 0148',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 5.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 4.6,
                    height: 1.32,
                    color: text,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MiniSectionHeading(
                        title: 'SUMMARY',
                        lineColor: line,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Client success manager with 6 years leading renewals, onboarding, and high-touch account support for fast-growing SaaS teams.',
                      ),
                      const SizedBox(height: 7),
                      const _MiniSectionHeading(
                        title: 'SKILLS',
                        lineColor: line,
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _MiniBulletColumn(
                              items: [
                                'Renewal strategy',
                                'CRM operations',
                                'Service recovery',
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _MiniBulletColumn(
                              items: [
                                'Lifecycle emails',
                                'Stakeholder updates',
                                'Churn analysis',
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const _MiniSectionHeading(
                        title: 'EXPERIENCE',
                        lineColor: line,
                      ),
                      const SizedBox(height: 4),
                      const _MiniExperienceBlock(
                        title: 'Client Success Lead  /  Ember Cloud',
                        subtitle: 'Austin, TX',
                        dates: '2021 - Present',
                        bullets: [
                          'Lifted renewal rate by 14% through proactive risk reviews.',
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: _MiniInfoSection(
                              heading: 'EDUCATION',
                              lineColor: line,
                              lines: ['BBA, Communication Strategy', '2018'],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _MiniInfoSection(
                              heading: 'LANGUAGES',
                              lineColor: line,
                              lines: ['English  C2', 'Spanish  B2'],
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _CenteredClassicTemplateArt extends StatelessWidget {
  const _CenteredClassicTemplateArt();

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF2E3135);
    const muted = Color(0xFF6F747B);
    const line = Color(0xFFDADDE2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: 4.7, height: 1.3, color: text),
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: muted),
                    ),
                    child: const Text(
                      'RK',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'RHEA KHANNA',
                    style: TextStyle(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'rhea.khanna@mail.com  |  +1 646 555 0193  |  Boston, MA',
                    style: TextStyle(color: muted, fontSize: 4.9),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const _MiniClassicHeading(title: 'Summary', lineColor: line),
                  const SizedBox(height: 4),
                  const Text(
                    'Operations analyst known for cleaning messy workflows, reporting metrics clearly, and helping service teams run with fewer handoff errors.',
                  ),
                  const SizedBox(height: 6),
                  const _MiniClassicHeading(title: 'Skills', lineColor: line),
                  const SizedBox(height: 4),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MiniBulletColumn(
                          items: [
                            'Excel dashboards',
                            'Process mapping',
                            'Vendor coordination',
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _MiniBulletColumn(
                          items: ['Scheduling', 'KPI reporting', 'SOP writing'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _MiniClassicHeading(
                    title: 'Experience',
                    lineColor: line,
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blue Harbor Logistics',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Operations Analyst',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '2020 - Present',
                              style: TextStyle(
                                color: muted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 12,
                        child: _MiniBulletColumn(
                          items: [
                            'Reduced reporting time from 4 hours to 90 minutes.',
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _MiniClassicHeading(
                    title: 'Education and Training',
                    lineColor: line,
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Northeastern University  |  B.S. Business Analytics',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _MiniClassicHeading(
                    title: 'Languages',
                    lineColor: line,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: const [
                      Expanded(
                        child: _MiniLanguageBar(
                          label: 'English',
                          level: 'C2',
                          fill: 0.9,
                          color: muted,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _MiniLanguageBar(
                          label: 'Hindi',
                          level: 'B2',
                          fill: 0.7,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSidebarTemplateArt extends StatelessWidget {
  const _ProfileSidebarTemplateArt();

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF33373D);
    const text = Color(0xFF2E3135);
    const line = Color(0xFFBFC4CB);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 15,
                decoration: const BoxDecoration(
                  color: dark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 4.6,
                    height: 1.28,
                    color: text,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE7D0B2), Color(0xFFF7ECDD)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF84664A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MATEO VARGAS',
                                  style: TextStyle(
                                    fontSize: 9.4,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                _MiniIconLine(text: 'Seattle, WA 98101'),
                                SizedBox(height: 2),
                                _MiniIconLine(text: '+1 206 555 0117'),
                                SizedBox(height: 2),
                                _MiniIconLine(text: 'mateo.vargas@mail.com'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const _MiniSidebarHeading(
                        title: 'SUMMARY',
                        lineColor: line,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Project coordinator with a sharp eye for handoffs, meeting cadence, and stakeholder updates across marketing and product teams.',
                      ),
                      const SizedBox(height: 6),
                      const _MiniSidebarHeading(
                        title: 'SKILLS',
                        lineColor: line,
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _MiniBulletColumn(
                              items: ['Timeline tracking', 'Meeting notes'],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _MiniBulletColumn(
                              items: [
                                'Cross-team briefs',
                                'Status reports',
                                'Client updates',
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const _MiniSidebarHeading(
                        title: 'EXPERIENCE',
                        lineColor: line,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PROJECT COORDINATOR, 2021 - Present',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Text(
                        'Juniper Studio, Seattle, WA',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const _MiniBulletColumn(
                        items: [
                          'Managed creative timelines for 25+ campaign deliverables.',
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: _MiniInfoSection(
                              heading: 'EDUCATION',
                              lineColor: line,
                              lines: ['B.A. Media Studies', '2021'],
                              sidebarStyle: true,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _MiniInfoSection(
                              heading: 'LANGUAGES',
                              lineColor: line,
                              lines: ['English  C2', 'Portuguese  B1'],
                              sidebarStyle: true,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _CopperSerifTemplateArt extends StatelessWidget {
  const _CopperSerifTemplateArt();

  @override
  Widget build(BuildContext context) {
    const copper = Color(0xFFE7A055);
    const text = Color(0xFF363A40);
    const muted = Color(0xFF737881);
    const line = Color(0xFFD4D8DE);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: 4.5, height: 1.32, color: text),
              child: Column(
                children: [
                  const Text(
                    'SANA MALHOTRA',
                    style: TextStyle(
                      fontSize: 10.2,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.35,
                      color: copper,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'sana.malhotra@mail.com   |   +1 720 555 0132   |   Denver, CO 80202',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 4.6, color: muted),
                  ),
                  const SizedBox(height: 8),
                  const _MiniCenteredDividerHeading(
                    title: 'Summary',
                    accentColor: copper,
                    lineColor: line,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Customer experience specialist with a record of improving in-store service, training floor teams, and lifting repeat customer satisfaction.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 7),
                  const _MiniCenteredDividerHeading(
                    title: 'Skills',
                    accentColor: copper,
                    lineColor: line,
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MiniBulletColumn(
                          items: [
                            'Team coaching',
                            'POS workflows',
                            'Service recovery',
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _MiniBulletColumn(
                          items: [
                            'Inventory checks',
                            'Upselling',
                            'Daily reporting',
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const _MiniCenteredDividerHeading(
                    title: 'Experience',
                    accentColor: copper,
                    lineColor: line,
                  ),
                  const SizedBox(height: 4),
                  const _MiniExperienceBlock(
                    title: 'Customer Experience Lead  /  Bloom Market',
                    subtitle: 'Denver, CO',
                    dates: '2022 - Present',
                    bullets: [
                      'Raised repeat-customer satisfaction by 18% with staff coaching.',
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _MiniCenteredDividerHeading(
                    title: 'Education and Training',
                    accentColor: copper,
                    lineColor: line,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Metro State University   |   B.A. Business Communication   |   2021',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 7),
                  const _MiniCenteredDividerHeading(
                    title: 'Languages',
                    accentColor: copper,
                    lineColor: line,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: const [
                      Expanded(
                        child: _MiniLanguageBar(
                          label: 'English',
                          level: 'C2',
                          fill: 0.9,
                          color: copper,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _MiniLanguageBar(
                          label: 'Hindi',
                          level: 'B2',
                          fill: 0.74,
                          color: copper,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitBannerTemplateArt extends StatelessWidget {
  const _SplitBannerTemplateArt();

  @override
  Widget build(BuildContext context) {
    const copper = Color(0xFFEE9938);
    const line = Color(0xFFD7DBE0);
    const text = Color(0xFF33373D);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: const BoxDecoration(
                  color: copper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'AARAV\nSHAH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 4.5,
                        height: 1.35,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('aarav.shah@mail.com'),
                          SizedBox(height: 2),
                          Text('+1 312 555 0108'),
                          SizedBox(height: 2),
                          Text('Chicago, IL 60611'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 4.5,
                    height: 1.32,
                    color: text,
                  ),
                  child: Column(
                    children: [
                      const _MiniSplitSection(
                        title: 'SUMMARY',
                        accentColor: copper,
                        lineColor: line,
                        child: Text(
                          'Retail team lead focused on service quality, cross-selling, and dependable floor execution during peak traffic windows.',
                        ),
                      ),
                      const SizedBox(height: 6),
                      const _MiniSplitSection(
                        title: 'SKILLS',
                        accentColor: copper,
                        lineColor: line,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MiniBulletColumn(
                                items: [
                                  'Store operations',
                                  'Sales coaching',
                                  'Floor coverage',
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _MiniBulletColumn(
                                items: [
                                  'Register accuracy',
                                  'Customer support',
                                  'Daily cash close',
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const _MiniSplitSection(
                        title: 'EXPERIENCE',
                        accentColor: copper,
                        lineColor: line,
                        child: Column(
                          children: [
                            _MiniExperienceBlock(
                              title: 'Store Lead  /  North Harbor',
                              subtitle: 'Chicago, IL',
                              dates: '2021 - Present',
                              bullets: [
                                'Improved add-on sales with guided floor coaching and roleplay.',
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const _MiniSplitSection(
                        title: 'EDUCATION',
                        accentColor: copper,
                        lineColor: line,
                        child: Text(
                          'DePaul University  |  B.S. Retail Management  |  2020',
                        ),
                      ),
                      const SizedBox(height: 6),
                      _MiniSplitSection(
                        title: 'LANGUAGES',
                        accentColor: copper,
                        lineColor: line,
                        child: Row(
                          children: const [
                            Expanded(
                              child: _MiniLanguageBar(
                                label: 'English',
                                level: 'C2',
                                fill: 0.88,
                                color: copper,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _MiniLanguageBar(
                                label: 'Gujarati',
                                level: 'B2',
                                fill: 0.72,
                                color: copper,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _MonogramSidebarTemplateArt extends StatelessWidget {
  const _MonogramSidebarTemplateArt();

  @override
  Widget build(BuildContext context) {
    const copper = Color(0xFFE39A3A);
    const dark = Color(0xFF17181A);
    const text = Color(0xFF2F343A);
    const muted = Color(0xFF70757D);
    const line = Color(0xFFD5D9DE);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: 4.55, height: 1.33, color: text),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    padding: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: line)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          color: dark,
                          child: const Text(
                            'L',
                            style: TextStyle(
                              color: copper,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Leena\nKapoor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: copper,
                            fontSize: 6.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '+1 415 555 0164\nleena.kapoor@mail.com\nSan Jose, CA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 4.3,
                            color: muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniMonogramSectionHeading(title: 'SUMMARY'),
                        SizedBox(height: 3),
                        Text(
                          'Program assistant with strong follow-through across scheduling, documentation, and cross-functional communication.',
                        ),
                        SizedBox(height: 6),
                        _MiniMonogramSectionHeading(title: 'SKILLS'),
                        SizedBox(height: 3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MiniBulletColumn(
                                items: [
                                  'Calendar support',
                                  'Meeting prep',
                                  'Vendor follow-up',
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _MiniBulletColumn(
                                items: [
                                  'Records upkeep',
                                  'Email drafting',
                                  'Task tracking',
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        _MiniMonogramSectionHeading(title: 'EXPERIENCE'),
                        SizedBox(height: 3),
                        _MiniExperienceBlock(
                          title: 'Program Assistant  /  Brightwell Health',
                          subtitle: 'San Jose, CA',
                          dates: '2020 - Present',
                          bullets: [
                            'Coordinated scheduling and materials for 30+ weekly sessions.',
                          ],
                        ),
                        SizedBox(height: 6),
                        _MiniMonogramSectionHeading(title: 'EDUCATION'),
                        SizedBox(height: 3),
                        Text(
                          'San Jose State University  |  B.A. Public Administration',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6),
                        _MiniMonogramSectionHeading(title: 'LANGUAGES'),
                        SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniLanguageBar(
                                label: 'English',
                                level: 'C2',
                                fill: 0.88,
                                color: copper,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _MiniLanguageBar(
                                label: 'Punjabi',
                                level: 'B2',
                                fill: 0.74,
                                color: copper,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniSectionHeading extends StatelessWidget {
  const _MiniSectionHeading({required this.title, required this.lineColor});

  final String title;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 5.6,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.25,
          ),
        ),
        const SizedBox(height: 3),
        Container(height: 0.8, color: lineColor),
      ],
    );
  }
}

class _MiniCenteredDividerHeading extends StatelessWidget {
  const _MiniCenteredDividerHeading({
    required this.title,
    required this.accentColor,
    required this.lineColor,
  });

  final String title;
  final Color accentColor;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 0.8, color: lineColor)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 5.8,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: Container(height: 0.8, color: lineColor)),
      ],
    );
  }
}

class _MiniClassicHeading extends StatelessWidget {
  const _MiniClassicHeading({required this.title, required this.lineColor});

  final String title;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 6),
        Expanded(child: Container(height: 0.8, color: lineColor)),
      ],
    );
  }
}

class _MiniSplitSection extends StatelessWidget {
  const _MiniSplitSection({
    required this.title,
    required this.accentColor,
    required this.lineColor,
    required this.child,
  });

  final String title;
  final Color accentColor;
  final Color lineColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 5.5,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ),
        Container(width: 0.8, height: 30, color: lineColor),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _MiniSidebarHeading extends StatelessWidget {
  const _MiniSidebarHeading({required this.title, required this.lineColor});

  final String title;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            title,
            style: const TextStyle(fontSize: 5.8, fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(child: Container(height: 1.1, color: lineColor)),
      ],
    );
  }
}

class _MiniMonogramSectionHeading extends StatelessWidget {
  const _MiniMonogramSectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 6.2, fontWeight: FontWeight.w800),
    );
  }
}

class _MiniBulletColumn extends StatelessWidget {
  const _MiniBulletColumn({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.w700)),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

class _MiniExperienceBlock extends StatelessWidget {
  const _MiniExperienceBlock({
    required this.title,
    required this.subtitle,
    required this.dates,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final String dates;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF6C7178)),
                  ),
                ],
              ),
            ),
            Text(
              dates,
              style: const TextStyle(
                color: Color(0xFF6C7178),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        _MiniBulletColumn(items: bullets),
      ],
    );
  }
}

class _MiniInfoSection extends StatelessWidget {
  const _MiniInfoSection({
    required this.heading,
    required this.lineColor,
    required this.lines,
    this.sidebarStyle = false,
  });

  final String heading;
  final Color lineColor;
  final List<String> lines;
  final bool sidebarStyle;

  @override
  Widget build(BuildContext context) {
    final headingWidget = sidebarStyle
        ? _MiniSidebarHeading(title: heading, lineColor: lineColor)
        : _MiniSectionHeading(title: heading, lineColor: lineColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headingWidget,
        const SizedBox(height: 4),
        for (final line in lines)
          Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(line)),
      ],
    );
  }
}

class _MiniLanguageBar extends StatelessWidget {
  const _MiniLanguageBar({
    required this.label,
    required this.level,
    required this.fill,
    required this.color,
  });

  final String label;
  final String level;
  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(level),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 2.4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fill,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniIconLine extends StatelessWidget {
  const _MiniIconLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF444950),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF6A7077))),
        ),
      ],
    );
  }
}
