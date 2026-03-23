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

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.currentSegment,
    required this.onSegmentChanged,
    required this.onOpenResume,
    required this.onOpenCoverLetter,
  });

  final HomeSegment currentSegment;
  final ValueChanged<HomeSegment> onSegmentChanged;
  final ValueChanged<ResumeData> onOpenResume;
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
                      _ResumeSection(
                        library: resumeLibrary,
                        dateFormat: dateFormat,
                        onOpenResume: onOpenResume,
                      )
                    else
                      _CoverLetterSection(
                        library: coverLetterLibrary,
                        dateFormat: dateFormat,
                        onOpenCoverLetter: onOpenCoverLetter,
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
  });

  final ResumeLibraryViewModel library;
  final DateFormat dateFormat;
  final ValueChanged<ResumeData> onOpenResume;

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
      children: library.resumes.map((resume) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                library.selectResume(resume.id);
                onOpenResume(resume);
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    IconButton(
                      tooltip: 'Delete resume',
                      onPressed: () => library.deleteResume(resume.id),
                      icon: const Icon(Icons.delete_outline_rounded),
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
      children: library.coverLetters.map((coverLetter) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onOpenCoverLetter(coverLetter),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    IconButton(
                      tooltip: 'Delete cover letter',
                      onPressed: () =>
                          library.deleteCoverLetter(coverLetter.id),
                      icon: const Icon(Icons.delete_outline_rounded),
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

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
