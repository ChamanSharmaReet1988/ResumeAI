import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

class JobSearchService {
  JobSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<JobPosting>> fetchLatestJobs({
    required String query,
    String? location,
  }) async {
    final remotiveFuture = _fetchRemotive(query: query, location: location);
    final arbeitnowFuture = _fetchArbeitnow(query: query);
    final results = await Future.wait<List<JobPosting>>(
      [remotiveFuture, arbeitnowFuture],
      eagerError: false,
    );

    final merged = <JobPosting>[];
    for (final source in results) {
      merged.addAll(source);
    }
    if (merged.isEmpty) {
      throw JobSearchException('Could not fetch jobs right now.');
    }
    return _dedupe(merged);
  }

  Future<List<JobPosting>> _fetchRemotive({
    required String query,
    String? location,
  }) async {
    try {
      final uri = Uri.https('remotive.com', '/api/remote-jobs', {
        'search': query.trim(),
        if (location != null && location.trim().isNotEmpty)
          'location': location.trim(),
        'limit': '100',
      });
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return const [];
      }
      final jobsRaw = payload['jobs'];
      if (jobsRaw is! List) {
        return const [];
      }
      return jobsRaw
          .whereType<Map<String, dynamic>>()
          .map(JobPosting.fromRemotiveJson)
          .where((job) => job.title.trim().isNotEmpty && job.applyUrl.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<JobPosting>> _fetchArbeitnow({required String query}) async {
    try {
      final uri = Uri.https('www.arbeitnow.com', '/api/job-board-api', {
        'search': query.trim(),
        'page': '1',
      });
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return const [];
      }
      final jobsRaw = payload['data'];
      if (jobsRaw is! List) {
        return const [];
      }
      return jobsRaw
          .whereType<Map<String, dynamic>>()
          .map(JobPosting.fromArbeitnowJson)
          .where((job) => job.title.trim().isNotEmpty && job.applyUrl.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<JobPosting> _dedupe(List<JobPosting> jobs) {
    final deduped = <JobPosting>[];
    final seen = <String>{};
    for (final job in jobs) {
      final key =
          '${job.title.toLowerCase()}|${job.company.toLowerCase()}|${job.location.toLowerCase()}|${job.source.toLowerCase()}';
      if (seen.add(key)) {
        deduped.add(job);
      }
    }
    deduped.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return deduped;
  }
}

class JobPosting {
  const JobPosting({
    required this.title,
    required this.company,
    required this.location,
    required this.applyUrl,
    required this.source,
    required this.postedAt,
    required this.tags,
  });

  factory JobPosting.fromRemotiveJson(Map<String, dynamic> json) {
    final postedRaw = json['publication_date']?.toString() ?? '';
    final postedAt = DateTime.tryParse(postedRaw)?.toUtc() ?? DateTime.now().toUtc();
    final tagsRaw = json['tags'];
    return JobPosting(
      title: (json['title']?.toString() ?? '').trim(),
      company: (json['company_name']?.toString() ?? '').trim().isEmpty
          ? 'Unknown company'
          : (json['company_name']?.toString() ?? '').trim(),
      location: (json['candidate_required_location']?.toString() ?? '').trim().isEmpty
          ? 'Remote'
          : (json['candidate_required_location']?.toString() ?? '').trim(),
      applyUrl: (json['url']?.toString() ?? '').trim(),
      source: 'Remotive',
      postedAt: postedAt,
      tags: {
        ...(switch (tagsRaw) {
          List _ => tagsRaw
              .whereType<String>()
              .map((tag) => tag.trim().toLowerCase())
              .where((tag) => tag.isNotEmpty),
          _ => const <String>[],
        }),
      },
    );
  }

  factory JobPosting.fromArbeitnowJson(Map<String, dynamic> json) {
    final postedRaw = json['created_at']?.toString() ?? '';
    final postedAt = _parseArbeitnowDate(postedRaw);
    final tagsRaw = json['tags'];
    final location = (json['location']?.toString() ?? '').trim();
    final title = (json['title']?.toString() ?? '').trim();
    final company = (json['company_name']?.toString() ?? '').trim();
    final slug = (json['slug']?.toString() ?? '').trim();
    final url = slug.isEmpty
        ? (json['url']?.toString() ?? '').trim()
        : 'https://www.arbeitnow.com/jobs/$slug';
    return JobPosting(
      title: title,
      company: company.isEmpty ? 'Unknown company' : company,
      location: location.isEmpty ? 'Remote' : location,
      applyUrl: url,
      source: 'Arbeitnow',
      postedAt: postedAt,
      tags: {
        ...(switch (tagsRaw) {
          List _ => tagsRaw
              .whereType<String>()
              .map((tag) => tag.trim().toLowerCase())
              .where((tag) => tag.isNotEmpty),
          _ => const <String>[],
        }),
      },
    );
  }

  final String title;
  final String company;
  final String location;
  final String applyUrl;
  final String source;
  final DateTime postedAt;
  final Set<String> tags;
}

DateTime _parseArbeitnowDate(String raw) {
  if (raw.trim().isEmpty) return DateTime.now().toUtc();
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return parsed.toUtc();
  final lower = raw.toLowerCase();
  if (lower.contains('hour')) {
    final n = int.tryParse(lower.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return DateTime.now().toUtc().subtract(Duration(hours: math.max(1, n)));
  }
  if (lower.contains('day')) {
    final n = int.tryParse(lower.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return DateTime.now().toUtc().subtract(Duration(days: math.max(1, n)));
  }
  return DateTime.now().toUtc();
}

class JobSearchException implements Exception {
  const JobSearchException(this.message);
  final String message;
}
