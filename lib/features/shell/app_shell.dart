import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/app_localizations.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import 'dart:async';

import '../../core/models/resume_models.dart';
import '../../core/services/analytics_events.dart';
import '../../core/services/android_ads_service.dart';
import '../../core/services/android_genai_service.dart';
import '../../core/services/deep_link_service.dart';
import '../../core/services/in_app_review_prompt_service.dart';
import '../../core/services/platform_monetization.dart';
import '../../core/services/premium_access.dart';
import '../../core/services/premium_purchase_service.dart';
import '../../core/services/resume_import_service.dart';
import '../../core/services/resume_services.dart';
import '../ai/ai_assistance_screen.dart';
import '../builder/resume_builder_screen.dart';
import '../builder/resume_preview_screen.dart';
import '../cover_letters/cover_letter_content_screen.dart';
import '../cover_letters/cover_letter_editor_screen.dart';
import '../cover_letters/cover_letter_preview_screen.dart';
import '../home/home_screen.dart';
import '../premium/premium_gate.dart';
import '../settings/settings_screen.dart';
import '../shared/upload_feedback_dialog.dart';
import '../shared/view_models.dart';
import '../templates/templates_screen.dart';
import 'app_shell_scope.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  HomeSegment _homeSegment = HomeSegment.resumes;
  StreamSubscription<DeepLinkDestination>? _deepLinkSubscription;
  bool _deepLinkListenerAttached = false;
  bool _recordedLaunchHomeVisit = false;

  bool get _isCupertino =>
      Platform.isIOS || Theme.of(context).platform == TargetPlatform.iOS;

  static const int _aiResumeTabIndex = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recordedLaunchHomeVisit) {
      _recordedLaunchHomeVisit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_onHomeBecameVisible(countVisit: true));
      });
    }
    _attachDeepLinkListenerIfNeeded();
  }

  void _attachDeepLinkListenerIfNeeded() {
    if (_deepLinkListenerAttached) {
      return;
    }
    final deepLinks = context.read<DeepLinkService>();
    _deepLinkListenerAttached = true;
    final pending = deepLinks.takePendingDestination();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_openDeepLinkDestination(pending));
        }
      });
    }
    _deepLinkSubscription = deepLinks.destinations.listen((destination) {
      unawaited(_openDeepLinkDestination(destination));
    });
  }

  Future<void> _openDeepLinkDestination(DeepLinkDestination destination) async {
    if (!mounted) {
      return;
    }
    switch (destination) {
      case DeepLinkDestination.templates:
        await _selectTab(AppShellScope.templatesTabIndex);
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onHomeBecameVisible({required bool countVisit}) async {
    if (!mounted) {
      return;
    }
    final review = context.read<InAppReviewPromptService>();
    review.onArrivedAtHome();
    if (countVisit) {
      await review.recordHomeVisit();
    }
  }

  Future<void> _selectTab(int index) async {
    if (index == _currentIndex) {
      return;
    }

    unawaited(
      logAnalyticsEvent(
        context,
        AnalyticsEvents.tabSelected,
        parameters: shellTabAnalytics(index),
      ),
    );

    // iOS: AI Resume is Pro — open Go Premium instead of the tab when locked.
    if (index == _aiResumeTabIndex &&
        PremiumAccess.atsAiCreateRequiresPremium) {
      final allowed = await ensurePremiumForAtsAiCreate(context);
      if (!allowed || !mounted) {
        return;
      }
    }

    setState(() => _currentIndex = index);

    if (index == 0) {
      unawaited(_onHomeBecameVisible(countVisit: true));
    }
  }

  void _goToHomeResumeTab() {
    setState(() {
      _currentIndex = 0;
      _homeSegment = HomeSegment.resumes;
    });
    context.read<InAppReviewPromptService>().onArrivedAtHome();
  }

  void _goToHomeCoverLetterTab() {
    setState(() {
      _currentIndex = 0;
      _homeSegment = HomeSegment.coverLetters;
    });
    context.read<InAppReviewPromptService>().onArrivedAtHome();
  }

  String _activeHeaderTitle(AppLocalizations l10n) {
    return switch (_currentIndex) {
      2 => l10n.tabAiResume,
      _ => _destinations(l10n)[_currentIndex].label,
    };
  }

  Future<void> _openBuilder({
    ResumeData? seed,
    bool backPopsToHome = false,
  }) async {
    final repository = context.read<ResumeRepository>();
    final aiService = context.read<LocalAiResumeService>();
    final pdfService = context.read<ResumePdfService>();
    final library = context.read<ResumeLibraryViewModel>();
    final viewModel = ResumeEditorViewModel(
      repository: repository,
      aiService: aiService,
      pdfService: pdfService,
      androidAi: context.read<AndroidGenAiService>(),
      seedResume: seed ?? library.newDraft(l10n: context.l10n),
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<ResumeEditorViewModel>.value(
          value: viewModel,
          child: const ResumeBuilderScreen(),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (backPopsToHome) {
      _goToHomeResumeTab();
    }

    await library.loadResumes();
  }

  Future<void> _createResumeFromAddButton() async {
    final library = context.read<ResumeLibraryViewModel>();
    final enteredTitle = await _promptForResumeTitle();

    if (!mounted || enteredTitle == null) {
      return;
    }

    final normalizedTitle = enteredTitle.trim();
    final draft = library.newDraft(l10n: context.l10n).copyWith(
      title: normalizedTitle.isEmpty
          ? ResumeData.defaultTitle
          : normalizedTitle,
    );

    await context.read<ResumeRepository>().upsertResume(draft);
    if (!mounted) {
      return;
    }
    await logAnalyticsEvent(
      context,
      AnalyticsEvents.resumeCreated,
      parameters: {
        ...resumeTemplateAnalytics(draft.template.userFacingTemplate),
        'source': 'home_add',
      },
    );
    await _openBuilder(seed: draft);
  }

  /// Picks a PDF, DOCX, or TXT resume, fills in every section it can read,
  /// saves it as a new resume, and opens the builder so the user can review.
  Future<void> _uploadResume() async {
    final importService = context.read<ResumeImportService>();
    final library = context.read<ResumeLibraryViewModel>();
    final repository = context.read<ResumeRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final failedMessage = context.l10n.uploadResumeFailed;
    final processingMessage = context.l10n.uploadResumeProcessing;
    final draft = library.newDraft(l10n: context.l10n);

    var loadingShown = false;
    final loadingClock = Stopwatch();
    // Long enough to be read, so a fast import does not just flicker.
    const minimumLoadingTime = Duration(milliseconds: 700);

    Future<void> hideLoading({bool holdForMinimum = false}) async {
      if (!loadingShown) {
        return;
      }
      if (holdForMinimum) {
        final remaining = minimumLoadingTime - loadingClock.elapsed;
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
      }
      if (navigator.mounted) {
        navigator.pop();
      }
      loadingShown = false;
    }

    final ResumeData uploaded;
    try {
      final importedFile = await importService.pickResumeFile(
        // Reading and parsing a resume takes a moment; show that something is
        // happening from the point the file is chosen.
        onFilePicked: () async {
          if (!mounted) {
            return;
          }
          loadingShown = true;
          loadingClock.start();
          unawaited(
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              useRootNavigator: true,
              builder: (_) => PopScope(
                canPop: false,
                child: AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(width: 20),
                      Flexible(child: Text(processingMessage)),
                    ],
                  ),
                ),
              ),
            ),
          );
          // Wait for the dialog to finish fading in, so it is actually on
          // screen before the import starts.
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
      );
      if (!mounted || importedFile == null) {
        await hideLoading();
        return;
      }
      final parsed = await importService.parseInBackground(
        importedFile,
        template: draft.template,
      );
      uploaded = parsed.copyWith(
        corporateColorPresetIndex: draft.corporateColorPresetIndex,
      );
      await repository.upsertResume(uploaded);
    } on ResumeImportException catch (error) {
      await hideLoading();
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } catch (_) {
      await hideLoading();
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
      return;
    }

    await hideLoading(holdForMinimum: true);
    if (!mounted) {
      return;
    }
    await logAnalyticsEvent(
      context,
      AnalyticsEvents.resumeCreated,
      parameters: {
        ...resumeTemplateAnalytics(uploaded.template.userFacingTemplate),
        'source': 'home_upload',
      },
    );
    await _openBuilder(seed: uploaded);
    await _askUploadFeedback(uploaded);
  }

  /// Back on Home after reviewing an uploaded resume, ask how the upload went
  /// and report the answer. Dismissing without answering logs nothing.
  Future<void> _askUploadFeedback(ResumeData uploaded) async {
    if (!mounted) {
      return;
    }
    final good = await showUploadFeedbackDialog(context);
    if (!mounted || good == null) {
      return;
    }
    await logAnalyticsEvent(
      context,
      good ? AnalyticsEvents.resumeUploadGood : AnalyticsEvents.resumeUploadBad,
      parameters: {
        ...resumeTemplateAnalytics(uploaded.template.userFacingTemplate),
        'source': 'home_upload',
      },
    );
  }

  Future<void> _createResumeFromTemplatesTab() async {
    final library = context.read<ResumeLibraryViewModel>();
    final draft = library.newDraft(l10n: context.l10n);
    await logAnalyticsEvent(
      context,
      AnalyticsEvents.resumeCreated,
      parameters: {
        ...resumeTemplateAnalytics(draft.template.userFacingTemplate),
        'source': 'templates_tab',
      },
    );
    await _openBuilder(seed: draft, backPopsToHome: true);
  }

  Future<String?> _promptForResumeTitle({String initialTitle = ''}) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _ResumeTitleDialog(initialTitle: initialTitle),
    );
  }

  Future<void> _createCoverLetterFromAddButton() async {
    final library = context.read<CoverLetterLibraryViewModel>();
    final enteredTitle = await _promptForCoverLetterTitle();

    if (!mounted || enteredTitle == null) {
      return;
    }

    final draft = library.newDraft().copyWith(title: enteredTitle.trim());
    await _openCoverLetterEditor(seed: draft, backPopsToHome: true);
  }

  Future<String?> _promptForCoverLetterTitle() async {
    return showDialog<String>(
      context: context,
      builder: (context) => const _CoverLetterTitleDialog(),
    );
  }

  Future<void> _openPreview({required ResumeData seed}) async {
    await AndroidAdsService.showInterstitialIfReady(
      placement: AndroidAdPlacement.preview,
    );
    if (!mounted) {
      return;
    }
    final repository = context.read<ResumeRepository>();
    final aiService = context.read<LocalAiResumeService>();
    final pdfService = context.read<ResumePdfService>();
    final library = context.read<ResumeLibraryViewModel>();
    final viewModel = ResumeEditorViewModel(
      repository: repository,
      aiService: aiService,
      pdfService: pdfService,
      androidAi: context.read<AndroidGenAiService>(),
      seedResume: seed,
    );

    final targetStep = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => ChangeNotifierProvider<ResumeEditorViewModel>.value(
          value: viewModel,
          child: const ResumePreviewScreen(backPopsToHome: true),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (targetStep != null) {
      viewModel.setStep(targetStep);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<ResumeEditorViewModel>.value(
            value: viewModel,
            child: const ResumeBuilderScreen(),
          ),
        ),
      );

      if (!mounted) {
        return;
      }
    }

    await library.loadResumes();
  }

  Future<void> _openCoverLetterEditor({
    CoverLetterData? seed,
    bool backPopsToHome = false,
  }) async {
    final library = context.read<CoverLetterLibraryViewModel>();
    final viewModel = _buildCoverLetterViewModel(
      seed: seed ?? library.newDraft(),
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChangeNotifierProvider<CoverLetterEditorViewModel>.value(
              value: viewModel,
              child: CoverLetterEditorScreen(backPopsToHome: backPopsToHome),
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (backPopsToHome) {
      _goToHomeCoverLetterTab();
    }

    await library.loadCoverLetters();
  }

  Future<void> _openCoverLetterContent({
    required CoverLetterData seed,
    bool backPopsToHome = false,
  }) async {
    final library = context.read<CoverLetterLibraryViewModel>();
    final viewModel = _buildCoverLetterViewModel(seed: seed);

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ChangeNotifierProvider<CoverLetterEditorViewModel>.value(
              value: viewModel,
              child: CoverLetterContentScreen(backPopsToHome: backPopsToHome),
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (backPopsToHome) {
      _goToHomeCoverLetterTab();
    }

    await library.loadCoverLetters();
  }

  Future<void> _openCoverLetterPreview({required CoverLetterData seed}) async {
    final library = context.read<CoverLetterLibraryViewModel>();
    final viewModel = _buildCoverLetterViewModel(seed: seed);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChangeNotifierProvider<CoverLetterEditorViewModel>.value(
              value: viewModel,
              child: const CoverLetterPreviewScreen(),
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await library.loadCoverLetters();
  }

  CoverLetterEditorViewModel _buildCoverLetterViewModel({
    required CoverLetterData seed,
  }) {
    final repository = context.read<ResumeRepository>();
    final aiService = context.read<LocalAiResumeService>();
    final resumeLibrary = context.read<ResumeLibraryViewModel>();
    return CoverLetterEditorViewModel(
      repository: repository,
      aiService: aiService,
      resumeContext: resumeLibrary.selectedResume,
      seedCoverLetter: seed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = _destinations(l10n);
    final pages = [
      HomeScreen(
        currentSegment: _homeSegment,
        onSegmentChanged: (value) => setState(() => _homeSegment = value),
        onPreviewResume: (resume) => _openPreview(seed: resume),
        onOpenResume: (resume) => _openBuilder(seed: resume),
        onPreviewCoverLetter: (coverLetter) =>
            _openCoverLetterPreview(seed: coverLetter),
        onEditCoverLetter: (coverLetter) => _openCoverLetterContent(
          seed: coverLetter,
          backPopsToHome: true,
        ),
        onCreateResume: _createResumeFromAddButton,
        onUploadResume: _uploadResume,
        onCreateCoverLetter: _createCoverLetterFromAddButton,
      ),
      TemplatesScreen(onCreateResume: _createResumeFromTemplatesTab),
      ResumeAnalyserScreen(
        onOpenResumeBuilder: () => _openBuilder(),
        onGoToHomeTab: _goToHomeResumeTab,
      ),
      const SettingsScreen(),
    ];

    return AppShellScope(
      selectTab: _selectTab,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final content = IndexedStack(index: _currentIndex, children: pages);

          if (isWide) {
            return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: NavigationRail(
                          selectedIndex: _currentIndex,
                          useIndicator: true,
                          onDestinationSelected: _selectTab,
                          labelType: NavigationRailLabelType.all,
                          destinations: destinations
                              .map(
                                (item) => NavigationRailDestination(
                                  icon: Icon(item.icon),
                                  selectedIcon: Icon(item.selectedIcon),
                                  label: Text(item.label),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }

        final premiumHidesAds = PlatformMonetization.isIapEnabled &&
            context.watch<PremiumPurchaseService>().isPremium;
        final hideNavForBanner = !premiumHidesAds &&
            ((_currentIndex == 0 && PlatformMonetization.showsHomeBanner) ||
                (_currentIndex == AppShellScope.templatesTabIndex &&
                    PlatformMonetization.showsAds) ||
                (_currentIndex == AppShellScope.settingsTabIndex &&
                    PlatformMonetization.showsSettingsBanner));

        return Scaffold(
          body: _isCupertino
              ? CupertinoPageScaffold(
                  navigationBar: hideNavForBanner
                      ? null
                      : CupertinoNavigationBar(
                          middle: Text(_activeHeaderTitle(l10n)),
                          transitionBetweenRoutes: false,
                          backgroundColor: Theme.of(
                            context,
                          ).cupertinoOverrideTheme?.barBackgroundColor,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                        ),
                  child: content,
                )
              : SafeArea(bottom: false, child: content),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: _isCupertino
                ? CupertinoTheme(
                    data: CupertinoTheme.of(context).copyWith(
                      textTheme: CupertinoTheme.of(context).textTheme.copyWith(
                        tabLabelTextStyle: CupertinoTheme.of(context)
                            .textTheme
                            .tabLabelTextStyle
                            .copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    child: CupertinoTabBar(
                      height: 64,
                      iconSize: 24,
                      currentIndex: _currentIndex,
                      onTap: _selectTab,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: CupertinoColors.systemGrey,
                      backgroundColor: Theme.of(
                        context,
                      ).cardColor.withValues(alpha: 0.96),
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.18),
                        ),
                      ),
                      items: destinations
                          .map(
                            (item) => BottomNavigationBarItem(
                              icon: Icon(item.icon),
                              activeIcon: Icon(item.selectedIcon),
                              label: item.label,
                            ),
                          )
                          .toList(),
                    ),
                  )
                : NavigationBar(
                    selectedIndex: _currentIndex,
                    destinations: destinations
                        .map(
                          (item) => NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: item.label,
                          ),
                        )
                        .toList(),
                    onDestinationSelected: _selectTab,
                  ),
          ),
          );
        },
      ),
    );
  }

  List<_ShellDestination> _destinations(AppLocalizations l10n) {
    if (_isCupertino) {
      return [
        _ShellDestination(
          label: l10n.tabHome,
          icon: CupertinoIcons.house,
          selectedIcon: CupertinoIcons.house_fill,
        ),
        _ShellDestination(
          label: l10n.tabTemplates,
          icon: CupertinoIcons.rectangle_stack,
          selectedIcon: CupertinoIcons.rectangle_stack_fill,
        ),
        _ShellDestination(
          label: l10n.tabAiResume,
          icon: CupertinoIcons.sparkles,
          selectedIcon: CupertinoIcons.sparkles,
        ),
        _ShellDestination(
          label: l10n.tabSettings,
          icon: CupertinoIcons.settings,
          selectedIcon: CupertinoIcons.settings_solid,
        ),
      ];
    }

    return [
      _ShellDestination(
        label: l10n.tabHome,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      _ShellDestination(
        label: l10n.tabTemplates,
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize_rounded,
      ),
        _ShellDestination(
          label: l10n.tabAiResume,
          icon: Icons.auto_awesome_outlined,
          selectedIcon: Icons.auto_awesome_rounded,
        ),
      _ShellDestination(
        label: l10n.tabSettings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
      ),
    ];
  }
}

class _ResumeTitleDialog extends StatefulWidget {
  const _ResumeTitleDialog({this.initialTitle = ''});

  final String initialTitle;

  @override
  State<_ResumeTitleDialog> createState() => _ResumeTitleDialogState();
}

class _ResumeTitleDialogState extends State<_ResumeTitleDialog> {
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
        key: const Key('resume-title-dialog-field'),
        controller: _controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: l10n.resumeTitle),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.create),
        ),
      ],
    );
  }
}

class _CoverLetterTitleDialog extends StatefulWidget {
  const _CoverLetterTitleDialog();

  @override
  State<_CoverLetterTitleDialog> createState() =>
      _CoverLetterTitleDialogState();
}

class _CoverLetterTitleDialogState extends State<_CoverLetterTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(l10n.coverLetterTitle),
      content: TextField(
        key: const Key('cover-letter-title-dialog-field'),
        controller: _controller,
        textCapitalization: TextCapitalization.words,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.coverLetterTitle),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.create),
        ),
      ],
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
