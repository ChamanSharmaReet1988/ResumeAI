import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/bottom_sheet_insets.dart';
import '../../core/models/resume_models.dart';
import '../../core/resume_text_font.dart';
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
      (resume) => resume.copyWith(template: selectedTemplate),
    );
    await viewModel.saveResume();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selectedTemplate.label} template applied.')),
    );
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        // Modal overlay is not under the route's Provider; listen to the
        // view model directly instead of Consumer<ResumeEditorViewModel>.
        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final theme = Theme.of(sheetContext);
            final muted = theme.colorScheme.onSurfaceVariant;
            final groupValue = _resumeTemplateGroupValue(
              viewModel.resume.template,
            );

            Future<void> applyTemplate(ResumeTemplate template) async {
              if (viewModel.resume.template == template) {
                return;
              }
              viewModel.updateResume((r) => r.copyWith(template: template));
              await viewModel.saveResume();
            }

            Future<void> applyResumeTextFont(ResumeTextFont font) async {
              if (viewModel.resume.resumeTextFont == font) {
                return;
              }
              viewModel.updateResume((r) => r.copyWith(resumeTextFont: font));
              await viewModel.saveResume();
            }

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
                        'Color & Font',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose an accent color and a font layout. Both apply to your preview and exported PDF.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Accent color',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap a swatch to use that palette.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final template in availableResumeTemplates)
                              Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: _ResumeAccentSwatch(
                                  template: template,
                                  selected:
                                      _resumeTemplateGroupValue(
                                        viewModel.resume.template,
                                      ) ==
                                      template,
                                  onTap: () => applyTemplate(template),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Font & layout',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Each option uses tuned PDF typography for that structure.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioGroup<ResumeTemplate>(
                        groupValue: groupValue,
                        onChanged: (ResumeTemplate? value) {
                          if (value != null) {
                            applyTemplate(value);
                          }
                        },
                        child: Column(
                          children: [
                            for (final template in availableResumeTemplates)
                              RadioListTile<ResumeTemplate>(
                                value: template,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(template.label),
                                subtitle: Text(
                                  template.fontStyleLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Resume text font',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Used in the preview card. PDF export still follows each template’s PDF fonts.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioGroup<ResumeTextFont>(
                        groupValue: viewModel.resume.resumeTextFont,
                        onChanged: (ResumeTextFont? value) {
                          if (value != null) {
                            applyResumeTextFont(value);
                          }
                        },
                        child: Column(
                          children: [
                            for (final font in ResumeTextFont.values)
                              RadioListTile<ResumeTextFont>(
                                value: font,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(font.label),
                                subtitle: Text(
                                  font.hint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _chooseTemplate();
                          },
                          icon: const Icon(Icons.grid_view_rounded, size: 20),
                          label: const Text('Browse full template gallery'),
                        ),
                      ),
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
        const barBg = Colors.white;

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
                                        '${viewModel.resume.template.name}-${viewModel.resume.updatedAt.microsecondsSinceEpoch}',
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
                icon: Icons.share_outlined,
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

/// Maps stored template to the canonical entry in [availableResumeTemplates].
ResumeTemplate _resumeTemplateGroupValue(ResumeTemplate current) {
  for (final t in availableResumeTemplates) {
    if (t.userFacingTemplate == current.userFacingTemplate) {
      return t;
    }
  }
  return availableResumeTemplates.first;
}

Color _iconOnAccent(Color accent) {
  final luminance = accent.computeLuminance();
  return luminance > 0.55 ? const Color(0xFF1F2937) : Colors.white;
}

class _ResumeAccentSwatch extends StatelessWidget {
  const _ResumeAccentSwatch({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final ResumeTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: template.accentColor,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                  width: selected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: _iconOnAccent(template.accentColor),
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 92,
              child: Text(
                template.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
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

  late PdfViewerParams _viewerParams;

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
      future: widget.bytesFuture,
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
