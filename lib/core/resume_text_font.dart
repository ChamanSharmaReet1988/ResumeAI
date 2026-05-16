import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show TextStyle;

import 'resume_font_weight.dart';

/// Default type scale for resume content (preview + PDF). Font family defaults to
/// [ResumeTextFont.inter] on [ResumeData.resumeTextFont].
abstract final class ResumeTypography {
  static const double bodyPt = 11;
  static const double headingPt = 14;
  static const double namePt = 17;
  /// Section titles, headings (single-line friendly).
  static const double textLineHeight = 1.4;

  /// Body paragraphs, bullets, and summary (Flutter preview + PDF line height).
  static const double bodyTextLineHeight = 1.6;

  /// PDF [lineSpacing] (pt) so line height = [bodyTextLineHeight] × [fontSizePt].
  static double bodyPdfLineSpacingFor(double fontSizePt) =>
      fontSizePt * (bodyTextLineHeight - 1);
  static const double sectionGapPreviewPx = 44;
  static const double sectionGapPdfPt = 30;

  /// Dark Header (corporate template) — preview and PDF type scale.
  static const double darkHeaderNamePt = 28;
  static const double darkHeaderInitialsPt = 48;
  static const double darkHeaderSectionTitlePt = 16;
  static const double darkHeaderSubtitlePt = 14;

  /// Subtitle lines (role/company, school line, project title).
  static const Color darkHeaderSubtitleColor = Color(0xFF141414);

  /// Dark Header font weights (see [ResumeFontWeight]).
  static const int darkHeaderBodyWeight = 400;
  static const int darkHeaderContactWeight = 300;

  /// Line height for dark header contact lines (1 or 2 rows).
  static const double darkHeaderContactLineHeight = 1.4;

  static double darkHeaderContactPdfLineSpacingFor(double fontSizePt) =>
      fontSizePt * (darkHeaderContactLineHeight - 1);
  static const int darkHeaderInitialsWeight = 500;
  static const int darkHeaderNameWeight = 700;
  static const int darkHeaderSectionTitleWeight = 600;
  static const int darkHeaderSubtitleWeight = 500;

  /// Calibri (Carlito) text style for in-app resume previews.
  static TextStyle calibriPreviewStyle({
    required int weight,
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Calibri',
        fontWeight: ResumeFontWeight.toFlutter(weight),
        fontSize: fontSize,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Inter text style for in-app resume previews.
  static TextStyle interPreviewStyle({
    required int weight,
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontWeight: ResumeFontWeight.toFlutter(weight),
        fontSize: fontSize,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// In-app preview cards use a slightly smaller name when [compact] to reduce overflow.
  static double nameSizePreview(bool compact) => compact ? 14 : namePt;
}

/// User-facing resume body typefaces. Bundled files use open licenses (OFL / Apache).
///
/// **Calibri, Arial, Aptos** are common office fonts; we ship metric- or
/// style-compatible open fonts registered in [flutterFontFamily]. Exported PDFs
/// embed the same bundled TTFs as the PDF export so typography matches
/// the in-app template preview.
enum ResumeTextFont { inter, aptos, calibri, arial }

extension ResumeTextFontX on ResumeTextFont {
  /// Label shown in the UI (matches common resume font names).
  String get label => switch (this) {
    ResumeTextFont.inter => 'Inter',
    ResumeTextFont.aptos => 'Aptos',
    ResumeTextFont.calibri => 'Calibri',
    ResumeTextFont.arial => 'Arial',
  };

  /// Must match `family:` in [pubspec.yaml] for the bundled font files.
  String get flutterFontFamily => switch (this) {
    ResumeTextFont.inter => 'Inter',
    ResumeTextFont.aptos => 'Source Sans 3',
    ResumeTextFont.calibri => 'Calibri',
    ResumeTextFont.arial => 'Arimo',
  };

  /// Short note for pickers (optional).
  String get hint => switch (this) {
    ResumeTextFont.inter => 'Modern UI font',
    ResumeTextFont.aptos => 'Office-style sans (Source Sans 3)',
    ResumeTextFont.calibri => 'Metric match: Carlito',
    ResumeTextFont.arial => 'Metric match: Arimo',
  };
}

ResumeTextFont resumeTextFontFromStorage(String? raw) {
  if (raw == null || raw.isEmpty) {
    return ResumeTextFont.inter;
  }
  if (raw == 'helvetica') {
    return ResumeTextFont.inter;
  }
  for (final value in ResumeTextFont.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return ResumeTextFont.inter;
}
