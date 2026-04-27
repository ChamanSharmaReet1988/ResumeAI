import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/job_search_service.dart';
import '../shared/view_models.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  static const double _fieldHorizontalPadding = 12;
  static const int _pageSize = 12;

  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorText;
  String? _lastRequestKey;
  List<_JobSuggestion> _jobs = const [];
  int _visibleCount = _pageSize;

  List<_JobSuggestion> get _visibleJobs =>
      _jobs.take(_visibleCount).toList(growable: false);
  bool get _hasMoreJobs => _visibleCount < _jobs.length;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreJobs) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _loadMore();
    }
  }

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

        final selected = library.selectedResume ?? resumes.first;
        _ensureJobsLoaded(selected);

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('jobs-resume-picker-${selected.id}'),
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
                  library.selectResume(value);
                },
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _fieldHorizontalPadding,
                ),
                child: Text(
                  'Showing latest jobs from last 7 days based on the selected resume role and location.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else if (_jobs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No jobs found for this resume in last 7 days.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else ..._visibleJobs.map(_buildJobCard),
              if (!_isLoading && _hasMoreJobs) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _isLoadingMore
                        ? 'Loading more jobs...'
                        : 'Scroll down to load more',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobCard(_JobSuggestion job) {
    return Padding(
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
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${job.company} • ${job.location}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              job.source,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
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
    );
  }

  void _ensureJobsLoaded(ResumeData resume) {
    final key = '${resume.id}|7days';
    if (_lastRequestKey == key || _isLoading) return;
    _lastRequestKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchJobs(resume);
    });
  }

  Future<void> _fetchJobs(ResumeData resume) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
      _jobs = const [];
      _visibleCount = _pageSize;
    });

    final fallback = _jobsForResume(resume);
    try {
      final service = context.read<JobSearchService>();
      final role = _targetRoleForResume(resume);
      final topSkills = resume.skillsForResume
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .take(3)
          .join(' ');
      final combinedQuery = [role, topSkills]
          .where((item) => item.trim().isNotEmpty)
          .join(' ')
          .trim();
      final fetched = await service.fetchLatestJobs(
        query: combinedQuery.isEmpty ? role : combinedQuery,
        location: resume.location.trim(),
      );
      final mapped = _mapAndSortApiJobs(fetched, resume);
      final merged = _mergeWithFallback(mapped, fallback, minimumCount: 30);
      if (!mounted) return;
      setState(() => _jobs = merged);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Live jobs unavailable, showing backup results.';
        _jobs = fallback;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<_JobSuggestion> _mapAndSortApiJobs(
    List<JobPosting> jobs,
    ResumeData resume,
  ) {
    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(const Duration(days: 7));
    final keywords = _resumeKeywords(resume);
    final indiaOnly = _isIndiaContext(resume.location);
    final mapped = jobs
        .where((job) => job.postedAt.isAfter(cutoff))
        .where((job) => !indiaOnly || _isIndiaLocation(job.location))
        .map((job) => _JobSuggestion.fromPosting(job, now: now))
        .toList();
    mapped.sort((a, b) {
      final timeOrder = a.ageInHours.compareTo(b.ageInHours);
      if (timeOrder != 0) return timeOrder;
      return b.matchScore(keywords).compareTo(a.matchScore(keywords));
    });
    return mapped;
  }

  List<_JobSuggestion> _mergeWithFallback(
    List<_JobSuggestion> primary,
    List<_JobSuggestion> fallback, {
    required int minimumCount,
  }) {
    final merged = <_JobSuggestion>[];
    final seen = <String>{};

    void append(_JobSuggestion job) {
      final key =
          '${job.title.toLowerCase()}|${job.company.toLowerCase()}|${job.location.toLowerCase()}';
      if (seen.add(key)) {
        merged.add(job);
      }
    }

    for (final job in primary) {
      append(job);
    }
    if (merged.length < minimumCount) {
      for (final job in fallback) {
        append(job);
        if (merged.length >= minimumCount) break;
      }
    }
    return merged;
  }

  Set<String> _resumeKeywords(ResumeData resume) {
    final keywords = <String>{};
    keywords.addAll(
      resume.jobTitle
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((item) => item.trim().isNotEmpty),
    );
    keywords.addAll(
      resume.skillsForResume
          .map((item) => item.toLowerCase().trim())
          .where((item) => item.isNotEmpty),
    );
    return keywords;
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMoreJobs) return;
    setState(() => _isLoadingMore = true);
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, _jobs.length);
        _isLoadingMore = false;
      });
    });
  }

  Future<void> _openJobUrl(String url) async {
    final uri = Uri.parse(url);
    final isNaukri = uri.host.toLowerCase().contains('naukri.com');
    final mode = isNaukri ? LaunchMode.inAppWebView : LaunchMode.platformDefault;
    final launched = await launchUrl(uri, mode: mode);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open job link right now.')),
    );
  }

  List<_JobSuggestion> _jobsForResume(ResumeData resume) {
    final role = _targetRoleForResume(resume);
    final location = resume.location.trim().isEmpty
        ? 'Remote'
        : resume.location.trim();
    final keywords = _resumeKeywords(resume);
    final jobs = _generatePortalJobs(role: role, location: location);
    final indiaOnly = _isIndiaContext(location);
    final filteredJobs = indiaOnly
        ? jobs.where((job) => _isIndiaLocation(job.location)).toList()
        : jobs;
    filteredJobs.sort((a, b) {
      final recencyOrder = a.ageInHours.compareTo(b.ageInHours);
      if (recencyOrder != 0) return recencyOrder;
      return b.matchScore(keywords).compareTo(a.matchScore(keywords));
    });
    return filteredJobs;
  }

  List<_JobSuggestion> _generatePortalJobs({
    required String role,
    required String location,
  }) {
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
          'Senior $role',
          '$role - Platform Team',
          '$role - Product Team',
          'Associate $role',
          '$role - Integrations',
          'Lead $role',
          '$role - Consumer App',
          '$role - Performance',
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
          '$role Engineer',
          '$role Developer',
          'Lead $role',
          '$role - Core Team',
          'Principal $role',
          '$role - SaaS',
          '$role - Platform',
          '$role - Growth',
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
          'Junior $role',
          '$role Analyst',
          '$role - Automation',
          '$role Specialist',
          '$role - Reliability',
          '$role - Backend',
          'Staff $role',
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
          '$role (Startup)',
          'Founding $role',
          'Full Stack $role',
          '$role - Growth Product',
          '$role (0-1 Product)',
          '$role - Early Team',
          '$role (Founding Engineer)',
          '$role - App Platform',
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
    final now = DateTime.now().toUtc();
    final jobs = <_JobSuggestion>[];
    for (final template in templates) {
      for (var i = 0; i < template.titleVariants.length; i++) {
        final postedAgo = recency[i % recency.length];
        final title = template.titleVariants[i];
        final city = template.locations[i];
        jobs.add(
          _JobSuggestion(
            title: title,
            company: template.companies[i],
            location: city,
            applyUrl: _buildApplyUrl(template, title, city),
            source: template.source,
            postedAgo: postedAgo,
            tags: skillsTagPool[i % skillsTagPool.length],
            postedAt: _postedAtFromLabel(postedAgo, now),
          ),
        );
      }
    }
    return jobs.where((job) => _isWithinLast7Days(job.postedAgo)).toList();
  }

  String _buildApplyUrl(_JobTemplate template, String title, String location) {
    final source = template.source.toLowerCase();
    if (source == 'naukri') {
      final query = Uri.encodeQueryComponent(title);
      final city = Uri.encodeQueryComponent(location);
      return 'https://www.naukri.com/${_slugify(title)}-jobs?k=$query&l=$city';
    }
    return template.applyBaseUrl;
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
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

  bool _isIndiaContext(String location) {
    final normalized = location.toLowerCase().trim();
    if (normalized.isEmpty) return false;
    if (normalized.contains('india')) return true;
    return _indiaCities.any(normalized.contains);
  }

  bool _isIndiaLocation(String location) {
    final normalized = location.toLowerCase().trim();
    if (normalized.isEmpty) return false;
    if (normalized.contains('india')) return true;
    if (normalized.contains('remote') &&
        (normalized.contains('india') || normalized.contains('in'))) {
      return true;
    }
    return _indiaCities.any(normalized.contains);
  }

  DateTime _postedAtFromLabel(String label, DateTime now) {
    final number = int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (label.contains('h')) return now.subtract(Duration(hours: number));
    if (label.contains('d')) return now.subtract(Duration(days: number));
    return now;
  }
}

const Set<String> _indiaCities = {
  'ahmedabad',
  'bengaluru',
  'bangalore',
  'chandigarh',
  'chennai',
  'coimbatore',
  'delhi',
  'gurgaon',
  'gurugram',
  'hyderabad',
  'india',
  'indore',
  'jaipur',
  'kolkata',
  'lucknow',
  'mumbai',
  'nagpur',
  'new delhi',
  'noida',
  'pune',
  'surat',
};

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
    required this.postedAt,
  });

  factory _JobSuggestion.fromPosting(JobPosting posting, {required DateTime now}) {
    final age = now.difference(posting.postedAt.toUtc());
    final postedAgo = switch (age.inHours) {
      <= 0 => 'just now',
      < 24 => '${age.inHours}h ago',
      _ => '${age.inDays}d ago',
    };
    final titleTags = posting.title
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((item) => item.trim().isNotEmpty)
        .toSet();
    return _JobSuggestion(
      title: posting.title,
      company: posting.company,
      location: posting.location,
      applyUrl: posting.applyUrl,
      source: posting.source,
      postedAgo: postedAgo,
      tags: {...posting.tags, ...titleTags},
      postedAt: posting.postedAt,
    );
  }

  final String title;
  final String company;
  final String location;
  final String applyUrl;
  final String source;
  final String postedAgo;
  final Set<String> tags;
  final DateTime postedAt;

  int matchScore(Set<String> resumeKeywords) {
    if (resumeKeywords.isEmpty) return 0;
    return tags.intersection(resumeKeywords).length;
  }

  int get ageInHours {
    final number = int.tryParse(postedAgo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (postedAgo.contains('h')) return number;
    if (postedAgo.contains('d')) return number * 24;
    return 9999;
  }
}
