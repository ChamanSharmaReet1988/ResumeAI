import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cover_letter_preview_screen.dart';
import '../shared/view_models.dart';

class CoverLetterContentScreen extends StatefulWidget {
  const CoverLetterContentScreen({super.key});

  @override
  State<CoverLetterContentScreen> createState() =>
      _CoverLetterContentScreenState();
}

class _CoverLetterContentScreenState extends State<CoverLetterContentScreen> {
  Timer? _saveTimer;

  @override
  void dispose() {
    _saveTimer?.cancel();
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

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<CoverLetterEditorViewModel>.value(
          value: viewModel,
          child: const CoverLetterPreviewScreen(),
        ),
      ),
    );
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

        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              unawaited(_saveDraft(viewModel));
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leadingWidth: 40,
              titleSpacing: 8,
              title: Text(
                viewModel.coverLetter.displayTitle,
                style: titleStyle,
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('preview-cover-letter-button'),
                  onPressed: viewModel.coverLetter.content.trim().isEmpty
                      ? null
                      : () => _openPreview(viewModel),
                  child: const Text('Preview'),
                ),
              ),
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
                              'Cover letter content',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your cover letter draft is ready. Review the full content below, edit anything you want, and your changes will be saved automatically.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            _CoverLetterContentField(
                              value: viewModel.coverLetter.content,
                              onChanged: (value) {
                                viewModel.updateCoverLetter(
                                  (current) => current.copyWith(content: value),
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
          ),
        );
      },
    );
  }
}

class _CoverLetterContentField extends StatefulWidget {
  const _CoverLetterContentField({
    required this.value,
    required this.onChanged,
  });

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
      minLines: 18,
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        labelText: 'Cover letter content',
        hintText: 'Your generated cover letter will appear here.',
        alignLabelWithHint: true,
      ),
    );
  }
}
