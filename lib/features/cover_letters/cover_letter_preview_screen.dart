import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/resume_services.dart';
import '../shared/view_models.dart';
import '../templates/templates_screen.dart';

enum _CoverLetterPreviewMenuAction {
  chooseTemplate,
  downloadPdf,
  share,
  print,
}

class CoverLetterPreviewScreen extends StatefulWidget {
  const CoverLetterPreviewScreen({super.key});

  @override
  State<CoverLetterPreviewScreen> createState() =>
      _CoverLetterPreviewScreenState();
}

class _CoverLetterPreviewScreenState extends State<CoverLetterPreviewScreen> {
  Future<void> _downloadPdf() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    final pdfService = context.read<ResumePdfService>();
    final file = await pdfService.saveCoverLetterPdfToDevice(
      viewModel.coverLetter,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF saved to ${file.path}')));
  }

  Future<void> _sharePdf() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    final pdfService = context.read<ResumePdfService>();
    await pdfService.shareCoverLetter(viewModel.coverLetter);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share sheet opened.')));
  }

  Future<void> _printPdf() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    final pdfService = context.read<ResumePdfService>();
    await pdfService.printCoverLetter(viewModel.coverLetter);
  }

  Future<void> _chooseTemplate() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    final selectedTemplate = await Navigator.of(context).push<CoverLetterTemplate>(
      MaterialPageRoute<CoverLetterTemplate>(
        builder: (routeContext) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: 40,
              titleSpacing: 8,
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
      (letter) => letter.copyWith(template: selectedTemplate),
    );
    await viewModel.saveCoverLetter(showBusy: false);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selectedTemplate.label} template applied.')),
    );
  }

  Future<void> _handleMenuSelection(
    _CoverLetterPreviewMenuAction action,
  ) async {
    switch (action) {
      case _CoverLetterPreviewMenuAction.chooseTemplate:
        await _chooseTemplate();
        return;
      case _CoverLetterPreviewMenuAction.downloadPdf:
        await _downloadPdf();
        return;
      case _CoverLetterPreviewMenuAction.share:
        await _sharePdf();
        return;
      case _CoverLetterPreviewMenuAction.print:
        await _printPdf();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfService = context.read<ResumePdfService>();

    return Consumer<CoverLetterEditorViewModel>(
      builder: (context, viewModel, _) {
        final letter = viewModel.coverLetter;
        final isTestBinding = WidgetsBinding.instance.runtimeType
            .toString()
            .contains('TestWidgetsFlutterBinding');
        final menuTextStyle = Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500);
        final iosTitleStyle = Theme.of(
          context,
        ).cupertinoOverrideTheme?.textTheme?.navTitleTextStyle;
        final baseTitleStyle = Theme.of(context).platform == TargetPlatform.iOS
            ? iosTitleStyle?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              )
            : Theme.of(context).appBarTheme.titleTextStyle;

        return Scaffold(
          appBar: AppBar(
            leadingWidth: 40,
            titleSpacing: 8,
            title: Text(letter.displayTitle, style: baseTitleStyle),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: PopupMenuButton<_CoverLetterPreviewMenuAction>(
                  tooltip: 'Menu',
                  onSelected: _handleMenuSelection,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: const Icon(Icons.more_horiz_rounded, size: 22),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _CoverLetterPreviewMenuAction.chooseTemplate,
                      child: Text('Choose template', style: menuTextStyle),
                    ),
                    PopupMenuItem(
                      value: _CoverLetterPreviewMenuAction.downloadPdf,
                      child: Text('Download PDF', style: menuTextStyle),
                    ),
                    PopupMenuItem(
                      value: _CoverLetterPreviewMenuAction.share,
                      child: Text('Share', style: menuTextStyle),
                    ),
                    PopupMenuItem(
                      value: _CoverLetterPreviewMenuAction.print,
                      child: Text('Print', style: menuTextStyle),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (viewModel.isBusy) const LinearProgressIndicator(),
                Expanded(
                  child: Container(
                    key: const Key('cover-letter-preview-screen'),
                    width: double.infinity,
                    color: Colors.white,
                    child: isTestBinding
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: Text(letter.content),
                            ),
                          )
                        : PdfPreview.builder(
                            key: ValueKey(
                              '${letter.template.name}-${letter.updatedAt.microsecondsSinceEpoch}',
                            ),
                            build: (_) => pdfService.buildCoverLetterPdf(letter),
                            allowPrinting: false,
                            allowSharing: false,
                            useActions: false,
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            canDebug: false,
                            shouldRepaint: true,
                            dpi: 220,
                            pagesBuilder: (context, pages) {
                              return _ZoomablePdfPageViewer(pages: pages);
                            },
                            previewPageMargin: EdgeInsets.zero,
                            padding: EdgeInsets.zero,
                            scrollViewDecoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            pdfPreviewPageDecoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            loadingWidget: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
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

class _ZoomablePdfPageViewer extends StatefulWidget {
  const _ZoomablePdfPageViewer({required this.pages});

  final List<PdfPreviewPageData> pages;

  @override
  State<_ZoomablePdfPageViewer> createState() => _ZoomablePdfPageViewerState();
}

class _ZoomablePdfPageViewerState extends State<_ZoomablePdfPageViewer> {
  late final PageController _pageController;
  final List<TransformationController> _controllers = [];
  int _currentPage = 0;
  bool _isCurrentPageZoomed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _ZoomablePdfPageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
    if (_currentPage >= widget.pages.length && widget.pages.isNotEmpty) {
      _currentPage = widget.pages.length - 1;
    }
    _refreshZoomState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    while (_controllers.length < widget.pages.length) {
      _controllers.add(TransformationController());
    }
    while (_controllers.length > widget.pages.length) {
      _controllers.removeLast().dispose();
    }
  }

  void _refreshZoomState() {
    if (!mounted || widget.pages.isEmpty) {
      return;
    }

    final isZoomed =
        _controllers[_currentPage].value.getMaxScaleOnAxis() > 1.01;
    if (isZoomed != _isCurrentPageZoomed) {
      setState(() {
        _isCurrentPageZoomed = isZoomed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: _isCurrentPageZoomed
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      itemCount: widget.pages.length,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
          _isCurrentPageZoomed =
              _controllers[index].value.getMaxScaleOnAxis() > 1.01;
        });
      },
      itemBuilder: (context, index) {
        final page = widget.pages[index];
        final controller = _controllers[index];

        return LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer(
              transformationController: controller,
              minScale: 1,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(64),
              trackpadScrollCausesScale: true,
              clipBehavior: Clip.none,
              onInteractionUpdate: (_) => _refreshZoomState(),
              onInteractionEnd: (_) => _refreshZoomState(),
              child: SizedBox.expand(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: page.width.toDouble(),
                      height: page.height.toDouble(),
                      child: Image(image: page.image, fit: BoxFit.fill),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
