import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import 'cover_letter_preview_screen.dart';
import '../shared/view_models.dart';

class CoverLetterContentScreen extends StatefulWidget {
  const CoverLetterContentScreen({super.key, this.backPopsToHome = false});

  final bool backPopsToHome;

  @override
  State<CoverLetterContentScreen> createState() =>
      _CoverLetterContentScreenState();
}

class _CoverLetterContentScreenState extends State<CoverLetterContentScreen> {
  Timer? _saveTimer;
  final _contentFocusNode = FocusNode();

  @override
  void dispose() {
    _saveTimer?.cancel();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveDraft(CoverLetterEditorViewModel viewModel) async {
    await viewModel.saveCoverLetter(showBusy: false);
  }

  void _scheduleSave(CoverLetterEditorViewModel viewModel) {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_saveDraft(viewModel)),
    );
  }

  Future<void> _openPreview(CoverLetterEditorViewModel viewModel) async {
    _saveTimer?.cancel();
    await _saveDraft(viewModel);
    if (!mounted) {
      return;
    }

    final previewResult = await Navigator.of(context).push<bool?>(
      MaterialPageRoute<bool?>(
        builder: (_) => ChangeNotifierProvider<CoverLetterEditorViewModel>.value(
          value: viewModel,
          child: CoverLetterPreviewScreen(
            backPopsToHome: widget.backPopsToHome,
          ),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (widget.backPopsToHome && previewResult == null) {
      Navigator.of(context).pop(true);
    }
  }

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

        final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
        final showKeyboardHideButton = keyboardInset > 0;

        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              unawaited(_saveDraft(viewModel));
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              leadingWidth: 56,
              titleSpacing: 2,
              title: Text(
                viewModel.coverLetter.displayTitle,
                style: titleStyle,
              ),
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            32 + keyboardInset,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (viewModel.isBusy)
                                const LinearProgressIndicator(),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.coverLetterContentHeading,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.l10n.coverLetterContentIntro,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 20),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          key: const Key(
                                            'regenerate-cover-letter-button',
                                          ),
                                          onPressed: viewModel.isBusy ||
                                                  !viewModel
                                                      .canCreateCoverLetter
                                              ? null
                                              : () => unawaited(
                                                    viewModel
                                                        .regenerateCoverLetter(),
                                                  ),
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                          ),
                                          label: Text(context.l10n.regenerate),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _CoverLetterContentField(
                                        focusNode: _contentFocusNode,
                                        value: viewModel.coverLetter.content,
                                        onChanged: (value) {
                                          viewModel.updateCoverLetter(
                                            (current) => current.copyWith(
                                              content: value,
                                            ),
                                          );
                                          _scheduleSave(viewModel);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('preview-cover-letter-button'),
                            onPressed:
                                viewModel.coverLetter.content.trim().isEmpty
                                ? null
                                : () => _openPreview(viewModel),
                            child: Text(context.l10n.preview),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showKeyboardHideButton)
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
          ),
        );
      },
    );
  }
}

class _CoverLetterContentField extends StatefulWidget {
  const _CoverLetterContentField({
    required this.focusNode,
    required this.value,
    required this.onChanged,
  });

  final FocusNode focusNode;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_CoverLetterContentField> createState() =>
      _CoverLetterContentFieldState();
}

class _CoverLetterContentFieldState extends State<_CoverLetterContentField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _CoverLetterContentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      minLines: 18,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: context.l10n.coverLetterContentHeading,
        hintText: context.l10n.coverLetterContentHint,
        alignLabelWithHint: true,
      ),
    );
  }
}
