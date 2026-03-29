import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../shared/view_models.dart';

enum HomeSegment { resumes, coverLetters }

extension HomeSegmentX on HomeSegment {
  String get label => switch (this) {
    HomeSegment.resumes => 'Resume',
    HomeSegment.coverLetters => 'Cover Letter',
  };
}

enum _ResumeCardAction { open, edit, duplicate, delete }

enum _CoverLetterCardAction { open, delete }

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.currentSegment,
    required this.onSegmentChanged,
    required this.onOpenResume,
    required this.onPreviewResume,
    required this.onOpenCoverLetter,
  });

  final HomeSegment currentSegment;
  final ValueChanged<HomeSegment> onSegmentChanged;
  final ValueChanged<ResumeData> onOpenResume;
  final ValueChanged<ResumeData> onPreviewResume;
  final ValueChanged<CoverLetterData> onOpenCoverLetter;

  @override
  Widget build(BuildContext context) {
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
                                        'Resume',
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
                                        'Cover Letter',
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
                              segments: const [
                                ButtonSegment<HomeSegment>(
                                  value: HomeSegment.resumes,
                                  label: Text('Resume'),
                                ),
                                ButtonSegment<HomeSegment>(
                                  value: HomeSegment.coverLetters,
                                  label: Text('Cover Letter'),
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
                          onOpenCoverLetter: onOpenCoverLetter,
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

  Future<void> _confirmDeleteResume(
    BuildContext context,
    ResumeData resume,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete resume?'),
          content: Text(
            'Delete "${resume.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
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
    final action = await showModalBottomSheet<_ResumeCardAction>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionSheetTile(
                icon: Icons.visibility_outlined,
                label: 'Open',
                onTap: () => Navigator.of(context).pop(_ResumeCardAction.open),
              ),
              _ActionSheetTile(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => Navigator.of(context).pop(_ResumeCardAction.edit),
              ),
              _ActionSheetTile(
                icon: Icons.copy_all_outlined,
                label: 'Duplicate',
                onTap: () =>
                    Navigator.of(context).pop(_ResumeCardAction.duplicate),
              ),
              _ActionSheetTile(
                leading: const ImageIcon(AssetImage('assets/fonts/delete.png')),
                label: 'Delete',
                onTap: () =>
                    Navigator.of(context).pop(_ResumeCardAction.delete),
              ),
            ],
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
      case _ResumeCardAction.duplicate:
        await library.duplicateResume(resume);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Resume duplicated.')));
        return;
      case _ResumeCardAction.delete:
        await _confirmDeleteResume(context, resume);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (library.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (library.resumes.isEmpty) {
      return const _EmptySegmentState(
        icon: CupertinoIcons.doc_text,
        title: 'No resumes yet',
        body: 'Tap the add button to create your first resume.',
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
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resume.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [resume.fullName.trim(), resume.jobTitle.trim()]
                                .where((item) => item.isNotEmpty)
                                .join(' • ')
                                .ifBlank('Empty draft'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Updated ${dateFormat.format(resume.updatedAt)}',
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
    required this.onOpenCoverLetter,
  });

  final CoverLetterLibraryViewModel library;
  final DateFormat dateFormat;
  final ValueChanged<CoverLetterData> onOpenCoverLetter;

  Future<void> _confirmDeleteCoverLetter(
    BuildContext context,
    CoverLetterData coverLetter,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete cover letter?'),
          content: Text(
            'Delete "${coverLetter.displayTitle}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
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
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionSheetTile(
                icon: Icons.visibility_outlined,
                label: 'Open',
                onTap: () =>
                    Navigator.of(context).pop(_CoverLetterCardAction.open),
              ),
              _ActionSheetTile(
                leading: const ImageIcon(AssetImage('assets/fonts/delete.png')),
                label: 'Delete',
                onTap: () =>
                    Navigator.of(context).pop(_CoverLetterCardAction.delete),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _CoverLetterCardAction.open:
        onOpenCoverLetter(coverLetter);
        return;
      case _CoverLetterCardAction.delete:
        await _confirmDeleteCoverLetter(context, coverLetter);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (library.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (library.coverLetters.isEmpty) {
      return const _EmptySegmentState(
        icon: CupertinoIcons.mail,
        title: 'No cover letters yet',
        body: 'Tap the add button to create your first cover letter.',
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
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coverLetter.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                                  coverLetter.company.trim(),
                                  coverLetter.role.trim(),
                                ]
                                .where((item) => item.isNotEmpty)
                                .join(' • ')
                                .ifBlank('Empty draft'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Updated ${dateFormat.format(coverLetter.updatedAt)}',
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
    return ListTile(
      leading: leading ?? (icon == null ? null : Icon(icon)),
      title: Text(label),
      onTap: onTap,
    );
  }
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
