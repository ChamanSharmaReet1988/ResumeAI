import 'package:flutter/material.dart';

import 'models/resume_models.dart';

/// Dark Header–specific: section title color + top bar background.
final class CorporateColorPreset {
  const CorporateColorPreset({
    required this.titleColor,
    required this.headerColor,
  });

  final Color titleColor;
  final Color headerColor;
}

extension CorporateColorPresetX on CorporateColorPreset {
  /// Light header bars need dark name/contact text instead of white.
  bool get usesLightHeader => headerColor.computeLuminance() > 0.55;

  Color get headerOnColor =>
      usesLightHeader ? titleColor : Colors.white;

  Color get headerBorderColor => usesLightHeader
      ? titleColor.withValues(alpha: 0.4)
      : Colors.white;
}

/// Preset palettes: section titles + Dark Header bar.
///
/// First option matches Dark Header template preview (`header` / `text`) — default for new resumes.
///
/// Remaining colors follow the reference palette (salmon, blue, tan, teal, cyan); [headerColor] is the top bar.
/// Beige is stepped darker so white name/contact text meets contrast; teal/cyan use screenshot hex.
const kCorporateColorPresets = <CorporateColorPreset>[
  CorporateColorPreset(
    titleColor: Color(0xFF2E3135),
    headerColor: Color(0xFF31353B),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF5C2C2C),
    headerColor: Color(0xFFFF6861),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF102E4A),
    headerColor: Color(0xFF2E7CB3),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF3F3634),
    headerColor: Color(0xFFA68F87),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF004D40),
    headerColor: Color(0xFF00A48A),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF0A4A58),
    headerColor: Color(0xFF41B9CC),
  ),
  // Additional hues (medium-light headers); each distinct from the six above.
  CorporateColorPreset(
    titleColor: Color(0xFF4A3570),
    headerColor: Color(0xFFB39DDB),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF2F4A2F),
    headerColor: Color(0xFF94B88A),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF5C4A1A),
    headerColor: Color(0xFFE5C36A),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF5C2A42),
    headerColor: Color(0xFFC989A8),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF2C3560),
    headerColor: Color(0xFF8E9FD4),
  ),
  CorporateColorPreset(
    titleColor: Color(0xFF5C3828),
    headerColor: Color(0xFFD4967E),
  ),
];

/// Virtual preset index used by template 2/3 to keep their native accent color.
final int kTemplateDefaultColorPresetIndex = kCorporateColorPresets.length;

int defaultColorPresetIndexForTemplate(ResumeTemplate template) {
  return switch (template) {
    ResumeTemplate.corporate => 0,
    ResumeTemplate.creative => kTemplateDefaultColorPresetIndex,
    ResumeTemplate.classicSidebar => 2,
    ResumeTemplate.detailsSidebar => kTemplateDefaultColorPresetIndex,
    ResumeTemplate.accentStrip => kTemplateDefaultColorPresetIndex,
    ResumeTemplate.atsStructured => 0,
    ResumeTemplate.atsSerifRules => 0,
    ResumeTemplate.atsModernFlow => 0,
    ResumeTemplate.atsExecutive => 0,
    ResumeTemplate.atsCenterClassic => 0,
    ResumeTemplate.atsProfessionalBlue => 0,
  };
}

/// Body font size slider range for resume preview + PDF export (pt).
const int kResumeBodyFontPtMin = 11;
const int kResumeBodyFontPtMax = 13;
const int kResumeBodyFontPtDefault = 12;

/// Title-case each word in a person's name (e.g. "morgan lee" → "Morgan Lee").
String resumeFullNameTitleCase(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) {
    return 'Your Name';
  }
  return trimmed
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length <= 2
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

extension ResumeCorporateStyleX on ResumeData {
  /// Serif Rules ATS header name — each word capitalized, not ALL CAPS.
  String get serifRulesDisplayName => resumeFullNameTitleCase(fullName);

  /// Clamped [kResumeBodyFontPtMin]–[kResumeBodyFontPtMax] for preview + PDF body text.
  int get effectiveBodyFontPt {
    final v = bodyFontPt;
    if (v < kResumeBodyFontPtMin) return kResumeBodyFontPtMin;
    if (v > kResumeBodyFontPtMax) return kResumeBodyFontPtMax;
    return v;
  }

  /// Sidebar / PDF contact order (email, location, phone, website, GitHub, LinkedIn).
  List<String> resumeContactItems() => [
    email.trim(),
    location.trim(),
    phone.trim(),
    website.trim(),
    githubLink.trim(),
    linkedinLink.trim(),
  ].where((item) => item.isNotEmpty).toList();

  /// Structured ATS header contact block (location, email/phone, website, GitHub, LinkedIn).
  List<String> atsStructuredHeaderContactLines() {
    final email = this.email.trim();
    final phone = this.phone.trim();
    final loc = location.trim();
    final web = website.trim();
    final github = githubLink.trim();
    final linkedin = linkedinLink.trim();
    final lines = <String>[];
    if (loc.isNotEmpty) {
      lines.add(loc);
    }
    if (email.isNotEmpty && phone.isNotEmpty) {
      lines.add('$email    $phone');
    } else if (email.isNotEmpty) {
      lines.add(email);
    } else if (phone.isNotEmpty) {
      lines.add(phone);
    }
    if (web.isNotEmpty) {
      lines.add(web);
    }
    if (github.isNotEmpty) {
      lines.add(github);
    }
    if (linkedin.isNotEmpty) {
      lines.add(linkedin);
    }
    return lines;
  }

  /// Serif Rules ATS header — right column (top-aligned with name).
  List<String> atsSerifRulesRightContactLines() => [
    email.trim(),
    linkedinLink.trim(),
    githubLink.trim(),
    website.trim(),
  ].where((item) => item.isNotEmpty).toList();

  /// Scales Profile Sidebar (template 2) type from the body font slider (11–13 pt).
  double get creativeFontScale => effectiveBodyFontPt / kResumeBodyFontPtDefault;

  double creativeScaledPt(double designPt) => designPt * creativeFontScale;

  /// Scales Classic Sidebar (template 3) type from the body font slider (11–13 pt).
  double get classicSidebarFontScale =>
      effectiveBodyFontPt / kResumeBodyFontPtDefault;

  double classicSidebarScaledPt(double designPt) =>
      designPt * classicSidebarFontScale;

  CorporateColorPreset get corporateColorPreset {
    if (corporateColorPresetIndex == kTemplateDefaultColorPresetIndex) {
      return CorporateColorPreset(
        titleColor: const Color(0xFF2E3135),
        headerColor: template.accentColor,
      );
    }
    final i = corporateColorPresetIndex
        .clamp(0, kCorporateColorPresets.length - 1)
        .toInt();
    return kCorporateColorPresets[i];
  }

  /// Creative template uses the selected preset only as an accent, not for titles.
  Color get creativeAccentColor => corporateColorPreset.headerColor;

  Color get creativeRailColor =>
      Color.lerp(Colors.white, creativeAccentColor, 0.18) ?? Colors.white;

  Color get creativeAvatarBackgroundColor =>
      Color.lerp(creativeRailColor, Colors.black, 0.10) ?? creativeRailColor;

  Color get creativeTitleColor => const Color(0xFF2E3135);

  Color get creativeMutedColor => const Color(0xFF5F656C);

  Color get creativeLineColor => const Color(0xFFCDBAAC);

  Color get classicSidebarRailColor =>
      Color.lerp(
        const Color(0xFFF2F4F7),
        corporateColorPreset.headerColor,
        0.08,
      ) ??
      const Color(0xFFF2F4F7);

  Color get classicSidebarAccentColor =>
      Color.lerp(corporateColorPreset.headerColor, Colors.black, 0.12) ??
      corporateColorPreset.headerColor;

  Color get classicSidebarAvatarFillColor =>
      Color.lerp(classicSidebarAccentColor, Colors.white, 0.38) ??
      classicSidebarAccentColor;

  Color get classicSidebarTitleColor => const Color(0xFF111827);

  Color get classicSidebarMutedColor => const Color(0xFF475467);

  Color get classicSidebarDividerColor => const Color(0xFF344054);

  Color get classicSidebarSectionBorderColor => const Color(0xFFE5E7EB);

  Color get detailsSidebarAccentColor => corporateColorPreset.headerColor;

  Color get detailsSidebarRailColor => const Color(0xFFF3F4F6);

  Color get detailsSidebarTitleColor => const Color(0xFF344054);

  Color get detailsSidebarMutedColor => const Color(0xFF475467);

  Color get detailsSidebarDividerColor => const Color(0xFF98A2B3);
}
