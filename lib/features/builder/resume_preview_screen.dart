import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/bottom_sheet_insets.dart';
import '../../core/corporate_resume_style.dart';
import '../../core/models/resume_models.dart';
import '../shared/resume_preview_card.dart';
import '../templates/templates_screen.dart';
import '../shared/view_models.dart';

class ResumePreviewScreen extends StatefulWidget {
  const ResumePreviewScreen({
    super.key,
    this.backPopsToHome = false,
  });

  /// When `true` (e.g. opened from home via preview action), the system/back
  /// control pops with `null` so only the home screen remains. When `false`
  /// (opened from the resume builder), back pops with the current step so the
  /// builder is shown again.
  final bool backPopsToHome;

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<ResumeEditorViewModel>().analyzeResume();
    });
  }

  Future<void> _shareResume() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    try {
      // Brief delay before opening the share sheet.
      await Future<void>.delayed(const Duration(milliseconds: 160));
      final file = await viewModel.pdfService.savePdfToDevice(viewModel.resume);
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${viewModel.resume.title} resume',
        text: 'Shared from ResumeAI',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
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
    final viewModel = context.read<ResumeEditorViewModel>();
    final selectedTemplate = await Navigator.of(context).push<ResumeTemplate>(
      MaterialPageRoute<ResumeTemplate>(
        builder: (routeContext) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: 56,
              titleSpacing: 2,
              title: const Text('Choose template'),
            ),
            body: TemplatesScreen(
              selectedTemplate: viewModel.resume.template,
              onTemplateSelected: (template) =>
                  Navigator.of(routeContext).pop(template),
            ),
          );
        },
      ),
    );

    if (!mounted ||
        selectedTemplate == null ||
        selectedTemplate == viewModel.resume.template) {
      return;
    }

    viewModel.updateResume(
      (resume) => resume.copyWith(
        template: selectedTemplate,
        bodyFontPt: 13,
        corporateColorPresetIndex: defaultColorPresetIndexForTemplate(
          selectedTemplate,
        ),
      ),
    );
    await viewModel.saveResume();
  }

  void _onBackPressed() {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      return;
    }
    if (widget.backPopsToHome) {
      navigator.pop<int?>(null);
      return;
    }
    final step = context.read<ResumeEditorViewModel>().currentStep;
    navigator.pop(step);
  }

  /// Toolbar Edit: always returns a step so the shell can open the builder,
  /// or the resume builder restores the step underneath preview.
  void _openEditResume() {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      return;
    }
    final step = context.read<ResumeEditorViewModel>().currentStep;
    navigator.pop(step);
  }

  Future<void> _showResumeStyleSheet() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        // Modal overlay is not under the route's Provider; listen to the
        // view model directly instead of Consumer<ResumeEditorViewModel>.
        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final theme = Theme.of(sheetContext);
            final muted = theme.colorScheme.onSurfaceVariant;
            final resume = viewModel.resume;
            final selectedTemplateDefault =
                resume.corporateColorPresetIndex ==
                kTemplateDefaultColorPresetIndex;
            final presetIndex = selectedTemplateDefault
                ? 0
                : resume.corporateColorPresetIndex.clamp(
                    0,
                    kCorporateColorPresets.length - 1,
                  );

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20 + BottomSheetInsets.leftPadding,
                    8 + BottomSheetInsets.topSpacing,
                    20,
                    28,
                  ),
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
                              '11',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: resume.effectiveBodyFontPt.toDouble(),
                              min: 11,
                              max: 15,
                              divisions: 4,
                              label: '${resume.effectiveBodyFontPt}',
                              onChanged: (v) {
                                viewModel.updateResume(
                                  (r) => r.copyWith(bodyFontPt: v.round()),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '15',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Color',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var i = 0; i < kCorporateColorPresets.length; i++)
                            _CorporateColorPresetCircle(
                              preset: kCorporateColorPresets[i],
                              selected: presetIndex == i,
                              onTap: () {
                                viewModel.updateResume(
                                  (r) =>
                                      r.copyWith(corporateColorPresetIndex: i),
                                );
                              },
                            ),
                          _CorporateColorPresetCircle(
                            preset: CorporateColorPreset(
                              titleColor: const Color(0xFF2E3135),
                              headerColor: resume.template.accentColor,
                            ),
                            selected: selectedTemplateDefault,
                            onTap: () {
                              viewModel.updateResume(
                                (r) => r.copyWith(
                                  corporateColorPresetIndex:
                                      kTemplateDefaultColorPresetIndex,
                                ),
                              );
                            },
                          ),
                        ],
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
    return Consumer<ResumeEditorViewModel>(
      builder: (context, viewModel, _) {
        final currentTitle = viewModel.resume.title.ifBlank('Resume Preview');
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
        final titleStyle = baseTitleStyle;
        final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
        final barBg = Theme.of(context).cardColor;

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
              title: Text(currentTitle, style: titleStyle),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    onPressed: _openEditResume,
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ],
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
                              key: const Key('resume-pdf-preview'),
                              width: double.infinity,
                              color: scaffoldBg,
                              child: isTestBinding
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: ResumePreviewCard(
                                        resume: viewModel.resume,
                                      ),
                                    )
                                  : _NativePdfPreview(
                                      key: ValueKey(
                                        '${viewModel.resume.template.name}-${viewModel.resume.bodyFontPt}-${viewModel.resume.corporateColorPresetIndex}-${viewModel.resume.updatedAt.microsecondsSinceEpoch}',
                                      ),
                                      documentKey:
                                          '${viewModel.resume.id}-${viewModel.resume.updatedAt.microsecondsSinceEpoch}',
                                      viewerBackground: scaffoldBg,
                                      bytesFuture: viewModel.pdfService
                                          .buildPdf(viewModel.resume),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _ResumePreviewBottomBar(
                  backgroundColor: barBg,
                  onTemplate: _chooseTemplate,
                  onShare: _shareResume,
                  onStyle: _showResumeStyleSheet,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CorporateColorPresetCircle extends StatelessWidget {
  const _CorporateColorPresetCircle({
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

class _ResumePreviewBottomBar extends StatelessWidget {
  const _ResumePreviewBottomBar({
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
              _PreviewBottomAction(
                icon: Icons.view_quilt_outlined,
                label: 'Template',
                onTap: onTemplate,
              ),
              _PreviewBottomAction(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: onShare,
              ),
              _PreviewBottomAction(
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

class _PreviewBottomAction extends StatelessWidget {
  const _PreviewBottomAction({
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

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}

class _NativePdfPreview extends StatefulWidget {
  const _NativePdfPreview({
    super.key,
    required this.bytesFuture,
    required this.documentKey,
    required this.viewerBackground,
  });

  final Future<Uint8List> bytesFuture;

  /// Stable id for [PdfViewer.data] `sourceName` (must change when the PDF bytes change).
  final String documentKey;
  final Color viewerBackground;

  @override
  State<_NativePdfPreview> createState() => _NativePdfPreviewState();
}

class _NativePdfPreviewState extends State<_NativePdfPreview> {
  int _currentPage = 1;
  int _totalPages = 1;
  late Future<Uint8List> _cachedBytesFuture;

  late PdfViewerParams _viewerParams;

  @override
  void initState() {
    super.initState();
    _cachedBytesFuture = widget.bytesFuture;
  }

  @override
  void didUpdateWidget(covariant _NativePdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate bytes only when the caller signals a new PDF document.
    if (oldWidget.documentKey != widget.documentKey) {
      _cachedBytesFuture = widget.bytesFuture;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewerParams = PdfViewerParams(
      margin: 10,
      backgroundColor: widget.viewerBackground,
      pageDropShadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
      scrollPhysics: PdfViewerParams.getScrollPhysics(context),
      onPageChanged: _onPdfPageChanged,
      onViewerReady: _onPdfViewerReady,
    );
  }

  void _onPdfPageChanged(int? pageNumber) {
    if (!mounted) {
      return;
    }
    setState(() => _currentPage = pageNumber ?? 1);
  }

  void _onPdfViewerReady(PdfDocument document, PdfViewerController controller) {
    if (!mounted) {
      return;
    }
    setState(() {
      _totalPages = document.pages.length;
      _currentPage = controller.pageNumber ?? 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _cachedBytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Unable to load PDF preview right now.'),
          );
        }

        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Stack(
            children: [
              PdfViewer.data(
                snapshot.data!,
                sourceName: widget.documentKey,
                params: _viewerParams,
              ),
              Positioned(
                top: 14,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
