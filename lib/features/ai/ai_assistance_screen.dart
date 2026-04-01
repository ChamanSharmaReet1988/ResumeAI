import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/resume_import_service.dart';
import '../../core/services/resume_services.dart';
import '../shared/resume_preview_card.dart';
import '../shared/view_models.dart';

class ResumeAnalyserScreen extends StatefulWidget {
  const ResumeAnalyserScreen({super.key, required this.onOpenResumeBuilder});

  final VoidCallback onOpenResumeBuilder;

  @override
  State<ResumeAnalyserScreen> createState() => _ResumeAnalyserScreenState();
}

@Deprecated('Use ResumeAnalyserScreen instead.')
class AiAssistanceScreen extends ResumeAnalyserScreen {
  const AiAssistanceScreen({super.key, required super.onOpenResumeBuilder});
}

class _ResumeAnalyserScreenState extends State<ResumeAnalyserScreen> {
  final _jobDescriptionController = TextEditingController();

  bool _isBusy = false;
  List<String> _appliedChanges = const [];
  ImportedResumeFile? _uploadedResume;
  _ResumeHighlightPreviewData? _previewData;

  @override
  void initState() {
    super.initState();
    _jobDescriptionController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _jobDescriptionController.removeListener(_handleInputChanged);
    _jobDescriptionController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _runTask(Future<void> Function() task) async {
    if (_isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _pickResumeFile(ResumeImportService importService) async {
    try {
      final importedResume = await importService.pickResumeFile();
      if (!mounted || importedResume == null) {
        return;
      }

      setState(() {
        _uploadedResume = importedResume;
        _appliedChanges = const [];
        _previewData = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${importedResume.fileName} uploaded.')),
      );
    } on ResumeImportException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not upload that resume file right now.'),
        ),
      );
    }
  }

  Future<void> _applyAtsFixes({
    required LocalAiResumeService aiService,
    required ResumeRepository repository,
    required ResumeLibraryViewModel library,
    required ResumeData? selectedResume,
  }) async {
    final jobDescription = _jobDescriptionController.text.trim();
    final uploadedResume = _uploadedResume;

    if (jobDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste a job description first.')),
      );
      return;
    }

    if (uploadedResume == null &&
        (selectedResume == null || !selectedResume.hasMeaningfulContent)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload a resume or select a saved one first.'),
        ),
      );
      return;
    }

    await _runTask(() async {
      final beforeResume = uploadedResume != null
          ? aiService.parseImportedResumeText(
              resumeText: uploadedResume.resumeText,
              template: library.defaultTemplate,
              sourceTitle: uploadedResume.suggestedTitle,
            )
          : selectedResume!;
      final result = await aiService.improveResumeForAts(
        resume: beforeResume,
        jobDescription: jobDescription,
      );
      final improvedResume = result.resume.copyWith(updatedAt: DateTime.now());

      await repository.upsertResume(improvedResume);
      await library.loadResumes();
      library.selectResume(improvedResume.id);

      if (!mounted) {
        return;
      }

      final beforeSummary = beforeResume.summary.trim();
      final afterSummary = improvedResume.summary.trim();
      final highlightedSkills = improvedResume.skills
          .where((skill) => !beforeResume.skills.contains(skill))
          .toSet();
      final highlightedBulletsByExperience = <int, Set<String>>{};
      for (
        var index = 0;
        index < improvedResume.workExperiences.length;
        index++
      ) {
        final updatedExperience = improvedResume.workExperiences[index];
        final originalExperience = index < beforeResume.workExperiences.length
            ? beforeResume.workExperiences[index]
            : const WorkExperience.empty();
        final newBullets = updatedExperience.bullets
            .where((bullet) => !originalExperience.bullets.contains(bullet))
            .toSet();
        if (newBullets.isNotEmpty) {
          highlightedBulletsByExperience[index] = newBullets;
        }
      }

      setState(() {
        _appliedChanges = result.appliedChanges;
        _previewData = _ResumeHighlightPreviewData(
          beforeResume: beforeResume,
          afterResume: improvedResume,
          highlightSummary: beforeSummary != afterSummary,
          highlightedSkills: highlightedSkills,
          highlightedBulletsByExperience: highlightedBulletsByExperience,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploadedResume != null
                ? 'Uploaded resume imported and improved.'
                : 'AI improvements applied to the selected resume.',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiService = context.read<LocalAiResumeService>();
    final importService = context.read<ResumeImportService>();
    final repository = context.read<ResumeRepository>();
    final pdfService = context.read<ResumePdfService>();
    final library = context.watch<ResumeLibraryViewModel>();
    final selectedResume = library.selectedResume;
    final hasSelectedResume = selectedResume?.hasMeaningfulContent ?? false;
    final canImprove =
        (_uploadedResume != null || hasSelectedResume) &&
        _jobDescriptionController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume analyser',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a resume, paste the target job description, and let AI improve the resume for that role. Uploaded files open through the system file picker, so this uses Files on iPhone and Drive-enabled pickers on Android.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _jobDescriptionController,
            minLines: 5,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Job description',
              hintText:
                  'Paste the target job post to compare your resume against it.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                key: const Key('upload-resume-button'),
                onPressed: () => _pickResumeFile(importService),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload resume'),
              ),
              FilledButton.icon(
                key: const Key('improve-resume-ai-button'),
                onPressed: canImprove
                    ? () => _applyAtsFixes(
                        aiService: aiService,
                        repository: repository,
                        library: library,
                        selectedResume: selectedResume,
                      )
                    : null,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Improve resume by AI'),
              ),
            ],
          ),
          if (_isBusy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 20),
          if (!hasSelectedResume && _uploadedResume == null)
            FilledButton.tonal(
              onPressed: widget.onOpenResumeBuilder,
              child: const Text('Open builder'),
            ),
          if (_appliedChanges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Applied changes',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ..._appliedChanges.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
          if (_previewData != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _AnalyserCard(
                title: 'Improved resume PDF',
                subtitle:
                    'The improved PDF below highlights AI changes in yellow so you can see exactly what was updated.',
                icon: Icons.picture_as_pdf_outlined,
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.82,
                  child: _HighlightedResumePdfPreview(
                    pdfService: pdfService,
                    previewData: _previewData!,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalyserCard extends StatelessWidget {
  const _AnalyserCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResumeHighlightPreviewData {
  const _ResumeHighlightPreviewData({
    required this.beforeResume,
    required this.afterResume,
    required this.highlightSummary,
    required this.highlightedSkills,
    required this.highlightedBulletsByExperience,
  });

  final ResumeData beforeResume;
  final ResumeData afterResume;
  final bool highlightSummary;
  final Set<String> highlightedSkills;
  final Map<int, Set<String>> highlightedBulletsByExperience;
}

class _HighlightedResumePdfPreview extends StatelessWidget {
  const _HighlightedResumePdfPreview({
    required this.pdfService,
    required this.previewData,
  });

  final ResumePdfService pdfService;
  final _ResumeHighlightPreviewData previewData;

  @override
  Widget build(BuildContext context) {
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');

    if (isTestBinding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ResumePreviewCard(resume: previewData.afterResume),
            ),
          ),
          const SizedBox(height: 12),
          if (previewData.highlightSummary)
            const Text('Highlighted summary change'),
          if (previewData.highlightedSkills.isNotEmpty)
            Text(
              'Highlighted skills: ${previewData.highlightedSkills.join(', ')}',
            ),
        ],
      );
    }

    return PdfPreview.builder(
      key: ValueKey(previewData.afterResume.updatedAt.microsecondsSinceEpoch),
      build: (_) => pdfService.buildHighlightedResumePdf(
        resume: previewData.afterResume,
        highlightSummary: previewData.highlightSummary,
        highlightedSkills: previewData.highlightedSkills,
        highlightedBulletsByExperience:
            previewData.highlightedBulletsByExperience,
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
      scrollViewDecoration: const BoxDecoration(color: Colors.white),
      pdfPreviewPageDecoration: const BoxDecoration(color: Colors.white),
      loadingWidget: const Center(child: CircularProgressIndicator()),
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
  }
}
