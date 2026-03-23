import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../shared/resume_preview_card.dart';
import '../shared/view_models.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final _skillController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _coverLetterCompanyController = TextEditingController();
  final _coverLetterRoleController = TextEditingController();
  final _summaryFocusNode = FocusNode();
  final _stepScrollController = ScrollController();
  final Map<String, FocusNode> _extendedKeyboardHideFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _summaryFocusNode.addListener(_handleSummaryFocusChange);
  }

  void _handleSummaryFocusChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleExtendedKeyboardHideFocusChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  FocusNode _focusNodeForExtendedKeyboardField(String key) {
    return _extendedKeyboardHideFocusNodes.putIfAbsent(key, () {
      final node = FocusNode();
      node.addListener(_handleExtendedKeyboardHideFocusChange);
      return node;
    });
  }

  bool get _isExtendedKeyboardHideFieldFocused =>
      _extendedKeyboardHideFocusNodes.values.any((node) => node.hasFocus);

  @override
  void dispose() {
    _skillController.dispose();
    _jobDescriptionController.dispose();
    _coverLetterCompanyController.dispose();
    _coverLetterRoleController.dispose();
    _stepScrollController.dispose();
    _summaryFocusNode
      ..removeListener(_handleSummaryFocusChange)
      ..dispose();
    for (final node in _extendedKeyboardHideFocusNodes.values) {
      node
        ..removeListener(_handleExtendedKeyboardHideFocusChange)
        ..dispose();
    }
    super.dispose();
  }

  Future<void> _saveResume() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    await viewModel.saveResume();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
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

  Future<void> _generateSummary() async {
    await context.read<ResumeEditorViewModel>().generateSummary();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI summary added to the resume.')),
    );
  }

  Future<void> _suggestSkills() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    final previousCount = viewModel.resume.skills.length;
    await viewModel.suggestSkills();
    if (!mounted) {
      return;
    }

    final addedCount =
        context.read<ResumeEditorViewModel>().resume.skills.length -
        previousCount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          addedCount > 0
              ? 'AI added $addedCount skill${addedCount == 1 ? '' : 's'} to the draft.'
              : 'You already have the maximum 50 skills.',
        ),
      ),
    );
  }

  void _addSkillFromInput() {
    final viewModel = context.read<ResumeEditorViewModel>();
    final rawValue = _skillController.text;
    final wasAtLimit = viewModel.hasReachedSkillLimit;
    final added = viewModel.addSkill(rawValue);

    if (added) {
      _skillController.clear();
      return;
    }

    if (wasAtLimit && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 50 skills.')),
      );
    }
  }

  Future<void> _analyzeResume() async {
    await context.read<ResumeEditorViewModel>().analyzeResume(
      jobDescription: _jobDescriptionController.text,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Resume analysis refreshed.')));
  }

  Future<void> _analyzeJobDescription() async {
    await context.read<ResumeEditorViewModel>().analyzeJobDescription(
      _jobDescriptionController.text,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Job description insights updated.')),
    );
  }

  Future<void> _generateCoverLetter() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    await viewModel.generateCoverLetter(
      company: _coverLetterCompanyController.text.ifBlank('the company'),
      role: _coverLetterRoleController.text.ifBlank(
        viewModel.resume.jobTitle.ifBlank('the role'),
      ),
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cover letter drafted.')));
  }

  Future<void> _generateBullets(int index) async {
    try {
      await context.read<ResumeEditorViewModel>().generateBullets(index);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI bullets added to the experience.')),
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'resume builder',
          context: ErrorDescription('while generating work experience bullets'),
        ),
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to generate bullets right now. Please try again.',
          ),
        ),
      );
    }
  }

  ButtonStyle _mediumTonalButtonStyle(BuildContext context) {
    return FilledButton.styleFrom(
      textStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  String _resumeOrderLabel(int index) {
    if (index == 0) {
      return 'Appears first on your resume';
    }

    return 'Appears ${_ordinal(index + 1)} on your resume';
  }

  String _ordinal(int value) {
    final mod100 = value % 100;
    if (mod100 >= 11 && mod100 <= 13) {
      return '${value}th';
    }

    return switch (value % 10) {
      1 => '${value}st',
      2 => '${value}nd',
      3 => '${value}rd',
      _ => '${value}th',
    };
  }

  Future<void> _pickWorkDate({
    required int index,
    required bool isEndDate,
    required String currentValue,
  }) async {
    FocusScope.of(context).unfocus();

    if (isEndDate) {
      final selection = await showModalBottomSheet<_EndDateSelection>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Choose month and year'),
                  onTap: () =>
                      Navigator.of(context).pop(_EndDateSelection.chooseDate),
                ),
                ListTile(
                  leading: const Icon(Icons.work_history_outlined),
                  title: const Text('Present'),
                  onTap: () =>
                      Navigator.of(context).pop(_EndDateSelection.present),
                ),
                if (currentValue.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.clear_rounded),
                    title: const Text('Clear date'),
                    onTap: () =>
                        Navigator.of(context).pop(_EndDateSelection.clear),
                  ),
              ],
            ),
          );
        },
      );

      if (!mounted || selection == null) {
        return;
      }

      switch (selection) {
        case _EndDateSelection.present:
          _updateWorkDate(index: index, isEndDate: true, value: 'Present');
          return;
        case _EndDateSelection.clear:
          _updateWorkDate(index: index, isEndDate: true, value: '');
          return;
        case _EndDateSelection.chooseDate:
          break;
      }
    }

    final selectedDate = await _showMonthYearPicker(
      title: isEndDate
          ? 'Select end month and year'
          : 'Select start month and year',
      initialDate: _initialWorkPickerDate(currentValue),
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    _updateWorkDate(
      index: index,
      isEndDate: isEndDate,
      value: DateFormat('MMM yyyy').format(selectedDate),
    );
  }

  Future<void> _pickEducationCompletionYear({
    required int index,
    required String currentValue,
  }) async {
    FocusScope.of(context).unfocus();
    final selectedYear = await _showYearPickerDialog(
      title: 'Select completion year',
      initialValue: currentValue,
    );

    if (!mounted || selectedYear == null) {
      return;
    }

    context.read<ResumeEditorViewModel>().updateEducation(
      index,
      (current) => current.copyWith(year: selectedYear),
    );
  }

  DateTime _initialWorkPickerDate(String currentValue) {
    final trimmed = currentValue.trim();
    if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'present') {
      return _parseWorkDate(trimmed);
    }

    final educationYear = _latestEducationCompletionYear();
    if (educationYear != null) {
      return DateTime(educationYear, DateTime.now().month);
    }

    return DateTime.now();
  }

  int? _latestEducationCompletionYear() {
    final years = context
        .read<ResumeEditorViewModel>()
        .resume
        .education
        .map((item) => int.tryParse(item.year.trim()))
        .whereType<int>()
        .toList();

    if (years.isEmpty) {
      return null;
    }

    return years.reduce(math.max);
  }

  Future<DateTime?> _showMonthYearPicker({
    required String title,
    required DateTime initialDate,
  }) async {
    final years = _availableYears();
    var selectedYear = initialDate.year;
    var selectedMonth = initialDate.month;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: years
                          .map(
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text('$year'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedYear = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (index) {
                        final month = index + 1;
                        final label = DateFormat.MMM().format(
                          DateTime(2000, month),
                        );
                        return ChoiceChip(
                          label: Text(label),
                          selected: month == selectedMonth,
                          onSelected: (_) {
                            setState(() => selectedMonth = month);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(DateTime(selectedYear, selectedMonth)),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showYearPickerDialog({
    required String title,
    required String initialValue,
  }) async {
    final selectedYear = _parseYear(initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 320,
            height: 320,
            child: YearPicker(
              firstDate: DateTime(1970),
              lastDate: DateTime(2100),
              selectedDate: DateTime(selectedYear),
              currentDate: DateTime.now(),
              onChanged: (date) => Navigator.of(context).pop('${date.year}'),
            ),
          ),
        );
      },
    );
  }

  DateTime _parseWorkDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'present') {
      return DateTime.now();
    }

    for (final format in [
      DateFormat('MMM yyyy'),
      DateFormat('MMMM yyyy'),
      DateFormat('yyyy'),
    ]) {
      try {
        final parsed = format.parseStrict(trimmed);
        return DateTime(parsed.year, parsed.month);
      } catch (_) {
        continue;
      }
    }

    return DateTime.now();
  }

  int _parseYear(String value) {
    return int.tryParse(value.trim()) ?? DateTime.now().year;
  }

  List<int> _availableYears() {
    final currentYear = DateTime.now().year;
    return List<int>.generate(131, (index) => currentYear + 5 - index);
  }

  void _updateWorkDate({
    required int index,
    required bool isEndDate,
    required String value,
  }) {
    context.read<ResumeEditorViewModel>().updateWorkExperience(
      index,
      (current) => current.copyWith(
        startDate: isEndDate ? current.startDate : value,
        endDate: isEndDate ? value : current.endDate,
      ),
    );
  }

  void _moveWorkExperience({required int index, required bool moveUp}) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final viewModel = context.read<ResumeEditorViewModel>();
      if (moveUp) {
        viewModel.moveWorkExperienceUp(index);
      } else {
        viewModel.moveWorkExperienceDown(index);
      }
    });
  }

  void _moveEducation({required int index, required bool moveUp}) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final viewModel = context.read<ResumeEditorViewModel>();
      if (moveUp) {
        viewModel.moveEducationUp(index);
      } else {
        viewModel.moveEducationDown(index);
      }
    });
  }

  void _scrollToStepTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stepScrollController.hasClients) {
        return;
      }

      _stepScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    context.read<ResumeEditorViewModel>().setStep(step);
    _scrollToStepTop();
  }

  Future<void> _goToNextStep() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    FocusScope.of(context).unfocus();
    await viewModel.saveResume();
    if (!mounted) {
      return;
    }
    _goToStep(viewModel.currentStep + 1);
  }

  void _goToPreviousStep() {
    final viewModel = context.read<ResumeEditorViewModel>();
    _goToStep(viewModel.currentStep - 1);
  }

  Future<void> _promptForBullet(int index) async {
    final value = await _showInputDialog(
      title: 'Add bullet point',
      hintText: 'Describe a measurable accomplishment or responsibility.',
    );

    if (!mounted || value == null || value.trim().isEmpty) {
      return;
    }

    context.read<ResumeEditorViewModel>().updateWorkExperience(
      index,
      (current) =>
          current.copyWith(bullets: [...current.bullets, value.trim()]),
    );
  }

  Future<String?> _showInputDialog({
    required String title,
    required String hintText,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(title: title, hintText: hintText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResumeEditorViewModel>(
      builder: (context, viewModel, _) {
        final currentTitle = viewModel.resume.title.ifBlank('Resume Builder');
        final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
        final showKeyboardHideButton =
            keyboardInset > 0 &&
            (_summaryFocusNode.hasFocus || _isExtendedKeyboardHideFieldFocused);
        final iosTitleStyle = Theme.of(
          context,
        ).cupertinoOverrideTheme?.textTheme?.navTitleTextStyle;
        final baseTitleStyle = Theme.of(context).platform == TargetPlatform.iOS
            ? iosTitleStyle?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              )
            : Theme.of(context).appBarTheme.titleTextStyle;
        final titleStyle = baseTitleStyle;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            leadingWidth: 40,
            titleSpacing: 8,
            title: Text(currentTitle, style: titleStyle),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: viewModel.isBusy ? null : _saveResume,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 22),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _StepProgressHeader(
                      currentStep: viewModel.currentStep,
                      onSelectStep: _goToStep,
                    ),
                    if (viewModel.isBusy) const LinearProgressIndicator(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 1080;
                          final main = Column(
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: SingleChildScrollView(
                                    controller: _stepScrollController,
                                    key: ValueKey(viewModel.currentStep),
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: EdgeInsets.fromLTRB(
                                      20,
                                      20,
                                      20,
                                      24 + keyboardInset,
                                    ),
                                    child: _buildStepContent(
                                      context,
                                      viewModel,
                                      isWide,
                                    ),
                                  ),
                                ),
                              ),
                              _BottomControls(
                                currentStep: viewModel.currentStep,
                                totalSteps:
                                    ResumeEditorViewModel.stepTitles.length,
                                onBack: viewModel.currentStep == 0
                                    ? null
                                    : _goToPreviousStep,
                                onNext:
                                    viewModel.currentStep ==
                                        ResumeEditorViewModel
                                                .stepTitles
                                                .length -
                                            1
                                    ? _saveResume
                                    : viewModel.currentStep == 0 &&
                                          !viewModel
                                              .resume
                                              .hasRequiredPersonalInfo
                                    ? null
                                    : () => _goToNextStep(),
                              ),
                            ],
                          );

                          if (!isWide) {
                            return main;
                          }

                          return Row(
                            children: [
                              Expanded(flex: 6, child: main),
                              SizedBox(
                                width: math.min(
                                  420,
                                  constraints.maxWidth * 0.34,
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    20,
                                    20,
                                    24,
                                  ),
                                  child: _LivePreviewPanel(
                                    resume: viewModel.resume,
                                    analysis: viewModel.analysis,
                                    onDownload: _downloadResume,
                                    onShare: _shareResume,
                                    onPrint: _printResume,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (showKeyboardHideButton)
                  Positioned(
                    right: 20,
                    bottom: keyboardInset + 12,
                    child: IconButton.filledTonal(
                      onPressed: () => FocusScope.of(context).unfocus(),
                      icon: const Icon(Icons.keyboard_hide_rounded),
                      tooltip: 'Hide keyboard',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ResumeEditorViewModel viewModel,
    bool isWide,
  ) {
    return switch (viewModel.currentStep) {
      0 => _buildPersonalStep(viewModel),
      1 => _buildWorkStep(viewModel),
      2 => _buildEducationStep(viewModel),
      3 => _buildSkillsStep(viewModel),
      4 => _buildProjectsStep(viewModel),
      _ => _buildPreviewStep(viewModel, showPreview: !isWide),
    };
  }

  Widget _buildPersonalStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: 'Personal information',
      subtitle:
          'Start with identity, contact details, target role, and a short positioning summary.',
      child: _ResponsiveFieldGroup(
        children: [
          _SyncTextField(
            label: 'Resume title',
            value: viewModel.resume.title,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(title: value),
            ),
          ),
          _SyncTextField(
            label: 'Full name',
            value: viewModel.resume.fullName,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(fullName: value),
            ),
          ),
          _SyncTextField(
            label: 'Target job title',
            value: viewModel.resume.jobTitle,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(jobTitle: value),
            ),
          ),
          _SyncTextField(
            label: 'GitHub link',
            value: viewModel.resume.githubLink,
            keyboardType: TextInputType.url,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(githubLink: value),
            ),
          ),
          _SyncTextField(
            label: 'LinkedIn link',
            value: viewModel.resume.linkedinLink,
            keyboardType: TextInputType.url,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(linkedinLink: value),
            ),
          ),
          _SyncTextField(
            label: 'Email',
            value: viewModel.resume.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(email: value),
            ),
          ),
          _SyncTextField(
            label: 'Phone',
            value: viewModel.resume.phone,
            keyboardType: TextInputType.phone,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(phone: value),
            ),
          ),
          _SyncTextField(
            label: 'Location',
            value: viewModel.resume.location,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(location: value),
            ),
          ),
          _SyncTextField(
            label: 'Website or portfolio',
            value: viewModel.resume.website,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(website: value),
            ),
          ),
          _SyncTextField(
            label: 'Professional summary',
            value: viewModel.resume.summary,
            maxLines: 5,
            focusNode: _summaryFocusNode,
            onChanged: (value) => viewModel.updateResume(
              (resume) => resume.copyWith(summary: value),
            ),
            fullWidth: true,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: viewModel.isBusy ? null : _generateSummary,
                style: _mediumTonalButtonStyle(context),
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Generate summary'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: 'Work experience',
      subtitle:
          'Add role details and measurable outcomes. Use AI to generate stronger bullet points.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HintBanner(
            title: 'Resume order',
            body:
                'Experiences appear on the resume from top to bottom in this same order. Use the arrows to move your strongest role to the top.',
          ),
          const SizedBox(height: 16),
          ...viewModel.resume.workExperiences.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Experience ${index + 1}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _resumeOrderLabel(index),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (viewModel.resume.workExperiences.length > 1) ...[
                          IconButton.filledTonal(
                            tooltip: 'Move up',
                            onPressed: index == 0
                                ? null
                                : () => _moveWorkExperience(
                                    index: index,
                                    moveUp: true,
                                  ),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Move down',
                            onPressed:
                                index ==
                                    viewModel.resume.workExperiences.length - 1
                                ? null
                                : () => _moveWorkExperience(
                                    index: index,
                                    moveUp: false,
                                  ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                          IconButton(
                            onPressed: () =>
                                viewModel.removeWorkExperience(index),
                            icon: const ImageIcon(
                              AssetImage('assets/fonts/delete.png'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          label: 'Role',
                          value: item.role,
                          onChanged: (value) => viewModel.updateWorkExperience(
                            index,
                            (current) => current.copyWith(role: value),
                          ),
                        ),
                        _SyncTextField(
                          label: 'Company',
                          value: item.company,
                          onChanged: (value) => viewModel.updateWorkExperience(
                            index,
                            (current) => current.copyWith(company: value),
                          ),
                        ),
                        _PickerField(
                          key: Key('work-start-date-$index'),
                          label: 'Start date',
                          value: item.startDate,
                          hintText: 'Month/year',
                          onTap: () => _pickWorkDate(
                            index: index,
                            isEndDate: false,
                            currentValue: item.startDate,
                          ),
                        ),
                        _PickerField(
                          key: Key('work-end-date-$index'),
                          label: 'End date',
                          value: item.endDate,
                          hintText: 'Month/year or Present',
                          onTap: () => _pickWorkDate(
                            index: index,
                            isEndDate: true,
                            currentValue: item.endDate,
                          ),
                        ),
                        _SyncTextField(
                          key: Key('work-description-$index'),
                          label: 'Short description',
                          value: item.description,
                          maxLines: 4,
                          fullWidth: true,
                          focusNode: _focusNodeForExtendedKeyboardField(
                            'work-description-$index',
                          ),
                          onChanged: (value) => viewModel.updateWorkExperience(
                            index,
                            (current) => current.copyWith(description: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: viewModel.isBusy
                              ? null
                              : () => _generateBullets(index),
                          style: _mediumTonalButtonStyle(context),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Generate bullets'),
                        ),
                        OutlinedButton.icon(
                          onPressed: viewModel.isBusy
                              ? null
                              : () => _promptForBullet(index),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add bullet'),
                        ),
                      ],
                    ),
                    if (item.bullets.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ...item.bullets.asMap().entries.map((bulletEntry) {
                        final bulletIndex = bulletEntry.key;
                        final bullet = bulletEntry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                Expanded(child: Text(bullet)),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final updated = [...item.bullets]
                                      ..removeAt(bulletIndex);
                                    viewModel.updateWorkExperience(
                                      index,
                                      (current) =>
                                          current.copyWith(bullets: updated),
                                    );
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: viewModel.isBusy ? null : viewModel.addWorkExperience,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add experience'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: 'Education',
      subtitle:
          'Include your degree, institution, completion year, score, and supporting details like honors or coursework.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HintBanner(
            title: 'Resume order',
            body:
                'Education entries appear on the resume from top to bottom in this same order. Use the arrows to keep the most important one first.',
          ),
          const SizedBox(height: 16),
          ...viewModel.resume.education.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Education ${index + 1}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _resumeOrderLabel(index),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (viewModel.resume.education.length > 1) ...[
                          IconButton.filledTonal(
                            tooltip: 'Move education up',
                            onPressed: index == 0
                                ? null
                                : () => _moveEducation(
                                    index: index,
                                    moveUp: true,
                                  ),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Move education down',
                            onPressed:
                                index == viewModel.resume.education.length - 1
                                ? null
                                : () => _moveEducation(
                                    index: index,
                                    moveUp: false,
                                  ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                          IconButton(
                            onPressed: () => viewModel.removeEducation(index),
                            icon: const ImageIcon(
                              AssetImage('assets/fonts/delete.png'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          label: 'Institution',
                          value: item.institution,
                          onChanged: (value) => viewModel.updateEducation(
                            index,
                            (current) => current.copyWith(institution: value),
                          ),
                        ),
                        _SyncTextField(
                          label: 'Degree',
                          value: item.degree,
                          onChanged: (value) => viewModel.updateEducation(
                            index,
                            (current) => current.copyWith(degree: value),
                          ),
                        ),
                        _PickerField(
                          key: Key('education-completion-year-$index'),
                          label: 'Completion year',
                          value: item.year,
                          hintText: 'Select year',
                          onTap: () => _pickEducationCompletionYear(
                            index: index,
                            currentValue: item.year,
                          ),
                        ),
                        _SyncTextField(
                          label: 'Score / marks',
                          value: item.score,
                          hintText: '8.6 CGPA, 92%, or 780/800',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) => viewModel.updateEducation(
                            index,
                            (current) => current.copyWith(score: value),
                          ),
                        ),
                        _SyncTextField(
                          key: Key('education-details-$index'),
                          label: 'Details',
                          value: item.details,
                          fullWidth: true,
                          maxLines: 3,
                          focusNode: _focusNodeForExtendedKeyboardField(
                            'education-details-$index',
                          ),
                          onChanged: (value) => viewModel.updateEducation(
                            index,
                            (current) => current.copyWith(details: value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: viewModel.isBusy ? null : viewModel.addEducation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add education'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: 'Skills',
      subtitle:
          'Add job-specific tools and keywords. AI suggests skills from the resume title, target role, and work experience details like role, company, and descriptions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${viewModel.resume.skills.length}/${ResumeEditorViewModel.maxSkills} skills',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _EnsureVisibleOnFocus(
            child: TextField(
              controller: _skillController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addSkillFromInput(),
              decoration: InputDecoration(
                labelText: 'Add a skill',
                helperText: viewModel.hasReachedSkillLimit
                    ? 'Maximum 50 skills reached'
                    : 'You can add up to 50 skills',
                suffixIcon: IconButton(
                  onPressed: _addSkillFromInput,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: viewModel.isBusy || viewModel.hasReachedSkillLimit
                    ? null
                    : _suggestSkills,
                style: _mediumTonalButtonStyle(context),
                icon: const Icon(Icons.psychology_alt_outlined),
                label: const Text('Suggest skills'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (viewModel.resume.skills.isEmpty)
            _HintBanner(
              title: 'No skills added yet',
              body:
                  'Aim for 6-12 relevant skills so ATS systems can match your resume more reliably, with room for up to 50 if needed.',
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: viewModel.resume.skills.map((skill) {
                return InputChip(
                  label: Text(skill),
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.bodyMedium?.fontSize ??
                            14) -
                        2,
                    fontWeight: FontWeight.w400,
                  ),
                  onDeleted: () => viewModel.removeSkill(skill),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectsStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: 'Projects',
      subtitle:
          'Showcase standout side projects, product launches, or portfolio work with clear outcomes.',
      child: Column(
        children: [
          ...viewModel.resume.projects.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Project ${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (viewModel.resume.projects.length > 1)
                          IconButton(
                            onPressed: () => viewModel.removeProject(index),
                            icon: const ImageIcon(
                              AssetImage('assets/fonts/delete.png'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          label: 'Project title',
                          value: item.title,
                          onChanged: (value) => viewModel.updateProject(
                            index,
                            (current) => current.copyWith(title: value),
                          ),
                        ),
                        _SyncTextField(
                          label: 'Subtitle or stack',
                          value: item.subtitle,
                          onChanged: (value) => viewModel.updateProject(
                            index,
                            (current) => current.copyWith(subtitle: value),
                          ),
                        ),
                        _SyncTextField(
                          label: 'Overview',
                          value: item.overview,
                          maxLines: 4,
                          fullWidth: true,
                          onChanged: (value) => viewModel.updateProject(
                            index,
                            (current) => current.copyWith(overview: value),
                          ),
                        ),
                        _SyncTextField(
                          label: 'Impact',
                          value: item.impact,
                          maxLines: 3,
                          fullWidth: true,
                          onChanged: (value) => viewModel.updateProject(
                            index,
                            (current) => current.copyWith(impact: value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: viewModel.isBusy ? null : viewModel.addProject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add project'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(
    ResumeEditorViewModel viewModel, {
    required bool showPreview,
  }) {
    final analysis = viewModel.analysis;
    final jobInsights = viewModel.jobInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview) ...[
          ResumePreviewCard(resume: viewModel.resume),
          const SizedBox(height: 16),
        ],
        _StepSurface(
          title: 'Preview, analyzer, and export',
          subtitle:
              'Review the live template preview, run ATS checks, generate a cover letter, and export to PDF.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (analysis != null) ...[
                _ScoreTile(analysis: analysis),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: viewModel.isBusy ? null : _analyzeResume,
                    style: _mediumTonalButtonStyle(context),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analyze resume'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EnsureVisibleOnFocus(
                child: TextField(
                  controller: _jobDescriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Job description',
                    hintText:
                        'Paste a job post to compare ATS keywords and resume alignment.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonal(
                    onPressed: viewModel.isBusy ? null : _analyzeJobDescription,
                    style: _mediumTonalButtonStyle(context),
                    child: const Text('Analyze job description'),
                  ),
                  FilledButton.tonal(
                    onPressed: viewModel.isBusy ? null : _downloadResume,
                    style: _mediumTonalButtonStyle(context),
                    child: const Text('Download PDF'),
                  ),
                  OutlinedButton(
                    onPressed: viewModel.isBusy ? null : _shareResume,
                    child: const Text('Share resume'),
                  ),
                  OutlinedButton(
                    onPressed: viewModel.isBusy ? null : _printResume,
                    child: const Text('Print'),
                  ),
                ],
              ),
              if (jobInsights != null) ...[
                const SizedBox(height: 16),
                _InsightPanel(
                  title: 'Job description insights',
                  items: [
                    jobInsights.summary,
                    if (jobInsights.keywords.isNotEmpty)
                      'Keywords: ${jobInsights.keywords.join(', ')}',
                    if (jobInsights.missingSkills.isNotEmpty)
                      'Missing skills: ${jobInsights.missingSkills.join(', ')}',
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Cover letter generator',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _ResponsiveFieldGroup(
                children: [
                  _SyncTextField(
                    label: 'Company',
                    value: _coverLetterCompanyController.text,
                    hintText: 'Acme Inc.',
                    onChanged: (value) {
                      if (_coverLetterCompanyController.text != value) {
                        _coverLetterCompanyController.text = value;
                      }
                    },
                  ),
                  _SyncTextField(
                    label: 'Role',
                    value: _coverLetterRoleController.text,
                    hintText: viewModel.resume.jobTitle.ifBlank('Target role'),
                    onChanged: (value) {
                      if (_coverLetterRoleController.text != value) {
                        _coverLetterRoleController.text = value;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: viewModel.isBusy ? null : _generateCoverLetter,
                style: _mediumTonalButtonStyle(context),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Generate cover letter'),
              ),
              if (viewModel.coverLetter.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SelectableText(viewModel.coverLetter),
                ),
              ],
              if ((analysis?.improvements.isNotEmpty ?? false) ||
                  (analysis?.weakDescriptions.isNotEmpty ?? false)) ...[
                const SizedBox(height: 16),
                _InsightPanel(
                  title: 'Improvement suggestions',
                  items: [
                    ...?analysis?.improvements,
                    ...?analysis?.weakDescriptions,
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepProgressHeader extends StatefulWidget {
  const _StepProgressHeader({
    required this.currentStep,
    required this.onSelectStep,
  });

  final int currentStep;
  final ValueChanged<int> onSelectStep;

  @override
  State<_StepProgressHeader> createState() => _StepProgressHeaderState();
}

class _StepProgressHeaderState extends State<_StepProgressHeader> {
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _chipKeys = {};

  GlobalKey _chipKeyFor(int index) {
    return _chipKeys.putIfAbsent(index, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _scrollSelectedChip();
  }

  @override
  void didUpdateWidget(covariant _StepProgressHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _scrollSelectedChip();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollSelectedChip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final chipContext = _chipKeyFor(widget.currentStep).currentContext;
      if (chipContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (widget.currentStep + 1) / ResumeEditorViewModel.stepTitles.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.currentStep + 1}/${ResumeEditorViewModel.stepTitles.length}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ResumeEditorViewModel.stepTitles.asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                final label = entry.value;
                final selected = index == widget.currentStep;
                return Padding(
                  key: _chipKeyFor(index),
                  padding: EdgeInsets.only(
                    right: index == ResumeEditorViewModel.stepTitles.length - 1
                        ? 0
                        : 10,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => widget.onSelectStep(index),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(onPressed: onBack, child: const Text('Back')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onNext,
              child: Text(isLastStep ? 'Save resume' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepSurface extends StatelessWidget {
  const _StepSurface({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFieldGroup extends StatelessWidget {
  const _ResponsiveFieldGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final multiColumn = constraints.maxWidth >= 760;
        final regularWidth = multiColumn
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children.map((child) {
            if (child is _SyncTextField && child.fullWidth) {
              return SizedBox(width: constraints.maxWidth, child: child);
            }
            if (child is Wrap || child is TextField || child is _HintBanner) {
              return SizedBox(width: constraints.maxWidth, child: child);
            }
            return SizedBox(width: regularWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}

void _scheduleEnsureVisible(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!context.mounted) {
        return;
      }

      final renderObject = context.findRenderObject();
      final scrollable = Scrollable.maybeOf(context);
      if (renderObject is! RenderBox || scrollable == null) {
        return;
      }

      final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
      if (keyboardInset <= 0) {
        return;
      }

      final fieldTop = renderObject.localToGlobal(Offset.zero).dy;
      final fieldBottom = fieldTop + renderObject.size.height;
      final visibleBottom =
          MediaQuery.sizeOf(context).height - keyboardInset - 12;
      final overlap = fieldBottom - visibleBottom;

      if (overlap <= 0) {
        return;
      }

      final position = scrollable.position;
      final targetOffset = (position.pixels + overlap + 12)
          .clamp(0.0, position.maxScrollExtent)
          .toDouble();

      if ((targetOffset - position.pixels).abs() < 1) {
        return;
      }

      position.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  });
}

class _EnsureVisibleOnFocus extends StatelessWidget {
  const _EnsureVisibleOnFocus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _scheduleEnsureVisible(context);
        }
      },
      child: child,
    );
  }
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({required this.title, required this.hintText});

  final String title;
  final String hintText;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
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
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        decoration: InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

enum _EndDateSelection { chooseDate, present, clear }

class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hintText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintMaxLines: 1,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: hasValue
            ? Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _SyncTextField extends StatefulWidget {
  const _SyncTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.focusNode,
    this.hintText,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final String? hintText;
  final bool fullWidth;

  @override
  State<_SyncTextField> createState() => _SyncTextFieldState();
}

class _SyncTextFieldState extends State<_SyncTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _scheduleEnsureVisible(context);
    }
  }

  @override
  void didUpdateWidget(covariant _SyncTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePreviewPanel extends StatelessWidget {
  const _LivePreviewPanel({
    required this.resume,
    required this.analysis,
    required this.onDownload,
    required this.onShare,
    required this.onPrint,
  });

  final ResumeData resume;
  final ResumeAnalysis? analysis;
  final Future<void> Function() onDownload;
  final Future<void> Function() onShare;
  final Future<void> Function() onPrint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live preview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ResumePreviewCard(resume: resume),
        const SizedBox(height: 16),
        if (analysis != null) ...[
          _ScoreTile(analysis: analysis!),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onDownload,
                  child: const Text('Download PDF'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onShare,
                  child: const Text('Share resume'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: onPrint, child: const Text('Print')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({required this.analysis});

  final ResumeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
                    'Resume score',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ATS compatibility ${(analysis.atsCompatibility * 100).round()}% with ${analysis.missingSkills.length} missing skill gap${analysis.missingSkills.length == 1 ? '' : 's'}.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
