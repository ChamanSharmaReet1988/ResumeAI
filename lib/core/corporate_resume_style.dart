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

/// Preset palettes: section titles + Dark Header bar.
///
/// First option matches [templates_screen] `_DarkHeaderTemplateArt` (`header` / `text`) — default for new resumes.
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
];

extension ResumeCorporateStyleX on ResumeData {
  /// Clamped 11–15 for preview + PDF body text (Dark Header).
  int get effectiveBodyFontPt {
    final v = bodyFontPt;
    if (v < 11) return 11;
    if (v > 15) return 15;
    return v;
  }

  CorporateColorPreset get corporateColorPreset {
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
}
