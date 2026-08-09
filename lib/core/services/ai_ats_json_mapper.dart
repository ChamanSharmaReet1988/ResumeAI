import 'dart:convert';

import '../models/resume_models.dart';
import 'resume_services.dart';

/// Shared prompt + JSON mapping for cloud / Apple on-device ATS generation.
class AiAtsJsonMapper {
  const AiAtsJsonMapper();

  String buildPrompt({
    required ResumeData sourceResume,
    String jobDescription = '',
    int attemptIndex = 0,
    bool compact = false,
  }) {
    final workLimit = compact ? 3 : 8;
    final bulletLimit = compact ? 3 : 6;
    final skillLimit = compact ? 12 : 24;
    final jobLimit = compact ? 700 : 4000;

    final payload = {
      'jobTitle': sourceResume.jobTitle,
      'summary': sourceResume.summary,
      'skills': sourceResume.skills.take(skillLimit).toList(),
      'workExperiences': sourceResume.workExperiences
          .where((item) => !item.isBlank)
          .take(workLimit)
          .map(
            (item) => {
              'role': item.role,
              'company': item.company,
              'startDate': item.startDate,
              'endDate': item.endDate,
              'bullets': item.bullets.take(bulletLimit).toList(),
              if (!compact) 'description': item.description,
            },
          )
          .toList(),
      if (!compact)
        'education': sourceResume.education
            .where((item) => !item.isBlank)
            .take(4)
            .map(
              (item) => {
                'institution': item.institution,
                'degree': item.degree,
                'startDate': item.startDate,
                'endDate': item.endDate,
              },
            )
            .toList(),
      if (!compact)
        'projects': sourceResume.projects
            .where((item) => !item.isBlank)
            .take(3)
            .map(
              (item) => {
                'title': item.title,
                'overview': item.overview,
                'bullets': item.bullets.take(3).toList(),
              },
            )
            .toList(),
    };

    final trimmedJob = jobDescription.trim();
    final jobBlock = trimmedJob.isEmpty
        ? 'No job description provided. Optimize for general ATS readability.'
        : 'Target job description:\n${trimmedJob.length > jobLimit ? trimmedJob.substring(0, jobLimit) : trimmedJob}';

    return '''
You are an expert resume writer. Rewrite the resume into a clean ChatGPT/Claude-style ATS resume.

Rules:
- Keep facts truthful. Do not invent employers, degrees, or dates.
- Strengthen summary and bullets with clear action verbs and measurable impact when supported.
- Prefer 4-5 strong bullets per role.
- Flatten skills into a simple keyword list (12-18 skills).
- Optimization pass index: $attemptIndex (0 = first ATS draft; higher = further refine).
- $jobBlock

Return ONLY valid JSON (no markdown) with this shape:
{
  "jobTitle": "string",
  "summary": "string",
  "skills": ["string"],
  "workExperiences": [
    {
      "role": "string",
      "company": "string",
      "bullets": ["string"]
    }
  ],
  "appliedChanges": ["string"]
]

Match workExperiences to the same companies/roles when possible.

Resume JSON:
${jsonEncode(payload)}
''';
  }

  ResumeImprovementResult mapResponse({
    required ResumeData sourceResume,
    required String rawResponse,
    required String engineLabel,
  }) {
    final json = _extractJsonObject(rawResponse);
    final jobTitle = (json['jobTitle'] as String?)?.trim();
    final summary = (json['summary'] as String?)?.trim();
    final skills = (json['skills'] as List<dynamic>? ?? [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final appliedChanges = (json['appliedChanges'] as List<dynamic>? ?? [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final aiWork = (json['workExperiences'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final updatedWork = sourceResume.workExperiences.map((item) {
      if (item.isBlank) {
        return item;
      }
      final match = _matchWorkExperience(item, aiWork);
      if (match == null) {
        return item;
      }
      final bullets = (match['bullets'] as List<dynamic>? ?? [])
          .map((bullet) => bullet.toString().trim())
          .where((bullet) => bullet.isNotEmpty)
          .toList();
      if (bullets.isEmpty) {
        return item;
      }
      return item.copyWith(
        role: (match['role'] as String?)?.trim().isNotEmpty == true
            ? (match['role'] as String).trim()
            : item.role,
        company: (match['company'] as String?)?.trim().isNotEmpty == true
            ? (match['company'] as String).trim()
            : item.company,
        bullets: bullets.take(5).toList(),
        layoutMode: WorkExperienceLayoutMode.bullets,
      );
    }).toList();

    final changes = <String>[
      'Generated ATS resume with $engineLabel.',
      ...appliedChanges,
    ];
    if (changes.length == 1) {
      changes.add('Rewrote summary, skills, and experience for ATS scanners.');
    }

    return ResumeImprovementResult(
      resume: sourceResume.copyWith(
        jobTitle: (jobTitle != null && jobTitle.isNotEmpty)
            ? jobTitle
            : sourceResume.jobTitle,
        summary: (summary != null && summary.isNotEmpty)
            ? summary
            : sourceResume.summary,
        skills: skills.isNotEmpty ? skills.take(18).toList() : sourceResume.skills,
        useSkillSubheadings: false,
        skillGroups: const [],
        workExperiences: updatedWork,
        template: ResumeTemplate.atsLatexClassic,
        updatedAt: DateTime.now(),
      ),
      appliedChanges: changes,
    );
  }

  Map<String, dynamic> _extractJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty AI response.');
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      // Fall through to fence / substring extraction.
    }

    final fenceMatch = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (fenceMatch != null) {
      final inner = fenceMatch.group(1)?.trim() ?? '';
      final decoded = jsonDecode(inner);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final decoded = jsonDecode(trimmed.substring(start, end + 1));
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw const FormatException('AI response was not valid JSON.');
  }

  Map<String, dynamic>? _matchWorkExperience(
    WorkExperience source,
    List<Map<String, dynamic>> aiWork,
  ) {
    final company = source.company.trim().toLowerCase();
    final role = source.role.trim().toLowerCase();

    for (final item in aiWork) {
      final itemCompany = (item['company'] as String? ?? '')
          .trim()
          .toLowerCase();
      final itemRole = (item['role'] as String? ?? '').trim().toLowerCase();
      if (company.isNotEmpty &&
          itemCompany == company &&
          (role.isEmpty || itemRole == role || itemRole.contains(role))) {
        return item;
      }
    }

    for (final item in aiWork) {
      final itemRole = (item['role'] as String? ?? '').trim().toLowerCase();
      if (role.isNotEmpty && itemRole == role) {
        return item;
      }
    }

    if (aiWork.length == 1) {
      return aiWork.first;
    }
    return null;
  }
}
