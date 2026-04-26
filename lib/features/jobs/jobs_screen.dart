import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/resume_models.dart';
import '../shared/view_models.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  static const double _fieldHorizontalPadding = 12;
  String? _selectedResumeId;

  @override
  Widget build(BuildContext context) {
    return Consumer<ResumeLibraryViewModel>(
      builder: (context, library, _) {
        final resumes = library.resumes;
        if (resumes.isEmpty) {
          return const Center(
            child: Text('Create a resume first to see job matches.'),
          );
        }

        _selectedResumeId ??= library.selectedResume?.id ?? resumes.first.id;
        final selected = resumes.firstWhere(
          (r) => r.id == _selectedResumeId,
          orElse: () => resumes.first,
        );
        final jobs = _jobsForResume(selected);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected.id,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                alignment: AlignmentDirectional.centerStart,
                dropdownColor: Theme.of(context).cardColor,
                elevation: 6,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                menuMaxHeight: 360,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                decoration: const InputDecoration(
                  labelText: 'Select resume',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _fieldHorizontalPadding,
                    vertical: 14,
                  ),
                ),
                selectedItemBuilder: (context) {
                  return resumes.map((resume) {
                    final title = resume.title.trim().isEmpty
                        ? ResumeData.defaultTitle
                        : resume.title;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: resumes
                    .map(
                      (resume) => DropdownMenuItem(
                        value: resume.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _fieldHorizontalPadding,
                            vertical: 12,
                          ),
                          child: Text(
                            resume.title.trim().isEmpty
                                ? ResumeData.defaultTitle
                                : resume.title,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedResumeId = value);
                },
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _fieldHorizontalPadding,
                ),
                child: Text(
                  'Choose a resume, then review combined jobs from multiple portals below.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...jobs.map(
                (job) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _openJobUrl(job.applyUrl),
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
                                    job.title,
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${job.company} • ${job.location}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: Text(
                                          job.source,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        job.postedAgo,
                                        style: Theme.of(context).textTheme.labelSmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 14,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_JobSuggestion> _jobsForResume(ResumeData resume) {
    final role = _targetRoleForResume(resume);
    final location = resume.location.trim().isEmpty
        ? 'Remote'
        : resume.location.trim();
    final topSkills = resume.skillsForResume
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList();
    final keywords = resume.skillsForResume
        .map((item) => item.toLowerCase().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final jobs = _generatePortalJobs(
      role: role,
      location: location,
      topSkills: topSkills,
    );
    jobs.sort((a, b) {
      final recencyOrder = a.ageInHours.compareTo(b.ageInHours);
      if (recencyOrder != 0) {
        return recencyOrder;
      }
      return b.matchScore(keywords).compareTo(a.matchScore(keywords));
    });
    return jobs;
  }

  Future<void> _openJobUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!mounted || launched) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open job link right now.')),
    );
  }

  List<_JobSuggestion> _generatePortalJobs({
    required String role,
    required String location,
    required List<String> topSkills,
  }) {
    final skillA = topSkills.isNotEmpty ? topSkills[0] : 'Flutter';
    final skillB = topSkills.length > 1 ? topSkills[1] : 'API';
    final skillC = topSkills.length > 2 ? topSkills[2] : 'Testing';
    final templates = <_JobTemplate>[
      _JobTemplate(
        source: 'LinkedIn',
        applyBaseUrl: 'https://www.linkedin.com/jobs/search',
        companies: const [
          'Northstar Labs',
          'Apex Cloud',
          'Violet Systems',
          'SignalPath',
          'Byte Harbor',
          'Neon Grid',
          'DeltaScale',
          'Open Ridge',
          'Nimbus Core',
          'ArcByte',
        ],
        titleVariants: [
          role,
          'Senior $role ($skillA)',
          '$role (Platform Team - $skillB)',
          '$role - Product & $skillC',
          'Associate $role',
          '$role - Integrations ($skillA)',
          'Lead $role ($skillB)',
          '$role (Consumer App - $skillC)',
          '$role - Performance ($skillA)',
          '$role (Remote)',
        ],
        locations: [
          location,
          'Remote',
          'Hybrid',
          'Bangalore',
          'Pune',
          'Hyderabad',
          'Noida',
          'Chennai',
          'Gurugram',
          'Mumbai',
        ],
      ),
      _JobTemplate(
        source: 'Naukri',
        applyBaseUrl: 'https://www.naukri.com',
        companies: const [
          'TechVista',
          'CloudForge Labs',
          'PixelOrbit',
          'Nexa Digital',
          'SwiftScale',
          'CobaltWare',
          'AsterMind',
          'Riverstack',
          'Hyperlane Tech',
          'Prime Orbit',
        ],
        titleVariants: [
          role,
          '$role Engineer ($skillA)',
          '$role Developer ($skillB)',
          'Lead $role ($skillC)',
          '$role (Core Team - $skillA)',
          'Principal $role ($skillB)',
          '$role (SaaS - $skillC)',
          '$role - Platform ($skillA)',
          '$role (Growth - $skillB)',
          '$role (Product Team)',
        ],
        locations: [
          location,
          'Remote',
          'Delhi NCR',
          'Mumbai',
          'Hyderabad',
          'Pune',
          'Bangalore',
          'Noida',
          'Chennai',
          'Kolkata',
        ],
      ),
      _JobTemplate(
        source: 'Indeed',
        applyBaseUrl: 'https://www.indeed.com/jobs',
        companies: const [
          'Blue Ridge Tech',
          'Orbit Systems',
          'Macrobyte',
          'Acorn Data',
          'OpenFrame Labs',
          'SpectraOps',
          'Wave Matrix',
          'BrightArc',
          'Hexa Spark',
          'Urban Cloud',
        ],
        titleVariants: [
          role,
          'Junior $role ($skillA)',
          '$role Analyst ($skillB)',
          '$role (Automation - $skillC)',
          '$role Specialist ($skillA)',
          '$role (Reliability - $skillB)',
          '$role (Backend API - $skillC)',
          'Staff $role ($skillA)',
          '$role (Mobile Platform)',
          '$role (Tooling)',
        ],
        locations: [
          location,
          'Remote',
          'Chennai',
          'Noida',
          'Ahmedabad',
          'Delhi NCR',
          'Pune',
          'Bangalore',
          'Hyderabad',
          'Jaipur',
        ],
      ),
      _JobTemplate(
        source: 'Wellfound',
        applyBaseUrl: 'https://wellfound.com/jobs',
        companies: const [
          'Startup Forge',
          'ProtoPulse',
          'RocketMint',
          'Alpha Circuit',
          'Gridline AI',
          'DashFlow',
          'SyncNest',
          'Crux Labs',
          'NovaMint',
          'Shipline',
        ],
        titleVariants: [
          role,
          '$role (Startup - $skillA)',
          'Founding $role ($skillB)',
          'Full Stack $role ($skillC)',
          '$role (Growth Product - $skillA)',
          '$role (0-1 Product)',
          '$role (Early Team - $skillB)',
          '$role (Founding Engineer)',
          '$role (App Platform - $skillC)',
          '$role (Remote Startup)',
        ],
        locations: [
          location,
          'Remote',
          'Bengaluru',
          'Hybrid',
          'Gurugram',
          'Pune',
          'Noida',
          'Delhi NCR',
          'Hyderabad',
          'Mumbai',
        ],
      ),
    ];

    final recency = const [
      '2h ago',
      '6h ago',
      '12h ago',
      '1d ago',
      '2d ago',
      '3d ago',
      '4d ago',
      '5d ago',
      '6d ago',
      '7d ago',
    ];
    final skillsTagPool = const [
      {'flutter', 'dart', 'mobile', 'ui'},
      {'api', 'system design', 'architecture', 'rest'},
      {'firebase', 'ci/cd', 'testing', 'debugging'},
      {'product', 'analytics', 'git', 'agile'},
      {'android', 'ios', 'graphql', 'node.js'},
    ];

    final jobs = <_JobSuggestion>[];
    for (final template in templates) {
      for (var i = 0; i < template.titleVariants.length; i++) {
        jobs.add(
          _JobSuggestion(
            title: template.titleVariants[i],
            company: template.companies[i],
            location: template.locations[i],
            applyUrl: template.applyBaseUrl,
            source: template.source,
            postedAgo: recency[i % recency.length],
            tags: skillsTagPool[i % skillsTagPool.length],
          ),
        );
      }
    }

    // Feed is fixed to last 7 days only (all seeded entries satisfy this).
    return jobs.where((job) => _isWithinLast7Days(job.postedAgo)).toList();
  }

  String _targetRoleForResume(ResumeData resume) {
    final jobTitle = resume.jobTitle.trim();
    if (jobTitle.isNotEmpty) return jobTitle;

    final summary = resume.summary.toLowerCase();
    final skills = resume.skillsForResume.map((s) => s.toLowerCase()).toSet();
    if (summary.contains('flutter') || skills.any((s) => s.contains('flutter'))) {
      return 'Flutter Developer';
    }
    if (summary.contains('android') || skills.any((s) => s.contains('android'))) {
      return 'Android Developer';
    }
    if (summary.contains('ios') || skills.any((s) => s.contains('ios'))) {
      return 'iOS Developer';
    }
    if (summary.contains('data') || skills.any((s) => s.contains('sql'))) {
      return 'Data Analyst';
    }
    return 'Software Engineer';
  }

  bool _isWithinLast7Days(String postedAgo) {
    if (postedAgo.contains('h')) return true;
    if (postedAgo.contains('d')) {
      final days = int.tryParse(postedAgo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return days <= 7;
    }
    return true;
  }
}

class _JobTemplate {
  const _JobTemplate({
    required this.source,
    required this.applyBaseUrl,
    required this.companies,
    required this.titleVariants,
    required this.locations,
  });

  final String source;
  final String applyBaseUrl;
  final List<String> companies;
  final List<String> titleVariants;
  final List<String> locations;
}

class _JobSuggestion {
  const _JobSuggestion({
    required this.title,
    required this.company,
    required this.location,
    required this.applyUrl,
    required this.source,
    required this.postedAgo,
    required this.tags,
  });

  final String title;
  final String company;
  final String location;
  final String applyUrl;
  final String source;
  final String postedAgo;
  final Set<String> tags;

  int matchScore(Set<String> resumeKeywords) {
    if (resumeKeywords.isEmpty) {
      return 0;
    }
    return tags.intersection(resumeKeywords).length;
  }

  int get ageInHours {
    final number = int.tryParse(postedAgo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (postedAgo.contains('h')) {
      return number;
    }
    if (postedAgo.contains('d')) {
      return number * 24;
    }
    return 9999;
  }
}
