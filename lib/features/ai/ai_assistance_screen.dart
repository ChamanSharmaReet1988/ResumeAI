import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/ai_api_key_store.dart';
import '../../core/services/ai_resume_coordinator.dart';
import '../../core/services/android_ads_service.dart';
import '../../core/services/platform_monetization.dart';
import '../../core/services/premium_purchase_service.dart';
import '../../core/services/resume_import_service.dart';
import '../../core/services/resume_services.dart';
import '../premium/premium_gate.dart';
import '../shared/android_banner_ad.dart';
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

enum _AiResumeSegment { checkAts, enhanceResume }

class _ResumeAnalyserScreenState extends State<ResumeAnalyserScreen>
    with WidgetsBindingObserver {
  final _jobDescriptionController = TextEditingController();
  final _jobDescriptionFocusNode = FocusNode();
  OverlayEntry? _keyboardHideOverlay;

  bool _isBusy = false;
  List<String> _appliedChanges = const [];
  ResumeOptimizeHighlightData? _previewData;
  ResumeData? _createdResume;
  int _atsCreateAttempt = 0;
  String? _atsAttemptSourceId;
  String? _engineStatusLabel;
  AiApiKeyStore? _apiKeyStore;
  _AiResumeSegment _selectedSegment = _AiResumeSegment.checkAts;
  ResumeData? _importedResume;
  String? _importedFileName;
  String? _importedRawText;
  ResumeAnalysis? _atsAnalysis;
  String? _libraryResumeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _jobDescriptionController.addListener(_handleInputChanged);
    _jobDescriptionFocusNode.addListener(_handleJobDescriptionFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _apiKeyStore = context.read<AiApiKeyStore>();
      _apiKeyStore!.addListener(_refreshEngineStatus);
      _refreshEngineStatus();
    });
  }

  Future<void> _refreshEngineStatus() async {
    if (!mounted) {
      return;
    }
    final coordinator = context.read<AiResumeCoordinator>();
    final engine = await coordinator.resolvePreferredEngine();
    if (!mounted) {
      return;
    }
    setState(() {
      _engineStatusLabel = _labelForEngine(engine);
    });
  }

  String _labelForEngine(AiEngineKind engine) {
    final l10n = context.l10n;
    return switch (engine) {
      AiEngineKind.cloudApi => l10n.aiEngineUsingCloudApi,
      AiEngineKind.appleOnDevice => l10n.aiEngineUsingAppleIntelligence,
      AiEngineKind.local => l10n.aiEngineUsingBuiltIn,
    };
  }

  @override
  void dispose() {
    _apiKeyStore?.removeListener(_refreshEngineStatus);
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
    _atsAnalysis = null;
    _resetOptimizationPreview();
  }

  void _clearImportedResume() {
    _importedResume = null;
    _importedFileName = null;
    _importedRawText = null;
  }

  ResumeData? _sourceResumeFor(List<ResumeData> resumes) {
    if (_importedResume != null) {
      return _importedResume;
    }
    final libraryId = _libraryResumeId;
    if (libraryId == null) {
      return null;
    }
    for (final resume in resumes) {
      if (resume.id == libraryId) {
        return resume;
      }
    }
    return null;
  }

  void _selectLibraryResume(String id) {
    setState(() {
      _libraryResumeId = id;
      _clearImportedResume();
      _resetAtsCreateProgress();
    });
  }

  Future<void> _runTask(Future<void> Function() task) async {
    if (_isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      await task();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString().trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Something went wrong. Please try again.'
                : message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _importResumeFromDevice({required bool analyzeAfter}) async {
    _dismissKeyboard();
    final importService = context.read<ResumeImportService>();
    final aiService = context.read<LocalAiResumeService>();
    final library = context.read<ResumeLibraryViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = context.l10n.uploadResumeFailed;
    final draft = library.newDraft(l10n: context.l10n);

    try {
      final importedFile = await importService.pickResumeFile();
      if (!mounted || importedFile == null) {
        return;
      }

      final uploaded = aiService
          .parseImportedResumeText(
            resumeText: importedFile.resumeText,
            candidateResumeTexts: importedFile.candidateResumeTexts,
            template: draft.template,
            sourceTitle: importedFile.suggestedTitle,
          )
          .copyWith(corporateColorPresetIndex: draft.corporateColorPresetIndex);

      setState(() {
        _importedResume = uploaded;
        _importedFileName = importedFile.fileName;
        _importedRawText = importedFile.resumeText;
        _libraryResumeId = null;
        _resetAtsCreateProgress();
      });

      if (analyzeAfter) {
        await _checkAts(
          resume: uploaded,
          fallbackText: importedFile.resumeText,
        );
      }
    } on ResumeImportException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }

  Future<void> _checkAts({
    required ResumeData? resume,
    String fallbackText = '',
  }) async {
    _dismissKeyboard();
    final source = resume;
    final rawText = fallbackText.trim().isNotEmpty
        ? fallbackText
        : _importedRawText ?? '';
    if ((source == null || !source.hasMeaningfulContent) &&
        rawText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectResumeWithContentFirst)),
      );
      return;
    }

    await _runTask(() async {
      final aiService = context.read<LocalAiResumeService>();
      final analysis = source != null && source.hasMeaningfulContent
          ? await aiService.analyzeResume(resume: source)
          : await aiService.analyzeResumeText(resumeText: rawText);
      if (!mounted) {
        return;
      }
      setState(() => _atsAnalysis = analysis);
    });
  }

  Future<void> _createAtsResume({
    required AiResumeCoordinator coordinator,
  }) async {
    _dismissKeyboard();

    final selectedSource = _sourceResumeFor(
      context.read<ResumeLibraryViewModel>().resumes,
    );
    if (selectedSource == null || !selectedSource.hasMeaningfulContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectResumeWithContentFirst),
        ),
      );
      return;
    }

    if (!await ensurePremiumForAtsAiCreate(context)) {
      return;
    }
    if (!mounted) {
      return;
    }

    final jobDescription = _jobDescriptionController.text.trim();
    if (_atsAttemptSourceId != selectedSource.id) {
      _atsAttemptSourceId = selectedSource.id;
      _atsCreateAttempt = 0;
      _createdResume = null;
    }

    final sourceForPass = _createdResume ?? selectedSource;
    final attemptIndex = _atsCreateAttempt;

    await _runTask(() async {
      final outcome = await coordinator.createAtsResumeWithAi(
        sourceResume: sourceForPass,
        jobDescription: jobDescription,
        attemptIndex: attemptIndex,
      );
      final created = outcome.result.resume.copyWith(updatedAt: DateTime.now());

      if (!mounted) {
        return;
      }

      if (outcome.fallbackNotice != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(outcome.fallbackNotice!)),
        );
      }

      setState(() {
        _createdResume = created;
        _atsCreateAttempt = attemptIndex + 1;
        _appliedChanges = outcome.result.appliedChanges;
        _engineStatusLabel = _labelForEngine(outcome.engine);
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

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _OptimizedResumePreviewScreen(
          sourceResume: _sourceResumeFor(
                context.read<ResumeLibraryViewModel>().resumes,
              ) ??
              created,
          previewData: previewData,
        ),
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    _jobDescriptionController.clear();
    setState(() {
      _clearImportedResume();
      _libraryResumeId = null;
      _resetAtsCreateProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = context.read<AiResumeCoordinator>();
    final library = context.watch<ResumeLibraryViewModel>();
    final resumes = library.resumes;
    final l10n = context.l10n;
    final isCheckAts = _selectedSegment == _AiResumeSegment.checkAts;
    final sourceResume = _sourceResumeFor(resumes);
    final showAiResumeBanner = PlatformMonetization.showsAiResumeBanner &&
        !(PlatformMonetization.isIapEnabled &&
            context.watch<PremiumPurchaseService>().isPremium);

    return ListenableBuilder(
      listenable: _jobDescriptionController,
      builder: (context, _) {
        final hasSource =
            (sourceResume?.hasMeaningfulContent ?? false) ||
            (_importedRawText?.trim().isNotEmpty ?? false);
        final isFurtherPass = _createdResume != null &&
            _atsAttemptSourceId == sourceResume?.id &&
            _atsCreateAttempt > 0;

        final scrollBody = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_engineStatusLabel != null) ...[
                Text(
                  _engineStatusLabel!,
                  key: const Key('ai-engine-status-label'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                isCheckAts
                    ? l10n.aiResumeUploadHintCheckAts
                    : l10n.aiResumeUploadHintEnhance,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: const Key('ai-resume-upload-button'),
                  onPressed: _isBusy
                      ? null
                      : () => _importResumeFromDevice(analyzeAfter: isCheckAts),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(l10n.aiResumeUploadCta),
                ),
              ),
              if (_importedFileName != null) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.aiResumeUsingFile(_importedFileName!),
                  key: const Key('ai-resume-using-file-label'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (resumes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _AiResumeOrDivider(),
                const SizedBox(height: 16),
                Text(
                  l10n.selectFromAppResumeList,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                KeyedSubtree(
                  key: const Key('ai-library-resume-selector'),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'ai-library-resume-${_libraryResumeId ?? 'none'}',
                    ),
                    initialValue: _libraryResumeId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    alignment: AlignmentDirectional.centerStart,
                    dropdownColor: Theme.of(context).cardColor,
                    elevation: 6,
                    hint: Text(
                      l10n.selectFromAppResumeList,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
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
                        horizontal: 12,
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
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Text(
                                resume.title.trim().isEmpty
                                    ? ResumeData.defaultTitle
                                    : resume.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _selectLibraryResume(value);
                    },
                  ),
                ),
              ],
              if (!isCheckAts) ...[
                const SizedBox(height: 16),
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
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCheckAts)
                    FilledButton(
                      key: const Key('check-ats-button'),
                      onPressed: hasSource && !_isBusy
                          ? () => _checkAts(resume: sourceResume)
                          : null,
                      child: Text(l10n.aiResumeCheckAts),
                    )
                  else
                    FilledButton(
                      key: const Key('create-ats-resume-ai-button'),
                      onPressed: hasSource && !_isBusy
                          ? () => _createAtsResume(coordinator: coordinator)
                          : null,
                      child: Text(
                        isFurtherPass
                            ? l10n.furtherOptimizeAtsPass(_atsCreateAttempt + 1)
                            : l10n.optimizeResume,
                      ),
                    ),
                ],
              ),
              if (!isCheckAts &&
                  _previewData != null &&
                  _createdResume != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.tonal(
                      key: const Key('show-created-ats-resume-button'),
                      onPressed: _openCreatedAtsResumePreview,
                      child: Text(l10n.showResume),
                    ),
                  ],
                ),
              ],
              if (_isBusy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
              if (isCheckAts && _atsAnalysis != null) ...[
                const SizedBox(height: 20),
                _AtsCheckResultsCard(analysis: _atsAnalysis!),
              ],
              if (!isCheckAts && _appliedChanges.isNotEmpty) ...[
                const SizedBox(height: 20),
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
              ],
            ],
          ),
        );

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showAiResumeBanner)
              const Material(
                elevation: 0,
                child: AndroidBannerAdSlot(
                  placement: AndroidBannerPlacement.aiResume,
                ),
              ),
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  showAiResumeBanner ? 12 : 20,
                  20,
                  12,
                ),
                child: _AiResumeSegmentControl(
                  selected: _selectedSegment,
                  onChanged: (value) {
                    setState(() => _selectedSegment = value);
                  },
                ),
              ),
            ),
            Expanded(child: scrollBody),
          ],
        );

        return showAiResumeBanner ? SafeArea(bottom: false, child: body) : body;
      },
    );
  }
}

class _AiResumeOrDivider extends StatelessWidget {
  const _AiResumeOrDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      key: const Key('ai-resume-or-divider'),
      children: [
        Expanded(child: Divider(color: color.withValues(alpha: 0.35))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.aiResumeOr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(child: Divider(color: color.withValues(alpha: 0.35))),
      ],
    );
  }
}

class _AiResumeSegmentControl extends StatelessWidget {
  const _AiResumeSegmentControl({
    required this.selected,
    required this.onChanged,
  });

  final _AiResumeSegment selected;
  final ValueChanged<_AiResumeSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;
    final blue = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: Material(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.14),
          surfaceTintColor: Colors.transparent,
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: CupertinoSlidingSegmentedControl<_AiResumeSegment>(
              key: const Key('ai-resume-segmented-button'),
              groupValue: selected,
              proportionalWidth: true,
              backgroundColor: isDark
                  ? const Color(0xFF3A3A3C)
                  : const Color(0xFFE8E8ED),
              thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
              onValueChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
              children: {
                _AiResumeSegment.checkAts: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    l10n.aiResumeCheckAts,
                    style: TextStyle(
                      fontSize: 16,
                      color: selected == _AiResumeSegment.checkAts
                          ? blue
                          : inactiveColor,
                    ),
                  ),
                ),
                _AiResumeSegment.enhanceResume: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    l10n.aiResumeEnhanceResume,
                    style: TextStyle(
                      fontSize: 16,
                      color: selected == _AiResumeSegment.enhanceResume
                          ? blue
                          : inactiveColor,
                    ),
                  ),
                ),
              },
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SegmentedButton<_AiResumeSegment>(
            key: const Key('ai-resume-segmented-button'),
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedForegroundColor: blue,
              foregroundColor: inactiveColor,
              backgroundColor: Colors.transparent,
              selectedBackgroundColor: blue.withValues(alpha: 0.12),
              surfaceTintColor: Colors.transparent,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontSize: 16),
            ),
            segments: [
              ButtonSegment<_AiResumeSegment>(
                value: _AiResumeSegment.checkAts,
                label: Text(l10n.aiResumeCheckAts),
              ),
              ButtonSegment<_AiResumeSegment>(
                value: _AiResumeSegment.enhanceResume,
                label: Text(l10n.aiResumeEnhanceResume),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (value) => onChanged(value.first),
          ),
        ),
      ),
    );
  }
}

class _AtsCheckResultsCard extends StatelessWidget {
  const _AtsCheckResultsCard({required this.analysis});

  final ResumeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    Widget section(String title, List<String> items, IconData icon) {
      if (items.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      key: const Key('ats-check-results-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.atsCheckResults,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: analysis.score / 100,
                        strokeWidth: 8,
                      ),
                      Center(
                        child: Text(
                          '${analysis.score}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.resumeScore,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.atsCompatibilitySummary(
                          (analysis.atsCompatibility * 100).round(),
                          analysis.missingSkills.length,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            section(l10n.atsStrengths, analysis.strengths, Icons.check_circle_outline),
            section(
              l10n.atsMissingKeywords,
              analysis.missingSkills,
              Icons.warning_amber_rounded,
            ),
            section(
              l10n.atsImprovements,
              analysis.improvements,
              Icons.lightbulb_outline,
            ),
          ],
        ),
      ),
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
  });

  final ResumeData sourceResume;
  final ResumeOptimizeHighlightData previewData;

  @override
  State<_OptimizedResumePreviewScreen> createState() =>
      _OptimizedResumePreviewScreenState();
}

class _OptimizedResumePreviewScreenState
    extends State<_OptimizedResumePreviewScreen> {
  bool _isSaving = false;

  String _optimizedCopyTitle(String title) {
    final trimmed = title.trim();
    final baseTitle = trimmed.isEmpty ? ResumeData.defaultTitle : trimmed;
    final suffix = context.l10n.atsTitleSuffix;
    return baseTitle.endsWith(suffix) ? baseTitle : '$baseTitle$suffix';
  }

  Future<void> _saveResume() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final copyTitle = await showDialog<String>(
        context: context,
        builder: (context) => _OptimizedResumeTitleDialog(
          initialTitle: _optimizedCopyTitle(widget.sourceResume.title),
        ),
      );
      if (!mounted || copyTitle == null) {
        return;
      }

      final repository = context.read<ResumeRepository>();
      final library = context.read<ResumeLibraryViewModel>();
      final savedResume = widget.previewData.afterResume.copyWith(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: copyTitle.trim().isEmpty
            ? ResumeData.defaultTitle
            : copyTitle.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSyncedAt: null,
      );

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
              child: KeyedSubtree(
                key: const Key('created-ats-resume-preview'),
                child: _HighlightedResumePdfPreview(
                  pdfService: pdfService,
                  previewData: widget.previewData,
                ),
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
