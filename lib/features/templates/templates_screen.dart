import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../shared/resume_preview_card.dart';
import '../shared/view_models.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key, required this.onCreateResume});

  final VoidCallback onCreateResume;

  @override
  Widget build(BuildContext context) {
    return Consumer<ResumeLibraryViewModel>(
      builder: (context, library, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resume templates',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Switch styles instantly while keeping the content intact. The selected template becomes the default for new resumes.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1100
                      ? 2
                      : constraints.maxWidth >= 700
                      ? 2
                      : 1;
                  final itemWidth =
                      (constraints.maxWidth - ((columns - 1) * 16)) / columns;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: ResumeTemplate.values.map((template) {
                      final selected = template == library.defaultTemplate;
                      final sample = _sampleResume(template);
                      return SizedBox(
                        width: itemWidth,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ResumePreviewCard(
                                  resume: sample,
                                  isCompact: true,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            template.label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            template.description,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? template.accentColor
                                            : template.tintColor,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        selected ? 'Selected' : 'Preview',
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : template.accentColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () =>
                                          library.setDefaultTemplate(template),
                                      child: Text(
                                        selected
                                            ? 'Using this template'
                                            : 'Use template',
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        library.setDefaultTemplate(template);
                                        onCreateResume();
                                      },
                                      child: const Text('Create resume'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Template preview updates live inside the resume builder so you can edit and compare layouts without leaving the flow.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

ResumeData _sampleResume(ResumeTemplate template) {
  return ResumeData(
    id: 'template-$template',
    title: '${template.label} Resume',
    fullName: 'Your Name',
    jobTitle: 'Target Role',
    email: 'email@example.com',
    phone: '+1 555 0000',
    location: 'City, Country',
    website: 'portfolio.com',
    summary:
        'Use this preview to compare templates before adding your own content.',
    template: template,
    workExperiences: const [
      WorkExperience(
        role: 'Job Title',
        company: 'Company',
        startDate: 'Start',
        endDate: 'Present',
        description:
            'Add your own experience details after selecting a template.',
        bullets: [
          'Replace this text with your real achievements and impact.',
          'Keep the preview while removing seeded user-style data.',
        ],
      ),
    ],
    education: const [
      EducationItem(
        institution: 'Institution',
        degree: 'Degree',
        year: 'Year',
        details: 'Optional details',
      ),
    ],
    skills: const ['Skill', 'Tool', 'Keyword', 'Method'],
    projects: const [
      ProjectItem(
        title: 'Project Title',
        subtitle: 'Project subtitle',
        overview: 'Project overview placeholder.',
        impact: 'Project impact placeholder.',
      ),
    ],
    updatedAt: DateTime(2026, 3, 1),
    githubLink: 'github.com/username',
    linkedinLink: 'linkedin.com/in/username',
  );
}
