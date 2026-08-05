import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/app_localizations.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/services/analytics_events.dart';
import '../../core/skill_autocomplete_suggestions.dart';
import 'cover_letter_content_screen.dart';
import '../shared/view_models.dart';

/// Canonical language values stored on the cover letter (English labels).
const List<String> _coverLetterLanguageValues = [
  'English (English)',
  'Arabic (العربية)',
  'Bengali (বাংলা)',
  'Chinese, Mandarin (中文)',
  'Dutch (Nederlands)',
  'French (Français)',
  'German (Deutsch)',
  'Hindi (हिन्दी)',
  'Italian (Italiano)',
  'Japanese (日本語)',
  'Korean (한국어)',
  'Portuguese (Português)',
  'Russian (Русский)',
  'Spanish (Español)',
  'Turkish (Türkçe)',
  'Urdu (اردو)',
  'Vietnamese (Tiếng Việt)',
];

String _coverLetterLanguageLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'English (English)':
      return l10n.clLangEnglish;
    case 'Arabic (العربية)':
      return l10n.clLangArabic;
    case 'Bengali (বাংলা)':
      return l10n.clLangBengali;
    case 'Chinese, Mandarin (中文)':
      return l10n.clLangChinese;
    case 'Dutch (Nederlands)':
      return l10n.clLangDutch;
    case 'French (Français)':
      return l10n.clLangFrench;
    case 'German (Deutsch)':
      return l10n.clLangGerman;
    case 'Hindi (हिन्दी)':
      return l10n.clLangHindi;
    case 'Italian (Italiano)':
      return l10n.clLangItalian;
    case 'Japanese (日本語)':
      return l10n.clLangJapanese;
    case 'Korean (한국어)':
      return l10n.clLangKorean;
    case 'Portuguese (Português)':
      return l10n.clLangPortuguese;
    case 'Russian (Русский)':
      return l10n.clLangRussian;
    case 'Spanish (Español)':
      return l10n.clLangSpanish;
    case 'Turkish (Türkçe)':
      return l10n.clLangTurkish;
    case 'Urdu (اردو)':
      return l10n.clLangUrdu;
    case 'Vietnamese (Tiếng Việt)':
      return l10n.clLangVietnamese;
    default:
      return value;
  }
}

List<String> _coverLetterSkillsFromValue(String value) {
  final seen = <String>{};
  final skills = <String>[];
  for (final item in value.split(',')) {
    final trimmed = item.trim();
    final key = trimmed.toLowerCase();
    if (trimmed.isEmpty || !seen.add(key)) {
      continue;
    }
    skills.add(trimmed);
  }
  return skills;
}

String _coverLetterSkillsToValue(List<String> skills) {
  return skills
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .join(', ');
}

void _scheduleEnsureVisible(
  BuildContext context, {
  double extraVisibleHeight = 0,
  bool alignNearTop = false,
}) {
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

      if (alignNearTop) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.08,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
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
      final requiredBottom = fieldBottom + extraVisibleHeight;
      final overlap = requiredBottom - visibleBottom;

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

class CoverLetterEditorScreen extends StatelessWidget {
  const CoverLetterEditorScreen({super.key, this.backPopsToHome = false});

  final bool backPopsToHome;

  @override
  Widget build(BuildContext context) {
    return Consumer<CoverLetterEditorViewModel>(
      builder: (context, viewModel, _) {
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
          appBar: AppBar(
            leadingWidth: 56,
            titleSpacing: 2,
            title: Text(viewModel.coverLetter.displayTitle, style: titleStyle),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.isBusy) const LinearProgressIndicator(),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.coverLetterHeading,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.coverLetterEditorIntro,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 20),
                          _SyncTextField(
                            label: context.l10n.companyName,
                            value: viewModel.coverLetter.company,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) => viewModel.updateCoverLetter(
                              (current) => current.copyWith(company: value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SyncTextField(
                            label: context.l10n.jobPositionName,
                            value: viewModel.coverLetter.role,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) => viewModel.updateCoverLetter(
                              (current) => current.copyWith(role: value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SkillSuggestionField(
                            fieldKey: const Key('cover-letter-skill-field'),
                            addButtonKey: const Key(
                              'cover-letter-skill-add-button',
                            ),
                            label: context.l10n.skillToHighlight,
                            value: viewModel.coverLetter.skillToHighlight,
                            onChanged: (value) => viewModel.updateCoverLetter(
                              (current) =>
                                  current.copyWith(skillToHighlight: value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SyncDropdownField(
                            fieldKey: const Key(
                              'cover-letter-language-dropdown',
                            ),
                            label: context.l10n.language,
                            value: viewModel.coverLetter.language,
                            items: _coverLetterLanguageValues,
                            itemLabel: (value) =>
                                _coverLetterLanguageLabel(context.l10n, value),
                            onChanged: (value) => viewModel.updateCoverLetter(
                              (current) => current.copyWith(language: value),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  viewModel.isBusy ||
                                      !viewModel.canCreateCoverLetter
                                  ? null
                                  : () async {
                                      await viewModel.createCoverLetter();
                                      if (!context.mounted) {
                                        return;
                                      }
                                      await logAnalyticsEvent(
                                        context,
                                        AnalyticsEvents.coverLetterCreated,
                                        parameters: {
                                          ...coverLetterTemplateAnalytics(
                                            viewModel.coverLetter.template,
                                          ),
                                          'source': 'cover_letter_editor',
                                        },
                                      );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      final exitToHome =
                                          await Navigator.of(context).push<bool>(
                                        MaterialPageRoute<bool>(
                                          builder: (_) =>
                                              ChangeNotifierProvider<
                                                CoverLetterEditorViewModel
                                              >.value(
                                                value: viewModel,
                                                child: CoverLetterContentScreen(
                                                  backPopsToHome:
                                                      backPopsToHome,
                                                ),
                                              ),
                                        ),
                                      );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (backPopsToHome && exitToHome == true) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                              child: viewModel.isBusy
                                  ? SizedBox(
                                      height: 20,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            key: Key(
                                              'create-cover-letter-loader',
                                            ),
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(context.l10n.creatingEllipsis),
                                        ],
                                      ),
                                    )
                                  : Text(context.l10n.createCoverLetter),
                            ),
                          ),
                        ],
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

class _SyncTextField extends StatefulWidget {
  const _SyncTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextCapitalization textCapitalization;

  @override
  State<_SyncTextField> createState() => _SyncTextFieldState();
}

class _SyncTextFieldState extends State<_SyncTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textCapitalization: widget.textCapitalization,
      onChanged: widget.onChanged,
      decoration: InputDecoration(labelText: widget.label),
    );
  }
}

class _SyncDropdownField extends StatelessWidget {
  const _SyncDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
    this.fieldKey,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final String Function(String value)? itemLabel;
  final Key? fieldKey;

  String _labelFor(String value) => itemLabel?.call(value) ?? value;

  @override
  Widget build(BuildContext context) {
    final normalizedItems = <String>[];
    final seen = <String>{};
    for (final item in items) {
      final trimmed = item.trim();
      final key = trimmed.toLowerCase();
      if (trimmed.isEmpty || !seen.add(key)) {
        continue;
      }
      normalizedItems.add(trimmed);
    }
    final initialValue = normalizedItems.contains(value) ? value : null;
    final fieldTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return DropdownButtonFormField<String>(
      key: fieldKey,
      initialValue: initialValue,
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      alignment: AlignmentDirectional.centerStart,
      dropdownColor: Theme.of(context).cardColor,
      menuMaxHeight: 360,
      style: fieldTextStyle,
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      selectedItemBuilder: (context) {
        return normalizedItems
            .map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _labelFor(item),
                  overflow: TextOverflow.ellipsis,
                  style: fieldTextStyle,
                ),
              ),
            )
            .toList();
      },
      items: normalizedItems
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                _labelFor(item),
                overflow: TextOverflow.ellipsis,
                style: fieldTextStyle,
              ),
            ),
          )
          .toList(),
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}

class _SkillSuggestionField extends StatefulWidget {
  const _SkillSuggestionField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.fieldKey,
    this.addButtonKey,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;
  final Key? addButtonKey;

  @override
  State<_SkillSuggestionField> createState() => _SkillSuggestionFieldState();
}

class _SkillSuggestionFieldState extends State<_SkillSuggestionField> {
  static const double _suggestionRowHeight = 49;
  static const double _suggestionMaxHeight = 220;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _scheduleEnsureVisible(
        context,
        extraVisibleHeight: _suggestionMaxHeight,
        alignNearTop: true,
      );
      setState(() {});
    } else {
      setState(() {});
    }
  }

  double _estimatedSuggestionHeight(int suggestionCount) {
    if (suggestionCount <= 0) {
      return _suggestionMaxHeight;
    }
    return (suggestionCount * _suggestionRowHeight)
        .clamp(_suggestionRowHeight, _suggestionMaxHeight)
        .toDouble();
  }

  @override
  void didUpdateWidget(covariant _SkillSuggestionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _commitInput() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final currentSkills = _coverLetterSkillsFromValue(widget.value);
    final existing = currentSkills.map((item) => item.toLowerCase()).toSet();
    if (!existing.contains(trimmed.toLowerCase())) {
      currentSkills.add(trimmed);
      widget.onChanged(_coverLetterSkillsToValue(currentSkills));
    }
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentSkills = _coverLetterSkillsFromValue(widget.value);
    final query = _controller.text.trim();
    final suggestions = skillSuggestionsForQuery(
      query,
      excludeLowercase: {
        ...currentSkills.map((item) => item.toLowerCase()),
        if (query.isNotEmpty) query.toLowerCase(),
      },
    ).toList();
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.28,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: widget.fieldKey,
          controller: _controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            setState(() {});
            if (_focusNode.hasFocus) {
              _scheduleEnsureVisible(
                context,
                extraVisibleHeight: _estimatedSuggestionHeight(
                  suggestions.length,
                ),
                alignNearTop: true,
              );
            }
          },
          onSubmitted: (_) => _commitInput(),
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: IconButton(
              key: widget.addButtonKey,
              onPressed: _commitInput,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        if (_focusNode.hasFocus && suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              elevation: 6,
              shadowColor: Colors.black26,
              surfaceTintColor: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              color: theme.cardColor,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: dividerColor),
                  itemBuilder: (context, index) {
                    final option = suggestions[index];
                    return InkWell(
                      onTap: () {
                        final updated = [...currentSkills, option];
                        widget.onChanged(_coverLetterSkillsToValue(updated));
                        _controller.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          option,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        if (currentSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentSkills.map((skill) {
              return InputChip(
                label: Text(
                  skill,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -2,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 6,
                  top: 0,
                  bottom: 0,
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () {
                  final updated = currentSkills
                      .where(
                        (item) => item.toLowerCase() != skill.toLowerCase(),
                      )
                      .toList();
                  widget.onChanged(_coverLetterSkillsToValue(updated));
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
