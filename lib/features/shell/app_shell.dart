import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/resume_services.dart';
import '../ai/ai_assistance_screen.dart';
import '../builder/resume_builder_screen.dart';
import '../cover_letters/cover_letter_editor_screen.dart';
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

  Future<void> _openCoverLetterEditor({CoverLetterData? seed}) async {
    final repository = context.read<ResumeRepository>();
    final library = context.read<CoverLetterLibraryViewModel>();
    final viewModel = CoverLetterEditorViewModel(
      repository: repository,
      seedCoverLetter: seed ?? library.newDraft(),
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

  Widget? _buildFloatingActionButton() {
    if (_currentIndex != 0) {
      return null;
    }

    final isResumeSegment = _homeSegment == HomeSegment.resumes;
    final primaryBlue = Theme.of(context).colorScheme.primary;

    return FloatingActionButton.extended(
      backgroundColor: Colors.white,
      onPressed: isResumeSegment
          ? () => _openBuilder()
          : () => _openCoverLetterEditor(),
      icon: Icon(
        isResumeSegment ? Icons.add_card_rounded : Icons.note_add_rounded,
        color: primaryBlue,
      ),
      label: Text(
        isResumeSegment ? 'Add Resume' : 'Add Cover Letter',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
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
        onOpenCoverLetter: (coverLetter) =>
            _openCoverLetterEditor(seed: coverLetter),
      ),
      TemplatesScreen(onCreateResume: () => _openBuilder()),
      AiAssistanceScreen(onOpenResumeBuilder: () => _openBuilder()),
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
          label: 'AI',
          icon: CupertinoIcons.sparkles,
          selectedIcon: CupertinoIcons.sparkles,
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
        label: 'AI',
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome_rounded,
      ),
      _ShellDestination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
      ),
    ];
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
