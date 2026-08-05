import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/bottom_sheet_insets.dart';
import '../../core/models/resume_builder_section_order.dart';
import '../../core/services/analytics_events.dart';
import '../../core/services/profile_image_storage.dart';
import '../../core/models/resume_models.dart';
import '../../core/skill_autocomplete_suggestions.dart';
import '../../core/services/app_preferences.dart';
import 'resume_preview_screen.dart';
import '../shared/resume_preview_card.dart';
import '../shared/resume_share_format_sheet.dart';
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
  static const double _calendarIconStroke = 1.65;
  static const double _entryDividerHorizontalPadding = 20;

  final _skillController = TextEditingController();
  final _skillFocusNode = FocusNode();
  final _skillInputKey = GlobalKey();
  static const double _skillSuggestionMaxHeight = 280;
  final Map<int, TextEditingController> _groupSkillControllers = {};
  final Map<int, FocusNode> _groupSkillFocusNodes = {};
  final Map<int, GlobalKey> _groupSkillInputKeys = {};
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
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_skillFocusNode.hasFocus) {
      final fieldContext = _skillInputKey.currentContext;
      if (fieldContext != null) {
        _scheduleEnsureVisible(
          fieldContext,
          extraVisibleHeight: _skillSuggestionMaxHeight,
          alignNearTop: true,
        );
      }
    }
  }

  FocusNode _groupSkillFocusNode(int index) {
    return _groupSkillFocusNodes.putIfAbsent(index, () {
      final node = FocusNode();
      node.addListener(() {
        if (!mounted) {
          return;
        }
        final currentIndex = _groupSkillFocusNodes.entries
            .where((entry) => identical(entry.value, node))
            .map((entry) => entry.key)
            .firstOrNull;
        if (currentIndex != null) {
          _handleGroupSkillFocusChange(currentIndex);
        }
      });
      return node;
    });
  }

  GlobalKey _groupSkillInputKey(int index) {
    return _groupSkillInputKeys.putIfAbsent(index, GlobalKey.new);
  }

  void _handleGroupSkillFocusChange(int index) {
    if (!mounted) {
      return;
    }
    setState(() {});
    final node = _groupSkillFocusNodes[index];
    if (node == null || !node.hasFocus) {
      return;
    }
    final fieldContext = _groupSkillInputKeys[index]?.currentContext;
    if (fieldContext != null) {
      _scheduleEnsureVisible(
        fieldContext,
        extraVisibleHeight: _skillSuggestionMaxHeight,
        alignNearTop: true,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefsHydrated) {
      _prefsHydrated = true;
      _resumeOrderNudgeDismissed = context
          .read<AppPreferences>()
          .resumeOrderNudgeDismissed;
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
    for (final controller in _groupSkillControllers.values) {
      controller.dispose();
    }
    for (final node in _groupSkillFocusNodes.values) {
      node.dispose();
    }
    _groupSkillFocusNodes.clear();
    _groupSkillInputKeys.clear();
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
          child: const ResumePreviewScreen(backPopsToHome: true),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (targetStep == null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    _goToStep(targetStep);
  }

  Future<void> _downloadResume() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    final path = await viewModel.downloadPdf();
    if (!mounted) {
      return;
    }

    await logAnalyticsEvent(
      context,
      AnalyticsEvents.resumeExportedPdf,
      parameters: {
        ...resumeTemplateAnalytics(viewModel.resume.template.userFacingTemplate),
        'source': 'resume_builder',
      },
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.pdfSavedTo(path))));
  }

  Future<void> _shareResume() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    final format = await showResumeShareFormatSheet(context);
    if (!mounted || format == null) {
      return;
    }

    if (format == ResumeShareFormat.pdf) {
      await viewModel.sharePdf();
    } else {
      await viewModel.shareDocx();
    }
    if (!mounted) {
      return;
    }
    await logAnalyticsEvent(
      context,
      format == ResumeShareFormat.pdf
          ? AnalyticsEvents.resumeSharedPdf
          : AnalyticsEvents.resumeSharedDocx,
      parameters: {
        ...resumeTemplateAnalytics(viewModel.resume.template.userFacingTemplate),
        'source': 'resume_builder',
        'format': format.name,
      },
    );
  }

  Future<void> _printResume() async {
    await context.read<ResumeEditorViewModel>().printPdf();
  }

  Future<void> _generateSummary() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    final hadSummary = viewModel.resume.summary.trim().isNotEmpty;
    await viewModel.generateSummary();
    if (!mounted) {
      return;
    }

    final summary =
        context.read<ResumeEditorViewModel>().resume.summary.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          summary.isEmpty
              ? context.l10n.unableToGenerateSummary
              : hadSummary
              ? context.l10n.summaryUpdated
              : context.l10n.summaryAdded,
        ),
      ),
    );
  }

  void _addSkillFromInput() {
    if (!mounted) {
      return;
    }
    final viewModel = context.read<ResumeEditorViewModel>();
    final trimmed = _skillController.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (viewModel.resume.skills.any(
      (s) => s.toLowerCase() == trimmed.toLowerCase(),
    )) {
      _showDuplicateSkillMessage();
      return;
    }
    final added = viewModel.addSkill(_skillController.text);
    if (added) {
      _skillController.clear();
      setState(() {});
    }
  }

  TextEditingController _groupSkillController(int index) {
    return _groupSkillControllers.putIfAbsent(
      index,
      TextEditingController.new,
    );
  }

  void _addSkillToGroupFromInput(int index) {
    if (!mounted) {
      return;
    }
    final viewModel = context.read<ResumeEditorViewModel>();
    final controller = _groupSkillController(index);
    final trimmed = controller.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final added = viewModel.addSkillToGroup(index, trimmed);
    if (added) {
      controller.clear();
      setState(() {});
    } else {
      _showDuplicateSkillMessage();
    }
  }

  void _reindexGroupSkillControllersAfterRemove(int removedIndex) {
    final nextControllers = <int, TextEditingController>{};
    for (final entry in _groupSkillControllers.entries) {
      if (entry.key == removedIndex) {
        entry.value.dispose();
        continue;
      }
      final newKey = entry.key > removedIndex ? entry.key - 1 : entry.key;
      nextControllers[newKey] = entry.value;
    }
    _groupSkillControllers
      ..clear()
      ..addAll(nextControllers);

    // Recreate focus/key maps so listener indexes stay correct.
    for (final node in _groupSkillFocusNodes.values) {
      node.dispose();
    }
    _groupSkillFocusNodes.clear();
    _groupSkillInputKeys.clear();
  }

  void _showDuplicateSkillMessage() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.skillAlreadyInList)),
    );
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
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.actionDelete),
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

  ButtonStyle _secondaryActionButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fill = primary.withValues(alpha: 0.16);
    return TextButton.styleFrom(
      foregroundColor: primary,
      backgroundColor: fill,
      disabledForegroundColor: primary.withValues(alpha: 0.45),
      disabledBackgroundColor: fill.withValues(alpha: 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      minimumSize: const Size(0, 46),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontFamily: 'Outfit',
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildAddBulletPointButton({required VoidCallback? onPressed}) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextButton.icon(
      onPressed: onPressed,
      style: _secondaryActionButtonStyle(context),
      icon: Icon(Icons.add_rounded, size: 24, color: primary),
      label: Text(context.l10n.addBulletPoint),
    );
  }

  String _resumeOrderLabel(int index) {
    final l10n = context.l10n;
    if (index == 0) {
      return l10n.appearsFirstOnYourResume;
    }
    return l10n.appearsOnYourResumeAt(index + 1);
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
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          title: Text(context.l10n.hideFromResumeTitle),
          content: Text(
            context.l10n.hideFromResumeMessage(sectionName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.hide),
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
        tooltip: included ? context.l10n.hideFromResume : context.l10n.showOnResume,
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
          size: 24,
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
        backgroundColor: Theme.of(context).cardColor,
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
                    leading: IconTheme(
                      data: IconThemeData(color: primaryColor),
                      child: const _ThinCalendarIcon(
                        strokeWidth:
                            _ResumeBuilderScreenState._calendarIconStroke,
                      ),
                    ),
                    title: Text(context.l10n.chooseMonthAndYear),
                    onTap: () =>
                        Navigator.of(context).pop(_EndDateSelection.chooseDate),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.work_history_outlined,
                      color: primaryColor,
                    ),
                    title: Text(context.l10n.present),
                    onTap: () =>
                        Navigator.of(context).pop(_EndDateSelection.present),
                  ),
                  if (currentValue.trim().isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.clear_rounded, color: primaryColor),
                      title: Text(context.l10n.clearDate),
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
          ? context.l10n.selectEndMonthAndYear
          : context.l10n.selectStartMonthAndYear,
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
      title: isEndDate ? context.l10n.selectEndYear : context.l10n.selectStartYear,
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
          backgroundColor: Theme.of(context).cardColor,
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
              backgroundColor: Theme.of(context).cardColor,
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
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.year,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      items: years
                          .map(
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(
                                '$year',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onSurface,
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
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(DateTime(selectedYear, selectedMonth)),
                  child: Text(context.l10n.done),
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

  void _moveSkillGroup({required int index, required bool moveUp}) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final viewModel = context.read<ResumeEditorViewModel>();
      if (moveUp) {
        viewModel.moveSkillGroupUp(index);
        _swapGroupSkillInputState(index, index - 1);
      } else {
        viewModel.moveSkillGroupDown(index);
        _swapGroupSkillInputState(index, index + 1);
      }
      setState(() {});
    });
  }

  void _swapGroupSkillInputState(int a, int b) {
    void swapMap<T>(Map<int, T> map) {
      final va = map[a];
      final vb = map[b];
      if (va != null) {
        map[b] = va;
      } else {
        map.remove(b);
      }
      if (vb != null) {
        map[a] = vb;
      } else {
        map.remove(a);
      }
    }

    swapMap(_groupSkillControllers);
    swapMap(_groupSkillFocusNodes);
    swapMap(_groupSkillInputKeys);
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
    var sectionType = _CustomSectionCreationType.normal;
    final result = await showDialog<_NewCustomSectionDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final typeOptionTitleStyle =
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.normal,
                    );
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              surfaceTintColor: Colors.transparent,
              title: Text(context.l10n.newSection),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: context.l10n.title,
                      hintText: context.l10n.newSectionTitleHint,
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) {
                      final t = controller.text.trim();
                      if (t.isNotEmpty) {
                        Navigator.pop(
                          dialogContext,
                          _NewCustomSectionDialogResult(
                            title: t,
                            type: sectionType,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.type,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  RadioGroup<_CustomSectionCreationType>(
                    groupValue: sectionType,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() => sectionType = value);
                    },
                    child: Column(
                      children: [
                        RadioListTile<_CustomSectionCreationType>(
                          value: _CustomSectionCreationType.normal,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            context.l10n.sectionTypeNormal,
                            style: typeOptionTitleStyle,
                          ),
                          subtitle: Text(
                            context.l10n.sectionTypeNormalSubtitle,
                          ),
                        ),
                        RadioListTile<_CustomSectionCreationType>(
                          value: _CustomSectionCreationType.advance,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            context.l10n.sectionTypeAdvance,
                            style: typeOptionTitleStyle,
                          ),
                          subtitle: Text(
                            context.l10n.sectionTypeAdvanceSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final t = controller.text.trim();
                    if (t.isEmpty) {
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      _NewCustomSectionDialogResult(
                        title: t,
                        type: sectionType,
                      ),
                    );
                  },
                  child: Text(context.l10n.ok),
                ),
              ],
            );
          },
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (!mounted || result == null || result.title.trim().isEmpty) {
      return;
    }

    final viewModel = context.read<ResumeEditorViewModel>();
    viewModel.addCustomSectionWithTitle(
      result.title.trim(),
      layoutMode: result.type == _CustomSectionCreationType.advance
          ? CustomSectionLayoutMode.projects
          : CustomSectionLayoutMode.summary,
    );
    final newIndex = viewModel.resume.customSections.length - 1;
    final targetStep = viewModel.stepForSectionId(
      ResumeBuilderSectionIds.custom(newIndex),
    );
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
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          title: Text(context.l10n.removeSectionTitle),
          content: Text(context.l10n.removeSectionMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.remove),
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
      final persistedPath = await ProfileImageStorage.saveFromXFile(
        picked,
        resumeId: viewModel.resume.id,
      );
      if (!mounted) {
        return;
      }
      if (ProfileImageStorage.isManagedPath(currentPath) &&
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
      await viewModel.saveResume();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.unableToPickImage)),
      );
    }
  }

  Future<void> _clearProfileImage() async {
    final viewModel = context.read<ResumeEditorViewModel>();
    final currentPath = viewModel.resume.profileImagePath.trim();
    await ProfileImageStorage.deleteForResume(
      viewModel.resume.id,
      knownPath: currentPath,
    );
    viewModel.updateResume((resume) => resume.copyWith(profileImagePath: ''));
    await viewModel.saveResume();
  }

  Future<void> _showProfilePhotoOptions({required bool hasImage}) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
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
                  title: Text(context.l10n.camera),
                  onTap: () => Navigator.of(sheetContext).pop('camera'),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: iconColor),
                  title: Text(context.l10n.library),
                  onTap: () => Navigator.of(sheetContext).pop('library'),
                ),
                if (hasImage)
                  ListTile(
                    leading: ImageIcon(
                      const AssetImage('assets/fonts/delete.png'),
                      color: iconColor,
                    ),
                    title: Text(context.l10n.remove),
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
      await _clearProfileImage();
    }
  }

  Widget _buildProfilePhotoPicker(ResumeEditorViewModel viewModel) {
    final imagePath = viewModel.resume.profileImagePath.trim();
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.transparent
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.l10n.profilePhoto,
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
            context.l10n.tapToChangePhoto,
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
            viewModel.isSectionStep(ResumeBuilderSectionIds.projects) &&
            _isProjectKeyboardHideFieldFocused;
        final showCustomKeyboardBar =
            keyboardInset > 0 &&
            viewModel.customIndexAtStep(viewModel.currentStep) != null &&
            _isCustomKeyboardHideFieldFocused;
        final showWorkKeyboardHideButton =
            keyboardInset > 0 &&
            viewModel.isSectionStep(ResumeBuilderSectionIds.work) &&
            _isWorkKeyboardHideFieldFocused;
        final showEducationKeyboardHideButton =
            keyboardInset > 0 &&
            viewModel.isSectionStep(ResumeBuilderSectionIds.education);
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
                      sectionIds: viewModel.orderedSectionIds,
                      customSections: viewModel.resume.customSections,
                      onSelectStep: _goToStep,
                      onAddCategory: _showAddCustomCategoryDialog,
                      onReorderChips: (oldIndex, newIndex) {
                        FocusScope.of(context).unfocus();
                        final selectedBefore = viewModel.currentStep;
                        viewModel.reorderBuilderSectionChips(
                          oldIndex,
                          newIndex,
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) {
                            return;
                          }
                          final target = context
                              .read<ResumeEditorViewModel>()
                              .currentStep;
                          if (_pageController.hasClients &&
                              _pageController.page?.round() != target) {
                            _pageController.jumpToPage(target);
                          } else if (selectedBefore != target) {
                            _goToStep(target);
                          }
                        });
                      },
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
                              tooltip: context.l10n.previousField,
                              onPressed: () => _focusPreviousKeyboardField(
                                viewModel.currentStep,
                              ),
                              icon: const Icon(Icons.keyboard_arrow_up_rounded),
                            ),
                            IconButton(
                              tooltip: context.l10n.nextField,
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
                      tooltip: context.l10n.hideKeyboard,
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
    if (step == ResumeEditorViewModel.personalStepIndex) {
      return _buildPersonalStep(viewModel);
    }
    final sectionId = viewModel.sectionIdAtStep(step);
    if (sectionId == null) {
      return const SizedBox.shrink();
    }
    final customIndex = ResumeBuilderSectionIds.customIndex(sectionId);
    if (customIndex != null) {
      return _buildSingleCustomSectionStep(viewModel, customIndex);
    }
    return switch (sectionId) {
      ResumeBuilderSectionIds.work => _buildWorkStep(viewModel),
      ResumeBuilderSectionIds.education => _buildEducationStep(viewModel),
      ResumeBuilderSectionIds.skills => _buildSkillsStep(viewModel),
      ResumeBuilderSectionIds.projects => _buildProjectsStep(viewModel),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildPersonalStep(ResumeEditorViewModel viewModel) {
    final personalFields = _ResponsiveFieldGroup(
      children: [
        _SyncTextField(
          label: context.l10n.fullName,
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
          label: context.l10n.targetJobTitle,
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
          label: context.l10n.githubLink,
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
          label: context.l10n.linkedinLink,
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
          label: context.l10n.email,
          value: viewModel.resume.email,
          focusNode: _personalFieldFocusNodes[4],
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[5].requestFocus(),
          onChanged: (value) =>
              viewModel.updateResume((resume) => resume.copyWith(email: value)),
        ),
        _PhoneWithCountryCodeField(
          label: context.l10n.phoneNumber,
          value: viewModel.resume.phone,
          focusNode: _personalFieldFocusNodes[5],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _personalFieldFocusNodes[6].requestFocus(),
          onChanged: (value) =>
              viewModel.updateResume((resume) => resume.copyWith(phone: value)),
        ),
        _SyncTextField(
          label: context.l10n.location,
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
          label: context.l10n.websiteOrPortfolio,
          value: viewModel.resume.website,
          focusNode: _personalFieldFocusNodes[7],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _summaryFocusNode.requestFocus(),
          onChanged: (value) => viewModel.updateResume(
            (resume) => resume.copyWith(website: value),
          ),
        ),
        _SyncTextField(
          label: context.l10n.professionalSummary,
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
      ],
    );
    return _StepSurface(
      title: context.l10n.personalInformationTitle,
      subtitle:
          context.l10n.personalInformationSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          personalFields,
          if (viewModel.resume.jobTitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Builder(
              builder: (context) {
                final primary = Theme.of(context).colorScheme.primary;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    TextButton.icon(
                      key: const Key('generate-summary-ai-button'),
                      onPressed: viewModel.isBusy ? null : _generateSummary,
                      style: _secondaryActionButtonStyle(context),
                      icon: Icon(
                        Icons.psychology_alt_outlined,
                        size: 24,
                        color: primary,
                      ),
                      label: Text(context.l10n.suggestSummary),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 36),
          _buildProfilePhotoPicker(viewModel),
        ],
      ),
    );
  }

  Widget _buildWorkStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: context.l10n.workExperienceTitle,
      subtitle: '',
      titleTrailing: _resumeSectionVisibilityLead(
        viewModel: viewModel,
        included: viewModel.resume.includeWorkInResume,
        sectionName: context.l10n.workExperienceTitle,
        setIncluded: viewModel.setIncludeWorkInResume,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (!_resumeOrderNudgeDismissed &&
              viewModel.resume.workExperiences.length > 1) ...[
            _HintBanner(
              title: context.l10n.resumeOrder,
              body:
                  context.l10n.resumeOrderBody,
              compact: true,
              onDismiss: _onDismissResumeOrderNudge,
            ),
            const SizedBox(height: 10),
          ],
          ...viewModel.resume.workExperiences.asMap().entries.expand((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast =
                index == viewModel.resume.workExperiences.length - 1;
            final experienceWidgets = <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 20 : 0),
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
                                context.l10n.experienceNumber(index + 1),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _resumeOrderLabel(index),
                                style: _resumeOrderHintStyle(context),
                              ),
                            ],
                          ),
                        ),
                        if (viewModel.resume.workExperiences.length > 1) ...[
                          IconButton.filledTonal(
                            tooltip: context.l10n.moveUp,
                            onPressed: index == 0
                                ? null
                                : () => _moveWorkExperience(
                                    index: index,
                                    moveUp: true,
                                  ),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          ),
                          IconButton.filledTonal(
                            tooltip: context.l10n.moveDown,
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
                            tooltip: context.l10n.deleteExperience,
                            onPressed: viewModel.isBusy
                                ? null
                                : () {
                                    _confirmRemoval(
                                      title: context.l10n.deleteWorkExperienceTitle,
                                      message:
                                          context.l10n.deleteWorkExperienceMessage,
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
                    const SizedBox(height: 28),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          key: Key('work-role-$index'),
                          label: context.l10n.role,
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
                          key: Key('work-company-$index'),
                          label: context.l10n.company,
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
                          label: context.l10n.startDate,
                          value: item.startDate,
                          hintText: context.l10n.monthYearHint,
                          onTap: () => _pickWorkDate(
                            index: index,
                            isEndDate: false,
                            currentValue: item.startDate,
                          ),
                        ),
                        _PickerField(
                          key: Key('work-end-date-$index'),
                          label: context.l10n.endDate,
                          value: item.endDate,
                          hintText: context.l10n.monthYearOrPresentHint,
                          onTap: () => _pickWorkDate(
                            index: index,
                            isEndDate: true,
                            currentValue: item.endDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    ...(() {
                      final displayBullets = List<String>.from(item.bullets);
                      return <Widget>[
                        ...displayBullets.asMap().entries.map((bulletEntry) {
                          final bulletIndex = bulletEntry.key;
                          final bullet = bulletEntry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _BulletField(
                              fieldKey: Key('work-bullet-$index-$bulletIndex'),
                              label: context.l10n.bulletNumber(bulletIndex + 1),
                              value: bullet,
                              deleteEnabled: !viewModel.isBusy,
                              focusNode: _focusNodeForExtendedKeyboardField(
                                'work-bullet-$index-$bulletIndex',
                              ),
                              onChanged: (value) => viewModel
                                  .updateWorkExperience(index, (current) {
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
                                  }),
                              onDelete: () {
                                _confirmRemoval(
                                  title: context.l10n.removeBulletTitle,
                                  message:
                                      context.l10n.removeBulletFromJob,
                                  onConfirm: () {
                                    viewModel.updateWorkExperience(
                                      index,
                                      (current) {
                                        final updated = List<String>.from(
                                          current.bullets,
                                        );
                                        if (bulletIndex >= updated.length) {
                                          return current;
                                        }
                                        updated.removeAt(bulletIndex);
                                        return current.copyWith(
                                          bullets: updated,
                                          layoutMode:
                                              WorkExperienceLayoutMode.bullets,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildAddBulletPointButton(
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
                          ),
                        ),
                      ];
                    })(),
                  ],
                ),
              ),
            ];
            if (!isLast) {
              final dividerColor = Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.28);
              experienceWidgets.addAll([
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _entryDividerHorizontalPadding,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: ColoredBox(color: dividerColor),
                  ),
                ),
                const SizedBox(height: 18),
              ]);
            }
            return experienceWidgets;
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: viewModel.isBusy ? null : viewModel.addWorkExperience,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.addExperience),
            ),
          ),
        ],
      ),
    );
  }

  void _focusPreviousKeyboardField(int currentStep) {
    final viewModel = context.read<ResumeEditorViewModel>();
    if (currentStep == 0) {
      _movePersonalFieldFocus(delta: -1);
      return;
    }
    if (viewModel.isSectionStep(ResumeBuilderSectionIds.projects)) {
      _moveFocusInOrder(_projectKeyboardFocusOrder, delta: -1);
      return;
    }
    final customIndex = viewModel.customIndexAtStep(currentStep);
    if (customIndex != null) {
      _moveFocusInOrder(
        _customKeyboardFocusOrderForIndex(viewModel, customIndex),
        delta: -1,
      );
    }
  }

  void _focusNextKeyboardField(int currentStep) {
    final viewModel = context.read<ResumeEditorViewModel>();
    if (currentStep == 0) {
      _movePersonalFieldFocus(delta: 1);
      return;
    }
    if (viewModel.isSectionStep(ResumeBuilderSectionIds.projects)) {
      _moveFocusInOrder(_projectKeyboardFocusOrder, delta: 1);
      return;
    }
    final customIndex = viewModel.customIndexAtStep(currentStep);
    if (customIndex != null) {
      _moveFocusInOrder(
        _customKeyboardFocusOrderForIndex(viewModel, customIndex),
        delta: 1,
      );
    }
  }

  List<FocusNode> _customKeyboardFocusOrderForIndex(
    ResumeEditorViewModel vm,
    int customIndex,
  ) {
    final item = vm.resume.customSections[customIndex];
    if (item.layoutMode == CustomSectionLayoutMode.projects) {
      return [
        for (var pi = 0; pi < item.projectEntries.length; pi++)
          for (var bi = 0; bi < item.projectEntries[pi].bullets.length; bi++)
            _focusNodeForExtendedKeyboardField(
              'custom-section-project-$customIndex-$pi-$bi',
            ),
        for (var pi = 0; pi < item.projectEntries.length; pi++)
          _focusNodeForExtendedKeyboardField(
            'custom-section-project-title-$customIndex-$pi',
          ),
      ];
    }
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
      title: context.l10n.sectionEducation,
      subtitle: context.l10n.educationSubtitle,
      titleTrailing: _resumeSectionVisibilityLead(
        viewModel: viewModel,
        included: viewModel.resume.includeEducationInResume,
        sectionName: context.l10n.sectionEducation,
        setIncluded: viewModel.setIncludeEducationInResume,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (!_resumeOrderNudgeDismissed &&
              viewModel.resume.education.length > 1) ...[
            _HintBanner(
              title: context.l10n.resumeOrder,
              body:
                  context.l10n.resumeOrderBody,
              compact: true,
              onDismiss: _onDismissResumeOrderNudge,
            ),
            const SizedBox(height: 10),
          ],
          ...viewModel.resume.education.asMap().entries.expand((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == viewModel.resume.education.length - 1;
            final educationWidgets = <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 20 : 0),
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
                                context.l10n.educationNumber(index + 1),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _resumeOrderLabel(index),
                                style: _resumeOrderHintStyle(context),
                              ),
                            ],
                          ),
                        ),
                        if (viewModel.resume.education.length > 1) ...[
                          IconButton.filledTonal(
                            tooltip: context.l10n.moveEducationUp,
                            onPressed: index == 0
                                ? null
                                : () => _moveEducation(
                                    index: index,
                                    moveUp: true,
                                  ),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          ),
                          IconButton.filledTonal(
                            tooltip: context.l10n.moveEducationDown,
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
                            tooltip: context.l10n.deleteEducationEntry,
                            onPressed: viewModel.isBusy
                                ? null
                                : () {
                                    _confirmRemoval(
                                      title: context.l10n.deleteEducationEntryTitle,
                                      message:
                                          context.l10n.deleteEducationEntryMessage,
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
                    const SizedBox(height: 28),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          label: context.l10n.institution,
                          value: item.institution,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) => viewModel.updateEducation(
                            index,
                            (current) => current.copyWith(institution: value),
                          ),
                        ),
                        _SyncTextField(
                          label: context.l10n.degree,
                          value: item.degree,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) => viewModel.updateEducation(
                            index,
                            (current) => current.copyWith(degree: value),
                          ),
                        ),
                        _PickerField(
                          key: Key('education-start-date-$index'),
                          label: context.l10n.startYear,
                          value: item.startDate,
                          hintText: context.l10n.selectYear,
                          onTap: () => _pickEducationDate(
                            index: index,
                            isEndDate: false,
                            currentValue: item.startDate,
                          ),
                        ),
                        _PickerField(
                          key: Key('education-end-date-$index'),
                          label: context.l10n.endYear,
                          value: item.endDate,
                          hintText: context.l10n.selectYear,
                          onTap: () => _pickEducationDate(
                            index: index,
                            isEndDate: true,
                            currentValue: item.endDate,
                          ),
                        ),
                        _SyncTextField(
                          label: context.l10n.marksScore,
                          value: item.score,
                          hintText: context.l10n.marksScoreHint,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffixIcon: _EducationScorePercentToggle(
                            active: item.showScoreAsPercent,
                            onPressed: viewModel.isBusy
                                ? null
                                : () => viewModel.updateEducation(
                                    index,
                                    (current) => current.copyWith(
                                      showScoreAsPercent:
                                          !current.showScoreAsPercent,
                                    ),
                                  ),
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
            ];
            if (!isLast) {
              final dividerColor = Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.28);
              educationWidgets.addAll([
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _entryDividerHorizontalPadding,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: ColoredBox(color: dividerColor),
                  ),
                ),
                const SizedBox(height: 18),
              ]);
            }
            return educationWidgets;
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: viewModel.isBusy ? null : viewModel.addEducation,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.addEducation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsStep(ResumeEditorViewModel viewModel) {
    final useSubheadings = viewModel.resume.useSkillSubheadings;
    final chipLabelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) - 2,
      fontWeight: FontWeight.w400,
    );

    return _StepSurface(
      title: context.l10n.sectionSkills,
      subtitle: context.l10n.skillsSubtitle,
      titleTrailing: _resumeSectionVisibilityLead(
        viewModel: viewModel,
        included: viewModel.resume.includeSkillsInResume,
        sectionName: context.l10n.sectionSkills,
        setIncluded: viewModel.setIncludeSkillsInResume,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            context.l10n.skillsCount(viewModel.resume.skills.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<bool>(
            groupValue: useSubheadings,
            onChanged: (bool? value) {
              if (value == null || viewModel.isBusy) {
                return;
              }
              viewModel.setUseSkillSubheadings(value);
              setState(() {});
            },
            child: Row(
              children: [
                Expanded(
                  child: _SkillsModeRadioOption(
                    value: false,
                    label: context.l10n.simpleList,
                    enabled: !viewModel.isBusy,
                  ),
                ),
                Expanded(
                  child: _SkillsModeRadioOption(
                    value: true,
                    label: context.l10n.categorised,
                    enabled: !viewModel.isBusy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!useSubheadings) ...[
            Builder(
              builder: (context) {
                final inset = MediaQuery.viewInsetsOf(context).bottom;
                final skillSuggestions = skillSuggestionsForQuery(
                  _skillController.text,
                  excludeLowercase: viewModel.resume.skills
                      .map((s) => s.toLowerCase())
                      .toSet(),
                ).toList();
                final theme = Theme.of(context);
                return KeyedSubtree(
                  key: _skillInputKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _skillController,
                        focusNode: _skillFocusNode,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          setState(() {});
                          if (_skillFocusNode.hasFocus) {
                            final fieldContext = _skillInputKey.currentContext;
                            if (fieldContext != null) {
                              _scheduleEnsureVisible(
                                fieldContext,
                                extraVisibleHeight: _skillSuggestionMaxHeight,
                                alignNearTop: true,
                              );
                            }
                          }
                        },
                        onSubmitted: (_) => _addSkillFromInput(),
                        scrollPadding: EdgeInsets.only(
                          left: 20,
                          top: 20,
                          right: 20,
                          bottom: inset + _skillSuggestionMaxHeight + 48,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n.addASkill,
                          helperText: context.l10n.addSkillHelper,
                          helperStyle: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                height: 1.35,
                              ),
                          suffixIcon: IconButton(
                            onPressed: _addSkillFromInput,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ),
                      if (_skillFocusNode.hasFocus &&
                          skillSuggestions.isNotEmpty)
                        _buildSkillSuggestionPanel(
                          theme: theme,
                          suggestions: skillSuggestions,
                          onSelect: (option) {
                            final added = viewModel.addSkill(option);
                            if (added) {
                              _skillController.clear();
                              setState(() {});
                            } else {
                              _showDuplicateSkillMessage();
                            }
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            if (viewModel.resume.skills.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: viewModel.resume.skills.map((skill) {
                  return InputChip(
                    label: Text(skill),
                    labelStyle: chipLabelStyle,
                    onDeleted: () => viewModel.removeSkill(skill),
                  );
                }).toList(),
              ),
          ] else ...[
            const SizedBox(height: 8),
            ...viewModel.resume.skillGroups.asMap().entries.map((entry) {
              final index = entry.key;
              final group = entry.value;
              final groupController = _groupSkillController(index);
              final groupFocus = _groupSkillFocusNode(index);
              final groupInputKey = _groupSkillInputKey(index);
              final inset = MediaQuery.viewInsetsOf(context).bottom;
              final groupSuggestions = skillSuggestionsForQuery(
                groupController.text,
                excludeLowercase: {
                  ...viewModel.resume.skills.map((s) => s.toLowerCase()),
                  ...group.skills.map((s) => s.toLowerCase()),
                },
              ).toList();
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _SyncTextField(
                                key: Key('skill-group-heading-$index'),
                                label: context.l10n.category,
                                value: group.heading,
                                hintText:
                                    context.l10n.categoryHint,
                                textCapitalization:
                                    TextCapitalization.words,
                                onChanged: (value) => viewModel
                                    .updateSkillGroupHeading(index, value),
                              ),
                            ),
                            if (viewModel.resume.skillGroups.length > 1) ...[
                              IconButton(
                                tooltip: context.l10n.moveCategoryUp,
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 4,
                                    end: 0,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: viewModel.isBusy || index == 0
                                    ? null
                                    : () => _moveSkillGroup(
                                          index: index,
                                          moveUp: true,
                                        ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                ),
                              ),
                              IconButton(
                                tooltip: context.l10n.moveCategoryDown,
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 0,
                                    end: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed:
                                    viewModel.isBusy ||
                                        index ==
                                            viewModel
                                                    .resume
                                                    .skillGroups
                                                    .length -
                                                1
                                    ? null
                                    : () => _moveSkillGroup(
                                          index: index,
                                          moveUp: false,
                                        ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                              ),
                            ],
                            IconButton(
                              tooltip: context.l10n.removeCategory,
                              style: IconButton.styleFrom(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 6,
                                  end: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: viewModel.isBusy
                                  ? null
                                  : () {
                                      _confirmRemoval(
                                        title: context.l10n.deleteCategoryTitle,
                                        message:
                                            context.l10n.deleteCategoryMessage,
                                        onConfirm: () {
                                          viewModel.removeSkillGroup(index);
                                          _reindexGroupSkillControllersAfterRemove(
                                            index,
                                          );
                                          setState(() {});
                                        },
                                      );
                                    },
                              icon: const ImageIcon(
                                AssetImage('assets/fonts/delete.png'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        KeyedSubtree(
                          key: groupInputKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: groupController,
                                focusNode: groupFocus,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) {
                                  setState(() {});
                                  if (groupFocus.hasFocus) {
                                    final fieldContext =
                                        groupInputKey.currentContext;
                                    if (fieldContext != null) {
                                      _scheduleEnsureVisible(
                                        fieldContext,
                                        extraVisibleHeight:
                                            _skillSuggestionMaxHeight,
                                        alignNearTop: true,
                                      );
                                    }
                                  }
                                },
                                onSubmitted: (_) =>
                                    _addSkillToGroupFromInput(index),
                                scrollPadding: EdgeInsets.only(
                                  left: 20,
                                  top: 20,
                                  right: 20,
                                  bottom:
                                      inset + _skillSuggestionMaxHeight + 48,
                                ),
                                decoration: InputDecoration(
                                  labelText: context.l10n.addASkill,
                                  isDense: true,
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        _addSkillToGroupFromInput(index),
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                ),
                              ),
                              if (groupFocus.hasFocus &&
                                  groupSuggestions.isNotEmpty)
                                _buildSkillSuggestionPanel(
                                  theme: theme,
                                  suggestions: groupSuggestions,
                                  onSelect: (option) {
                                    final added = viewModel.addSkillToGroup(
                                      index,
                                      option,
                                    );
                                    if (added) {
                                      groupController.clear();
                                      setState(() {});
                                    } else {
                                      _showDuplicateSkillMessage();
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                        if (group.skills.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: group.skills.map((skill) {
                              return InputChip(
                                label: Text(skill),
                                labelStyle: chipLabelStyle,
                                onDeleted: () => viewModel
                                    .removeSkillFromGroup(index, skill),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            FilledButton.tonalIcon(
              onPressed: viewModel.isBusy
                  ? null
                  : () {
                      viewModel.addSkillGroup();
                      setState(() {});
                    },
              style: _mediumTonalButtonStyle(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.addCategory),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillSuggestionPanel({
    required ThemeData theme,
    required List<String> suggestions,
    required ValueChanged<String> onSelect,
  }) {
    final dividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.28,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: _skillSuggestionMaxHeight,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: dividerColor),
            itemBuilder: (context, index) {
              final option = suggestions[index];
              return InkWell(
                onTap: () => onSelect(option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    option,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
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
  }



  Widget _buildProjectsStep(ResumeEditorViewModel viewModel) {
    return _StepSurface(
      title: context.l10n.sectionProjects,
      subtitle: context.l10n.projectsSubtitle,
      titleTrailing: _resumeSectionVisibilityLead(
        viewModel: viewModel,
        included: viewModel.resume.includeProjectsInResume,
        sectionName: context.l10n.sectionProjects,
        setIncluded: viewModel.setIncludeProjectsInResume,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (!_resumeOrderNudgeDismissed &&
              viewModel.resume.projects.length > 1) ...[
            _HintBanner(
              title: context.l10n.resumeOrder,
              body:
                  context.l10n.resumeOrderBody,
              compact: true,
              onDismiss: _onDismissResumeOrderNudge,
            ),
            const SizedBox(height: 10),
          ],
          ...viewModel.resume.projects.asMap().entries.expand((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == viewModel.resume.projects.length - 1;
            final projectWidgets = <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 20 : 0),
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
                                context.l10n.projectNumber(index + 1),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _resumeOrderLabel(index),
                                style: _resumeOrderHintStyle(context),
                              ),
                            ],
                          ),
                        ),
                        if (viewModel.resume.projects.length > 1) ...[
                          IconButton.filledTonal(
                            tooltip: context.l10n.moveProjectUp,
                            onPressed: index == 0
                                ? null
                                : () =>
                                      _moveProject(index: index, moveUp: true),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          ),
                          IconButton.filledTonal(
                            tooltip: context.l10n.moveProjectDown,
                            onPressed:
                                index == viewModel.resume.projects.length - 1
                                ? null
                                : () =>
                                      _moveProject(index: index, moveUp: false),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                          IconButton(
                            tooltip: context.l10n.deleteProject,
                            onPressed: viewModel.isBusy
                                ? null
                                : () {
                                    _confirmRemoval(
                                      title: context.l10n.deleteProjectTitle,
                                      message:
                                          context.l10n.deleteProjectMessage,
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
                    const SizedBox(height: 28),
                    _ResponsiveFieldGroup(
                      children: [
                        _SyncTextField(
                          key: Key('project-title-$index'),
                          label: context.l10n.projectTitle,
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
                    const SizedBox(height: 26),
                    ...item.bullets.asMap().entries.map((bulletEntry) {
                      final bi = bulletEntry.key;
                      final text = bulletEntry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BulletField(
                          fieldKey: Key('project-bullet-$index-$bi'),
                          label: context.l10n.bulletNumber(bi + 1),
                          value: text,
                          hintText: context.l10n.enterBulletPoint,
                          deleteEnabled: !viewModel.isBusy,
                          focusNode: _focusNodeForExtendedKeyboardField(
                            'project-bullet-$index-$bi',
                          ),
                          onChanged: (value) =>
                              viewModel.updateProject(index, (current) {
                                final next = List<String>.from(
                                  current.bullets,
                                );
                                if (bi < next.length) {
                                  next[bi] = value;
                                }
                                return current.copyWith(bullets: next);
                              }),
                          onDelete: () {
                            _confirmRemoval(
                              title: context.l10n.removeBulletTitle,
                              message:
                                  context.l10n.removeBulletFromProject,
                              onConfirm: () {
                                viewModel.updateProject(index, (current) {
                                  final next = List<String>.from(
                                    current.bullets,
                                  );
                                  if (bi < next.length) {
                                    next.removeAt(bi);
                                  }
                                  return current.copyWith(bullets: next);
                                });
                              },
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildAddBulletPointButton(
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
                      ),
                    ),
                  ],
                ),
              ),
            ];
            if (!isLast) {
              final dividerColor = Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.28);
              projectWidgets.addAll([
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _entryDividerHorizontalPadding,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: ColoredBox(color: dividerColor),
                  ),
                ),
                const SizedBox(height: 18),
              ]);
            }
            return projectWidgets;
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: viewModel.isBusy ? null : viewModel.addProject,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.addProject),
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
      title: _customSectionStepTitle(context, item, index),
      subtitle: item.layoutMode == CustomSectionLayoutMode.projects
          ? context.l10n.customSectionProjectsSubtitle
          : '',
      titleTrailing: IconButton(
        tooltip: context.l10n.removeSection,
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
        icon: const ImageIcon(AssetImage('assets/fonts/delete.png')),
      ),
      child: item.layoutMode == CustomSectionLayoutMode.projects
          ? _buildCustomSectionProjectsEditor(viewModel, index, item)
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          RadioGroup<CustomSectionLayoutMode>(
            groupValue: item.layoutMode,
            onChanged: (CustomSectionLayoutMode? value) {
              if (value == null || viewModel.isBusy) {
                return;
              }
              viewModel.updateCustomSection(index, (c) {
                if (value == CustomSectionLayoutMode.bullets &&
                    c.bullets.isEmpty) {
                  return c.copyWith(layoutMode: value, bullets: ['']);
                }
                return c.copyWith(layoutMode: value);
              });
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
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    title: Text(
                      context.l10n.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
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
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    title: Text(
                      context.l10n.bulletPoints,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
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
                  label: context.l10n.summary,
                  value: item.content,
                  textCapitalization: TextCapitalization.sentences,
                  hintText:
                      context.l10n.customSectionSummaryHint,
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
                child: _BulletField(
                  fieldKey: Key('custom-section-bullet-$index-$bi'),
                  label: context.l10n.bulletNumber(bi + 1),
                  value: text,
                  hintText: context.l10n.enterBulletPoint,
                  deleteEnabled: !viewModel.isBusy,
                  focusNode: _focusNodeForExtendedKeyboardField(
                    'custom-section-bullet-$index-$bi',
                  ),
                  onChanged: (value) =>
                      viewModel.updateCustomSection(index, (c) {
                        final next = List<String>.from(c.bullets);
                        if (bi < next.length) {
                          next[bi] = value;
                        }
                        return c.copyWith(bullets: next);
                      }),
                  onDelete: () {
                    viewModel.updateCustomSection(index, (c) {
                      final next = List<String>.from(c.bullets)..removeAt(bi);
                      return c.copyWith(bullets: next);
                    });
                  },
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildAddBulletPointButton(
                onPressed: viewModel.isBusy
                    ? null
                    : () {
                        viewModel.updateCustomSection(
                          index,
                          (c) => c.copyWith(bullets: [...c.bullets, '']),
                        );
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomSectionProjectsEditor(
    ResumeEditorViewModel viewModel,
    int sectionIndex,
    CustomSectionItem item,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (!_resumeOrderNudgeDismissed && item.projectEntries.length > 1) ...[
          _HintBanner(
            title: context.l10n.resumeOrder,
            body:
                context.l10n.resumeOrderBody,
            compact: true,
            onDismiss: _onDismissResumeOrderNudge,
          ),
          const SizedBox(height: 10),
        ],
        ...item.projectEntries.asMap().entries.expand((entry) {
          final index = entry.key;
          final project = entry.value;
          final isLast = index == item.projectEntries.length - 1;
          final projectWidgets = <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: isLast ? 20 : 0),
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
                              context.l10n.entryNumber(index + 1),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _resumeOrderLabel(index),
                              style: _resumeOrderHintStyle(context),
                            ),
                          ],
                        ),
                      ),
                      if (item.projectEntries.length > 1) ...[
                        IconButton.filledTonal(
                          tooltip: context.l10n.moveEntryUp,
                          onPressed: index == 0
                              ? null
                              : () => viewModel.moveCustomSectionProjectUp(
                                    sectionIndex,
                                    index,
                                  ),
                          icon: const Icon(Icons.keyboard_arrow_up_rounded),
                        ),
                        IconButton.filledTonal(
                          tooltip: context.l10n.moveEntryDown,
                          onPressed: index == item.projectEntries.length - 1
                              ? null
                              : () => viewModel.moveCustomSectionProjectDown(
                                    sectionIndex,
                                    index,
                                  ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        IconButton(
                          tooltip: context.l10n.deleteEntry,
                          onPressed: viewModel.isBusy
                              ? null
                              : () {
                                  _confirmRemoval(
                                    title: context.l10n.deleteEntryTitle,
                                    message:
                                        context.l10n.deleteEntryMessage,
                                    onConfirm: () => viewModel
                                        .removeCustomSectionProject(
                                          sectionIndex,
                                          index,
                                        ),
                                  );
                                },
                          icon: const ImageIcon(
                            AssetImage('assets/fonts/delete.png'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),
                  _ResponsiveFieldGroup(
                    children: [
                      _SyncTextField(
                        key: Key(
                          'custom-section-project-title-$sectionIndex-$index',
                        ),
                        label: context.l10n.title,
                        value: project.title,
                        textCapitalization: TextCapitalization.sentences,
                        focusNode: _focusNodeForExtendedKeyboardField(
                          'custom-section-project-title-$sectionIndex-$index',
                        ),
                        onChanged: (value) =>
                            viewModel.updateCustomSectionProject(
                              sectionIndex,
                              index,
                              (current) => current.copyWith(title: value),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  ...project.bullets.asMap().entries.map((bulletEntry) {
                    final bi = bulletEntry.key;
                    final text = bulletEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _BulletField(
                        fieldKey: Key(
                          'custom-section-project-$sectionIndex-$index-$bi',
                        ),
                        label: context.l10n.bulletNumber(bi + 1),
                        value: text,
                        hintText: context.l10n.enterBulletPoint,
                        deleteEnabled: !viewModel.isBusy,
                        focusNode: _focusNodeForExtendedKeyboardField(
                          'custom-section-project-$sectionIndex-$index-$bi',
                        ),
                        onChanged: (value) =>
                            viewModel.updateCustomSectionProject(
                              sectionIndex,
                              index,
                              (current) {
                                final next = List<String>.from(current.bullets);
                                if (bi < next.length) {
                                  next[bi] = value;
                                }
                                return current.copyWith(bullets: next);
                              },
                            ),
                        onDelete: () {
                          _confirmRemoval(
                            title: context.l10n.removeBulletTitle,
                            message:
                                context.l10n.removeBulletFromEntry,
                            onConfirm: () {
                              viewModel.updateCustomSectionProject(
                                sectionIndex,
                                index,
                                (current) {
                                  final next = List<String>.from(
                                    current.bullets,
                                  );
                                  if (bi < next.length) {
                                    next.removeAt(bi);
                                  }
                                  return current.copyWith(bullets: next);
                                },
                              );
                            },
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildAddBulletPointButton(
                      onPressed: viewModel.isBusy
                          ? null
                          : () {
                              viewModel.updateCustomSectionProject(
                                sectionIndex,
                                index,
                                (current) => current.copyWith(
                                  bullets: [...current.bullets, ''],
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ),
          ];
          if (!isLast) {
            final dividerColor = Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.28);
            projectWidgets.addAll([
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _entryDividerHorizontalPadding,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 1,
                  child: ColoredBox(color: dividerColor),
                ),
              ),
              const SizedBox(height: 18),
            ]);
          }
          return projectWidgets;
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: viewModel.isBusy
                ? null
                : () => viewModel.addCustomSectionProject(sectionIndex),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.addEntry),
          ),
        ),
      ],
    );
  }
}

String _customSectionStepTitle(
  BuildContext context,
  CustomSectionItem item,
  int index,
) {
  final t = item.title.trim();
  if (t.isEmpty) {
    return context.l10n.categoryNumber(index + 1);
  }
  return t;
}

enum _CustomSectionCreationType { normal, advance }

class _NewCustomSectionDialogResult {
  const _NewCustomSectionDialogResult({
    required this.title,
    required this.type,
  });

  final String title;
  final _CustomSectionCreationType type;
}

class _StepProgressHeader extends StatefulWidget {
  const _StepProgressHeader({
    required this.currentStep,
    required this.totalStepCount,
    required this.sectionIds,
    required this.customSections,
    required this.onSelectStep,
    required this.onAddCategory,
    required this.onReorderChips,
  });

  final int currentStep;
  final int totalStepCount;
  final List<String> sectionIds;
  final List<CustomSectionItem> customSections;
  final ValueChanged<int> onSelectStep;
  final VoidCallback onAddCategory;
  final void Function(int oldIndex, int newIndex) onReorderChips;

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
        oldWidget.sectionIds.length != widget.sectionIds.length ||
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

    final chipStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w400);

    final addIconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    // Children: Personal + ordered sections + Add
    final chipCount = 1 + widget.sectionIds.length + 1;

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
            height: 48,
            width: double.infinity,
            child: ReorderableListView.builder(
              key: const Key('step-progress-scroll'),
              scrollController: _scrollController,
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(animation.value);
                    return Material(
                      elevation: 2 + 4 * t,
                      color: Colors.transparent,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: widget.onReorderChips,
              itemCount: chipCount,
              itemBuilder: (context, index) {
                final isPersonal = index == 0;
                final isAdd = index == chipCount - 1;
                final Widget chip;
                if (isPersonal) {
                  chip = ChoiceChip(
                    key: _chipKeyFor(0),
                    label: Text(
                      context.l10n.sectionPersonalInformation,
                      style: chipStyle,
                    ),
                    selected: widget.currentStep == 0,
                    onSelected: (_) => widget.onSelectStep(0),
                  );
                } else if (isAdd) {
                  chip = ChoiceChip(
                    avatar: Icon(
                      Icons.add_rounded,
                      size: 24,
                      color: addIconColor,
                    ),
                    label: Text(context.l10n.add, style: chipStyle),
                    selected: false,
                    onSelected: (_) => widget.onAddCategory(),
                  );
                } else {
                  final sectionId = widget.sectionIds[index - 1];
                  chip = ChoiceChip(
                    key: _chipKeyFor(index),
                    label: Text(
                      ResumeBuilderSectionIds.titleFor(
                        sectionId,
                        widget.customSections,
                        context.l10n,
                      ),
                      style: chipStyle,
                    ),
                    selected: widget.currentStep == index,
                    onSelected: (_) => widget.onSelectStep(index),
                  );
                }

                final padded = Padding(
                  padding: EdgeInsets.only(right: isAdd ? 0 : 10),
                  child: chip,
                );

                if (isPersonal || isAdd) {
                  return KeyedSubtree(
                    key: ValueKey(isPersonal ? 'chip-personal' : 'chip-add'),
                    child: padded,
                  );
                }

                return ReorderableDelayedDragStartListener(
                  key: ValueKey('chip-${widget.sectionIds[index - 1]}'),
                  index: index,
                  child: padded,
                );
              },
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
            child: OutlinedButton(onPressed: onBack, child: Text(context.l10n.back)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onNext,
              child: Text(isLastStep ? context.l10n.preview : context.l10n.continueAction),
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

void _scheduleEnsureVisible(
  BuildContext context, {
  double extraVisibleHeight = 0,
  bool alignNearTop = false,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!context.mounted) {
        return;
      }

      final renderObject = context.findRenderObject();
      final scrollable = Scrollable.maybeOf(context);
      if (renderObject is! RenderBox || scrollable == null) {
        return;
      }

      if (alignNearTop) {
        try {
          Scrollable.ensureVisible(
            context,
            alignment: 0.08,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        } catch (_) {
          // Focus may outlive its scroll context briefly during transitions.
        }
        return;
      }

      final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
      if (keyboardInset <= 0) {
        return;
      }

      final fieldTop = renderObject.localToGlobal(Offset.zero).dy;
      final fieldBottom = fieldTop + renderObject.size.height;
      // Keep focused field clearly above keyboard + suggestion list.
      final visibleBottom =
          MediaQuery.sizeOf(context).height - keyboardInset - 96;
      final requiredBottom = fieldBottom + extraVisibleHeight;
      final overlap = requiredBottom - visibleBottom;

      if (overlap <= 0) {
        return;
      }

      try {
        final position = scrollable.position;
        if (!position.hasPixels || !position.hasContentDimensions) {
          return;
        }
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
      } catch (_) {
        // Focus may outlive its scroll context briefly during transitions.
        // Skip auto-scroll in that frame instead of crashing.
      }
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
    final trimmed = value.trim();
    final hasValue = trimmed.isNotEmpty;
    final displayValue = trimmed.toLowerCase() == 'present'
        ? context.l10n.present
        : value;
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    final fillColor = inputTheme.fillColor ?? theme.colorScheme.surface;
    final enabledBorder = inputTheme.enabledBorder;
    final outlineBorder = enabledBorder is OutlineInputBorder
        ? enabledBorder
        : const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          );
    final borderSide = outlineBorder.borderSide == BorderSide.none
        ? BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          )
        : outlineBorder.borderSide;
    final borderRadius = outlineBorder.borderRadius;
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      color: hasValue
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: borderRadius,
          border: Border.fromBorderSide(borderSide),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? displayValue : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            const SizedBox(width: 8),
            IconTheme(
              data: IconThemeData(color: theme.colorScheme.primary),
              child: const _ThinCalendarIcon(
                strokeWidth: _ResumeBuilderScreenState._calendarIconStroke,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinCalendarIcon extends StatelessWidget {
  const _ThinCalendarIcon({required this.strokeWidth});

  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? Theme.of(context).iconTheme.color;
    return SizedBox.square(
      dimension: 24,
      child: CustomPaint(
        painter: _ThinCalendarIconPainter(
          color: color ?? Colors.black,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Larger radio + label for Skills layout mode (Simple list / Categorised).
class _SkillsModeRadioOption extends StatelessWidget {
  const _SkillsModeRadioOption({
    required this.value,
    required this.label,
    required this.enabled,
  });

  final bool value;
  final String label;
  final bool enabled;

  static const double _radioScale = 1.45;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) + 1,
    );

    return InkWell(
      onTap: enabled
          ? () => RadioGroup.maybeOf<bool>(context)?.onChanged(value)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Transform.scale(
              scale: _radioScale,
              child: Radio<bool>(
                value: value,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinCalendarIconPainter extends CustomPainter {
  const _ThinCalendarIconPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.12, height * 0.18, width * 0.76, height * 0.7),
      Radius.circular(width * 0.08),
    );
    canvas.drawRRect(outer, paint);

    final headerY = height * 0.36;
    canvas.drawLine(
      Offset(width * 0.12, headerY),
      Offset(width * 0.88, headerY),
      paint,
    );

    canvas.drawLine(
      Offset(width * 0.28, height * 0.1),
      Offset(width * 0.28, height * 0.26),
      paint,
    );
    canvas.drawLine(
      Offset(width * 0.72, height * 0.1),
      Offset(width * 0.72, height * 0.26),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThinCalendarIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class _BulletField extends StatelessWidget {
  const _BulletField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.focusNode,
    this.hintText,
    this.onDelete,
    this.deleteEnabled = true,
  });

  static const double _deleteButtonSize = 28;
  static const double _deleteButtonHalf = _deleteButtonSize / 2;
  /// Outlined field border top sits below the widget top (floating label gap).
  static const double _deleteButtonBorderInset = 4;

  final Key fieldKey;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final FocusNode focusNode;
  final String? hintText;
  final VoidCallback? onDelete;
  final bool deleteEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _SyncTextField(
            key: fieldKey,
            label: label,
            value: value,
            hintText: hintText,
            textCapitalization: TextCapitalization.sentences,
            fullWidth: true,
            minLines: 1,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            focusNode: focusNode,
            onChanged: onChanged,
          ),
          if (onDelete != null)
            Positioned(
              top: -_deleteButtonHalf + _deleteButtonBorderInset,
              right: -_deleteButtonHalf + _deleteButtonBorderInset,
              child: Material(
                color: deleteEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.38),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: deleteEnabled ? onDelete : null,
                  customBorder: const CircleBorder(),
                  child: Tooltip(
                    message: context.l10n.removeBullet,
                    child: SizedBox(
                      width: _deleteButtonSize,
                      height: _deleteButtonSize,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EducationScorePercentToggle extends StatelessWidget {
  const _EducationScorePercentToggle({
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const toggleSize = 24.0;
    const borderRadius = 4.0;

    return Padding(
      padding: const EdgeInsets.only(right: 19),
      child: Material(
        color: active
            ? primary.withValues(alpha: 0.15)
            : theme.colorScheme.outline.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashFactory: NoSplash.splashFactory,
          highlightColor: primary.withValues(alpha: 0.08),
          child: Tooltip(
            message: active
                ? context.l10n.hidePercentOnResume
                : context.l10n.showPercentOnResume,
            child: SizedBox.square(
              dimension: toggleSize,
              child: Center(
                child: Text(
                  '%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1,
                    color: active ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
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
    this.suffixIcon,
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
  final Widget? suffixIcon;

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
        suffixIcon: widget.suffixIcon,
        suffixIconConstraints: widget.suffixIcon != null
            ? const BoxConstraints(
                minWidth: 43,
                minHeight: 24,
                maxWidth: 44,
                maxHeight: 24,
              )
            : null,
        isDense: widget.suffixIcon != null,
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
        hintText: _focusNode.hasFocus ? '' : context.l10n.phoneNumber,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryKey,
              isDense: true,
              iconSize: 18,
              style: inputStyle,
              dropdownColor: Theme.of(context).cardColor,
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
          minWidth: 108,
          maxWidth: 108,
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
                  tooltip: context.l10n.dismiss,
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
          context.l10n.livePreview,
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
                  context.l10n.exportActions,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onDownload,
                  child: Text(context.l10n.downloadPdf),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onShare,
                  child: Text(context.l10n.shareResume),
                ),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: onPrint, child: Text(context.l10n.print)),
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
                    context.l10n.resumeScore,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.atsCompatibilitySummary(
                      (analysis.atsCompatibility * 100).round(),
                      analysis.missingSkills.length,
                    ),
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
