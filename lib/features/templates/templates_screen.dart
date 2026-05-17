import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/corporate_resume_style.dart';
import '../../core/models/resume_models.dart';
import '../../core/resume_text_font.dart';
import '../../core/services/resume_services.dart';
import '../premium/premium_gate.dart';
import '../shared/native_pdf_preview.dart';
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

  Future<void> _onTemplateTileTapped(
    BuildContext context,
    _TemplateTileData item,
    ResumeLibraryViewModel? library,
  ) async {
    if (!await ensurePremiumForTemplateTile(context, templateTileId: item.id)) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    if (widget.onTemplateSelected != null && item.resumeTemplate != null) {
      widget.onTemplateSelected!(item.resumeTemplate!);
      return;
    }
    if (widget.onCoverLetterTemplateSelected != null &&
        item.coverLetterTemplate != null) {
      widget.onCoverLetterTemplateSelected!(item.coverLetterTemplate!);
      return;
    }

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TemplateDetailScreen(
          item: item,
          paletteSeed: library?.selectedResume,
          onUseTemplate: item.resumeTemplate == null
              ? null
              : () => _applyResumeTemplate(context, item, library),
        ),
      ),
    );
  }

  Future<void> _applyResumeTemplate(
    BuildContext context,
    _TemplateTileData item,
    ResumeLibraryViewModel? library,
  ) async {
    if (!await ensurePremiumForTemplateTile(context, templateTileId: item.id)) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    library?.setDefaultTemplate(item.resumeTemplate!);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    widget.onCreateResume?.call();
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
                onTap: () =>
                    _onTemplateTileTapped(context, item, library),
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
                  onTap: () =>
                      _onTemplateTileTapped(context, item, library),
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
                  top: 4,
                  right: 14,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: selectedColor,
                    size: 30,
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
    headline: 'Corporate',
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
    id: 'accent-strip',
    resumeTemplate: ResumeTemplate.accentStrip,
    previewKind: _TemplatePreviewKind.accentStripResume,
    headline: 'Accent Strip',
    caption: 'Bold left stripe with an oversized nameplate and clean sections.',
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
    isPremium: false,
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
  _TemplateTileData(
    id: 'ats-center-classic',
    resumeTemplate: ResumeTemplate.atsCenterClassic,
    previewKind: _TemplatePreviewKind.atsCenterClassicResume,
    headline: 'Center Classic ATS',
    caption: 'Centered name, pipe tagline, and ruled single-column sections.',
    isPremium: true,
  ),
  _TemplateTileData(
    id: 'ats-professional-blue',
    resumeTemplate: ResumeTemplate.atsProfessionalBlue,
    previewKind: _TemplatePreviewKind.atsProfessionalBlueResume,
    headline: 'Professional Blue ATS',
    caption: 'Blue accent headings with right-aligned contact and skills grid.',
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
    isPremium: false,
  ),
  _TemplateTileData(
    id: 'minimal-letter',
    coverLetterTemplate: CoverLetterTemplate.minimalLetter,
    previewKind: _TemplatePreviewKind.minimalCoverLetter,
    headline: 'Minimal Letter',
    caption: 'Centered and airy layout with restrained modern spacing.',
    isPremium: false,
  ),
  _TemplateTileData(
    id: 'sidebar-letter',
    coverLetterTemplate: CoverLetterTemplate.sidebarLetter,
    previewKind: _TemplatePreviewKind.sidebarCoverLetter,
    headline: 'Sidebar Letter',
    caption: 'A bolder cover letter with a left rail for contact details.',
    isPremium: false,
  ),
  _TemplateTileData(
    id: 'classic-business-letter',
    coverLetterTemplate: CoverLetterTemplate.classicBusinessLetter,
    previewKind: _TemplatePreviewKind.classicBusinessCoverLetter,
    headline: 'Classic Business',
    caption:
        'Traditional business letter: date, recipient block, and left-aligned body.',
    isPremium: false,
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
  accentStripResume,
  atsStructuredResume,
  atsSerifRulesResume,
  atsModernFlowResume,
  atsExecutiveResume,
  atsCenterClassicResume,
  atsProfessionalBlueResume,
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
      _TemplatePreviewKind.darkHeaderResume => _ResumeTemplatePreviewArt(
        resume: _applyTemplatePreviewPalette(
          _darkHeaderTemplateResume,
          paletteSeed,
        ),
        fit: _ResumeTemplatePreviewFit.tile,
      ),
      _TemplatePreviewKind.profileSidebarResume => _ProfileSidebarTemplateArtCompact(
        resume: _applyTemplatePreviewPalette(
          _profileSidebarTemplateResume,
          paletteSeed,
        ),
        detailed: true,
      ),
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
      _TemplatePreviewKind.accentStripResume => _ResumeTemplatePreviewArt(
        resume: _applyTemplatePreviewPalette(
          _accentStripTemplateResume,
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
      _TemplatePreviewKind.atsCenterClassicResume =>
        _AtsCenterClassicTemplateArt(
          resume: _applyTemplatePreviewPalette(
            _atsSampleFor(ResumeTemplate.atsCenterClassic),
            paletteSeed,
          ),
        ),
      _TemplatePreviewKind.atsProfessionalBlueResume =>
        _AtsProfessionalBlueTemplateArt(
          resume: _applyTemplatePreviewPalette(
            _atsSampleFor(ResumeTemplate.atsProfessionalBlue),
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

/// Full-screen template detail — paginated PDF preview (all pages scrollable).
class _TemplateDetailPdfPreview extends StatelessWidget {
  const _TemplateDetailPdfPreview({required this.resume});

  final ResumeData resume;

  @override
  Widget build(BuildContext context) {
    final pdfService = context.read<ResumePdfService>();
    final viewerBackground = Theme.of(context).scaffoldBackgroundColor;
    return NativePdfPreview(
      documentKey:
          'template-detail-${resume.id}-${resume.template.name}',
      viewerBackground: viewerBackground,
      bytesFuture: pdfService.buildPdf(resume),
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
      return _TemplateDetailPdfPreview(
        resume: _applyTemplatePreviewPalette(
          _darkHeaderTemplateResume,
          paletteSeed,
        ),
      );
    }
    if (template == ResumeTemplate.creative) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _ProfileSidebarTemplateArtCompact(
          resume: _applyTemplatePreviewPalette(
            _profileSidebarTemplateResume,
            paletteSeed,
          ),
          detailed: true,
        ),
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
    if (template == ResumeTemplate.accentStrip) {
      return _TemplateDetailPdfPreview(
        resume: _applyTemplatePreviewPalette(
          _accentStripTemplateResume,
          paletteSeed,
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
    if (template == ResumeTemplate.atsCenterClassic) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _AtsCenterClassicTemplateArt(
          resume: _applyTemplatePreviewPalette(
            _atsSampleFor(ResumeTemplate.atsCenterClassic),
            paletteSeed,
          ),
          detailed: true,
        ),
      );
    }
    if (template == ResumeTemplate.atsProfessionalBlue) {
      return _LargeTemplateArtPreview(
        showPremiumBadge: true,
        child: _AtsProfessionalBlueTemplateArt(
          resume: _applyTemplatePreviewPalette(
            _atsSampleFor(ResumeTemplate.atsProfessionalBlue),
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
  // Dark Header always shows the first color-picker swatch (#31353B).
  if (sample.template == ResumeTemplate.corporate) {
    return sample.copyWith(
      corporateColorPresetIndex: defaultColorPresetIndexForTemplate(
        ResumeTemplate.corporate,
      ),
    );
  }
  if (sample.template == ResumeTemplate.creative) {
    return sample.copyWith(
      corporateColorPresetIndex: defaultColorPresetIndexForTemplate(
        ResumeTemplate.creative,
      ),
    );
  }
  if (sample.template == ResumeTemplate.accentStrip) {
    return sample.copyWith(
      corporateColorPresetIndex: defaultColorPresetIndexForTemplate(
        ResumeTemplate.accentStrip,
      ),
    );
  }
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
  resumeTextFont: ResumeTextFont.inter,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: true,
  bodyFontPt: kResumeBodyFontPtDefault,
  corporateColorPresetIndex: 0,
);

ResumeData _atsSampleFor(ResumeTemplate template) =>
    _atsFullSampleResume.copyWith(template: template);

/// Dark Header template tile + detail preview (same typography as builder/PDF).
final ResumeData _darkHeaderTemplateResume = _atsFullSampleResume.copyWith(
  id: 'template-dark-header',
  template: ResumeTemplate.corporate,
  corporateColorPresetIndex: defaultColorPresetIndexForTemplate(
    ResumeTemplate.corporate,
  ),
);

/// Profile Sidebar template tile + detail preview (same typography/layout as builder/PDF).
final ResumeData _profileSidebarTemplateResume = _atsFullSampleResume.copyWith(
  id: 'template-profile-sidebar',
  template: ResumeTemplate.creative,
  summary:
      'Delivery-focused program manager with 8+ years aligning engineering, design, and business stakeholders. Known for turning ambiguous goals into phased roadmaps, measurable KPIs, and predictable releases in regulated and high-growth environments. Comfortable leading vendor negotiations, dependency mapping, and executive readouts across distributed teams.',
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
        'Introduced release readiness scorecards adopted by product, QA, and customer success.',
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
        'Coached scrum masters on dependency risk reviews and milestone forecasting.',
      ],
    ),
    WorkExperience(
      role: 'Business Analyst',
      company: 'Brightline Retail — San Jose, CA',
      startDate: 'Aug 2012',
      endDate: 'May 2015',
      description: '',
      bullets: [
        'Mapped order-to-cash workflows and delivered requirements for inventory visibility tools.',
        'Built Tableau dashboards used weekly by merchandising and operations leadership.',
      ],
    ),
    WorkExperience(
      role: 'Operations Coordinator',
      company: 'Summit Logistics',
      startDate: 'Jun 2010',
      endDate: 'Jul 2012',
      description: '',
      bullets: [
        'Coordinated carrier schedules and SLA reporting for a 14-site distribution network.',
        'Reduced invoice exceptions by 18% through standardized exception codes and training.',
      ],
    ),
  ],
  skills: const [
    'Program governance',
    'SQL & Excel modeling',
    'Agile / Scrum',
    'Stakeholder communication',
    'Risk & dependency tracking',
    'Vendor management',
    'Roadmap planning',
    'Executive reporting',
    'Jira & Confluence',
    'Process design',
    'Change management',
    'Data visualization',
  ],
  projects: const [
    ProjectItem(
      title: 'Forecast Automation Toolkit',
      overview: 'Finance forecasting workflow',
      impact: 'SQL, Python, Airflow',
      bullets: [
        'Partnered with finance to replace spreadsheet forecasts with auditable, versioned pipelines.',
        'Cut monthly close prep from five days to two through automated variance checks.',
        'Documented runbooks and rollback steps for on-call finance engineering support.',
      ],
    ),
    ProjectItem(
      title: 'Customer Onboarding Playbook',
      overview: 'Cross-functional onboarding',
      impact: 'Notion, Miro, Figma',
      bullets: [
        'Published a stage-gated onboarding framework used by sales, CS, and implementation.',
        'Reduced time-to-first-value by 22% for mid-market accounts in the first pilot quarter.',
      ],
    ),
    ProjectItem(
      title: 'Release Readiness Dashboard',
      overview: 'Engineering release metrics',
      impact: 'Looker, BigQuery',
      bullets: [
        'Defined readiness criteria and automated weekly scorecards for five product squads.',
        'Surfaced blocker trends that cut release slip rate by one third over two quarters.',
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
        'SAFe Program Consultant — Scaled Agile (2018)',
      ],
    ),
    CustomSectionItem(
      title: 'Languages',
      content: '',
      layoutMode: CustomSectionLayoutMode.bullets,
      bullets: ['English (native)', 'Spanish (professional working proficiency)'],
    ),
  ],
  corporateColorPresetIndex: defaultColorPresetIndexForTemplate(
    ResumeTemplate.creative,
  ),
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
  resumeTextFont: ResumeTextFont.inter,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: true,
  bodyFontPt: kResumeBodyFontPtDefault,
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
  resumeTextFont: ResumeTextFont.inter,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: false,
  bodyFontPt: kResumeBodyFontPtDefault,
  corporateColorPresetIndex: 4,
);

final ResumeData _accentStripTemplateResume = ResumeData(
  id: 'template-accent-strip',
  title: 'Accent Strip Template',
  fullName: 'DONNA ROBBINS',
  jobTitle: 'Senior Accountant',
  email: 'donna@example.com',
  phone: '(313) 555-0100',
  location: '4567 Main Street, Detroit, MI 48127',
  website: 'www.greatsiteaddress.com',
  summary:
      'Analytical, organized and detail-oriented accountant with GAAP expertise and experience in the full spectrum of public accounting. Collaborative team player with ownership mentality and a track record of delivering strategic solutions to resolve challenges and support business growth.',
  template: ResumeTemplate.accentStrip,
  workExperiences: const [
    WorkExperience(
      role: 'Accountant',
      company: 'Trey Research | San Francisco, CA',
      startDate: '20XX',
      endDate: 'Present',
      description:
          'Working in a mid-sized public accounting firm to provide professional accounting services for individuals and business clients. Provide full range of services, including income tax preparation, audit support, preparation of financial statements, pro forma budgeting, general ledger accounting, and bank reconciliation.',
      bullets: [],
    ),
    WorkExperience(
      role: 'Bookkeeper',
      company: 'Bandter Real Estate | Berkeley, CA',
      startDate: '20XX',
      endDate: '20XX',
      description:
          'Inhouse bookkeeper for a real estate development company. Maintained financial books, tracked expenses, prepared and submitted invoices, and oversaw payroll.',
      bullets: [],
    ),
    WorkExperience(
      role: 'Accounting Intern',
      company: 'Olson Harris Ltd. | Vallejo, CA',
      startDate: 'December 20XX',
      endDate: 'April 20XX',
      description:
          'Assisted with payroll and pensions service management for 150+ employees. Prepared invoices for more than 200 clients. Assisted with bill payments, records organization and preparation, and other office duties to support financial and accounting operations.',
      bullets: [],
    ),
  ],
  education: const [
    EducationItem(
      institution: 'University of Michigan',
      degree: 'Bachelor of Business Administration in Accounting',
      startDate: '20XX',
      endDate: '20XX',
      score: '',
    ),
    EducationItem(
      institution: 'Macomb Community College',
      degree: 'Associate Degree in Business Administration',
      startDate: '20XX',
      endDate: '20XX',
      score: '',
    ),
  ],
  skills: const [
    'GAAP',
    'Income tax preparation',
    'Audit support',
    'General ledger accounting',
    'Bank reconciliation',
    'Financial statements',
  ],
  projects: const [
    ProjectItem(
      title: 'Quarter-End Close Playbook',
      overview: 'Finance operations process improvement',
      impact: 'Accounting controls, reporting, reconciliation',
      bullets: [
        'Standardized close checklists and reconciliations to improve month-end reporting readiness.',
      ],
    ),
  ],
  customSections: const [
    CustomSectionItem(
      title: 'Certifications',
      content: '',
      layoutMode: CustomSectionLayoutMode.bullets,
      bullets: [
        'Certified Public Accountant (CPA)',
        'QuickBooks ProAdvisor',
        'Advanced Excel for Finance',
      ],
    ),
  ],
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  githubLink: '',
  linkedinLink: '',
  profileImagePath: '',
  resumeTextFont: ResumeTextFont.inter,
  includeWorkInResume: true,
  includeEducationInResume: true,
  includeSkillsInResume: true,
  includeProjectsInResume: true,
  bodyFontPt: kResumeBodyFontPtDefault,
  corporateColorPresetIndex: defaultColorPresetIndexForTemplate(
    ResumeTemplate.accentStrip,
  ),
);

enum _ResumeTemplatePreviewFit { tile, detail }

class _ResumeTemplatePreviewArt extends StatelessWidget {
  const _ResumeTemplatePreviewArt({
    required this.resume,
    this.fit = _ResumeTemplatePreviewFit.tile,
  });

  final ResumeData resume;
  final _ResumeTemplatePreviewFit fit;

  /// Matches [PdfPageFormat.a4] width in points (same as PDF export).
  static const double _pageWidth = 595.28;
  /// Screen padding below the scaled page on the full template screen.
  static const double _detailBottomInset = 64;

  /// Small gap at the bottom of grid tiles.
  static const double _tileBottomInset = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = constraints.maxWidth;
        final targetHeight = constraints.maxHeight;
        if (!targetWidth.isFinite || targetWidth <= 0) {
          return const SizedBox.shrink();
        }

        final isAccentStrip =
            resume.template.userFacingTemplate == ResumeTemplate.accentStrip;
        final fullHeightTemplate = switch (resume.template.userFacingTemplate) {
          ResumeTemplate.creative => true,
          ResumeTemplate.accentStrip => true,
          _ => false,
        };
        final bottomInset = fullHeightTemplate
            ? 0.0
            : switch (fit) {
                _ResumeTemplatePreviewFit.detail => _detailBottomInset,
                _ResumeTemplatePreviewFit.tile => _tileBottomInset,
              };
        final hasHeight = targetHeight.isFinite && targetHeight > 0;
        final contentHeight = hasHeight
            ? (targetHeight - bottomInset).clamp(0.0, targetHeight)
            : null;

        final pagePreview = FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _pageWidth,
            child: ResumePreviewCanvas(
              resume: resume,
              showDebugLabel: false,
              scrollable: false,
              showAllContent: true,
            ),
          ),
        );

        return ColoredBox(
          color: Colors.white,
          child: ClipRect(
            child: SizedBox(
              width: targetWidth,
              height: contentHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isAccentStrip)
                    Positioned(
                      left: targetWidth * (22 / _pageWidth),
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: resume.corporateColorPreset.headerColor,
                        child: SizedBox(
                          width: targetWidth * (34 / _pageWidth),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: pagePreview,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _ProfileSidebarTemplateArtCompact extends StatelessWidget {
  const _ProfileSidebarTemplateArtCompact({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  /// Same width basis as [_LargeTemplateArtPreview] (matches builder preview scale).
  static const double _layoutScale = 240 / 595.28;

  static double _scaledPt(double pt) => pt * _layoutScale;

  TextStyle _bodyStyle() => ResumeTypography.nunitoBodyPreviewStyle(
        fontSize: _scaledPt(resume.effectiveBodyFontPt.toDouble()),
        color: ResumeTypography.creativeBodyTextColor,
        height: ResumeTypography.creativeBodyLineHeight,
      );

  static TextStyle _subtitleStyle({bool italic = false}) =>
      ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.creativeSubtitleWeight,
        fontSize: _scaledPt(ResumeTypography.creativeSubtitlePt),
        color: ResumeTypography.creativeBodyTextColor,
        height: ResumeTypography.creativeBodyLineHeight,
      ).copyWith(fontStyle: italic ? FontStyle.italic : null);

  static TextStyle _nameStyle() => ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.creativeNameWeight,
        fontSize: _scaledPt(ResumeTypography.creativeNamePt),
        color: ResumeTypography.creativeBodyTextColor,
        height: 1,
        letterSpacing: 0.2,
      );

  static TextStyle _sectionHeadingStyle() => ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.creativeSectionTitleWeight,
        fontSize: _scaledPt(ResumeTypography.creativeSectionTitlePt),
        color: ResumeTypography.creativeBodyTextColor,
        height: ResumeTypography.creativeBodyLineHeight,
        letterSpacing: 0.2,
      );

  TextStyle _sidebarStyle() => ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.creativeSidebarContentWeight,
        fontSize: _scaledPt(resume.effectiveBodyFontPt.toDouble()),
        color: ResumeTypography.creativeBodyTextColor,
        height: ResumeTypography.creativeBodyLineHeight,
      );

  TextStyle _experienceDateStyle() =>
      _bodyStyle().copyWith(fontStyle: FontStyle.italic);

  static const double _avatarWidth = 48;
  static const double _avatarHeight = 58;
  static const double _avatarCornerRadius = 2;
  static const double _avatarBackgroundOpacity = 0.4;
  static const double _sectionRuleHeight = 1.0;
  static const double _sectionTitleRuleGap = 1;
  static const double _mainColumnTopPadding = 18;
  static const double _mainColumnBottomPadding = 16;

  static double get _mainColumnRightPadding =>
      _scaledPt(ResumeTypography.creativeMainColumnRightInset);

  static Widget _buildAvatar({
    required ResumeData resume,
    required Color avatarFill,
    required Color accentColor,
  }) {
    final path = resume.profileImagePath.trim();
    final hasImage = path.isNotEmpty && File(path).existsSync();
    final initialsStyle = ResumeTypography.calibriPreviewStyle(
      weight: ResumeTypography.creativeNameWeight,
      fontSize: _scaledPt(ResumeTypography.creativeNamePt * 1.15),
      color: accentColor,
      height: 1,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(_avatarCornerRadius),
      child: Container(
        width: _avatarWidth,
        height: _avatarHeight,
        color: avatarFill.withValues(alpha: _avatarBackgroundOpacity),
        alignment: Alignment.center,
        child: hasImage
            ? Image.file(
                File(path),
                width: _avatarWidth,
                height: _avatarHeight,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(
                  _miniClassicInitials(resume.fullName),
                  style: initialsStyle,
                ),
              )
            : Text(
                _miniClassicInitials(resume.fullName),
                style: initialsStyle,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final railColor = resume.creativeRailColor;
    final accentColor = resume.creativeAccentColor;
    final avatarFill = resume.creativeAvatarBackgroundColor;
    final line = resume.creativeLineColor;
    final bodyStyle = _bodyStyle();
    final subtitleStyle = _subtitleStyle();
    final experienceDateStyle = _experienceDateStyle();
    final sidebarStyle = _sidebarStyle();
    final contacts = [
      resume.email.trim(),
      resume.location.trim(),
      resume.phone.trim(),
      resume.website.trim(),
      resume.githubLink.trim(),
    ].where((item) => item.isNotEmpty).take(4).toList();
    final experiences = resume.workExperiences
        .where((item) => !item.isBlank)
        .take(2)
        .toList();
    final education = resume.education
        .where((item) => !item.isBlank)
        .take(2)
        .toList();
    final skillItems = resume.skills
        .where((item) => item.trim().isNotEmpty)
        .take(detailed ? 6 : 4)
        .toList();
    final skillMidpoint = (skillItems.length / 2).ceil();
    final leftSkills = skillItems.take(skillMidpoint).toList();
    final rightSkills = skillItems.skip(skillMidpoint).toList();
    final projects = resume.visibleProjects.take(1).toList();
    final summary = resume.summary.trim();

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 240,
          height: 360,
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Container(
              width: 58,
              color: railColor,
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: DefaultTextStyle(
                style: sidebarStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(
                      resume: resume,
                      avatarFill: avatarFill,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 6),
                    Container(width: 44, height: 1, color: line),
                    const SizedBox(height: 6),
                    for (final lineText in contacts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _ProfileSidebarContactRow(
                          text: lineText,
                          accentColor: accentColor,
                          style: sidebarStyle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  6,
                  _mainColumnTopPadding,
                  _mainColumnRightPadding,
                  _mainColumnBottomPadding,
                ),
                child: DefaultTextStyle(
                  style: bodyStyle,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRect(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                          Text(
                            _miniClassicNameLine(resume.fullName),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _nameStyle(),
                          ),
                          if (resume.jobTitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              resume.jobTitle.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _subtitleStyle(italic: true),
                            ),
                          ],
                          const SizedBox(height: 6),
                          _MiniSidebarHeading(
                            title: 'SUMMARY',
                            lineColor: line,
                            titleStyle: _sectionHeadingStyle(),
                            lineHeight: _sectionRuleHeight,
                            titleGap: _sectionTitleRuleGap,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            summary,
                            maxLines: detailed ? 6 : 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          _MiniSidebarHeading(
                            title: 'EXPERIENCE',
                            lineColor: line,
                            titleStyle: _sectionHeadingStyle(),
                            lineHeight: _sectionRuleHeight,
                            titleGap: _sectionTitleRuleGap,
                          ),
                          const SizedBox(height: 3),
                          for (final item in experiences) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: RichText(
                                    maxLines: detailed ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      style: subtitleStyle,
                                      children: [
                                        TextSpan(
                                          text: item.role.trim().isEmpty
                                              ? 'Role'
                                              : item.role.trim().toUpperCase(),
                                        ),
                                        TextSpan(
                                          text:
                                              ' / ${item.company.trim().isEmpty ? 'Company' : item.company.trim()}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_profileSidebarCreativeDateRange(
                                  item.startDate,
                                  item.endDate,
                                ).isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    _profileSidebarCreativeDateRange(
                                      item.startDate,
                                      item.endDate,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: experienceDateStyle,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          const SizedBox(height: 6),
                          _MiniSidebarHeading(
                            title: 'EDUCATION',
                            lineColor: line,
                            titleStyle: _sectionHeadingStyle(),
                            lineHeight: _sectionRuleHeight,
                            titleGap: _sectionTitleRuleGap,
                          ),
                          const SizedBox(height: 3),
                          for (final item in education) ...[
                            Text(
                              item.degree.trim().isEmpty
                                  ? 'Degree'
                                  : item.degree.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleStyle,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              item.institution.trim().isEmpty
                                  ? 'Institution'
                                  : item.institution.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: bodyStyle,
                            ),
                            if (_profileSidebarCreativeDateRange(
                              item.startDate,
                              item.endDate,
                            ).isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                _profileSidebarCreativeDateRange(
                                  item.startDate,
                                  item.endDate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle,
                              ),
                            ],
                            const SizedBox(height: 3),
                          ],
                          if (projects.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _MiniSidebarHeading(
                              title: 'PROJECTS',
                              lineColor: line,
                              titleStyle: _sectionHeadingStyle(),
                              lineHeight: _sectionRuleHeight,
                              titleGap: _sectionTitleRuleGap,
                            ),
                            const SizedBox(height: 3),
                            for (final project in projects) ...[
                              Text(
                                project.title.trim().isEmpty
                                    ? 'Project'
                                    : project.title.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: subtitleStyle,
                              ),
                              if (project.overview.trim().isNotEmpty ||
                                  project.impact.trim().isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  [
                                    project.overview.trim(),
                                    project.impact.trim(),
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: bodyStyle,
                                ),
                              ],
                              if (_templateArtProjectBullets(project)
                                  .isNotEmpty) ...[
                                const SizedBox(height: 2),
                                _MiniBulletColumn(
                                  items: _templateArtProjectBullets(project)
                                      .take(detailed ? 3 : 2)
                                      .toList(),
                                  bulletColor:
                                      ResumeTypography.creativeBodyTextColor,
                                  textStyle: bodyStyle,
                                ),
                              ],
                            ],
                          ],
                          if (leftSkills.isNotEmpty || rightSkills.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _MiniSidebarHeading(
                              title: 'SKILLS',
                              lineColor: line,
                              titleStyle: _sectionHeadingStyle(),
                              lineHeight: _sectionRuleHeight,
                              titleGap: _sectionTitleRuleGap,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _MiniBulletColumn(
                                    items: leftSkills,
                                    bulletColor:
                                        ResumeTypography.creativeBodyTextColor,
                                    textStyle: bodyStyle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniBulletColumn(
                                    items: rightSkills,
                                    bulletColor:
                                        ResumeTypography.creativeBodyTextColor,
                                    textStyle: bodyStyle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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

String _profileSidebarCreativeDateRange(String startDate, String endDate) {
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

class _AtsCenterClassicTemplateArt extends StatelessWidget {
  const _AtsCenterClassicTemplateArt({
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
    final works = resume.visibleWorkExperiences;
    final edu = resume.visibleEducation;
    final skills = resume.skills.where((s) => s.trim().isNotEmpty).toList();
    final tagline = [
      if (resume.jobTitle.trim().isNotEmpty) resume.jobTitle.trim(),
      ...skills.take(3),
    ].join(' | ');
    final contact = [
      if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
      if (resume.email.trim().isNotEmpty) resume.email.trim(),
      if (resume.location.trim().isNotEmpty) resume.location.trim(),
    ].join(' | ');

    Widget sectionRule() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(height: 1, color: _ink.withValues(alpha: 0.28)),
    );

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
              fontSize: detailed ? 9.2 : 8.4,
              fontWeight: FontWeight.w800,
              color: _ink,
              fontFamily: 'Georgia',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (tagline.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              tagline,
              textAlign: TextAlign.center,
              style: body,
              maxLines: detailed ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              contact,
              textAlign: TextAlign.center,
              style: body.copyWith(fontSize: fs - 0.35),
              maxLines: detailed ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          sectionRule(),
          Text('SUMMARY', style: body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            resume.summary.trim(),
            style: body,
            maxLines: detailed ? 10 : 5,
            overflow: TextOverflow.ellipsis,
          ),
          sectionRule(),
          Text('EXPERIENCE', style: body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          if (works.isEmpty)
            Text('Add experience.', style: body)
          else
            for (final w in works.take(detailed ? 2 : 1)) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      w.company.trim(),
                      style: body.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (educationDateRangeLabel(w.startDate, w.endDate).isNotEmpty)
                    Text(
                      educationDateRangeLabel(w.startDate, w.endDate),
                      style: body,
                    ),
                ],
              ),
              Text(w.role.trim(), style: body, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
            ],
          sectionRule(),
          Text('SKILLS', style: body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            skills.take(detailed ? 8 : 5).join(', '),
            style: body,
            maxLines: detailed ? 4 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (detailed && edu.isNotEmpty) ...[
            sectionRule(),
            Text('EDUCATION', style: body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            for (final e in edu.take(1)) ...[
              Text(
                e.degree.trim(),
                style: body.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${e.institution.trim()} (${educationDateRangeLabel(e.startDate, e.endDate)})',
                style: body,
                maxLines: 2,
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

class _AtsProfessionalBlueTemplateArt extends StatelessWidget {
  const _AtsProfessionalBlueTemplateArt({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  static const Color _blue = Color(0xFF4A90C4);
  static const Color _ink = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    final fs = detailed ? 4.75 : 4.45;
    final body = TextStyle(fontSize: fs, height: 1.28, color: _ink);
    final blueBody = body.copyWith(color: _blue);
    final works = resume.visibleWorkExperiences;
    final edu = resume.visibleEducation;
    final skills = resume.skills.where((s) => s.trim().isNotEmpty).toList();
    final columns = <List<String>>[[], [], []];
    for (var i = 0; i < skills.length; i++) {
      columns[i % 3].add(skills[i]);
    }
    final skillRows = columns
        .map((c) => c.length)
        .fold<int>(0, (a, b) => a > b ? a : b);

    final pageContent = Padding(
      padding: EdgeInsets.fromLTRB(10, detailed ? 11 : 9, 10, detailed ? 10 : 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                      resume.fullName.trim(),
                      style: TextStyle(
                        fontSize: detailed ? 9.5 : 8.6,
                        fontWeight: FontWeight.w800,
                        color: _blue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (resume.jobTitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        resume.jobTitle.trim(),
                        style: blueBody.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (resume.email.trim().isNotEmpty)
                      Text(
                        resume.email.trim(),
                        style: blueBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    if (resume.phone.trim().isNotEmpty)
                      Text(
                        resume.phone.trim(),
                        style: blueBody,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    if (resume.location.trim().isNotEmpty)
                      Text(
                        resume.location.trim(),
                        style: blueBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            resume.summary.trim(),
            style: body,
            maxLines: detailed ? 8 : 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'Professional Experience',
            style: blueBody.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: fs + 0.85,
            ),
          ),
          const SizedBox(height: 4),
          if (works.isEmpty)
            Text('Add roles.', style: body)
          else
            for (final w in works.take(detailed ? 2 : 1)) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      w.company.trim(),
                      style: blueBody.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (educationDateRangeLabel(w.startDate, w.endDate).isNotEmpty)
                    Text(
                      educationDateRangeLabel(w.startDate, w.endDate),
                      style: blueBody,
                    ),
                ],
              ),
              Text(w.role.trim(), style: blueBody, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
            ],
          if (detailed && edu.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Education',
              style: blueBody.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: fs + 0.85,
              ),
            ),
            const SizedBox(height: 4),
            for (final e in edu.take(1)) ...[
              Text(
                e.degree.trim(),
                style: blueBody.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                e.institution.trim(),
                style: body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
          const SizedBox(height: 4),
          Text(
            'Areas of Expertise',
            style: blueBody.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: fs + 0.85,
            ),
          ),
          const SizedBox(height: 4),
          if (skills.isEmpty)
            Text('Add skills.', style: body)
          else
            for (var r = 0; r < skillRows.clamp(0, detailed ? 5 : 3); r++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < 3; c++)
                      Expanded(
                        child: r < columns[c].length
                            ? Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 3,
                                    margin: const EdgeInsets.only(top: 2, right: 3),
                                    decoration: const BoxDecoration(
                                      color: _blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      columns[c][r],
                                      style: body.copyWith(fontSize: fs - 0.35),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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

/// Sidebar list spacing aligned with [_ClassicSidebarPreview] / [_ClassicSidebarListSection].
abstract final class _ClassicSidebarPreviewSkillsSpacing {
  static const double headingGap = 14;
  static const double itemGap = 8;
  static const double afterSectionGap = 12;
  static const double beforeNextTitleGap = 10;
  static const double languagesHeadingGap = 8;
}

class _ClassicSidebarTemplateArtCompact extends StatelessWidget {
  const _ClassicSidebarTemplateArtCompact({
    required this.resume,
    this.detailed = false,
  });

  final ResumeData resume;
  final bool detailed;

  static const double _layoutScale = 240 / 595.28;

  /// [_ClassicSidebarPreview] sidebar is 122 logical px wide; tile art is 60.
  static const double _previewSidebarWidth = 122;
  static const double _tileSidebarWidth = 60;

  static double _scaledPt(double pt) => pt * _layoutScale;

  static double _matchPreviewSpacing(double previewLogicalPx) =>
      previewLogicalPx * (_tileSidebarWidth / _previewSidebarWidth);

  /// Matches Classic Sidebar PDF main-column right margin (40pt).
  static double get _mainColumnRightPadding => _scaledPt(40);

  TextStyle _bodyStyle() => ResumeTypography.nunitoBodyPreviewStyle(
        fontSize: _scaledPt(resume.effectiveBodyFontPt.toDouble()),
        color: ResumeTypography.classicSidebarBodyTextColor,
        height: ResumeTypography.classicSidebarBodyLineHeight,
      );

  static TextStyle _subtitleStyle({bool italic = false}) =>
      ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.classicSidebarSubtitleWeight,
        fontSize: _scaledPt(ResumeTypography.classicSidebarSubtitlePt),
        color: ResumeTypography.classicSidebarBodyTextColor,
        height: ResumeTypography.classicSidebarBodyLineHeight,
      ).copyWith(fontStyle: italic ? FontStyle.italic : null);

  static TextStyle _nameStyle() => ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.classicSidebarNameWeight,
        fontSize: _scaledPt(ResumeTypography.classicSidebarNamePt),
        color: ResumeTypography.classicSidebarBodyTextColor,
        height: 1,
        letterSpacing: 0.2,
      );

  /// Matches [_ClassicSidebarPreview] avatar initials sizing, scaled for tile art.
  static double _avatarInitialsFontSize(ResumeData resume) => _scaledPt(
        ResumeTypography.classicSidebarAvatarInitialsFontPt(
          resume.classicSidebarScaledPt(ResumeTypography.classicSidebarNamePt),
        ),
      );

  static TextStyle _avatarInitialsStyle(ResumeData resume) =>
      ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.classicSidebarNameWeight,
        fontSize: _avatarInitialsFontSize(resume),
        color: ResumeTypography.classicSidebarBodyTextColor,
        height: 1,
      );

  static TextStyle _sectionHeadingStyle() => ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.classicSidebarSectionTitleWeight,
        fontSize: _scaledPt(ResumeTypography.classicSidebarSectionTitlePt),
        color: ResumeTypography.classicSidebarBodyTextColor,
        height: ResumeTypography.classicSidebarBodyLineHeight,
        letterSpacing: 0.2,
      );

  TextStyle _sidebarStyle() => ResumeTypography.calibriPreviewStyle(
        weight: ResumeTypography.classicSidebarSidebarContentWeight,
        fontSize: _scaledPt(resume.effectiveBodyFontPt.toDouble()),
        color: ResumeTypography.classicSidebarBodyTextColor,
        height: ResumeTypography.classicSidebarBodyLineHeight,
      );

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2E7CB3);
    final rail = Color.lerp(Colors.white, accent, 0.14)!;
    final avatar = Color.lerp(accent, Colors.white, 0.45)!;
    const title = Color(0xFF1F2937);
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

    final bodyStyle = _bodyStyle();
    final sidebarStyle = _sidebarStyle();
    final nameStyle = _nameStyle();
    final avatarInitialsStyle = _avatarInitialsStyle(resume);
    final sectionHeadingStyle = _sectionHeadingStyle();
    final subtitleStyle = _subtitleStyle();
    final mutedBodyStyle = bodyStyle.copyWith(color: muted);

    return DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: 'Calibri'),
      child: DecoratedBox(
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
                style: sidebarStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: avatar,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _miniClassicInitials(resume.fullName),
                              textAlign: TextAlign.center,
                              style: avatarInitialsStyle.copyWith(color: title),
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: line),
                    const SizedBox(height: 6),
                    Text(
                      'SKILLS',
                      style: sectionHeadingStyle.copyWith(color: title),
                    ),
                    SizedBox(
                      height: _matchPreviewSpacing(
                        _ClassicSidebarPreviewSkillsSpacing.headingGap,
                      ),
                    ),
                    _MiniBulletColumn(
                      items: skills,
                      bulletColor: accent,
                      textStyle: bodyStyle,
                      itemBottom: _matchPreviewSpacing(
                        _ClassicSidebarPreviewSkillsSpacing.itemGap,
                      ),
                    ),
                    SizedBox(
                      height: _matchPreviewSpacing(
                        _ClassicSidebarPreviewSkillsSpacing.afterSectionGap,
                      ),
                    ),
                    Container(height: 1, color: line),
                    SizedBox(
                      height: _matchPreviewSpacing(
                        _ClassicSidebarPreviewSkillsSpacing.beforeNextTitleGap,
                      ),
                    ),
                    Text(
                      'LANGUAGES',
                      style: sectionHeadingStyle.copyWith(color: title),
                    ),
                    SizedBox(
                      height: _matchPreviewSpacing(
                        _ClassicSidebarPreviewSkillsSpacing.languagesHeadingGap,
                      ),
                    ),
                    _MiniBulletColumn(
                      items: languages,
                      bulletColor: accent,
                      textStyle: bodyStyle,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  9,
                  14,
                  _mainColumnRightPadding,
                  6,
                ),
                child: DefaultTextStyle(
                  style: bodyStyle,
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
                            style: nameStyle.copyWith(color: title),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            resume.jobTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle.copyWith(
                              color: muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: detailed ? 5 : 3),
                          _MiniClassicInfoLine(text: resume.email),
                          SizedBox(height: detailed ? 4 : 3),
                          _MiniClassicInfoLine(text: resume.location),
                          SizedBox(height: detailed ? 4 : 3),
                          _MiniClassicInfoLine(text: resume.phone),
                          if (resume.githubLink.trim().isNotEmpty) ...[
                            SizedBox(height: detailed ? 4 : 3),
                            _MiniClassicInfoLine(text: resume.githubLink.trim()),
                          ],
                          if (resume.linkedinLink.trim().isNotEmpty) ...[
                            SizedBox(height: detailed ? 4 : 3),
                            _MiniClassicInfoLine(
                              text: resume.linkedinLink.trim(),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'SUMMARY',
                            style: sectionHeadingStyle.copyWith(color: title),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            summary,
                            maxLines: detailed ? 5 : 2,
                            overflow: TextOverflow.clip,
                            style: bodyStyle,
                          ),
                          SizedBox(height: detailed ? 4 : 2),
                          Container(height: 1, color: line),
                          SizedBox(height: detailed ? 4 : 2),
                          Text(
                            'EXPERIENCE',
                            style: sectionHeadingStyle.copyWith(color: title),
                          ),
                          const SizedBox(height: 4),
                          if (experiences.isNotEmpty) ...[
                            Text(
                              experiences.first.role,
                              style: subtitleStyle.copyWith(color: title),
                            ),
                            Text(
                              _classicSidebarExperienceCompanyDatesLine(
                                experiences.first,
                              ),
                              style: bodyStyle,
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
                          SizedBox(height: detailed ? 4 : 2),
                          Container(height: 1, color: line),
                          SizedBox(height: detailed ? 4 : 2),
                          Text(
                            'EDUCATION',
                            style: sectionHeadingStyle.copyWith(color: title),
                          ),
                          const SizedBox(height: 4),
                          for (final item in education) ...[
                            Text(
                              '${item.degree.trim().isEmpty ? 'Degree' : item.degree.trim()}, '
                              '${item.institution.trim().isEmpty ? 'Institution' : item.institution.trim()}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleStyle.copyWith(color: title),
                            ),
                            if ([
                              item.startDate.trim(),
                              item.endDate.trim(),
                            ].where((value) => value.isNotEmpty).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  [
                                    item.startDate.trim(),
                                    item.endDate.trim(),
                                  ].where((value) => value.isNotEmpty).join(' - '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: mutedBodyStyle.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            SizedBox(height: detailed ? 8 : 6),
                          ],
                          SizedBox(height: detailed ? 3 : 2),
                          Container(height: 1, color: line),
                          SizedBox(height: detailed ? 4 : 2),
                          Text(
                            'PROJECTS',
                            style: sectionHeadingStyle.copyWith(color: title),
                          ),
                          const SizedBox(height: 4),
                          for (final item in projects) ...[
                            Text(
                              item.title,
                              style: subtitleStyle.copyWith(color: title),
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

class _ProfileSidebarContactRow extends StatelessWidget {
  const _ProfileSidebarContactRow({
    required this.text,
    required this.accentColor,
    required this.style,
  });

  final String text;
  final Color accentColor;
  final TextStyle style;

  static const double _squareSize = 3.6;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 4.2;
    final lineHeight = style.height ?? ResumeTypography.creativeBodyLineHeight;
    final firstLineExtent = fontSize * lineHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: firstLineExtent,
          child: Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.square,
              size: _squareSize,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(width: 3),
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

class _MiniSidebarHeading extends StatelessWidget {
  const _MiniSidebarHeading({
    required this.title,
    required this.lineColor,
    this.titleStyle,
    this.lineHeight = 1.1,
    this.titleGap = 4,
  });

  final String title;
  final Color lineColor;
  final TextStyle? titleStyle;
  final double lineHeight;
  final double titleGap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle ??
                const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 5.8,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        SizedBox(width: titleGap),
        Expanded(
          flex: 6,
          child: Container(height: lineHeight, color: lineColor),
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
    this.itemBottom = 2,
  });

  final List<String> items;
  final Color bulletColor;

  /// When omitted, inherits [DefaultTextStyle] (template arts should pass a small style).
  final TextStyle? textStyle;
  final double itemBottom;

  static const double _bulletTextGap = 3;

  @override
  Widget build(BuildContext context) {
    final base =
        textStyle ?? DefaultTextStyle.of(context).style;
    final fontSize = base.fontSize ?? 4.2;
    final lineHeight = base.height ?? 1.2;
    final firstLineExtent = fontSize * lineHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: itemBottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: firstLineExtent,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      '•',
                      style: base.copyWith(
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                        color: bulletColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _bulletTextGap),
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
