import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show TextStyle;

import 'resume_font_weight.dart';

/// Default type scale for resume content (preview + PDF). Font family defaults to
/// [ResumeTextFont.inter] on [ResumeData.resumeTextFont].
abstract final class ResumeTypography {
  static const double bodyPt = 12;
  static const double headingPt = 14;
  static const double namePt = 17;

  /// Accent Strip (template 4): fixed Garamond titles; body uses slider pt (11–13, default 12).
  static const double accentStripNamePt = 24;
  static const double accentStripSectionTitlePt = 14;
  static const double accentStripSubsectionPt = 13;
  static const int accentStripNameWeight = 700;
  static const int accentStripTitleWeight = 600;
  static const int accentStripSubtitleWeight = 500;
  static const int accentStripContactWeight = 500;

  /// Structured ATS (first ATS template) — same Garamond sizes as Accent Strip.
  static const double atsStructuredNamePt = accentStripNamePt;
  static const int atsStructuredNameWeight = accentStripNameWeight;
  static const double atsStructuredJobTitlePt = accentStripSectionTitlePt;
  static const int atsStructuredTitleWeight = accentStripTitleWeight;
  static const double atsStructuredSectionTitlePt = accentStripSectionTitlePt;
  static const double atsStructuredSubtitlePt = accentStripSubsectionPt;
  static const int atsStructuredSubtitleWeight = accentStripSubtitleWeight;
  static const int atsStructuredBodyWeight = accentStripBodyWeight;
  static const int atsStructuredContactWeight = accentStripContactWeight;

  /// Page margin for Structured ATS (preview px = PDF pt).
  static const double atsStructuredPageInsetPt = 40;

  /// Serif Rules ATS (template 6) horizontal inset (preview px = PDF pt).
  static const double atsSerifRulesPageHorizontalInsetPt = 45;

  /// Serif Rules ATS page 2+ header gap (PDF pt). Page margin already sets top inset.
  static const double atsSerifRulesContinuationPageTopGapPt = 0;

  /// Serif Rules ATS — gap between sections (preview px = PDF pt).
  static const double atsSerifRulesSectionGapPt = 16;

  /// Space before a section title (after prior section or header block).
  static const double atsSerifRulesSectionLeadGapPt = 6;

  /// Section title to horizontal rule.
  static const double atsSerifRulesSectionTitleToRuleGapPt = 3;

  /// Rule to section body content.
  static const double atsSerifRulesSectionContentTopGapPt = 5;

  /// Serif Rules 240px grid tile — tighter gaps between sections (logical px).
  static const double atsSerifRulesGridSectionGapPx = 3;
  static const double atsSerifRulesGridSectionLeadGapPx = 3;
  static const double atsSerifRulesGridSectionTitleToRuleGapPx = 2;
  static const double atsSerifRulesGridSectionContentTopGapPx = 2;

  /// Template grid tile bottom inset (logical px in 240px-wide art).
  static const double atsStructuredGridBottomInsetPx = 30;

  /// Structured ATS body ink (preview + template art; matches PDF black).
  static const Color atsStructuredBodyTextColor = Color(0xFF000000);

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

  /// Dark Header (corporate template) — Garamond; same scale as Accent Strip.
  static const double darkHeaderNamePt = accentStripNamePt;
  static const double darkHeaderInitialsPt = 48;
  static const double darkHeaderSectionTitlePt = accentStripSectionTitlePt;
  static const double darkHeaderSubtitlePt = accentStripSubsectionPt;

  /// Corporate body paragraph line height (preview + PDF).
  static const double darkHeaderBodyLineHeight = creativeBodyLineHeight;

  /// Subtitle lines (role/company, school line, project title).
  static const Color darkHeaderSubtitleColor = atsStructuredBodyTextColor;

  static const int darkHeaderBodyWeight = accentStripBodyWeight;
  static const int darkHeaderContactWeight = accentStripContactWeight;

  /// Line height for dark header contact lines (1 or 2 rows).
  static const double darkHeaderContactLineHeight = textLineHeight;

  static double darkHeaderContactPdfLineSpacingFor(double fontSizePt) =>
      fontSizePt * (darkHeaderContactLineHeight - 1);
  static const int darkHeaderInitialsWeight = accentStripSubtitleWeight;
  static const int darkHeaderNameWeight = accentStripNameWeight;
  static const int darkHeaderSectionTitleWeight = accentStripTitleWeight;
  static const int darkHeaderSubtitleWeight = accentStripSubtitleWeight;

  /// Profile Sidebar (creative / template 2) — Garamond; same scale as Accent Strip.
  static const double creativeNamePt = accentStripNamePt;
  static const int creativeNameWeight = accentStripNameWeight;
  static const int creativeSidebarContentWeight = accentStripContactWeight;
  static const double creativeSectionTitlePt = accentStripSectionTitlePt;
  static const int creativeSectionTitleWeight = accentStripTitleWeight;
  /// Legacy design reference; body copy uses [ResumeData.effectiveBodyFontPt] (11–13).
  static const double creativeBodyPt = 14;
  static const int creativeBodyWeight = accentStripBodyWeight;
  static const double creativeSubtitlePt = accentStripSubsectionPt;
  static const int creativeSubtitleWeight = accentStripSubtitleWeight;

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

  /// Classic Sidebar (template 3) — Garamond; same scale as Accent Strip.
  static const double classicSidebarNamePt = accentStripNamePt;
  static const int classicSidebarNameWeight = accentStripNameWeight;
  static const double classicSidebarAvatarInitialsNameRatio = 1.15;
  static const double classicSidebarAvatarInitialsExtraPt = 18;

  /// Sidebar avatar initials (scaled name × ratio + extra points).
  static double classicSidebarAvatarInitialsFontPt(double scaledNamePt) =>
      scaledNamePt * classicSidebarAvatarInitialsNameRatio +
      classicSidebarAvatarInitialsExtraPt;
  static const int classicSidebarSidebarContentWeight = accentStripContactWeight;
  static const double classicSidebarSectionTitlePt = accentStripSectionTitlePt;
  static const int classicSidebarSectionTitleWeight = accentStripTitleWeight;
  /// Legacy design reference; body copy uses [ResumeData.effectiveBodyFontPt] (11–13).
  static const double classicSidebarBodyPt = 14;
  static const int classicSidebarBodyWeight = accentStripBodyWeight;

  /// Accent Strip body — Garamond Regular (400).
  static const int accentStripBodyWeight = 400;

  static const double classicSidebarSubtitlePt = accentStripSubsectionPt;
  static const int classicSidebarSubtitleWeight = accentStripSubtitleWeight;

  static const double classicSidebarBodyLineHeight = 1.2;

  static double classicSidebarBodyPdfLineSpacingFor(double fontSizePt) =>
      fontSizePt * (classicSidebarBodyLineHeight - 1);

  /// Classic Sidebar body copy (preview + PDF).
  static const Color classicSidebarBodyTextColor = Color(0xFF000000);

  /// Accent Strip body — Garamond at [accentStripBodyWeight].
  static TextStyle accentStripBodyPreviewStyle({
    double? fontSize,
    Color? color,
    double? height,
  }) =>
      garamondPreviewStyle(
        weight: accentStripBodyWeight,
        fontSize: fontSize,
        color: color,
        height: height ?? creativeBodyLineHeight,
      );

  /// Templates 2–3 body — Garamond Regular at [creativeBodyWeight].
  static TextStyle sidebarBodyPreviewStyle({
    double? fontSize,
    Color? color,
    double? height,
    int weight = creativeBodyWeight,
  }) =>
      garamondPreviewStyle(
        weight: weight,
        fontSize: fontSize,
        color: color,
        height: height ?? creativeBodyLineHeight,
      );

  /// @deprecated Use [sidebarBodyPreviewStyle] for templates 2–3.
  static TextStyle nunitoBodyPreviewStyle({
    double? fontSize,
    Color? color,
    double? height,
    int weight = creativeBodyWeight,
  }) =>
      sidebarBodyPreviewStyle(
        fontSize: fontSize,
        color: color,
        height: height,
        weight: weight,
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
