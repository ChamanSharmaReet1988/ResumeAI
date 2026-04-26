import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/resume_services.dart';
import '../ai/ai_assistance_screen.dart';
import '../builder/resume_builder_screen.dart';
import '../builder/resume_preview_screen.dart';
import '../cover_letters/cover_letter_content_screen.dart';
import '../cover_letters/cover_letter_editor_screen.dart';
import '../cover_letters/cover_letter_preview_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../shared/view_models.dart';
import '../templates/templates_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  HomeSegment _homeSegment = HomeSegment.resumes;

  bool get _isCupertino =>
      Platform.isIOS || Theme.of(context).platform == TargetPlatform.iOS;

  void _selectTab(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() => _currentIndex = index);
  }

  Future<void> _openBuilder({ResumeData? seed}) async {
    final repository = context.read<ResumeRepository>();
    final aiService = context.read<LocalAiResumeService>();
    final pdfService = context.read<ResumePdfService>();
    final library = context.read<ResumeLibraryViewModel>();
    final viewModel = ResumeEditorViewModel(
      repository: repository,
      aiService: aiService,
      pdfService: pdfService,
      seedResume: seed ?? library.newDraft(),
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

    await library.loadResumes();
  }

  Future<void> _createResumeFromAddButton() async {
    final library = context.read<ResumeLibraryViewModel>();
    final enteredTitle = await _promptForResumeTitle();

    if (!mounted || enteredTitle == null) {
      return;
    }

    final normalizedTitle = enteredTitle.trim();
    final draft = library.newDraft().copyWith(
      title: normalizedTitle.isEmpty
          ? ResumeData.defaultTitle
          : normalizedTitle,
    );

    await context.read<ResumeRepository>().upsertResume(draft);
    await _openBuilder(seed: draft);
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
    await _openCoverLetterEditor(seed: draft);
  }

  Future<String?> _promptForCoverLetterTitle() async {
    return showDialog<String>(
      context: context,
      builder: (context) => const _CoverLetterTitleDialog(),
    );
  }

  Future<void> _openPreview({required ResumeData seed}) async {
    final repository = context.read<ResumeRepository>();
    final aiService = context.read<LocalAiResumeService>();
    final pdfService = context.read<ResumePdfService>();
    final library = context.read<ResumeLibraryViewModel>();
    final viewModel = ResumeEditorViewModel(
      repository: repository,
      aiService: aiService,
      pdfService: pdfService,
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

  Future<void> _openCoverLetterEditor({CoverLetterData? seed}) async {
    final library = context.read<CoverLetterLibraryViewModel>();
    final viewModel = _buildCoverLetterViewModel(
      seed: seed ?? library.newDraft(),
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChangeNotifierProvider<CoverLetterEditorViewModel>.value(
              value: viewModel,
              child: const CoverLetterEditorScreen(),
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await library.loadCoverLetters();
  }

  Future<void> _openCoverLetterContent({required CoverLetterData seed}) async {
    final library = context.read<CoverLetterLibraryViewModel>();
    final viewModel = _buildCoverLetterViewModel(seed: seed);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChangeNotifierProvider<CoverLetterEditorViewModel>.value(
              value: viewModel,
              child: const CoverLetterContentScreen(),
            ),
      ),
    );

    if (!mounted) {
      return;
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

  Widget? _buildFloatingActionButton() {
    if (_currentIndex != 0) {
      return null;
    }

    final isResumeSegment = _homeSegment == HomeSegment.resumes;
    final primaryBlue = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        backgroundColor: Theme.of(context).cardColor,
        shape: const CircleBorder(),
        onPressed: isResumeSegment
            ? _createResumeFromAddButton
            : _createCoverLetterFromAddButton,
        child: Icon(
          isResumeSegment ? Icons.add_card_rounded : Icons.note_add_rounded,
          color: primaryBlue,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final activeDestination = destinations[_currentIndex];
    final pages = [
      HomeScreen(
        currentSegment: _homeSegment,
        onSegmentChanged: (value) => setState(() => _homeSegment = value),
        onOpenResume: (resume) => _openBuilder(seed: resume),
        onPreviewResume: (resume) => _openPreview(seed: resume),
        onPreviewCoverLetter: (coverLetter) =>
            _openCoverLetterPreview(seed: coverLetter),
        onEditCoverLetter: (coverLetter) =>
            _openCoverLetterContent(seed: coverLetter),
      ),
      TemplatesScreen(onCreateResume: () => _openBuilder()),
      ResumeAnalyserScreen(onOpenResumeBuilder: () => _openBuilder()),
      const SettingsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final content = IndexedStack(index: _currentIndex, children: pages);

        if (isWide) {
          return Scaffold(
            floatingActionButton: _buildFloatingActionButton(),
            body: SafeArea(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    child: Card(
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
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          floatingActionButton: _buildFloatingActionButton(),
          body: _isCupertino
              ? CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text(activeDestination.label),
                    transitionBetweenRoutes: false,
                    backgroundColor: Theme.of(
                      context,
                    ).cupertinoOverrideTheme?.barBackgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  child: content,
                )
              : SafeArea(bottom: false, child: content),
          bottomNavigationBar: _isCupertino
              ? CupertinoTheme(
                  data: CupertinoTheme.of(context).copyWith(
                    textTheme: CupertinoTheme.of(context).textTheme.copyWith(
                      tabLabelTextStyle: CupertinoTheme.of(context)
                          .textTheme
                          .tabLabelTextStyle
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.18),
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
        );
      },
    );
  }

  List<_ShellDestination> get _destinations {
    if (_isCupertino) {
      return const [
        _ShellDestination(
          label: 'Home',
          icon: CupertinoIcons.house,
          selectedIcon: CupertinoIcons.house_fill,
        ),
        _ShellDestination(
          label: 'Templates',
          icon: CupertinoIcons.rectangle_stack,
          selectedIcon: CupertinoIcons.rectangle_stack_fill,
        ),
        _ShellDestination(
          label: 'Analyser',
          icon: CupertinoIcons.chart_bar,
          selectedIcon: CupertinoIcons.chart_bar_fill,
        ),
        _ShellDestination(
          label: 'Settings',
          icon: CupertinoIcons.settings,
          selectedIcon: CupertinoIcons.settings_solid,
        ),
      ];
    }

    return const [
      _ShellDestination(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      _ShellDestination(
        label: 'Templates',
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize_rounded,
      ),
      _ShellDestination(
        label: 'Analyser',
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics_rounded,
      ),
      _ShellDestination(
        label: 'Settings',
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
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: const Text('Resume title'),
      content: TextField(
        key: const Key('resume-title-dialog-field'),
        controller: _controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Resume title'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Create'),
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
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: const Text('Cover letter title'),
      content: TextField(
        key: const Key('cover-letter-title-dialog-field'),
        controller: _controller,
        textCapitalization: TextCapitalization.words,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Cover letter title',
          hintText: 'Product Designer Application',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Create'),
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
