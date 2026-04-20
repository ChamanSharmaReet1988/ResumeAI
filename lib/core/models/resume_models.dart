import 'package:flutter/material.dart';

import '../resume_text_font.dart';

enum ResumeTemplate {
  minimal,
  corporate,
  creative,
  copperSerif,
  splitBanner,
  monogramSidebar,
}

enum CoverLetterTemplate { executiveNote, minimalLetter, sidebarLetter }

const availableResumeTemplates = <ResumeTemplate>[
  ResumeTemplate.corporate,
  ResumeTemplate.minimal,
  ResumeTemplate.creative,
  ResumeTemplate.copperSerif,
  ResumeTemplate.splitBanner,
  ResumeTemplate.monogramSidebar,
];

extension ResumeTemplateX on ResumeTemplate {
  ResumeTemplate get userFacingTemplate => this;

  String get label => switch (userFacingTemplate) {
    ResumeTemplate.minimal => 'Centered Classic',
    ResumeTemplate.corporate => 'Dark Header',
    ResumeTemplate.creative => 'Profile Sidebar',
    ResumeTemplate.copperSerif => 'Copper Serif',
    ResumeTemplate.splitBanner => 'Split Banner',
    ResumeTemplate.monogramSidebar => 'Monogram Sidebar',
  };

  String get description => switch (userFacingTemplate) {
    ResumeTemplate.minimal =>
      'Centered name block with a timeless layout and clean section dividers.',
    ResumeTemplate.corporate =>
      'Dark top header with a strong structured layout and compact sections.',
    ResumeTemplate.creative =>
      'Profile-led layout with bold side accents and editorial-style sections.',
    ResumeTemplate.copperSerif =>
      'Centered name styling with warm copper section accents and elegant dividers.',
    ResumeTemplate.splitBanner =>
      'Bold copper banner header with a structured editorial layout underneath.',
    ResumeTemplate.monogramSidebar =>
      'Monogram-led sidebar with contact details on the left and content on the right.',
  };

  Color get accentColor => switch (userFacingTemplate) {
    ResumeTemplate.minimal => const Color(0xFF111827),
    ResumeTemplate.corporate => const Color(0xFF0F766E),
    ResumeTemplate.creative => const Color(0xFFE85D04),
    ResumeTemplate.copperSerif => const Color(0xFFE7A055),
    ResumeTemplate.splitBanner => const Color(0xFFEE9938),
    ResumeTemplate.monogramSidebar => const Color(0xFFE39A3A),
  };

  Color get tintColor => switch (userFacingTemplate) {
    ResumeTemplate.minimal => const Color(0xFFF3F4F6),
    ResumeTemplate.corporate => const Color(0xFFE4FBF6),
    ResumeTemplate.creative => const Color(0xFFFFE9D8),
    ResumeTemplate.copperSerif => const Color(0xFFFFF4E9),
    ResumeTemplate.splitBanner => const Color(0xFFFFF0E0),
    ResumeTemplate.monogramSidebar => const Color(0xFFFFF3E3),
  };

  /// Short typography hint for the style sheet (PDF uses built-in fonts per layout).
  String get fontStyleLabel => switch (userFacingTemplate) {
    ResumeTemplate.minimal => 'Sans · centered classic',
    ResumeTemplate.corporate => 'Sans · dark header',
    ResumeTemplate.creative => 'Sans · profile sidebar',
    ResumeTemplate.copperSerif => 'Serif accents · warm',
    ResumeTemplate.splitBanner => 'Sans · banner header',
    ResumeTemplate.monogramSidebar => 'Sans · monogram sidebar',
  };
}

extension CoverLetterTemplateX on CoverLetterTemplate {
  String get label => switch (this) {
    CoverLetterTemplate.executiveNote => 'Executive Note',
    CoverLetterTemplate.minimalLetter => 'Minimal Letter',
    CoverLetterTemplate.sidebarLetter => 'Sidebar Letter',
  };
}

class ResumeData {
  static const defaultTitle = 'Untitled Resume';

  const ResumeData({
    required this.id,
    required this.title,
    required this.fullName,
    required this.jobTitle,
    required this.email,
    required this.phone,
    required this.location,
    required this.website,
    required this.summary,
    required this.template,
    required this.workExperiences,
    required this.education,
    required this.skills,
    required this.projects,
    required this.customSections,
    required this.updatedAt,
    required this.githubLink,
    required this.linkedinLink,
    required this.profileImagePath,
    required this.resumeTextFont,
    required this.includeWorkInResume,
    required this.includeEducationInResume,
    required this.includeSkillsInResume,
    required this.includeProjectsInResume,
  });

  factory ResumeData.empty({required ResumeTemplate template}) {
    return ResumeData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: defaultTitle,
      fullName: '',
      jobTitle: '',
      email: '',
      phone: '',
      location: '',
      website: '',
      summary: '',
      template: template,
      workExperiences: const [WorkExperience.empty()],
      education: const [EducationItem.empty()],
      skills: const [],
      projects: const [ProjectItem.empty()],
      customSections: const [],
      updatedAt: DateTime.now(),
      githubLink: '',
      linkedinLink: '',
      profileImagePath: '',
      resumeTextFont: ResumeTextFont.inter,
      includeWorkInResume: true,
      includeEducationInResume: true,
      includeSkillsInResume: true,
      includeProjectsInResume: true,
    );
  }

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    return ResumeData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? defaultTitle,
      fullName: json['fullName'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      website: json['website'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      template: ResumeTemplate.values.firstWhere(
        (value) => value.name == json['template'],
        orElse: () => ResumeTemplate.corporate,
      ),
      workExperiences: (json['workExperiences'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                WorkExperience.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      education: (json['education'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                EducationItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      projects: (json['projects'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ProjectItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      customSections: (json['customSections'] as List<dynamic>? ?? [])
          .map(
            (item) => CustomSectionItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      githubLink: json['githubLink'] as String? ?? '',
      linkedinLink: json['linkedinLink'] as String? ?? '',
      profileImagePath: json['profileImagePath'] as String? ?? '',
      resumeTextFont: resumeTextFontFromStorage(
        json['resumeTextFont'] as String?,
      ),
      includeWorkInResume: json['includeWorkInResume'] as bool? ?? true,
      includeEducationInResume: json['includeEducationInResume'] as bool? ?? true,
      includeSkillsInResume: json['includeSkillsInResume'] as bool? ?? true,
      includeProjectsInResume: json['includeProjectsInResume'] as bool? ?? true,
    );
  }

  final String id;
  final String title;
  final String fullName;
  final String jobTitle;
  final String email;
  final String phone;
  final String location;
  final String website;
  final String summary;
  final ResumeTemplate template;
  final List<WorkExperience> workExperiences;
  final List<EducationItem> education;
  final List<String> skills;
  final List<ProjectItem> projects;
  final List<CustomSectionItem> customSections;
  final DateTime updatedAt;
  final String githubLink;
  final String linkedinLink;
  final String profileImagePath;
  final ResumeTextFont resumeTextFont;
  final bool includeWorkInResume;
  final bool includeEducationInResume;
  final bool includeSkillsInResume;
  final bool includeProjectsInResume;

  List<WorkExperience> get visibleWorkExperiences =>
      includeWorkInResume
          ? workExperiences.where((item) => !item.isBlank).toList()
          : const <WorkExperience>[];

  List<EducationItem> get visibleEducation =>
      includeEducationInResume
          ? education.where((item) => !item.isBlank).toList()
          : const <EducationItem>[];

  List<ProjectItem> get visibleProjects =>
      includeProjectsInResume
          ? projects.where((item) => !item.isBlank).toList()
          : const <ProjectItem>[];

  /// Skills shown on preview/PDF when the section is included.
  List<String> get skillsForResume =>
      includeSkillsInResume ? skills : const <String>[];

  List<CustomSectionItem> get visibleCustomSections =>
      customSections.where((item) => !item.isBlank).toList();

  double get completionRatio {
    var completed = 0;
    const total = 8;
    if (fullName.trim().isNotEmpty) completed++;
    if (jobTitle.trim().isNotEmpty) completed++;
    if (email.trim().isNotEmpty && phone.trim().isNotEmpty) completed++;
    if (summary.trim().length > 50) completed++;
    if (visibleWorkExperiences.isNotEmpty) completed++;
    if (visibleEducation.isNotEmpty) completed++;
    if (skills.length >= 5) completed++;
    if (visibleProjects.isNotEmpty) completed++;
    return completed / total;
  }

  bool get hasMeaningfulContent =>
      completionRatio > 0.15 ||
      fullName.trim().isNotEmpty ||
      jobTitle.trim().isNotEmpty;

  bool get hasRequiredPersonalInfo {
    final normalizedTitle = title.trim();
    return normalizedTitle.isNotEmpty &&
        normalizedTitle != defaultTitle &&
        fullName.trim().isNotEmpty &&
        jobTitle.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        summary.trim().isNotEmpty;
  }

  ResumeData copyWith({
    String? id,
    String? title,
    String? fullName,
    String? jobTitle,
    String? email,
    String? phone,
    String? location,
    String? website,
    String? summary,
    ResumeTemplate? template,
    List<WorkExperience>? workExperiences,
    List<EducationItem>? education,
    List<String>? skills,
    List<ProjectItem>? projects,
    List<CustomSectionItem>? customSections,
    DateTime? updatedAt,
    String? githubLink,
    String? linkedinLink,
    String? profileImagePath,
    ResumeTextFont? resumeTextFont,
    bool? includeWorkInResume,
    bool? includeEducationInResume,
    bool? includeSkillsInResume,
    bool? includeProjectsInResume,
  }) {
    return ResumeData(
      id: id ?? this.id,
      title: title ?? this.title,
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      summary: summary ?? this.summary,
      template: template ?? this.template,
      workExperiences: workExperiences ?? this.workExperiences,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      customSections: customSections ?? this.customSections,
      updatedAt: updatedAt ?? this.updatedAt,
      githubLink: githubLink ?? this.githubLink,
      linkedinLink: linkedinLink ?? this.linkedinLink,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      resumeTextFont: resumeTextFont ?? this.resumeTextFont,
      includeWorkInResume: includeWorkInResume ?? this.includeWorkInResume,
      includeEducationInResume:
          includeEducationInResume ?? this.includeEducationInResume,
      includeSkillsInResume: includeSkillsInResume ?? this.includeSkillsInResume,
      includeProjectsInResume:
          includeProjectsInResume ?? this.includeProjectsInResume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'fullName': fullName,
      'jobTitle': jobTitle,
      'email': email,
      'phone': phone,
      'location': location,
      'website': website,
      'summary': summary,
      'template': template.name,
      'workExperiences': workExperiences.map((item) => item.toJson()).toList(),
      'education': education.map((item) => item.toJson()).toList(),
      'skills': skills,
      'projects': projects.map((item) => item.toJson()).toList(),
      'customSections': customSections.map((item) => item.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
      'githubLink': githubLink,
      'linkedinLink': linkedinLink,
      'profileImagePath': profileImagePath,
      'resumeTextFont': resumeTextFont.name,
      'includeWorkInResume': includeWorkInResume,
      'includeEducationInResume': includeEducationInResume,
      'includeSkillsInResume': includeSkillsInResume,
      'includeProjectsInResume': includeProjectsInResume,
    };
  }
}

class CoverLetterData {
  const CoverLetterData({
    required this.id,
    required this.title,
    required this.company,
    required this.role,
    required this.template,
    required this.skillToHighlight,
    required this.language,
    required this.content,
    required this.updatedAt,
  });

  factory CoverLetterData.empty() {
    return CoverLetterData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '',
      company: '',
      role: '',
      template: CoverLetterTemplate.executiveNote,
      skillToHighlight: '',
      language: '',
      content: '',
      updatedAt: DateTime.now(),
    );
  }

  factory CoverLetterData.fromJson(Map<String, dynamic> json) {
    return CoverLetterData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      role: json['role'] as String? ?? '',
      template: CoverLetterTemplate.values.firstWhere(
        (value) => value.name == json['template'],
        orElse: () => CoverLetterTemplate.executiveNote,
      ),
      skillToHighlight: json['skillToHighlight'] as String? ?? '',
      language: json['language'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String company;
  final String role;
  final CoverLetterTemplate template;
  final String skillToHighlight;
  final String language;
  final String content;
  final DateTime updatedAt;

  bool get hasMeaningfulContent =>
      title.trim().isNotEmpty ||
      company.trim().isNotEmpty ||
      role.trim().isNotEmpty ||
      skillToHighlight.trim().isNotEmpty ||
      language.trim().isNotEmpty ||
      content.trim().isNotEmpty;

  String get displayTitle {
    if (title.trim().isNotEmpty) {
      return title.trim();
    }

    final generated = [
      role.trim(),
      company.trim(),
    ].where((item) => item.isNotEmpty).join(' · ');

    return generated.isEmpty ? 'Untitled Cover Letter' : generated;
  }

  CoverLetterData copyWith({
    String? id,
    String? title,
    String? company,
    String? role,
    CoverLetterTemplate? template,
    String? skillToHighlight,
    String? language,
    String? content,
    DateTime? updatedAt,
  }) {
    return CoverLetterData(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      role: role ?? this.role,
      template: template ?? this.template,
      skillToHighlight: skillToHighlight ?? this.skillToHighlight,
      language: language ?? this.language,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'role': role,
      'template': template.name,
      'skillToHighlight': skillToHighlight,
      'language': language,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class WorkExperience {
  const WorkExperience({
    required this.role,
    required this.company,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.bullets,
  });

  const WorkExperience.empty()
    : role = '',
      company = '',
      startDate = '',
      endDate = '',
      description = '',
      bullets = const [];

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      role: json['role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bullets: (json['bullets'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
    );
  }

  final String role;
  final String company;
  final String startDate;
  final String endDate;
  final String description;
  final List<String> bullets;

  bool get isBlank =>
      role.trim().isEmpty &&
      company.trim().isEmpty &&
      description.trim().isEmpty &&
      bullets.isEmpty;

  WorkExperience copyWith({
    String? role,
    String? company,
    String? startDate,
    String? endDate,
    String? description,
    List<String>? bullets,
  }) {
    return WorkExperience(
      role: role ?? this.role,
      company: company ?? this.company,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      bullets: bullets ?? this.bullets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'company': company,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
      'bullets': bullets,
    };
  }
}

class EducationItem {
  const EducationItem({
    required this.institution,
    required this.degree,
    required this.year,
    required this.score,
    required this.details,
  });

  const EducationItem.empty()
    : institution = '',
      degree = '',
      year = '',
      score = '',
      details = '';

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    return EducationItem(
      institution: json['institution'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      year: json['year'] as String? ?? '',
      score: json['score'] as String? ?? '',
      details: json['details'] as String? ?? '',
    );
  }

  final String institution;
  final String degree;
  final String year;
  final String score;
  final String details;

  bool get isBlank =>
      institution.trim().isEmpty &&
      degree.trim().isEmpty &&
      year.trim().isEmpty &&
      score.trim().isEmpty &&
      details.trim().isEmpty;

  EducationItem copyWith({
    String? institution,
    String? degree,
    String? year,
    String? score,
    String? details,
  }) {
    return EducationItem(
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      year: year ?? this.year,
      score: score ?? this.score,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'year': year,
      'score': score,
      'details': details,
    };
  }
}

class ProjectItem {
  const ProjectItem({
    required this.title,
    required this.subtitle,
    required this.overview,
    required this.impact,
  });

  const ProjectItem.empty()
    : title = '',
      subtitle = '',
      overview = '',
      impact = '';

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      impact: json['impact'] as String? ?? '',
    );
  }

  final String title;
  final String subtitle;
  final String overview;
  final String impact;

  bool get isBlank =>
      title.trim().isEmpty && overview.trim().isEmpty && impact.trim().isEmpty;

  ProjectItem copyWith({
    String? title,
    String? subtitle,
    String? overview,
    String? impact,
  }) {
    return ProjectItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      overview: overview ?? this.overview,
      impact: impact ?? this.impact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'overview': overview,
      'impact': impact,
    };
  }
}

enum CustomSectionLayoutMode {
  summary,
  bullets,
}

class CustomSectionItem {
  const CustomSectionItem({
    required this.title,
    required this.content,
    this.layoutMode = CustomSectionLayoutMode.summary,
    this.bullets = const [],
  });

  const CustomSectionItem.empty()
    : title = '',
      content = '',
      layoutMode = CustomSectionLayoutMode.summary,
      bullets = const [];

  factory CustomSectionItem.fromJson(Map<String, dynamic> json) {
    final bulletsJson = json['bullets'] as List<dynamic>?;
    final parsedBullets =
        bulletsJson?.map((e) => e.toString()).toList() ?? const <String>[];
    final modeStr = json['layoutMode'] as String?;
    final layoutMode = modeStr == 'bullets'
        ? CustomSectionLayoutMode.bullets
        : CustomSectionLayoutMode.summary;

    return CustomSectionItem(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      layoutMode: layoutMode,
      bullets: parsedBullets,
    );
  }

  final String title;
  final String content;
  final CustomSectionLayoutMode layoutMode;
  final List<String> bullets;

  bool get isBlank {
    if (title.trim().isNotEmpty) {
      return false;
    }
    if (layoutMode == CustomSectionLayoutMode.summary) {
      return content.trim().isEmpty;
    }
    return bullets.isEmpty || bullets.every((b) => b.trim().isEmpty);
  }

  CustomSectionItem copyWith({
    String? title,
    String? content,
    CustomSectionLayoutMode? layoutMode,
    List<String>? bullets,
  }) {
    return CustomSectionItem(
      title: title ?? this.title,
      content: content ?? this.content,
      layoutMode: layoutMode ?? this.layoutMode,
      bullets: bullets ?? this.bullets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'layoutMode': layoutMode.name,
      'bullets': bullets,
    };
  }
}

class ResumeAnalysis {
  const ResumeAnalysis({
    required this.score,
    required this.atsCompatibility,
    required this.missingSkills,
    required this.weakDescriptions,
    required this.strengths,
    required this.improvements,
  });

  final int score;
  final double atsCompatibility;
  final List<String> missingSkills;
  final List<String> weakDescriptions;
  final List<String> strengths;
  final List<String> improvements;
}

class JobDescriptionInsights {
  const JobDescriptionInsights({
    required this.summary,
    required this.keywords,
    required this.missingSkills,
  });

  final String summary;
  final List<String> keywords;
  final List<String> missingSkills;
}
