import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/resume_text_font.dart';
import '../shared/resume_preview_card.dart';
import '../shared/view_models.dart';

enum _TemplateSegment { resume, coverLetter }

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({
    super.key,
    this.onCreateResume,
    this.onTemplateSelected,
    this.selectedTemplate,
    this.onCoverLetterTemplateSelected,
    this.selectedCoverLetterTemplate,
  });

  final VoidCallback? onCreateResume;
  final ValueChanged<ResumeTemplate>? onTemplateSelected;
  final ResumeTemplate? selectedTemplate;
  final ValueChanged<CoverLetterTemplate>? onCoverLetterTemplateSelected;
  final CoverLetterTemplate? selectedCoverLetterTemplate;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  _TemplateSegment _selectedSegment = _TemplateSegment.resume;

  @override
  void initState() {
    super.initState();
    if (widget.onCoverLetterTemplateSelected != null &&
        widget.onTemplateSelected == null) {
      _selectedSegment = _TemplateSegment.coverLetter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<ResumeLibraryViewModel?>(context);
    final isResumeTemplatePicker = widget.onTemplateSelected != null;
    final isCoverLetterTemplatePicker =
        widget.onCoverLetterTemplateSelected != null;
    final isTemplatePicker =
        isResumeTemplatePicker || isCoverLetterTemplatePicker;
    final activeTemplate = (widget.selectedTemplate ?? library?.defaultTemplate)
        ?.userFacingTemplate;
    final activeCoverLetterTemplate = widget.selectedCoverLetterTemplate;
    final visibleItems = isResumeTemplatePicker
        ? _resumeTemplateCards
        : isCoverLetterTemplatePicker
        ? _coverLetterTemplateCards
        : _selectedSegment == _TemplateSegment.resume
        ? _resumeTemplateCards
        : _coverLetterTemplateCards;
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;
    final blue = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final bottomSafeInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 160 + bottomSafeInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isTemplatePicker) ...[
            isCupertino
                ? SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<_TemplateSegment>(
                      key: const Key('template-segmented-button'),
                      groupValue: _selectedSegment,
                      proportionalWidth: true,
                      onValueChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() => _selectedSegment = value);
                      },
                      children: {
                        _TemplateSegment.resume: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'Resume',
                            style: TextStyle(
                              fontSize: 17,
                              color: _selectedSegment == _TemplateSegment.resume
                                  ? blue
                                  : inactiveColor,
                            ),
                          ),
                        ),
                        _TemplateSegment.coverLetter: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'Cover Letter',
                            style: TextStyle(
                              fontSize: 17,
                              color:
                                  _selectedSegment ==
                                      _TemplateSegment.coverLetter
                                  ? blue
                                  : inactiveColor,
                            ),
                          ),
                        ),
                      },
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_TemplateSegment>(
                      key: const Key('template-segmented-button'),
                      expandedInsets: EdgeInsets.zero,
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        selectedForegroundColor: blue,
                        foregroundColor: inactiveColor,
                        textStyle: const TextStyle(fontSize: 17),
                      ),
                      segments: const [
                        ButtonSegment<_TemplateSegment>(
                          value: _TemplateSegment.resume,
                          label: Text('Resume'),
                        ),
                        ButtonSegment<_TemplateSegment>(
                          value: _TemplateSegment.coverLetter,
                          label: Text('Cover Letter'),
                        ),
                      ],
                      selected: {_selectedSegment},
                      onSelectionChanged: (value) {
                        setState(() => _selectedSegment = value.first);
                      },
                    ),
                  ),
            const SizedBox(height: 20),
          ],
          GridView.builder(
            key: const Key('template-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.66,
            ),
            itemBuilder: (context, index) {
              final item = visibleItems[index];
              final selected =
                  (isResumeTemplatePicker &&
                      item.resumeTemplate != null &&
                      item.resumeTemplate == activeTemplate) ||
                  (isCoverLetterTemplatePicker &&
                      item.coverLetterTemplate != null &&
                      item.coverLetterTemplate == activeCoverLetterTemplate);

              return _TemplateTile(
                item: item,
                selected: selected,
                onTap: () {
                  if (widget.onTemplateSelected != null &&
                      item.resumeTemplate != null) {
                    widget.onTemplateSelected!(item.resumeTemplate!);
                    return;
                  }
                  if (widget.onCoverLetterTemplateSelected != null &&
                      item.coverLetterTemplate != null) {
                    widget.onCoverLetterTemplateSelected!(
                      item.coverLetterTemplate!,
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _TemplateDetailScreen(
                        item: item,
                        onUseTemplate: item.resumeTemplate == null
                            ? null
                            : () {
                                library?.setDefaultTemplate(
                                  item.resumeTemplate!,
                                );
                                Navigator.of(context).pop();
                                widget.onCreateResume?.call();
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
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        titleSpacing: 2,
        title: Text(item.headline),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: KeyedSubtree(
                      key: Key('template-detail-preview-${item.id}'),
                      child: item.resumeTemplate != null
                          ? _ResumeTemplateDetailPreview(item: item)
                          : _TemplatePreviewArt(
                              item: item,
                              showPremiumBadgeOnPage: true,
                              premiumBadgeRightPadding: 10,
                              premiumBadgeSize: 18,
                              badgeMetricsInScreenPixels: true,
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
      color: Colors.transparent,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                child: Column(
                  children: [
                    Expanded(
                      child: KeyedSubtree(
                        key: Key('template-image-${item.id}'),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _TemplatePreviewArt(item: item),
                            if (item.isPremium)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 20,
                                    bottom: 10,
                                  ),
                                  child: Image.asset(
                                    'assets/premium_badge.png',
                                    width: 18,
                                    height: 18,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.headline,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 7,
                  right: 19,
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
    );
  }
}

const _templateCards = <_TemplateTileData>[
  _TemplateTileData(
    id: 'dark-header',
    resumeTemplate: ResumeTemplate.corporate,
    previewKind: _TemplatePreviewKind.darkHeaderResume,
    headline: 'Dark Header',
    caption: 'Bold top band with compact professional sections.',
    isPremium: false,
  ),
  _TemplateTileData(
    id: 'profile-sidebar',
    resumeTemplate: ResumeTemplate.creative,
    previewKind: _TemplatePreviewKind.profileSidebarResume,
    headline: 'Profile Sidebar',
    caption: 'Profile-led layout with strong visual anchors.',
    isPremium: true,
  ),
  _TemplateTileData(
    id: 'classic-sidebar',
    resumeTemplate: ResumeTemplate.classicSidebar,
    previewKind: _TemplatePreviewKind.classicSidebarResume,
    headline: 'Classic Sidebar',
    caption: 'Soft left rail with photo-led identity and structured sections.',
    isPremium: true,
  ),
];

const _resumeTemplateCards = _templateCards;

const _coverLetterTemplateCards = <_TemplateTileData>[
  _TemplateTileData(
    id: 'executive-note',
    coverLetterTemplate: CoverLetterTemplate.executiveNote,
    previewKind: _TemplatePreviewKind.executiveNoteCoverLetter,
    headline: 'Executive Note',
    caption: 'Clean professional cover letter with a strong header block.',
    isPremium: true,
  ),
  _TemplateTileData(
    id: 'minimal-letter',
    coverLetterTemplate: CoverLetterTemplate.minimalLetter,
    previewKind: _TemplatePreviewKind.minimalCoverLetter,
    headline: 'Minimal Letter',
    caption: 'Centered and airy layout with restrained modern spacing.',
    isPremium: true,
  ),
  _TemplateTileData(
    id: 'sidebar-letter',
    coverLetterTemplate: CoverLetterTemplate.sidebarLetter,
    previewKind: _TemplatePreviewKind.sidebarCoverLetter,
    headline: 'Sidebar Letter',
    caption: 'A bolder cover letter with a left rail for contact details.',
    isPremium: true,
  ),
];

class _TemplateTileData {
  const _TemplateTileData({
    required this.id,
    this.resumeTemplate,
    this.coverLetterTemplate,
    required this.previewKind,
    required this.headline,
    required this.caption,
    this.isPremium = false,
  });

  final String id;
  final ResumeTemplate? resumeTemplate;
  final CoverLetterTemplate? coverLetterTemplate;
  final _TemplatePreviewKind previewKind;
  final String headline;
  final String caption;
  final bool isPremium;
}

enum _TemplatePreviewKind {
  darkHeaderResume,
  profileSidebarResume,
  classicSidebarResume,
  executiveNoteCoverLetter,
  minimalCoverLetter,
  sidebarCoverLetter,
}

class _TemplatePreviewArt extends StatelessWidget {
  const _TemplatePreviewArt({
    required this.item,
    this.showPremiumBadgeOnPage = false,
    this.premiumBadgeRightPadding = 20,
    this.premiumBadgeSize = 18,
    this.badgeMetricsInScreenPixels = false,
  });

  final _TemplateTileData item;
  final bool showPremiumBadgeOnPage;
  final double premiumBadgeRightPadding;
  final double premiumBadgeSize;
  final bool badgeMetricsInScreenPixels;

  @override
  Widget build(BuildContext context) {
    final preview = switch (item.previewKind) {
      _TemplatePreviewKind.darkHeaderResume => const _DarkHeaderTemplateArt(),
      _TemplatePreviewKind.profileSidebarResume =>
        showPremiumBadgeOnPage
            ? _ResumeTemplatePreviewArt(resume: _profileSidebarTemplateResume)
            : const _ProfileSidebarTemplateArtCompact(),
      _TemplatePreviewKind.classicSidebarResume => _ResumeTemplatePreviewArt(
        resume: _classicSidebarTemplateResume,
      ),
      _TemplatePreviewKind.executiveNoteCoverLetter =>
        const _ExecutiveNoteCoverLetterArt(),
      _TemplatePreviewKind.minimalCoverLetter => const _MinimalCoverLetterArt(),
      _TemplatePreviewKind.sidebarCoverLetter => const _SidebarCoverLetterArt(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / 168;
        final scaleY = constraints.maxHeight / 252;
        final scale = math.min(scaleX, scaleY).toDouble();
        final safeScale = (scale.isFinite && scale > 0) ? scale : 1.0;
        final double badgeRightPadding = badgeMetricsInScreenPixels
            ? premiumBadgeRightPadding / safeScale
            : premiumBadgeRightPadding;
        final double badgeBottomPadding = badgeMetricsInScreenPixels
            ? 10.0 / safeScale
            : 10.0;
        final double badgeSize = badgeMetricsInScreenPixels
            ? premiumBadgeSize / safeScale
            : premiumBadgeSize;

        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 168,
            height: 252,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontFamily: 'Calibri'),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: preview,
                      ),
                    ),
                  ),
                ),
                if (showPremiumBadgeOnPage && item.isPremium)
                  Positioned(
                    right: badgeRightPadding,
                    bottom: badgeBottomPadding,
                    child: Image.asset(
                      'assets/premium_badge.png',
                      width: badgeSize,
                      height: badgeSize,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResumeTemplateDetailPreview extends StatelessWidget {
  const _ResumeTemplateDetailPreview({required this.item});

  final _TemplateTileData item;

  @override
  Widget build(BuildContext context) {
    final template = item.resumeTemplate!;
    if (template == ResumeTemplate.corporate) {
      return const _LargeTemplateArtPreview(child: _DarkHeaderTemplateArt());
    }
    if (template == ResumeTemplate.creative) {
      return const _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _ProfileSidebarTemplateArtCompact(),
      );
    }

    final sampleResume = switch (template) {
      ResumeTemplate.corporate => _darkHeaderTemplateResume,
      ResumeTemplate.creative => _profileSidebarTemplateResume,
      ResumeTemplate.classicSidebar => _classicSidebarTemplateResume,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _ResumeTemplatePreviewArt(resume: sampleResume),
      ),
    );
  }
}

class _LargeTemplateArtPreview extends StatelessWidget {
  const _LargeTemplateArtPreview({
    required this.child,
    this.showPremiumBadge = false,
  });

  final Widget child;
  final bool showPremiumBadge;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / 240;
        final scaleY = constraints.maxHeight / 360;
        final scale = math.min(scaleX, scaleY).toDouble();
        final safeScale = (scale.isFinite && scale > 0) ? scale : 1.0;
        final badgeSize = 18.0 / safeScale;
        final badgeInset = 12.0 / safeScale;

        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 240,
            height: 360,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: Colors.white, child: child),
                ),
                if (showPremiumBadge)
                  Positioned(
                    right: badgeInset,
                    bottom: badgeInset,
                    child: Image.asset(
                      'assets/premium_badge.png',
                      width: badgeSize,
                      height: badgeSize,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final ResumeData _darkHeaderTemplateResume = ResumeData(
  id: 'template-dark-header',
  title: 'Dark Header Template',
  fullName: 'Maya Lopez',
  jobTitle: 'Client Success Manager',
  email: 'maya@sample.in',
  phone: '+1 512 555 0148',
  location: 'Austin, TX',
  website: 'portfolio.dev/maya',
  summary:
      'Client success manager focused on renewals, onboarding, and long-term account health for B2B software customers.',
  template: ResumeTemplate.corporate,
  workExperiences: const [
    WorkExperience(
      role: 'Client Success Lead',
      company: 'Ember Cloud',
      startDate: '2021',
      endDate: 'Present',
      description: '',
      bullets: [
        'Lifted renewal rate by 14% through proactive risk reviews and structured customer check-ins.',
      ],
    ),
  ],
  education: const [
    EducationItem(
      institution: 'Northeastern University',
      degree: 'BBA, Communication Strategy',
      startDate: '2014',
      endDate: '2018',
      score: '',
    ),
  ],
  skills: const [
    'Renewal strategy',
    'CRM operations',
    'Lifecycle emails',
    'Churn analysis',
  ],
  projects: const [
    ProjectItem(
      title: 'Customer Health Dashboard',
      bullets: ['Shipped dashboard for weekly customer health reviews.'],
    ),
  ],
  customSections: const [],
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  githubLink: 'github.com/mayalopez',
  linkedinLink: 'linkedin.com/in/mayalopez',
  profileImagePath: '',
  resumeTextFont: ResumeTextFont.calibri,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: true,
  bodyFontPt: 13,
  corporateColorPresetIndex: 0,
);

final ResumeData _profileSidebarTemplateResume = ResumeData(
  id: 'template-profile-sidebar',
  title: 'Profile Sidebar Template',
  fullName: '',
  jobTitle: 'Project Coordinator',
  email: 'mateo@sample.in',
  phone: '+1 206 555 0117',
  location: 'Seattle, WA',
  website: 'mateovargas.dev',
  summary:
      'Project coordinator focused on team handoffs, timeline tracking, and stakeholder updates.',
  template: ResumeTemplate.creative,
  workExperiences: const [
    WorkExperience(
      role: 'Project Coordinator',
      company: 'Juniper Studio',
      startDate: '2021',
      endDate: 'Present',
      description: '',
      bullets: ['Managed creative timelines for campaign deliverables.'],
    ),
  ],
  education: const [
    EducationItem(
      institution: 'University of Washington',
      degree: 'B.A. Media Studies',
      startDate: '2017',
      endDate: '2021',
      score: '',
    ),
  ],
  skills: const ['Timeline tracking', 'Meeting notes', 'Status reports'],
  projects: const [
    ProjectItem(
      title: 'Campaign Launch Tracker',
      bullets: ['Built tracker for campaign milestones and owner handoffs.'],
    ),
  ],
  customSections: const [],
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  githubLink: 'github.com/mateovargas',
  linkedinLink: '',
  profileImagePath: '',
  resumeTextFont: ResumeTextFont.calibri,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: true,
  bodyFontPt: 13,
  corporateColorPresetIndex: 3,
);

final ResumeData _classicSidebarTemplateResume = ResumeData(
  id: 'template-classic-sidebar',
  title: 'Classic Sidebar Template',
  fullName: 'Avery Brooks',
  jobTitle: 'Financial Analyst',
  email: 'avery@sample.in',
  phone: '+1 617 555 0142',
  location: 'Boston, MA 02101',
  website: 'averybrooks.dev',
  summary:
      'Financial analyst with experience supporting budgets, planning reviews, and decision-making through clear reporting and grounded operational analysis.',
  template: ResumeTemplate.classicSidebar,
  workExperiences: const [
    WorkExperience(
      role: 'Financial Analyst',
      company: 'GEO Advisory',
      startDate: 'Apr 2018',
      endDate: 'Present',
      description: '',
      bullets: [
        'Built operating budget models that reduced quarterly variance across business units.',
        'Prepared financial summaries for leadership reviews and monthly planning cycles.',
      ],
    ),
    WorkExperience(
      role: 'Analyst',
      company: 'North Harbor Group',
      startDate: 'Sep 2014',
      endDate: 'Mar 2018',
      description: '',
      bullets: [
        'Tracked revenue, forecast updates, and project spend across finance and operations.',
      ],
    ),
  ],
  education: const [
    EducationItem(
      institution: 'Boston University',
      degree: 'B.S. Finance',
      startDate: '2010',
      endDate: '2014',
      score: 'Magna cum laude',
    ),
  ],
  skills: const [
    'Financial analysis',
    'Strategic planning',
    'Trend analysis',
    'Budget tracking',
    'Team leadership',
  ],
  projects: const [
    ProjectItem(
      title: 'Budget Reporting Framework',
      bullets: [
        'Standardized monthly reporting decks used in leadership finance reviews.',
      ],
    ),
  ],
  customSections: const [
    CustomSectionItem(
      title: 'Languages',
      content: '',
      layoutMode: CustomSectionLayoutMode.bullets,
      bullets: ['English', 'German'],
    ),
  ],
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  githubLink: '',
  linkedinLink: 'linkedin.com/in/averybrooks',
  profileImagePath: '',
  resumeTextFont: ResumeTextFont.calibri,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: true,
  bodyFontPt: 13,
  corporateColorPresetIndex: 2,
);

class _ResumeTemplatePreviewArt extends StatelessWidget {
  const _ResumeTemplatePreviewArt({required this.resume});

  final ResumeData resume;
  static const double _pageWidth = 210;
  static const double _pageHeight = 297;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          constraints.maxWidth / _pageWidth,
          constraints.maxHeight / _pageHeight,
        );
        final safeScale = (scale.isFinite && scale > 0) ? scale : 1.0;

        return ColoredBox(
          color: Colors.white,
          child: ClipRect(
            child: OverflowBox(
              minWidth: _pageWidth,
              maxWidth: _pageWidth,
              minHeight: _pageHeight,
              maxHeight: _pageHeight,
              alignment: Alignment.topCenter,
              child: Transform.scale(
                scale: safeScale,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: _pageWidth,
                  height: _pageHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ResumePreviewCanvas(
                      resume: resume,
                      showDebugLabel: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
        borderRadius: BorderRadius.zero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
                decoration: const BoxDecoration(
                  color: header,
                  borderRadius: BorderRadius.vertical(top: Radius.zero),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 33,
                      height: 33,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70),
                      ),
                      child: const Text(
                        'ML',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.2,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Austin, TX 78701 | +1 512 555 0148',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 4.5,
                              height: 1.35,
                            ),
                          ),
                          Text(
                            'portfolio.dev/maya | github.com/mayalopez | linkedin.com/in/mayalopez',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 4.5,
                              height: 1.35,
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
                    height: 1.3,
                    color: text,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MiniSectionHeading(
                        title: 'SUMMARY',
                        lineColor: line,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Client success manager focused on renewals and onboarding.',
                      ),
                      const SizedBox(height: 4),
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
                      const SizedBox(height: 4),
                      const _MiniSectionHeading(
                        title: 'EDUCATION',
                        lineColor: line,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Northeastern University | 2014 - 2018',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      const Text('BBA, Communication Strategy'),
                      const SizedBox(height: 4),
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
                              items: ['Renewal strategy', 'CRM operations'],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _MiniBulletColumn(
                              items: ['Lifecycle emails', 'Churn analysis'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const _MiniSectionHeading(
                        title: 'PROJECTS',
                        lineColor: line,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Customer Health Dashboard',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      const Text('Shipped dashboard for weekly reviews.'),
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

class _ProfileSidebarTemplateArtCompact extends StatelessWidget {
  const _ProfileSidebarTemplateArtCompact();

  @override
  Widget build(BuildContext context) {
    const rail = Color(0xFFF4E6DA);
    const dark = Color(0xFF33373D);
    const text = Color(0xFF2E3135);
    const line = Color(0xFFBFC4CB);
    const muted = Color(0xFF6E747B);
    final avatarBackground = Color.lerp(
      rail,
      Colors.black,
      0.10,
    )!.withValues(alpha: 0.4);

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 48,
              color: rail,
              padding: const EdgeInsets.fromLTRB(0, 9, 0, 8),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 3.8,
                  height: 1.35,
                  color: text,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: _MiniAvatarBlock(
                        backgroundColor: avatarBackground,
                        textColor: Color(0xFFE17A3B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(6, 0, 4, 0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 1,
                        child: ColoredBox(color: line),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: const _MiniAccentDotLine(text: 'Seattle, WA'),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: const _MiniAccentDotLine(text: '+1 206 555 0117'),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: const _MiniAccentDotLine(text: 'mateo@sample.in'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 4.6,
                      height: 1.28,
                      color: text,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROJECT COORDINATOR',
                          style: TextStyle(
                            fontSize: 8.8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Marketing operations and handoff management',
                          style: TextStyle(color: muted),
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
                        const SizedBox(height: 7),
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
                        const SizedBox(height: 7),
                        const _MiniSidebarHeading(
                          title: 'EDUCATION',
                          lineColor: line,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'B.A. MEDIA STUDIES, 2021',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Text(
                          'University of Washington',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const _MiniSidebarHeading(
                          title: 'PROJECTS',
                          lineColor: line,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CAMPAIGN LAUNCH TRACKER',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const _MiniBulletColumn(
                          items: [
                            'Built tracker for campaign milestones and owner handoffs.',
                          ],
                        ),
                        const SizedBox(height: 7),
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
                                items: ['Timeline tracking'],
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _MiniBulletColumn(
                                items: ['Cross-team briefs', 'Status reports'],
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
          ],
        ),
      ),
    );
  }
}

class _ExecutiveNoteCoverLetterArt extends StatelessWidget {
  const _ExecutiveNoteCoverLetterArt();

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F3A5F);
    const text = Color(0xFF31363C);
    const muted = Color(0xFF75808C);
    const line = Color(0xFFDCE3EA);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 4.45, height: 1.38, color: text),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MAYA FERNANDES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'mfernandes@mail.com  |  +1 646 555 0131  |  Brooklyn, NY',
                        style: TextStyle(
                          color: Color(0xFFD7E4F5),
                          fontSize: 4.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                const Text('March 30, 2026', style: TextStyle(color: muted)),
                const SizedBox(height: 3),
                const Text(
                  'Hiring Manager\nNorthpeak Studio\nNew York, NY',
                  style: TextStyle(color: muted, height: 1.38),
                ),
                const SizedBox(height: 4),
                Container(height: 1, color: line),
                const SizedBox(height: 4),
                const Text(
                  'Dear Hiring Manager,',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                const _MiniCoverLetterParagraph(
                  text:
                      'I am excited to apply for the Brand Marketing Manager role at Northpeak Studio, bringing experience across launch planning, storytelling, and growth-minded execution.',
                ),
                const SizedBox(height: 3),
                const _MiniCoverLetterParagraph(
                  text:
                      'I recently led cross-functional campaigns and improved conversion by aligning creative direction, paid channels, and customer-facing messaging.',
                ),
                const Spacer(),
                Container(height: 1, color: line),
                const SizedBox(height: 4),
                const Text(
                  'Sincerely,',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text('Maya Fernandes'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalCoverLetterArt extends StatelessWidget {
  const _MinimalCoverLetterArt();

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF2E3138);
    const muted = Color(0xFF7A818A);
    const accent = Color(0xFFB86D3A);
    const line = Color(0xFFD9DDE3);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 4.6, height: 1.45, color: text),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'NOAH PARK',
                  style: TextStyle(
                    fontSize: 8.4,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'noah.park@mail.com  |  +1 206 555 0126  |  Seattle, WA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 4.1),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: line)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'COVER LETTER',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: line)),
                  ],
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dear Product Team,',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 5),
                const _MiniCoverLetterParagraph(
                  text:
                      'I am writing to express my interest in the Product Operations role at Atlas Cloud. My background combines systems thinking, stakeholder communication, and a steady focus on improving how teams deliver work.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                const _MiniCoverLetterParagraph(
                  text:
                      'Across recent projects, I streamlined handoffs, documented repeatable workflows, and created lightweight reporting that helped leaders spot blockers faster and move with more confidence.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                const _MiniCoverLetterParagraph(
                  text:
                      'I would love to contribute that same blend of structure and adaptability to Atlas Cloud. Thank you for considering my application.',
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Best regards,'),
                ),
                const SizedBox(height: 2),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Noah Park',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _SidebarCoverLetterArt extends StatelessWidget {
  const _SidebarCoverLetterArt();

  @override
  Widget build(BuildContext context) {
    const rail = Color(0xFF262A31);
    const gold = Color(0xFFD5923B);
    const text = Color(0xFF2E3238);
    const muted = Color(0xFF717880);
    const line = Color(0xFFD8DDE3);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 42,
              color: rail,
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
              child: const DefaultTextStyle(
                style: TextStyle(
                  fontSize: 4.1,
                  height: 1.42,
                  color: Color(0xFFE7EDF6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AK',
                      style: TextStyle(
                        color: gold,
                        fontSize: 8.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Aisha Khan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text('aisha.khan@mail.com\n+91 98765 43120\nMumbai, India'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 10, 10, 12),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 4.6,
                    height: 1.45,
                    color: text,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OPERATIONS COORDINATOR',
                        style: TextStyle(
                          fontSize: 7.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'April 1, 2026  |  Horizon Logistics  |  Pune, India',
                        style: TextStyle(color: muted, fontSize: 4.1),
                      ),
                      const SizedBox(height: 6),
                      Container(height: 1, color: line),
                      const SizedBox(height: 6),
                      const Text(
                        'Dear Hiring Committee,',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const _MiniCoverLetterParagraph(
                        text:
                            'I am applying for the Operations Coordinator opportunity at Horizon Logistics. I enjoy creating structure in fast-moving environments and supporting teams with dependable processes, communication, and follow-through.',
                      ),
                      const SizedBox(height: 4),
                      const _MiniCoverLetterParagraph(
                        text:
                            'My recent work included coordinating schedules, tracking execution details, and improving reporting visibility so cross-functional teams could respond to issues more quickly and keep projects on pace.',
                      ),
                      const SizedBox(height: 4),
                      const _MiniCoverLetterParagraph(
                        text:
                            'I would be excited to bring that organized, service-minded approach to Horizon Logistics. Thank you for your consideration.',
                      ),
                      const Spacer(),
                      const Text('Warm regards,'),
                      const SizedBox(height: 2),
                      const Text(
                        'Aisha Khan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCoverLetterParagraph extends StatelessWidget {
  const _MiniCoverLetterParagraph({
    required this.text,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: 5,
      overflow: TextOverflow.clip,
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

class _MiniAvatarBlock extends StatelessWidget {
  const _MiniAvatarBlock({
    required this.backgroundColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35.2,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: backgroundColor,
      ),
      alignment: Alignment.center,
      child: Text(
        'MV',
        style: TextStyle(
          color: textColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniAccentDotLine extends StatelessWidget {
  const _MiniAccentDotLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 0, right: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE17A3B),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF6E747B))),
        ),
      ],
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
