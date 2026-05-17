import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show TextStyle;

import 'resume_font_weight.dart';

/// Default type scale for resume content (preview + PDF). Font family defaults to
/// [ResumeTextFont.inter] on [ResumeData.resumeTextFont].
abstract final class ResumeTypography {
  static const double bodyPt = 11;
  static const double headingPt = 14;
  static const double namePt = 17;

  /// Accent Strip (template 4): fixed Garamond titles; body uses slider pt (10–12, default 11).
  static const double accentStripNamePt = 24;
  static const double accentStripSectionTitlePt = 14;
  static const double accentStripSubsectionPt = 13;
  /// Section titles, headings (single-line friendly).
  static const double textLineHeight = 1.4;

  /// Body paragraphs, bullets, and summary (Flutter preview + PDF line height).
  static const double bodyTextLineHeight = 1.4;

  /// PDF [lineSpacing] (pt) so line height = [bodyTextLineHeight] × [fontSizePt].
  static double bodyPdfLineSpacingFor(double fontSizePt) =>
      fontSizePt * (bodyTextLineHeight - 1);

  static double darkHeaderBodyPdfLineSpacingFor(double fontSizePt) =>
      fontSizePt * (darkHeaderBodyLineHeight - 1);
  static const double sectionGapPreviewPx = 44;
  static const double sectionGapPdfPt = 30;

  /// Corporate (template 1) gap between sections (preview px = PDF pt).
  static const double darkHeaderSectionGapPreviewPx = 20;
  static const double darkHeaderSectionGapPdfPt = 20;

  /// Corporate header inner horizontal inset (preview px = PDF pt).
  static const double corporateHeaderHorizontalInset = 40;

  /// Corporate body sections below the header (preview px = PDF pt).
  static const double corporateBodyHorizontalInset = 40;

  /// Dark Header (corporate template) — preview and PDF type scale.
  static const double darkHeaderNamePt = 24;
  static const double darkHeaderInitialsPt = 48;
  static const double darkHeaderSectionTitlePt = 14;
  static const double darkHeaderSubtitlePt = 13;

  /// Corporate body paragraph line height (preview + PDF).
  static const double darkHeaderBodyLineHeight = 1.2;

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

  /// Profile Sidebar (creative / template 2) — preview and PDF type scale.
  static const double creativeNamePt = 24;
  static const int creativeNameWeight = 600;
  static const int creativeSidebarContentWeight = 300;
  static const double creativeSectionTitlePt = 14;
  static const int creativeSectionTitleWeight = 500;
  /// Legacy design reference; body copy uses [ResumeData.effectiveBodyFontPt] (10–12).
  static const double creativeBodyPt = 14;
  /// Profile Sidebar main body — Nunito Regular (preview + PDF).
  static const int creativeBodyWeight = 400;
  static const double creativeSubtitlePt = 13;
  static const int creativeSubtitleWeight = 400;

  /// Profile Sidebar body paragraph line height (preview + PDF).
  static const double creativeBodyLineHeight = 1.2;

  static double creativeBodyPdfLineSpacingFor(double fontSizePt) =>
      fontSizePt * (creativeBodyLineHeight - 1);

  /// Profile Sidebar main-column margins (preview px = PDF pt). Sidebar has none.
  static const double creativeBodyTopMargin = 30;
  static const double creativeBodyBottomMargin = 40;
  static const double creativeMainColumnRightInset = 40;

  /// Profile Sidebar avatar top spacing (preview px = PDF pt).
  static const double creativeSidebarImageTopPadding = 20;

  /// Gap between sidebar rail and main body column (preview px = PDF pt).
  static const double creativeSidebarBodyGap = 15;

  /// Profile Sidebar page 2+ horizontal inset (preview px = PDF pt).
  static const double creativeContinuationPageHorizontalInset = 40;

  /// Profile Sidebar page 2+ top margin (PDF; matches [creativeBodyTopMargin]).
  static const double creativeContinuationPageTopMargin = 30;

  /// Profile Sidebar body copy (preview + PDF).
  static const Color creativeBodyTextColor = Color(0xFF000000);

  /// Classic Sidebar (template 3) — same type scale as Profile Sidebar, independent tokens.
  static const double classicSidebarNamePt = 24;
  static const int classicSidebarNameWeight = 600;
  static const double classicSidebarAvatarInitialsNameRatio = 1.15;
  static const double classicSidebarAvatarInitialsExtraPt = 18;

  /// Sidebar avatar initials (scaled name × ratio + extra points).
  static double classicSidebarAvatarInitialsFontPt(double scaledNamePt) =>
      scaledNamePt * classicSidebarAvatarInitialsNameRatio +
      classicSidebarAvatarInitialsExtraPt;
  static const int classicSidebarSidebarContentWeight = 300;
  static const double classicSidebarSectionTitlePt = 14;
  static const int classicSidebarSectionTitleWeight = 500;
  /// Legacy design reference; body copy uses [ResumeData.effectiveBodyFontPt] (10–12).
  static const double classicSidebarBodyPt = 14;
  /// Classic Sidebar main body — Nunito Regular (preview + PDF).
  static const int classicSidebarBodyWeight = 400;

  /// Accent Strip body — same Nunito Regular weight as templates 2–3.
  static const int accentStripBodyWeight = 400;

  static const double classicSidebarSubtitlePt = 13;
  static const int classicSidebarSubtitleWeight = 400;

  static const double classicSidebarBodyLineHeight = 1.2;

  static double classicSidebarBodyPdfLineSpacingFor(double fontSizePt) =>
      fontSizePt * (classicSidebarBodyLineHeight - 1);

  /// Classic Sidebar body copy (preview + PDF).
  static const Color classicSidebarBodyTextColor = Color(0xFF000000);

  /// Templates 2–4 body — Nunito Regular at [creativeBodyWeight] (not Carlito).
  static TextStyle nunitoBodyPreviewStyle({
    double? fontSize,
    Color? color,
    double? height,
    int weight = creativeBodyWeight,
  }) =>
      TextStyle(
        fontFamily: 'Nunito',
        fontWeight: ResumeFontWeight.toFlutter(weight),
        fontSize: fontSize,
        color: color,
        height: height,
      );

  /// Calibri (Carlito) text style for in-app resume previews.
  static TextStyle calibriPreviewStyle({
    required int weight,
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: ResumeTextFont.calibri.flutterFontFamily,
        fontWeight: ResumeFontWeight.toFlutter(weight),
        fontSize: fontSize,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Garamond (EB Garamond) for accent-strip name and section titles in preview.
  static TextStyle garamondPreviewStyle({
    required int weight,
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Garamond',
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
