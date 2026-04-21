import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/bottom_sheet_insets.dart';
import '../../core/models/resume_models.dart';
import '../../core/skill_autocomplete_suggestions.dart';
import '../../core/services/app_preferences.dart';
import 'resume_preview_screen.dart';
import '../shared/resume_preview_card.dart';
import '../shared/view_models.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  static const Duration _stepScrollAnimationDuration = Duration(
    milliseconds: 280,
  );
  static const Duration _stepPageAnimationDuration = Duration(
    milliseconds: 340,
  );
  static const Curve _stepAnimationCurve = Curves.easeInOutCubicEmphasized;

  final _skillController = TextEditingController();
  final _skillFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final _personalFieldFocusNodes = List<FocusNode>.generate(
    8,
    (_) => FocusNode(),
  );
  final _summaryFocusNode = FocusNode();
  late final PageController _pageController;
  final Map<int, ScrollController> _stepScrollControllers = {};
  final Map<String, FocusNode> _extendedKeyboardHideFocusNodes = {};
  bool _didInitPageController = false;
  bool _prefsHydrated = false;
  bool _resumeOrderNudgeDismissed = false;

  List<FocusNode> get _personalKeyboardFocusOrder => [
    ..._personalFieldFocusNodes,
    _summaryFocusNode,
  ];

  bool get _isWorkKeyboardHideFieldFocused =>
      _extendedKeyboardHideFocusNodes.entries.any(
        (entry) =>
            (entry.key.startsWith('work-role-') ||
                entry.key.startsWith('work-company-') ||
                entry.key.startsWith('work-bullet-')) &&
            entry.value.hasFocus,
      );

  bool get _isProjectKeyboardHideFieldFocused => _extendedKeyboardHideFocusNodes
      .entries
      .any((entry) => entry.key.startsWith('project-') && entry.value.hasFocus);

  bool get _isCustomKeyboardHideFieldFocused =>
      _extendedKeyboardHideFocusNodes.entries.any(
        (entry) =>
            entry.key.startsWith('custom-section-') && entry.value.hasFocus,
      );

  List<FocusNode> get _projectKeyboardFocusOrder {
    final projectEntries =
        _extendedKeyboardHideFocusNodes.entries
            .where((entry) => entry.key.startsWith('project-'))
            .toList()
          ..sort((a, b) => _compareProjectFocusKeys(a.key, b.key));
    return projectEntries.map((entry) => entry.value).toList(growable: false);
  }

  int _compareProjectFocusKeys(String a, String b) {
    int parseProjectIndex(String key) {
      final parts = key.split('-');
      if (parts.length >= 4 && parts[1] == 'bullet') {
        return int.tryParse(parts[2]) ?? 0;
      }
      return int.tryParse(parts.last) ?? 0;
    }

    int parseBulletIndex(String key) {
      final parts = key.split('-');
      if (parts.length >= 4 && parts[1] == 'bullet') {
        return int.tryParse(parts[3]) ?? 0;
      }
      return 0;
    }

    int fieldRank(String key) {
      if (key.startsWith('project-title-')) return 0;
      if (key.startsWith('project-bullet-')) return 1;
      return 99;
    }

    final indexCompare = parseProjectIndex(a).compareTo(parseProjectIndex(b));
    if (indexCompare != 0) {
      return indexCompare;
    }
    final rankCompare = fieldRank(a).compareTo(fieldRank(b));
    if (rankCompare != 0) {
      return rankCompare;
    }
    return parseBulletIndex(a).compareTo(parseBulletIndex(b));
  }

  @override
  void initState() {
    super.initState();
    _summaryFocusNode.addListener(_handleSummaryFocusChange);
    _skillFocusNode.addListener(_handleSkillFocusChange);
  }

  void _handleSkillFocusChange() {
    if (_skillFocusNode.hasFocus && mounted) {
      _scheduleEnsureVisible(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefsHydrated) {
      _prefsHydrated = true;
      _resumeOrderNudgeDismissed =
          context.read<AppPreferences>().resumeOrderNudgeDismissed;
    }
    if (_didInitPageController) {
      return;
    }

    _pageController = PageController(
      initialPage: context.read<ResumeEditorViewModel>().currentStep,
    );
    _didInitPageController = true;
  }

  void _onDismissResumeOrderNudge() {
    final prefs = context.read<AppPreferences>();
    setState(() => _resumeOrderNudgeDismissed = true);
    prefs.setResumeOrderNudgeDismissed(true);
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

  @override
  void dispose() {
    _skillFocusNode
      ..removeListener(_handleSkillFocusChange)
      ..dispose();
    _skillController.dispose();
    _pageController.dispose();
    for (final controller in _stepScrollControllers.values) {
      controller.dispose();
    }
    for (final node in _personalFieldFocusNodes) {
      node.dispose();
    }
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

  Future<void> _openPreview() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    await viewModel.saveResume();
    if (!mounted) {
      return;
    }

    final targetStep = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: viewModel,
          child: const ResumePreviewScreen(),
        ),
      ),
    );

    if (!mounted || targetStep == null) {
      return;
    }

    _goToStep(targetStep);
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
              : 'No new skills were added.',
        ),
      ),
    );
  }

  void _addSkillFromInput() {
    final viewModel = context.read<ResumeEditorViewModel>();
    final rawValue = _skillController.text;
    final added = viewModel.addSkill(rawValue);

    if (added) {
      _skillController.clear();
      return;
    }
  }

  Future<void> _confirmRemoval({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (result == true && mounted) {
      onConfirm();
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

  Future<void> _toggleResumeSectionVisibility({
    required bool isIncluded,
    required String sectionName,
    required void Function(bool) setIncluded,
  }) async {
    if (!isIncluded) {
      setIncluded(true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Hide from resume?'),
          content: Text(
            '$sectionName will not be shown on your resume or in exported PDFs. '
            'You can show it again anytime using the button next to the section title.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hide'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }
    setIncluded(false);
  }

  Widget _resumeSectionVisibilityLead({
    required ResumeEditorViewModel viewModel,
    required bool included,
    required String sectionName,
    required void Function(bool) setIncluded,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Transform.translate(
      offset: const Offset(0, 2),
      child: IconButton(
        tooltip: included ? 'Hide from resume' : 'Show on resume',
        style: IconButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsetsDirectional.only(start: 6, end: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        onPressed: viewModel.isBusy
            ? null
            : () async {
                await _toggleResumeSectionVisibility(
                  isIncluded: included,
                  sectionName: sectionName,
                  setIncluded: setIncluded,
                );
              },
        icon: Icon(
          included ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 22,
        ),
      ),
    );
  }

  TextStyle? _resumeOrderHintStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.3,
      color: theme.colorScheme.onSurfaceVariant,
    );
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
        backgroundColor: Colors.white,
        builder: (context) {
          final primaryColor = Theme.of(context).colorScheme.primary;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: BottomSheetInsets.leftPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: BottomSheetInsets.topSpacing),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_month_outlined,
                      color: primaryColor,
                    ),
                    title: const Text('Choose month and year'),
                    onTap: () =>
                        Navigator.of(context).pop(_EndDateSelection.chooseDate),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.work_history_outlined,
                      color: primaryColor,
                    ),
                    title: const Text('Present'),
                    onTap: () =>
                        Navigator.of(context).pop(_EndDateSelection.present),
                  ),
                  if (currentValue.trim().isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.clear_rounded, color: primaryColor),
                      title: const Text('Clear date'),
                      onTap: () =>
                          Navigator.of(context).pop(_EndDateSelection.clear),
                    ),
                ],
              ),
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

  Future<void> _pickEducationDate({
    required int index,
    required bool isEndDate,
    required String currentValue,
  }) async {
    FocusScope.of(context).unfocus();
    final selectedYear = await _showYearPickerDialog(
      title: isEndDate ? 'Select end year' : 'Select start year',
      initialValue: currentValue,
    );

    if (!mounted || selectedYear == null) {
      return;
    }

    context.read<ResumeEditorViewModel>().updateEducation(
      index,
      (current) => current.copyWith(
        startDate: isEndDate ? current.startDate : selectedYear,
        endDate: isEndDate ? selectedYear : current.endDate,
      ),
    );
  }

  DateTime _initialWorkPickerDate(String currentValue) {
    final trimmed = currentValue.trim();
    if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'present') {
      return _parseWorkDate(trimmed);
    }

    final educationYear = _latestEducationEndYear();
    if (educationYear != null) {
      return DateTime(educationYear, DateTime.now().month);
    }

    return DateTime.now();
  }

  int? _latestEducationEndYear() {
    final years = context
        .read<ResumeEditorViewModel>()
        .resume
        .education
        .map((item) => int.tryParse(item.endDate.trim()))
        .whereType<int>()
        .toList();

    if (years.isEmpty) {
      return null;
    }

    return years.reduce(math.max);
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
          backgroundColor: Colors.white,
          title: Text(title),
          content: SizedBox(
            width: 320,
            height: 320,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  onSurface: Colors.black,
                  primary: Colors.black,
                ),
                textTheme: Theme.of(context).textTheme.copyWith(
                  bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  labelLarge: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
              child: YearPicker(
                firstDate: DateTime(1970),
                lastDate: DateTime(2100),
                selectedDate: DateTime(selectedYear),
                currentDate: DateTime.now(),
                onChanged: (date) => Navigator.of(context).pop('${date.year}'),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<DateTime?> _showMonthYearPicker({
    required String title,
    required DateTime initialDate,
  }) async {
    final years = _availableYears();
    var selectedYear = years.contains(initialDate.year)
        ? initialDate.year
        : years.first;
    var selectedMonth = initialDate.month;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(title),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: years.contains(selectedYear)
                          ? selectedYear
                          : years.first,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      items: years
                          .map(
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(
                                '$year',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
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
                          label: Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
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

  void _moveProject({required int index, required bool moveUp}) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final viewModel = context.read<ResumeEditorViewModel>();
      if (moveUp) {
        viewModel.moveProjectUp(index);
      } else {
        viewModel.moveProjectDown(index);
      }
    });
  }

  ScrollController _scrollControllerForStep(int step) {
    return _stepScrollControllers.putIfAbsent(step, ScrollController.new);
  }

  void _scrollToStepTop([int? step]) {
    final targetStep =
        step ?? context.read<ResumeEditorViewModel>().currentStep;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _stepScrollControllers[targetStep];
      if (!mounted || controller == null || !controller.hasClients) {
        return;
      }

      controller.animateTo(
        0,
        duration: _stepScrollAnimationDuration,
        curve: _stepAnimationCurve,
      );
    });
  }

  Future<void> _showAddCustomCategoryDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('New section'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Certifications, Languages, Awards…',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) {
              final t = controller.text.trim();
              if (t.isNotEmpty) {
                Navigator.pop(dialogContext, t);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, t);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }

    final viewModel = context.read<ResumeEditorViewModel>();
    viewModel.addCustomSectionWithTitle(name.trim());
    final newIndex = viewModel.resume.customSections.length - 1;
    final targetStep = ResumeEditorViewModel.coreStepCount + newIndex;
    // Wait until PageView rebuilds with the new itemCount before animateToPage;
    // otherwise the index can be out of range and the framework asserts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _goToStep(targetStep);
    });
  }

  Future<void> _confirmRemoveCustomSection(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Remove section?'),
          content: const Text(
            'This section will be removed from your resume. You can add a new '
            'custom section with Add anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }
    context.read<ResumeEditorViewModel>().removeCustomSection(index);
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    final maxStep = context.read<ResumeEditorViewModel>().totalStepCount - 1;
    final normalizedStep = step.clamp(0, maxStep < 0 ? 0 : maxStep);
    context.read<ResumeEditorViewModel>().setStep(normalizedStep);
    _scrollToStepTop(normalizedStep);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        normalizedStep,
        duration: _stepPageAnimationDuration,
        curve: _stepAnimationCurve,
      );
    }
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

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 88,
      );
      if (!mounted || picked == null) {
        return;
      }
      final viewModel = context.read<ResumeEditorViewModel>();
      final currentPath = viewModel.resume.profileImagePath.trim();
      final persistedPath = await _persistProfileImage(
        picked,
        resumeId: viewModel.resume.id,
      );
      if (!mounted) {
        return;
      }
      if (_isManagedProfileImagePath(currentPath) &&
          currentPath.isNotEmpty &&
          currentPath != persistedPath) {
        final previous = File(currentPath);
        if (previous.existsSync()) {
          previous.deleteSync();
        }
      }
      viewModel.updateResume(
        (resume) => resume.copyWith(profileImagePath: persistedPath),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick image right now.')),
      );
    }
  }

  void _clearProfileImage() {
    final viewModel = context.read<ResumeEditorViewModel>();
    final currentPath = viewModel.resume.profileImagePath.trim();
    if (_isManagedProfileImagePath(currentPath) && currentPath.isNotEmpty) {
      final file = File(currentPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    viewModel.updateResume((resume) => resume.copyWith(profileImagePath: ''));
  }

  Future<String> _persistProfileImage(
    XFile picked, {
    required String resumeId,
  }) async {
    final appSupport = await getApplicationSupportDirectory();
    final profileDir = Directory('${appSupport.path}/profile_images');
    if (!profileDir.existsSync()) {
      profileDir.createSync(recursive: true);
    }
    final extension = _fileExtension(picked.path);
    final fileName = '${resumeId}_${
        DateTime.now().millisecondsSinceEpoch
      }$extension';
    final target = File('${profileDir.path}/$fileName');
    await File(picked.path).copy(target.path);
    return target.path;
  }

  String _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return '.jpg';
    }
    return path.substring(dotIndex);
  }

  bool _isManagedProfileImagePath(String path) =>
      path.contains('/profile_images/');

  Future<void> _showProfilePhotoOptions({required bool hasImage}) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        final iconColor = Theme.of(sheetContext).colorScheme.primary;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: BottomSheetInsets.leftPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: BottomSheetInsets.topSpacing),
                ListTile(
                  leading: Icon(Icons.photo_camera_outlined, color: iconColor),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(sheetContext).pop('camera'),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: iconColor),
                  title: const Text('Library'),
                  onTap: () => Navigator.of(sheetContext).pop('library'),
                ),
                if (hasImage)
                  ListTile(
                    leading: ImageIcon(
                      const AssetImage('assets/fonts/delete.png'),
                      color: iconColor,
                    ),
                    title: const Text('Remove'),
                    onTap: () => Navigator.of(sheetContext).pop('remove'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }
    if (action == 'camera') {
      await _pickProfileImage(ImageSource.camera);
      return;
    }
    if (action == 'library') {
      await _pickProfileImage(ImageSource.gallery);
      return;
    }
    if (action == 'remove') {
      _clearProfileImage();
    }
  }

  Widget _buildProfilePhotoPicker(ResumeEditorViewModel viewModel) {
    final imagePath = viewModel.resume.profileImagePath.trim();
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Profile photo',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(56),
            onTap: () => _showProfilePhotoOptions(hasImage: hasImage),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              backgroundImage: hasImage ? FileImage(File(imagePath)) : null,
              child: hasImage
                  ? null
                  : Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to change photo',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResumeEditorViewModel>(
      builder: (context, viewModel, _) {
        final currentTitle = viewModel.resume.title.ifBlank(
          ResumeData.defaultTitle,
        );
        final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
        final showPersonalKeyboardBar =
            keyboardInset > 0 && viewModel.currentStep == 0;
        final showProjectKeyboardBar =
            keyboardInset > 0 &&
            viewModel.currentStep == 4 &&
            _isProjectKeyboardHideFieldFocused;
        final showCustomKeyboardBar =
            keyboardInset > 0 &&
            viewModel.currentStep >= ResumeEditorViewModel.coreStepCount &&
            _isCustomKeyboardHideFieldFocused;
        final showWorkKeyboardHideButton =
            keyboardInset > 0 &&
            viewModel.currentStep == 1 &&
            _isWorkKeyboardHideFieldFocused;
        final showEducationKeyboardHideButton =
            keyboardInset > 0 && viewModel.currentStep == 2;
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
            leadingWidth: 56,
            titleSpacing: 2,
            title: Text(currentTitle, style: titleStyle),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _StepProgressHeader(
                      currentStep: viewModel.currentStep,
                      totalStepCount: viewModel.totalStepCount,
                      customSections: viewModel.resume.customSections,
                      onSelectStep: _goToStep,
                      onAddCategory: _showAddCustomCategoryDialog,
                    ),
                    if (viewModel.isBusy) const LinearProgressIndicator(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 1080;
                          final main = Column(
                            children: [
                              Expanded(
                                child: PageView.builder(
                                  key: const Key('resume-step-pages'),
                                  controller: _pageController,
                                  allowImplicitScrolling: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: viewModel.totalStepCount,
                                  onPageChanged: (index) {
                                    FocusScope.of(context).unfocus();
                                    if (viewModel.currentStep != index) {
                                      viewModel.setStep(index);
                                    }
                                  },
                                  itemBuilder: (context, index) {
                                    final isIosPersonalStep =
                                        Theme.of(context).platform ==
                                            TargetPlatform.iOS &&
                                        index == 0;
                                    final keyboardToolbarPadding =
                                        isIosPersonalStep ? 72.0 : 0.0;
                                    return SingleChildScrollView(
                                      key: Key('step-scroll-$index'),
                                      controller: _scrollControllerForStep(
                                        index,
                                      ),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: EdgeInsets.fromLTRB(
                                        20,
                                        20,
                                        20,
                                        24 +
                                            keyboardInset +
                                            keyboardToolbarPadding,
                                      ),
                                      child: _buildStepContentForStep(
                                        index,
                                        viewModel,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              _BottomControls(
                                currentStep: viewModel.currentStep,
                                totalSteps: viewModel.totalStepCount,
                                onBack: viewModel.currentStep == 0
                                    ? null
                                    : _goToPreviousStep,
                                onNext:
                                    viewModel.currentStep ==
                                        viewModel.totalStepCount - 1
                                    ? _openPreview
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
                if (showPersonalKeyboardBar ||
                    showProjectKeyboardBar ||
                    showCustomKeyboardBar)
                  Positioned(
                    left: 12,
                    bottom: keyboardInset + 8,
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Previous field',
                              onPressed: () => _focusPreviousKeyboardField(
                                viewModel.currentStep,
                              ),
                              icon: const Icon(Icons.keyboard_arrow_up_rounded),
                            ),
                            IconButton(
                              tooltip: 'Next field',
                              onPressed: () => _focusNextKeyboardField(
                                viewModel.currentStep,
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (showPersonalKeyboardBar ||
                    showProjectKeyboardBar ||
                    showCustomKeyboardBar ||
                    showWorkKeyboardHideButton ||
                    showEducationKeyboardHideButton)
                  Positioned(
                    right: 12,
                    bottom: keyboardInset + 8,
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

  Widget _buildStepContentForStep(int step, ResumeEditorViewModel viewModel) {
    if (step < ResumeEditorViewModel.coreStepCount) {
      return switch (step) {
        0 => _buildPersonalStep(viewModel),
        1 => _buildWorkStep(viewModel),
        2 => _buildEducationStep(viewModel),
        3 => _buildSkillsStep(viewModel),
        4 => _buildProjectsStep(viewModel),
        _ => const SizedBox.shrink(),
      };
    }
    final customIndex = step - ResumeEditorViewModel.coreStepCount;
    return _buildSingleCustomSectionStep(viewModel, customIndex);
  }

  Widget _buildPersonalStep(ResumeEditorViewModel viewModel) {
    final personalFields = _ResponsiveFieldGroup(
      children: [
        _SyncTextField(
          label: 'Full name',
          value: viewModel.resume.fullName,
          focusNode: _personalFieldFocusNodes[0],
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[1].requestFocus(),
          onChanged: (value) => viewModel.updateResume(
            (resume) => resume.copyWith(fullName: value),
          ),
        ),
        _SyncTextField(
          label: 'Target job title',
          value: viewModel.resume.jobTitle,
          focusNode: _personalFieldFocusNodes[1],
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[2].requestFocus(),
          onChanged: (value) => viewModel.updateResume(
            (resume) => resume.copyWith(jobTitle: value),
          ),
        ),
        _ProfileLinkField(
          label: 'GitHub link',
          value: viewModel.resume.githubLink,
          basePrefix: 'https://github.com/',
          hintText: 'github.com/username',
          focusNode: _personalFieldFocusNodes[2],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[3].requestFocus(),
          onChanged: (value) => viewModel.updateResume(
            (resume) => resume.copyWith(githubLink: value),
          ),
        ),
        _ProfileLinkField(
          label: 'LinkedIn link',
          value: viewModel.resume.linkedinLink,
          basePrefix: 'https://www.linkedin.com/in/',
          hintText: 'linkedin.com/in/your-name',
          focusNode: _personalFieldFocusNodes[3],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[4].requestFocus(),
          onChanged: (value) => viewModel.updateResume(
            (resume) => resume.copyWith(linkedinLink: value),
          ),
        ),
        _SyncTextField(
          label: 'Email',
          value: viewModel.resume.email,
          focusNode: _personalFieldFocusNodes[4],
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[5].requestFocus(),
          onChanged: (value) =>
              viewModel.updateResume((resume) => resume.copyWith(email: value)),
        ),
        _PhoneWithCountryCodeField(
          label: 'Phoen number',
          value: viewModel.resume.phone,
          focusNode: _personalFieldFocusNodes[5],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[6].requestFocus(),
          onChanged: (value) =>
              viewModel.updateResume((resume) => resume.copyWith(phone: value)),
        ),
        _SyncTextField(
          label: 'Location',
          value: viewModel.resume.location,
          focusNode: _personalFieldFocusNodes[6],
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[7].requestFocus(),
          onChanged: (value) => viewModel.updateResume(
            (resume) => resume.copyWith(location: value),
          ),
        ),
        _SyncTextField(
          label: 'Website or portfolio',
          value: viewModel.resume.website,
          focusNode: _personalFieldFocusNodes[7],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _summaryFocusNode.requestFocus(),
          onChanged: (value) => viewModel.updateResume(
            (resume) => resume.copyWith(website: value),
          ),
        ),
        _SyncTextField(
          label: 'Professional summary',
          value: viewModel.resume.summary,
          minLines: 5,
          maxLines: null,
          focusNode: _summaryFocusNode,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
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
    );
    return _StepSurface(
      title: 'Personal information',
      subtitle:
          'Start with identity, contact details, target role, and a short positioning summary.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          personalFields,
          const SizedBox(height: 36),
          _buildProfilePhotoPicker(viewModel),
        ],
      ),
    );
  }

  Widget _buildWorkStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: 'Work experience',
      subtitle: '',
      titleTrailing: _resumeSectionVisibilityLead(
        viewModel: viewModel,
        included: viewModel.resume.includeWorkInResume,
        sectionName: 'Work experience',
        setIncluded: viewModel.setIncludeWorkInResume,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (!_resumeOrderNudgeDismissed &&
              viewModel.resume.workExperiences.length > 1) ...[
            _HintBanner(
              title: 'Resume order',
              body:
                  'Entries stay in this order. Use arrows to move your strongest role to top.',
              compact: true,
              onDismiss: _onDismissResumeOrderNudge,
            ),
            const SizedBox(height: 10),
          ],
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
                                style: _resumeOrderHintStyle(context),
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
                            tooltip: 'Delete experience',
                            onPressed: viewModel.isBusy
                                ? null
                                : () {
                                    _confirmRemoval(
                                      title: 'Delete work experience?',
                                      message:
                                          'This will remove this job and all of its bullet points. This cannot be undone.',
                                      onConfirm: () =>
                                          viewModel.removeWorkExperience(index),
                                    );
                                  },
                            icon: const ImageIcon(
                              AssetImage('assets/fonts/delete.png'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          label: 'Role',
                          value: item.role,
                          textCapitalization: TextCapitalization.sentences,
                          focusNode: _focusNodeForExtendedKeyboardField(
                            'work-role-$index',
                          ),
                          onChanged: (value) => viewModel.updateWorkExperience(
                            index,
                            (current) => current.copyWith(role: value),
                          ),
                        ),
                        _SyncTextField(
                          label: 'Company',
                          value: item.company,
                          textCapitalization: TextCapitalization.sentences,
                          focusNode: _focusNodeForExtendedKeyboardField(
                            'work-company-$index',
                          ),
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
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...(() {
                      final displayBullets = List<String>.from(item.bullets);
                      return <Widget>[
                        if (displayBullets.isEmpty)
                          Text(
                            'Add bullet points for this experience.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ...displayBullets.asMap().entries.map((bulletEntry) {
                          final bulletIndex = bulletEntry.key;
                          final bullet = bulletEntry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _SyncTextField(
                                    key: Key('work-bullet-$index-$bulletIndex'),
                                    label: 'Bullet ${bulletIndex + 1}',
                                    value: bullet,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    fullWidth: true,
                                    minLines: 1,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    focusNode:
                                        _focusNodeForExtendedKeyboardField(
                                          'work-bullet-$index-$bulletIndex',
                                        ),
                                    onChanged: (value) =>
                                        viewModel.updateWorkExperience(
                                      index,
                                      (current) {
                                        final updated = List<String>.from(
                                          current.bullets,
                                        );
                                        if (bulletIndex < updated.length) {
                                          updated[bulletIndex] = value;
                                        }
                                        return current.copyWith(
                                          bullets: updated,
                                          layoutMode:
                                              WorkExperienceLayoutMode.bullets,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove bullet',
                                  onPressed: viewModel.isBusy
                                      ? null
                                      : () {
                                          _confirmRemoval(
                                            title: 'Remove bullet?',
                                            message:
                                                'This bullet will be removed from this job.',
                                            onConfirm: () {
                                              viewModel.updateWorkExperience(
                                                index,
                                                (current) {
                                                  final updated =
                                                      List<String>.from(
                                                    current.bullets,
                                                  );
                                                  if (bulletIndex >=
                                                      updated.length) {
                                                    return current;
                                                  }
                                                  updated.removeAt(
                                                    bulletIndex,
                                                  );
                                                  return current.copyWith(
                                                    bullets: updated,
                                                    layoutMode:
                                                        WorkExperienceLayoutMode
                                                            .bullets,
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                  icon: const ImageIcon(
                                    AssetImage('assets/fonts/delete.png'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: viewModel.isBusy
                                ? null
                                : () {
                                    viewModel.updateWorkExperience(
                                      index,
                                      (current) => current.copyWith(
                                        bullets: [...current.bullets, ''],
                                        layoutMode:
                                            WorkExperienceLayoutMode.bullets,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add bullet point'),
                          ),
                        ),
                      ];
                    })(),
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

  void _focusPreviousKeyboardField(int currentStep) {
    if (currentStep == 0) {
      _movePersonalFieldFocus(delta: -1);
      return;
    }
    if (currentStep == 4) {
      _moveFocusInOrder(_projectKeyboardFocusOrder, delta: -1);
      return;
    }
    if (currentStep >= ResumeEditorViewModel.coreStepCount) {
      final i = currentStep - ResumeEditorViewModel.coreStepCount;
      final vm = context.read<ResumeEditorViewModel>();
      _moveFocusInOrder(_customKeyboardFocusOrderForIndex(vm, i), delta: -1);
    }
  }

  void _focusNextKeyboardField(int currentStep) {
    if (currentStep == 0) {
      _movePersonalFieldFocus(delta: 1);
      return;
    }
    if (currentStep == 4) {
      _moveFocusInOrder(_projectKeyboardFocusOrder, delta: 1);
      return;
    }
    if (currentStep >= ResumeEditorViewModel.coreStepCount) {
      final i = currentStep - ResumeEditorViewModel.coreStepCount;
      final vm = context.read<ResumeEditorViewModel>();
      _moveFocusInOrder(_customKeyboardFocusOrderForIndex(vm, i), delta: 1);
    }
  }

  List<FocusNode> _customKeyboardFocusOrderForIndex(
    ResumeEditorViewModel vm,
    int customIndex,
  ) {
    final item = vm.resume.customSections[customIndex];
    if (item.layoutMode == CustomSectionLayoutMode.summary) {
      return [
        _focusNodeForExtendedKeyboardField(
          'custom-section-content-$customIndex',
        ),
      ];
    }
    return [
      for (var i = 0; i < item.bullets.length; i++)
        _focusNodeForExtendedKeyboardField(
          'custom-section-bullet-$customIndex-$i',
        ),
    ];
  }

  void _movePersonalFieldFocus({required int delta}) {
    final currentIndex = _personalKeyboardFocusOrder.indexWhere(
      (node) => node.hasFocus,
    );
    if (currentIndex < 0) {
      return;
    }

    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= _personalKeyboardFocusOrder.length) {
      return;
    }

    final target = _personalKeyboardFocusOrder[nextIndex];
    target.requestFocus();
    _scheduleEnsureVisible(target.context ?? context);
  }

  void _moveFocusInOrder(List<FocusNode> orderedNodes, {required int delta}) {
    final currentIndex = orderedNodes.indexWhere((node) => node.hasFocus);
    if (currentIndex < 0) {
      return;
    }

    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= orderedNodes.length) {
      return;
    }

    final target = orderedNodes[nextIndex];
    target.requestFocus();
    _scheduleEnsureVisible(target.context ?? context);
  }

  Widget _buildEducationStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: 'Education',
      subtitle:
          'Include your degree, institution, and study timeline.',
      titleTrailing: _resumeSectionVisibilityLead(
        viewModel: viewModel,
        included: viewModel.resume.includeEducationInResume,
        sectionName: 'Education',
        setIncluded: viewModel.setIncludeEducationInResume,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_resumeOrderNudgeDismissed &&
              viewModel.resume.education.length > 1) ...[
            const SizedBox(height: 12),
            _HintBanner(
              title: 'Resume order',
              body:
                  'Entries stay in this order. Use arrows to move your strongest role to top.',
              compact: true,
              onDismiss: _onDismissResumeOrderNudge,
            ),
            const SizedBox(height: 10),
          ],
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
                                style: _resumeOrderHintStyle(context),
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
                            tooltip: 'Delete education entry',
                            onPressed: viewModel.isBusy
                                ? null
                                : () {
                                    _confirmRemoval(
                                      title: 'Delete education entry?',
                                      message:
                                          'This will remove this school and degree from your resume. This cannot be undone.',
                                      onConfirm: () =>
                                          viewModel.removeEducation(index),
                                    );
                                  },
                            icon: const ImageIcon(
                              AssetImage('assets/fonts/delete.png'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          label: 'Institution',
                          value: item.institution,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) => viewModel.updateEducation(
                            index,
                            (current) => current.copyWith(institution: value),
                          ),
                        ),
                        _SyncTextField(
                          label: 'Degree',
                          value: item.degree,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) => viewModel.updateEducation(
                            index,
                            (current) => current.copyWith(degree: value),
                          ),
                        ),
                        _PickerField(
                          key: Key('education-start-date-$index'),
                          label: 'Start year',
                          value: item.startDate,
                          hintText: 'Select year',
                          onTap: () => _pickEducationDate(
                            index: index,
                            isEndDate: false,
                            currentValue: item.startDate,
                          ),
                        ),
                        _PickerField(
                          key: Key('education-end-date-$index'),
                          label: 'End year',
                          value: item.endDate,
                          hintText: 'Select year',
                          onTap: () => _pickEducationDate(
                            index: index,
                            isEndDate: true,
                            currentValue: item.endDate,
                          ),
                        ),
                        _SyncTextField(
                          label: 'Marks / score (%)',
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
          'Add job-specific tools and keywords. Suggest skills prioritizes each work experience role, then descriptions and bullets, then your target job title and the rest of the resume.',
      titleTrailing: _resumeSectionVisibilityLead(
        viewModel: viewModel,
        included: viewModel.resume.includeSkillsInResume,
        sectionName: 'Skills',
        setIncluded: viewModel.setIncludeSkillsInResume,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            '${viewModel.resume.skills.length} skills',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          RawAutocomplete<String>(
            focusNode: _skillFocusNode,
            textEditingController: _skillController,
            displayStringForOption: (skill) => skill,
            optionsBuilder: (textEditingValue) {
              return skillSuggestionsForQuery(
                textEditingValue.text,
                excludeLowercase: viewModel.resume.skills
                    .map((s) => s.toLowerCase())
                    .toSet(),
              );
            },
            onSelected: (selection) {
              final added = viewModel.addSkill(selection);
              if (added) {
                _skillController.clear();
              }
            },
            optionsViewBuilder: (context, onSelected, options) {
              final list = options.toList();
              if (list.isEmpty) {
                return const SizedBox.shrink();
              }
              final theme = Theme.of(context);
              final onPopup = theme.brightness == Brightness.dark
                  ? const Color(0xFF1C1B1F)
                  : theme.colorScheme.onSurface;
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  surfaceTintColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, index) {
                        final option = list[index];
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              option,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: onPopup,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (context, textEditingController, focusNode, _) {
              final inset = MediaQuery.viewInsetsOf(context).bottom;
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addSkillFromInput(),
                scrollPadding: EdgeInsets.only(
                  left: 20,
                  top: 20,
                  right: 20,
                  bottom: inset + 120,
                ),
                decoration: InputDecoration(
                  labelText: 'Add a skill',
                  helperText:
                      'Type to see suggestions, or add your own keywords',
                  helperStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.35,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _addSkillFromInput,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: viewModel.isBusy ? null : _suggestSkills,
                style: _mediumTonalButtonStyle(context),
                icon: const Icon(Icons.psychology_alt_outlined),
                label: const Text('Suggest skills'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (viewModel.resume.skills.isNotEmpty)
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
      titleTrailing: _resumeSectionVisibilityLead(
        viewModel: viewModel,
        included: viewModel.resume.includeProjectsInResume,
        sectionName: 'Projects',
        setIncluded: viewModel.setIncludeProjectsInResume,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_resumeOrderNudgeDismissed &&
              viewModel.resume.projects.length > 1) ...[
            const SizedBox(height: 12),
            _HintBanner(
              title: 'Resume order',
              body:
                  'Entries stay in this order. Use arrows to move your strongest role to top.',
              compact: true,
              onDismiss: _onDismissResumeOrderNudge,
            ),
            const SizedBox(height: 10),
          ],
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Project ${index + 1}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _resumeOrderLabel(index),
                                style: _resumeOrderHintStyle(context),
                              ),
                            ],
                          ),
                        ),
                        if (viewModel.resume.projects.length > 1) ...[
                          IconButton.filledTonal(
                            tooltip: 'Move project up',
                            onPressed: index == 0
                                ? null
                                : () =>
                                      _moveProject(index: index, moveUp: true),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Move project down',
                            onPressed:
                                index == viewModel.resume.projects.length - 1
                                ? null
                                : () =>
                                      _moveProject(index: index, moveUp: false),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                          IconButton(
                            tooltip: 'Delete project',
                            onPressed: viewModel.isBusy
                                ? null
                                : () {
                                    _confirmRemoval(
                                      title: 'Delete project?',
                                      message:
                                          'This will remove this project and all of its bullet points. This cannot be undone.',
                                      onConfirm: () =>
                                          viewModel.removeProject(index),
                                    );
                                  },
                            icon: const ImageIcon(
                              AssetImage('assets/fonts/delete.png'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          label: 'Project title',
                          value: item.title,
                          textCapitalization: TextCapitalization.sentences,
                          focusNode: _focusNodeForExtendedKeyboardField(
                            'project-title-$index',
                          ),
                          onChanged: (value) => viewModel.updateProject(
                            index,
                            (current) => current.copyWith(title: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...((item.bullets.isEmpty ? [''] : item.bullets)
                        .asMap()
                        .entries
                        .map((entry) {
                          final bi = entry.key;
                          final text = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _SyncTextField(
                                    key: Key('project-bullet-$index-$bi'),
                                    label: 'Bullet ${bi + 1}',
                                    value: text,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    hintText: 'Enter a bullet point',
                                    fullWidth: true,
                                    minLines: 1,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    focusNode: _focusNodeForExtendedKeyboardField(
                                      'project-bullet-$index-$bi',
                                    ),
                                    onChanged: (value) =>
                                        viewModel.updateProject(
                                          index,
                                          (current) {
                                            final next = current.bullets.isEmpty
                                                ? ['']
                                                : List<String>.from(
                                                    current.bullets,
                                                  );
                                            if (bi < next.length) {
                                              next[bi] = value;
                                            }
                                            return current.copyWith(
                                              bullets: next,
                                            );
                                          },
                                        ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove bullet',
                                  onPressed: viewModel.isBusy
                                      ? null
                                      : () {
                                          _confirmRemoval(
                                            title: 'Remove bullet?',
                                            message:
                                                'This bullet will be removed from this project.',
                                            onConfirm: () {
                                              viewModel.updateProject(
                                                index,
                                                (current) {
                                                  final next =
                                                      current.bullets.isEmpty
                                                      ? <String>[]
                                                      : List<String>.from(
                                                          current.bullets,
                                                        );
                                                  if (bi < next.length) {
                                                    next.removeAt(bi);
                                                  }
                                                  return current.copyWith(
                                                    bullets: next,
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                  icon: const ImageIcon(
                                    AssetImage('assets/fonts/delete.png'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: viewModel.isBusy
                            ? null
                            : () {
                                viewModel.updateProject(
                                  index,
                                  (current) => current.copyWith(
                                    bullets: [...current.bullets, ''],
                                  ),
                                );
                              },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add bullet point'),
                      ),
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

  Widget _buildSingleCustomSectionStep(
    ResumeEditorViewModel viewModel,
    int index,
  ) {
    final item = viewModel.resume.customSections[index];

    return _StepSurface(
      title: _customSectionStepTitle(item, index),
      subtitle: '',
      titleTrailing: IconButton(
        tooltip: 'Remove section',
        style: IconButton.styleFrom(
          padding: const EdgeInsetsDirectional.only(start: 6, end: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        onPressed: viewModel.isBusy
            ? null
            : () async {
                await _confirmRemoveCustomSection(index);
              },
        icon: const ImageIcon(
          AssetImage('assets/fonts/delete.png'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          RadioGroup<CustomSectionLayoutMode>(
                  groupValue: item.layoutMode,
                  onChanged: (CustomSectionLayoutMode? value) {
                    if (value == null || viewModel.isBusy) {
                      return;
                    }
                    viewModel.updateCustomSection(
                      index,
                      (c) {
                        if (value == CustomSectionLayoutMode.bullets &&
                            c.bullets.isEmpty) {
                          return c.copyWith(
                            layoutMode: value,
                            bullets: [''],
                          );
                        }
                        return c.copyWith(layoutMode: value);
                      },
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RadioListTile<CustomSectionLayoutMode>(
                          value: CustomSectionLayoutMode.summary,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          horizontalTitleGap: 4,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          title: Text(
                            'Summary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<CustomSectionLayoutMode>(
                          value: CustomSectionLayoutMode.bullets,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          horizontalTitleGap: 4,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          title: Text(
                            'Bullet points',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (item.layoutMode == CustomSectionLayoutMode.summary)
                  _ResponsiveFieldGroup(
                    children: [
                      _SyncTextField(
                        key: Key('custom-section-content-$index'),
                        label: 'Summary',
                        value: item.content,
                        textCapitalization: TextCapitalization.sentences,
                        hintText:
                            'Write the section as a short paragraph for your resume.',
                        minLines: 5,
                        maxLines: null,
                        fullWidth: true,
                        focusNode: _focusNodeForExtendedKeyboardField(
                          'custom-section-content-$index',
                        ),
                        onChanged: (value) => viewModel.updateCustomSection(
                          index,
                          (current) => current.copyWith(content: value),
                        ),
                      ),
                    ],
                  )
                else ...[
                  ...item.bullets.asMap().entries.map((entry) {
                    final bi = entry.key;
                    final text = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SyncTextField(
                              key: Key('custom-section-bullet-$index-$bi'),
                              label: 'Bullet ${bi + 1}',
                              value: text,
                              textCapitalization: TextCapitalization.sentences,
                              hintText: 'Enter a bullet point',
                              fullWidth: true,
                              minLines: 1,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              focusNode: _focusNodeForExtendedKeyboardField(
                                'custom-section-bullet-$index-$bi',
                              ),
                              onChanged: (value) =>
                                  viewModel.updateCustomSection(
                                index,
                                (c) {
                                  final next = List<String>.from(c.bullets);
                                  if (bi < next.length) {
                                    next[bi] = value;
                                  }
                                  return c.copyWith(bullets: next);
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove bullet',
                            onPressed: viewModel.isBusy
                                ? null
                                : () {
                                    viewModel.updateCustomSection(
                                      index,
                                      (c) {
                                        final next = List<String>.from(
                                          c.bullets,
                                        )..removeAt(bi);
                                        return c.copyWith(bullets: next);
                                      },
                                    );
                                  },
                            icon: const ImageIcon(
                              AssetImage('assets/fonts/delete.png'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: viewModel.isBusy
                          ? null
                          : () {
                              viewModel.updateCustomSection(
                                index,
                                (c) => c.copyWith(
                                  bullets: [...c.bullets, ''],
                                ),
                              );
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add bullet point'),
                    ),
                  ),
                ],
        ],
      ),
    );
  }
}

String _customSectionStepTitle(CustomSectionItem item, int index) {
  final t = item.title.trim();
  if (t.isEmpty) {
    return 'Category ${index + 1}';
  }
  return t;
}

String _resumeCategoryChipLabel(CustomSectionItem item, int index) {
  final t = item.title.trim();
  final raw = t.isEmpty ? 'Category ${index + 1}' : t;
  if (raw.length > 22) {
    return '${raw.substring(0, 21)}…';
  }
  return raw;
}

class _StepProgressHeader extends StatefulWidget {
  const _StepProgressHeader({
    required this.currentStep,
    required this.totalStepCount,
    required this.customSections,
    required this.onSelectStep,
    required this.onAddCategory,
  });

  final int currentStep;
  final int totalStepCount;
  final List<CustomSectionItem> customSections;
  final ValueChanged<int> onSelectStep;
  final VoidCallback onAddCategory;

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
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.customSections.length != widget.customSections.length) {
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
        duration: _ResumeBuilderScreenState._stepScrollAnimationDuration,
        curve: _ResumeBuilderScreenState._stepAnimationCurve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalStepCount;
    final denom = total <= 0 ? 1 : total;
    final progress = (widget.currentStep + 1) / denom;

    final chipStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
    );

    final rowChildren = <Widget>[];

    for (var i = 0; i < ResumeEditorViewModel.coreStepCount; i++) {
      rowChildren.add(
        Padding(
          key: _chipKeyFor(i),
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(
              ResumeEditorViewModel.coreStepTitles[i],
              style: chipStyle,
            ),
            selected: widget.currentStep == i,
            onSelected: (_) => widget.onSelectStep(i),
          ),
        ),
      );
    }

    for (var j = 0; j < widget.customSections.length; j++) {
      final step = ResumeEditorViewModel.coreStepCount + j;
      rowChildren.add(
        Padding(
          key: _chipKeyFor(step),
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(
              _resumeCategoryChipLabel(widget.customSections[j], j),
              style: chipStyle,
            ),
            selected: widget.currentStep == step,
            onSelected: (_) => widget.onSelectStep(step),
          ),
        ),
      );
    }

    final addIconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    rowChildren.add(
      Padding(
        padding: EdgeInsets.zero,
        child: ChoiceChip(
          avatar: Icon(Icons.add_rounded, size: 24, color: addIconColor),
          label: Text('Add', style: chipStyle),
          selected: false,
          onSelected: (_) => widget.onAddCategory(),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${widget.currentStep + 1}/$total',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              key: const Key('step-progress-scroll'),
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: rowChildren),
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
              child: Text(isLastStep ? 'Preview' : 'Continue'),
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
    this.titleTrailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (titleTrailing == null)
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    titleTrailing!,
                  ],
                ),
              ),
            const SizedBox(height: 8),
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
    Future<void>.delayed(const Duration(milliseconds: 180), () {
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
      // Keep focused field clearly above iOS keyboard + accessory toolbar.
      final visibleBottom =
          MediaQuery.sizeOf(context).height - keyboardInset - 96;
      final overlap = fieldBottom - visibleBottom;

      if (overlap <= 0) {
        return;
      }

      final position = scrollable.position;
      final targetOffset = (position.pixels + overlap + 28)
          .clamp(0.0, position.maxScrollExtent)
          .toDouble();

      if ((targetOffset - position.pixels).abs() < 1) {
        return;
      }

      position.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    });
  });
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
    this.minLines,
    this.keyboardType,
    this.focusNode,
    this.hintText,
    this.textInputAction,
    this.onSubmitted,
    this.fullWidth = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final String? hintText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool fullWidth;
  final TextCapitalization textCapitalization;

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
    if (mounted) {
      setState(() {});
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      scrollPadding: EdgeInsets.only(
        left: 20,
        top: 20,
        right: 20,
        bottom: keyboardInset + 120,
      ),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
      ),
    );
  }
}

class _ProfileLinkField extends StatefulWidget {
  const _ProfileLinkField({
    required this.label,
    required this.value,
    required this.basePrefix,
    required this.hintText,
    required this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String value;
  final String basePrefix;
  final String hintText;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_ProfileLinkField> createState() => _ProfileLinkFieldState();
}

class _ProfileLinkFieldState extends State<_ProfileLinkField> {
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

  @override
  void didUpdateWidget(covariant _ProfileLinkField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _scheduleEnsureVisible(context);
      if (_controller.text.trim().isEmpty) {
        _controller.value = TextEditingValue(
          text: widget.basePrefix,
          selection: TextSelection.collapsed(offset: widget.basePrefix.length),
        );
      }
    }
  }

  String _normalizedValue(String rawInput) {
    final raw = rawInput.trim();
    if (raw.isEmpty || raw == widget.basePrefix) {
      return '';
    }

    final withoutAt = raw.startsWith('@') ? raw.substring(1) : raw;
    if (withoutAt.startsWith('http://') || withoutAt.startsWith('https://')) {
      return withoutAt;
    }

    if (withoutAt.startsWith('www.')) {
      return 'https://$withoutAt';
    }

    final baseHost = Uri.parse(widget.basePrefix).host;
    if (withoutAt.contains(baseHost)) {
      return 'https://${withoutAt.replaceFirst(RegExp(r'^https?://'), '')}';
    }

    return '${widget.basePrefix}$withoutAt';
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.url,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      scrollPadding: EdgeInsets.only(
        left: 20,
        top: 20,
        right: 20,
        bottom: keyboardInset + 120,
      ),
      onChanged: (value) {
        widget.onChanged(_normalizedValue(value));
      },
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
      ),
    );
  }
}

class _PhoneWithCountryCodeField extends StatefulWidget {
  const _PhoneWithCountryCodeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PhoneWithCountryCodeField> createState() =>
      _PhoneWithCountryCodeFieldState();
}

class _PhoneWithCountryCodeFieldState
    extends State<_PhoneWithCountryCodeField> {
  static const List<_CountryDialCode> _countries = [
    _CountryDialCode('Afghanistan', '+93'),
    _CountryDialCode('Albania', '+355'),
    _CountryDialCode('Algeria', '+213'),
    _CountryDialCode('Argentina', '+54'),
    _CountryDialCode('Armenia', '+374'),
    _CountryDialCode('Australia', '+61'),
    _CountryDialCode('Austria', '+43'),
    _CountryDialCode('Azerbaijan', '+994'),
    _CountryDialCode('Bahrain', '+973'),
    _CountryDialCode('Bangladesh', '+880'),
    _CountryDialCode('Belarus', '+375'),
    _CountryDialCode('Belgium', '+32'),
    _CountryDialCode('Bhutan', '+975'),
    _CountryDialCode('Bolivia', '+591'),
    _CountryDialCode('Bosnia and Herzegovina', '+387'),
    _CountryDialCode('Brazil', '+55'),
    _CountryDialCode('Bulgaria', '+359'),
    _CountryDialCode('Cambodia', '+855'),
    _CountryDialCode('Canada', '+1'),
    _CountryDialCode('Chile', '+56'),
    _CountryDialCode('China', '+86'),
    _CountryDialCode('Colombia', '+57'),
    _CountryDialCode('Costa Rica', '+506'),
    _CountryDialCode('Croatia', '+385'),
    _CountryDialCode('Cyprus', '+357'),
    _CountryDialCode('Czech Republic', '+420'),
    _CountryDialCode('Denmark', '+45'),
    _CountryDialCode('Dominican Republic', '+1'),
    _CountryDialCode('Ecuador', '+593'),
    _CountryDialCode('Egypt', '+20'),
    _CountryDialCode('Estonia', '+372'),
    _CountryDialCode('Ethiopia', '+251'),
    _CountryDialCode('Finland', '+358'),
    _CountryDialCode('France', '+33'),
    _CountryDialCode('Georgia', '+995'),
    _CountryDialCode('Germany', '+49'),
    _CountryDialCode('Ghana', '+233'),
    _CountryDialCode('Greece', '+30'),
    _CountryDialCode('Guatemala', '+502'),
    _CountryDialCode('Hong Kong', '+852'),
    _CountryDialCode('Hungary', '+36'),
    _CountryDialCode('Iceland', '+354'),
    _CountryDialCode('India', '+91'),
    _CountryDialCode('Indonesia', '+62'),
    _CountryDialCode('Iran', '+98'),
    _CountryDialCode('Iraq', '+964'),
    _CountryDialCode('Ireland', '+353'),
    _CountryDialCode('Israel', '+972'),
    _CountryDialCode('Italy', '+39'),
    _CountryDialCode('Japan', '+81'),
    _CountryDialCode('Jordan', '+962'),
    _CountryDialCode('Kazakhstan', '+7'),
    _CountryDialCode('Kenya', '+254'),
    _CountryDialCode('Kuwait', '+965'),
    _CountryDialCode('Kyrgyzstan', '+996'),
    _CountryDialCode('Laos', '+856'),
    _CountryDialCode('Latvia', '+371'),
    _CountryDialCode('Lebanon', '+961'),
    _CountryDialCode('Lithuania', '+370'),
    _CountryDialCode('Luxembourg', '+352'),
    _CountryDialCode('Malaysia', '+60'),
    _CountryDialCode('Maldives', '+960'),
    _CountryDialCode('Mexico', '+52'),
    _CountryDialCode('Moldova', '+373'),
    _CountryDialCode('Mongolia', '+976'),
    _CountryDialCode('Morocco', '+212'),
    _CountryDialCode('Myanmar', '+95'),
    _CountryDialCode('Nepal', '+977'),
    _CountryDialCode('Netherlands', '+31'),
    _CountryDialCode('New Zealand', '+64'),
    _CountryDialCode('Nigeria', '+234'),
    _CountryDialCode('North Macedonia', '+389'),
    _CountryDialCode('Norway', '+47'),
    _CountryDialCode('Oman', '+968'),
    _CountryDialCode('Pakistan', '+92'),
    _CountryDialCode('Panama', '+507'),
    _CountryDialCode('Paraguay', '+595'),
    _CountryDialCode('Peru', '+51'),
    _CountryDialCode('Philippines', '+63'),
    _CountryDialCode('Poland', '+48'),
    _CountryDialCode('Portugal', '+351'),
    _CountryDialCode('Qatar', '+974'),
    _CountryDialCode('Romania', '+40'),
    _CountryDialCode('Russia', '+7'),
    _CountryDialCode('Saudi Arabia', '+966'),
    _CountryDialCode('Serbia', '+381'),
    _CountryDialCode('Singapore', '+65'),
    _CountryDialCode('Slovakia', '+421'),
    _CountryDialCode('Slovenia', '+386'),
    _CountryDialCode('South Africa', '+27'),
    _CountryDialCode('South Korea', '+82'),
    _CountryDialCode('Spain', '+34'),
    _CountryDialCode('Sri Lanka', '+94'),
    _CountryDialCode('Sweden', '+46'),
    _CountryDialCode('Switzerland', '+41'),
    _CountryDialCode('Taiwan', '+886'),
    _CountryDialCode('Tanzania', '+255'),
    _CountryDialCode('Thailand', '+66'),
    _CountryDialCode('Tunisia', '+216'),
    _CountryDialCode('Turkey', '+90'),
    _CountryDialCode('Uganda', '+256'),
    _CountryDialCode('Ukraine', '+380'),
    _CountryDialCode('United Arab Emirates', '+971'),
    _CountryDialCode('United Kingdom', '+44'),
    _CountryDialCode('United States', '+1'),
    _CountryDialCode('Uruguay', '+598'),
    _CountryDialCode('Uzbekistan', '+998'),
    _CountryDialCode('Venezuela', '+58'),
    _CountryDialCode('Vietnam', '+84'),
    _CountryDialCode('Yemen', '+967'),
    _CountryDialCode('Zambia', '+260'),
    _CountryDialCode('Zimbabwe', '+263'),
  ];

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  late String _selectedCountryKey;

  @override
  void initState() {
    super.initState();
    final parsed = _parsePhone(widget.value);
    _selectedCountryKey = parsed.$1;
    _controller = TextEditingController(text: parsed.$2);
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _scheduleEnsureVisible(context);
    }
  }

  (String, String) _parsePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (_defaultCountryKey(), '');
    }

    final match = RegExp(r'^(\+\d+)\s*(.*)$').firstMatch(trimmed);
    if (match == null) {
      return (_defaultCountryKey(), trimmed);
    }

    final code = match.group(1) ?? '+1';
    final number = match.group(2) ?? '';
    final matchedCountry = _countries.firstWhere(
      (item) => item.code == code,
      orElse: () => const _CountryDialCode('United States', '+1'),
    );
    return (_countryKey(matchedCountry), number);
  }

  void _emitValue() {
    final number = _controller.text.trim();
    if (number.isEmpty) {
      widget.onChanged('');
      return;
    }
    widget.onChanged('${_selectedCountry.code} $number');
  }

  @override
  void didUpdateWidget(covariant _PhoneWithCountryCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      final parsed = _parsePhone(widget.value);
      _selectedCountryKey = parsed.$1;
      _controller.text = parsed.$2;
    }
  }

  String _countryKey(_CountryDialCode country) =>
      '${country.name}|${country.code}';

  String _defaultCountryKey() {
    final localeCountry = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .countryCode
        ?.toUpperCase();
    final dialCode = _dialCodeFromCountryCode(localeCountry);
    final matched = _countries.firstWhere(
      (item) => item.code == dialCode,
      orElse: () => const _CountryDialCode('United States', '+1'),
    );
    return _countryKey(matched);
  }

  String _dialCodeFromCountryCode(String? code) {
    return switch (code) {
      'IN' => '+91',
      'US' => '+1',
      'CA' => '+1',
      'GB' => '+44',
      'AE' => '+971',
      'AU' => '+61',
      'SG' => '+65',
      'DE' => '+49',
      'FR' => '+33',
      'IT' => '+39',
      'ES' => '+34',
      'NL' => '+31',
      'SE' => '+46',
      'NO' => '+47',
      'DK' => '+45',
      'FI' => '+358',
      'CH' => '+41',
      'AT' => '+43',
      'IE' => '+353',
      'NZ' => '+64',
      'JP' => '+81',
      'KR' => '+82',
      'CN' => '+86',
      'HK' => '+852',
      'TW' => '+886',
      'MY' => '+60',
      'ID' => '+62',
      'TH' => '+66',
      'VN' => '+84',
      'PH' => '+63',
      'PK' => '+92',
      'BD' => '+880',
      'LK' => '+94',
      'NP' => '+977',
      'SA' => '+966',
      'QA' => '+974',
      'KW' => '+965',
      'OM' => '+968',
      'EG' => '+20',
      'ZA' => '+27',
      'NG' => '+234',
      'KE' => '+254',
      'BR' => '+55',
      'MX' => '+52',
      'AR' => '+54',
      'CO' => '+57',
      'CL' => '+56',
      'PE' => '+51',
      'TR' => '+90',
      'RU' => '+7',
      _ => '+1',
    };
  }

  _CountryDialCode get _selectedCountry => _countries.firstWhere(
    (item) => _countryKey(item) == _selectedCountryKey,
    orElse: () => const _CountryDialCode('United States', '+1'),
  );

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
    final inputStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.phone,
      style: inputStyle,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: (_) => _emitValue(),
      scrollPadding: EdgeInsets.only(
        left: 20,
        top: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 120,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: _focusNode.hasFocus ? '' : 'Phone number',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryKey,
              isDense: true,
              style: inputStyle,
              dropdownColor: Colors.white,
              menuMaxHeight: 340,
              menuWidth: 280,
              items: _countries
                  .map(
                    (country) => DropdownMenuItem<String>(
                      value: _countryKey(country),
                      child: Text(
                        '${country.name} (${country.code})',
                        style: inputStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (context) => _countries
                  .map(
                    (country) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedCountry.code,
                        style: inputStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedCountryKey = value);
                _emitValue();
              },
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 101,
          maxWidth: 101,
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      ),
    );
  }
}

class _CountryDialCode {
  const _CountryDialCode(this.name, this.code);

  final String name;
  final String code;
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({
    required this.title,
    required this.body,
    this.compact = false,
    this.onDismiss,
  });

  final String title;
  final String body;
  final bool compact;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalPadding = compact ? 8.0 : 12.0;
    final verticalPadding = compact ? 6.0 : 10.0;
    final radius = compact ? 10.0 : 14.0;
    final iconSize = compact ? 14.0 : 18.0;
    final spacing = compact ? 6.0 : 8.0;
    final bodySpacing = compact ? 1.0 : 2.0;
    final dismissReserve = onDismiss != null ? 26.0 : 0.0;
    final titleStyle = compact
        ? theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          )
        : theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = compact
        ? theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.2)
        : theme.textTheme.bodySmall;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding + dismissReserve,
                verticalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: iconSize,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: titleStyle),
                        SizedBox(height: bodySpacing),
                        Text(body, style: bodyStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              Positioned(
                top: 2,
                right: 2,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Dismiss',
                  icon: Icon(
                    Icons.close_rounded,
                    size: compact ? 18 : 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onDismiss,
                ),
              ),
          ],
        ),
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

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
