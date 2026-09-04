import 'package:flutter/material.dart';

import '../corporate_resume_style.dart';
import '../resume_text_font.dart';
import 'resume_builder_section_order.dart';

/// Maps stored template ids; legacy removed layouts default to [ResumeTemplate.corporate].
ResumeTemplate resumeTemplateFromStorage(dynamic raw) {
  switch (raw?.toString()) {
    case 'detailsSidebar':
      return ResumeTemplate.detailsSidebar;
    case 'accentStrip':
      return ResumeTemplate.accentStrip;
    case 'classicSidebar':
      return ResumeTemplate.classicSidebar;
    case 'creative':
      return ResumeTemplate.creative;
    case 'corporate':
      return ResumeTemplate.corporate;
    case 'atsStructured':
      return ResumeTemplate.atsStructured;
    case 'atsSerifRules':
      return ResumeTemplate.atsSerifRules;
    case 'atsModernFlow':
      return ResumeTemplate.atsModernFlow;
    case 'atsExecutive':
      return ResumeTemplate.atsExecutive;
    case 'atsCenterClassic':
      return ResumeTemplate.atsCenterClassic;
    case 'atsProfessionalBlue':
      return ResumeTemplate.atsProfessionalBlue;
    case 'atsLatexClassic':
      return ResumeTemplate.atsLatexClassic;
    case 'atsClassicCv':
      return ResumeTemplate.atsClassicCv;
    case 'headerSidebar':
      return ResumeTemplate.headerSidebar;
    default:
      return ResumeTemplate.corporate;
  }
}

enum ResumeTemplate {
  corporate,
  creative,
  classicSidebar,
  detailsSidebar,
  accentStrip,

  /// Centered header, gray section bands (ATS-friendly).
  atsStructured,

  /// Serif-style rules, email aligned right (ATS-friendly).
  atsSerifRules,

  /// Centered contact, summary → education → skills → experience flow.
  atsModernFlow,

  /// Uppercase headings, strong hierarchy, two-column skills.
  atsExecutive,

  /// Centered name, pipe tagline, ruled sections (Enhancv-style ATS).
  atsCenterClassic,

  /// Blue accent, contact top-right, three-column skills.
  atsProfessionalBlue,

  /// LaTeX-inspired one-page academic ATS format with ruled sections.
  atsLatexClassic,

  /// Centered name + title, personal-details grid, left-labeled ruled CV.
  atsClassicCv,

  /// Circular photo + name header with a navy details rail on the right.
  headerSidebar,
}

enum CoverLetterTemplate {
  executiveNote,
  minimalLetter,
  sidebarLetter,

  /// Traditional left-aligned letter: date, recipient block, body (ATS-friendly).
  classicBusinessLetter,
}

const availableResumeTemplates = <ResumeTemplate>[
  ResumeTemplate.corporate,
  ResumeTemplate.creative,
  ResumeTemplate.classicSidebar,
  ResumeTemplate.accentStrip,
  ResumeTemplate.headerSidebar,
  ResumeTemplate.atsStructured,
  ResumeTemplate.atsLatexClassic,
  ResumeTemplate.atsModernFlow,
  ResumeTemplate.atsExecutive,
  ResumeTemplate.atsCenterClassic,
  ResumeTemplate.atsProfessionalBlue,
  ResumeTemplate.atsClassicCv,
];

extension ResumeTemplateX on ResumeTemplate {
  ResumeTemplate get userFacingTemplate => this;

  /// ATS layouts keep black type on the template gallery; color is chosen in preview.
  bool get isAtsTemplate => switch (userFacingTemplate) {
    ResumeTemplate.atsStructured ||
    ResumeTemplate.atsSerifRules ||
    ResumeTemplate.atsModernFlow ||
    ResumeTemplate.atsExecutive ||
    ResumeTemplate.atsCenterClassic ||
    ResumeTemplate.atsProfessionalBlue ||
    ResumeTemplate.atsLatexClassic ||
    ResumeTemplate.atsClassicCv => true,
    _ => false,
  };

  String get label => switch (userFacingTemplate) {
    ResumeTemplate.corporate => 'Corporate',
    ResumeTemplate.creative => 'Profile Sidebar',
    ResumeTemplate.classicSidebar => 'Classic Sidebar',
    ResumeTemplate.detailsSidebar => 'Details Sidebar',
    ResumeTemplate.accentStrip => 'Accent Strip',
    ResumeTemplate.atsStructured => 'Structured ATS',
    ResumeTemplate.atsSerifRules => 'Serif Rules ATS',
    ResumeTemplate.atsModernFlow => 'Modern Flow ATS',
    ResumeTemplate.atsExecutive => 'Executive ATS',
    ResumeTemplate.atsCenterClassic => 'Center Classic ATS',
    ResumeTemplate.atsProfessionalBlue => 'Professional Blue ATS',
    ResumeTemplate.atsLatexClassic => 'LaTeX Classic ATS',
    ResumeTemplate.atsClassicCv => 'Classic CV ATS',
    ResumeTemplate.headerSidebar => 'Header Sidebar',
  };

  String get description => switch (userFacingTemplate) {
    ResumeTemplate.corporate =>
      'Dark top header with a strong structured layout and compact sections.',
    ResumeTemplate.creative =>
      'Profile-led layout with bold side accents and editorial-style sections.',
    ResumeTemplate.classicSidebar =>
      'Soft sidebar layout with a profile photo, skills rail, and clean resume blocks.',
    ResumeTemplate.detailsSidebar =>
      'Minimal left details rail with clean section lines and balanced content blocks.',
    ResumeTemplate.accentStrip =>
      'Bold left accent stripe with an oversized nameplate and single-column sections.',
    ResumeTemplate.atsStructured =>
      'Single column with banded section titles—optimized for keyword parsing.',
    ResumeTemplate.atsSerifRules =>
      'Classic rules and hierarchy with clear contact and date alignment.',
    ResumeTemplate.atsModernFlow =>
      'Centered header and a logical section flow for scanners and recruiters.',
    ResumeTemplate.atsExecutive =>
      'Strong uppercase headings and scannable two-column skills.',
    ResumeTemplate.atsCenterClassic =>
      'Centered Garamond header with ruled sections and inline skills.',
    ResumeTemplate.atsProfessionalBlue =>
      'Blue accent headings, right-aligned contact, and three-column skills.',
    ResumeTemplate.atsLatexClassic =>
      'LaTeX-style ruled sections with compact academic project emphasis.',
    ResumeTemplate.atsClassicCv =>
      'Centered name, personal-details grid, and left-labeled ruled sections.',
    ResumeTemplate.headerSidebar =>
      'Photo-led nameplate with a navy details rail and skill bars.',
  };

  Color get accentColor => switch (userFacingTemplate) {
    ResumeTemplate.corporate => const Color(0xFF0F766E),
    ResumeTemplate.creative => const Color(0xFFE85D04),
    ResumeTemplate.classicSidebar => const Color(0xFF344054),
    ResumeTemplate.detailsSidebar => const Color(0xFF344054),
    ResumeTemplate.accentStrip => const Color(0xFFF4552F),
    ResumeTemplate.atsStructured => const Color(0xFF000000),
    ResumeTemplate.atsSerifRules => const Color(0xFF000000),
    ResumeTemplate.atsModernFlow => const Color(0xFF000000),
    ResumeTemplate.atsExecutive => const Color(0xFF000000),
    ResumeTemplate.atsCenterClassic => const Color(0xFF000000),
    ResumeTemplate.atsProfessionalBlue => const Color(0xFF000000),
    ResumeTemplate.atsLatexClassic => const Color(0xFF000000),
    ResumeTemplate.atsClassicCv => const Color(0xFF000000),
    ResumeTemplate.headerSidebar => const Color(0xFF1B365D),
  };

  Color get tintColor => switch (userFacingTemplate) {
    ResumeTemplate.corporate => const Color(0xFFE4FBF6),
    ResumeTemplate.creative => const Color(0xFFFFE9D8),
    ResumeTemplate.classicSidebar => const Color(0xFFF2F4F7),
    ResumeTemplate.detailsSidebar => const Color(0xFFF2F4F7),
    ResumeTemplate.accentStrip => const Color(0xFFFFEFE8),
    ResumeTemplate.atsStructured => const Color(0xFFF3F4F6),
    ResumeTemplate.atsSerifRules => const Color(0xFFF9FAFB),
    ResumeTemplate.atsModernFlow => const Color(0xFFEFF6FF),
    ResumeTemplate.atsExecutive => const Color(0xFFF3F4F6),
    ResumeTemplate.atsCenterClassic => const Color(0xFFF9FAFB),
    ResumeTemplate.atsProfessionalBlue => const Color(0xFFE8F2FC),
    ResumeTemplate.atsLatexClassic => const Color(0xFFF9FAFB),
    ResumeTemplate.atsClassicCv => const Color(0xFFF9FAFB),
    ResumeTemplate.headerSidebar => const Color(0xFFE8EEF6),
  };

  /// Short typography hint for the style sheet (PDF uses built-in fonts per layout).
  String get fontStyleLabel => switch (userFacingTemplate) {
    ResumeTemplate.corporate => 'Sans · corporate header',
    ResumeTemplate.creative => 'Sans · profile sidebar',
    ResumeTemplate.classicSidebar => 'Sans · classic sidebar',
    ResumeTemplate.detailsSidebar => 'Sans · details sidebar',
    ResumeTemplate.accentStrip => 'Garamond · accent strip',
    ResumeTemplate.atsStructured => 'Garamond · banded ATS',
    ResumeTemplate.atsSerifRules => 'Garamond · rules ATS',
    ResumeTemplate.atsModernFlow => 'Garamond · flow ATS',
    ResumeTemplate.atsExecutive => 'Garamond · executive ATS',
    ResumeTemplate.atsCenterClassic => 'Garamond · center ATS',
    ResumeTemplate.atsProfessionalBlue => 'Garamond · blue ATS',
    ResumeTemplate.atsLatexClassic => 'Garamond · LaTeX ATS',
    ResumeTemplate.atsClassicCv => 'Garamond · classic CV',
    ResumeTemplate.headerSidebar => 'Sans · navy sidebar',
  };
}

extension CoverLetterTemplateX on CoverLetterTemplate {
  String get label => switch (this) {
    CoverLetterTemplate.executiveNote => 'Executive Note',
    CoverLetterTemplate.minimalLetter => 'Minimal Letter',
    CoverLetterTemplate.sidebarLetter => 'Mint Letter',
    CoverLetterTemplate.classicBusinessLetter => 'Classic Business',
  };

  Color get accentColor => switch (this) {
    CoverLetterTemplate.executiveNote => const Color(0xFF1F2937),
    CoverLetterTemplate.minimalLetter => const Color(0xFF9A6B2F),
    CoverLetterTemplate.sidebarLetter => const Color(0xFF4DBB82),
    CoverLetterTemplate.classicBusinessLetter => const Color(0xFF374151),
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
    this.useSkillSubheadings = false,
    this.skillGroups = const [],
    required this.projects,
    required this.customSections,
    required this.updatedAt,
    DateTime? createdAt,
    this.lastSyncedAt,
    required this.githubLink,
    required this.linkedinLink,
    required this.profileImagePath,
    required this.resumeTextFont,
    required this.includeWorkInResume,
    required this.includeEducationInResume,
    required this.includeSkillsInResume,
    required this.includeProjectsInResume,
    required this.bodyFontPt,
    required this.corporateColorPresetIndex,
    this.builderSectionOrder = ResumeBuilderSectionIds.bodyDefaults,
  }) : createdAt = createdAt ?? updatedAt;

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
      useSkillSubheadings: false,
      skillGroups: const [],
      projects: const [ProjectItem.empty()],
      customSections: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSyncedAt: null,
      githubLink: '',
      linkedinLink: '',
      profileImagePath: '',
      resumeTextFont: ResumeTextFont.inter,
      includeWorkInResume: true,
      includeEducationInResume: true,
      includeSkillsInResume: true,
      includeProjectsInResume: true,
      bodyFontPt: kResumeBodyFontPtDefault,
      corporateColorPresetIndex: 0,
      builderSectionOrder: ResumeBuilderSectionIds.bodyDefaults,
    );
  }

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    final updatedAt =
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now();
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
      template: resumeTemplateFromStorage(json['template']),
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
      useSkillSubheadings: json['useSkillSubheadings'] as bool? ?? false,
      skillGroups: (json['skillGroups'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                SkillGroup.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .where((group) => !group.isBlank)
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
      updatedAt: updatedAt,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? updatedAt,
      lastSyncedAt: DateTime.tryParse(json['lastSyncedAt'] as String? ?? ''),
      githubLink: json['githubLink'] as String? ?? '',
      linkedinLink: json['linkedinLink'] as String? ?? '',
      profileImagePath: json['profileImagePath'] as String? ?? '',
      resumeTextFont: resumeTextFontFromStorage(
        json['resumeTextFont'] as String?,
      ),
      includeWorkInResume: json['includeWorkInResume'] as bool? ?? true,
      includeEducationInResume:
          json['includeEducationInResume'] as bool? ?? true,
      includeSkillsInResume: json['includeSkillsInResume'] as bool? ?? true,
      includeProjectsInResume: json['includeProjectsInResume'] as bool? ?? true,
      bodyFontPt:
          (json['bodyFontPt'] as num?)?.toInt() ?? kResumeBodyFontPtDefault,
      corporateColorPresetIndex:
          (json['corporateColorPresetIndex'] as num?)?.toInt() ?? 0,
      builderSectionOrder: normalizeBuilderSectionOrder(
        (json['builderSectionOrder'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList(),
        (json['customSections'] as List<dynamic>? ?? []).length,
      ),
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

  /// When true, preview/PDF show [skillGroups] with headings; [skills] stays flat for ATS/AI.
  final bool useSkillSubheadings;

  /// Grouped skills used when [useSkillSubheadings] is enabled.
  final List<SkillGroup> skillGroups;

  final List<ProjectItem> projects;
  final List<CustomSectionItem> customSections;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final String githubLink;
  final String linkedinLink;
  final String profileImagePath;
  final ResumeTextFont resumeTextFont;
  final bool includeWorkInResume;
  final bool includeEducationInResume;
  final bool includeSkillsInResume;
  final bool includeProjectsInResume;

  /// Body text size (pt) for resume preview + PDF; typically 11–13.
  final int bodyFontPt;

  /// Index 0–4 for Dark Header title + top bar colors (see `corporate_resume_style.dart`).
  final int corporateColorPresetIndex;

  /// Order of builder steps after Personal (work/education/skills/projects/custom:N).
  final List<String> builderSectionOrder;

  /// Normalized section order used by the builder chips and content pages.
  List<String> get effectiveBuilderSectionOrder => normalizeBuilderSectionOrder(
    builderSectionOrder,
    customSections.length,
  );

  List<WorkExperience> get visibleWorkExperiences => includeWorkInResume
      ? workExperiences.where((item) => !item.isBlank).toList()
      : const <WorkExperience>[];

  List<EducationItem> get visibleEducation => includeEducationInResume
      ? education.where((item) => !item.isBlank).toList()
      : const <EducationItem>[];

  List<ProjectItem> get visibleProjects => includeProjectsInResume
      ? projects.where((item) => !item.isBlank).toList()
      : const <ProjectItem>[];

  /// Flat skill names for ATS matching, jobs, and AI (always individual skills).
  List<String> get skillsForResume =>
      includeSkillsInResume ? skills : const <String>[];

  /// True when Skills should render as category subtitle + comma-separated skills.
  bool get showCategorisedSkills =>
      includeSkillsInResume &&
      useSkillSubheadings &&
      skillGroupsForResume.isNotEmpty;

  /// Non-empty skill groups for preview/PDF when categorised mode is on.
  List<SkillGroup> get skillGroupsForResume {
    if (!includeSkillsInResume || !useSkillSubheadings) {
      return const <SkillGroup>[];
    }
    return skillGroups
        .where((group) => group.skillsCommaSeparated.isNotEmpty)
        .toList();
  }

  /// Flat skill lines for simple-list mode (and legacy callers).
  /// Prefer [showCategorisedSkills] + [skillGroupsForResume] for categorised UI.
  List<String> get skillsLinesForDisplay {
    if (!includeSkillsInResume) {
      return const <String>[];
    }
    // Keep flat skill names for simple list. Categorised layouts use groups.
    return skills.where((item) => item.trim().isNotEmpty).toList();
  }

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
    bool? useSkillSubheadings,
    List<SkillGroup>? skillGroups,
    List<ProjectItem>? projects,
    List<CustomSectionItem>? customSections,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastSyncedAt = _resumeDateSentinel,
    String? githubLink,
    String? linkedinLink,
    String? profileImagePath,
    ResumeTextFont? resumeTextFont,
    bool? includeWorkInResume,
    bool? includeEducationInResume,
    bool? includeSkillsInResume,
    bool? includeProjectsInResume,
    int? bodyFontPt,
    int? corporateColorPresetIndex,
    List<String>? builderSectionOrder,
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
      useSkillSubheadings: useSkillSubheadings ?? this.useSkillSubheadings,
      skillGroups: skillGroups ?? this.skillGroups,
      projects: projects ?? this.projects,
      customSections: customSections ?? this.customSections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: identical(lastSyncedAt, _resumeDateSentinel)
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      githubLink: githubLink ?? this.githubLink,
      linkedinLink: linkedinLink ?? this.linkedinLink,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      resumeTextFont: resumeTextFont ?? this.resumeTextFont,
      includeWorkInResume: includeWorkInResume ?? this.includeWorkInResume,
      includeEducationInResume:
          includeEducationInResume ?? this.includeEducationInResume,
      includeSkillsInResume:
          includeSkillsInResume ?? this.includeSkillsInResume,
      includeProjectsInResume:
          includeProjectsInResume ?? this.includeProjectsInResume,
      bodyFontPt: bodyFontPt ?? this.bodyFontPt,
      corporateColorPresetIndex:
          corporateColorPresetIndex ?? this.corporateColorPresetIndex,
      builderSectionOrder: builderSectionOrder ?? this.builderSectionOrder,
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
      'useSkillSubheadings': useSkillSubheadings,
      'skillGroups': skillGroups.map((item) => item.toJson()).toList(),
      'projects': projects.map((item) => item.toJson()).toList(),
      'customSections': customSections.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'githubLink': githubLink,
      'linkedinLink': linkedinLink,
      'profileImagePath': profileImagePath,
      'resumeTextFont': resumeTextFont.name,
      'includeWorkInResume': includeWorkInResume,
      'includeEducationInResume': includeEducationInResume,
      'includeSkillsInResume': includeSkillsInResume,
      'includeProjectsInResume': includeProjectsInResume,
      'bodyFontPt': bodyFontPt,
      'corporateColorPresetIndex': corporateColorPresetIndex,
      'builderSectionOrder': effectiveBuilderSectionOrder,
    };
  }
}

/// A labeled group of skills (e.g. "Languages", "Tools").
class SkillGroup {
  const SkillGroup({
    required this.heading,
    required this.skills,
  });

  const SkillGroup.empty()
      : heading = '',
        skills = const [];

  factory SkillGroup.fromJson(Map<String, dynamic> json) {
    return SkillGroup(
      heading: json['heading'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
    );
  }

  final String heading;
  final List<String> skills;

  bool get isBlank =>
      heading.trim().isEmpty && skills.every((s) => s.trim().isEmpty);

  /// Comma-separated skills for resume body under the category subtitle.
  String get skillsCommaSeparated => skills
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(', ');

  /// Legacy single-line form: `Heading: skill1, skill2`.
  String get displayLine {
    final joined = skillsCommaSeparated;
    if (joined.isEmpty) {
      return '';
    }
    final label = heading.trim();
    return label.isEmpty ? joined : '$label: $joined';
  }

  SkillGroup copyWith({
    String? heading,
    List<String>? skills,
  }) {
    return SkillGroup(
      heading: heading ?? this.heading,
      skills: skills ?? this.skills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heading': heading,
      'skills': skills,
    };
  }
}

const Object _resumeDateSentinel = Object();

const Object _coverLetterDateSentinel = Object();

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
    this.lastSyncedAt,
    required this.bodyFontPt,
    required this.corporateColorPresetIndex,
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
      lastSyncedAt: null,
      bodyFontPt: kResumeBodyFontPtDefault,
      corporateColorPresetIndex: 0,
    );
  }

  factory CoverLetterData.fromJson(Map<String, dynamic> json) {
    final template = CoverLetterTemplate.values.firstWhere(
      (value) => value.name == json['template'],
      orElse: () => CoverLetterTemplate.executiveNote,
    );
    return CoverLetterData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      role: json['role'] as String? ?? '',
      template: template,
      skillToHighlight: json['skillToHighlight'] as String? ?? '',
      language: json['language'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      lastSyncedAt: DateTime.tryParse(json['lastSyncedAt'] as String? ?? ''),
      bodyFontPt:
          (json['bodyFontPt'] as num?)?.toInt() ?? kResumeBodyFontPtDefault,
      corporateColorPresetIndex:
          (json['corporateColorPresetIndex'] as num?)?.toInt() ??
          defaultColorPresetIndexForCoverLetterTemplate(template),
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
  final DateTime? lastSyncedAt;

  /// Body text size (pt) for cover letter preview + PDF; typically 11–13.
  final int bodyFontPt;

  /// Accent/header palette index (see `corporate_resume_style.dart`).
  final int corporateColorPresetIndex;

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
    Object? lastSyncedAt = _coverLetterDateSentinel,
    int? bodyFontPt,
    int? corporateColorPresetIndex,
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
      lastSyncedAt: identical(lastSyncedAt, _coverLetterDateSentinel)
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      bodyFontPt: bodyFontPt ?? this.bodyFontPt,
      corporateColorPresetIndex:
          corporateColorPresetIndex ?? this.corporateColorPresetIndex,
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
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'bodyFontPt': bodyFontPt,
      'corporateColorPresetIndex': corporateColorPresetIndex,
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
    this.layoutMode = WorkExperienceLayoutMode.bullets,
  });

  const WorkExperience.empty()
    : role = '',
      company = '',
      startDate = '',
      endDate = '',
      description = '',
      bullets = const [],
      layoutMode = WorkExperienceLayoutMode.bullets;

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    final parsedBullets = (json['bullets'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final description = json['description'] as String? ?? '';
    final layoutMode = WorkExperienceLayoutMode.bullets;
    return WorkExperience(
      role: json['role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      description: description,
      bullets: parsedBullets,
      layoutMode: layoutMode,
    );
  }

  final String role;
  final String company;
  final String startDate;
  final String endDate;
  final String description;
  final List<String> bullets;
  final WorkExperienceLayoutMode layoutMode;

  bool get isBlank =>
      role.trim().isEmpty &&
      company.trim().isEmpty &&
      description.trim().isEmpty &&
      (bullets.isEmpty || bullets.every((bullet) => bullet.trim().isEmpty));

  WorkExperience copyWith({
    String? role,
    String? company,
    String? startDate,
    String? endDate,
    String? description,
    List<String>? bullets,
    WorkExperienceLayoutMode? layoutMode,
  }) {
    return WorkExperience(
      role: role ?? this.role,
      company: company ?? this.company,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      bullets: bullets ?? this.bullets,
      layoutMode: layoutMode ?? this.layoutMode,
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
      'layoutMode': layoutMode.name,
    };
  }
}

enum WorkExperienceLayoutMode { summary, bullets }

class EducationItem {
  const EducationItem({
    required this.institution,
    required this.degree,
    required this.startDate,
    required this.endDate,
    this.score = '',
    this.showScoreAsPercent = false,
  });

  const EducationItem.empty()
    : institution = '',
      degree = '',
      startDate = '',
      endDate = '',
      score = '',
      showScoreAsPercent = false;

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'] as String? ?? '';
    final showFromJson = json['showScoreAsPercent'] as bool?;
    final bool showScoreAsPercent;
    final String score;
    if (showFromJson != null) {
      showScoreAsPercent = showFromJson;
      score = rawScore;
    } else if (rawScore.trim().endsWith('%')) {
      showScoreAsPercent = true;
      score = rawScore.trim().replaceFirst(RegExp(r'%\s*$'), '').trim();
    } else {
      showScoreAsPercent = false;
      score = rawScore;
    }

    return EducationItem(
      institution: json['institution'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? (json['year'] as String? ?? ''),
      score: score,
      showScoreAsPercent: showScoreAsPercent,
    );
  }

  final String institution;
  final String degree;
  final String startDate;
  final String endDate;
  final String score;
  final bool showScoreAsPercent;

  bool get isBlank =>
      institution.trim().isEmpty &&
      degree.trim().isEmpty &&
      startDate.trim().isEmpty &&
      endDate.trim().isEmpty &&
      score.trim().isEmpty;

  EducationItem copyWith({
    String? institution,
    String? degree,
    String? startDate,
    String? endDate,
    String? score,
    bool? showScoreAsPercent,
  }) {
    return EducationItem(
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      score: score ?? this.score,
      showScoreAsPercent: showScoreAsPercent ?? this.showScoreAsPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'startDate': startDate,
      'endDate': endDate,
      'score': score,
      'showScoreAsPercent': showScoreAsPercent,
    };
  }
}

/// Resume label for an education score, honoring the % display toggle.
String educationScoreDisplayLabel(EducationItem item) {
  final raw = item.score.trim();
  if (raw.isEmpty) return '';
  final base = raw.replaceAll(RegExp(r'%\s*$'), '').trim();
  if (base.isEmpty) return '';
  if (item.showScoreAsPercent) {
    return '$base%';
  }
  return base;
}

/// `2014 - 2018`, or a single year if only one side is set (matches template card).
String educationDateRangeLabel(String startDate, String endDate) {
  final a = startDate.trim();
  final b = endDate.trim();
  if (a.isEmpty && b.isEmpty) return '';
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a - $b';
}

/// Dark Header education first line: `Northeastern University  |  2014 - 2018`.
String corporateEducationTitleLine(
  String institution,
  String startDate,
  String endDate, {
  String institutionFallback = 'Institution',
}) {
  final inst = institution.trim().isEmpty
      ? institutionFallback
      : institution.trim();
  final range = educationDateRangeLabel(startDate, endDate);
  if (range.isEmpty) return inst;
  return '$inst  |  $range';
}

class ProjectItem {
  const ProjectItem({
    required this.title,
    this.subtitle = '',
    this.overview = '',
    this.impact = '',
    this.bullets = const [],
  });

  const ProjectItem.empty()
    : title = '',
      subtitle = '',
      overview = '',
      impact = '',
      bullets = const [];

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    final bulletsJson = json['bullets'] as List<dynamic>?;
    return ProjectItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      impact: json['impact'] as String? ?? '',
      bullets: bulletsJson?.map((item) => item.toString()).toList() ?? const [],
    );
  }

  final String title;
  final String subtitle;
  final String overview;
  final String impact;
  final List<String> bullets;

  bool get isBlank =>
      title.trim().isEmpty &&
      overview.trim().isEmpty &&
      impact.trim().isEmpty &&
      bullets.every((item) => item.trim().isEmpty);

  ProjectItem copyWith({
    String? title,
    String? subtitle,
    String? overview,
    String? impact,
    List<String>? bullets,
  }) {
    return ProjectItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      overview: overview ?? this.overview,
      impact: impact ?? this.impact,
      bullets: bullets ?? this.bullets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'overview': overview,
      'impact': impact,
      'bullets': bullets,
    };
  }
}

enum CustomSectionLayoutMode { summary, bullets, projects }

class CustomSectionItem {
  const CustomSectionItem({
    required this.title,
    required this.content,
    this.layoutMode = CustomSectionLayoutMode.summary,
    this.bullets = const [],
    this.projectEntries = const [],
  });

  const CustomSectionItem.empty()
    : title = '',
      content = '',
      layoutMode = CustomSectionLayoutMode.summary,
      bullets = const [],
      projectEntries = const [];

  factory CustomSectionItem.fromJson(Map<String, dynamic> json) {
    final bulletsJson = json['bullets'] as List<dynamic>?;
    final parsedBullets =
        bulletsJson?.map((e) => e.toString()).toList() ?? const <String>[];
    final projectsJson = json['projectEntries'] as List<dynamic>?;
    final parsedProjects =
        projectsJson
            ?.map(
              (item) =>
                  ProjectItem.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList() ??
        const <ProjectItem>[];
    final modeStr = json['layoutMode'] as String?;
    final layoutMode = switch (modeStr) {
      'bullets' => CustomSectionLayoutMode.bullets,
      'projects' => CustomSectionLayoutMode.projects,
      _ => CustomSectionLayoutMode.summary,
    };

    return CustomSectionItem(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      layoutMode: layoutMode,
      bullets: parsedBullets,
      projectEntries: parsedProjects,
    );
  }

  final String title;
  final String content;
  final CustomSectionLayoutMode layoutMode;
  final List<String> bullets;
  final List<ProjectItem> projectEntries;

  List<ProjectItem> get visibleProjectEntries =>
      projectEntries.where((item) => !item.isBlank).toList();

  bool get isBlank {
    if (title.trim().isNotEmpty) {
      return false;
    }
    return switch (layoutMode) {
      CustomSectionLayoutMode.summary => content.trim().isEmpty,
      CustomSectionLayoutMode.bullets =>
        bullets.isEmpty || bullets.every((b) => b.trim().isEmpty),
      CustomSectionLayoutMode.projects =>
        projectEntries.isEmpty ||
            projectEntries.every((entry) => entry.isBlank),
    };
  }

  CustomSectionItem copyWith({
    String? title,
    String? content,
    CustomSectionLayoutMode? layoutMode,
    List<String>? bullets,
    List<ProjectItem>? projectEntries,
  }) {
    return CustomSectionItem(
      title: title ?? this.title,
      content: content ?? this.content,
      layoutMode: layoutMode ?? this.layoutMode,
      bullets: bullets ?? this.bullets,
      projectEntries: projectEntries ?? this.projectEntries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'layoutMode': layoutMode.name,
      'bullets': bullets,
      'projectEntries': projectEntries.map((item) => item.toJson()).toList(),
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
