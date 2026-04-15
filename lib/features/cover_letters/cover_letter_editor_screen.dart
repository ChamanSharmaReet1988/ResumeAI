import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cover_letter_content_screen.dart';
import '../shared/view_models.dart';

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
                            'This page creates a cover letter draft automatically from your selected resume plus the details below. Add the company name, job position name, one skill to highlight, and a language you want to mention, then tap Create cover letter to open the full draft on the next screen.',
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
                          _SyncTextField(
                            label: 'Skill to highlight',
                            hintText: 'UX research',
                            value: viewModel.coverLetter.skillToHighlight,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) => viewModel.updateCoverLetter(
                              (current) =>
                                  current.copyWith(skillToHighlight: value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SyncTextField(
                            label: 'Language',
                            hintText: 'English',
                            value: viewModel.coverLetter.language,
                            textCapitalization: TextCapitalization.words,
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
                                          builder: (_) => ChangeNotifierProvider<
                                            CoverLetterEditorViewModel
                                          >.value(
                                            value: viewModel,
                                            child:
                                                const CoverLetterContentScreen(),
                                          ),
                                        ),
                                      );
                                    },
                              child: const Text('Create cover letter'),
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
    _controller = TextEditingController(text: widget.value);
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
