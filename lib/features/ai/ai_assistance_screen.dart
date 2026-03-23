import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/resume_services.dart';
import '../shared/view_models.dart';

class AiAssistanceScreen extends StatefulWidget {
  const AiAssistanceScreen({super.key, required this.onOpenResumeBuilder});

  final VoidCallback onOpenResumeBuilder;

  @override
  State<AiAssistanceScreen> createState() => _AiAssistanceScreenState();
}

class _AiAssistanceScreenState extends State<AiAssistanceScreen> {
  final _jobTitleController = TextEditingController();
  final _roleController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _coverLetterCompanyController = TextEditingController();
  final _coverLetterRoleController = TextEditingController();

  bool _isBusy = false;
  String _summary = '';
  List<String> _skillSuggestions = const [];
  List<String> _jobBullets = const [];
  ResumeAnalysis? _analysis;
  JobDescriptionInsights? _jobInsights;
  String _coverLetter = '';

  @override
  void dispose() {
    _jobTitleController.dispose();
    _roleController.dispose();
    _companyController.dispose();
    _jobDescriptionController.dispose();
    _coverLetterCompanyController.dispose();
    _coverLetterRoleController.dispose();
    super.dispose();
  }

  Future<void> _runTask(Future<void> Function() task) async {
    setState(() => _isBusy = true);
    await task();
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
  }

  ResumeData _fallbackResume(ResumeTemplate template) {
    return ResumeData.empty(template: template);
  }

  @override
  Widget build(BuildContext context) {
    final aiService = context.read<LocalAiResumeService>();
    final library = context.watch<ResumeLibraryViewModel>();
    final resume =
        library.selectedResume ?? _fallbackResume(library.defaultTemplate);
    final canDoDeepAnalysis = resume.hasMeaningfulContent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI assistance',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate stronger summaries, keyword-rich bullets, tailored skills, and ATS guidance using your saved resume as the source of truth.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.auto_awesome_rounded),
                  ),
                  const SizedBox(width: 14),
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
                          [
                            resume.fullName,
                            resume.jobTitle,
                            '${resume.skills.length} skills',
                          ].join(' • '),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          canDoDeepAnalysis
                              ? 'This resume is ready for AI suggestions.'
                              : 'The AI tools work best after you add some real content in the builder.',
                        ),
                      ],
                    ),
                  ),
                  if (!canDoDeepAnalysis)
                    FilledButton(
                      onPressed: widget.onOpenResumeBuilder,
                      child: const Text('Open builder'),
                    ),
                ],
              ),
            ),
          ),
          if (_isBusy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 2
                  : constraints.maxWidth >= 760
                  ? 2
                  : 1;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * 16)) / columns;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _AiToolCard(
                      title: 'AI summary generator',
                      subtitle:
                          'Create a polished introduction based on the active resume.',
                      icon: Icons.summarize_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () {
                              _runTask(() async {
                                _summary = await aiService.generateSummary(
                                  resume,
                                );
                              });
                            },
                            icon: const Icon(Icons.auto_fix_high_outlined),
                            label: const Text('Generate summary'),
                          ),
                          if (_summary.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(_summary),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AiToolCard(
                      title: 'AI skill suggestions',
                      subtitle:
                          'Add targeted keywords based on the resume title, target job title, and work experience details.',
                      icon: Icons.psychology_alt_outlined,
                      child: Column(
                        children: [
                          TextField(
                            controller: _jobTitleController,
                            decoration: InputDecoration(
                              labelText: 'Target job title',
                              hintText: resume.jobTitle.ifBlank(
                                'Senior Flutter Developer',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              _runTask(() async {
                                _skillSuggestions = await aiService
                                    .suggestSkills(
                                      resume: resume,
                                      targetJobTitle:
                                          _jobTitleController.text
                                              .trim()
                                              .isEmpty
                                          ? resume.jobTitle
                                          : _jobTitleController.text.trim(),
                                    );
                              });
                            },
                            icon: const Icon(Icons.tips_and_updates_outlined),
                            label: const Text('Suggest skills'),
                          ),
                          if (_skillSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _skillSuggestions
                                  .map((item) => Chip(label: Text(item)))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AiToolCard(
                      title: 'Job bullet generator',
                      subtitle:
                          'Create sharper work experience bullets with stronger action language.',
                      icon: Icons.work_outline_rounded,
                      child: Column(
                        children: [
                          TextField(
                            controller: _roleController,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              hintText: 'Product Designer',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Company',
                              hintText: 'Northstar',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              _runTask(() async {
                                _jobBullets = await aiService
                                    .generateJobBullets(
                                      role: _roleController.text,
                                      company: _companyController.text,
                                      targetJobTitle:
                                          _jobTitleController.text
                                              .trim()
                                              .isEmpty
                                          ? resume.jobTitle
                                          : _jobTitleController.text.trim(),
                                    );
                              });
                            },
                            icon: const Icon(Icons.bolt_outlined),
                            label: const Text('Generate bullets'),
                          ),
                          if (_jobBullets.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            ..._jobBullets.map(
                              (bullet) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• '),
                                    Expanded(child: Text(bullet)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AiToolCard(
                      title: 'Resume analyzer',
                      subtitle:
                          'Check ATS alignment, missing keywords, and resume score against a job description.',
                      icon: Icons.analytics_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _jobDescriptionController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Job description',
                              hintText:
                                  'Paste a job post to compare keywords and requirements.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.tonal(
                                onPressed: canDoDeepAnalysis
                                    ? () {
                                        _runTask(() async {
                                          _analysis = await aiService
                                              .analyzeResume(
                                                resume: resume,
                                                jobDescription:
                                                    _jobDescriptionController
                                                        .text,
                                              );
                                          _jobInsights = await aiService
                                              .analyzeJobDescription(
                                                jobDescription:
                                                    _jobDescriptionController
                                                        .text,
                                                resume: resume,
                                              );
                                        });
                                      }
                                    : null,
                                child: const Text('Analyze'),
                              ),
                            ],
                          ),
                          if (_analysis != null) ...[
                            const SizedBox(height: 14),
                            _ScoreRow(score: _analysis!.score),
                            if (_analysis!.missingSkills.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Missing skills: ${_analysis!.missingSkills.join(', ')}',
                              ),
                            ],
                            if (_analysis!.weakDescriptions.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Weak descriptions: ${_analysis!.weakDescriptions.join(' ')}',
                              ),
                            ],
                          ],
                          if (_jobInsights != null) ...[
                            const SizedBox(height: 14),
                            Text(_jobInsights!.summary),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AiToolCard(
                      title: 'Cover letter generator',
                      subtitle:
                          'Draft a tailored cover letter from the current resume in one tap.',
                      icon: Icons.mail_outline_rounded,
                      child: Column(
                        children: [
                          TextField(
                            controller: _coverLetterCompanyController,
                            decoration: const InputDecoration(
                              labelText: 'Company',
                              hintText: 'Acme Inc.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _coverLetterRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              hintText: 'Senior Product Designer',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: canDoDeepAnalysis
                                ? () {
                                    _runTask(() async {
                                      _coverLetter = await aiService
                                          .generateCoverLetter(
                                            resume: resume,
                                            company:
                                                _coverLetterCompanyController
                                                    .text
                                                    .ifBlank('the company'),
                                            role: _coverLetterRoleController
                                                .text
                                                .ifBlank(resume.jobTitle),
                                          );
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Generate cover letter'),
                          ),
                          if (_coverLetter.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            SelectableText(_coverLetter),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AiToolCard extends StatelessWidget {
  const _AiToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final progress = score / 100;

    return Row(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(value: progress, strokeWidth: 6),
              Center(
                child: Text(
                  '$score',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Resume score indicator based on structure, content strength, and ATS match.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
