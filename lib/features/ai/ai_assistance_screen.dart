import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/resume_services.dart';
import 'resume_optimize_highlight.dart';
import '../shared/native_pdf_preview.dart';
import '../shared/resume_preview_card.dart';
import '../shared/view_models.dart';

class ResumeAnalyserScreen extends StatefulWidget {
  const ResumeAnalyserScreen({
    super.key,
    required this.onOpenResumeBuilder,
    this.onGoToHomeTab,
  });

  final VoidCallback onOpenResumeBuilder;
  final VoidCallback? onGoToHomeTab;

  @override
  State<ResumeAnalyserScreen> createState() => _ResumeAnalyserScreenState();
}

@Deprecated('Use ResumeAnalyserScreen instead.')
class AiAssistanceScreen extends ResumeAnalyserScreen {
  const AiAssistanceScreen({
    super.key,
    required super.onOpenResumeBuilder,
    super.onGoToHomeTab,
  });
}

enum _OptimizedResumeSaveChoice { newCopy, existingResume }


class _ResumeAnalyserScreenState extends State<ResumeAnalyserScreen>
    with WidgetsBindingObserver {
  static const double _fieldHorizontalPadding = 12;
  final _jobDescriptionController = TextEditingController();
  final _jobDescriptionFocusNode = FocusNode();
  OverlayEntry? _keyboardHideOverlay;

  bool _isBusy = false;
  List<String> _appliedChanges = const [];
  ResumeOptimizeHighlightData? _previewData;
  ResumeData? _createdResume;
  int _atsCreateAttempt = 0;
  String? _atsAttemptSourceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _jobDescriptionController.addListener(_handleInputChanged);
    _jobDescriptionFocusNode.addListener(_handleJobDescriptionFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _jobDescriptionController.removeListener(_handleInputChanged);
    _jobDescriptionController.dispose();
    _jobDescriptionFocusNode
      ..removeListener(_handleJobDescriptionFocusChanged)
      ..dispose();
    _removeKeyboardHideOverlay();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _scheduleKeyboardHideOverlayUpdate();
  }

  void _handleInputChanged() {
    if (!mounted) {
      return;
    }
    setState(_resetAtsCreateProgress);
  }

  void _handleJobDescriptionFocusChanged() {
    _scheduleKeyboardHideOverlayUpdate();
  }

  void _scheduleKeyboardHideOverlayUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateKeyboardHideOverlay();
      }
    });
  }

  double _keyboardInsetForOverlay() {
    if (!mounted) {
      return 0;
    }
    final view = View.of(context);
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  bool _shouldShowKeyboardHideOverlay() {
    return mounted &&
        _jobDescriptionFocusNode.hasFocus &&
        _keyboardInsetForOverlay() > 0;
  }

  void _updateKeyboardHideOverlay() {
    if (!_shouldShowKeyboardHideOverlay()) {
      _removeKeyboardHideOverlay();
      return;
    }

    if (_keyboardHideOverlay == null) {
      final overlay = Overlay.of(context, rootOverlay: true);
      _keyboardHideOverlay = OverlayEntry(
        builder: (overlayContext) {
          final keyboardInset = _keyboardInsetForOverlay();
          return Positioned(
            right: 12,
            bottom: keyboardInset + 8,
            child: SafeArea(
              minimum: const EdgeInsets.only(right: 4, bottom: 4),
              child: IconButton.filledTonal(
                key: const Key('optimize-hide-keyboard-button'),
                onPressed: () => FocusScope.of(context).unfocus(),
                icon: const Icon(Icons.keyboard_hide_rounded),
                tooltip: context.l10n.hideKeyboard,
              ),
            ),
          );
        },
      );
      overlay.insert(_keyboardHideOverlay!);
      return;
    }

    _keyboardHideOverlay?.markNeedsBuild();
  }

  void _removeKeyboardHideOverlay() {
    _keyboardHideOverlay?.remove();
    _keyboardHideOverlay = null;
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    _removeKeyboardHideOverlay();
  }

  void _resetOptimizationPreview() {
    _appliedChanges = const [];
    _previewData = null;
    _createdResume = null;
  }

  void _resetAtsCreateProgress() {
    _atsCreateAttempt = 0;
    _atsAttemptSourceId = null;
    _resetOptimizationPreview();
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

  Future<void> _createAtsResume({
    required LocalAiResumeService aiService,
    required ResumeData? selectedResume,
  }) async {
    _dismissKeyboard();

    if (selectedResume == null || !selectedResume.hasMeaningfulContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectResumeWithContentFirst),
        ),
      );
      return;
    }

    final jobDescription = _jobDescriptionController.text.trim();
    if (_atsAttemptSourceId != selectedResume.id) {
      _atsAttemptSourceId = selectedResume.id;
      _atsCreateAttempt = 0;
      _createdResume = null;
    }

    final sourceForPass = _createdResume ?? selectedResume;
    final attemptIndex = _atsCreateAttempt;

    await _runTask(() async {
      final result = await aiService.createAtsResumeWithAi(
        sourceResume: sourceForPass,
        jobDescription: jobDescription,
        attemptIndex: attemptIndex,
      );
      final created = result.resume.copyWith(updatedAt: DateTime.now());

      if (!mounted) {
        return;
      }

      setState(() {
        _createdResume = created;
        _atsCreateAttempt = attemptIndex + 1;
        _appliedChanges = result.appliedChanges;
        _previewData = buildResumeOptimizeHighlightData(
          beforeResume: sourceForPass,
          afterResume: created,
        );
      });
    });
  }

  Future<void> _openCreatedAtsResumePreview() async {
    final previewData = _previewData;
    final created = _createdResume;
    if (previewData == null || created == null) {
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _OptimizedResumePreviewScreen(
          sourceResume: created,
          previewData: previewData,
          saveAsNewCopyOnly: true,
          newCopyTitleSuffix: context.l10n.atsTitleSuffix,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    _jobDescriptionController.clear();
    setState(_resetAtsCreateProgress);
  }

  @override
  Widget build(BuildContext context) {
    final aiService = context.read<LocalAiResumeService>();
    final library = context.watch<ResumeLibraryViewModel>();
    final resumes = library.resumes;
    final selectedResume = library.selectedResume;
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: _jobDescriptionController,
      builder: (context, _) {
        final enableCreate = resumes.isNotEmpty &&
            selectedResume != null &&
            selectedResume.hasMeaningfulContent;
        final isFurtherPass = _createdResume != null &&
            _atsAttemptSourceId == selectedResume?.id &&
            _atsCreateAttempt > 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _fieldHorizontalPadding,
                ),
                child: Text(
                  l10n.aiAtsIntro,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (resumes.isEmpty) ...[
                Card(
                  child: InkWell(
                    key: const Key('optimize-empty-go-home-button'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.onGoToHomeTab,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.noResumeAvailable,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.createResumeThenGenerateAts,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (resumes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _fieldHorizontalPadding,
                  ),
                  child: Text(
                    l10n.selectResume,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                KeyedSubtree(
                  key: const Key('tailor-resume-selector'),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'tailor-resume-selector-${selectedResume?.id ?? resumes.first.id}',
                    ),
                    initialValue: selectedResume?.id ?? resumes.first.id,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    alignment: AlignmentDirectional.centerStart,
                    dropdownColor: Theme.of(context).cardColor,
                    elevation: 6,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    menuMaxHeight: 360,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _fieldHorizontalPadding,
                        vertical: 14,
                      ),
                    ),
                    selectedItemBuilder: (context) {
                      return resumes.map((resume) {
                        final title = resume.title.trim().isEmpty
                            ? ResumeData.defaultTitle
                            : resume.title;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        );
                      }).toList();
                    },
                    items: resumes
                        .map(
                          (resume) => DropdownMenuItem<String>(
                            value: resume.id,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _fieldHorizontalPadding,
                                vertical: 12,
                              ),
                              child: Text(
                                resume.title.trim().isEmpty
                                    ? ResumeData.defaultTitle
                                    : resume.title,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      library.selectResume(value);
                      setState(_resetAtsCreateProgress);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _jobDescriptionController,
                focusNode: _jobDescriptionFocusNode,
                minLines: 5,
                maxLines: 7,
                onChanged: (_) => _handleInputChanged(),
                decoration: InputDecoration(
                  labelText: l10n.jobDescriptionOptional,
                  hintText: l10n.jobDescriptionHint,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    key: const Key('create-ats-resume-ai-button'),
                    onPressed: enableCreate
                        ? () => _createAtsResume(
                            aiService: aiService,
                            selectedResume: selectedResume,
                          )
                        : null,
                    child: Text(
                      isFurtherPass
                          ? l10n.furtherOptimizeAtsPass(_atsCreateAttempt + 1)
                          : l10n.createAtsResume,
                    ),
                  ),
                ],
              ),
              if (_isBusy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 20),
              if (_appliedChanges.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.appliedChanges,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                if (_previewData != null && _createdResume != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.tonal(
                        key: const Key('show-created-ats-resume-button'),
                        onPressed: _openCreatedAtsResumePreview,
                        child: Text(l10n.showAtsResume),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OptimizedResumeTitleDialog extends StatefulWidget {
  const _OptimizedResumeTitleDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_OptimizedResumeTitleDialog> createState() =>
      _OptimizedResumeTitleDialogState();
}

class _OptimizedResumeTitleDialogState
    extends State<_OptimizedResumeTitleDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(l10n.resumeTitle),
      content: TextField(
        key: const Key('optimized-resume-title-dialog-field'),
        controller: _controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: l10n.resumeTitle),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('optimized-resume-title-dialog-save-button'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _OptimizedResumePreviewScreen extends StatefulWidget {
  const _OptimizedResumePreviewScreen({
    required this.sourceResume,
    required this.previewData,
    this.saveAsNewCopyOnly = false,
    this.newCopyTitleSuffix = '',
  });

  final ResumeData sourceResume;
  final ResumeOptimizeHighlightData previewData;
  final bool saveAsNewCopyOnly;
  final String newCopyTitleSuffix;

  @override
  State<_OptimizedResumePreviewScreen> createState() =>
      _OptimizedResumePreviewScreenState();
}

class _OptimizedResumePreviewScreenState
    extends State<_OptimizedResumePreviewScreen> {
  bool _isSaving = false;

  Future<_OptimizedResumeSaveChoice?> _promptSaveChoice() {
    final sourceTitle = widget.sourceResume.title.trim().isEmpty
        ? ResumeData.defaultTitle
        : widget.sourceResume.title.trim();
    final l10n = context.l10n;
    return showModalBottomSheet<_OptimizedResumeSaveChoice>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.saveOptimizedResume,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.saveOptimizedResumePrompt(sourceTitle),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  key: const Key('save-optimized-new-copy-button'),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_OptimizedResumeSaveChoice.newCopy),
                  child: Text(l10n.newCopy),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('save-optimized-existing-button'),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_OptimizedResumeSaveChoice.existingResume),
                  child: Text(l10n.existingResume),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _optimizedCopyTitle(String title) {
    final trimmed = title.trim();
    final baseTitle = trimmed.isEmpty ? ResumeData.defaultTitle : trimmed;
    final suffix = widget.newCopyTitleSuffix.isEmpty
        ? context.l10n.optimizedTitleSuffix
        : widget.newCopyTitleSuffix;
    return baseTitle.endsWith(suffix) ? baseTitle : '$baseTitle$suffix';
  }

  Future<String?> _promptNewCopyTitle() {
    final suggestedTitle = _optimizedCopyTitle(widget.sourceResume.title);
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _OptimizedResumeTitleDialog(initialTitle: suggestedTitle),
    );
  }

  Future<void> _saveResume() async {
    if (_isSaving) {
      return;
    }

    final _OptimizedResumeSaveChoice? choice;
    if (widget.saveAsNewCopyOnly) {
      choice = _OptimizedResumeSaveChoice.newCopy;
    } else {
      choice = await _promptSaveChoice();
    }
    if (!mounted || choice == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repository = context.read<ResumeRepository>();
      final library = context.read<ResumeLibraryViewModel>();
      final pendingOptimizedResume = widget.previewData.afterResume;
      String? copyTitle;
      if (choice == _OptimizedResumeSaveChoice.newCopy) {
        copyTitle = await _promptNewCopyTitle();
        if (!mounted || copyTitle == null) {
          return;
        }
      }
      final savedResume = switch (choice) {
        _OptimizedResumeSaveChoice.newCopy => pendingOptimizedResume.copyWith(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: copyTitle!.trim().isEmpty
              ? ResumeData.defaultTitle
              : copyTitle.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastSyncedAt: null,
        ),
        _OptimizedResumeSaveChoice.existingResume =>
          pendingOptimizedResume.copyWith(
            id: widget.sourceResume.id,
            title: widget.sourceResume.title,
            updatedAt: DateTime.now(),
          ),
      };

      await repository.upsertResume(savedResume);
      await library.loadResumes();
      library.selectResume(savedResume.id);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfService = context.read<ResumePdfService>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        titleSpacing: 2,
        title: Text(l10n.resumePreview),
      ),
      body: Column(
        children: [
          if (_isSaving) const LinearProgressIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _HighlightedResumePdfPreview(
                pdfService: pdfService,
                previewData: widget.previewData,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('save-optimized-resume-button'),
                  onPressed: _isSaving ? null : _saveResume,
                  child: Text(l10n.save),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedResumePdfPreview extends StatelessWidget {
  const _HighlightedResumePdfPreview({
    required this.pdfService,
    required this.previewData,
  });

  final ResumePdfService pdfService;
  final ResumeOptimizeHighlightData previewData;

  @override
  Widget build(BuildContext context) {
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    final viewerBackground = Theme.of(context).scaffoldBackgroundColor;

    if (isTestBinding) {
      final l10n = context.l10n;
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
            Text(l10n.highlightedSummaryChange),
          if (previewData.highlightedSkills.isNotEmpty)
            Text(
              l10n.highlightedSkillsLabel(
                previewData.highlightedSkills.join(', '),
              ),
            ),
        ],
      );
    }

    return NativePdfPreview(
      key: ValueKey(previewData.afterResume.updatedAt.microsecondsSinceEpoch),
      documentKey:
          '${previewData.afterResume.id}-${previewData.afterResume.updatedAt.microsecondsSinceEpoch}',
      viewerBackground: viewerBackground,
      bytesFuture: pdfService.buildHighlightedResumePdf(
        resume: previewData.afterResume,
        highlightSummary: previewData.highlightSummary,
        highlightedSkills: previewData.highlightedSkills,
        highlightedBulletsByExperience:
            previewData.highlightedBulletsByExperience,
      ),
    );
  }
}
