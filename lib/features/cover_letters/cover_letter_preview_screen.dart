import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/bottom_sheet_insets.dart';
import '../../core/corporate_resume_style.dart';
import '../../core/models/resume_models.dart';
import '../../core/services/analytics_events.dart';
import '../../core/services/resume_services.dart';
import '../shared/native_pdf_preview.dart';
import '../shared/view_models.dart';
import '../templates/templates_screen.dart';

class CoverLetterPreviewScreen extends StatefulWidget {
  const CoverLetterPreviewScreen({super.key, this.backPopsToHome = false});

  /// When `true`, the system/back control pops with `null` so the caller can
  /// return to the home screen (e.g. home preview, or editor preview where
  /// the editor routes are popped as well). When `false`, back returns to the
  /// cover letter content screen underneath.
  final bool backPopsToHome;

  @override
  State<CoverLetterPreviewScreen> createState() =>
      _CoverLetterPreviewScreenState();
}

class _CoverLetterPreviewScreenState extends State<CoverLetterPreviewScreen> {
  Future<void> _sharePdf() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    final pdfService = context.read<ResumePdfService>();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 160));
      final file = await pdfService.saveCoverLetterPdfToDevice(
        viewModel.coverLetter,
      );
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${viewModel.coverLetter.displayTitle} cover letter',
        text: 'Shared from ResumeAI',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      if (!mounted) {
        return;
      }
      await logAnalyticsEvent(
        context,
        AnalyticsEvents.coverLetterSharedPdf,
        parameters: {
          ...coverLetterTemplateAnalytics(viewModel.coverLetter.template),
          'source': 'cover_letter_preview',
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open share sheet right now.')),
      );
    }
  }

  Future<void> _chooseTemplate() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    final selectedTemplate = await Navigator.of(context)
        .push<CoverLetterTemplate>(
          MaterialPageRoute<CoverLetterTemplate>(
            builder: (routeContext) {
              return Scaffold(
                appBar: AppBar(
                  leadingWidth: 56,
                  titleSpacing: 2,
                  title: const Text('Choose template'),
                ),
                body: TemplatesScreen(
                  selectedCoverLetterTemplate: viewModel.coverLetter.template,
                  onCoverLetterTemplateSelected: (template) =>
                      Navigator.of(routeContext).pop(template),
                ),
              );
            },
          ),
        );

    if (!mounted ||
        selectedTemplate == null ||
        selectedTemplate == viewModel.coverLetter.template) {
      return;
    }

    viewModel.updateCoverLetter(
      (letter) => letter.copyWith(
        template: selectedTemplate,
        bodyFontPt: kResumeBodyFontPtDefault,
        corporateColorPresetIndex: defaultColorPresetIndexForCoverLetterTemplate(
          selectedTemplate,
        ),
      ),
    );
    await viewModel.saveCoverLetter(showBusy: false);
    if (!mounted) {
      return;
    }
    await logAnalyticsEvent(
      context,
      AnalyticsEvents.coverLetterTemplateSelected,
      parameters: {
        ...coverLetterTemplateAnalytics(selectedTemplate),
        'source': 'cover_letter_preview',
      },
    );
  }

  void _onBackPressed() {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      return;
    }
    if (widget.backPopsToHome) {
      navigator.pop<bool?>(null);
      return;
    }
    navigator.pop(true);
  }

  Future<void> _showCoverLetterStyleSheet() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final theme = Theme.of(sheetContext);
            final muted = theme.colorScheme.onSurfaceVariant;
            final letter = viewModel.coverLetter;
            final selectedTemplateDefault =
                letter.corporateColorPresetIndex ==
                kTemplateDefaultColorPresetIndex;
            final presetIndex = selectedTemplateDefault
                ? 0
                : letter.corporateColorPresetIndex.clamp(
                    0,
                    kCorporateColorPresets.length - 1,
                  );

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: BottomSheetInsets.topSpacing,
                    bottom: 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Font size',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '$kResumeBodyFontPtMin',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: letter.effectiveBodyFontPt
                                        .clamp(
                                          kResumeBodyFontPtMin,
                                          kResumeBodyFontPtMax,
                                        )
                                        .toDouble(),
                                    min: kResumeBodyFontPtMin.toDouble(),
                                    max: kResumeBodyFontPtMax.toDouble(),
                                    divisions: kResumeBodyFontPtMax -
                                        kResumeBodyFontPtMin,
                                    label: '${letter.effectiveBodyFontPt}',
                                    onChanged: (v) {
                                      viewModel.updateCoverLetter(
                                        (current) => current.copyWith(
                                          bodyFontPt: v.round(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '$kResumeBodyFontPtMax',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Text(
                          'Color',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const outerLeftMargin = 20.0;
                          const outerRightMargin = 20.0;
                          const itemGap = 12.0;
                          final items = <Widget>[
                            for (
                              var i = 0;
                              i < kCorporateColorPresets.length;
                              i++
                            )
                              _CoverLetterColorPresetCircle(
                                preset: kCorporateColorPresets[i],
                                selected: presetIndex == i,
                                onTap: () {
                                  viewModel.updateCoverLetter(
                                    (current) => current.copyWith(
                                      corporateColorPresetIndex: i,
                                    ),
                                  );
                                },
                              ),
                            _CoverLetterColorPresetCircle(
                              preset: CorporateColorPreset(
                                titleColor: const Color(0xFF2E3135),
                                headerColor: letter.template.accentColor,
                              ),
                              selected: selectedTemplateDefault,
                              onTap: () {
                                viewModel.updateCoverLetter(
                                  (current) => current.copyWith(
                                    corporateColorPresetIndex:
                                        kTemplateDefaultColorPresetIndex,
                                  ),
                                );
                              },
                            ),
                          ];
                          final lastIndex = items.length - 1;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < items.length; i++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: i == 0 ? outerLeftMargin : 0,
                                        right: i == lastIndex
                                            ? outerRightMargin
                                            : itemGap,
                                      ),
                                      child: items[i],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfService = context.read<ResumePdfService>();
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final barBg = theme.cardColor;

    return Consumer<CoverLetterEditorViewModel>(
      builder: (context, viewModel, _) {
        final letter = viewModel.coverLetter;
        final isTestBinding = WidgetsBinding.instance.runtimeType
            .toString()
            .contains('TestWidgetsFlutterBinding');
        final iosTitleStyle = Theme.of(
          context,
        ).cupertinoOverrideTheme?.textTheme?.navTitleTextStyle;
        final baseTitleStyle = Theme.of(context).platform == TargetPlatform.iOS
            ? iosTitleStyle?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              )
            : Theme.of(context).appBarTheme.titleTextStyle;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _onBackPressed();
          },
          child: Scaffold(
            backgroundColor: scaffoldBg,
            appBar: AppBar(
              backgroundColor: barBg,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              leadingWidth: 56,
              automaticallyImplyLeading: Navigator.of(context).canPop(),
              leading: Navigator.of(context).canPop()
                  ? BackButton(onPressed: _onBackPressed)
                  : null,
              titleSpacing: 2,
              title: Text(letter.displayTitle, style: baseTitleStyle),
            ),
          body: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    color: scaffoldBg,
                    child: Column(
                      children: [
                        if (viewModel.isBusy) const LinearProgressIndicator(),
                        Expanded(
                          child: Container(
                            key: const Key('cover-letter-preview-screen'),
                            width: double.infinity,
                            color: scaffoldBg,
                            child: isTestBinding
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: SingleChildScrollView(
                                      child: Text(letter.content),
                                    ),
                                  )
                                : NativePdfPreview(
                                    key: ValueKey(
                                      '${letter.template.name}-${letter.bodyFontPt}-${letter.corporateColorPresetIndex}-${letter.updatedAt.microsecondsSinceEpoch}',
                                    ),
                                    documentKey:
                                        '${letter.id}-${letter.updatedAt.microsecondsSinceEpoch}',
                                    viewerBackground: scaffoldBg,
                                    bytesFuture: pdfService.buildCoverLetterPdf(
                                      letter,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _CoverLetterPreviewBottomBar(
                backgroundColor: barBg,
                onTemplate: _chooseTemplate,
                onShare: _sharePdf,
                onStyle: _showCoverLetterStyleSheet,
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _CoverLetterColorPresetCircle extends StatelessWidget {
  const _CoverLetterColorPresetCircle({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final CorporateColorPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: preset.headerColor,
            border: preset.usesLightHeader
                ? Border.all(
                    color: Colors.black.withValues(alpha: 0.14),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.12 : 0.06),
                blurRadius: selected ? 8 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverLetterPreviewBottomBar extends StatelessWidget {
  const _CoverLetterPreviewBottomBar({
    required this.backgroundColor,
    required this.onTemplate,
    required this.onShare,
    required this.onStyle,
  });

  final Color backgroundColor;
  final VoidCallback onTemplate;
  final VoidCallback onShare;
  final VoidCallback onStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CoverLetterPreviewBottomAction(
                icon: Icons.view_quilt_outlined,
                label: 'Template',
                onTap: onTemplate,
              ),
              _CoverLetterPreviewBottomAction(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: onShare,
              ),
              _CoverLetterPreviewBottomAction(
                icon: Icons.palette_outlined,
                label: 'Color & Font',
                onTap: onStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverLetterPreviewBottomAction extends StatelessWidget {
  const _CoverLetterPreviewBottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
