import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../shared/resume_preview_card.dart';
import '../templates/templates_screen.dart';
import '../shared/view_models.dart';

class ResumePreviewScreen extends StatefulWidget {
  const ResumePreviewScreen({super.key});

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

  Future<void> _downloadResume() async {
    final path = await context.read<ResumeEditorViewModel>().downloadPdf();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF saved to $path')));
  }

  Future<void> _shareResume() async {
    await context.read<ResumeEditorViewModel>().sharePdf();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share sheet opened.')));
  }

  Future<void> _printResume() async {
    await context.read<ResumeEditorViewModel>().printPdf();
  }

  Future<void> _chooseTemplate() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    final selectedTemplate = await Navigator.of(context).push<ResumeTemplate>(
      MaterialPageRoute<ResumeTemplate>(
        builder: (routeContext) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: 40,
              titleSpacing: 8,
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

  Future<void> _handleMenuSelection(_PreviewMenuAction action) async {
    switch (action) {
      case _PreviewMenuAction.chooseTemplate:
        await _chooseTemplate();
        return;
      case _PreviewMenuAction.atsScore:
        await _showAtsOptions();
        return;
      case _PreviewMenuAction.downloadPdf:
        await _downloadResume();
        return;
      case _PreviewMenuAction.shareResume:
        await _shareResume();
        return;
      case _PreviewMenuAction.printResume:
        await _printResume();
        return;
    }
  }

  void _returnToHome() {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      return;
    }

    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _showAtsOptions() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    final target = _bestImprovementTarget(
      resume: viewModel.resume,
      analysis: viewModel.analysis,
    );

    final selectedStep = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: _PreviewScoreCard(
              viewModel: viewModel,
              target: target,
              onIncreaseAts: () => Navigator.of(sheetContext).pop(target.step),
            ),
          ),
        );
      },
    );

    if (!mounted || selectedStep == null) {
      return;
    }

    Navigator.of(context).pop(selectedStep);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResumeEditorViewModel>(
      builder: (context, viewModel, _) {
        final currentTitle = viewModel.resume.title.ifBlank('Resume Preview');
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
        final titleStyle = baseTitleStyle;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _returnToHome();
          },
          child: Scaffold(
            appBar: AppBar(
              leadingWidth: 40,
              automaticallyImplyLeading: Navigator.of(context).canPop(),
              leading: Navigator.of(context).canPop()
                  ? BackButton(onPressed: _returnToHome)
                  : null,
              titleSpacing: 8,
              title: Text(currentTitle, style: titleStyle),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: PopupMenuButton<_PreviewMenuAction>(
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
                        value: _PreviewMenuAction.chooseTemplate,
                        child: Text('Choose template', style: menuTextStyle),
                      ),
                      PopupMenuItem(
                        value: _PreviewMenuAction.atsScore,
                        child: Text('ATS score', style: menuTextStyle),
                      ),
                      PopupMenuItem(
                        value: _PreviewMenuAction.downloadPdf,
                        child: Text('Download PDF', style: menuTextStyle),
                      ),
                      PopupMenuItem(
                        value: _PreviewMenuAction.shareResume,
                        child: Text('Share resume', style: menuTextStyle),
                      ),
                      PopupMenuItem(
                        value: _PreviewMenuAction.printResume,
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
                      key: const Key('resume-pdf-preview'),
                      width: double.infinity,
                      color: Colors.white,
                      child: isTestBinding
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: ResumePreviewCard(
                                resume: viewModel.resume,
                              ),
                            )
                          : PdfPreview.builder(
                              key: ValueKey(
                                '${viewModel.resume.template.name}-${viewModel.resume.updatedAt.microsecondsSinceEpoch}',
                              ),
                              build: (_) => viewModel.pdfService.buildPdf(
                                viewModel.resume,
                              ),
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
          ),
        );
      },
    );
  }
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}

enum _PreviewMenuAction {
  chooseTemplate,
  atsScore,
  downloadPdf,
  shareResume,
  printResume,
}

class _AtsImprovementTarget {
  const _AtsImprovementTarget({
    required this.step,
    required this.stepTitle,
    required this.description,
  });

  final int step;
  final String stepTitle;
  final String description;
}

_AtsImprovementTarget _bestImprovementTarget({
  required ResumeData resume,
  required ResumeAnalysis? analysis,
}) {
  if (!resume.hasRequiredPersonalInfo ||
      resume.summary.trim().length <= 90 ||
      resume.email.trim().isEmpty ||
      resume.phone.trim().isEmpty) {
    return const _AtsImprovementTarget(
      step: 0,
      stepTitle: 'Personal Information',
      description:
          'Add complete contact details and strengthen your summary to improve ATS readability.',
    );
  }

  if (resume.visibleWorkExperiences.isEmpty ||
      (analysis?.weakDescriptions.isNotEmpty ?? false)) {
    return const _AtsImprovementTarget(
      step: 1,
      stepTitle: 'Work Experience',
      description:
          'Add stronger outcome-focused work details and bullets to raise your ATS score.',
    );
  }

  if (resume.skills.length < 6 ||
      (analysis?.missingSkills.isNotEmpty ?? false)) {
    return const _AtsImprovementTarget(
      step: 3,
      stepTitle: 'Skills',
      description:
          'Add more relevant tools and keywords so ATS can match your resume more confidently.',
    );
  }

  if (resume.visibleProjects.isEmpty) {
    return const _AtsImprovementTarget(
      step: 4,
      stepTitle: 'Projects',
      description:
          'Add 1-2 strong projects with tools and outcomes to improve proof of execution.',
    );
  }

  if (resume.visibleEducation.isEmpty) {
    return const _AtsImprovementTarget(
      step: 2,
      stepTitle: 'Education',
      description:
          'Complete your education section so your profile feels more complete to recruiters.',
    );
  }

  return const _AtsImprovementTarget(
    step: 1,
    stepTitle: 'Work Experience',
    description:
        'Tune your strongest work entries with clearer outcomes and stronger keywords.',
  );
}

class _PreviewScoreCard extends StatelessWidget {
  const _PreviewScoreCard({
    required this.viewModel,
    required this.target,
    required this.onIncreaseAts,
  });

  final ResumeEditorViewModel viewModel;
  final _AtsImprovementTarget target;
  final VoidCallback onIncreaseAts;

  @override
  Widget build(BuildContext context) {
    final analysis = viewModel.analysis;
    final atsCompatibility =
        analysis?.atsCompatibility ?? viewModel.resume.completionRatio;
    final score = analysis?.score ?? (atsCompatibility * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ATS score',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                      ),
                      Center(
                        child: Text(
                          '$score',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'ATS compatibility ${(atsCompatibility * 100).round()}%'
                    '${analysis == null ? '.' : ' with ${analysis.missingSkills.length} missing skill gap${analysis.missingSkills.length == 1 ? '' : 's'}.'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Best next update: ${target.stepTitle}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              target.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onIncreaseAts,
              icon: const Icon(Icons.trending_up_rounded),
              label: Text('Increase ATS in ${target.stepTitle}'),
            ),
          ],
        ),
      ),
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
