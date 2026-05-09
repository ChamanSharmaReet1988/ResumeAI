import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/skill_autocomplete_suggestions.dart';
import 'cover_letter_content_screen.dart';
import '../shared/view_models.dart';

const List<String> _coverLetterLanguageOptions = [
  'English',
  'Hindi',
  'Spanish',
  'French',
  'German',
  'Arabic',
  'Mandarin',
  'Portuguese',
  'Japanese',
];

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

class CoverLetterEditorScreen extends StatelessWidget {
  const CoverLetterEditorScreen({super.key});

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
                            'Cover letter',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This page creates a cover letter draft from the details below. Add the company name, job position name, one or more skills to highlight, and a language you want to mention, then tap Create cover letter to open the full draft on the next screen.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 20),
                          _SyncTextField(
                            label: 'Company name',
                            hintText: 'Acme Labs',
                            value: viewModel.coverLetter.company,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) => viewModel.updateCoverLetter(
                              (current) => current.copyWith(company: value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SyncTextField(
                            label: 'Job position name',
                            hintText: 'Product Designer',
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
                            label: 'Skill to highlight',
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
                            label: 'Language',
                            value: viewModel.coverLetter.language,
                            items: _coverLetterLanguageOptions,
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
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              ChangeNotifierProvider<
                                                CoverLetterEditorViewModel
                                              >.value(
                                                value: viewModel,
                                                child:
                                                    const CoverLetterContentScreen(),
                                              ),
                                        ),
                                      );
                                    },
                              child: viewModel.isBusy
                                  ? const SizedBox(
                                      height: 20,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            key: Key(
                                              'create-cover-letter-loader',
                                            ),
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text('Creating...'),
                                        ],
                                      ),
                                    )
                                  : const Text('Create cover letter'),
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
    this.hintText,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hintText;
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
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
      ),
    );
  }
}

class _SyncDropdownField extends StatelessWidget {
  const _SyncDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.fieldKey,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final normalizedItems = items.toSet().toList()..sort();
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
                  item,
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
                item,
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
      _scheduleEnsureVisible(context);
      setState(() {});
    } else {
      setState(() {});
    }
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
          onChanged: (_) => setState(() {}),
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
                    fontSize:
                        (theme.textTheme.bodySmall?.fontSize ?? 12) - 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -2,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
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
      ],
    );
  }
}
