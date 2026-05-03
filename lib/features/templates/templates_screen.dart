import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/corporate_resume_style.dart';
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
    final showResumeTemplatesSection = isResumeTemplatePicker ||
        (!isCoverLetterTemplatePicker &&
            _selectedSegment == _TemplateSegment.resume);
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
          if (showResumeTemplatesSection && visibleItems.isNotEmpty) ...[
            Text(
              'Professional',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
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
                paletteSeed: library?.selectedResume,
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
                        paletteSeed: library?.selectedResume,
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
          if (showResumeTemplatesSection && visibleItems.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'ATS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              key: const Key('template-grid-ats'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _atsResumeCards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.66,
              ),
              itemBuilder: (context, index) {
                final item = _atsResumeCards[index];
                final selected = isResumeTemplatePicker &&
                    item.resumeTemplate != null &&
                    item.resumeTemplate == activeTemplate;

                return _TemplateTile(
                  item: item,
                  selected: selected,
                  paletteSeed: library?.selectedResume,
                  onTap: () {
                    if (widget.onTemplateSelected != null &&
                        item.resumeTemplate != null) {
                      widget.onTemplateSelected!(item.resumeTemplate!);
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _TemplateDetailScreen(
                          item: item,
                          paletteSeed: library?.selectedResume,
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
        ],
      ),
    );
  }
}

class _TemplateDetailScreen extends StatelessWidget {
  const _TemplateDetailScreen({
    required this.item,
    this.onUseTemplate,
    this.paletteSeed,
  });

  final _TemplateTileData item;
  final VoidCallback? onUseTemplate;
  final ResumeData? paletteSeed;

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
                          ? _ResumeTemplateDetailPreview(
                              item: item,
                              paletteSeed: paletteSeed,
                            )
                          : _TemplatePreviewArt(
                              item: item,
                              paletteSeed: paletteSeed,
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
    this.paletteSeed,
  });

  final _TemplateTileData item;
  final bool selected;
  final VoidCallback onTap;
  final ResumeData? paletteSeed;

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
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
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
                            _TemplatePreviewArt(
                              item: item,
                              paletteSeed: paletteSeed,
                            ),
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

const _professionalResumeCards = <_TemplateTileData>[
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
  _TemplateTileData(
    id: 'details-sidebar',
    resumeTemplate: ResumeTemplate.detailsSidebar,
    previewKind: _TemplatePreviewKind.detailsSidebarResume,
    headline: 'Details Sidebar',
    caption: 'Minimal left details rail with structured content on the right.',
    isPremium: true,
  ),
];

const _resumeTemplateCards = _professionalResumeCards;

const _atsResumeCards = <_TemplateTileData>[
  _TemplateTileData(
    id: 'ats-structured',
    resumeTemplate: ResumeTemplate.atsStructured,
    previewKind: _TemplatePreviewKind.atsStructuredResume,
    headline: 'Structured ATS',
    caption: 'Gray section bands and a centered header for parsers.',
    isPremium: true,
  ),
  _TemplateTileData(
    id: 'ats-serif-rules',
    resumeTemplate: ResumeTemplate.atsSerifRules,
    previewKind: _TemplatePreviewKind.atsSerifRulesResume,
    headline: 'Serif Rules ATS',
    caption: 'Classic rules, bold headings, and aligned dates.',
    isPremium: true,
  ),
  _TemplateTileData(
    id: 'ats-modern-flow',
    resumeTemplate: ResumeTemplate.atsModernFlow,
    previewKind: _TemplatePreviewKind.atsModernFlowResume,
    headline: 'Modern Flow ATS',
    caption: 'Centered contact row with a logical section sequence.',
    isPremium: true,
  ),
  _TemplateTileData(
    id: 'ats-executive',
    resumeTemplate: ResumeTemplate.atsExecutive,
    previewKind: _TemplatePreviewKind.atsExecutiveResume,
    headline: 'Executive ATS',
    caption: 'Uppercase headings and two-column keyword skills.',
    isPremium: true,
  ),
];

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
  _TemplateTileData(
    id: 'classic-business-letter',
    coverLetterTemplate: CoverLetterTemplate.classicBusinessLetter,
    previewKind: _TemplatePreviewKind.classicBusinessCoverLetter,
    headline: 'Classic Business',
    caption:
        'Traditional business letter: date, recipient block, and left-aligned body.',
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
  detailsSidebarResume,
  atsStructuredResume,
  atsSerifRulesResume,
  atsModernFlowResume,
  atsExecutiveResume,
  executiveNoteCoverLetter,
  minimalCoverLetter,
  sidebarCoverLetter,
  classicBusinessCoverLetter,
}

class _TemplatePreviewArt extends StatelessWidget {
  const _TemplatePreviewArt({
    required this.item,
    this.paletteSeed,
    this.showPremiumBadgeOnPage = false,
    this.premiumBadgeRightPadding = 20,
    this.premiumBadgeSize = 18,
    this.badgeMetricsInScreenPixels = false,
  });

  final _TemplateTileData item;
  final ResumeData? paletteSeed;
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
            ? _ResumeTemplatePreviewArt(
                resume: _applyTemplatePreviewPalette(
                  _profileSidebarTemplateResume,
                  paletteSeed,
                ),
              )
            : const _ProfileSidebarTemplateArtCompact(),
      _TemplatePreviewKind.classicSidebarResume =>
        showPremiumBadgeOnPage
            ? _ResumeTemplatePreviewArt(
                resume: _applyTemplatePreviewPalette(
                  _classicSidebarTemplateResume,
                  paletteSeed,
                ),
              )
            : _ClassicSidebarTemplateArtCompact(
                resume: _applyTemplatePreviewPalette(
                  _classicSidebarTemplateResume,
                  paletteSeed,
                ),
              ),
      _TemplatePreviewKind.detailsSidebarResume =>
        showPremiumBadgeOnPage
            ? _ResumeTemplatePreviewArt(
                resume: _applyTemplatePreviewPalette(
                  _detailsSidebarTemplateResume,
                  paletteSeed,
                ),
              )
            : _DetailsSidebarTemplateArtCompact(
                resume: _applyTemplatePreviewPalette(
                  _detailsSidebarTemplateResume,
                  paletteSeed,
                ),
              ),
      _TemplatePreviewKind.atsStructuredResume => _AtsStructuredTemplateArt(
        resume: _applyTemplatePreviewPalette(
          _atsSampleFor(ResumeTemplate.atsStructured),
          paletteSeed,
        ),
      ),
      _TemplatePreviewKind.atsSerifRulesResume => _AtsSerifRulesTemplateArt(
        resume: _applyTemplatePreviewPalette(
          _atsSampleFor(ResumeTemplate.atsSerifRules),
          paletteSeed,
        ),
      ),
      _TemplatePreviewKind.atsModernFlowResume => _AtsModernFlowTemplateArt(
        resume: _applyTemplatePreviewPalette(
          _atsSampleFor(ResumeTemplate.atsModernFlow),
          paletteSeed,
        ),
      ),
      _TemplatePreviewKind.atsExecutiveResume => _AtsExecutiveTemplateArt(
        resume: _applyTemplatePreviewPalette(
          _atsSampleFor(ResumeTemplate.atsExecutive),
          paletteSeed,
        ),
      ),
      _TemplatePreviewKind.executiveNoteCoverLetter =>
        const _ExecutiveNoteCoverLetterArt(),
      _TemplatePreviewKind.minimalCoverLetter => const _MinimalCoverLetterArt(),
      _TemplatePreviewKind.sidebarCoverLetter => const _SidebarCoverLetterArt(),
      _TemplatePreviewKind.classicBusinessCoverLetter =>
        const _ClassicBusinessCoverLetterArt(),
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
  const _ResumeTemplateDetailPreview({required this.item, this.paletteSeed});

  final _TemplateTileData item;
  final ResumeData? paletteSeed;

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
    if (template == ResumeTemplate.classicSidebar) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _ClassicSidebarTemplateArtCompact(
          resume: _applyTemplatePreviewPalette(
            _classicSidebarTemplateResume,
            paletteSeed,
          ),
          detailed: true,
        ),
      );
    }
    if (template == ResumeTemplate.detailsSidebar) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _DetailsSidebarTemplateArtCompact(
          resume: _applyTemplatePreviewPalette(
            _detailsSidebarTemplateResume,
            paletteSeed,
          ),
          detailed: true,
        ),
      );
    }
    if (template == ResumeTemplate.atsStructured) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _AtsStructuredTemplateArt(
          resume: _applyTemplatePreviewPalette(
            _atsSampleFor(ResumeTemplate.atsStructured),
            paletteSeed,
          ),
          detailed: true,
        ),
      );
    }
    if (template == ResumeTemplate.atsSerifRules) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _AtsSerifRulesTemplateArt(
          resume: _applyTemplatePreviewPalette(
            _atsSampleFor(ResumeTemplate.atsSerifRules),
            paletteSeed,
          ),
          detailed: true,
        ),
      );
    }
    if (template == ResumeTemplate.atsModernFlow) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _AtsModernFlowTemplateArt(
          resume: _applyTemplatePreviewPalette(
            _atsSampleFor(ResumeTemplate.atsModernFlow),
            paletteSeed,
          ),
          detailed: true,
        ),
      );
    }
    if (template == ResumeTemplate.atsExecutive) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _AtsExecutiveTemplateArt(
          resume: _applyTemplatePreviewPalette(
            _atsSampleFor(ResumeTemplate.atsExecutive),
            paletteSeed,
          ),
          detailed: true,
        ),
      );
    }

    throw StateError('Unhandled resume template in detail preview: $template');
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

ResumeData _applyTemplatePreviewPalette(
  ResumeData sample,
  ResumeData? paletteSeed,
) {
  if (paletteSeed == null) {
    return sample;
  }

  return sample.copyWith(
    corporateColorPresetIndex: paletteSeed.corporateColorPresetIndex,
  );
}

/// Rich sample used for all four ATS template card arts and detail previews.
final ResumeData _atsFullSampleResume = ResumeData(
  id: 'template-ats-full-sample',
  title: 'ATS Sample Resume',
  fullName: 'Morgan A. Lee',
  jobTitle: 'Senior Program Manager',
  email: 'morgan.lee@professional.example.com',
  phone: '(415) 555-0192',
  location: 'San Francisco, CA 94105',
  website: 'morganlee.dev',
  summary:
      'Delivery-focused program manager with 8+ years aligning engineering, design, and business stakeholders. Known for turning ambiguous goals into phased roadmaps, measurable KPIs, and predictable releases in regulated and high-growth environments.',
  template: ResumeTemplate.atsStructured,
  workExperiences: const [
    WorkExperience(
      role: 'Senior Program Manager',
      company: 'Northwind Analytics',
      startDate: 'Jan 2019',
      endDate: 'Present',
      description: '',
      bullets: [
        'Directed portfolio planning for three product lines with an \$18M annual budget and quarterly executive reviews.',
        'Reduced cross-team dependency delays by 27% through shared milestone dashboards and clearer RACI ownership.',
        'Led vendor selection and contract renewals for analytics and data-pipeline partners.',
      ],
    ),
    WorkExperience(
      role: 'Project Lead',
      company: 'Harbor Systems LLC — Oakland, CA',
      startDate: 'Jun 2015',
      endDate: 'Dec 2018',
      description: '',
      bullets: [
        'Led ERP rollout for 120 users; completed UAT two weeks early with zero Sev-1 defects.',
        'Standardized project intake and status reporting for a 25-person delivery group.',
      ],
    ),
  ],
  education: const [
    EducationItem(
      institution: 'University of California, Berkeley',
      degree: 'MBA, Technology Strategy',
      startDate: '2013',
      endDate: '2015',
      score: "Dean's List",
    ),
    EducationItem(
      institution: 'San José State University',
      degree: 'BS, Industrial Engineering',
      startDate: '2009',
      endDate: '2013',
      score: 'cum laude',
    ),
  ],
  skills: const [
    'Program governance',
    'SQL & Excel modeling',
    'Agile / Scrum',
    'Stakeholder communication',
    'Risk & dependency tracking',
    'Vendor management',
  ],
  projects: const [
    ProjectItem(
      title: 'Forecast Automation Toolkit',
      overview: 'Finance forecasting workflow',
      impact: 'SQL, Python, Airflow',
      bullets: [
        'Partnered with finance to replace spreadsheet forecasts with auditable, versioned pipelines.',
        'Cut monthly close prep from five days to two through automated variance checks.',
      ],
    ),
  ],
  customSections: const [
    CustomSectionItem(
      title: 'Certifications',
      content: '',
      layoutMode: CustomSectionLayoutMode.bullets,
      bullets: [
        'PMP — Project Management Institute (2016)',
        'Agile PM Certificate — Berkeley Extension (2014)',
      ],
    ),
  ],
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  githubLink: 'github.com/malee',
  linkedinLink: 'linkedin.com/in/morganalee',
  profileImagePath: '',
  resumeTextFont: ResumeTextFont.calibri,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: true,
  bodyFontPt: 13,
  corporateColorPresetIndex: 0,
);

ResumeData _atsSampleFor(ResumeTemplate template) =>
    _atsFullSampleResume.copyWith(template: template);

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
  skills: const ['Timeline tracking'],
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
    EducationItem(
      institution: 'Camden High School',
      degree: 'High School Diploma',
      startDate: '2006',
      endDate: '2010',
      score: 'Honor roll',
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
    ProjectItem(
      title: 'Forecast Planning Dashboard',
      bullets: [
        'Built a finance dashboard that gave leaders clearer monthly forecast and variance visibility.',
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

final ResumeData _detailsSidebarTemplateResume = ResumeData(
  id: 'template-details-sidebar',
  title: 'Details Sidebar Template',
  fullName: 'MAYA LPEZ',
  jobTitle: 'Administrative Assistant',
  email: 'kelly.blackwell@example.com',
  phone: '(210) 286-1624',
  location: '1685 N Commerce Island Pkwy, Weston, FL 33326, United States',
  website: '',
  summary:
      'Administrative assistant with 9+ years of experience organizing presentations, preparing facility reports, and maintaining the utmost confidentiality. Possesses a B.A. in history and expertise in Microsoft Excel.',
  template: ResumeTemplate.detailsSidebar,
  workExperiences: const [
    WorkExperience(
      role: 'Administrative Assistant',
      company: 'Redford & Sons, Boston, MA',
      startDate: 'Sep 2017',
      endDate: 'Current',
      description: '',
      bullets: [
        'Scheduled and coordinated meetings, appointments, and travel arrangements for supervisors and C-level executives.',
        'Trained 2 administrative assistants during a period of company expansion to ensure attention to detail and adherence to company standards.',
      ],
    ),
    WorkExperience(
      role: 'Secretary',
      company: 'Bright Spot Ltd., Boston',
      startDate: 'Jun 2016',
      endDate: 'Aug 2017',
      description: '',
      bullets: [
        'Typed documents such as correspondence, drafts, memos, and emails, and prepared 3 reports weekly for management.',
        'Opened, sorted, and distributed incoming messages and correspondence to the appropriate personnel.',
      ],
    ),
  ],
  education: const [
    EducationItem(
      institution: 'Brown University, Providence, RI',
      degree: 'Bachelor of Arts in Finance',
      startDate: '2004',
      endDate: '2009',
      score: '',
    ),
  ],
  skills: const [
    'Analytical Thinking',
    'Tolerant & Flexible',
    'Team Leadership',
    'Organization & Prioritization',
    'Strong Communication',
    'Microsoft Excel',
  ],
  projects: const [],
  customSections: const [],
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  githubLink: '',
  linkedinLink: '',
  profileImagePath: '',
  resumeTextFont: ResumeTextFont.calibri,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: false,
  bodyFontPt: 13,
  corporateColorPresetIndex: 4,
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
                      const _MiniBulletColumn(
                        items: ['Renewal strategy', 'CRM operations'],
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

List<String> _templateArtProjectBullets(ProjectItem p) {
  final lines = p.bullets.where((b) => b.trim().isNotEmpty).toList();
  if (lines.isNotEmpty) {
    return lines;
  }
  return [p.overview.trim(), p.impact.trim()]
      .where((s) => s.isNotEmpty)
      .toList();
}

class _AtsStructuredTemplateArt extends StatelessWidget {
  const _AtsStructuredTemplateArt({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  static const Color _ink = Color(0xFF1F2937);
  static const Color _band = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final fs = detailed ? 4.75 : 4.35;
    final body = TextStyle(fontSize: fs, height: 1.28, color: _ink);
    final skillsBody = body.copyWith(fontSize: math.max(3.25, fs - 0.85));
    final works = resume.visibleWorkExperiences;
    final edu = resume.visibleEducation;
    final skills = resume.skills.where((s) => s.trim().isNotEmpty).toList();
    final projects = resume.visibleProjects;
    final contactLine = [
      if (resume.email.trim().isNotEmpty && resume.phone.trim().isNotEmpty)
        '${resume.email.trim()}    ${resume.phone.trim()}'
      else if (resume.email.trim().isNotEmpty)
        resume.email.trim()
      else if (resume.phone.trim().isNotEmpty)
        resume.phone.trim(),
    ];

    final pageContent = Padding(
          padding: EdgeInsets.fromLTRB(10, detailed ? 11 : 9, 10, detailed ? 10 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                resume.fullName.trim().toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink,
                  fontSize: detailed ? 8.2 : 7.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (resume.jobTitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  resume.jobTitle.trim(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: fs + 0.35,
                  ),
                ),
              ],
              if (resume.location.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  resume.location.trim(),
                  textAlign: TextAlign.center,
                  maxLines: detailed ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: body,
                ),
              ],
              if (contactLine.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  contactLine.first,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: body,
                ),
              ],
              const SizedBox(height: 5),
              Container(height: 1, color: _ink.withValues(alpha: 0.85)),
              _atsGrayBandLabel('SUMMARY'),
              Text(
                resume.summary.trim(),
                maxLines: detailed ? 12 : 5,
                overflow: TextOverflow.ellipsis,
                style: body,
              ),
              _atsGrayBandLabel('EXPERIENCE'),
              ..._atsStructuredJobs(works, body),
              _atsGrayBandLabel('EDUCATION'),
              ..._atsStructuredSchools(edu, body),
              _atsGrayBandLabel('SKILLS'),
              _MiniBulletColumn(
                items: skills.take(detailed ? 8 : 5).toList(),
                textStyle: skillsBody,
              ),
              if (detailed && projects.isNotEmpty) ...[
                _atsGrayBandLabel('PROJECTS'),
                Text(
                  projects.first.title.trim(),
                  style: body.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_templateArtProjectBullets(projects.first).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _templateArtProjectBullets(projects.first).first,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: body,
                  ),
                ],
              ],
              if (detailed && resume.visibleCustomSections.isNotEmpty) ...[
                for (final section in resume.visibleCustomSections.take(1)) ...[
                  _atsGrayBandLabel(section.title.trim().toUpperCase()),
                  if (section.layoutMode == CustomSectionLayoutMode.bullets)
                    ...section.bullets
                        .where((b) => b.trim().isNotEmpty)
                        .take(3)
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              b,
                              style: body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                  else
                    Text(
                      section.content.trim(),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: body,
                    ),
                ],
              ],
            ],
          ),
        );

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: detailed
          ? FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(width: 240, child: pageContent),
            )
          : SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: pageContent,
            ),
    );
  }

  Widget _atsGrayBandLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: _band,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 4.75,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  List<Widget> _atsStructuredJobs(List<WorkExperience> works, TextStyle body) {
    if (works.isEmpty) {
      return [Text('Add experience.', style: body), const SizedBox(height: 4)];
    }
    final out = <Widget>[];
    final slice = works.take(detailed ? 2 : 1);
    for (final w in slice) {
      final dr = educationDateRangeLabel(w.startDate, w.endDate);
      out.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '* ${w.role.trim()}, ${w.company.trim()}',
                style: body.copyWith(fontWeight: FontWeight.w700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dr.isNotEmpty)
              Flexible(
                child: Text(
                  dr,
                  textAlign: TextAlign.right,
                  style: body.copyWith(fontSize: (body.fontSize ?? 4.5) - 0.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
      final bullets = w.bullets.where((b) => b.trim().isNotEmpty).toList();
      final limit = detailed ? 3 : 1;
      for (var i = 0; i < bullets.length && i < limit; i++) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Text(
              '• ${bullets[i]}',
              style: body,
              maxLines: detailed ? 4 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
      out.add(const SizedBox(height: 5));
    }
    return out;
  }

  List<Widget> _atsStructuredSchools(List<EducationItem> items, TextStyle body) {
    if (items.isEmpty) {
      return [Text('Add education.', style: body), const SizedBox(height: 4)];
    }
    final out = <Widget>[];
    for (final e in items.take(detailed ? 2 : 1)) {
      final dr = educationDateRangeLabel(e.startDate, e.endDate);
      out.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '* ${e.institution.trim()}',
                style: body.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dr.isNotEmpty)
              Flexible(
                child: Text(
                  dr,
                  textAlign: TextAlign.right,
                  style: body.copyWith(fontSize: (body.fontSize ?? 4.5) - 0.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            e.degree.trim(),
            style: body.copyWith(fontStyle: FontStyle.italic),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      out.add(const SizedBox(height: 4));
    }
    return out;
  }
}

class _AtsSerifRulesTemplateArt extends StatelessWidget {
  const _AtsSerifRulesTemplateArt({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  static const Color _ink = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final fs = detailed ? 4.75 : 4.45;
    final body = TextStyle(fontSize: fs, height: 1.28, color: _ink);
    final skillsBody = body.copyWith(fontSize: math.max(3.25, fs - 0.85));
    final works = resume.visibleWorkExperiences;
    final edu = resume.visibleEducation;
    final skills = resume.skills.where((s) => s.trim().isNotEmpty).toList();

    final pageContent = Padding(
          padding: EdgeInsets.fromLTRB(10, detailed ? 11 : 9, 10, detailed ? 10 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                          resume.fullName.trim(),
                          style: TextStyle(
                            fontSize: detailed ? 9 : 8.2,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (resume.jobTitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            resume.jobTitle.trim(),
                            style: body.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 3),
                        if (resume.location.trim().isNotEmpty)
                          Text(
                            resume.location.trim(),
                            style: body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (resume.phone.trim().isNotEmpty)
                          Text(
                            resume.phone.trim(),
                            style: body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (resume.email.trim().isNotEmpty)
                    Flexible(
                      child: Text(
                        resume.email.trim(),
                        style: body.copyWith(fontStyle: FontStyle.italic),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text('Summary', style: body.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Container(height: 1, color: _ink.withValues(alpha: 0.35)),
              const SizedBox(height: 5),
              Text(
                resume.summary.trim(),
                style: body,
                maxLines: detailed ? 10 : 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (works.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Experience',
                  style: body.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Container(height: 1, color: _ink.withValues(alpha: 0.35)),
                const SizedBox(height: 5),
                for (final w in works.take(detailed ? 2 : 1)) ...[
                  Text(
                    w.role.trim(),
                    style: body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: fs + 0.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          w.company.trim(),
                          style: body.copyWith(fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (educationDateRangeLabel(w.startDate, w.endDate)
                          .isNotEmpty)
                        Flexible(
                          child: Text(
                            educationDateRangeLabel(w.startDate, w.endDate),
                            textAlign: TextAlign.right,
                            style: body.copyWith(
                              fontStyle: FontStyle.italic,
                              color: _ink.withValues(alpha: 0.72),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  for (
                    var i = 0;
                    i <
                        w.bullets
                            .where((b) => b.trim().isNotEmpty)
                            .length
                            .clamp(0, detailed ? 3 : 1);
                    i++
                  )
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• ${w.bullets.where((b) => b.trim().isNotEmpty).toList()[i]}',
                        style: body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 5),
                ],
              ],
              if (edu.isNotEmpty) ...[
                Text(
                  'Education',
                  style: body.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Container(height: 1, color: _ink.withValues(alpha: 0.35)),
                const SizedBox(height: 5),
                for (final e in edu.take(detailed ? 2 : 1)) ...[
                  Text(
                    '${e.degree.trim()} · ${educationDateRangeLabel(e.startDate, e.endDate)}',
                    style: body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.institution.trim(),
                    style: body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                ],
              ],
              if (skills.isNotEmpty) ...[
                Text('Skills', style: body.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Container(height: 1, color: _ink.withValues(alpha: 0.35)),
                const SizedBox(height: 5),
                _MiniBulletColumn(
                  items: skills.take(detailed ? 8 : 5).toList(),
                  textStyle: skillsBody,
                ),
              ],
            ],
          ),
        );

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: detailed
          ? FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(width: 240, child: pageContent),
            )
          : SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: pageContent,
            ),
    );
  }
}

class _AtsModernFlowTemplateArt extends StatelessWidget {
  const _AtsModernFlowTemplateArt({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  static const Color _ink = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final fs = detailed ? 4.75 : 4.45;
    final body = TextStyle(fontSize: fs, height: 1.28, color: _ink);
    final skillsBody = body.copyWith(fontSize: math.max(3.25, fs - 0.85));
    final pipes = [
      if (resume.location.trim().isNotEmpty) resume.location.trim(),
      if (resume.email.trim().isNotEmpty) resume.email.trim(),
      if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
    ].join('  |  ');
    final edu = resume.visibleEducation;
    final works = resume.visibleWorkExperiences;
    final skills = resume.skills.where((s) => s.trim().isNotEmpty).toList();
    final projects = resume.visibleProjects;

    final pageContent = Padding(
          padding: EdgeInsets.fromLTRB(10, detailed ? 11 : 9, 10, detailed ? 10 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                resume.fullName.trim(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: detailed ? 9 : 8.2,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (pipes.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  pipes,
                  textAlign: TextAlign.center,
                  style: body.copyWith(color: _ink.withValues(alpha: 0.92)),
                  maxLines: detailed ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Container(height: 1, color: _ink.withValues(alpha: 0.42)),
              const SizedBox(height: 7),
              Text(
                'Professional Summary',
                style: body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                resume.summary.trim(),
                style: body,
                maxLines: detailed ? 10 : 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(height: 1, color: _ink.withValues(alpha: 0.22)),
              const SizedBox(height: 7),
              Text(
                'Education',
                style: body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              if (edu.isEmpty)
                Text('Add education.', style: body)
              else
                for (final e in edu.take(detailed ? 2 : 1)) ...[
                  Text(
                    e.degree.trim(),
                    style: body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.institution.trim()}'
                    '${educationDateRangeLabel(e.startDate, e.endDate).isNotEmpty ? '  |  Graduated: ${educationDateRangeLabel(e.startDate, e.endDate)}' : ''}',
                    style: body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (e.score.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      e.score.trim(),
                      style: body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                ],
              Container(height: 1, color: _ink.withValues(alpha: 0.22)),
              const SizedBox(height: 7),
              Text('Skills', style: body.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              _MiniBulletColumn(
                items: skills.take(detailed ? 7 : 4).toList(),
                textStyle: skillsBody,
              ),
              const SizedBox(height: 6),
              Container(height: 1, color: _ink.withValues(alpha: 0.22)),
              const SizedBox(height: 7),
              Text(
                'Experience',
                style: body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              if (works.isEmpty)
                Text('Add roles.', style: body)
              else
                for (final w in works.take(detailed ? 2 : 1)) ...[
                  Text(
                    '${w.role.trim()} — ${w.company.trim()}',
                    style: body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (educationDateRangeLabel(w.startDate, w.endDate).isNotEmpty)
                    Text(
                      educationDateRangeLabel(w.startDate, w.endDate),
                      style: body,
                    ),
                  for (
                    var i = 0;
                    i <
                        w.bullets
                            .where((b) => b.trim().isNotEmpty)
                            .length
                            .clamp(0, detailed ? 3 : 1);
                    i++
                  )
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• ${w.bullets.where((b) => b.trim().isNotEmpty).toList()[i]}',
                        style: body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              if (detailed && projects.isNotEmpty) ...[
                Container(height: 1, color: _ink.withValues(alpha: 0.22)),
                const SizedBox(height: 7),
                Text(
                  'Projects',
                  style: body.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                for (final p in projects.take(1)) ...[
                  Text(
                    p.title.trim(),
                    style: body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_templateArtProjectBullets(p).isNotEmpty)
                    Text(
                      _templateArtProjectBullets(p).first,
                      style: body,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
            ],
          ),
        );

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: detailed
          ? FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(width: 240, child: pageContent),
            )
          : SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: pageContent,
            ),
    );
  }
}

class _AtsExecutiveTemplateArt extends StatelessWidget {
  const _AtsExecutiveTemplateArt({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  static const Color _ink = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final fs = detailed ? 4.75 : 4.45;
    final body = TextStyle(fontSize: fs, height: 1.28, color: _ink);
    final skillsBody = body.copyWith(fontSize: math.max(3.25, fs - 0.85));
    final works = resume.visibleWorkExperiences;
    final edu = resume.visibleEducation;
    final skills = resume.skills.where((s) => s.trim().isNotEmpty).toList();
    final mid = skills.length ~/ 2;
    final left = skills.take(mid == 0 ? skills.length : mid).toList();
    final right = mid == 0
        ? const <String>[]
        : skills.skip(mid).toList();

    final pageContent = Padding(
          padding: EdgeInsets.fromLTRB(10, detailed ? 11 : 9, 10, detailed ? 10 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (resume.jobTitle.trim().isNotEmpty)
                Text(
                  resume.jobTitle.trim().toUpperCase(),
                  textAlign: TextAlign.center,
                  style: body.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (resume.jobTitle.trim().isNotEmpty) const SizedBox(height: 3),
              Text(
                resume.fullName.trim(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: detailed ? 9.5 : 8.8,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (resume.location.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  resume.location.trim(),
                  textAlign: TextAlign.center,
                  style: body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (resume.email.trim().isNotEmpty ||
                  resume.phone.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  [
                    if (resume.email.trim().isNotEmpty) resume.email.trim(),
                    if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
                  ].join('   '),
                  textAlign: TextAlign.center,
                  style: body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Container(height: 1, color: _ink.withValues(alpha: 0.85)),
              const SizedBox(height: 7),
              Text(
                'SUMMARY',
                style: body.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                resume.summary.trim(),
                style: body,
                maxLines: detailed ? 10 : 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Text(
                'EXPERIENCE',
                style: body.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              if (works.isEmpty)
                Text('Add experience.', style: body)
              else
                for (final w in works.take(detailed ? 2 : 1)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          w.role.trim().toUpperCase(),
                          style: body.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (educationDateRangeLabel(w.startDate, w.endDate)
                          .isNotEmpty)
                        Flexible(
                          child: Text(
                            educationDateRangeLabel(w.startDate, w.endDate),
                            textAlign: TextAlign.right,
                            style: body.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    w.company.trim(),
                    style: body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  for (
                    var i = 0;
                    i <
                        w.bullets
                            .where((b) => b.trim().isNotEmpty)
                            .length
                            .clamp(0, detailed ? 3 : 1);
                    i++
                  )
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• ${w.bullets.where((b) => b.trim().isNotEmpty).toList()[i]}',
                        style: body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              Text(
                'EDUCATION',
                style: body.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              if (edu.isEmpty)
                Text('Add education.', style: body)
              else
                for (final e in edu.take(detailed ? 2 : 1)) ...[
                  Text(
                    '${e.institution.trim()} | ${e.degree.trim()}',
                    style: body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (e.score.trim().isNotEmpty) e.score.trim(),
                      if (educationDateRangeLabel(e.startDate, e.endDate)
                          .isNotEmpty)
                        educationDateRangeLabel(e.startDate, e.endDate),
                    ].join(' | '),
                    style: body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                ],
              Text(
                'SKILLS',
                style: body.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              if (skills.isEmpty)
                Text('Add skills.', style: skillsBody)
              else
                for (var r = 0; r < math.max(left.length, right.length); r++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: r < left.length
                              ? Text(
                                  '• ${left[r]}',
                                  style: skillsBody,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const SizedBox(),
                        ),
                        Expanded(
                          child: r < right.length
                              ? Text(
                                  '• ${right[r]}',
                                  style: skillsBody,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: detailed
          ? FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(width: 240, child: pageContent),
            )
          : SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: pageContent,
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
              width: 72,
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
                    Center(
                      child: _MiniAvatarBlock(
                        backgroundColor: avatarBackground,
                        textColor: Color(0xFFE17A3B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: SizedBox(
                        width: 55,
                        height: 1,
                        child: ColoredBox(color: line),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: const _MiniAccentDotLine(text: 'Seattle, WA'),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: const _MiniAccentDotLine(text: '+1 206 555 0117'),
                    ),
                    const SizedBox(height: 4),
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
                        const _MiniBulletColumn(items: ['Timeline tracking']),
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

class _ClassicSidebarTemplateArtCompact extends StatelessWidget {
  const _ClassicSidebarTemplateArtCompact({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2E7CB3);
    final rail = Color.lerp(Colors.white, accent, 0.14)!;
    final avatar = Color.lerp(accent, Colors.white, 0.45)!;
    const title = Color(0xFF1F2937);
    const text = Color(0xFF344054);
    const muted = Color(0xFF667085);
    final line = Color.lerp(accent, Colors.white, 0.7)!;
    final skills = resume.skills.take(detailed ? 3 : 2).toList();
    final languages = resume.customSections
        .where((item) => item.title.trim().toLowerCase() == 'languages')
        .expand(
          (item) => item.layoutMode == CustomSectionLayoutMode.bullets
              ? item.bullets
              : item.content.split(RegExp(r'[\n,]+')),
        )
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(detailed ? 2 : 1)
        .toList();
    final experiences = resume.workExperiences
        .where((item) => !item.isBlank)
        .take(1)
        .toList();
    final education = resume.education
        .where((item) => !item.isBlank)
        .take(detailed ? 2 : 1)
        .toList();
    final projects = resume.projects
        .where((item) => !item.isBlank)
        .take(detailed ? 2 : 1)
        .toList();
    final nameLine = _miniClassicNameLine(resume.fullName);
    final summary = resume.summary.trim();

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 60,
              color: rail,
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 4.6,
                  height: 1.28,
                  color: text,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: avatar,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _miniClassicInitials(resume.fullName),
                          style: TextStyle(
                            color: title,
                            fontSize: 12.6,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: line),
                    const SizedBox(height: 6),
                    Text(
                      'SKILLS',
                      style: TextStyle(
                        fontSize: 5.7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.15,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _MiniBulletColumn(items: skills, bulletColor: accent),
                    SizedBox(height: detailed ? 8 : 4),
                    Container(height: 1, color: line),
                    SizedBox(height: detailed ? 5 : 3),
                    Text(
                      'LANGUAGES',
                      style: TextStyle(
                        fontSize: 5.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.15,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _MiniBulletColumn(items: languages, bulletColor: accent),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 10, 9, 9),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 4.6,
                    height: 1.28,
                    color: text,
                  ),
                  child: ClipRect(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.4,
                              height: 0.96,
                              fontWeight: FontWeight.w900,
                              color: title,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            resume.jobTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted),
                          ),
                          SizedBox(height: detailed ? 5 : 3),
                          _MiniClassicInfoLine(text: resume.email),
                          SizedBox(height: detailed ? 4 : 3),
                          _MiniClassicInfoLine(text: resume.location),
                          SizedBox(height: detailed ? 4 : 3),
                          _MiniClassicInfoLine(text: resume.phone),
                          SizedBox(height: detailed ? 7 : 4),
                          Container(height: 1, color: line),
                          SizedBox(height: detailed ? 6 : 4),
                          Text(
                            'SUMMARY',
                            style: TextStyle(
                              fontSize: 5.6,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.15,
                              color: title,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary,
                            maxLines: detailed ? 5 : 2,
                            overflow: TextOverflow.clip,
                            style: TextStyle(color: muted),
                          ),
                          SizedBox(height: detailed ? 7 : 4),
                          Container(height: 1, color: line),
                          SizedBox(height: detailed ? 6 : 4),
                          Text(
                            'EXPERIENCE',
                            style: TextStyle(
                              fontSize: 5.6,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.15,
                              color: title,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (experiences.isNotEmpty) ...[
                            Text(
                              experiences.first.role,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: title,
                              ),
                            ),
                            Text(
                              '${experiences.first.company} · ${experiences.first.startDate}-${experiences.first.endDate}',
                              style: TextStyle(color: muted),
                            ),
                            const SizedBox(height: 3),
                            _MiniBulletColumn(
                              items: [
                                ...experiences.first.bullets.take(1),
                                if (experiences.first.bullets.isEmpty &&
                                    experiences.first.description
                                        .trim()
                                        .isNotEmpty)
                                  experiences.first.description.trim(),
                              ],
                              bulletColor: accent,
                            ),
                          ],
                          SizedBox(height: detailed ? 7 : 4),
                          Container(height: 1, color: line),
                          SizedBox(height: detailed ? 6 : 4),
                          Text(
                            'EDUCATION',
                            style: TextStyle(
                              fontSize: 5.6,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.15,
                              color: title,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (final item in education) ...[
                            Text(
                              item.degree,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: title,
                              ),
                            ),
                            Text(
                              '${item.institution} · ${item.endDate}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: muted),
                            ),
                            SizedBox(height: detailed ? 3 : 1),
                          ],
                          SizedBox(height: detailed ? 5 : 3),
                          Container(height: 1, color: line),
                          SizedBox(height: detailed ? 6 : 4),
                          Text(
                            'PROJECTS',
                            style: TextStyle(
                              fontSize: 5.6,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.15,
                              color: title,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (final item in projects) ...[
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: title,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            _MiniBulletColumn(
                              items: [
                                ...item.bullets.take(1),
                                if (item.bullets.isEmpty &&
                                    item.overview.trim().isNotEmpty)
                                  item.overview.trim(),
                              ],
                              bulletColor: accent,
                            ),
                            SizedBox(height: detailed ? 3 : 1),
                          ],
                        ],
                      ),
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

class _DetailsSidebarTemplateArtCompact extends StatelessWidget {
  const _DetailsSidebarTemplateArtCompact({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    const rail = Color(0xFFF3F4F6);
    const title = Color(0xFF344054);
    const text = Color(0xFF475467);
    const line = Color(0xFF98A2B3);
    final accent = resume.corporateColorPreset.headerColor;
    final experiences = resume.workExperiences
        .where((item) => !item.isBlank)
        .take(2)
        .toList();
    final education = resume.education
        .where((item) => !item.isBlank)
        .take(1)
        .toList();
    final skills = resume.skills.take(detailed ? 6 : 4).toList();
    final summary = resume.summary.trim();

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 64,
              color: rail,
              padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 4.6,
                  height: 1.32,
                  color: text,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _miniClassicNameLine(resume.fullName),
                      maxLines: detailed ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.0,
                        height: 0.98,
                        fontWeight: FontWeight.w800,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      resume.jobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: title, fontSize: 5.1),
                    ),
                    const SizedBox(height: 11),
                    const Text(
                      'DETAILS',
                      style: TextStyle(
                        fontSize: 5.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(height: 1, color: line),
                    const SizedBox(height: 6),
                    _MiniDetailsLine(
                      text: resume.email,
                      color: title,
                      textColor: text,
                    ),
                    const SizedBox(height: 4),
                    _MiniDetailsLine(
                      text: resume.phone,
                      color: title,
                      textColor: text,
                    ),
                    const SizedBox(height: 4),
                    _MiniDetailsLine(
                      text: resume.location,
                      color: title,
                      textColor: text,
                      maxLines: detailed ? 4 : 3,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'SKILLS',
                      style: TextStyle(
                        fontSize: 5.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(height: 1, color: line),
                    const SizedBox(height: 6),
                    _MiniBulletColumn(items: skills, bulletColor: accent),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 4.65,
                    height: 1.32,
                    color: text,
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _MiniSidebarHeading(
                          title: 'SUMMARY',
                          lineColor: line,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          maxLines: detailed ? 5 : 3,
                          overflow: TextOverflow.clip,
                        ),
                        const SizedBox(height: 8),
                        const _MiniSidebarHeading(
                          title: 'EXPERIENCE',
                          lineColor: line,
                        ),
                        const SizedBox(height: 4),
                        for (final item in experiences) ...[
                          Text(
                            '${item.startDate} — ${item.endDate}',
                            style: const TextStyle(color: text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.role,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: title,
                            ),
                          ),
                          Text(
                            item.company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          _MiniBulletColumn(
                            items: item.bullets.take(detailed ? 2 : 1).toList(),
                            bulletColor: accent,
                          ),
                          const SizedBox(height: 6),
                        ],
                        const _MiniSidebarHeading(
                          title: 'EDUCATION',
                          lineColor: line,
                        ),
                        const SizedBox(height: 4),
                        for (final item in education) ...[
                          Text(
                            '${item.startDate} — ${item.endDate}',
                            style: const TextStyle(color: text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.degree,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: title,
                            ),
                          ),
                          Text(
                            item.institution,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

String _miniClassicInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return 'AB';
  }
  return parts.map((item) => item[0].toUpperCase()).join();
}

String _miniClassicNameLine(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'AVERY BROOKS';
  }
  return parts.join(' ').toUpperCase();
}

class _ClassicBusinessCoverLetterArt extends StatelessWidget {
  const _ClassicBusinessCoverLetterArt();

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF1F2328);
    const muted = Color(0xFF5C6370);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 4.35, height: 1.34, color: text),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'October 6, 2026',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Christine Smith\n'
                  'VP Technical Services\n'
                  'Computers Forever\n'
                  '1224 Main Street, Allentown, PA 55555',
                  style: TextStyle(color: muted, height: 1.38),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dear Ms. Smith:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const _MiniCoverLetterParagraph(
                  text:
                      'I am writing to apply for the software engineer position at Computers Forever. I am eager to contribute to your technical innovations and support initiatives that keep products reliable and customer-focused.',
                ),
                const SizedBox(height: 4),
                const _MiniCoverLetterParagraph(
                  text:
                      'Since 2019 at Action Company, I have delivered full-lifecycle development across requirements, implementation, and release support—partnering closely with stakeholders to ship predictable improvements.',
                ),
                const SizedBox(height: 4),
                const _MiniCoverLetterParagraph(
                  text:
                      'I combine excellent client-facing skills with clear proposals and presentations, and I translate complex constraints into practical design solutions.',
                ),
                const Spacer(),
                const Text(
                  'Sincerely,',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Martin Stein',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
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
      width: 55,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: backgroundColor,
      ),
      alignment: Alignment.center,
      child: Text(
        'MV',
        style: TextStyle(
          color: textColor,
          fontSize: 13.6,
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

class _MiniClassicInfoLine extends StatelessWidget {
  const _MiniClassicInfoLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 1.2, right: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF344054),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF667085)),
          ),
        ),
      ],
    );
  }
}

class _MiniDetailsLine extends StatelessWidget {
  const _MiniDetailsLine({
    required this.text,
    required this.color,
    required this.textColor,
    this.maxLines = 2,
  });

  final String text;
  final Color color;
  final Color textColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 1.3, right: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );
  }
}

class _MiniBulletColumn extends StatelessWidget {
  const _MiniBulletColumn({
    required this.items,
    this.bulletColor = const Color(0xFF344054),
    this.textStyle,
  });

  final List<String> items;
  final Color bulletColor;

  /// When omitted, inherits [DefaultTextStyle] (template arts should pass a small style).
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final base =
        textStyle ?? DefaultTextStyle.of(context).style;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: base.copyWith(
                    fontWeight: FontWeight.w700,
                    color: bulletColor,
                  ),
                ),
                Expanded(
                  child: Text(item, style: base),
                ),
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
