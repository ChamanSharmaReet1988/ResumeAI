import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/app_localizations.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/bottom_sheet_insets.dart';
import '../../core/models/resume_models.dart';
import '../shared/view_models.dart';

enum HomeSegment { resumes, coverLetters }

extension HomeSegmentX on HomeSegment {
  String label(AppLocalizations l10n) => switch (this) {
    HomeSegment.resumes => l10n.homeSegmentResume,
    HomeSegment.coverLetters => l10n.homeSegmentCoverLetter,
  };
}

enum _ResumeCardAction { open, edit, rename, duplicate, delete }

enum _CoverLetterCardAction { open, edit, delete }

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.currentSegment,
    required this.onSegmentChanged,
    required this.onOpenResume,
    required this.onPreviewResume,
    required this.onPreviewCoverLetter,
    required this.onEditCoverLetter,
  });

  final HomeSegment currentSegment;
  final ValueChanged<HomeSegment> onSegmentChanged;
  final ValueChanged<ResumeData> onOpenResume;
  final ValueChanged<ResumeData> onPreviewResume;
  final ValueChanged<CoverLetterData> onPreviewCoverLetter;
  final ValueChanged<CoverLetterData> onEditCoverLetter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;
    final blue = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Consumer2<ResumeLibraryViewModel, CoverLetterLibraryViewModel>(
      builder: (context, resumeLibrary, coverLetterLibrary, _) {
        final dateFormat = DateFormat('MMM d, y');

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isCupertino
                        ? SizedBox(
                            width: double.infinity,
                            child:
                                CupertinoSlidingSegmentedControl<HomeSegment>(
                                  groupValue: currentSegment,
                                  proportionalWidth: true,
                                  onValueChanged: (value) {
                                    if (value != null) {
                                      onSegmentChanged(value);
                                    }
                                  },
                                  children: {
                                    HomeSegment.resumes: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        l10n.homeSegmentResume,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color:
                                              currentSegment ==
                                                  HomeSegment.resumes
                                              ? blue
                                              : inactiveColor,
                                        ),
                                      ),
                                    ),
                                    HomeSegment.coverLetters: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        l10n.homeSegmentCoverLetter,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color:
                                              currentSegment ==
                                                  HomeSegment.coverLetters
                                              ? blue
                                              : inactiveColor,
                                        ),
                                      ),
                                    ),
                                  },
                                ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<HomeSegment>(
                              expandedInsets: EdgeInsets.zero,
                              style: SegmentedButton.styleFrom(
                                selectedForegroundColor: blue,
                                foregroundColor: inactiveColor,
                                textStyle: const TextStyle(fontSize: 17),
                              ),
                              selected: {currentSegment},
                              onSelectionChanged: (values) {
                                onSegmentChanged(values.first);
                              },
                              segments: [
                                ButtonSegment<HomeSegment>(
                                  value: HomeSegment.resumes,
                                  label: Text(l10n.homeSegmentResume),
                                ),
                                ButtonSegment<HomeSegment>(
                                  value: HomeSegment.coverLetters,
                                  label: Text(l10n.homeSegmentCoverLetter),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 20),
                    if (currentSegment == HomeSegment.resumes)
                      SizedBox(
                        width: double.infinity,
                        child: _ResumeSection(
                          library: resumeLibrary,
                          dateFormat: dateFormat,
                          onOpenResume: onOpenResume,
                          onPreviewResume: onPreviewResume,
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: _CoverLetterSection(
                          library: coverLetterLibrary,
                          dateFormat: dateFormat,
                          onPreviewCoverLetter: onPreviewCoverLetter,
                          onEditCoverLetter: onEditCoverLetter,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }
}

class _ResumeSection extends StatelessWidget {
  const _ResumeSection({
    required this.library,
    required this.dateFormat,
    required this.onOpenResume,
    required this.onPreviewResume,
  });

  final ResumeLibraryViewModel library;
  final DateFormat dateFormat;
  final ValueChanged<ResumeData> onOpenResume;
  final ValueChanged<ResumeData> onPreviewResume;

  String _displayResumeTitle(AppLocalizations l10n, ResumeData resume) {
    final title = resume.title.trim();
    if (title.isEmpty || title == ResumeData.defaultTitle) {
      return l10n.untitledResume;
    }
    return title;
  }

  Future<void> _confirmDeleteResume(
    BuildContext context,
    ResumeData resume,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = context.l10n;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(dialogL10n.deleteResumeTitle),
          content: Text(
            dialogL10n.deleteResumeMessage(
              _displayResumeTitle(dialogL10n, resume),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(dialogL10n.actionDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await library.deleteResume(resume.id);
    }
  }

  Future<void> _showResumeActions(
    BuildContext context,
    ResumeData resume,
  ) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<_ResumeCardAction>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        final sheetL10n = context.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: BottomSheetInsets.leftPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: BottomSheetInsets.topSpacing),
                _ActionSheetTile(
                  icon: Icons.visibility_outlined,
                  label: sheetL10n.actionOpen,
                  onTap: () =>
                      Navigator.of(context).pop(_ResumeCardAction.open),
                ),
                _ActionSheetTile(
                  icon: Icons.edit_outlined,
                  label: sheetL10n.actionEdit,
                  onTap: () =>
                      Navigator.of(context).pop(_ResumeCardAction.edit),
                ),
                _ActionSheetTile(
                  icon: Icons.drive_file_rename_outline,
                  label: sheetL10n.actionRename,
                  onTap: () =>
                      Navigator.of(context).pop(_ResumeCardAction.rename),
                ),
                _ActionSheetTile(
                  icon: Icons.copy_all_outlined,
                  label: sheetL10n.actionDuplicate,
                  onTap: () =>
                      Navigator.of(context).pop(_ResumeCardAction.duplicate),
                ),
                _ActionSheetTile(
                  leading: const ImageIcon(
                    AssetImage('assets/fonts/delete.png'),
                  ),
                  label: sheetL10n.actionDelete,
                  onTap: () =>
                      Navigator.of(context).pop(_ResumeCardAction.delete),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _ResumeCardAction.open:
        library.selectResume(resume.id);
        onPreviewResume(resume);
        return;
      case _ResumeCardAction.edit:
        library.selectResume(resume.id);
        onOpenResume(resume);
        return;
      case _ResumeCardAction.rename:
        final nextTitle = await _showRenameResumeDialog(context, resume);
        if (!context.mounted || nextTitle == null) {
          return;
        }
        await library.renameResume(resume, nextTitle);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resumeRenamed)));
        return;
      case _ResumeCardAction.duplicate:
        final duplicateTitle = await _showDuplicateResumeDialog(
          context,
          resume,
        );
        if (!context.mounted || duplicateTitle == null) {
          return;
        }
        await library.duplicateResume(resume, title: duplicateTitle);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resumeDuplicated)));
        return;
      case _ResumeCardAction.delete:
        await _confirmDeleteResume(context, resume);
        return;
    }
  }

  Future<String?> _showRenameResumeDialog(
    BuildContext context,
    ResumeData resume,
  ) async {
    final l10n = context.l10n;
    final currentTitle = resume.title.trim();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _ResumeTitleDialog(
          title: l10n.renameResumeTitle,
          actionLabel: l10n.actionRename,
          fieldKey: const Key('rename-resume-title-field'),
          initialTitle: currentTitle == ResumeData.defaultTitle
              ? ''
              : currentTitle,
        );
      },
    );
  }

  Future<String?> _showDuplicateResumeDialog(
    BuildContext context,
    ResumeData resume,
  ) async {
    final l10n = context.l10n;
    final currentTitle = resume.title.trim();
    final suggestedTitle =
        (currentTitle.isEmpty || currentTitle == ResumeData.defaultTitle)
        ? l10n.untitledResume
        : currentTitle;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _ResumeTitleDialog(
          title: l10n.duplicateResumeTitle,
          actionLabel: l10n.actionDuplicate,
          fieldKey: const Key('duplicate-resume-title-field'),
          initialTitle: l10n.titleWithCopySuffix(suggestedTitle),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (library.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (library.resumes.isEmpty) {
      return _EmptySegmentState(
        icon: CupertinoIcons.doc_text,
        title: l10n.noResumesYet,
        body: l10n.noResumesYetBody,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: library.resumes.map((resume) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _showResumeActions(context, resume),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayResumeTitle(l10n, resume),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            l10n.updatedDate(dateFormat.format(resume.updatedAt)),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize:
                                      ((Theme.of(context).textTheme.bodySmall
                                                  ?.fontSize ??
                                              12) -
                                          3)
                                          .toDouble(),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      key: Key('resume-card-arrow-${resume.id}'),
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CoverLetterSection extends StatelessWidget {
  const _CoverLetterSection({
    required this.library,
    required this.dateFormat,
    required this.onPreviewCoverLetter,
    required this.onEditCoverLetter,
  });

  final CoverLetterLibraryViewModel library;
  final DateFormat dateFormat;
  final ValueChanged<CoverLetterData> onPreviewCoverLetter;
  final ValueChanged<CoverLetterData> onEditCoverLetter;

  String _displayCoverLetterTitle(
    AppLocalizations l10n,
    CoverLetterData coverLetter,
  ) {
    final title = coverLetter.displayTitle;
    if (title == 'Untitled Cover Letter') {
      return l10n.untitledCoverLetter;
    }
    return title;
  }

  Future<void> _confirmDeleteCoverLetter(
    BuildContext context,
    CoverLetterData coverLetter,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = context.l10n;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(dialogL10n.deleteCoverLetterTitle),
          content: Text(
            dialogL10n.deleteCoverLetterMessage(
              _displayCoverLetterTitle(dialogL10n, coverLetter),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(dialogL10n.actionDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await library.deleteCoverLetter(coverLetter.id);
    }
  }

  Future<void> _showCoverLetterActions(
    BuildContext context,
    CoverLetterData coverLetter,
  ) async {
    final action = await showModalBottomSheet<_CoverLetterCardAction>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        final sheetL10n = context.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: BottomSheetInsets.leftPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: BottomSheetInsets.topSpacing),
                _ActionSheetTile(
                  icon: Icons.visibility_outlined,
                  label: sheetL10n.actionOpen,
                  onTap: () =>
                      Navigator.of(context).pop(_CoverLetterCardAction.open),
                ),
                _ActionSheetTile(
                  icon: Icons.edit_outlined,
                  label: sheetL10n.actionEdit,
                  onTap: () =>
                      Navigator.of(context).pop(_CoverLetterCardAction.edit),
                ),
                _ActionSheetTile(
                  leading: const ImageIcon(
                    AssetImage('assets/fonts/delete.png'),
                  ),
                  label: sheetL10n.actionDelete,
                  onTap: () =>
                      Navigator.of(context).pop(_CoverLetterCardAction.delete),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _CoverLetterCardAction.open:
        onPreviewCoverLetter(coverLetter);
        return;
      case _CoverLetterCardAction.edit:
        onEditCoverLetter(coverLetter);
        return;
      case _CoverLetterCardAction.delete:
        await _confirmDeleteCoverLetter(context, coverLetter);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (library.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (library.coverLetters.isEmpty) {
      return _EmptySegmentState(
        icon: CupertinoIcons.mail,
        title: l10n.noCoverLettersYet,
        body: l10n.noCoverLettersYetBody,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: library.coverLetters.map((coverLetter) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _showCoverLetterActions(context, coverLetter),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayCoverLetterTitle(l10n, coverLetter),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            l10n.updatedDate(
                              dateFormat.format(coverLetter.updatedAt),
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize:
                                      ((Theme.of(context).textTheme.bodySmall
                                                  ?.fontSize ??
                                              12) -
                                          3)
                                          .toDouble(),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      key: Key('cover-letter-card-arrow-${coverLetter.id}'),
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptySegmentState extends StatelessWidget {
  const _EmptySegmentState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final helperTextStyle = Theme.of(context).textTheme.bodySmall;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: helperTextStyle?.copyWith(
                fontSize: ((helperTextStyle.fontSize ?? 16) - 3).toDouble(),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeTitleDialog extends StatefulWidget {
  const _ResumeTitleDialog({
    required this.title,
    required this.actionLabel,
    required this.initialTitle,
    required this.fieldKey,
  });

  final String title;
  final String actionLabel;
  final String initialTitle;
  final Key fieldKey;

  @override
  State<_ResumeTitleDialog> createState() => _ResumeTitleDialogState();
}

class _ResumeTitleDialogState extends State<_ResumeTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.resumeTitle,
          hintText: l10n.enterResumeTitle,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  const _ActionSheetTile({
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
  });

  final IconData? icon;
  final Widget? leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: IconTheme(
        data: IconThemeData(color: primaryColor),
        child: leading ?? (icon == null ? const SizedBox.shrink() : Icon(icon)),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
