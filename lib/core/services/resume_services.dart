import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'app_preferences.dart';
import '../corporate_resume_style.dart';
import '../models/resume_models.dart';
import '../resume_font_weight.dart';
import '../resume_text_font.dart';
import 'google_drive_resume_service.dart';
import 'icloud_resume_service.dart';
import 'profile_image_storage.dart';
import 'resume_pdf/arimo_pdf_fonts.dart';
import 'resume_pdf/calibri_pdf_fonts.dart' hide darkHeaderInitialsPdfStyle;
import 'resume_pdf/garamond_pdf_fonts.dart';
import 'resume_pdf/inter_pdf_fonts.dart';
import 'resume_pdf/resume_pdf_theme.dart';

part 'resume_pdf/resume_pdf_template_pages.dart';
part 'resume_pdf/resume_pdf_highlighted_pages.dart';
part 'resume_pdf/resume_pdf_ats_pages.dart';

PdfColor _pdfRgb(Color c) => PdfColor(c.r, c.g, c.b);

final RegExp _pdfContactUrlPattern = RegExp(
  r'((?:https?:\/\/)?(?:www\.)?(?:github\.com|linkedin\.com|[a-z0-9-]+(?:\.[a-z0-9-]+)+)\/[^\s|,;)]*|(?:https?:\/\/)?(?:www\.)?[a-z0-9-]+(?:\.[a-z0-9-]+)+)',
  caseSensitive: false,
);

String? _pdfContactDestination(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.contains('@') ||
      !_pdfContactUrlPattern.hasMatch(trimmed)) {
    return null;
  }
  if (trimmed.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))) {
    return trimmed;
  }
  return 'https://$trimmed';
}

pw.Widget _pdfContactText(
  String value, {
  required pw.TextStyle style,
  pw.TextAlign? textAlign,
}) {
  final matches = _pdfContactUrlPattern.allMatches(value).toList();
  if (matches.isEmpty) {
    return pw.Text(value, style: style, textAlign: textAlign);
  }

  var cursor = 0;
  final spans = <pw.InlineSpan>[];
  for (final match in matches) {
    if (match.start > cursor) {
      spans.add(pw.TextSpan(text: value.substring(cursor, match.start)));
    }
    final linkText = value.substring(match.start, match.end);
    final destination = _pdfContactDestination(linkText);
    spans.add(
      pw.TextSpan(
        text: linkText,
        annotation: destination == null ? null : pw.AnnotationUrl(destination),
      ),
    );
    cursor = match.end;
  }
  if (cursor < value.length) {
    spans.add(pw.TextSpan(text: value.substring(cursor)));
  }

  return pw.RichText(
    textAlign: textAlign ?? pw.TextAlign.left,
    text: pw.TextSpan(style: style, children: spans),
  );
}

PdfColor _corporateTitlePdf(ResumeData resume) =>
    _pdfRgb(resume.corporateColorPreset.titleColor);

PdfColor _corporateHeaderPdf(ResumeData resume) =>
    _pdfRgb(resume.corporateColorPreset.headerColor);

PdfColor _corporateHeaderOnPdf(ResumeData resume) =>
    _pdfRgb(resume.corporateColorPreset.headerOnColor);

PdfColor _coverLetterHeaderPdf(CoverLetterData letter) =>
    _pdfRgb(letter.corporateColorPreset.headerColor);

PdfColor _coverLetterHeaderOnPdf(CoverLetterData letter) =>
    _pdfRgb(letter.corporateColorPreset.headerOnColor);

/// Cover letter body paragraphs (matches [ResumeTypography.atsStructuredBodyTextColor]).
PdfColor _coverLetterBodyTextPdf() => PdfColors.black;

double _coverLetterBodyPt(CoverLetterData letter) =>
    letter.coverLetterBodyScaledPt();

double _coverLetterHeadingPt(CoverLetterData letter, [double designPt = 14]) =>
    letter.coverLetterHeadingScaledPt(designPt);

double _coverLetterNamePt(CoverLetterData letter, [double designPt = 24]) =>
    letter.coverLetterNameScaledPt(designPt);

List<String> _corporateHeaderContactLines(List<String> items) {
  final cleaned = items.where((item) => item.trim().isNotEmpty).toList();
  if (cleaned.isEmpty) {
    return const <String>[];
  }
  if (cleaned.length <= 2) {
    return <String>[cleaned.join(' | ')];
  }
  final firstLine = cleaned.take(2).join(' | ');
  final secondLine = cleaned.skip(2).join(' | ');
  return <String>[firstLine, if (secondLine.isNotEmpty) secondLine];
}

List<String> _projectBulletLinesPdf(ProjectItem item) {
  final nonEmptyBullets = item.bullets
      .where((b) => b.trim().isNotEmpty)
      .toList();
  if (nonEmptyBullets.isNotEmpty) {
    return nonEmptyBullets;
  }
  return [
    item.overview.trim(),
    item.impact.trim(),
  ].where((part) => part.isNotEmpty).toList();
}

List<pw.Widget> _pwCompactProjectWidgets(
  ProjectItem item, {
  GaramondPdfFonts? garamond,
  double bodyFontPt = ResumeTypography.bodyPt,
  bool atsGaramondBody = false,
  bool atsModernFlowGaramondBody = false,
  bool atsExecutiveGaramondBody = false,
}) {
  final bullets = _projectBulletLinesPdf(item);
  final subtitleWeight = atsGaramondBody
      ? ResumeTypography.atsStructuredSubtitleWeight
      : ResumeTypography.darkHeaderSubtitleWeight;
  final subtitlePt = atsGaramondBody
      ? ResumeTypography.atsStructuredSubtitlePt
      : ResumeTypography.darkHeaderSubtitlePt;
  final titleWidget = garamond != null
      ? pw.Text(
          item.title.ifEmpty('Project'),
          style: garamondPdfTextStyle(
            garamond,
            subtitleWeight,
            fontSize: subtitlePt,
            color: const PdfColor.fromInt(0xFF141414),
          ).copyWith(lineSpacing: 0),
        )
      : pw.Text(
          item.title.ifEmpty('Project'),
          style: pw.TextStyle(
            color: PdfColors.black,
            fontSize: subtitlePt,
            fontWeight: pw.FontWeight.bold,
          ),
        );
  final bulletStyle = garamond != null
      ? (atsModernFlowGaramondBody
            ? atsModernFlowBodyPdfTextStyle(garamond, bodyFontPt)
            : atsExecutiveGaramondBody
            ? atsExecutiveBodyPdfTextStyle(garamond, bodyFontPt)
            : atsGaramondBody
            ? atsStructuredBodyPdfTextStyle(garamond, bodyFontPt)
            : corporateBodyPdfTextStyle(garamond, bodyFontPt))
      : pw.TextStyle(
          color: PdfColors.black,
          fontSize: bodyFontPt,
          lineSpacing: ResumeTypography.darkHeaderBodyPdfLineSpacingFor(
            bodyFontPt,
          ),
        );
  return [
    titleWidget,
    for (var i = 0; i < bullets.length; i++)
      pw.Padding(
        padding: pw.EdgeInsets.only(top: i == 0 ? 2 : 3),
        child: pw.Bullet(text: bullets[i], style: bulletStyle),
      ),
    pw.SizedBox(height: 8),
  ];
}

pw.Widget _pwCustomSectionBody(CustomSectionItem item) {
  switch (item.layoutMode) {
    case CustomSectionLayoutMode.summary:
      return pw.Text(item.content.trim());
    case CustomSectionLayoutMode.bullets:
      final lines = item.bullets.where((b) => b.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        return pw.SizedBox();
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: i == 0 ? 2 : 3),
              child: pw.Bullet(
                text: lines[i].trim(),
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: ResumeTypography.bodyPt,
                ),
              ),
            ),
        ],
      );
    case CustomSectionLayoutMode.projects:
      final entries = item.visibleProjectEntries;
      if (entries.isEmpty) {
        return pw.SizedBox();
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final entry in entries) ..._pwCompactProjectWidgets(entry),
        ],
      );
  }
}

List<pw.Widget> _pwCustomSectionBodyWidgets(
  CustomSectionItem item, {
  InterPdfFonts? inter,
  CalibriPdfFonts? calibri,
  GaramondPdfFonts? garamond,
  double? bodyFontPt,
  bool accentStripGaramondBody = false,
  bool atsModernFlowGaramondBody = false,
  bool atsExecutiveGaramondBody = false,
  ArimoPdfFonts? arimo,
  bool atsCenterClassicArimoBody = false,
  bool atsProfessionalBlueArimoBody = false,
}) {
  final bodyStyle = arimo != null && bodyFontPt != null
      ? atsCenterClassicArimoBody
            ? atsCenterClassicBodyPdfTextStyle(arimo, bodyFontPt)
            : atsProfessionalBlueArimoBody
            ? atsProfessionalBlueBodyPdfTextStyle(arimo, bodyFontPt)
            : atsCenterClassicBodyPdfTextStyle(arimo, bodyFontPt)
      : garamond != null && bodyFontPt != null
      ? accentStripGaramondBody
            ? accentStripBodyPdfTextStyle(garamond, bodyFontPt)
            : atsModernFlowGaramondBody
            ? atsModernFlowBodyPdfTextStyle(garamond, bodyFontPt)
            : atsExecutiveGaramondBody
            ? atsExecutiveBodyPdfTextStyle(garamond, bodyFontPt)
            : atsStructuredBodyPdfTextStyle(garamond, bodyFontPt)
      : calibri != null && bodyFontPt != null
      ? nunitoBodyPdfTextStyle(calibri, bodyFontPt)
      : inter != null && bodyFontPt != null
      ? interDarkHeaderBodyPdfTextStyle(inter, bodyFontPt)
      : pw.TextStyle(
          color: PdfColors.black,
          fontSize: bodyFontPt ?? ResumeTypography.bodyPt,
        );
  switch (item.layoutMode) {
    case CustomSectionLayoutMode.summary:
      final content = item.content.trim();
      if (content.isEmpty) {
        return const <pw.Widget>[];
      }
      return [pw.Text(content, style: bodyStyle)];
    case CustomSectionLayoutMode.bullets:
      final lines = item.bullets.where((b) => b.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        return const <pw.Widget>[];
      }
      return [
        for (var i = 0; i < lines.length; i++)
          pw.Padding(
            padding: pw.EdgeInsets.only(top: i == 0 ? 2 : 3),
            child: pw.Bullet(text: lines[i].trim(), style: bodyStyle),
          ),
      ];
    case CustomSectionLayoutMode.projects:
      final entries = item.visibleProjectEntries;
      if (entries.isEmpty) {
        return const <pw.Widget>[];
      }
      return [
        for (final entry in entries)
          ..._pwCompactProjectWidgets(
            entry,
            garamond: garamond,
            bodyFontPt: bodyFontPt ?? ResumeTypography.bodyPt,
            atsGaramondBody:
                accentStripGaramondBody ||
                atsModernFlowGaramondBody ||
                atsExecutiveGaramondBody,
            atsModernFlowGaramondBody: atsModernFlowGaramondBody,
            atsExecutiveGaramondBody: atsExecutiveGaramondBody,
          ),
      ];
  }
}

pw.Widget _creativeAvatarIconPlaceholder({
  double width = 96,
  double height = 112,
  String initials = 'DA',
  required PdfColor backgroundColor,
  PdfColor textColor = const PdfColor(0.9098, 0.3647, 0.0157),
}) {
  final bgColor = PdfColor(
    backgroundColor.red,
    backgroundColor.green,
    backgroundColor.blue,
    _creativeAvatarBackgroundOpacity,
  );

  return pw.Container(
    width: width,
    height: height,
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(2),
      color: bgColor,
    ),
    alignment: pw.Alignment.center,
    child: pw.Text(
      initials,
      style: pw.TextStyle(
        color: textColor,
        fontSize: width * 0.28,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

const double _creativeSidebarRailWidthPt = 176.0;
const double _creativeAvatarWidthPt = 150.0;
const double _creativeSidebarContentInsetPt =
    (_creativeSidebarRailWidthPt - _creativeAvatarWidthPt) / 2;
const double _creativeAvatarHeightPt = 175.0;
// Ensure Template 2 body starts to the right of sidebar rail.
const double _creativeMainColumnInsetPt =
    _creativeSidebarRailWidthPt + ResumeTypography.creativeSidebarBodyGap;
const double _creativeSectionGapPt = 20.0;
const double _creativeHeadingBodyGapPt = 8.0;
const double _creativeSidebarDividerGapPt = 20.0;
const double _creativeNameFontPt = ResumeTypography.creativeNamePt;
const double _creativeAvatarBackgroundOpacity = 0.4;

const double _classicSidebarRailWidthPt = 165.0;
const double _classicSidebarContentWidthPt = 134.0;
const double _classicSidebarMainInsetPt = 159.0;
const double _classicSidebarAvatarSizePt = 130.0;
const double _classicSidebarSectionGapPt = 12.0;
const double _classicSidebarHeadingGapPt = 6.0;
const double _classicSidebarSectionBottomPt = 8.0;
const double _classicSidebarSectionDividerGapPt = 8.0;
const double _classicSidebarPanelTopPt = 24.0;
const double _classicSidebarPanelBottomPt = 0.0;
const double _classicSidebarPageLeftMargin = 20.0;
const double _classicSidebarPageRightMargin = 40.0;

/// Extra left inset on full-width pages so total left matches [_classicSidebarPageRightMargin].
const double _classicSidebarContinuationPageLeftInsetPt =
    _classicSidebarPageRightMargin - _classicSidebarPageLeftMargin;
const double _classicSidebarPageTopMargin = 20.0;
const double _classicSidebarFirstPageMainTopGapPt = 16.0;
const double _classicSidebarPageBottomMargin = 18.0;
const double _classicSidebarFirstPageExtraBottomPaddingPt = 24.0;
const double _classicSidebarPanelLeftInsetPt =
    (_classicSidebarRailWidthPt - _classicSidebarContentWidthPt) / 2;
const double _detailsSidebarRailWidthPt = 164.0;
const double _detailsSidebarPanelWidthPt = 118.0;
const double _detailsSidebarPanelLeftInsetPt = 28.0;
const double _detailsSidebarMainInsetPt = 170.0;
const double _detailsSidebarSectionGapPt = 18.0;
const double _detailsSidebarHeadingGapPt = 6.0;

enum _ClassicSidebarSectionType { skills, languages }

class _ClassicSidebarPageSection {
  const _ClassicSidebarPageSection({
    required this.type,
    required this.items,
    this.highlightedItems = const <String>{},
    this.showSectionTitle = true,
  });

  final _ClassicSidebarSectionType type;
  final List<String> items;
  final Set<String> highlightedItems;

  /// False for continued Skills lists on page 2+ (title shown only once).
  final bool showSectionTitle;
}

class _ClassicSidebarPageSlice {
  const _ClassicSidebarPageSlice({
    required this.showAvatar,
    required this.sections,
  });

  final bool showAvatar;
  final List<_ClassicSidebarPageSection> sections;

  bool get hasContent => showAvatar || sections.isNotEmpty;
}

PdfColor _creativeSidebarRailColorPdf(ResumeData resume) =>
    _pdfRgb(resume.creativeRailColor);

PdfColor _creativeSidebarAccentColorPdf(ResumeData resume) =>
    _pdfRgb(resume.creativeAccentColor);

PdfColor _creativeTitleColorPdf(ResumeData resume) =>
    _pdfRgb(resume.creativeTitleColor);

PdfColor _creativeSidebarLineColorPdf() => PdfColor.fromHex('#CDBAAC');

PdfColor _creativeSidebarMutedColorPdf() => PdfColor.fromHex('#5F656C');

PdfColor _creativeBodyTextColorPdf() => PdfColors.black;

PdfColor _classicSidebarRailColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarRailColor);

PdfColor _classicSidebarAccentColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarAccentColor);

PdfColor _classicSidebarTitleColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarTitleColor);

PdfColor _classicSidebarMutedColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarMutedColor);

PdfColor _classicSidebarDividerColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarDividerColor);

PdfColor _classicSidebarSectionBorderPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarSectionBorderColor);

PdfColor _classicSidebarAvatarFillPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarAvatarFillColor);

pw.TextStyle _classicSidebarPdfTextStyle(
  GaramondPdfFonts? garamond,
  int weight,
  double fontSize, {
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) {
  if (garamond == null) {
    return pw.TextStyle(color: color, fontSize: fontSize, fontStyle: fontStyle);
  }
  if (weight == ResumeTypography.classicSidebarBodyWeight) {
    return accentStripBodyPdfTextStyle(
      garamond,
      fontSize,
      color: color,
      fontStyle: fontStyle,
    );
  }
  return garamondPdfTextStyle(
    garamond,
    weight,
    fontSize: fontSize,
    color: color,
    fontStyle: fontStyle,
  );
}

PdfColor _detailsSidebarRailColorPdf(ResumeData resume) =>
    _pdfRgb(resume.detailsSidebarRailColor);

PdfColor _detailsSidebarAccentColorPdf(ResumeData resume) =>
    _pdfRgb(resume.detailsSidebarAccentColor);

PdfColor _detailsSidebarTitleColorPdf(ResumeData resume) =>
    _pdfRgb(resume.detailsSidebarTitleColor);

PdfColor _detailsSidebarMutedColorPdf(ResumeData resume) =>
    _pdfRgb(resume.detailsSidebarMutedColor);

PdfColor _detailsSidebarDividerColorPdf(ResumeData resume) =>
    _pdfRgb(resume.detailsSidebarDividerColor);

/// Profile Sidebar page 2+ top spacing comes from [creativeBodyTopMargin] on
/// [_creativeSidebarPageTheme]; do not add an extra header gap like corporate.
pw.Widget _creativeContinuedPageTopGap(pw.Context context) => pw.SizedBox();

pw.PageTheme _creativeSidebarPageTheme({
  required PdfColor railColor,
  pw.Widget? firstPageSidebar,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) {
  return pw.PageTheme(
    pageFormat: pageFormat,
    margin: pw.EdgeInsets.fromLTRB(
      0,
      ResumeTypography.creativeBodyTopMargin,
      ResumeTypography.creativeMainColumnRightInset,
      ResumeTypography.creativeBodyBottomMargin,
    ),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: context.pageNumber == 1
          ? pw.Stack(
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      width: _creativeSidebarRailWidthPt,
                      color: railColor,
                    ),
                    pw.Expanded(child: pw.Container(color: PdfColors.white)),
                  ],
                ),
                if (firstPageSidebar != null)
                  pw.Positioned(left: 0, top: 0, child: firstPageSidebar),
              ],
            )
          : pw.Container(color: PdfColors.white),
    ),
  );
}

pw.Widget _creativeSectionHeadingRow({
  required String title,
  required PdfColor titleColor,
  required PdfColor lineColor,
  GaramondPdfFonts? garamond,
  required double sectionTitlePt,
}) {
  final headingColor = _creativeBodyTextColorPdf();
  final headingStyle = garamond != null
      ? garamondPdfTextStyle(
          garamond,
          ResumeTypography.creativeSectionTitleWeight,
          fontSize: sectionTitlePt,
          color: headingColor,
        ).copyWith(letterSpacing: 0.15)
      : pw.TextStyle(
          fontSize: sectionTitlePt,
          fontWeight: pw.FontWeight.normal,
          color: headingColor,
          letterSpacing: 0.15,
        );
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(title.toUpperCase(), style: headingStyle),
      pw.SizedBox(width: 8),
      pw.Expanded(child: pw.Container(height: 1.2, color: lineColor)),
    ],
  );
}

pw.Widget _creativeMainColumnChild(pw.Widget child) {
  return _CreativePageAwareInset(child: child);
}

pw.Widget _classicSidebarMainColumnChild(
  pw.Widget child, {
  required int sidebarPageCount,
}) {
  return _ClassicSidebarDynamicInset(
    child: child,
    sidebarPageCount: sidebarPageCount,
  );
}

pw.Widget _classicSidebarFirstPageBottomSpacer(pw.Context context) =>
    context.pageNumber == 1
    ? pw.SizedBox(height: _classicSidebarFirstPageExtraBottomPaddingPt)
    : pw.SizedBox();

class _CreativePageAwareInset extends pw.SingleChildWidget {
  _CreativePageAwareInset({required pw.Widget child}) : super(child: child);

  double _leftInsetFor(pw.Context context) => context.pageNumber == 1
      ? _creativeMainColumnInsetPt
      : ResumeTypography.creativeContinuationPageHorizontalInset;

  // ignore: must_call_super
  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final leftInset = _leftInsetFor(context);

    if (child != null) {
      final childConstraints = constraints.deflate(
        pw.EdgeInsets.only(left: leftInset),
      );
      child!.layout(context, childConstraints, parentUsesSize: parentUsesSize);
      assert(child!.box != null);
      box = constraints.constrainRect(
        width: child!.box!.width + leftInset,
        height: child!.box!.height,
      );
      return;
    }

    box = constraints.constrainRect(width: leftInset, height: 0);
  }

  // ignore: must_call_super
  // ignore: must_call_super
  // ignore: must_call_super
  @override
  void paint(pw.Context context) {
    super.paint(context);

    final leftInset = _leftInsetFor(context);
    if (child == null) {
      return;
    }

    final mat = context.canvas.getTransform();
    mat.translateByDouble(box!.x + leftInset, box!.y, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(mat);
    child!.paint(context);
    context.canvas.restoreContext();
  }
}

class _ClassicSidebarDynamicInset extends pw.Widget with pw.SpanningWidget {
  _ClassicSidebarDynamicInset({
    required this.child,
    required this.sidebarPageCount,
  });

  final pw.Widget child;
  final int sidebarPageCount;
  pw.Widget? _wrapped;

  double _leftInsetFor(pw.Context context) =>
      context.pageNumber <= sidebarPageCount
      ? _classicSidebarMainInsetPt
      : _classicSidebarContinuationPageLeftInsetPt;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    _wrapped = pw.Padding(
      padding: pw.EdgeInsets.only(left: _leftInsetFor(context)),
      child: child,
    );
    _wrapped!.layout(context, constraints, parentUsesSize: parentUsesSize);
    box = _wrapped!.box;
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    if (_wrapped == null) {
      return;
    }

    final mat = context.canvas.getTransform();
    mat.translateByDouble(box!.x, box!.y, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(mat);
    _wrapped!.paint(context);
    context.canvas.restoreContext();
  }

  @override
  bool get canSpan =>
      child is pw.SpanningWidget && (child as pw.SpanningWidget).canSpan;

  @override
  bool get hasMoreWidgets =>
      child is pw.SpanningWidget && (child as pw.SpanningWidget).hasMoreWidgets;

  @override
  void restoreContext(covariant pw.WidgetContext context) {
    if (child is pw.SpanningWidget) {
      (child as pw.SpanningWidget).restoreContext(context);
    }
  }

  @override
  pw.WidgetContext saveContext() {
    if (child is pw.SpanningWidget) {
      return (child as pw.SpanningWidget).saveContext();
    }
    throw UnimplementedError();
  }
}

pw.Widget _creativeSidebarContactRow(
  String value, {
  required PdfColor iconColor,
  required PdfColor textColor,
  GaramondPdfFonts? garamond,
  required double bodyPt,
}) {
  final textStyle = garamond != null
      ? garamondPdfTextStyle(
          garamond,
          ResumeTypography.creativeSidebarContentWeight,
          fontSize: bodyPt,
          color: textColor,
          lineSpacing: ResumeTypography.creativeBodyPdfLineSpacingFor(bodyPt),
        )
      : pw.TextStyle(color: textColor, fontSize: bodyPt);
  const squareSize = 7.0;
  final firstLineExtent = bodyPt * ResumeTypography.creativeBodyLineHeight;

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          height: firstLineExtent,
          child: pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Container(
              width: squareSize,
              height: squareSize,
              margin: const pw.EdgeInsets.only(right: 6),
              decoration: pw.BoxDecoration(
                color: iconColor,
                borderRadius: pw.BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
        pw.Expanded(child: _pdfContactText(value, style: textStyle)),
      ],
    ),
  );
}

pw.PageTheme _classicSidebarPageTheme({
  required ResumeData resume,
  required PdfColor railColor,
  required PdfColor dividerColor,
  required PdfColor accentColor,
  required PdfColor titleColor,
  required PdfColor mutedColor,
  required double bodyPt,
  required double sectionTitlePt,
  GaramondPdfFonts? garamond,
  pw.MemoryImage? profileImage,
  Set<String> highlightedSkills = const <String>{},
  PdfColor? highlightColor,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) {
  final sidebarPages = _classicSidebarPageSlices(
    resume: resume,
    bodyPt: bodyPt,
    sectionTitlePt: sectionTitlePt,
    highlightedSkills: highlightedSkills,
    pageFormat: pageFormat,
  );
  return pw.PageTheme(
    pageFormat: pageFormat,
    margin: const pw.EdgeInsets.fromLTRB(
      _classicSidebarPageLeftMargin,
      _classicSidebarPageTopMargin,
      _classicSidebarPageRightMargin,
      _classicSidebarPageBottomMargin,
    ),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: context.pageNumber <= sidebarPages.length
          ? pw.Stack(
              children: [
                pw.Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: pw.Container(
                    width: _classicSidebarRailWidthPt,
                    color: railColor,
                  ),
                ),
                pw.Positioned(
                  left: _classicSidebarPanelLeftInsetPt,
                  top: _classicSidebarPanelTopPt,
                  child: _classicSidebarPanel(
                    resume: resume,
                    accentColor: accentColor,
                    dividerColor: dividerColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    bodyPt: bodyPt,
                    sectionTitlePt: sectionTitlePt,
                    garamond: garamond,
                    profileImage: profileImage,
                    highlightColor: highlightColor,
                    pageSlice: sidebarPages[context.pageNumber - 1],
                  ),
                ),
              ],
            )
          : pw.SizedBox(),
    ),
  );
}

List<_ClassicSidebarPageSlice> _classicSidebarPageSlices({
  required ResumeData resume,
  required double bodyPt,
  required double sectionTitlePt,
  required Set<String> highlightedSkills,
  required PdfPageFormat pageFormat,
}) {
  final sections =
      <
        ({
          _ClassicSidebarSectionType type,
          List<String> items,
          Set<String> highlightedItems,
        })
      >[
        if (resume.skillsForResume.isNotEmpty)
          (
            type: _ClassicSidebarSectionType.skills,
            items: resume.skillsForResume
                .where((item) => item.trim().isNotEmpty)
                .toList(),
            highlightedItems: highlightedSkills,
          ),
        if (_classicSidebarLanguageLines(resume).isNotEmpty)
          (
            type: _ClassicSidebarSectionType.languages,
            items: _classicSidebarLanguageLines(resume),
            highlightedItems: const <String>{},
          ),
      ];

  final pageOneSections = <_ClassicSidebarPageSection>[];
  final pageTwoSections = <_ClassicSidebarPageSection>[];
  final pages = [pageOneSections, pageTwoSections];
  var pageIndex = 0;
  var skillsSectionTitleUsed = false;
  final availableHeights = <double>[
    _classicSidebarAvailablePanelHeight(pageFormat) -
        _classicSidebarFirstPageHeaderHeight(),
    _classicSidebarAvailablePanelHeight(pageFormat),
  ];

  for (final section in sections) {
    var itemIndex = 0;

    while (itemIndex < section.items.length && pageIndex < pages.length) {
      final pageSections = pages[pageIndex];
      final sectionOverhead =
          (pageSections.isNotEmpty ? _classicSidebarInterSectionHeight() : 0) +
          _classicSidebarSectionTitleHeight(sectionTitlePt);
      if (availableHeights[pageIndex] <=
          sectionOverhead + _classicSidebarMinItemHeight(bodyPt)) {
        pageIndex++;
        continue;
      }

      if (pageSections.isNotEmpty) {
        availableHeights[pageIndex] -= _classicSidebarInterSectionHeight();
      }
      availableHeights[pageIndex] -= _classicSidebarSectionTitleHeight(
        sectionTitlePt,
      );

      final pageItems = <String>[];
      while (itemIndex < section.items.length) {
        final item = section.items[itemIndex];
        final itemHeight = _classicSidebarEstimatedItemHeight(
          item,
          bodyPt,
          itemBottom: section.type == _ClassicSidebarSectionType.skills ? 6 : 8,
        );
        if (pageItems.isNotEmpty && availableHeights[pageIndex] < itemHeight) {
          break;
        }
        if (pageItems.isEmpty && availableHeights[pageIndex] < itemHeight) {
          pageIndex++;
          break;
        }

        pageItems.add(item);
        availableHeights[pageIndex] -= itemHeight;
        itemIndex++;
      }

      if (pageItems.isNotEmpty) {
        final showSkillsHeading =
            section.type != _ClassicSidebarSectionType.skills ||
            !skillsSectionTitleUsed;
        pageSections.add(
          _ClassicSidebarPageSection(
            type: section.type,
            items: pageItems,
            highlightedItems: section.highlightedItems,
            showSectionTitle: section.type == _ClassicSidebarSectionType.skills
                ? showSkillsHeading
                : true,
          ),
        );
        if (section.type == _ClassicSidebarSectionType.skills) {
          skillsSectionTitleUsed = true;
        }
      }
    }
  }

  final slices = <_ClassicSidebarPageSlice>[
    _ClassicSidebarPageSlice(showAvatar: true, sections: pageOneSections),
  ];
  if (pageTwoSections.isNotEmpty) {
    slices.add(
      _ClassicSidebarPageSlice(showAvatar: false, sections: pageTwoSections),
    );
  }
  return slices;
}

double _classicSidebarAvailablePanelHeight(PdfPageFormat pageFormat) =>
    pageFormat.height -
    _classicSidebarPanelTopPt -
    _classicSidebarPanelBottomPt;

double _classicSidebarFirstPageHeaderHeight() =>
    _classicSidebarAvatarSizePt + _classicSidebarSectionGapPt + 1.2 + 10;

double _classicSidebarInterSectionHeight() =>
    _classicSidebarSectionGapPt + 1.2 + 10;

double _classicSidebarSectionTitleHeight(double sectionTitlePt) =>
    sectionTitlePt + 8;

double _classicSidebarMinItemHeight(double bodyPt) =>
    bodyPt * ResumeTypography.classicSidebarBodyLineHeight;

double _classicSidebarEstimatedItemHeight(
  String text,
  double fontSize, {
  required double itemBottom,
}) {
  final lines = _classicSidebarEstimatedLineCount(text, fontSize);
  return (lines * fontSize * ResumeTypography.classicSidebarBodyLineHeight) +
      itemBottom;
}

int _classicSidebarEstimatedLineCount(String text, double fontSize) {
  final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) {
    return 1;
  }

  final usableWidth = _classicSidebarContentWidthPt - 14;
  final maxCharsPerLine = math.max(
    8,
    (usableWidth / (fontSize * 0.56)).floor(),
  );
  var currentLineLength = 0;
  var lineCount = 1;

  for (final word in normalized.split(' ')) {
    final wordLength = word.length;
    if (currentLineLength == 0) {
      currentLineLength = wordLength;
      continue;
    }
    if (currentLineLength + 1 + wordLength > maxCharsPerLine) {
      lineCount++;
      currentLineLength = wordLength;
    } else {
      currentLineLength += 1 + wordLength;
    }
  }

  return lineCount;
}

pw.Widget _classicSidebarPanel({
  required ResumeData resume,
  required PdfColor accentColor,
  required PdfColor dividerColor,
  required PdfColor titleColor,
  required PdfColor mutedColor,
  required double bodyPt,
  required double sectionTitlePt,
  required _ClassicSidebarPageSlice pageSlice,
  GaramondPdfFonts? garamond,
  pw.MemoryImage? profileImage,
  PdfColor? highlightColor,
}) {
  final avatarInitialsPt = ResumeTypography.classicSidebarAvatarInitialsFontPt(
    resume.classicSidebarScaledPt(ResumeTypography.classicSidebarNamePt),
  );
  return pw.SizedBox(
    width: _classicSidebarContentWidthPt,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (pageSlice.showAvatar && profileImage != null)
          pw.Center(
            child: pw.ClipOval(
              child: pw.SizedBox(
                width: _classicSidebarAvatarSizePt,
                height: _classicSidebarAvatarSizePt,
                child: pw.Image(profileImage, fit: pw.BoxFit.cover),
              ),
            ),
          )
        else if (pageSlice.showAvatar)
          pw.Center(
            child: pw.Container(
              width: _classicSidebarAvatarSizePt,
              height: _classicSidebarAvatarSizePt,
              decoration: pw.BoxDecoration(
                color: _classicSidebarAvatarFillPdf(resume),
                shape: pw.BoxShape.circle,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                _classicSidebarInitials(resume),
                style: _classicSidebarPdfTextStyle(
                  garamond,
                  ResumeTypography.classicSidebarNameWeight,
                  avatarInitialsPt,
                  color: titleColor,
                ),
              ),
            ),
          ),
        if (pageSlice.showAvatar)
          pw.SizedBox(height: _classicSidebarSectionGapPt),
        if (pageSlice.showAvatar && pageSlice.sections.isNotEmpty)
          pw.Container(height: 1.2, color: dividerColor),
        if (pageSlice.showAvatar && pageSlice.sections.isNotEmpty)
          pw.SizedBox(height: 10),
        for (var index = 0; index < pageSlice.sections.length; index++) ...[
          if (index > 0) ...[
            pw.SizedBox(height: _classicSidebarSectionGapPt),
            pw.Container(height: 1.2, color: dividerColor),
            pw.SizedBox(height: 10),
          ],
          _classicSidebarListSection(
            title:
                pageSlice.sections[index].type ==
                    _ClassicSidebarSectionType.skills
                ? 'Skills'
                : 'Languages',
            items: pageSlice.sections[index].items,
            titleColor: titleColor,
            bulletColor: accentColor,
            textColor: titleColor,
            fontSize: bodyPt,
            sectionTitlePt: sectionTitlePt,
            garamond: garamond,
            textWeight: ResumeTypography.classicSidebarBodyWeight,
            highlightedItems: pageSlice.sections[index].highlightedItems,
            highlightColor: highlightColor,
            showTitle: pageSlice.sections[index].showSectionTitle,
            itemBottom:
                pageSlice.sections[index].type ==
                    _ClassicSidebarSectionType.skills
                ? 6
                : 8,
            titleBottomGap:
                pageSlice.sections[index].type ==
                    _ClassicSidebarSectionType.skills
                ? 14
                : 8,
          ),
        ],
      ],
    ),
  );
}

pw.Widget _classicSidebarListSection({
  required String title,
  required List<String> items,
  required PdfColor titleColor,
  required PdfColor bulletColor,
  required PdfColor textColor,
  required double fontSize,
  required double sectionTitlePt,
  GaramondPdfFonts? garamond,
  int textWeight = ResumeTypography.classicSidebarBodyWeight,
  Set<String> highlightedItems = const <String>{},
  PdfColor? highlightColor,
  bool showTitle = true,
  double itemBottom = 8,
  double titleBottomGap = 8,
}) {
  final visibleItems = items.where((item) => item.trim().isNotEmpty).toList();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (showTitle)
        pw.Text(
          title.toUpperCase(),
          style: _classicSidebarPdfTextStyle(
            garamond,
            ResumeTypography.classicSidebarSectionTitleWeight,
            sectionTitlePt,
            color: titleColor,
          ),
        ),
      if (showTitle) pw.SizedBox(height: titleBottomGap),
      if (visibleItems.isEmpty)
        pw.Text(
          'Add items',
          style: _classicSidebarPdfTextStyle(
            garamond,
            textWeight,
            fontSize,
            color: textColor,
          ),
        )
      else
        for (final item in visibleItems)
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: itemBottom),
            child: _classicBulletRow(
              text: item,
              bulletColor: bulletColor,
              textColor: textColor,
              fontSize: fontSize,
              garamond: garamond,
              textWeight: textWeight,
              backgroundColor: highlightedItems.contains(item)
                  ? highlightColor
                  : null,
            ),
          ),
    ],
  );
}

pw.Widget _highlightedPdfLineText(String text, {required pw.TextStyle style}) {
  return pw.Text(text, style: style);
}

pw.Widget _classicBulletRow({
  required String text,
  required PdfColor bulletColor,
  required PdfColor textColor,
  required double fontSize,
  GaramondPdfFonts? garamond,
  int textWeight = ResumeTypography.classicSidebarBodyWeight,
  PdfColor? backgroundColor,
}) {
  final row = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '•',
        style: _classicSidebarPdfTextStyle(
          garamond,
          ResumeTypography.classicSidebarSectionTitleWeight,
          fontSize,
          color: bulletColor,
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Expanded(
        child: pw.Text(
          text,
          style: _classicSidebarPdfTextStyle(
            garamond,
            textWeight,
            fontSize,
            color: textColor,
          ),
        ),
      ),
    ],
  );

  if (backgroundColor == null) {
    return row;
  }
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    color: backgroundColor,
    child: row,
  );
}

List<String> _classicSidebarLanguageLines(ResumeData resume) {
  final section = _classicSidebarLanguagesSection(resume);
  if (section == null) {
    return const <String>[];
  }
  if (section.layoutMode == CustomSectionLayoutMode.bullets) {
    return section.bullets.where((item) => item.trim().isNotEmpty).toList();
  }
  return section.content
      .split(RegExp(r'[\n,]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _classicSidebarExperienceCompanyDatesLine(WorkExperience item) {
  final company = item.company.trim();
  final dates = [
    item.startDate.trim(),
    item.endDate.trim(),
  ].where((value) => value.isNotEmpty).join(' - ');
  if (company.isEmpty && dates.isEmpty) {
    return '';
  }
  if (company.isEmpty) {
    return dates;
  }
  if (dates.isEmpty) {
    return company;
  }
  return '$company · $dates';
}

pw.Widget _classicSidebarSectionBodyBlock({
  bool showBottomBorder = true,
  required pw.Widget child,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      child,
      if (showBottomBorder) ...[
        pw.SizedBox(height: _classicSidebarSectionDividerGapPt),
        pw.SizedBox(height: _classicSidebarSectionBottomPt),
      ],
    ],
  );
}

String _classicSidebarInitials(ResumeData resume) {
  final name = resume.fullName.trim().isEmpty
      ? 'Your Name'
      : resume.fullName.trim();
  final words = name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (words.isEmpty) {
    return 'DA';
  }
  return words.map((part) => part[0].toUpperCase()).join();
}

CustomSectionItem? _classicSidebarLanguagesSection(ResumeData resume) {
  for (final item in resume.visibleCustomSections) {
    if (_isClassicSidebarLanguagesTitle(item.title)) {
      return item;
    }
  }
  return null;
}

bool _isClassicSidebarLanguagesTitle(String title) {
  final normalized = title.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z]'),
    '',
  );
  return normalized == 'language' ||
      normalized == 'languages' ||
      normalized == 'langueage' ||
      normalized == 'langueages';
}

List<CustomSectionItem> _classicSidebarMainCustomSections(ResumeData resume) {
  final languages = _classicSidebarLanguagesSection(resume);
  var skippedLanguages = false;
  return resume.visibleCustomSections.where((item) {
    if (!skippedLanguages && identical(item, languages)) {
      skippedLanguages = true;
      return false;
    }
    return true;
  }).toList();
}

List<String> _detailsSidebarInfoItems(ResumeData resume) {
  return [
    resume.email.trim(),
    resume.phone.trim(),
    resume.location.trim(),
    resume.website.trim(),
  ].where((item) => item.isNotEmpty).toList();
}

class _DetailsSidebarPageSlice {
  const _DetailsSidebarPageSlice({
    required this.showIdentity,
    required this.showSkillsHeading,
    required this.skills,
    required this.highlightedSkills,
  });

  final bool showIdentity;
  final bool showSkillsHeading;
  final List<String> skills;
  final Set<String> highlightedSkills;
}

List<_DetailsSidebarPageSlice> _detailsSidebarPageSlices({
  required ResumeData resume,
  required double bodyPt,
  required Set<String> highlightedSkills,
  required PdfPageFormat pageFormat,
}) {
  final skills = resume.includeSkillsInResume
      ? resume.skills.where((item) => item.trim().isNotEmpty).toList()
      : const <String>[];
  final infoItems = _detailsSidebarInfoItems(resume);
  final hasJobTitle = resume.jobTitle.trim().isNotEmpty;

  const panelTop = 24.0;
  const pageBottomMargin = 30.0;
  const bottomSafetyMargin = 20.0;
  const skillsBottomGap = 12.0;
  final availableHeight =
      pageFormat.height - panelTop - pageBottomMargin - bottomSafetyMargin;

  final headingBlockHeight =
      ResumeTypography.darkHeaderSectionTitlePt + 8 + 1 + 12;
  final infoItemsHeight = infoItems.isEmpty
      ? (bodyPt * ResumeTypography.bodyTextLineHeight)
      : infoItems.fold<double>(
          0,
          (sum, _) => sum + (bodyPt * ResumeTypography.bodyTextLineHeight) + 10,
        );
  final nameBlockHeight = 30 + (hasJobTitle ? (14 + bodyPt + 4) : 0) + 26;

  final firstPageFixedHeight =
      nameBlockHeight + headingBlockHeight + infoItemsHeight + 20;
  final firstPageSkillsAvailable =
      availableHeight -
      firstPageFixedHeight -
      headingBlockHeight -
      skillsBottomGap;
  final continuedPageSkillsAvailable =
      availableHeight - headingBlockHeight - skillsBottomGap;

  double skillHeight(String item) {
    final lines = _detailsSidebarEstimatedLineCount(item, bodyPt);
    return (lines * bodyPt * ResumeTypography.bodyTextLineHeight) + 11;
  }

  List<String> takeChunk(Iterable<String> source, double maxHeight) {
    final chunk = <String>[];
    var used = 0.0;
    for (final item in source) {
      final height = skillHeight(item);
      if (chunk.isNotEmpty && used + height > maxHeight) {
        break;
      }
      if (chunk.isEmpty && height > maxHeight) {
        chunk.add(item);
        break;
      }
      chunk.add(item);
      used += height;
    }
    return chunk;
  }

  if (skills.isEmpty) {
    return const [
      _DetailsSidebarPageSlice(
        showIdentity: true,
        showSkillsHeading: true,
        skills: <String>[],
        highlightedSkills: <String>{},
      ),
    ];
  }

  final slices = <_DetailsSidebarPageSlice>[];
  var index = 0;

  final firstChunk = takeChunk(
    skills.skip(index),
    firstPageSkillsAvailable > 0 ? firstPageSkillsAvailable : 0,
  );
  final firstShowsSkills = firstChunk.isNotEmpty;
  index += firstChunk.length;
  slices.add(
    _DetailsSidebarPageSlice(
      showIdentity: true,
      showSkillsHeading: firstShowsSkills,
      skills: firstChunk,
      highlightedSkills: highlightedSkills.intersection(firstChunk.toSet()),
    ),
  );

  while (index < skills.length) {
    final chunk = takeChunk(
      skills.skip(index),
      continuedPageSkillsAvailable > 0 ? continuedPageSkillsAvailable : 0,
    );
    if (chunk.isEmpty) {
      break;
    }
    index += chunk.length;
    slices.add(
      _DetailsSidebarPageSlice(
        showIdentity: false,
        showSkillsHeading: true,
        skills: chunk,
        highlightedSkills: highlightedSkills.intersection(chunk.toSet()),
      ),
    );
  }

  return slices;
}

int _detailsSidebarEstimatedLineCount(String text, double fontSize) {
  final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) {
    return 1;
  }
  final usableWidth = _detailsSidebarPanelWidthPt - 18;
  final maxCharsPerLine = math.max(
    8,
    (usableWidth / (fontSize * 0.56)).floor(),
  );
  var currentLineLength = 0;
  var lineCount = 1;
  for (final word in normalized.split(' ')) {
    final wordLength = word.length;
    if (currentLineLength == 0) {
      currentLineLength = wordLength;
      continue;
    }
    if (currentLineLength + 1 + wordLength > maxCharsPerLine) {
      lineCount++;
      currentLineLength = wordLength;
    } else {
      currentLineLength += 1 + wordLength;
    }
  }
  return lineCount;
}

pw.Widget _detailsSidebarMainColumnChild(pw.Widget child) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(left: _detailsSidebarMainInsetPt),
    child: child,
  );
}

pw.PageTheme _detailsSidebarPageTheme({
  required ResumeData resume,
  required PdfColor railColor,
  required PdfColor accentColor,
  required PdfColor titleColor,
  required PdfColor mutedColor,
  required PdfColor dividerColor,
  required double bodyPt,
  required List<_DetailsSidebarPageSlice> sidebarSlices,
  PdfColor? highlightColor,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) {
  return pw.PageTheme(
    pageFormat: pageFormat,
    margin: const pw.EdgeInsets.fromLTRB(24, 18, 24, 30),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(width: _detailsSidebarRailWidthPt, color: railColor),
              pw.Expanded(child: pw.Container(color: PdfColors.white)),
            ],
          ),
          if (context.pageNumber <= sidebarSlices.length)
            pw.Positioned(
              left: _detailsSidebarPanelLeftInsetPt,
              top: 24,
              child: _detailsSidebarPanel(
                resume: resume,
                accentColor: accentColor,
                titleColor: titleColor,
                mutedColor: mutedColor,
                dividerColor: dividerColor,
                bodyPt: bodyPt,
                pageSlice: sidebarSlices[context.pageNumber - 1],
                highlightColor: highlightColor,
              ),
            ),
        ],
      ),
    ),
  );
}

pw.Widget _detailsSidebarPanel({
  required ResumeData resume,
  required PdfColor accentColor,
  required PdfColor titleColor,
  required PdfColor mutedColor,
  required PdfColor dividerColor,
  required double bodyPt,
  required _DetailsSidebarPageSlice pageSlice,
  PdfColor? highlightColor,
}) {
  final infoItems = _detailsSidebarInfoItems(resume);
  final displayName = resume.fullName.trim().isEmpty
      ? 'Your Name'
      : resume.fullName.trim();

  return pw.SizedBox(
    width: _detailsSidebarPanelWidthPt,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (pageSlice.showIdentity) ...[
          pw.Text(
            displayName.toUpperCase(),
            style: pw.TextStyle(
              color: titleColor,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 1.1,
            ),
          ),
          if (resume.jobTitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              resume.jobTitle.trim(),
              style: pw.TextStyle(
                color: titleColor,
                fontSize: bodyPt + 1.3,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ],
          pw.SizedBox(height: 26),
          _detailsSidebarSidebarHeading(
            title: 'DETAILS',
            titleColor: titleColor,
            dividerColor: dividerColor,
          ),
          pw.SizedBox(height: 12),
          if (infoItems.isEmpty)
            pw.Text(
              'Add contact details',
              style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
            )
          else
            for (final item in infoItems)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: _detailsSidebarInfoRow(
                  text: item,
                  accentColor: accentColor,
                  textColor: mutedColor,
                  fontSize: bodyPt,
                ),
              ),
          pw.SizedBox(height: 20),
        ],
        if (pageSlice.showSkillsHeading) ...[
          _detailsSidebarSidebarHeading(
            title: 'SKILLS',
            titleColor: titleColor,
            dividerColor: dividerColor,
          ),
          pw.SizedBox(height: 12),
          if (pageSlice.skills.isEmpty)
            pw.Text(
              pageSlice.showIdentity ? 'Add skills' : '',
              style: pw.TextStyle(color: mutedColor, fontSize: bodyPt),
            )
          else
            for (final skill in pageSlice.skills)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 11),
                child: _detailsSidebarSkillRow(
                  text: skill,
                  accentColor: accentColor,
                  textColor: mutedColor,
                  fontSize: bodyPt,
                  backgroundColor: pageSlice.highlightedSkills.contains(skill)
                      ? highlightColor
                      : null,
                ),
              ),
        ],
      ],
    ),
  );
}

pw.Widget _detailsSidebarSidebarHeading({
  required String title,
  required PdfColor titleColor,
  required PdfColor dividerColor,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          color: titleColor,
          fontSize: ResumeTypography.darkHeaderSectionTitlePt,
          fontWeight: pw.FontWeight.normal,
          letterSpacing: 0.6,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 1, color: dividerColor),
    ],
  );
}

pw.Widget _detailsSidebarInfoRow({
  required String text,
  required PdfColor accentColor,
  required PdfColor textColor,
  required double fontSize,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: 12,
        height: 12,
        margin: const pw.EdgeInsets.only(top: 1, right: 7),
        decoration: pw.BoxDecoration(
          color: accentColor,
          borderRadius: pw.BorderRadius.circular(6),
        ),
      ),
      pw.Expanded(
        child: _pdfContactText(
          text,
          style: pw.TextStyle(color: textColor, fontSize: fontSize),
        ),
      ),
    ],
  );
}

pw.Widget _detailsSidebarSkillRow({
  required String text,
  required PdfColor accentColor,
  required PdfColor textColor,
  required double fontSize,
  PdfColor? backgroundColor,
}) {
  final row = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '·',
        style: pw.TextStyle(
          color: accentColor,
          fontSize: fontSize + 2,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Expanded(
        child: pw.Text(
          text,
          style: pw.TextStyle(color: textColor, fontSize: fontSize),
        ),
      ),
    ],
  );
  if (backgroundColor == null) {
    return row;
  }
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    color: backgroundColor,
    child: row,
  );
}

pw.Widget _detailsSidebarHeadingRow({
  required String title,
  required PdfColor titleColor,
  required PdfColor dividerColor,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          color: titleColor,
          fontSize: ResumeTypography.darkHeaderSectionTitlePt,
          fontWeight: pw.FontWeight.normal,
          letterSpacing: 0.6,
        ),
      ),
      pw.SizedBox(width: 12),
      pw.Expanded(child: pw.Container(height: 1, color: dividerColor)),
    ],
  );
}

pw.Widget _creativeSidebarEducationEntry(
  EducationItem item, {
  required PdfColor titleColor,
  required PdfColor mutedColor,
  GaramondPdfFonts? garamond,
  required double bodyPt,
  required double subtitlePt,
}) {
  final dates = [
    item.startDate.trim(),
    item.endDate.trim(),
  ].where((value) => value.isNotEmpty).join(' - ');

  final bodyColor = _creativeBodyTextColorPdf();
  final subtitleStyle = garamond != null
      ? garamondPdfTextStyle(
          garamond,
          ResumeTypography.creativeSubtitleWeight,
          fontSize: subtitlePt,
          color: bodyColor,
        )
      : pw.TextStyle(color: bodyColor, fontSize: subtitlePt);
  final bodyStyle = garamond != null
      ? accentStripBodyPdfTextStyle(garamond, bodyPt, color: bodyColor)
      : pw.TextStyle(color: bodyColor, fontSize: bodyPt);

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(item.degree.ifEmpty('Degree'), style: subtitleStyle),
        pw.SizedBox(height: 2),
        pw.Text(item.institution.ifEmpty('Institution'), style: bodyStyle),
        if (dates.isNotEmpty) ...[
          pw.SizedBox(height: 1.5),
          pw.Text(dates, style: bodyStyle),
        ],
      ],
    ),
  );
}

pw.Widget _creativeFirstPageSidebar({
  required ResumeData resume,
  required List<String> contactItems,
  required PdfColor accentColor,
  required PdfColor lineColor,
  required PdfColor mutedColor,
  GaramondPdfFonts? garamond,
  pw.MemoryImage? profileImage,
  required double bodyPt,
}) {
  return pw.SizedBox(
    width: _creativeSidebarRailWidthPt,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: ResumeTypography.creativeSidebarImageTopPadding),
        pw.Center(
          child: profileImage != null
              ? pw.ClipRRect(
                  horizontalRadius: 2,
                  verticalRadius: 2,
                  child: pw.Container(
                    width: _creativeAvatarWidthPt,
                    height: _creativeAvatarHeightPt,
                    child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                  ),
                )
              : _creativeAvatarIconPlaceholder(
                  width: _creativeAvatarWidthPt,
                  height: _creativeAvatarHeightPt,
                  initials: _creativeSidebarInitials(resume),
                  backgroundColor: _pdfRgb(
                    resume.creativeAvatarBackgroundColor,
                  ),
                  textColor: accentColor,
                ),
        ),
        if (contactItems.isNotEmpty) ...[
          pw.SizedBox(height: _creativeSectionGapPt),
          pw.Center(
            child: pw.Container(
              width: _creativeAvatarWidthPt,
              height: 1.2,
              color: lineColor,
            ),
          ),
          pw.SizedBox(height: _creativeSidebarDividerGapPt),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: _creativeSidebarContentInsetPt,
            ),
            child: pw.Column(
              children: [
                for (final item in contactItems)
                  _creativeSidebarContactRow(
                    item,
                    iconColor: accentColor,
                    textColor: mutedColor,
                    garamond: garamond,
                    bodyPt: bodyPt,
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

String _creativeSidebarInitials(ResumeData resume) {
  final name = resume.fullName.trim().isEmpty
      ? 'Your Name'
      : resume.fullName.trim();
  final words = name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (words.isEmpty) {
    return 'DA';
  }
  return words.map((part) => part[0].toUpperCase()).join();
}

class ResumeRepository {
  ResumeRepository._(this._resumeBox, this._coverLetterBox);

  final Box<dynamic> _resumeBox;
  final Box<dynamic> _coverLetterBox;
  AppPreferences? _appPreferences;
  bool Function()? _hasPremiumAccess;
  ICloudResumeService? _iCloudResumeService;
  Timer? _iCloudAutoSyncTimer;
  bool _isFlushingICloudAutoSync = false;
  final Set<String> _pendingICloudResumeIds = <String>{};
  final Set<String> _pendingICloudCoverLetterIds = <String>{};

  GoogleDriveResumeService? _googleDriveResumeService;
  Timer? _googleDriveAutoSyncTimer;
  bool _isFlushingGoogleDriveAutoSync = false;
  final Set<String> _pendingGoogleDriveResumeIds = <String>{};
  final Set<String> _pendingGoogleDriveCoverLetterIds = <String>{};

  static const Duration _iCloudAutoSyncDebounce = Duration(seconds: 2);
  static const Duration _googleDriveAutoSyncDebounce = Duration(seconds: 2);

  static Future<ResumeRepository> create() async {
    await Hive.initFlutter();
    final resumeBox = await Hive.openBox<dynamic>('resume_library');
    final coverLetterBox = await Hive.openBox<dynamic>('cover_letter_library');
    return ResumeRepository._(resumeBox, coverLetterBox);
  }

  void configureICloudAutoSync({
    required AppPreferences appPreferences,
    required ICloudResumeService service,
    bool Function()? hasPremium,
  }) {
    _appPreferences = appPreferences;
    _iCloudResumeService = service;
    _hasPremiumAccess = hasPremium;
  }

  bool get _canUseICloudBackup =>
      (_hasPremiumAccess?.call() ?? false) &&
      (_appPreferences?.isPremium ?? false);

  bool get _canUseGoogleDriveBackup =>
      (_hasPremiumAccess?.call() ?? false) &&
      (_appPreferences?.isPremium ?? false);

  void configureGoogleDriveAutoSync({
    required AppPreferences appPreferences,
    required GoogleDriveResumeService service,
    bool Function()? hasPremium,
  }) {
    _appPreferences = appPreferences;
    _googleDriveResumeService = service;
    if (hasPremium != null) {
      _hasPremiumAccess = hasPremium;
    }
  }

  Future<List<ResumeData>> loadResumes() async {
    final raw = _resumeBox.values
        .whereType<Map>()
        .map((item) => ResumeData.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final items = <ResumeData>[];
    for (final resume in raw) {
      final storedPath = resume.profileImagePath.trim();
      if (storedPath.isEmpty) {
        items.add(resume);
        continue;
      }
      final resolved = await ProfileImageStorage.resolvePath(
        storedPath,
        resume.id,
      );
      if (resolved != storedPath) {
        final updated = resume.copyWith(profileImagePath: resolved);
        await _resumeBox.put(resume.id, updated.toJson());
        items.add(updated);
      } else {
        items.add(resume);
      }
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> upsertResume(
    ResumeData resume, {
    bool scheduleAutoSync = true,
  }) async {
    await _resumeBox.put(resume.id, resume.toJson());
    if (scheduleAutoSync) {
      _scheduleICloudAutoSyncResume(resume.id);
      _scheduleGoogleDriveAutoSync(resume.id);
    }
  }

  Future<void> deleteResume(String id) async {
    final raw = _resumeBox.get(id);
    if (raw is Map) {
      final resume = ResumeData.fromJson(Map<String, dynamic>.from(raw));
      await ProfileImageStorage.deleteForResume(
        id,
        knownPath: resume.profileImagePath,
      );
    }
    await _resumeBox.delete(id);
  }

  void _scheduleICloudAutoSyncResume(String resumeId) {
    if (!_canUseICloudBackup ||
        !(_appPreferences?.iCloudAutoSyncEnabled ?? false)) {
      return;
    }

    _pendingICloudResumeIds.add(resumeId);
    _iCloudAutoSyncTimer?.cancel();
    _iCloudAutoSyncTimer = Timer(_iCloudAutoSyncDebounce, () {
      unawaited(_flushPendingICloudAutoSync());
    });
  }

  void _scheduleICloudAutoSyncCoverLetter(String coverLetterId) {
    if (!_canUseICloudBackup ||
        !(_appPreferences?.iCloudAutoSyncEnabled ?? false)) {
      return;
    }

    _pendingICloudCoverLetterIds.add(coverLetterId);
    _iCloudAutoSyncTimer?.cancel();
    _iCloudAutoSyncTimer = Timer(_iCloudAutoSyncDebounce, () {
      unawaited(_flushPendingICloudAutoSync());
    });
  }

  Future<void> _flushPendingICloudAutoSync() async {
    if (_isFlushingICloudAutoSync) {
      return;
    }

    final appPreferences = _appPreferences;
    final service = _iCloudResumeService;
    if (appPreferences == null || service == null || !_canUseICloudBackup) {
      _pendingICloudResumeIds.clear();
      _pendingICloudCoverLetterIds.clear();
      return;
    }

    _isFlushingICloudAutoSync = true;
    try {
      while (_pendingICloudResumeIds.isNotEmpty) {
        if (!appPreferences.iCloudAutoSyncEnabled || !_canUseICloudBackup) {
          _pendingICloudResumeIds.clear();
          _pendingICloudCoverLetterIds.clear();
          return;
        }

        final pendingIds = Set<String>.from(_pendingICloudResumeIds);
        _pendingICloudResumeIds.clear();

        if (!await service.isAvailable()) {
          return;
        }

        final localResumes = await loadResumes();
        final resumesToConsider = localResumes
            .where((resume) => pendingIds.contains(resume.id))
            .toList();
        if (resumesToConsider.isEmpty) {
          continue;
        }

        final cloudById = {
          for (final item in await service.listResumes())
            if (!item.isCoverLetter) item.id: item,
        };
        final resumesToUpload = resumesToConsider.where((resume) {
          final cloud = cloudById[resume.id];
          return cloud == null || !cloud.updatedAt.isAfter(resume.updatedAt);
        }).toList();
        if (resumesToUpload.isEmpty) {
          continue;
        }

        final uploadedIds = await service.uploadResumes(resumesToUpload);
        if (uploadedIds.isEmpty) {
          continue;
        }

        final syncedAt = DateTime.now();
        for (final resume in resumesToUpload) {
          if (!uploadedIds.contains(resume.id)) {
            continue;
          }
          await upsertResume(
            resume.copyWith(lastSyncedAt: syncedAt),
            scheduleAutoSync: false,
          );
        }
      }

      while (_pendingICloudCoverLetterIds.isNotEmpty) {
        if (!appPreferences.iCloudAutoSyncEnabled || !_canUseICloudBackup) {
          _pendingICloudCoverLetterIds.clear();
          _pendingICloudResumeIds.clear();
          return;
        }

        final pendingLetterIds = Set<String>.from(_pendingICloudCoverLetterIds);
        _pendingICloudCoverLetterIds.clear();

        if (!await service.isAvailable()) {
          return;
        }

        final localLetters = await loadCoverLetters();
        final lettersToConsider = localLetters
            .where((letter) => pendingLetterIds.contains(letter.id))
            .toList();
        if (lettersToConsider.isEmpty) {
          continue;
        }

        final cloudLettersById = {
          for (final item in await service.listResumes())
            if (item.isCoverLetter) item.id: item,
        };
        final lettersToUpload = lettersToConsider.where((letter) {
          final cloud = cloudLettersById[letter.id];
          return cloud == null || !cloud.updatedAt.isAfter(letter.updatedAt);
        }).toList();
        if (lettersToUpload.isEmpty) {
          continue;
        }

        final uploadedLetterIds = await service.uploadCoverLetters(
          lettersToUpload,
        );
        if (uploadedLetterIds.isEmpty) {
          continue;
        }

        final letterSyncedAt = DateTime.now();
        for (final letter in lettersToUpload) {
          if (!uploadedLetterIds.contains(letter.id)) {
            continue;
          }
          await upsertCoverLetter(
            letter.copyWith(lastSyncedAt: letterSyncedAt),
            scheduleAutoSync: false,
          );
        }
      }
    } catch (_) {
      // Keep local writes resilient; iCloud sync failures should not break saves.
    } finally {
      _isFlushingICloudAutoSync = false;
    }
  }

  void _scheduleGoogleDriveAutoSync(String resumeId) {
    if (!_canUseGoogleDriveBackup ||
        !(_appPreferences?.googleDriveAutoSyncEnabled ?? false)) {
      return;
    }

    _pendingGoogleDriveResumeIds.add(resumeId);
    _googleDriveAutoSyncTimer?.cancel();
    _googleDriveAutoSyncTimer = Timer(_googleDriveAutoSyncDebounce, () {
      unawaited(_flushPendingGoogleDriveAutoSync());
    });
  }

  void _scheduleGoogleDriveAutoSyncCoverLetter(String coverLetterId) {
    if (!_canUseGoogleDriveBackup ||
        !(_appPreferences?.googleDriveAutoSyncEnabled ?? false)) {
      return;
    }

    _pendingGoogleDriveCoverLetterIds.add(coverLetterId);
    _googleDriveAutoSyncTimer?.cancel();
    _googleDriveAutoSyncTimer = Timer(_googleDriveAutoSyncDebounce, () {
      unawaited(_flushPendingGoogleDriveAutoSync());
    });
  }

  Future<void> _flushPendingGoogleDriveAutoSync() async {
    if (_isFlushingGoogleDriveAutoSync) {
      return;
    }

    final appPreferences = _appPreferences;
    final service = _googleDriveResumeService;
    if (appPreferences == null ||
        service == null ||
        !_canUseGoogleDriveBackup) {
      _pendingGoogleDriveResumeIds.clear();
      _pendingGoogleDriveCoverLetterIds.clear();
      return;
    }

    _isFlushingGoogleDriveAutoSync = true;
    try {
      while (_pendingGoogleDriveResumeIds.isNotEmpty) {
        if (!appPreferences.googleDriveAutoSyncEnabled ||
            !_canUseGoogleDriveBackup) {
          _pendingGoogleDriveResumeIds.clear();
          _pendingGoogleDriveCoverLetterIds.clear();
          return;
        }

        final pendingIds = Set<String>.from(_pendingGoogleDriveResumeIds);
        _pendingGoogleDriveResumeIds.clear();

        if (!await service.hasAuthorizedSession()) {
          return;
        }

        final localResumes = await loadResumes();
        final resumesToConsider = localResumes
            .where((resume) => pendingIds.contains(resume.id))
            .toList();
        if (resumesToConsider.isEmpty) {
          continue;
        }

        final cloudById = {
          for (final item in await service.listResumes())
            if (!item.isCoverLetter) item.id: item,
        };
        final resumesToUpload = resumesToConsider.where((resume) {
          final cloud = cloudById[resume.id];
          return cloud == null || !cloud.updatedAt.isAfter(resume.updatedAt);
        }).toList();
        if (resumesToUpload.isEmpty) {
          continue;
        }

        final uploadedIds = await service.uploadResumes(resumesToUpload);
        if (uploadedIds.isEmpty) {
          continue;
        }

        final syncedAt = DateTime.now();
        for (final resume in resumesToUpload) {
          if (!uploadedIds.contains(resume.id)) {
            continue;
          }
          await upsertResume(
            resume.copyWith(lastSyncedAt: syncedAt),
            scheduleAutoSync: false,
          );
        }
      }

      while (_pendingGoogleDriveCoverLetterIds.isNotEmpty) {
        if (!appPreferences.googleDriveAutoSyncEnabled ||
            !_canUseGoogleDriveBackup) {
          _pendingGoogleDriveCoverLetterIds.clear();
          _pendingGoogleDriveResumeIds.clear();
          return;
        }

        final pendingLetterIds =
            Set<String>.from(_pendingGoogleDriveCoverLetterIds);
        _pendingGoogleDriveCoverLetterIds.clear();

        if (!await service.hasAuthorizedSession()) {
          return;
        }

        final localLetters = await loadCoverLetters();
        final lettersToConsider = localLetters
            .where((letter) => pendingLetterIds.contains(letter.id))
            .toList();
        if (lettersToConsider.isEmpty) {
          continue;
        }

        final cloudLettersById = {
          for (final item in await service.listResumes())
            if (item.isCoverLetter) item.id: item,
        };
        final lettersToUpload = lettersToConsider.where((letter) {
          final cloud = cloudLettersById[letter.id];
          return cloud == null || !cloud.updatedAt.isAfter(letter.updatedAt);
        }).toList();
        if (lettersToUpload.isEmpty) {
          continue;
        }

        final uploadedLetterIds = await service.uploadCoverLetters(
          lettersToUpload,
        );
        if (uploadedLetterIds.isEmpty) {
          continue;
        }

        final letterSyncedAt = DateTime.now();
        for (final letter in lettersToUpload) {
          if (!uploadedLetterIds.contains(letter.id)) {
            continue;
          }
          await upsertCoverLetter(
            letter.copyWith(lastSyncedAt: letterSyncedAt),
            scheduleAutoSync: false,
          );
        }
      }
    } catch (_) {
      // Keep local writes resilient; Drive sync failures should not break saves.
    } finally {
      _isFlushingGoogleDriveAutoSync = false;
    }
  }

  Future<List<CoverLetterData>> loadCoverLetters() async {
    final items =
        _coverLetterBox.values
            .whereType<Map>()
            .map(
              (item) =>
                  CoverLetterData.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> upsertCoverLetter(
    CoverLetterData coverLetter, {
    bool scheduleAutoSync = true,
  }) async {
    await _coverLetterBox.put(coverLetter.id, coverLetter.toJson());
    if (scheduleAutoSync) {
      _scheduleICloudAutoSyncCoverLetter(coverLetter.id);
      _scheduleGoogleDriveAutoSyncCoverLetter(coverLetter.id);
    }
  }

  Future<void> deleteCoverLetter(String id) async {
    await _coverLetterBox.delete(id);
  }
}

class ResumeImprovementResult {
  const ResumeImprovementResult({
    required this.resume,
    required this.appliedChanges,
  });

  final ResumeData resume;
  final List<String> appliedChanges;
}

class LocalAiResumeService {
  Future<String> generateSummary(
    ResumeData resume, {
    bool regenerate = false,
    int attemptIndex = 0,
  }) async {
    return _simulate(
      () => _buildSummary(
        resume,
        regenerate: regenerate,
        attemptIndex: attemptIndex,
      ),
    );
  }

  Future<List<String>> generateJobBullets({
    required String role,
    required String company,
    required String targetJobTitle,
  }) async {
    return _simulate(
      () => _buildJobBullets(
        role: role,
        company: company,
        targetJobTitle: targetJobTitle,
      ),
    );
  }

  Future<List<String>> suggestSkills({
    required ResumeData resume,
    String? targetJobTitle,
  }) async {
    return _simulate(
      () => _resumeSkillSuggestions(
        resume: resume,
        targetJobTitle: targetJobTitle,
      ),
    );
  }

  Future<List<String>> improveResume(ResumeData resume) async {
    return _simulate(() {
      final analysis = _buildAnalysis(resume: resume, jobDescription: '');
      final tips = <String>[
        ...analysis.improvements,
        if (resume.summary.trim().isEmpty)
          'Add a 2-3 sentence summary so recruiters understand your value immediately.',
        if (resume.visibleProjects.isEmpty)
          'Include at least one project with a measurable outcome to increase credibility.',
      ];

      return tips.toSet().take(6).toList();
    });
  }

  Future<ResumeAnalysis> analyzeResume({
    required ResumeData resume,
    String jobDescription = '',
  }) async {
    return _simulate(
      () => _buildAnalysis(resume: resume, jobDescription: jobDescription),
    );
  }

  Future<ResumeAnalysis> analyzeResumeText({
    required String resumeText,
    String jobDescription = '',
  }) async {
    return _simulate(
      () => _buildTextAnalysis(
        resumeText: resumeText,
        jobDescription: jobDescription,
      ),
    );
  }

  Future<List<String>> generateProofGapPrompts({
    required String resumeText,
    String jobDescription = '',
  }) async {
    return _simulate(
      () => _buildProofGapPrompts(
        resumeText: resumeText,
        jobDescription: jobDescription,
      ),
    );
  }

  ResumeData parseImportedResumeText({
    required String resumeText,
    required ResumeTemplate template,
    String sourceTitle = '',
    List<String> candidateResumeTexts = const [],
  }) {
    final normalizedCandidates = <String>[];
    final seen = <String>{};

    for (final candidate in [resumeText, ...candidateResumeTexts]) {
      final normalized = candidate.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final dedupeKey = normalized
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();
      if (seen.add(dedupeKey)) {
        normalizedCandidates.add(normalized);
      }
    }

    ResumeData? bestResume;
    var bestScore = -1;
    for (final candidate in normalizedCandidates) {
      final parsed = _buildResumeFromImportedText(
        resumeText: candidate,
        template: template,
        sourceTitle: sourceTitle,
      );
      final score = _scoreImportedResumeParse(parsed, candidate);
      if (score > bestScore) {
        bestScore = score;
        bestResume = parsed;
      }
    }

    return bestResume ??
        _buildResumeFromImportedText(
          resumeText: resumeText,
          template: template,
          sourceTitle: sourceTitle,
        );
  }

  Future<ResumeImprovementResult> improveResumeForAts({
    required ResumeData resume,
    String jobDescription = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final normalizedSummary = resume.summary.trim();
    final normalizedJobDescription = jobDescription.trim();
    final currentSkills = resume.skills.toSet();
    final targetJobTitle = resume.jobTitle.trim().isEmpty
        ? resume.title
        : resume.jobTitle;
    final analysis = _buildAnalysis(
      resume: resume,
      jobDescription: normalizedJobDescription,
    );
    final missingKeywords = analysis.missingSkills;
    final targetKeywords = normalizedJobDescription.isEmpty
        ? _prepareTargetKeywords(
            _extractKeywords(normalizedJobDescription),
          ).take(6).toList()
        : _atsKeywordsFromJobDescription(
            jobDescription: normalizedJobDescription,
            missingFromResume: missingKeywords,
          );
    final appliedChanges = <String>[];

    var optimizedJobTitle = resume.jobTitle;
    if (normalizedJobDescription.isNotEmpty) {
      final jobTitleFromPosting = _jobTitleFromJobDescription(
        normalizedJobDescription,
      );
      if (jobTitleFromPosting != null &&
          (resume.jobTitle.trim().isEmpty ||
              resume.jobTitle.trim().length < 4)) {
        optimizedJobTitle = jobTitleFromPosting;
        appliedChanges.add(
          'Aligned the job title with the pasted job description for ATS matching.',
        );
      }
    }

    var updatedSummary = normalizedSummary;
    if (normalizedJobDescription.isNotEmpty) {
      updatedSummary = _buildTailoredSummary(
        resume: resume,
        targetJobTitle: optimizedJobTitle.trim().isEmpty
            ? targetJobTitle
            : optimizedJobTitle,
        keywords: targetKeywords,
        jobDescription: normalizedJobDescription,
      );
      appliedChanges.add(
        'Tailored the summary to match the pasted job description more directly.',
      );
    } else if (updatedSummary.length < 90) {
      updatedSummary = _buildSummary(resume);
      if (missingKeywords.isNotEmpty) {
        updatedSummary =
            '$updatedSummary Focused on ${missingKeywords.take(2).join(' and ')}.';
      }
      appliedChanges.add(
        'Refreshed the summary to be stronger and more ATS-friendly.',
      );
    }

    final suggestedSkills = {
      ..._resumeSkillSuggestions(
        resume: resume,
        targetJobTitle: optimizedJobTitle.trim().isEmpty
            ? targetJobTitle
            : optimizedJobTitle,
      ),
      if (normalizedJobDescription.isEmpty) ...missingKeywords.take(4),
      if (normalizedJobDescription.isNotEmpty) ...targetKeywords.take(8),
    };
    final mergedSkills = [...currentSkills, ...suggestedSkills]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final cappedSkills = _orderSkillsForAts(
      skills: mergedSkills.take(50).toList(),
      priorityKeywords: targetKeywords,
    );
    final addedAtsSkills = cappedSkills.where(
      (skill) => !resume.skills.any(
        (existing) => existing.toLowerCase() == skill.toLowerCase(),
      ),
    );
    if (addedAtsSkills.isNotEmpty) {
      appliedChanges.add(
        'Added relevant skills and missing keywords from the target role.',
      );
    }

    var workChanged = false;
    int? primaryWorkIndex;
    for (var i = 0; i < resume.workExperiences.length; i++) {
      if (!resume.workExperiences[i].isBlank) {
        primaryWorkIndex = i;
        break;
      }
    }

    final updatedWork = resume.workExperiences.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final nonEmptyBullets = item.bullets
          .map((bullet) => bullet.trim())
          .where((bullet) => bullet.isNotEmpty)
          .toList();
      final hasWeakBullets =
          nonEmptyBullets.where((bullet) => bullet.length > 45).length < 2;
      final needsBulletSupport =
          !item.isBlank &&
          (nonEmptyBullets.isEmpty ||
              hasWeakBullets ||
              (item.description.trim().isNotEmpty &&
                  nonEmptyBullets.length < 2));
      if (!needsBulletSupport) {
        if (normalizedJobDescription.isEmpty || item.isBlank) {
          return item;
        }
        final roleKeywords = _keywordsForWorkEntry(
          entryIndex: index,
          primaryIndex: primaryWorkIndex,
          allKeywords: targetKeywords,
        );
        final polished = nonEmptyBullets
            .map(
              (bullet) => _polishBulletForAts(bullet, keywords: roleKeywords),
            )
            .take(4)
            .toList();
        if (_unorderedListEquals(nonEmptyBullets, polished)) {
          return item;
        }
        workChanged = true;
        return item.copyWith(bullets: polished);
      }

      final improvedBullets = _tailorWorkExperienceBullets(
        item: item,
        targetJobTitle: optimizedJobTitle.trim().isEmpty
            ? targetJobTitle
            : optimizedJobTitle,
        keywords: _keywordsForWorkEntry(
          entryIndex: index,
          primaryIndex: primaryWorkIndex,
          allKeywords: targetKeywords,
        ),
        weaveJobKeywords: normalizedJobDescription.isNotEmpty,
      );
      if (_unorderedListEquals(nonEmptyBullets, improvedBullets)) {
        return item;
      }
      workChanged = true;
      return item.copyWith(bullets: improvedBullets);
    }).toList();
    if (workChanged) {
      appliedChanges.add(
        normalizedJobDescription.isNotEmpty
            ? 'Rewrote work experience bullets to reflect the target job description more directly.'
            : 'Strengthened work experience bullets with clearer action language.',
      );
    }

    if (appliedChanges.isEmpty) {
      appliedChanges.add(
        'Your selected resume was already strong, so no direct ATS fixes were needed.',
      );
    }

    return ResumeImprovementResult(
      resume: resume.copyWith(
        jobTitle: optimizedJobTitle,
        summary: updatedSummary,
        skills: cappedSkills,
        workExperiences: updatedWork,
        updatedAt: DateTime.now(),
      ),
      appliedChanges: appliedChanges,
    );
  }

  Future<String> generateCoverLetter({
    required ResumeData resume,
    required String company,
    required String role,
    String skillToHighlight = '',
    String language = '',
    bool regenerate = false,
    int attemptIndex = 0,
  }) async {
    return _simulate(
      () => _buildCoverLetter(
        resume: resume,
        company: company,
        role: role,
        skillToHighlight: skillToHighlight,
        language: language,
        variantIndex: regenerate ? attemptIndex : 0,
      ),
    );
  }

  static const int _coverLetterVariantCount = 6;

  String _buildCoverLetter({
    required ResumeData resume,
    required String company,
    required String role,
    required String skillToHighlight,
    required String language,
    required int variantIndex,
  }) {
    final inputs = _coverLetterInputsFromResume(
      resume: resume,
      company: company,
      role: role,
      skillToHighlight: skillToHighlight,
      language: language,
    );
    final variant = variantIndex % _coverLetterVariantCount;
    final languageBase = inputs.languageBase.isEmpty
        ? 'English'
        : inputs.languageBase;
    final locale = _coverLetterLocaleFor(languageBase);
    final letterhead = _formatCoverLetterLetterhead(inputs, locale);
    final body = languageBase == 'English'
        ? _composeEnglishCoverLetterBody(inputs, locale, variant)
        : _composeLocalizedCoverLetterBody(inputs, locale, variant);

    return '$letterhead$body';
  }

  String _formatCoverLetterLetterhead(
    _CoverLetterInputs inputs,
    _CoverLetterLocale locale,
  ) {
    final currentDate = _formatCoverLetterDate(
      DateTime.now(),
      languageBase: inputs.languageBase.isEmpty
          ? 'English'
          : inputs.languageBase,
    );

    return '${inputs.senderName}\n'
        '${inputs.addressLine}\n'
        '${inputs.cityLine}\n'
        '${inputs.emailLine}\n'
        '${inputs.phoneLine}\n'
        '$currentDate\n\n'
        '${locale.hiringManager}\n'
        '${inputs.companyName}\n'
        '[Company Address]\n'
        '[City, State, Zip Code]\n\n';
  }

  String _composeEnglishCoverLetterBody(
    _CoverLetterInputs inputs,
    _CoverLetterLocale locale,
    int variant,
  ) {
    final greeting = _englishCoverLetterGreeting(inputs, variant);
    final opening = _englishCoverLetterOpening(inputs, variant);
    final fit = _englishCoverLetterFit(inputs, variant);
    final strengths = _englishCoverLetterStrengths(inputs, locale, variant);
    final closing = _englishCoverLetterClosing(inputs, variant);

    return '$greeting\n\n'
        '$opening\n\n'
        '$fit\n\n'
        '$strengths\n\n'
        '$closing\n\n'
        '${locale.sincerely}\n\n'
        '${inputs.senderName}';
  }

  String _composeLocalizedCoverLetterBody(
    _CoverLetterInputs inputs,
    _CoverLetterLocale locale,
    int variant,
  ) {
    final greeting = _localizedCoverLetterGreeting(inputs, locale, variant);
    final opening = locale.opening(inputs.roleName, inputs.companyName);
    final evidence = inputs.experienceEvidenceLine(variant);
    final fitBase = locale.fit(inputs.roleName, inputs.primarySkill);
    final fit = evidence.isEmpty ? fitBase : '$fitBase $evidence';
    final languageSentence = inputs.language.trim().isEmpty
        ? ''
        : locale.languageSentence(inputs.languageNative);
    final strengths = locale.strengths(languageSentence);
    final closing = locale.closing(inputs.companyName, inputs.roleName);

    return '$greeting\n\n'
        '$opening\n\n'
        '$fit\n\n'
        '$strengths\n\n'
        '$closing\n\n'
        '${locale.sincerely}\n\n'
        '${inputs.senderName}';
  }

  String _englishCoverLetterGreeting(_CoverLetterInputs inputs, int variant) {
    return switch (variant % 3) {
      0 => 'Dear Hiring Manager,',
      1 => 'Dear ${inputs.companyName} team,',
      _ => 'Hello,',
    };
  }

  String _localizedCoverLetterGreeting(
    _CoverLetterInputs inputs,
    _CoverLetterLocale locale,
    int variant,
  ) {
    if (variant % 3 != 1) {
      return locale.greeting;
    }
    return _coverLetterGreetingForCompany(
      inputs.languageBase.isEmpty ? 'English' : inputs.languageBase,
      inputs.companyName,
    );
  }

  String _coverLetterGreetingForCompany(String languageBase, String company) {
    return switch (languageBase) {
      'Arabic' => 'فريق $company المحترم،',
      'Bengali' => 'প্রিয় $company টিম,',
      'Chinese, Mandarin' => '尊敬的$company团队：',
      'Dutch' => 'Geacht team van $company,',
      'French' => 'Bonjour l’équipe $company,',
      'German' => 'Guten Tag Team $company,',
      'Hindi' => 'प्रिय $company टीम,',
      'Italian' => 'Gentile team di $company,',
      'Japanese' => '$company 採用チームの皆様',
      'Korean' => '$company 채용팀께,',
      'Portuguese' => 'Prezada equipe da $company,',
      'Russian' => 'Уважаемая команда $company,',
      'Spanish' => 'Estimado equipo de $company:',
      'Turkish' => 'Sayın $company ekibi,',
      'Urdu' => 'محترم $company ٹیم،',
      'Vietnamese' => 'Kính gửi đội ngũ $company,',
      _ => 'Dear $company team,',
    };
  }

  String _englishCoverLetterOpening(_CoverLetterInputs inputs, int variant) {
    final role = inputs.roleName;
    final company = inputs.companyName;
    return switch (variant % _coverLetterVariantCount) {
      0 =>
        'I am writing to apply for the $role position at $company. The role stood out to me because it lines up with the kind of work I have been doing and the impact I want to make next.',
      1 =>
        'When I saw the opening for $role at $company, it immediately caught my attention. The position sounds like a strong match for how I work: focused, collaborative, and oriented toward practical results.',
      2 =>
        'I would like to be considered for the $role role at $company. From what I understand about the team and the scope of the work, this is an opportunity where I could contribute quickly while continuing to grow.',
      3 =>
        'I am excited to apply for $role at $company. My recent work has centered on ${inputs.backgroundRole}, and this position feels like a natural next step.',
      4 =>
        'I am reaching out about the $role opportunity at $company. I admire teams that value clear communication and steady execution, and that is the environment where I do my best work.',
      _ =>
        'Please accept my application for the $role position at $company. I am motivated by roles where thoughtful planning and follow-through matter as much as the initial idea.',
    };
  }

  String _englishCoverLetterFit(_CoverLetterInputs inputs, int variant) {
    final role = inputs.roleName;
    final skills = inputs.primarySkill;
    final evidence = inputs.experienceEvidenceLine(variant);
    final background = inputs.backgroundRole;

    final evidenceSuffix = evidence.isEmpty ? '' : ' $evidence';

    return switch (variant % _coverLetterVariantCount) {
      0 =>
        'In my work as $background, I have built depth in $skills and learned how to translate that into outcomes stakeholders can see. I am confident I can bring the same approach to $role at ${inputs.companyName}.$evidenceSuffix',
      1 =>
        'What I would bring to $role is a grounded mix of $skills, good judgment under pressure, and the habit of checking that the work actually solves the problem. That combination has served me well in $background roles.$evidenceSuffix',
      2 =>
        'I believe I am a strong fit for $role because I can connect day-to-day execution with the bigger picture. My strengths in $skills are backed by hands-on experience, not just resume keywords.$evidenceSuffix',
      3 =>
        'The $role position aligns with how I already work: scoped goals, steady communication, and attention to $skills where they matter most. I am used to partnering across functions and closing loops without a lot of overhead.$evidenceSuffix',
      4 =>
        'Hiring for $role often comes down to whether someone can learn the context quickly and deliver without drama. That is where I am most effective, especially when $skills are central to the work.$evidenceSuffix',
      _ =>
        'I am not looking for a generic next job; I am looking for a place where $skills and reliable delivery are valued. $role at ${inputs.companyName} looks like that kind of opportunity, and my background in $background supports that read.$evidenceSuffix',
    };
  }

  String _englishCoverLetterStrengths(
    _CoverLetterInputs inputs,
    _CoverLetterLocale locale,
    int variant,
  ) {
    final languageSentence = inputs.language.trim().isEmpty
        ? ''
        : locale.languageSentence(inputs.languageNative);
    final summaryHook = inputs.summaryHook;

    return switch (variant % 3) {
      0 =>
        'Colleagues tend to describe me as organized, direct, and easy to work with when priorities shift. I take ownership of my piece of the work and keep updates clear so nothing falls through the cracks.$languageSentence',
      1 =>
        'I communicate early when tradeoffs appear, document decisions that others will need later, and keep quality high even when timelines are tight. Those habits matter in collaborative environments.$languageSentence',
      _ =>
        summaryHook.isEmpty
            ? 'I stay calm when plans change, break work into realistic steps, and make sure the final output is something the team can stand behind.$languageSentence'
            : '$summaryHook$languageSentence',
    };
  }

  String _englishCoverLetterClosing(_CoverLetterInputs inputs, int variant) {
    final company = inputs.companyName;
    final role = inputs.roleName;

    return switch (variant % _coverLetterVariantCount) {
      0 =>
        'I would welcome the chance to discuss how I can support $company as $role. Thank you for your time and consideration.',
      1 =>
        'If my background looks like a fit, I would appreciate the opportunity to talk further about the $role role and how I can help the team. Thank you for reviewing my application.',
      2 =>
        'I am available to speak at your convenience and happy to share more detail on relevant projects. Thank you for considering me for $role at $company.',
      3 =>
        'I would be glad to walk through examples of my work and how they relate to your needs for $role. Thanks again for your consideration.',
      4 =>
        'I hope we can connect soon about $role. I am enthusiastic about the possibility of contributing to $company.',
      _ =>
        'Thank you for reading my application. I look forward to the possibility of joining $company as $role and learning more about your goals for the team.',
    };
  }

  String _formatCoverLetterDate(DateTime date, {required String languageBase}) {
    if (languageBase != 'English') {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    }
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _joinNaturalListLocalized(List<String> items, String languageBase) {
    final cleaned = items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      return '';
    }
    if (cleaned.length == 1) {
      return cleaned.first;
    }
    final conjunction = switch (languageBase) {
      'Arabic' => 'و',
      'Bengali' => 'এবং',
      'Chinese, Mandarin' => '和',
      'Dutch' => 'en',
      'French' => 'et',
      'German' => 'und',
      'Hindi' => 'और',
      'Italian' => 'e',
      'Japanese' => 'と',
      'Korean' => '및',
      'Portuguese' => 'e',
      'Russian' => 'и',
      'Spanish' => 'y',
      'Turkish' => 've',
      'Urdu' => 'اور',
      'Vietnamese' => 'và',
      _ => 'and',
    };
    if (cleaned.length == 2) {
      return '${cleaned.first} $conjunction ${cleaned.last}';
    }
    return '${cleaned.sublist(0, cleaned.length - 1).join(', ')}, $conjunction ${cleaned.last}';
  }

  String _coverLetterLanguageName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    final bracketIndex = trimmed.indexOf(' (');
    if (bracketIndex <= 0) {
      return trimmed;
    }
    return trimmed.substring(0, bracketIndex).trim();
  }

  String _coverLetterLanguageNativeName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    final start = trimmed.indexOf('(');
    final end = trimmed.lastIndexOf(')');
    if (start >= 0 && end > start) {
      return trimmed.substring(start + 1, end).trim();
    }
    return _coverLetterLanguageName(trimmed);
  }

  _CoverLetterLocale _coverLetterLocaleFor(String languageBase) {
    return switch (languageBase) {
      'Arabic' => _CoverLetterLocale(
        hiringManager: 'مدير التوظيف',
        greeting: 'السيد/السيدة مدير التوظيف المحترم/ة،',
        opening: (role, company) =>
            'أكتب للتعبير عن اهتمامي بمنصب $role في $company. تجذبني هذه الفرصة لأنها تبدو قائمة على المهنية والموثوقية والقدرة على تقديم قيمة حقيقية منذ اليوم الأول.',
        fit: (role, skill) =>
            'أعتقد أنني سأكون مناسبًا/مناسبة لهذا المنصب لأنني أستطيع تقديم تركيز قوي على $skill، إلى جانب الاستعداد للتعلم بسرعة والتكيف مع احتياجات الفريق والحفاظ على جودة العمل بشكل مستمر.',
        strengths: (languageSentence) =>
            'سأقدم إلى هذا الدور مهارات قوية في التواصل والتنظيم وحل المشكلات، وسأتعامل مع مسؤولياته بعناية ومسؤولية واهتمام بالتفاصيل.$languageSentence',
        closing: (company, role) =>
            'سأرحب بفرصة المساهمة في $company بصفتي $role. شكرًا لكم على النظر في طلبي، وأتطلع إلى فرصة مناقشة كيفية دعمي لفريقكم.',
        sincerely: 'مع خالص التقدير،',
        languageSentence: (language) =>
            ' كما أنني أستطيع التواصل بفاعلية باللغة $language، مما يساعدني على التعاون بوضوح في هذا الدور.',
      ),
      'Bengali' => _CoverLetterLocale(
        hiringManager: 'নিয়োগ ব্যবস্থাপক',
        greeting: 'সম্মানিত নিয়োগ ব্যবস্থাপক,',
        opening: (role, company) =>
            'আমি $company-এ $role পদের প্রতি আমার আগ্রহ প্রকাশ করতে লিখছি। এই সুযোগটি আমাকে আকর্ষণ করছে, কারণ এখানে পেশাদারিত্ব, নির্ভরযোগ্যতা এবং প্রথম দিন থেকেই অর্থপূর্ণ অবদানকে গুরুত্ব দেওয়া হয় বলে মনে হচ্ছে।',
        fit: (role, skill) =>
            'আমি বিশ্বাস করি এই পদে আমি ভালোভাবে মানিয়ে নিতে পারব, কারণ আমি $skill-এ একটি কেন্দ্রীভূত দৃষ্টিভঙ্গি, দ্রুত শেখার মানসিকতা এবং দলের প্রয়োজন অনুযায়ী নিজেকে মানিয়ে নেওয়ার সক্ষমতা নিয়ে আসতে পারি।',
        strengths: (languageSentence) =>
            'আমি এই ভূমিকায় শক্তিশালী যোগাযোগ, সংগঠন এবং সমস্যা সমাধানের দক্ষতা নিয়ে আসব এবং দায়িত্বগুলি যত্ন, জবাবদিহি এবং সূক্ষ্ম বিষয়ে মনোযোগ দিয়ে পালন করব।$languageSentence',
        closing: (company, role) =>
            '$company-এ $role হিসেবে অবদান রাখার সুযোগ পেলে আমি আনন্দিত হব। আমার আবেদন বিবেচনা করার জন্য ধন্যবাদ। আমি আপনার দলের সহায়তায় কীভাবে কাজ করতে পারি, তা নিয়ে আলোচনার সুযোগের অপেক্ষায় থাকব।',
        sincerely: 'শুভেচ্ছান্তে,',
        languageSentence: (language) =>
            ' আমি $language ভাষাতেও কার্যকরভাবে যোগাযোগ করতে পারি, যা এই ভূমিকায় স্পষ্টভাবে সহযোগিতা করতে সহায়তা করবে।',
      ),
      'Chinese, Mandarin' => _CoverLetterLocale(
        hiringManager: '招聘经理',
        greeting: '尊敬的招聘经理：',
        opening: (role, company) =>
            '您好！我写信是想表达我对 $company 的 $role 职位的浓厚兴趣。这个机会吸引我的原因在于，它看起来非常重视专业性、可靠性以及从第一天起就能带来实际贡献的能力。',
        fit: (role, skill) =>
            '我相信自己能够胜任这一职位，因为我能够在 $skill 方面投入专注，同时也愿意快速学习、适应团队需求，并持续保持高质量的工作标准。',
        strengths: (languageSentence) =>
            '我能够为这一岗位带来良好的沟通能力、组织能力和解决问题的能力，并会以认真、负责和注重细节的方式承担相关职责。$languageSentence',
        closing: (company, role) =>
            '如果有机会以 $role 的身份为 $company 做出贡献，我将十分荣幸。感谢您考虑我的申请，期待有机会进一步交流我如何支持贵团队。',
        sincerely: '此致，敬礼',
        languageSentence: (language) =>
            ' 此外，我也能够使用$language进行有效沟通，这将有助于我在这一岗位中更清晰地协作。',
      ),
      'Dutch' => _CoverLetterLocale(
        hiringManager: 'Recruitmentmanager',
        greeting: 'Geachte recruitmentmanager,',
        opening: (role, company) =>
            'Met deze brief wil ik mijn interesse kenbaar maken voor de functie van $role bij $company. Deze kans spreekt mij aan omdat zij professionaliteit, betrouwbaarheid en de mogelijkheid om vanaf dag één betekenisvol bij te dragen lijkt te waarderen.',
        fit: (role, skill) =>
            'Ik geloof dat ik goed bij deze functie pas, omdat ik een gerichte aanpak op het gebied van $skill meebreng, samen met de bereidheid om snel te leren, mij aan te passen aan de behoeften van het team en consequent werk van hoge kwaliteit te leveren.',
        strengths: (languageSentence) =>
            'Ik zou sterke communicatieve, organisatorische en probleemoplossende vaardigheden in deze rol meebrengen en de verantwoordelijkheden met zorg, verantwoordelijkheid en oog voor detail oppakken.$languageSentence',
        closing: (company, role) =>
            'Ik zou de kans verwelkomen om als $role bij te dragen aan $company. Dank u voor uw overweging. Ik kijk uit naar de mogelijkheid om te bespreken hoe ik uw team kan ondersteunen.',
        sincerely: 'Met vriendelijke groet,',
        languageSentence: (language) =>
            ' Ik kan ook effectief communiceren in het $language, wat mij zou helpen om in deze rol helder samen te werken.',
      ),
      'French' => _CoverLetterLocale(
        hiringManager: 'Responsable du recrutement',
        greeting: 'Madame, Monsieur,',
        opening: (role, company) =>
            'Je vous écris afin d’exprimer mon intérêt pour le poste de $role chez $company. Cette opportunité m’intéresse, car elle semble valoriser le professionnalisme, la fiabilité et la capacité à contribuer de manière concrète dès le premier jour.',
        fit: (role, skill) =>
            'Je pense pouvoir être un bon profil pour ce poste, car j’apporte une approche solide en $skill, ainsi qu’une grande capacité d’apprentissage, d’adaptation aux besoins de l’équipe et de maintien d’un travail de qualité constante.',
        strengths: (languageSentence) =>
            'J’apporterais à ce poste de solides compétences en communication, en organisation et en résolution de problèmes, tout en assumant les responsabilités avec rigueur, sens des responsabilités et attention aux détails.$languageSentence',
        closing: (company, role) =>
            'Je serais ravi(e) d’avoir l’opportunité de contribuer à $company en tant que $role. Merci de l’attention portée à ma candidature. Je serais heureux/heureuse d’échanger sur la manière dont je pourrais soutenir votre équipe.',
        sincerely: 'Cordialement,',
        languageSentence: (language) =>
            ' Je peux également communiquer efficacement en $language, ce qui m’aiderait à collaborer avec clarté dans ce poste.',
      ),
      'German' => _CoverLetterLocale(
        hiringManager: 'Personalverantwortliche/r',
        greeting: 'Sehr geehrte Damen und Herren,',
        opening: (role, company) =>
            'hiermit möchte ich mein Interesse an der Position $role bei $company zum Ausdruck bringen. Diese Gelegenheit spricht mich an, weil sie Professionalität, Zuverlässigkeit und die Fähigkeit zu einem wertvollen Beitrag vom ersten Tag an zu schätzen scheint.',
        fit: (role, skill) =>
            'Ich bin überzeugt, dass ich gut zu dieser Position passe, da ich einen klaren Schwerpunkt auf $skill mitbringe und zugleich bereit bin, schnell zu lernen, mich an die Bedürfnisse des Teams anzupassen und konstant hochwertige Arbeit zu leisten.',
        strengths: (languageSentence) =>
            'Ich würde starke Kommunikations-, Organisations- und Problemlösungskompetenzen in diese Rolle einbringen und die Aufgaben mit Sorgfalt, Verantwortungsbewusstsein und Liebe zum Detail übernehmen.$languageSentence',
        closing: (company, role) =>
            'Ich würde mich über die Gelegenheit freuen, als $role zu $company beizutragen. Vielen Dank für die Berücksichtigung meiner Bewerbung. Ich freue mich auf die Möglichkeit, zu besprechen, wie ich Ihr Team unterstützen kann.',
        sincerely: 'Mit freundlichen Grüßen',
        languageSentence: (language) =>
            ' Ich kann zudem effektiv auf $language kommunizieren, was mir helfen würde, in dieser Rolle klar zusammenzuarbeiten.',
      ),
      'Hindi' => _CoverLetterLocale(
        hiringManager: 'भर्ती प्रबंधक',
        greeting: 'आदरणीय भर्ती प्रबंधक,',
        opening: (role, company) =>
            'मैं $company में $role पद के लिए अपनी रुचि व्यक्त करने हेतु यह पत्र लिख रहा/रही हूँ। यह अवसर मुझे इसलिए आकर्षित करता है क्योंकि यहाँ पेशेवरता, विश्वसनीयता और पहले दिन से सार्थक योगदान देने की क्षमता को महत्व दिया जाता है।',
        fit: (role, skill) =>
            'मुझे विश्वास है कि मैं इस भूमिका के लिए उपयुक्त रहूँगा/रहूँगी, क्योंकि मैं $skill पर केंद्रित दृष्टिकोण, तेज़ी से सीखने की इच्छा, टीम की ज़रूरतों के अनुसार स्वयं को ढालने की क्षमता और लगातार उच्च गुणवत्ता वाला काम करने की प्रतिबद्धता लेकर आ सकता/सकती हूँ।',
        strengths: (languageSentence) =>
            'मैं इस भूमिका में मजबूत संचार, संगठन और समस्या-समाधान कौशल लाऊँगा/लाऊँगी तथा जिम्मेदारियों को सावधानी, जवाबदेही और सूक्ष्म विवरणों पर ध्यान के साथ निभाऊँगा/निभाऊँगी।$languageSentence',
        closing: (company, role) =>
            '$company में $role के रूप में योगदान देने का अवसर मिलना मेरे लिए प्रसन्नता की बात होगी। मेरे आवेदन पर विचार करने के लिए धन्यवाद। आपके दल का मैं किस प्रकार सहयोग कर सकता/सकती हूँ, इस पर आगे चर्चा का अवसर मिलने की प्रतीक्षा रहेगी।',
        sincerely: 'सादर,',
        languageSentence: (language) =>
            ' मैं $language में भी प्रभावी रूप से संवाद कर सकता/सकती हूँ, जिससे इस भूमिका में स्पष्ट सहयोग करने में सहायता मिलेगी।',
      ),
      'Italian' => _CoverLetterLocale(
        hiringManager: 'Responsabile delle assunzioni',
        greeting: 'Gentile Responsabile delle assunzioni,',
        opening: (role, company) =>
            'Le scrivo per esprimere il mio interesse per il ruolo di $role presso $company. Questa opportunità mi interessa perché sembra valorizzare professionalità, affidabilità e la capacità di contribuire in modo concreto fin dal primo giorno.',
        fit: (role, skill) =>
            'Ritengo di poter essere adatto/a a questo ruolo perché posso offrire un approccio solido a $skill, insieme alla disponibilità ad apprendere rapidamente, adattarmi alle esigenze del team e mantenere uno standard di lavoro costantemente elevato.',
        strengths: (languageSentence) =>
            'Porterei nel ruolo solide capacità di comunicazione, organizzazione e risoluzione dei problemi, affrontando le responsabilità con cura, senso di responsabilità e attenzione ai dettagli.$languageSentence',
        closing: (company, role) =>
            'Accoglierei con piacere l’opportunità di contribuire a $company come $role. La ringrazio per l’attenzione alla mia candidatura. Sarei lieto/a di discutere come potrei supportare il vostro team.',
        sincerely: 'Cordiali saluti,',
        languageSentence: (language) =>
            ' Posso inoltre comunicare efficacemente in $language, il che mi aiuterebbe a collaborare con chiarezza in questo ruolo.',
      ),
      'Japanese' => _CoverLetterLocale(
        hiringManager: '採用ご担当者様',
        greeting: '採用ご担当者様',
        opening: (role, company) =>
            '$company の $role 職に応募したく、ご連絡いたしました。この機会に関心を持ったのは、貴社が専門性、信頼性、そして初日から価値を発揮できる力を重視していると感じたためです。',
        fit: (role, skill) =>
            '私は、この職務に適していると考えております。$skill にしっかりと取り組む姿勢に加え、素早く学び、チームのニーズに柔軟に対応し、安定して高品質な仕事を進めることができるためです。',
        strengths: (languageSentence) =>
            'この役割において、私は高いコミュニケーション力、整理力、問題解決力を発揮し、責任感と細部への配慮を持って業務に取り組みます。$languageSentence',
        closing: (company, role) =>
            '$company において $role として貢献できる機会をいただければ幸いです。ご検討いただきありがとうございます。どのように御社のチームを支援できるか、さらにお話しできる機会を楽しみにしております。',
        sincerely: '何卒よろしくお願いいたします。',
        languageSentence: (language) =>
            ' また、$language による円滑なコミュニケーションも可能であり、この役割で明確に連携するうえで役立ちます。',
      ),
      'Korean' => _CoverLetterLocale(
        hiringManager: '채용 담당자',
        greeting: '채용 담당자님께,',
        opening: (role, company) =>
            '$company의 $role 직무에 지원하고자 이렇게 글을 드립니다. 이 기회가 첫날부터 의미 있는 기여를 할 수 있는 전문성, 신뢰성, 책임감을 중요하게 여기는 역할로 보여 큰 관심을 갖게 되었습니다.',
        fit: (role, skill) =>
            '저는 $skill에 대한 집중된 접근 방식과 빠른 학습 태도, 팀의 요구에 유연하게 적응하는 능력, 그리고 꾸준히 높은 품질의 결과를 만들어내는 자세를 바탕으로 이 역할에 잘 맞는다고 생각합니다.',
        strengths: (languageSentence) =>
            '저는 이 역할에 강한 커뮤니케이션 능력, 조직력, 문제 해결 능력을 더할 수 있으며, 세심함과 책임감을 가지고 업무를 수행하겠습니다.$languageSentence',
        closing: (company, role) =>
            '$company에서 $role로 기여할 기회를 얻게 된다면 기쁘겠습니다. 제 지원서를 검토해 주셔서 감사합니다. 제가 팀에 어떻게 도움이 될 수 있을지 더 이야기 나눌 기회를 기대합니다.',
        sincerely: '감사합니다.',
        languageSentence: (language) =>
            ' 또한 $language로도 효과적으로 소통할 수 있어 이 역할에서 보다 명확하게 협업할 수 있습니다.',
      ),
      'Portuguese' => _CoverLetterLocale(
        hiringManager: 'Gerente de Contratação',
        greeting: 'Prezado(a) Gerente de Contratação,',
        opening: (role, company) =>
            'Escrevo para expressar meu interesse pela posição de $role na $company. Esta oportunidade me atrai porque parece valorizar profissionalismo, confiabilidade e a capacidade de contribuir de forma significativa desde o primeiro dia.',
        fit: (role, skill) =>
            'Acredito que eu seria uma boa escolha para esta função, pois posso oferecer uma abordagem focada em $skill, aliada à disposição para aprender rapidamente, adaptar-me às necessidades da equipe e manter um trabalho de alta qualidade de forma consistente.',
        strengths: (languageSentence) =>
            'Eu levaria para a função fortes habilidades de comunicação, organização e resolução de problemas, assumindo as responsabilidades com cuidado, responsabilidade e atenção aos detalhes.$languageSentence',
        closing: (company, role) =>
            'Ficaria feliz em ter a oportunidade de contribuir com a $company como $role. Obrigado por considerar minha candidatura. Aguardo a oportunidade de conversar sobre como posso apoiar sua equipe.',
        sincerely: 'Atenciosamente,',
        languageSentence: (language) =>
            ' Também consigo me comunicar de forma eficaz em $language, o que me ajudaria a colaborar com clareza nesta função.',
      ),
      'Russian' => _CoverLetterLocale(
        hiringManager: 'Менеджер по подбору персонала',
        greeting: 'Уважаемый менеджер по подбору персонала,',
        opening: (role, company) =>
            'Я пишу, чтобы выразить свой интерес к позиции $role в компании $company. Эта возможность привлекла меня, поскольку, как мне кажется, она ценит профессионализм, надежность и способность вносить значимый вклад с первого дня.',
        fit: (role, skill) =>
            'Я считаю, что хорошо подхожу для этой роли, потому что могу предложить уверенный подход в области $skill, а также готовность быстро учиться, адаптироваться к потребностям команды и стабильно поддерживать высокое качество работы.',
        strengths: (languageSentence) =>
            'Я привнесу в эту роль сильные навыки коммуникации, организации и решения проблем, а также буду выполнять обязанности внимательно, ответственно и с большим вниманием к деталям.$languageSentence',
        closing: (company, role) =>
            'Я был(а) бы рад(а) возможности внести вклад в $company в роли $role. Спасибо за рассмотрение моей кандидатуры. Буду признателен(льна) за возможность обсудить, как я могу поддержать вашу команду.',
        sincerely: 'С уважением,',
        languageSentence: (language) =>
            ' Я также могу эффективно общаться на $language, что поможет мне ясно взаимодействовать в рамках этой роли.',
      ),
      'Spanish' => _CoverLetterLocale(
        hiringManager: 'Gerente de Contratación',
        greeting: 'Estimado/a Gerente de Contratación:',
        opening: (role, company) =>
            'Le escribo para expresar mi interés en el puesto de $role en $company. Me interesa esta oportunidad porque parece valorar el profesionalismo, la confiabilidad y la capacidad de contribuir de manera significativa desde el primer día.',
        fit: (role, skill) =>
            'Considero que podría encajar bien en este puesto porque puedo aportar un enfoque sólido en $skill, además de la disposición para aprender con rapidez, adaptarme a las necesidades del equipo y mantener un trabajo de alta calidad de manera constante.',
        strengths: (languageSentence) =>
            'Aportaría sólidas habilidades de comunicación, organización y resolución de problemas, y asumiría las responsabilidades de este puesto con cuidado, responsabilidad y atención al detalle.$languageSentence',
        closing: (company, role) =>
            'Me gustaría tener la oportunidad de contribuir a $company como $role. Gracias por considerar mi candidatura. Quedo a su disposición para conversar sobre cómo puedo apoyar a su equipo.',
        sincerely: 'Atentamente,',
        languageSentence: (language) =>
            ' También puedo comunicarme eficazmente en $language, lo que me permitiría colaborar con claridad en este puesto.',
      ),
      'Turkish' => _CoverLetterLocale(
        hiringManager: 'İşe Alım Yöneticisi',
        greeting: 'Sayın İşe Alım Yöneticisi,',
        opening: (role, company) =>
            '$company bünyesindeki $role pozisyonuna olan ilgimi ifade etmek için yazıyorum. Bu fırsatın profesyonellik, güvenilirlik ve ilk günden itibaren anlamlı katkı sunma becerisini önemseyen bir yapıya sahip olması beni özellikle çekiyor.',
        fit: (role, skill) =>
            'Bu rol için güçlü bir aday olduğuma inanıyorum; çünkü $skill konusunda odaklı bir yaklaşım sunabilir, hızlı öğrenebilir, ekibin ihtiyaçlarına uyum sağlayabilir ve sürekli olarak yüksek kaliteli işler ortaya koyabilirim.',
        strengths: (languageSentence) =>
            'Bu role güçlü iletişim, organizasyon ve problem çözme becerileri getirir; sorumlulukları özen, hesap verebilirlik ve ayrıntılara dikkat ile yerine getiririm.$languageSentence',
        closing: (company, role) =>
            '$company bünyesinde $role olarak katkı sunma fırsatını memnuniyetle karşılarım. Başvurumu değerlendirdiğiniz için teşekkür ederim. Ekibinizi nasıl destekleyebileceğimi görüşme fırsatını sabırsızlıkla bekliyorum.',
        sincerely: 'Saygılarımla,',
        languageSentence: (language) =>
            ' Ayrıca $language dilinde de etkili şekilde iletişim kurabiliyorum; bu da bu rolde açık ve net iş birliği yapmama yardımcı olur.',
      ),
      'Urdu' => _CoverLetterLocale(
        hiringManager: 'بھرتی مینیجر',
        greeting: 'محترم بھرتی مینیجر،',
        opening: (role, company) =>
            'میں $company میں $role کے عہدے کے لیے اپنی دلچسپی ظاہر کرنے کے لیے یہ خط لکھ رہا/رہی ہوں۔ یہ موقع مجھے اس لیے پسند آیا کیونکہ اس میں پیشہ ورانہ طرزِ عمل، اعتماد اور پہلے دن سے بامعنی کردار ادا کرنے کی صلاحیت کو اہمیت دی جاتی ہے۔',
        fit: (role, skill) =>
            'مجھے یقین ہے کہ میں اس کردار کے لیے موزوں ہوں، کیونکہ میں $skill پر مضبوط توجہ، جلد سیکھنے کی آمادگی، ٹیم کی ضروریات کے مطابق خود کو ڈھالنے کی صلاحیت اور مسلسل معیاری کام فراہم کرنے کا رجحان رکھتا/رکھتی ہوں۔',
        strengths: (languageSentence) =>
            'میں اس کردار میں مضبوط ابلاغی، تنظیمی اور مسئلہ حل کرنے کی صلاحیتیں لا سکتا/سکتی ہوں اور ذمہ داریوں کو احتیاط، جوابدہی اور باریکیوں پر توجہ کے ساتھ نبھاؤں گا/گی۔$languageSentence',
        closing: (company, role) =>
            '$company میں $role کے طور پر کردار ادا کرنے کا موقع میرے لیے باعثِ خوشی ہوگا۔ میری درخواست پر غور کرنے کا شکریہ۔ میں اس امکان پر مزید گفتگو کے موقع کا منتظر/منتظرہ رہوں گا/گی کہ میں آپ کی ٹیم کی کس طرح مدد کر سکتا/سکتی ہوں۔',
        sincerely: 'مخلص،',
        languageSentence: (language) =>
            ' میں $language میں بھی مؤثر انداز میں بات چیت کر سکتا/سکتی ہوں، جس سے اس کردار میں واضح تعاون ممکن ہوگا۔',
      ),
      'Vietnamese' => _CoverLetterLocale(
        hiringManager: 'Quản lý tuyển dụng',
        greeting: 'Kính gửi Quản lý tuyển dụng,',
        opening: (role, company) =>
            'Tôi viết thư này để bày tỏ sự quan tâm của mình đối với vị trí $role tại $company. Cơ hội này thu hút tôi vì dường như đề cao tính chuyên nghiệp, sự tin cậy và khả năng đóng góp có ý nghĩa ngay từ ngày đầu tiên.',
        fit: (role, skill) =>
            'Tôi tin rằng mình sẽ phù hợp với vị trí này vì tôi có thể mang đến cách tiếp cận tập trung vào $skill, cùng với tinh thần học hỏi nhanh, khả năng thích nghi với nhu cầu của nhóm và duy trì chất lượng công việc một cách ổn định.',
        strengths: (languageSentence) =>
            'Tôi sẽ mang đến cho vai trò này khả năng giao tiếp, tổ chức và giải quyết vấn đề tốt, đồng thời đảm nhận trách nhiệm với sự cẩn trọng, tinh thần trách nhiệm và chú ý đến chi tiết.$languageSentence',
        closing: (company, role) =>
            'Tôi rất mong có cơ hội được đóng góp cho $company với vai trò $role. Cảm ơn quý công ty đã xem xét hồ sơ của tôi. Tôi mong có cơ hội trao đổi thêm về cách tôi có thể hỗ trợ đội ngũ của quý công ty.',
        sincerely: 'Trân trọng,',
        languageSentence: (language) =>
            ' Tôi cũng có thể giao tiếp hiệu quả bằng $language, điều này sẽ giúp tôi phối hợp rõ ràng hơn trong vai trò này.',
      ),
      _ => const _CoverLetterLocale.english(),
    };
  }

  Future<JobDescriptionInsights> analyzeJobDescription({
    required String jobDescription,
    required ResumeData resume,
  }) async {
    return _simulate(() {
      final keywords = _extractKeywords(jobDescription).take(8).toList();
      final haystack = [
        resume.jobTitle,
        resume.summary,
        ...resume.skills,
        ...resume.visibleWorkExperiences.expand((item) => item.bullets),
      ].join(' ').toLowerCase();

      final missing = keywords
          .where((keyword) => !haystack.contains(keyword.toLowerCase()))
          .take(5)
          .toList();

      final summary = keywords.isEmpty
          ? 'Add a job description to extract ATS keywords and compare them with your resume.'
          : 'The posting emphasizes ${keywords.take(3).join(', ')}. '
                '${missing.isEmpty ? 'Your resume already reflects the top terms well.' : 'Consider adding ${missing.take(2).join(' and ')} where it is truthful and relevant.'}';

      return JobDescriptionInsights(
        summary: summary,
        keywords: keywords,
        missingSkills: missing,
      );
    });
  }

  ResumeAnalysis _buildAnalysis({
    required ResumeData resume,
    required String jobDescription,
  }) {
    var score = 32;
    final improvements = <String>[];
    final strengths = <String>[];
    final weakDescriptions = <String>[];

    if (resume.fullName.trim().isNotEmpty) {
      score += 8;
    } else {
      improvements.add(
        'Add your full name to create a complete resume header.',
      );
    }

    if (resume.email.trim().isNotEmpty && resume.phone.trim().isNotEmpty) {
      score += 10;
      strengths.add('Includes reachable contact information.');
    } else {
      improvements.add(
        'Add both email and phone so recruiters can contact you quickly.',
      );
    }

    if (resume.summary.trim().length > 90) {
      score += 10;
      strengths.add('Summary introduces value clearly.');
    } else {
      improvements.add(
        'Strengthen the summary with 2-3 lines focused on outcomes and target role.',
      );
    }

    if (resume.visibleWorkExperiences.isNotEmpty) {
      score += 16;
      strengths.add('Work experience section is present.');
      for (final experience in resume.visibleWorkExperiences) {
        final bulletStrength = experience.bullets
            .where((item) => item.length > 45)
            .length;
        if (bulletStrength < 2 && experience.description.trim().length < 60) {
          weakDescriptions.add(
            '${experience.role.trim().isEmpty ? 'Experience entry' : experience.role.trim()} needs stronger, outcome-focused bullets.',
          );
        }
      }
    } else {
      improvements.add(
        'Add at least one work experience entry, internship, or freelance project.',
      );
    }

    if (resume.skills.length >= 6) {
      score += 10;
      strengths.add('Skill inventory is broad enough for ATS matching.');
    } else {
      improvements.add(
        'Expand the skills section with tools, methods, and domain keywords.',
      );
    }

    if (resume.visibleEducation.isNotEmpty) {
      score += 6;
    } else {
      improvements.add('Add education details to complete the profile.');
    }

    if (resume.visibleProjects.isNotEmpty) {
      score += 8;
      strengths.add('Projects add proof of execution.');
    } else {
      improvements.add(
        'Include 1-2 projects with impact metrics or user outcomes.',
      );
    }

    final keywords = _extractKeywords(jobDescription).take(10).toList();
    final resumeText = [
      resume.jobTitle,
      resume.summary,
      ...resume.skills,
      ...resume.visibleWorkExperiences.expand((item) => item.bullets),
    ].join(' ').toLowerCase();

    final missingSkills = keywords
        .where((keyword) => !resumeText.contains(keyword.toLowerCase()))
        .take(5)
        .toList();

    if (keywords.isNotEmpty) {
      if (missingSkills.isEmpty) {
        score += 12;
        strengths.add('Good alignment with the target job description.');
      } else {
        score += 5;
        improvements.add(
          'Mirror more relevant job-description keywords where they are truthful.',
        );
      }
    }

    score = score.clamp(0, 100);

    return ResumeAnalysis(
      score: score,
      atsCompatibility: score / 100,
      missingSkills: missingSkills,
      weakDescriptions: weakDescriptions,
      strengths: strengths,
      improvements: improvements.toSet().toList(),
    );
  }

  ResumeAnalysis _buildTextAnalysis({
    required String resumeText,
    required String jobDescription,
  }) {
    final normalized = resumeText.trim();
    if (normalized.isEmpty) {
      return const ResumeAnalysis(
        score: 0,
        atsCompatibility: 0,
        missingSkills: [],
        weakDescriptions: [],
        strengths: [],
        improvements: ['Paste your current resume text to run the analyser.'],
      );
    }

    final lower = normalized.toLowerCase();
    var score = 28;
    final improvements = <String>[];
    final strengths = <String>[];
    final weakDescriptions = <String>[];

    if (RegExp(r'[\w\.-]+@[\w\.-]+\.\w+').hasMatch(normalized)) {
      score += 8;
      strengths.add('Includes an email address.');
    } else {
      improvements.add('Add a clear email address to the resume header.');
    }

    if (RegExp(r'(\+\d{1,3}[\s-]?)?(\d[\s-]?){10,}').hasMatch(normalized)) {
      score += 8;
      strengths.add('Includes a phone number.');
    } else {
      improvements.add('Add a phone number recruiters can reach easily.');
    }

    if (_containsAny(lower, ['summary', 'profile', 'objective'])) {
      score += 10;
      strengths.add('Includes a professional summary section.');
    } else {
      improvements.add(
        'Add a short summary near the top to frame your value quickly.',
      );
    }

    if (_containsAny(lower, ['experience', 'employment', 'work history'])) {
      score += 14;
      strengths.add('Work experience is present.');
    } else {
      improvements.add(
        'Include work experience or equivalent project experience.',
      );
    }

    if (_containsAny(lower, ['education'])) {
      score += 6;
    } else {
      improvements.add('Add education details to round out the resume.');
    }

    if (_containsAny(lower, ['skills'])) {
      score += 8;
    } else {
      improvements.add('Create a dedicated skills section for ATS matching.');
    }

    final bulletCount = RegExp(
      r'^[\-\u2022\*]',
      multiLine: true,
    ).allMatches(normalized).length;
    if (bulletCount >= 3) {
      score += 10;
      strengths.add('Uses bullet points for scan-friendly reading.');
    } else {
      improvements.add(
        'Use more bullet points so achievements are easier to scan.',
      );
    }

    final metricCount = RegExp(
      r'\b\d+[%+xXkKmM]?\b',
    ).allMatches(normalized).length;
    if (metricCount >= 3) {
      score += 10;
      strengths.add('Contains measurable results or scope indicators.');
    } else {
      weakDescriptions.add(
        'Several claims still need numbers, percentages, scale, or concrete outcomes.',
      );
      improvements.add(
        'Add metrics like revenue, time saved, users, accuracy, or growth.',
      );
    }

    final keywords = _extractKeywords(jobDescription).take(10).toList();
    final missingSkills = keywords
        .where((keyword) => !lower.contains(keyword.toLowerCase()))
        .take(5)
        .toList();

    if (keywords.isNotEmpty) {
      if (missingSkills.isEmpty) {
        score += 12;
        strengths.add('Matches the target job description well.');
      } else {
        score += 4;
        improvements.add(
          'Mirror more truthful target-job keywords in your resume content.',
        );
      }
    }

    score = score.clamp(0, 100);

    return ResumeAnalysis(
      score: score,
      atsCompatibility: score / 100,
      missingSkills: missingSkills,
      weakDescriptions: weakDescriptions,
      strengths: strengths,
      improvements: improvements.toSet().toList(),
    );
  }

  List<String> _buildProofGapPrompts({
    required String resumeText,
    required String jobDescription,
  }) {
    final prompts = <String>[];
    final normalized = resumeText.trim();
    final lower = normalized.toLowerCase();
    final metricCount = RegExp(
      r'\b\d+[%+xXkKmM]?\b',
    ).allMatches(normalized).length;

    if (metricCount < 3) {
      prompts.add(
        'Which bullet can you quantify with a number, percentage, revenue impact, time saved, or users affected?',
      );
    }

    if (!_containsAny(lower, [
      'led',
      'owned',
      'built',
      'launched',
      'improved',
    ])) {
      prompts.add(
        'Where can you replace generic language with a stronger action verb like built, led, launched, improved, or reduced?',
      );
    }

    if (_containsAny(lower, ['team player', 'hardworking', 'responsible'])) {
      prompts.add(
        'Which vague phrase like "team player" or "responsible for" can you replace with a specific result or example?',
      );
    }

    final missingKeywords = _extractKeywords(jobDescription)
        .where((keyword) => !lower.contains(keyword.toLowerCase()))
        .take(2)
        .toList();
    if (missingKeywords.isNotEmpty) {
      prompts.add(
        'Which project or job entry best proves ${missingKeywords.join(' and ')} so you can add that evidence truthfully?',
      );
    }

    if (!_containsAny(lower, ['skills'])) {
      prompts.add(
        'What tools, platforms, or methods should be pulled into a dedicated skills section for easier ATS matching?',
      );
    }

    if (prompts.isEmpty) {
      prompts.add(
        'Your resume already reads strongly. Next, review each major claim and ask: what proof would make this even more believable to a recruiter?',
      );
    }

    return prompts.take(4).toList();
  }

  ResumeData _buildResumeFromImportedText({
    required String resumeText,
    required ResumeTemplate template,
    required String sourceTitle,
  }) {
    final normalizedText = resumeText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    final lines = normalizedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final sections = _splitImportedResumeSections(lines);
    final headerLines = sections['header'] ?? const <String>[];
    final summaryLines = sections['summary'] ?? const <String>[];
    final skillsLines = sections['skills'] ?? const <String>[];
    final experienceLines =
        sections['experience']
            ?.where((line) => line.trim().isNotEmpty)
            .toList() ??
        _fallbackImportedExperienceLines(lines);
    final educationLines =
        sections['education']
            ?.where((line) => line.trim().isNotEmpty)
            .toList() ??
        _fallbackImportedEducationLines(lines);
    final projectLines =
        sections['projects']
            ?.where((line) => line.trim().isNotEmpty)
            .toList() ??
        _fallbackImportedProjectLines(lines);

    final fallbackTitle = _cleanImportedTitle(sourceTitle);
    final fullName = _inferImportedFullName(headerLines, fallbackTitle);
    final jobTitle = _inferImportedJobTitle(
      headerLines: headerLines,
      experienceLines: experienceLines,
      fallbackTitle: fallbackTitle,
    );

    return ResumeData.empty(template: template.userFacingTemplate).copyWith(
      title: _normalizeImportedResumeTitle(
        sourceTitle: fallbackTitle,
        fullName: fullName,
        jobTitle: jobTitle,
      ),
      fullName: fullName,
      jobTitle: jobTitle,
      email:
          _firstRegexMatch(normalizedText, RegExp(r'[\w\.-]+@[\w\.-]+\.\w+')) ??
          '',
      phone: _extractImportedPhone(normalizedText),
      location: _inferImportedLocation(headerLines),
      website: _extractImportedWebsite(normalizedText),
      summary: _collectImportedSummary(
        summaryLines: summaryLines,
        headerLines: headerLines,
        allLines: lines,
      ),
      workExperiences: _extractImportedWorkExperiences(
        experienceLines: experienceLines,
        fallbackJobTitle: jobTitle,
      ),
      education: _extractImportedEducation(educationLines),
      skills: _extractImportedSkills(
        skillLines: skillsLines,
        resumeText: normalizedText,
      ).take(50).toList(),
      projects: _extractImportedProjects(projectLines),
      customSections: _extractImportedCustomSections(sections),
      githubLink: _extractImportedLink(normalizedText, 'github.com'),
      linkedinLink: _extractImportedLink(normalizedText, 'linkedin.com'),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, List<String>> _splitImportedResumeSections(List<String> lines) {
    final sections = <String, List<String>>{'header': <String>[]};
    var currentSection = 'header';

    for (final line in lines) {
      final headingData = _matchImportedSectionHeadingData(line);
      if (headingData != null) {
        currentSection = headingData.$1;
        sections.putIfAbsent(currentSection, () => <String>[]);
        if (headingData.$2.isNotEmpty) {
          sections[currentSection]!.add(headingData.$2);
        }
        continue;
      }

      sections.putIfAbsent(currentSection, () => <String>[]).add(line);
    }

    return sections;
  }

  String? _matchImportedSectionHeading(String line) {
    return _matchImportedSectionHeadingData(line)?.$1;
  }

  static const Map<String, String> _importedSectionHeadingMap = {
    'professional summary': 'summary',
    'career summary': 'summary',
    'executive summary': 'summary',
    'summary': 'summary',
    'profile': 'summary',
    'objective': 'summary',
    'technical skills': 'skills',
    'core competencies': 'skills',
    'key competencies': 'skills',
    'core skills': 'skills',
    'key skills': 'skills',
    'tools and technologies': 'skills',
    'tools & technologies': 'skills',
    'technologies': 'skills',
    'skills': 'skills',
    'professional experience': 'experience',
    'project experience': 'experience',
    'employment history': 'experience',
    'work experience': 'experience',
    'work history': 'experience',
    'career history': 'experience',
    'experience': 'experience',
    'employment': 'experience',
    'education and training': 'education',
    'academic background': 'education',
    'academic qualifications': 'education',
    'education': 'education',
    'selected projects': 'projects',
    'personal projects': 'projects',
    'academic projects': 'projects',
    'projects': 'projects',
    'project': 'projects',
    'certifications': 'certifications',
    'certification': 'certifications',
    'licenses': 'certifications',
    'languages': 'languages',
    'awards': 'awards',
    'honors': 'awards',
    'publications': 'publications',
    'volunteer experience': 'volunteer',
    'volunteer': 'volunteer',
    'activities': 'activities',
  };

  (String, String)? _matchImportedSectionHeadingData(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z& ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    for (final entry in _importedSectionHeadingMap.entries) {
      if (normalized == entry.key) {
        return (entry.value, '');
      }

      final aliasPattern = entry.key.split(' ').map(RegExp.escape).join(r'\s+');
      final prefixMatch = RegExp(
        '^$aliasPattern(?:\\s*[:\\-–—|]\\s*|\\s{2,})(.+)\$',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (prefixMatch != null) {
        return (entry.value, prefixMatch.group(1)?.trim() ?? '');
      }
    }

    return null;
  }

  String _inferImportedFullName(
    List<String> headerLines,
    String fallbackTitle,
  ) {
    for (final line in headerLines.take(3)) {
      if (_isImportedContactLine(line)) {
        continue;
      }
      final cleaned = line.trim();
      final wordCount = cleaned.split(RegExp(r'\s+')).length;
      if (cleaned.length <= 40 && wordCount <= 4) {
        return _toTitleCase(cleaned);
      }
    }

    final fallback = fallbackTitle
        .replaceAll(RegExp(r'\bresume\b', caseSensitive: false), '')
        .trim();
    return fallback.isEmpty ? '' : _toTitleCase(fallback);
  }

  String _inferImportedJobTitle({
    required List<String> headerLines,
    required List<String> experienceLines,
    required String fallbackTitle,
  }) {
    for (final line in headerLines.skip(1).take(3)) {
      if (_isImportedContactLine(line)) {
        continue;
      }
      if (line.split(RegExp(r'\s+')).length <= 8) {
        return line.trim();
      }
    }

    for (final line in experienceLines.take(3)) {
      if (_isImportedBulletLine(line) || _isImportedContactLine(line)) {
        continue;
      }
      final role = _extractImportedRole(line);
      if (role.isNotEmpty) {
        return role;
      }
    }

    return fallbackTitle
        .replaceAll(RegExp(r'\bresume\b', caseSensitive: false), '')
        .trim();
  }

  String _inferImportedLocation(List<String> headerLines) {
    for (final line in headerLines) {
      if (!_isImportedContactLine(line) && line.contains(',')) {
        return line.trim();
      }

      final segments = line.split('|').map((item) => item.trim());
      for (final segment in segments) {
        if (segment.contains(',') &&
            !_isImportedContactLine(segment) &&
            !segment.contains('@')) {
          return segment;
        }
      }
    }
    return '';
  }

  String _collectImportedSummary({
    required List<String> summaryLines,
    required List<String> headerLines,
    required List<String> allLines,
  }) {
    if (summaryLines.isNotEmpty) {
      return summaryLines.take(3).join(' ').trim();
    }

    final fallbackLines = allLines
        .where((line) {
          if (headerLines.contains(line)) {
            return false;
          }
          if (_matchImportedSectionHeading(line) != null) {
            return false;
          }
          if (_isImportedContactLine(line)) {
            return false;
          }
          return line.split(RegExp(r'\s+')).length >= 8;
        })
        .take(2);

    return fallbackLines.join(' ').trim();
  }

  List<String> _extractImportedSkills({
    required List<String> skillLines,
    required String resumeText,
  }) {
    final values = <String>{};
    final sources = skillLines.isNotEmpty
        ? skillLines
        : _extractKeywords(resumeText).take(10).toList();

    for (final source in sources) {
      final normalized = source
          .replaceAll('•', ',')
          .replaceAll('|', ',')
          .replaceAll('·', ',');
      for (final item in normalized.split(',')) {
        final cleaned = item.replaceAll(RegExp(r'^[\-\*\u2022]\s*'), '').trim();
        if (cleaned.isEmpty) {
          continue;
        }
        if (_matchImportedSectionHeading(cleaned) != null) {
          continue;
        }
        if (cleaned.split(RegExp(r'\s+')).length > 4) {
          continue;
        }
        values.add(cleaned);
      }
    }

    return values.toList();
  }

  List<WorkExperience> _extractImportedWorkExperiences({
    required List<String> experienceLines,
    required String fallbackJobTitle,
  }) {
    if (experienceLines.isEmpty) {
      return const [WorkExperience.empty()];
    }

    final entries = <List<String>>[];
    var current = <String>[];
    var sawBullet = false;

    for (final line in experienceLines) {
      final isBullet = _isImportedBulletLine(line);
      final currentHeaderCount = current
          .where((item) => !_isImportedBulletLine(item))
          .length;

      if (current.isNotEmpty &&
          !isBullet &&
          _looksLikeImportedExperienceHeader(line) &&
          (sawBullet || currentHeaderCount >= 2)) {
        entries.add(current);
        current = <String>[line];
        sawBullet = false;
        continue;
      }

      current.add(line);
      if (isBullet) {
        sawBullet = true;
      }
    }

    if (current.isNotEmpty) {
      entries.add(current);
    }

    final items = entries
        .map(
          (entry) => _buildImportedWorkExperience(
            entry,
            fallbackJobTitle: fallbackJobTitle,
          ),
        )
        .where((item) => !item.isBlank)
        .toList();

    return items.isEmpty ? const [WorkExperience.empty()] : items;
  }

  List<EducationItem> _extractImportedEducation(List<String> educationLines) {
    if (educationLines.isEmpty) {
      return const [EducationItem.empty()];
    }

    final entries = <List<String>>[];
    var current = <String>[];

    for (final line in educationLines) {
      if (current.isNotEmpty &&
          _looksLikeImportedEducationHeader(line) &&
          _educationEntryLooksComplete(current)) {
        entries.add(current);
        current = <String>[line];
        continue;
      }
      current.add(line);
    }

    if (current.isNotEmpty) {
      entries.add(current);
    }

    final items = entries
        .map(_buildImportedEducationItem)
        .where((item) => !item.isBlank)
        .toList();

    return items.isEmpty ? const [EducationItem.empty()] : items;
  }

  List<ProjectItem> _extractImportedProjects(List<String> projectLines) {
    if (projectLines.isEmpty) {
      return const [ProjectItem.empty()];
    }

    final entries = <List<String>>[];
    var current = <String>[];
    var sawBullet = false;

    for (final line in projectLines) {
      final isBullet = _isImportedBulletLine(line);
      if (current.isNotEmpty &&
          !isBullet &&
          _looksLikeImportedProjectHeader(line) &&
          sawBullet) {
        entries.add(current);
        current = <String>[line];
        sawBullet = false;
        continue;
      }

      current.add(line);
      if (isBullet) {
        sawBullet = true;
      }
    }

    if (current.isNotEmpty) {
      entries.add(current);
    }

    final items = entries
        .map(_buildImportedProjectItem)
        .where((item) => !item.isBlank)
        .toList();

    return items.isEmpty ? const [ProjectItem.empty()] : items;
  }

  List<CustomSectionItem> _extractImportedCustomSections(
    Map<String, List<String>> sections,
  ) {
    const customSectionTitles = <String, String>{
      'certifications': 'Certifications',
      'languages': 'Languages',
      'awards': 'Awards',
      'publications': 'Publications',
      'volunteer': 'Volunteer Experience',
      'activities': 'Activities',
    };

    final items = <CustomSectionItem>[];
    for (final entry in customSectionTitles.entries) {
      final lines = sections[entry.key] ?? const <String>[];
      if (lines.isEmpty) {
        continue;
      }

      final bullets = lines
          .where(_isImportedBulletLine)
          .map(_stripImportedBullet)
          .where((line) => line.isNotEmpty)
          .toList();
      final content = lines
          .where((line) => !_isImportedBulletLine(line))
          .join('\n')
          .trim();

      final item = bullets.isNotEmpty
          ? CustomSectionItem(
              title: entry.value,
              content: content,
              layoutMode: CustomSectionLayoutMode.bullets,
              bullets: bullets,
            )
          : CustomSectionItem(
              title: entry.value,
              content: content,
              layoutMode: CustomSectionLayoutMode.summary,
            );

      if (!item.isBlank) {
        items.add(item);
      }
    }

    return items;
  }

  List<String> _fallbackImportedExperienceLines(List<String> lines) {
    final collected = <String>[];
    var started = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }

      if (!started) {
        if (_looksLikeImportedExperienceHeader(line) &&
            _looksLikeExperienceEntryStart(lines, i)) {
          started = true;
          collected.add(line);
        }
        continue;
      }

      if (_isFallbackSectionBoundary(line, stopAtProjects: true) ||
          _looksLikeEducationEntryStart(lines, i)) {
        break;
      }

      collected.add(line);
    }

    return collected;
  }

  List<String> _fallbackImportedEducationLines(List<String> lines) {
    final collected = <String>[];
    var started = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }

      if (!started) {
        if (_looksLikeEducationEntryStart(lines, i)) {
          started = true;
          collected.add(line);
        }
        continue;
      }

      if (_isFallbackSectionBoundary(line, stopAtProjects: true)) {
        break;
      }

      collected.add(line);
    }

    return collected;
  }

  List<String> _fallbackImportedProjectLines(List<String> lines) {
    final collected = <String>[];
    var started = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }

      if (!started) {
        final lower = line.toLowerCase();
        if (lower.contains('project') &&
            !_isImportedContactLine(line) &&
            !_looksLikeImportedDateLine(line)) {
          started = true;
          collected.add(line);
        }
        continue;
      }

      if (_isFallbackSectionBoundary(line, stopAtProjects: false)) {
        break;
      }

      collected.add(line);
    }

    return collected;
  }

  bool _looksLikeExperienceEntryStart(List<String> lines, int index) {
    return _hasLookAheadMatch(lines, index, _looksLikeImportedDateLine, 2) ||
        _hasLookAheadMatch(lines, index, _isImportedBulletLine, 3);
  }

  bool _looksLikeEducationEntryStart(List<String> lines, int index) {
    final line = lines[index].trim();
    final lower = line.toLowerCase();
    final hasEducationKeyword = RegExp(
      r'(bachelor|master|diploma|degree|b\.tech|btech|mba|bsc|msc|ba|bs|phd|certificate|certification|associate)',
      caseSensitive: false,
    ).hasMatch(line);

    if (hasEducationKeyword) {
      return _hasLookAheadMatch(lines, index, _looksLikeImportedDateLine, 3) ||
          _hasLookAheadMatch(
            lines,
            index,
            (candidate) =>
                candidate.contains('University') ||
                candidate.contains('College') ||
                candidate.contains('Institute') ||
                candidate.contains('School'),
            2,
          );
    }

    return (lower.contains('university') ||
            lower.contains('college') ||
            lower.contains('institute') ||
            lower.contains('school')) &&
        _hasLookAheadMatch(lines, index, _looksLikeImportedDateLine, 2);
  }

  bool _hasLookAheadMatch(
    List<String> lines,
    int startIndex,
    bool Function(String line) predicate,
    int lookAhead,
  ) {
    final end = math.min(lines.length, startIndex + lookAhead + 1);
    for (var i = startIndex + 1; i < end; i++) {
      if (predicate(lines[i].trim())) {
        return true;
      }
    }
    return false;
  }

  bool _isFallbackSectionBoundary(String line, {required bool stopAtProjects}) {
    final heading = _matchImportedSectionHeading(line);
    if (heading == null) {
      return false;
    }

    if (heading == 'summary' ||
        heading == 'skills' ||
        heading == 'experience') {
      return false;
    }

    if (!stopAtProjects && heading == 'projects') {
      return false;
    }

    return true;
  }

  String _cleanImportedTitle(String sourceTitle) {
    final withoutExtension = sourceTitle.replaceFirst(
      RegExp(r'\.[a-z0-9]+$', caseSensitive: false),
      '',
    );
    return withoutExtension
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeImportedResumeTitle({
    required String sourceTitle,
    required String fullName,
    required String jobTitle,
  }) {
    if (sourceTitle.isNotEmpty) {
      return sourceTitle;
    }
    if (jobTitle.isNotEmpty) {
      return '$jobTitle Resume';
    }
    if (fullName.isNotEmpty) {
      return '$fullName Resume';
    }
    return ResumeData.defaultTitle;
  }

  int _scoreImportedResumeParse(ResumeData resume, String sourceText) {
    var score = 0;

    if (resume.fullName.trim().isNotEmpty &&
        !resume.fullName.contains('@') &&
        !RegExp(r'\d').hasMatch(resume.fullName)) {
      score += 10;
    }
    if (resume.jobTitle.trim().isNotEmpty) {
      score += 8;
    }
    if (resume.email.trim().isNotEmpty) {
      score += 8;
    }
    if (resume.phone.trim().isNotEmpty) {
      score += 6;
    }
    if (resume.location.trim().isNotEmpty) {
      score += 4;
    }
    if (resume.website.trim().isNotEmpty) {
      score += 3;
    }
    if (resume.githubLink.trim().isNotEmpty) {
      score += 2;
    }
    if (resume.linkedinLink.trim().isNotEmpty) {
      score += 2;
    }
    if (resume.summary.trim().length >= 60) {
      score += 12;
    } else if (resume.summary.trim().isNotEmpty) {
      score += 5;
    }

    for (final item in resume.visibleWorkExperiences) {
      score += 12;
      if (item.role.trim().isNotEmpty) {
        score += 4;
      }
      if (item.company.trim().isNotEmpty) {
        score += 4;
      }
      if (item.startDate.trim().isNotEmpty || item.endDate.trim().isNotEmpty) {
        score += 3;
      }
      score += math.min(
        4,
        item.bullets.where((b) => b.trim().isNotEmpty).length,
      );
    }

    for (final item in resume.visibleEducation) {
      score += 10;
      if (item.degree.trim().isNotEmpty) {
        score += 4;
      }
      if (item.institution.trim().isNotEmpty) {
        score += 4;
      }
    }

    score += math.min(20, resume.skills.length * 2);

    for (final item in resume.visibleProjects) {
      score += 8;
      if (item.title.trim().isNotEmpty) {
        score += 4;
      }
      score += math.min(
        3,
        item.bullets.where((b) => b.trim().isNotEmpty).length,
      );
    }

    score += resume.visibleCustomSections.length * 3;

    final lower = sourceText.toLowerCase();
    if (_containsAny(lower, const ['experience', 'work experience']) &&
        resume.visibleWorkExperiences.isEmpty) {
      score -= 12;
    }
    if (_containsAny(lower, const ['education']) &&
        resume.visibleEducation.isEmpty) {
      score -= 10;
    }
    if (_containsAny(lower, const ['skills', 'core competencies']) &&
        resume.skills.isEmpty) {
      score -= 10;
    }
    if (_containsAny(lower, const ['projects', 'project']) &&
        resume.visibleProjects.isEmpty) {
      score -= 8;
    }
    if (_containsAny(lower, const ['summary', 'profile']) &&
        resume.summary.trim().isEmpty) {
      score -= 8;
    }

    return score;
  }

  bool _isImportedContactLine(String line) {
    return line.contains('@') ||
        RegExp(r'(https?:\/\/|www\.)', caseSensitive: false).hasMatch(line) ||
        RegExp(r'(\+\d{1,3}[\s-]?)?(\d[\s-]?){10,}').hasMatch(line);
  }

  bool _isImportedBulletLine(String line) {
    return RegExp(r'^\s*[\-\u2022\*]').hasMatch(line);
  }

  String _stripImportedBullet(String line) {
    return line.replaceFirst(RegExp(r'^\s*[\-\u2022\*]\s*'), '').trim();
  }

  bool _looksLikeImportedExperienceHeader(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty ||
        _isImportedBulletLine(cleaned) ||
        _looksLikeImportedDateLine(cleaned)) {
      return false;
    }

    final wordCount = cleaned.split(RegExp(r'\s+')).length;
    if (cleaned.contains('|') || cleaned.contains(' / ')) {
      return true;
    }
    if (RegExp(r'\bat\b', caseSensitive: false).hasMatch(cleaned)) {
      return true;
    }

    return wordCount <= 8 && !cleaned.endsWith('.');
  }

  bool _looksLikeImportedProjectHeader(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty ||
        _isImportedBulletLine(cleaned) ||
        _looksLikeImportedDateLine(cleaned)) {
      return false;
    }

    return cleaned.split(RegExp(r'\s+')).length <= 10 && !cleaned.endsWith('.');
  }

  bool _looksLikeImportedEducationHeader(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty || _looksLikeImportedDateLine(cleaned)) {
      return false;
    }

    return RegExp(
          r'(bachelor|master|diploma|degree|b\.tech|btech|mba|bsc|msc|ba|bs|phd|certificate|certification|associate)',
          caseSensitive: false,
        ).hasMatch(cleaned) ||
        (cleaned.split(RegExp(r'\s+')).length <= 8 && !cleaned.endsWith('.'));
  }

  bool _educationEntryLooksComplete(List<String> lines) {
    return lines.length >= 2 && lines.any(_looksLikeImportedDateLine);
  }

  WorkExperience _buildImportedWorkExperience(
    List<String> entry, {
    required String fallbackJobTitle,
  }) {
    final bulletLines = entry
        .where(_isImportedBulletLine)
        .map(_stripImportedBullet)
        .where((line) => line.isNotEmpty)
        .take(8)
        .toList();
    final detailLines = entry
        .where((line) => !_isImportedBulletLine(line))
        .toList();

    var role = fallbackJobTitle;
    var company = '';
    var startDate = '';
    var endDate = '';
    final descriptionLines = <String>[];

    for (final line in detailLines) {
      if (_looksLikeImportedDateLine(line)) {
        final dates = _extractImportedDates(line);
        if (startDate.isEmpty && dates.$1.isNotEmpty) {
          startDate = dates.$1;
        }
        if (endDate.isEmpty && dates.$2.isNotEmpty) {
          endDate = dates.$2;
        }
        continue;
      }

      if (role == fallbackJobTitle || role.trim().isEmpty) {
        role = _extractImportedRole(line).ifEmpty(fallbackJobTitle);
        company = _extractImportedCompany(line);
        continue;
      }

      if (company.isEmpty &&
          line.split(RegExp(r'\s+')).length <= 8 &&
          !line.endsWith('.')) {
        company = line.trim();
        continue;
      }

      descriptionLines.add(line);
    }

    final description = descriptionLines.take(2).join(' ').trim();
    return WorkExperience(
      role: role.ifEmpty(fallbackJobTitle),
      company: company,
      startDate: startDate,
      endDate: endDate,
      description: description,
      bullets: bulletLines,
      layoutMode: WorkExperienceLayoutMode.bullets,
    );
  }

  EducationItem _buildImportedEducationItem(List<String> entry) {
    final combined = entry.join(' | ');
    final dates = _extractImportedDates(combined);
    final score =
        _firstRegexMatch(
          combined,
          RegExp(
            r'\b\d+(?:\.\d+)?\s*(?:cgpa|gpa|%|percent)\b',
            caseSensitive: false,
          ),
        ) ??
        '';
    final degree = entry.firstWhere(
      (line) => RegExp(
        r'(bachelor|master|diploma|degree|b\.tech|btech|mba|bsc|msc|ba|bs|phd|certificate|certification|associate)',
        caseSensitive: false,
      ).hasMatch(line),
      orElse: () => entry.first,
    );
    final institution = entry.firstWhere(
      (line) =>
          line != degree && !_looksLikeImportedDateLine(line) && line != score,
      orElse: () => '',
    );

    return EducationItem(
      institution: institution,
      degree: degree,
      startDate: dates.$1,
      endDate: dates.$2,
      score: score,
    );
  }

  ProjectItem _buildImportedProjectItem(List<String> entry) {
    final bullets = entry
        .where(_isImportedBulletLine)
        .map(_stripImportedBullet)
        .where((line) => line.isNotEmpty)
        .take(6)
        .toList();
    final detailLines = entry
        .where((line) => !_isImportedBulletLine(line))
        .toList();
    final title = detailLines.isNotEmpty ? detailLines.first.trim() : 'Project';
    final overview = detailLines.skip(1).take(2).join(' ').trim();

    return ProjectItem(title: title, overview: overview, bullets: bullets);
  }

  bool _looksLikeImportedDateLine(String line) {
    return RegExp(
      r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\b(?:19|20)\d{2}\b|present|current)',
      caseSensitive: false,
    ).hasMatch(line);
  }

  (String, String) _extractImportedDates(String line) {
    final matches = RegExp(
      r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\b(?:19|20)\d{2}\b|present|current)',
      caseSensitive: false,
    ).allMatches(line).map((match) => match.group(0)!.trim()).toList();

    if (matches.isEmpty) {
      return ('', '');
    }

    if (matches.length == 1) {
      final only = matches.first;
      final normalized =
          RegExp(r'^(present|current)$', caseSensitive: false).hasMatch(only)
          ? 'Present'
          : only;
      return ('', normalized);
    }

    final start = matches.first;
    final rawEnd = matches[1];
    final end =
        RegExp(r'^(present|current)$', caseSensitive: false).hasMatch(rawEnd)
        ? 'Present'
        : rawEnd;
    return (start, end);
  }

  String _extractImportedRole(String line) {
    final cleaned = line.trim();
    if (cleaned.contains('|')) {
      return cleaned.split('|').first.trim();
    }
    if (RegExp(r'\bat\b', caseSensitive: false).hasMatch(cleaned)) {
      return cleaned
          .split(RegExp(r'\bat\b', caseSensitive: false))
          .first
          .trim();
    }
    return cleaned;
  }

  String _extractImportedCompany(String line) {
    final cleaned = line.trim();
    if (cleaned.contains('|')) {
      final parts = cleaned.split('|').map((part) => part.trim()).toList();
      if (parts.length >= 2) {
        return parts[1];
      }
    }
    if (RegExp(r'\bat\b', caseSensitive: false).hasMatch(cleaned)) {
      final parts = cleaned.split(RegExp(r'\bat\b', caseSensitive: false));
      if (parts.length >= 2) {
        return parts[1].trim();
      }
    }
    return '';
  }

  String _extractImportedPhone(String text) {
    return _firstRegexMatch(
          text,
          RegExp(r'(\+\d{1,3}[\s-]?)?(\d[\s-]?){10,}'),
        ) ??
        '';
  }

  String _extractImportedWebsite(String text) {
    final matches = RegExp(
      r'((?:https?:\/\/|www\.)[^\s]+)',
      caseSensitive: false,
    ).allMatches(text);

    for (final match in matches) {
      final value = match.group(0)?.trim() ?? '';
      final lower = value.toLowerCase();
      if (lower.contains('linkedin.com') || lower.contains('github.com')) {
        continue;
      }
      return value;
    }

    return '';
  }

  String _extractImportedLink(String text, String domain) {
    final regex = RegExp(
      '((?:(?:https?:\\/\\/|www\\.)?[^\\s|]*${RegExp.escape(domain)}[^\\s|]*))',
      caseSensitive: false,
    );
    return _firstRegexMatch(text, regex) ?? '';
  }

  String? _firstRegexMatch(String text, RegExp pattern) {
    final match = pattern.firstMatch(text);
    return match?.group(0);
  }

  String _toTitleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length <= 2
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static const int _targetSummaryLinesMin = 4;
  static const int _targetSummaryLinesMax = 5;
  static const int _summaryVariantCount = 4;

  String _summaryEvidencePhrase(String source) {
    final normalized = _normalizeSentenceForResume(
      source,
    ).replaceAll(RegExp(r'\.$'), '');
    if (normalized.isEmpty) {
      return normalized;
    }
    return normalized[0].toLowerCase() + normalized.substring(1);
  }

  String _finalizeSummaryLines(String summary, ResumeData resume) {
    final lines = summary
        .split('\n')
        .map((line) => _withoutCompanyNames(line, resume).trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final capped = lines.length > _targetSummaryLinesMax
        ? lines.take(_targetSummaryLinesMax).toList()
        : lines;

    if (capped.length >= _targetSummaryLinesMin) {
      return capped.join('\n');
    }

    final padded = List<String>.from(capped);
    for (final line in _summaryExpansionLines(resume)) {
      if (padded.length >= _targetSummaryLinesMin) {
        break;
      }
      if (!padded.contains(line)) {
        padded.add(line);
      }
    }

    var index = 0;
    while (padded.length < _targetSummaryLinesMin) {
      padded.add(_genericSummaryExpansionLine(index, resume));
      index++;
    }

    return padded.take(_targetSummaryLinesMax).join('\n');
  }

  String _withoutCompanyNames(String value, ResumeData resume) {
    var result = value;
    for (final experience in resume.visibleWorkExperiences) {
      final company = experience.company.trim();
      if (company.isEmpty) {
        continue;
      }
      result = result.replaceAll(
        RegExp(RegExp.escape(company), caseSensitive: false),
        'the organization',
      );
    }
    return result
        .replaceAll(
          RegExp(r'\bat the organization\b', caseSensitive: false),
          'in that role',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _summaryExpansionLines(ResumeData resume) {
    final title = resume.jobTitle.trim().isEmpty
        ? 'their field'
        : resume.jobTitle.trim();
    final skills = resume.skills
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final skillPhrase = skills.isEmpty
        ? 'communication, prioritization, and steady execution'
        : skills.take(4).join(', ');

    return [
      'I stay calm under pressure and keep stakeholders aligned when priorities shift.',
      'Colleagues describe me as thoughtful, dependable, and easy to partner with across functions.',
      'I take time to understand the problem behind the request before proposing a path forward.',
      'Whether the work is strategic or hands-on, I focus on outcomes that are useful, measurable, and easy to explain.',
      'My experience in $title has strengthened how I plan work, communicate tradeoffs, and follow through.',
      'I am comfortable with ambiguity and turning loosely defined goals into clear milestones.',
      'Strengths in $skillPhrase show up in how I scope projects, review quality, and support teammates.',
      'I value feedback, iterate when new information appears, and keep documentation clear for the next person.',
    ];
  }

  String _genericSummaryExpansionLine(int index, ResumeData resume) {
    final title = resume.jobTitle.trim().isEmpty
        ? 'professional settings'
        : resume.jobTitle.trim();
    final variants = [
      'I bring a practical mindset to $title work and stay focused on what matters most to the team and end users.',
      'I am motivated by work where quality, clarity, and collaboration are shared responsibilities.',
      'I contribute early in planning so execution stays realistic and well supported.',
      'I am ready to add value quickly while learning the product, people, and priorities around me.',
    ];
    return variants[index % variants.length];
  }

  List<String> _composeSummaryLines(ResumeData resume, {int variantIndex = 0}) {
    final variant = variantIndex % _summaryVariantCount;
    final experiences = resume.visibleWorkExperiences
        .where((item) => !item.isBlank)
        .toList();
    final experienceHighlightIndex = experiences.isEmpty
        ? 0
        : variantIndex % experiences.length;

    final intro = _summaryIntroLine(resume, variant);
    final breadth = _summaryExperienceBreadthLine(resume, variant);
    final role = _summaryHighlightedRoleLine(
      resume,
      variant,
      experienceIndex: experienceHighlightIndex,
    );
    final titleFocus = _summaryTitleFocusLine(resume, variant);
    final context = _summaryContextLine(resume, variant);
    final closing = _summaryClosingLine(resume, variant);

    final blocks = <String>[
      intro,
      breadth,
      ?role,
      ?titleFocus,
      ?context,
      closing,
    ];

    return switch (variant) {
      1 => <String>[intro, ?titleFocus, ?context, ?role, closing],
      2 => <String>[intro, ?role, ?titleFocus, ?context, closing],
      3 => <String>[intro, ?context, ?titleFocus, ?role, closing],
      _ => blocks,
    };
  }

  String _summaryIntroLine(ResumeData resume, int variant) {
    final name = resume.fullName.trim();
    final title = resume.jobTitle.trim().isEmpty
        ? 'experienced contributor'
        : resume.jobTitle.trim();

    return switch (variant) {
      1 =>
        name.isEmpty
            ? 'I am a $title who enjoys turning messy problems into clear plans and steady results.'
            : "I'm $name, a $title who enjoys turning messy problems into clear plans and steady results.",
      2 =>
        name.isEmpty
            ? 'As a $title, I focus on practical delivery, honest communication, and work that holds up after launch.'
            : "I'm $name, a $title who focuses on practical delivery, honest communication, and work that holds up after launch.",
      3 =>
        name.isEmpty
            ? 'I work as a $title and care most about useful outcomes, reliable follow-through, and strong teamwork.'
            : "$name here — I work as a $title and care most about useful outcomes, reliable follow-through, and strong teamwork.",
      _ =>
        name.isEmpty
            ? 'I am an $title focused on dependable delivery, clear communication, and collaborative work.'
            : "I'm $name, an $title focused on dependable delivery, clear communication, and collaborative work.",
    };
  }

  String _summaryExperienceBreadthLine(ResumeData resume, int variant) {
    final experiences = resume.visibleWorkExperiences
        .where((item) => !item.isBlank)
        .toList();

    if (experiences.isEmpty) {
      return switch (variant) {
        1 =>
          'I learn quickly, clarify expectations early, and follow through in ways teammates can rely on.',
        2 =>
          'I am comfortable ramping on new tools and workflows while keeping stakeholders informed.',
        3 =>
          'I stay organized, ask thoughtful questions, and translate goals into work that is easy to review.',
        _ =>
          'I pick up context quickly, ask the right questions early, and turn goals into work teammates can trust.',
      };
    }

    final countLabel =
        '${experiences.length} ${experiences.length == 1 ? 'role' : 'roles'}';
    return switch (variant) {
      1 =>
        'Over the last few years, I have grown through $countLabel with increasing ownership and clearer communication.',
      2 =>
        'My recent work spans $countLabel where planning, execution, and stakeholder alignment all mattered.',
      3 =>
        "I've learned the most in settings with real ownership — across $countLabel, that's been the common thread.",
      _ =>
        'Across $countLabel, I have built depth in planning, delivery, and the communication that keeps projects moving.',
    };
  }

  String? _summaryHighlightedRoleLine(
    ResumeData resume,
    int variant, {
    required int experienceIndex,
  }) {
    final experiences = resume.visibleWorkExperiences
        .where((item) => !item.isBlank)
        .toList();
    if (experiences.isEmpty) {
      return null;
    }

    final experience = experiences[experienceIndex % experiences.length];
    final role = experience.role.trim().isEmpty
        ? 'Contributor'
        : experience.role.trim();
    final dateRange = [
      experience.startDate.trim(),
      experience.endDate.trim(),
    ].where((item) => item.isNotEmpty).join(' – ');
    final evidenceSource = [...experience.bullets, experience.description]
        .map((item) => _firstMeaningfulSentence(item))
        .firstWhere((item) => item.trim().isNotEmpty, orElse: () => '');
    final evidence = evidenceSource.isEmpty
        ? 'delivered meaningful results with clear ownership and steady follow-through'
        : _summaryEvidencePhrase(evidenceSource);
    final dateSuffix = dateRange.isEmpty ? '' : ' ($dateRange)';

    return switch (variant) {
      1 => 'Most recently, I worked as a $role$dateSuffix and $evidence.',
      2 => 'In my $role role$dateSuffix, I $evidence.',
      3 => 'Serving as a $role$dateSuffix, I $evidence.',
      _ => 'As a $role$dateSuffix, I $evidence.',
    };
  }

  String? _summaryTitleFocusLine(ResumeData resume, int variant) {
    final title = resume.jobTitle.trim();
    if (title.isEmpty) {
      return null;
    }

    final titleSkills = _jobTitleSkillSuggestions(title)
        .where((item) => item != 'Communication' && item != 'Problem Solving')
        .take(3)
        .toList();
    final focus = titleSkills.isEmpty
        ? 'clear ownership, practical execution, and measurable progress'
        : titleSkills.join(', ');

    return switch (variant) {
      1 =>
        'For $title roles, I bring energy around $focus and turn ambiguous needs into next steps people can act on.',
      2 =>
        'The $title work I want most is hands-on, collaborative, and centered on $focus.',
      3 =>
        'I approach $title responsibilities with curiosity, pace, and a strong bias for $focus.',
      _ =>
        'My $title focus combines $focus with clear communication and dependable follow-through.',
    };
  }

  String? _summaryContextLine(ResumeData resume, int variant) {
    final skills = resume.skills
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final education = resume.education
        .where(
          (item) =>
              item.institution.trim().isNotEmpty ||
              item.degree.trim().isNotEmpty,
        )
        .toList();
    final projects = resume.visibleProjects
        .where((item) => !item.isBlank)
        .toList();
    final titleSuggestions = _jobTitleSkillSuggestions(resume.jobTitle.trim());

    if (skills.isNotEmpty) {
      final skillList = skills.take(4).join(', ');
      return switch (variant) {
        1 =>
          "I'm strongest in $skillList, and I apply them where they improve quality, pace, and clarity.",
        2 =>
          'Core skills: $skillList — I lean on these daily when scoping work and partnering across teams.',
        3 =>
          'Day to day, $skillList are the tools I reach for most to keep work focused and outcomes measurable.',
        _ =>
          'My strengths include $skillList, and I use them to support quality and speed.',
      };
    }

    if (titleSuggestions.isNotEmpty) {
      final suggestions = titleSuggestions.take(4).join(', ');
      return switch (variant) {
        1 =>
          'I am comfortable with $suggestions and keep building depth through hands-on project work.',
        2 =>
          'I bring working knowledge of $suggestions and keep improving through practical delivery.',
        3 =>
          'Strengths around $suggestions show up in how I plan work, review quality, and support teammates.',
        _ =>
          'I am especially effective in $suggestions and keep sharpening those skills through real project work.',
      };
    }

    if (education.isNotEmpty) {
      final item = education.first;
      final institution = item.institution.trim();
      final degree = item.degree.trim();
      final educationPhrase = [
        if (degree.isNotEmpty) degree,
        if (institution.isNotEmpty) 'from $institution',
      ].join(' ');
      if (educationPhrase.isEmpty) {
        return null;
      }
      return switch (variant) {
        1 =>
          'My training in $educationPhrase informs how I structure problems and communicate with partners.',
        2 =>
          'Education in $educationPhrase gave me a solid foundation for analytical thinking and clear writing.',
        3 =>
          'With a background in $educationPhrase, I connect classroom concepts to practical team delivery.',
        _ =>
          'My background includes $educationPhrase, which shapes how I approach problems and communicate across teams.',
      };
    }

    if (projects.isEmpty) {
      return null;
    }

    final project = projects.first;
    final projectTitle = project.title.trim().isEmpty
        ? 'a recent project'
        : project.title.trim();
    final projectEvidence =
        [...project.bullets, project.overview, project.impact, project.subtitle]
            .map((item) => _firstMeaningfulSentence(item.toString()))
            .firstWhere((item) => item.trim().isNotEmpty, orElse: () => '');
    final projectDetail = projectEvidence.isEmpty
        ? 'showed initiative, sound judgment, and attention to detail'
        : _summaryEvidencePhrase(projectEvidence);

    return switch (variant) {
      1 => 'On $projectTitle, I $projectDetail.',
      2 => 'Through $projectTitle, I $projectDetail.',
      3 => 'A highlight project, $projectTitle, is where I $projectDetail.',
      _ => 'In $projectTitle, I $projectDetail.',
    };
  }

  String _summaryClosingLine(ResumeData resume, int variant) {
    final title = resume.jobTitle.trim().isEmpty
        ? 'experienced contributor'
        : resume.jobTitle.trim();

    return switch (variant) {
      1 =>
        "I'm interested in $title opportunities where I can add value quickly and keep growing.",
      2 =>
        "Next, I'm aiming for $title roles with clear goals, strong collaborators, and room to keep learning.",
      3 =>
        "I'm open to $title roles where thoughtful execution and good communication are part of the job.",
      _ =>
        'I am looking for roles where I can contribute as a $title and keep growing through clear, challenging work.',
    };
  }

  String _buildSummary(
    ResumeData resume, {
    bool regenerate = false,
    int attemptIndex = 0,
  }) {
    final variantIndex = regenerate ? attemptIndex % _summaryVariantCount : 0;
    final composed = _composeSummaryLines(
      resume,
      variantIndex: variantIndex,
    ).join('\n');
    return _finalizeSummaryLines(composed, resume);
  }

  String _buildTailoredSummary({
    required ResumeData resume,
    required String targetJobTitle,
    required List<String> keywords,
    String jobDescription = '',
  }) {
    final name = resume.fullName.trim().isEmpty
        ? 'This candidate'
        : resume.fullName.trim();
    final roleFromPosting = jobDescription.trim().isEmpty
        ? null
        : _jobTitleFromJobDescription(jobDescription);
    final role = (roleFromPosting ?? targetJobTitle).trim().isEmpty
        ? 'professional candidate'
        : (roleFromPosting ?? targetJobTitle).trim();
    final primarySkills = resume.skills.take(4).join(', ');
    final atsSkillLine = keywords.take(5).join(', ');
    final existingSummaryPhrase = _firstMeaningfulSentence(resume.summary);
    final workEvidence = resume.visibleWorkExperiences
        .expand((item) => [item.description, ...item.bullets])
        .map(_firstMeaningfulSentence)
        .where((item) => item.isNotEmpty)
        .take(2)
        .map(_normalizeSentenceForResume)
        .join(' ');
    final keywordPhrase = keywords.take(4).join(', ');
    final experiencePhrase = workEvidence.isNotEmpty
        ? workEvidence
        : existingSummaryPhrase;
    final evidenceClause = experiencePhrase.isNotEmpty
        ? _normalizeSentenceForResume(experiencePhrase)
        : 'Delivered measurable results through cross-functional collaboration.';

    final skillsClause = atsSkillLine.isNotEmpty
        ? atsSkillLine
        : (primarySkills.isEmpty
              ? 'delivery, collaboration, and execution'
              : primarySkills);

    return '$name is a $role with hands-on experience in $skillsClause. '
        '${keywordPhrase.isEmpty ? '' : 'Well aligned to opportunities requiring $keywordPhrase. '}'
        '$evidenceClause';
  }

  List<String> _buildJobBullets({
    required String role,
    required String company,
    required String targetJobTitle,
  }) {
    final focus = _jobTitleSkillSuggestions(
      targetJobTitle,
    ).take(2).join(' and ');
    final normalizedRole = role.trim().isEmpty
        ? 'team member'
        : role.trim().toLowerCase();
    final normalizedCompany = company.trim().isEmpty
        ? 'the organization'
        : company.trim();
    final roleText = role.trim().isEmpty ? 'Contributor' : role.trim();

    final isTechnical = RegExp(
      r'developer|engineer|programmer|architect|devops|data|analyst|mobile|flutter|ios|android',
      caseSensitive: false,
    ).hasMatch(roleText);
    final isDesign = RegExp(
      r'design|designer|ux|ui|product',
      caseSensitive: false,
    ).hasMatch(roleText);

    if (isTechnical) {
      return [
        'Delivered scoped features and fixes as $normalizedRole at $normalizedCompany, improving release quality and maintainability.',
        focus.isEmpty
            ? 'Collaborated with product and QA to ship roadmap work on schedule.'
            : 'Used $focus to build reliable solutions and support cross-functional delivery.',
      ];
    }
    if (isDesign) {
      return [
        'Created user-centered deliverables as $normalizedRole at $normalizedCompany, from discovery through handoff.',
        focus.isEmpty
            ? 'Partnered with engineering and product to iterate on flows and UI quality.'
            : 'Applied $focus to improve usability and design consistency across releases.',
      ];
    }

    return [
      'Owned key deliverables as $normalizedRole at $normalizedCompany, improving team throughput and stakeholder visibility.',
      focus.isEmpty
          ? 'Coordinated cross-functional work to meet deadlines with clear communication.'
          : 'Applied $focus to drive measurable outcomes for the business.',
    ];
  }

  String _polishBulletForAts(
    String bullet, {
    List<String> keywords = const [],
  }) {
    final polished = _normalizeSentenceForResume(
      bullet,
      prefix: _atsActionPrefixForBullet(bullet),
    );
    if (keywords.isEmpty) {
      return polished;
    }

    final lower = polished.toLowerCase();
    final missing =
        keywords
            .map((keyword) => keyword.trim())
            .where((keyword) => keyword.isNotEmpty)
            .where((keyword) => !lower.contains(keyword.toLowerCase()))
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    if (missing.isEmpty) {
      return polished;
    }
    missing.removeRange(1, missing.length);
    final keyword = missing.first;
    final body = polished.replaceAll(RegExp(r'[.!?]+$'), '');
    if (RegExp(
      r'\b(led|built|delivered|implemented|improved|managed)\b',
      caseSensitive: false,
    ).hasMatch(body)) {
      return '$body, applying $keyword to improve outcomes.';
    }
    return '$body, with demonstrated experience in $keyword.';
  }

  List<String> _tailorWorkExperienceBullets({
    required WorkExperience item,
    required String targetJobTitle,
    required List<String> keywords,
    bool weaveJobKeywords = false,
  }) {
    final existingBullets = item.bullets
        .map((bullet) => bullet.trim())
        .where((bullet) => bullet.isNotEmpty)
        .toList();
    final keywordsToWeave = weaveJobKeywords ? keywords : const <String>[];

    if (existingBullets.length >= 2 &&
        existingBullets.where((bullet) => bullet.length > 40).length >= 2) {
      return existingBullets
          .map(
            (bullet) => _polishBulletForAts(bullet, keywords: keywordsToWeave),
          )
          .take(4)
          .toList();
    }

    final descriptionBullets = _descriptionDrivenBullets(
      description: item.description,
      role: item.role,
      company: item.company,
      keywords: keywords,
      weaveKeywords: weaveJobKeywords,
    );
    final polishedExisting = existingBullets
        .map((bullet) => _polishBulletForAts(bullet, keywords: keywordsToWeave))
        .toList();

    final merged = <String>[...descriptionBullets, ...polishedExisting];

    if (merged.isEmpty) {
      return _buildJobBullets(
        role: item.role,
        company: item.company,
        targetJobTitle: targetJobTitle,
      );
    }

    final seen = <String>{};
    final normalized = <String>[];
    for (final bullet in merged) {
      final key = bullet.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      normalized.add(bullet);
    }
    return normalized.take(4).toList();
  }

  bool _unorderedListEquals(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    final normalizedLeft = [...left]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final normalizedRight = [...right]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (var index = 0; index < normalizedLeft.length; index++) {
      if (normalizedLeft[index] != normalizedRight[index]) {
        return false;
      }
    }
    return true;
  }

  List<String> _descriptionDrivenBullets({
    required String description,
    required String role,
    required String company,
    required List<String> keywords,
    bool weaveKeywords = false,
  }) {
    final cleanedDescription = description.trim();
    if (cleanedDescription.isEmpty) {
      return const [];
    }

    final sentences = cleanedDescription
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map(_firstMeaningfulSentence)
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList();

    final bullets = sentences
        .map(_normalizeSentenceForResume)
        .where((bullet) => bullet.isNotEmpty)
        .toList();

    if (!weaveKeywords || keywords.isEmpty || bullets.isEmpty) {
      return bullets;
    }

    final combined = bullets.join(' ').toLowerCase();
    final missing =
        keywords
            .map((keyword) => keyword.trim())
            .where((keyword) => keyword.isNotEmpty)
            .where((keyword) => !combined.contains(keyword.toLowerCase()))
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    if (missing.isEmpty) {
      return bullets;
    }
    missing.removeRange(1, missing.length);
    final lastIndex = bullets.length - 1;
    final body = bullets[lastIndex].replaceAll(RegExp(r'[.!?]+$'), '');
    bullets[lastIndex] =
        '$body, applying ${missing.first} in production delivery.';
    return bullets;
  }

  String? _jobTitleFromJobDescription(String jobDescription) {
    final normalized = jobDescription.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return null;
    }

    final patterns = <RegExp>[
      RegExp(
        r'(?:hiring|seeking|looking for|need)\s+(?:a|an)?\s*([A-Za-z][A-Za-z0-9 /,&+\-]{2,55}?)(?:\s+with\b|\s+who\b|\.|,|\s+to\b)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:job title|position|role)\s*[:.\-]\s*([^\n.]{3,60})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(normalized);
      if (match == null) {
        continue;
      }
      var title = match.group(1)!.trim();
      title = title.replaceAll(RegExp(r'\s+'), ' ');
      if (title.length < 3 || title.split(' ').length > 8) {
        continue;
      }
      return title[0].toUpperCase() + title.substring(1);
    }
    return null;
  }

  List<String> _atsKeywordsFromJobDescription({
    required String jobDescription,
    required List<String> missingFromResume,
  }) {
    final ordered = <String>[];
    final seen = <String>{};

    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      if (seen.add(trimmed.toLowerCase())) {
        ordered.add(trimmed);
      }
    }

    for (final keyword in missingFromResume) {
      add(keyword);
    }

    final phrasePatterns = <RegExp>[
      RegExp(r'\bREST\s*/?\s*APIs?\b', caseSensitive: false),
      RegExp(r'\bstakeholder\s+communication\b', caseSensitive: false),
      RegExp(r'\bcross[- ]functional\b', caseSensitive: false),
      RegExp(r'\bcontinuous\s+integration\b', caseSensitive: false),
      RegExp(r'\bCI/?CD\b', caseSensitive: false),
      RegExp(r'\bagile(?:\s+methodology)?\b', caseSensitive: false),
      RegExp(r'\bunit\s+tests?\b', caseSensitive: false),
      RegExp(r'\bversion\s+control\b', caseSensitive: false),
      RegExp(r'\bproblem[- ]solving\b', caseSensitive: false),
      RegExp(r'\btime\s+management\b', caseSensitive: false),
    ];
    for (final pattern in phrasePatterns) {
      final match = pattern.firstMatch(jobDescription);
      if (match != null) {
        add(match.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim());
      }
    }

    for (final keyword in _prepareTargetKeywords(
      _extractKeywords(jobDescription),
    )) {
      if (keyword.length < 4 &&
          ordered.any(
            (item) => item.toLowerCase().contains(keyword.toLowerCase()),
          )) {
        continue;
      }
      add(keyword);
    }

    return _preferLongerKeywordPhrases(ordered.take(10).toList());
  }

  List<String> _preferLongerKeywordPhrases(List<String> keywords) {
    return keywords.where((keyword) {
      final lower = keyword.toLowerCase();
      if (lower == 'rest' || lower == 'api' || lower == 'apis') {
        return !keywords.any((item) => item.toLowerCase().contains('rest api'));
      }
      return true;
    }).toList();
  }

  List<String> _keywordsForWorkEntry({
    required int entryIndex,
    required int? primaryIndex,
    required List<String> allKeywords,
  }) {
    if (allKeywords.isEmpty) {
      return const [];
    }
    final start = entryIndex == primaryIndex ? 0 : 1;
    return [
      allKeywords[start % allKeywords.length],
      if (allKeywords.length > 1) allKeywords[(start + 1) % allKeywords.length],
    ];
  }

  List<String> _orderSkillsForAts({
    required List<String> skills,
    required List<String> priorityKeywords,
  }) {
    final priority = <String>[];
    final rest = <String>[];
    final seen = <String>{};

    for (final keyword in priorityKeywords) {
      for (final skill in skills) {
        if (skill.toLowerCase().contains(keyword.toLowerCase()) &&
            seen.add(skill.toLowerCase())) {
          priority.add(skill);
          break;
        }
      }
    }

    for (final skill in skills) {
      if (seen.add(skill.toLowerCase())) {
        rest.add(skill);
      }
    }

    return [...priority, ...rest];
  }

  String? _atsActionPrefixForBullet(String bullet) {
    final trimmed = bullet.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (RegExp(
      r'^(built|delivered|led|managed|implemented|designed|developed|created|improved|reduced|increased|launched|optimized|automated|coordinated|partnered)\b',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return null;
    }
    if (RegExp(
      r'^(maintained|supported|helped|worked|assisted|participated)\b',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return null;
    }
    return 'Led';
  }

  String _firstMeaningfulSentence(String input) {
    final normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '';
    }

    final fragments = normalized
        .split(RegExp(r'(?<=[.!?])\s+|;\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return fragments.isEmpty ? normalized : fragments.first;
  }

  String _normalizeSentenceForResume(String sentence, {String? prefix}) {
    var normalized = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
    normalized = normalized.replaceFirst(RegExp(r'^[•\-–]+\s*'), '');
    normalized = normalized.replaceFirst(
      RegExp(
        r'^(responsible for|worked on|handled|helped with|assisted with|involved in)\s+',
        caseSensitive: false,
      ),
      '',
    );
    if (normalized.isEmpty) {
      return prefix?.trim() ?? '';
    }

    normalized = normalized.replaceFirst(RegExp(r'[.!?]+$'), '');
    final standalone =
        normalized[0].toUpperCase() + normalized.substring(1).trimLeft();
    final prefixed =
        normalized[0].toLowerCase() + normalized.substring(1).trimLeft();
    final base = prefix == null || prefix.trim().isEmpty
        ? standalone
        : '${prefix.trim()} $prefixed';
    return base.endsWith('.') ? base : '$base.';
  }

  String _normalizeResumeFragment(String sentence) {
    var normalized = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
    normalized = normalized.replaceFirst(RegExp(r'^[•\-–]+\s*'), '');
    normalized = normalized.replaceFirst(RegExp(r'[.!?]+$'), '');
    if (normalized.isEmpty) {
      return 'delivery, collaboration, and measurable execution';
    }
    return normalized[0].toLowerCase() + normalized.substring(1).trimLeft();
  }

  List<String> _prepareTargetKeywords(Iterable<String> keywords) {
    final raw = keywords
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final prepared = <String>[];
    for (var index = 0; index < raw.length; index++) {
      final current = raw[index];
      final currentLower = current.toLowerCase();
      final nextLower = index + 1 < raw.length
          ? raw[index + 1].toLowerCase()
          : '';

      if (currentLower == 'rest' && nextLower == 'apis') {
        prepared.add('REST APIs');
        index++;
        continue;
      }
      if (currentLower == 'stakeholder' && nextLower == 'communication') {
        prepared.add('stakeholder communication');
        index++;
        continue;
      }
      if (currentLower == 'cross' && nextLower == 'functional') {
        prepared.add('cross-functional');
        index++;
        continue;
      }
      if (currentLower == 'project' && nextLower == 'management') {
        prepared.add('project management');
        index++;
        continue;
      }
      if (currentLower == 'data' && nextLower == 'analysis') {
        prepared.add('data analysis');
        index++;
        continue;
      }
      if (currentLower == 'machine' && nextLower == 'learning') {
        prepared.add('machine learning');
        index++;
        continue;
      }
      if (currentLower == 'problem' && nextLower == 'solving') {
        prepared.add('problem-solving');
        index++;
        continue;
      }
      prepared.add(current);
    }
    return prepared;
  }

  List<String> _resumeSkillSuggestions({
    required ResumeData resume,
    String? targetJobTitle,
  }) {
    final suggestions = <String>[];
    final titleSources = <String>[];
    final seenTitleSources = <String>{};

    void addTitleSource(String value, {bool ignoreDefaultTitle = false}) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      if (ignoreDefaultTitle && trimmed == ResumeData.defaultTitle) {
        return;
      }

      if (seenTitleSources.add(trimmed.toLowerCase())) {
        titleSources.add(trimmed);
      }
    }

    addTitleSource(resume.title, ignoreDefaultTitle: true);
    addTitleSource(resume.jobTitle);
    addTitleSource(targetJobTitle ?? '');

    void addSuggestions(Iterable<String> values) {
      for (final value in values) {
        if (!suggestions.contains(value)) {
          suggestions.add(value);
        }
      }
    }

    // 1. Role-based skills from each work experience job title.
    for (final item in resume.visibleWorkExperiences) {
      addSuggestions(_jobTitleSkillSuggestions(item.role));
    }

    // 2. Keywords from work experience text (role, company, description, bullets).
    final workOnlyContext = resume.visibleWorkExperiences
        .expand(
          (item) => [
            item.role,
            item.company,
            item.description,
            ...item.bullets,
          ],
        )
        .where((item) => item.trim().isNotEmpty)
        .join(' ')
        .toLowerCase();
    _addSkillsMatchingContext(workOnlyContext, addSuggestions);

    // 3. Full resume: summary, education, projects, target role, etc.
    final combinedContext = <String>[
      ...titleSources,
      resume.summary,
      ...resume.skills,
      ...resume.visibleWorkExperiences.expand(
        (item) => [item.role, item.company, item.description, ...item.bullets],
      ),
      ...resume.visibleEducation.expand(
        (item) => [
          item.institution,
          item.degree,
          item.startDate,
          item.endDate,
          item.score,
        ],
      ),
      ...resume.visibleProjects.expand(
        (item) => [
          item.title,
          item.subtitle,
          item.overview,
          item.impact,
          ...item.bullets,
        ],
      ),
      ...resume.visibleCustomSections.expand(
        (section) => [
          section.title,
          ...switch (section.layoutMode) {
            CustomSectionLayoutMode.summary => [section.content],
            CustomSectionLayoutMode.bullets => section.bullets,
            CustomSectionLayoutMode.projects =>
              section.visibleProjectEntries
                  .expand(
                    (entry) => [
                      entry.title,
                      entry.subtitle,
                      entry.overview,
                      entry.impact,
                      ...entry.bullets,
                    ],
                  )
                  .toList(),
          },
        ],
      ),
    ].where((item) => item.trim().isNotEmpty).join(' ').toLowerCase();

    _addSkillsMatchingContext(combinedContext, addSuggestions);

    // 4. Document title and target job title (deduped).
    for (final titleSource in titleSources) {
      addSuggestions(_jobTitleSkillSuggestions(titleSource));
    }

    if (suggestions.isEmpty) {
      addSuggestions(const [
        'Communication',
        'Problem Solving',
        'Cross-functional Collaboration',
      ]);
    }

    return suggestions.take(8).toList();
  }

  List<String> _jobTitleSkillSuggestions(String jobTitle) {
    final normalized = jobTitle.toLowerCase();
    final suggestions = <String>{'Communication', 'Problem Solving'};

    if (normalized.contains('designer')) {
      suggestions.addAll([
        'Figma',
        'Design Systems',
        'User Research',
        'Wireframing',
        'Prototyping',
        'Accessibility',
      ]);
    } else if (normalized.contains('product')) {
      suggestions.addAll([
        'Product Strategy',
        'Stakeholder Management',
        'Roadmapping',
        'A/B Testing',
        'SQL',
        'Analytics',
        'Experiment Design',
      ]);
    } else if (normalized.contains('data scientist') ||
        normalized.contains('data science') ||
        normalized.contains('machine learning') ||
        normalized.contains(' ml ') ||
        normalized.startsWith('ml ') ||
        normalized.contains('research scientist')) {
      suggestions.addAll([
        'Python',
        'SQL',
        'Machine Learning',
        'Statistics',
        'Experiment Design',
        'Data Visualization',
      ]);
    } else if (normalized.contains('analyst') ||
        normalized.contains('analytics')) {
      suggestions.addAll([
        'SQL',
        'Analytics',
        'Data Visualization',
        'A/B Testing',
        'Excel',
        'Dashboarding',
      ]);
    } else if (normalized.contains('devops') ||
        normalized.contains('sre') ||
        normalized.contains('platform engineer') ||
        normalized.contains('site reliability')) {
      suggestions.addAll([
        'CI/CD',
        'Docker',
        'Kubernetes',
        'AWS',
        'Infrastructure as Code',
        'Monitoring',
      ]);
    } else if (normalized.contains('qa') ||
        normalized.contains('quality engineer') ||
        normalized.contains('test engineer')) {
      suggestions.addAll([
        'Unit Testing',
        'Test Automation',
        'CI/CD',
        'Documentation',
      ]);
    } else if (normalized.contains('intern') ||
        normalized.contains('student') ||
        normalized.contains('undergraduate') ||
        normalized.contains('graduate') ||
        normalized.contains('fresher')) {
      suggestions.addAll([
        'Data Structures and Algorithms',
        'Object-Oriented Programming',
        'SQL',
        'Git',
        'Unit Testing',
        'Debugging',
      ]);
    } else if (normalized.contains('engineer') ||
        normalized.contains('developer')) {
      suggestions.addAll([
        'Flutter',
        'Dart',
        'REST APIs',
        'State Management',
        'CI/CD',
        'Unit Testing',
      ]);
    } else if (normalized.contains('marketing')) {
      suggestions.addAll([
        'Campaign Strategy',
        'SEO',
        'Content Planning',
        'Performance Marketing',
        'CRM',
      ]);
    } else {
      suggestions.addAll([
        'Project Management',
        'Cross-functional Collaboration',
        'Documentation',
        'Presentation Skills',
      ]);
    }

    return suggestions.toList();
  }

  /// Keyword-based skills inferred from free text (job descriptions, bullets, etc.).
  void _addSkillsMatchingContext(
    String contextLower,
    void Function(Iterable<String>) addSuggestions,
  ) {
    if (_containsAny(contextLower, ['flutter', 'dart'])) {
      addSuggestions(['Flutter', 'Dart']);
    }
    if (_containsAny(contextLower, ['mobile', 'android', 'ios', 'app store'])) {
      addSuggestions(['Mobile App Development']);
    }
    if (_containsAny(contextLower, ['rest api', 'restful', 'api', 'graphql'])) {
      addSuggestions(['REST APIs', 'API Integration']);
    }
    if (_containsAny(contextLower, [
      'provider',
      'bloc',
      'riverpod',
      'state management',
    ])) {
      addSuggestions(['State Management']);
    }
    if (_containsAny(contextLower, ['firebase'])) {
      addSuggestions(['Firebase']);
    }
    if (_containsAny(contextLower, ['unit test', 'widget test', 'testing'])) {
      addSuggestions(['Unit Testing']);
    }
    if (_containsAny(contextLower, [
      'deploy',
      'release',
      'ci/cd',
      'pipeline',
    ])) {
      addSuggestions(['CI/CD']);
    }
    if (_containsAny(contextLower, ['react', 'next.js', 'nextjs'])) {
      addSuggestions(['React']);
    }
    if (_containsAny(contextLower, ['javascript'])) {
      addSuggestions(['JavaScript']);
    }
    if (_containsAny(contextLower, ['typescript'])) {
      addSuggestions(['TypeScript']);
    }
    if (_containsAny(contextLower, ['figma', 'wireframe', 'prototype'])) {
      addSuggestions(['Figma', 'Wireframing', 'Prototyping']);
    }
    if (_containsAny(contextLower, [
      'design system',
      'ui kit',
      'component library',
    ])) {
      addSuggestions(['Design Systems']);
    }
    if (_containsAny(contextLower, [
      'user research',
      'user interview',
      'usability',
    ])) {
      addSuggestions(['User Research']);
    }
    if (_containsAny(contextLower, ['sql', 'query', 'database', 'warehouse'])) {
      addSuggestions(['SQL', 'Data Analysis']);
    }
    if (_containsAny(contextLower, [
      'dashboard',
      'analytics',
      'metric',
      'kpi',
    ])) {
      addSuggestions(['Analytics', 'Dashboarding']);
    }
    if (_containsAny(contextLower, ['a/b test', 'ab test', 'experiment'])) {
      addSuggestions(['A/B Testing', 'Experiment Design']);
    }
    if (_containsAny(contextLower, [
      'roadmap',
      'product strategy',
      'backlog',
    ])) {
      addSuggestions(['Roadmapping', 'Product Strategy']);
    }
    if (_containsAny(contextLower, [
      'stakeholder',
      'client',
      'cross-functional',
      'cross functional',
    ])) {
      addSuggestions([
        'Stakeholder Management',
        'Cross-functional Collaboration',
      ]);
    }
    if (_containsAny(contextLower, [
      'document',
      'documentation',
      'report',
      'spec',
    ])) {
      addSuggestions(['Documentation']);
    }
    if (_containsAny(contextLower, [
      'launch',
      'delivery',
      'deliver',
      'execution',
    ])) {
      addSuggestions(['Project Management', 'Execution']);
    }
    if (_containsAny(contextLower, [
      'process improvement',
      'workflow',
      'automation',
      'streamline',
    ])) {
      addSuggestions(['Process Improvement']);
    }
    if (_containsAny(contextLower, [
      'presentation',
      'presented',
      'training',
      'enablement',
    ])) {
      addSuggestions(['Presentation Skills']);
    }
    if (_containsAny(contextLower, ['seo', 'campaign', 'content', 'crm'])) {
      addSuggestions(['SEO', 'Campaign Strategy', 'Content Planning']);
    }
  }

  bool _containsAny(String value, List<String> needles) {
    for (final needle in needles) {
      if (value.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  Iterable<String> _extractKeywords(String input) sync* {
    final commonWords = {
      'with',
      'that',
      'from',
      'this',
      'your',
      'their',
      'will',
      'have',
      'about',
      'using',
      'years',
      'ability',
      'team',
      'work',
      'role',
      'mobile',
      'application',
      'applications',
      'apps',
      'experience',
      'hiring',
      'looking',
      'seeking',
      'candidate',
      'candidates',
      'position',
      'opportunity',
      'opening',
      'ideal',
      'apply',
      'join',
      'strong',
      'developer',
      'engineer',
      'manager',
      'analyst',
      'designer',
      'specialist',
      'associate',
      'executive',
      'responsible',
      'preferred',
      'required',
    };

    final matches = RegExp(r'[A-Za-z][A-Za-z+/&-]{3,}').allMatches(input);
    final unique = <String>{};
    for (final match in matches) {
      final keyword = match.group(0)!.trim();
      final lower = keyword.toLowerCase();
      if (!commonWords.contains(lower) && unique.add(keyword)) {
        yield keyword;
      }
    }
  }

  _CoverLetterInputs _coverLetterInputsFromResume({
    required ResumeData resume,
    required String company,
    required String role,
    required String skillToHighlight,
    required String language,
  }) {
    final languageBase = _coverLetterLanguageName(language);
    final languageNative = _coverLetterLanguageNativeName(language);
    final companyName = company.trim().isEmpty ? 'the company' : company.trim();
    final roleName = role.trim().isEmpty ? 'the role' : role.trim();
    final highlightedSkills = skillToHighlight
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final resumeSkills = resume.skills
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final skillPool = highlightedSkills.isNotEmpty
        ? highlightedSkills
        : resumeSkills;
    final primarySkill = skillPool.isEmpty
        ? roleName
        : _joinNaturalListLocalized(
            skillPool.take(4).toList(),
            languageBase.isEmpty ? 'English' : languageBase,
          );
    final backgroundRole = resume.jobTitle.trim().isEmpty
        ? 'a professional'
        : resume.jobTitle.trim();
    final summaryHook = _summaryHookFromResume(resume);
    final workExperiences = resume.visibleWorkExperiences
        .where((item) => !item.isBlank)
        .toList();

    final fullName = resume.fullName.trim();
    final location = resume.location.trim();
    final email = resume.email.trim();
    final phone = resume.phone.trim();

    return _CoverLetterInputs(
      senderName: fullName.isEmpty ? '[Your Name]' : fullName,
      addressLine: location.isEmpty ? '[Your Address]' : location,
      cityLine: location.isEmpty ? '[City, State, Zip Code]' : location,
      emailLine: email.isEmpty ? '[Email Address]' : email,
      phoneLine: phone.isEmpty ? '[Phone Number]' : phone,
      companyName: companyName,
      roleName: roleName,
      primarySkill: primarySkill,
      backgroundRole: backgroundRole,
      language: language,
      languageBase: languageBase,
      languageNative: languageNative,
      summaryHook: summaryHook,
      workExperiences: workExperiences,
      evidenceLineBuilder: (variant) => _coverLetterExperienceEvidenceLine(
        workExperiences: workExperiences,
        backgroundRole: backgroundRole,
        variant: variant,
      ),
    );
  }

  String _summaryHookFromResume(ResumeData resume) {
    final summary = resume.summary.trim();
    if (summary.isEmpty) {
      return '';
    }
    final sentence = _firstMeaningfulSentence(summary);
    if (sentence.isEmpty) {
      return '';
    }
    final normalized = _normalizeSentenceForResume(sentence);
    if (RegExp(r'^I\b', caseSensitive: false).hasMatch(normalized)) {
      return normalized.endsWith('.') ? normalized : '$normalized.';
    }
    final lowered = normalized[0].toLowerCase() + normalized.substring(1);
    return 'A thread through my work is that I $lowered';
  }

  String _coverLetterExperienceEvidenceLine({
    required List<WorkExperience> workExperiences,
    required String backgroundRole,
    required int variant,
  }) {
    if (workExperiences.isEmpty) {
      return '';
    }
    final experience = workExperiences[variant % workExperiences.length];
    final roleLabel = experience.role.trim().isEmpty
        ? backgroundRole
        : experience.role.trim();
    final companyLabel = experience.company.trim().isEmpty
        ? 'a previous team'
        : experience.company.trim();
    final bullet = [experience.description, ...experience.bullets]
        .map(_firstMeaningfulSentence)
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    if (bullet.isEmpty) {
      return 'Most recently, I worked as $roleLabel at $companyLabel.';
    }
    final normalized = _normalizeSentenceForResume(bullet);
    final lowered = normalized[0].toLowerCase() + normalized.substring(1);
    return 'In my role as $roleLabel at $companyLabel, $lowered';
  }

  Future<T> _simulate<T>(T Function() action) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return action();
  }
}

class _CoverLetterInputs {
  const _CoverLetterInputs({
    required this.senderName,
    required this.addressLine,
    required this.cityLine,
    required this.emailLine,
    required this.phoneLine,
    required this.companyName,
    required this.roleName,
    required this.primarySkill,
    required this.backgroundRole,
    required this.language,
    required this.languageBase,
    required this.languageNative,
    required this.summaryHook,
    required this.workExperiences,
    required this.evidenceLineBuilder,
  });

  final String senderName;
  final String addressLine;
  final String cityLine;
  final String emailLine;
  final String phoneLine;
  final String companyName;
  final String roleName;
  final String primarySkill;
  final String backgroundRole;
  final String language;
  final String languageBase;
  final String languageNative;
  final String summaryHook;
  final List<WorkExperience> workExperiences;
  final String Function(int variant) evidenceLineBuilder;

  String experienceEvidenceLine(int variant) => evidenceLineBuilder(variant);
}

class _CoverLetterLocale {
  const _CoverLetterLocale({
    required this.hiringManager,
    required this.greeting,
    required this.opening,
    required this.fit,
    required this.strengths,
    required this.closing,
    required this.sincerely,
    required this.languageSentence,
  });

  const _CoverLetterLocale.english()
    : hiringManager = 'Hiring Manager',
      greeting = 'Dear Hiring Manager,',
      opening = _englishOpening,
      fit = _englishFit,
      strengths = _englishStrengths,
      closing = _englishClosing,
      sincerely = 'Sincerely,',
      languageSentence = _englishLanguageSentence;

  final String hiringManager;
  final String greeting;
  final String Function(String role, String company) opening;
  final String Function(String role, String primarySkill) fit;
  final String Function(String languageSentence) strengths;
  final String Function(String company, String role) closing;
  final String sincerely;
  final String Function(String language) languageSentence;

  static String _englishOpening(String role, String company) {
    return 'I am writing to express my interest in the $role position at $company. I am interested in this opportunity because it appears to value professionalism, reliability, and the ability to contribute meaningfully from day one.';
  }

  static String _englishFit(String role, String primarySkill) {
    return 'I believe I would be a strong fit for this role because I can bring a focused approach to $primarySkill, along with a willingness to learn quickly, adapt to team needs, and support high-quality work in a consistent way.';
  }

  static String _englishStrengths(String languageSentence) {
    return 'I would bring strong communication, organization, and problem-solving skills to the role, and I would approach the responsibilities of this position with care, accountability, and attention to detail.$languageSentence';
  }

  static String _englishClosing(String company, String role) {
    return 'I would welcome the opportunity to contribute to $company as a $role. Thank you for considering my application. I look forward to the possibility of discussing how I can support your team.';
  }

  static String _englishLanguageSentence(String language) {
    return ' I can also communicate effectively in $language, which would help me collaborate clearly in this role.';
  }
}

/// Body/heading/name point sizes used when rendering cover letter PDFs.
@immutable
class CoverLetterPdfTypography {
  const CoverLetterPdfTypography({
    required this.bodyPt,
    required this.headingPt,
    required this.namePt,
  });

  final double bodyPt;
  final double headingPt;
  final double namePt;
}

class ResumePdfService {
  InterPdfFonts? _interPdfFontsCache;
  CalibriPdfFonts? _calibriPdfFontsCache;
  GaramondPdfFonts? _garamondPdfFontsCache;
  ArimoPdfFonts? _arimoPdfFontsCache;

  Future<InterPdfFonts> _ensureInterPdfFonts() async {
    return _interPdfFontsCache ??= await loadInterPdfFonts();
  }

  Future<CalibriPdfFonts> _ensureCalibriPdfFonts() async {
    return _calibriPdfFontsCache ??= await loadCalibriPdfFonts();
  }

  Future<GaramondPdfFonts> _ensureGaramondPdfFonts() async {
    return _garamondPdfFontsCache ??= await loadGaramondPdfFonts();
  }

  Future<ArimoPdfFonts> _ensureArimoPdfFonts() async {
    return _arimoPdfFontsCache ??= await loadArimoPdfFonts();
  }

  Future<Uint8List> buildPdf(ResumeData resume) async {
    final profileImagePath = await ProfileImageStorage.resolvePath(
      resume.profileImagePath,
      resume.id,
    );
    final profileImage = await _loadProfileImage(profileImagePath);

    if (resume.template == ResumeTemplate.creative) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addCreativeTemplatePage(
        document,
        resume,
        garamond: garamond,
        profileImage: profileImage,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.classicSidebar) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addClassicSidebarTemplatePage(
        document,
        resume,
        garamond: garamond,
        profileImage: profileImage,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.accentStrip) {
      final calibri = await _ensureCalibriPdfFonts();
      final garamond = await _ensureGaramondPdfFonts();
      final bodyPt = resume.effectiveBodyFontPt.toDouble();
      final document = pw.Document(
        theme: await resumePdfThemeForCalibri(
          calibri,
          bodyFontPt: bodyPt,
          bodyLineHeight: ResumeTypography.creativeBodyLineHeight,
        ),
      );
      _addAccentStripTemplatePage(
        document,
        resume,
        calibri: calibri,
        garamond: garamond,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsStructured) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsStructuredTemplatePage(document, resume, garamond: garamond);
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsSerifRules) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsSerifRulesTemplatePage(document, resume, garamond: garamond);
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsModernFlow) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsModernFlowTemplatePage(document, resume, garamond: garamond);
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsExecutive) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsExecutiveTemplatePage(document, resume, garamond: garamond);
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsCenterClassic) {
      final arimo = await _ensureArimoPdfFonts();
      final bodyPt = resume.effectiveBodyFontPt.toDouble();
      final document = pw.Document(
        theme: await resumePdfThemeForArimo(
          arimo,
          bodyFontPt: bodyPt,
          bodyLineHeight: ResumeTypography.atsCenterClassicBodyLineHeight,
        ),
      );
      _addAtsCenterClassicTemplatePage(document, resume, arimo: arimo);
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsProfessionalBlue) {
      final arimo = await _ensureArimoPdfFonts();
      final bodyPt = resume.effectiveBodyFontPt.toDouble();
      final document = pw.Document(
        theme: await resumePdfThemeForArimo(
          arimo,
          bodyFontPt: bodyPt,
          bodyLineHeight: ResumeTypography.atsProfessionalBlueBodyLineHeight,
        ),
      );
      _addAtsProfessionalBlueTemplatePage(document, resume, arimo: arimo);
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsLatexClassic) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsLatexClassicTemplatePage(document, resume, garamond: garamond);
      return document.save();
    }

    if (resume.template == ResumeTemplate.corporate) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addCorporateTemplatePage(
        document,
        resume,
        garamond: garamond,
        profileImage: profileImage,
      );
      return document.save();
    }

    final corporateBodyPt = resume.effectiveBodyFontPt.toDouble();
    final inter = await _ensureInterPdfFonts();
    final document = pw.Document(
      theme: await resumePdfThemeForInter(
        inter,
        bodyFontPt: corporateBodyPt,
        bodyLineHeight: ResumeTypography.bodyTextLineHeight,
      ),
    );

    switch (resume.template) {
      case ResumeTemplate.corporate:
        break;
      case ResumeTemplate.creative:
        break;
      case ResumeTemplate.classicSidebar:
        break;
      case ResumeTemplate.detailsSidebar:
        _addDetailsSidebarTemplatePage(document, resume);
        break;
      case ResumeTemplate.accentStrip:
        break;
      case ResumeTemplate.atsStructured:
        break;
      case ResumeTemplate.atsSerifRules:
        break;
      case ResumeTemplate.atsModernFlow:
        break;
      case ResumeTemplate.atsExecutive:
        break;
      case ResumeTemplate.atsCenterClassic:
        break;
      case ResumeTemplate.atsProfessionalBlue:
        break;
      case ResumeTemplate.atsLatexClassic:
        break;
    }

    return document.save();
  }

  Future<Uint8List> buildHighlightedResumePdf({
    required ResumeData resume,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) async {
    if (resume.template == ResumeTemplate.creative) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addHighlightedCreativeTemplatePage(
        document,
        resume,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.classicSidebar) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addHighlightedClassicSidebarTemplatePage(
        document,
        resume,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.accentStrip) {
      final calibri = await _ensureCalibriPdfFonts();
      final garamond = await _ensureGaramondPdfFonts();
      final bodyPt = resume.effectiveBodyFontPt.toDouble();
      final document = pw.Document(
        theme: await resumePdfThemeForCalibri(
          calibri,
          bodyFontPt: bodyPt,
          bodyLineHeight: ResumeTypography.creativeBodyLineHeight,
        ),
      );
      _addAccentStripTemplatePage(
        document,
        resume,
        calibri: calibri,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsStructured) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsStructuredTemplatePage(
        document,
        resume,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsSerifRules) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsSerifRulesTemplatePage(
        document,
        resume,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsModernFlow) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsModernFlowTemplatePage(
        document,
        resume,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsExecutive) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsExecutiveTemplatePage(
        document,
        resume,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsCenterClassic) {
      final arimo = await _ensureArimoPdfFonts();
      final bodyPt = resume.effectiveBodyFontPt.toDouble();
      final document = pw.Document(
        theme: await resumePdfThemeForArimo(
          arimo,
          bodyFontPt: bodyPt,
          bodyLineHeight: ResumeTypography.atsCenterClassicBodyLineHeight,
        ),
      );
      _addAtsCenterClassicTemplatePage(
        document,
        resume,
        arimo: arimo,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsProfessionalBlue) {
      final arimo = await _ensureArimoPdfFonts();
      final bodyPt = resume.effectiveBodyFontPt.toDouble();
      final document = pw.Document(
        theme: await resumePdfThemeForArimo(
          arimo,
          bodyFontPt: bodyPt,
          bodyLineHeight: ResumeTypography.atsProfessionalBlueBodyLineHeight,
        ),
      );
      _addAtsProfessionalBlueTemplatePage(
        document,
        resume,
        arimo: arimo,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.atsLatexClassic) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addAtsLatexClassicTemplatePage(
        document,
        resume,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    if (resume.template == ResumeTemplate.corporate) {
      final garamond = await _ensureGaramondPdfFonts();
      final document = pw.Document();
      _addHighlightedCorporateTemplatePage(
        document,
        resume,
        garamond: garamond,
        highlightSummary: highlightSummary,
        highlightedSkills: highlightedSkills,
        highlightedBulletsByExperience: highlightedBulletsByExperience,
      );
      return document.save();
    }

    final corporateBodyPt = resume.effectiveBodyFontPt.toDouble();
    final inter = await _ensureInterPdfFonts();
    final document = pw.Document(
      theme: await resumePdfThemeForInter(
        inter,
        bodyFontPt: corporateBodyPt,
        bodyLineHeight: ResumeTypography.bodyTextLineHeight,
      ),
    );
    switch (resume.template) {
      case ResumeTemplate.corporate:
        break;
      case ResumeTemplate.creative:
        break;
      case ResumeTemplate.classicSidebar:
        break;
      case ResumeTemplate.detailsSidebar:
        _addHighlightedDetailsSidebarTemplatePage(
          document,
          resume,
          highlightSummary: highlightSummary,
          highlightedSkills: highlightedSkills,
          highlightedBulletsByExperience: highlightedBulletsByExperience,
        );
        break;
      case ResumeTemplate.accentStrip:
        break;
      case ResumeTemplate.atsStructured:
        break;
      case ResumeTemplate.atsSerifRules:
        break;
      case ResumeTemplate.atsModernFlow:
        break;
      case ResumeTemplate.atsExecutive:
        break;
      case ResumeTemplate.atsCenterClassic:
        break;
      case ResumeTemplate.atsProfessionalBlue:
        break;
      case ResumeTemplate.atsLatexClassic:
        break;
    }

    return document.save();
  }

  Future<Uint8List> buildCoverLetterPdf(CoverLetterData coverLetter) async {
    final parsed = _parseCoverLetterContent(coverLetter.content);
    final bodyPt = coverLetter.effectiveBodyFontPt.toDouble();
    final baseTheme = await resumePdfThemeForBodyFont(
      ResumeTextFont.inter,
      bodyFontPt: bodyPt,
    );
    // Embed Noto fallbacks for non-Latin scripts so Arabic, Hindi,
    // Bengali, CJK, etc. render in the PDF preview/export.
    final fallbacks = await _coverLetterFontFallbacks(parsed);
    final theme = fallbacks.isEmpty
        ? baseTheme
        : baseTheme.copyWith(
            defaultTextStyle: baseTheme.defaultTextStyle.copyWith(
              fontFallback: fallbacks,
            ),
            bulletStyle: baseTheme.bulletStyle.copyWith(
              fontFallback: fallbacks,
            ),
          );
    final document = pw.Document(theme: theme);

    switch (coverLetter.template) {
      case CoverLetterTemplate.executiveNote:
        _addExecutiveNoteCoverLetterPage(
          document,
          coverLetter,
          parsed,
          arimo: await _ensureArimoPdfFonts(),
          fontFallback: fallbacks,
        );
        break;
      case CoverLetterTemplate.minimalLetter:
        _addMinimalCoverLetterPage(
          document,
          coverLetter,
          parsed,
          arimo: await _ensureArimoPdfFonts(),
          fontFallback: fallbacks,
        );
        break;
      case CoverLetterTemplate.sidebarLetter:
        _addSidebarCoverLetterPage(
          document,
          coverLetter,
          parsed,
          arimo: await _ensureArimoPdfFonts(),
          fontFallback: fallbacks,
        );
        break;
      case CoverLetterTemplate.classicBusinessLetter:
        _addClassicBusinessCoverLetterPage(
          document,
          coverLetter,
          parsed,
          garamond: await _ensureGaramondPdfFonts(),
          fontFallback: fallbacks,
        );
        break;
    }

    return document.save();
  }

  /// Font sizes applied to cover letter greeting/body/name across all templates.
  @visibleForTesting
  static CoverLetterPdfTypography coverLetterTypographyFor(
    CoverLetterData letter,
  ) {
    return CoverLetterPdfTypography(
      bodyPt: _coverLetterBodyPt(letter),
      headingPt: _coverLetterHeadingPt(letter),
      namePt: _coverLetterNamePt(letter),
    );
  }

  /// Inspects [parsed] to detect non-Latin scripts (Arabic, Devanagari, Bengali,
  /// CJK, etc.) and downloads matching Noto fonts via the `printing` package so
  /// the cover letter PDF preview/export can render them. Failures are
  /// swallowed so the export never blocks on font fetching.
  Future<List<pw.Font>> _coverLetterFontFallbacks(
    _ParsedCoverLetterContent parsed,
  ) async {
    final scripts = _detectCoverLetterScripts(parsed);
    if (scripts.isEmpty) {
      return const <pw.Font>[];
    }
    final fonts = <pw.Font>[];
    for (final script in scripts) {
      try {
        final font = await _loadCoverLetterFallbackFont(script);
        if (font != null) {
          fonts.add(font);
        }
      } catch (_) {
        // Swallow; we still emit the PDF using the default Inter typeface.
      }
    }
    return fonts;
  }

  Set<_CoverLetterScript> _detectCoverLetterScripts(
    _ParsedCoverLetterContent parsed,
  ) {
    final scripts = <_CoverLetterScript>{};
    void scan(String text) {
      if (text.isEmpty) {
        return;
      }
      for (final rune in text.runes) {
        final script = _scriptForRune(rune);
        if (script != null) {
          scripts.add(script);
        }
      }
    }

    parsed.senderLines.forEach(scan);
    parsed.recipientLines.forEach(scan);
    scan(parsed.greeting);
    parsed.bodyParagraphs.forEach(scan);
    scan(parsed.closing);
    scan(parsed.signature);
    return scripts;
  }

  _CoverLetterScript? _scriptForRune(int code) {
    // Arabic + Arabic Supplement/Extended.
    if ((code >= 0x0600 && code <= 0x06FF) ||
        (code >= 0x0750 && code <= 0x077F) ||
        (code >= 0x08A0 && code <= 0x08FF) ||
        (code >= 0xFB50 && code <= 0xFDFF) ||
        (code >= 0xFE70 && code <= 0xFEFF)) {
      return _CoverLetterScript.arabic;
    }
    // Devanagari (Hindi).
    if (code >= 0x0900 && code <= 0x097F) {
      return _CoverLetterScript.devanagari;
    }
    // Bengali.
    if (code >= 0x0980 && code <= 0x09FF) {
      return _CoverLetterScript.bengali;
    }
    // Hebrew.
    if (code >= 0x0590 && code <= 0x05FF) {
      return _CoverLetterScript.hebrew;
    }
    // Thai.
    if (code >= 0x0E00 && code <= 0x0E7F) {
      return _CoverLetterScript.thai;
    }
    // Hiragana / Katakana / Japanese punctuation.
    if ((code >= 0x3040 && code <= 0x30FF) ||
        (code >= 0x31F0 && code <= 0x31FF)) {
      return _CoverLetterScript.japanese;
    }
    // Hangul (Korean).
    if ((code >= 0xAC00 && code <= 0xD7AF) ||
        (code >= 0x1100 && code <= 0x11FF) ||
        (code >= 0x3130 && code <= 0x318F)) {
      return _CoverLetterScript.korean;
    }
    // CJK Unified Ideographs (Chinese; also covers most kanji).
    if ((code >= 0x3400 && code <= 0x4DBF) ||
        (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0xF900 && code <= 0xFAFF)) {
      return _CoverLetterScript.chinese;
    }
    // Cyrillic (Russian, etc.).
    if (code >= 0x0400 && code <= 0x04FF) {
      return _CoverLetterScript.cyrillic;
    }
    // Greek.
    if (code >= 0x0370 && code <= 0x03FF) {
      return _CoverLetterScript.greek;
    }
    return null;
  }

  Future<pw.Font?> _loadCoverLetterFallbackFont(
    _CoverLetterScript script,
  ) async {
    switch (script) {
      case _CoverLetterScript.arabic:
        return PdfGoogleFonts.notoSansArabicRegular();
      case _CoverLetterScript.devanagari:
        return PdfGoogleFonts.notoSansDevanagariRegular();
      case _CoverLetterScript.bengali:
        return PdfGoogleFonts.notoSansBengaliRegular();
      case _CoverLetterScript.hebrew:
        return PdfGoogleFonts.notoSansHebrewRegular();
      case _CoverLetterScript.thai:
        return PdfGoogleFonts.notoSansThaiRegular();
      case _CoverLetterScript.japanese:
        return PdfGoogleFonts.notoSansJPRegular();
      case _CoverLetterScript.korean:
        return PdfGoogleFonts.notoSansKRRegular();
      case _CoverLetterScript.chinese:
        return PdfGoogleFonts.notoSansSCRegular();
      case _CoverLetterScript.cyrillic:
      case _CoverLetterScript.greek:
        // Inter already covers Latin Extended + Cyrillic + Greek glyphs, but
        // load Noto Sans as a safety net for older font subsets.
        return PdfGoogleFonts.notoSansRegular();
    }
  }

  Future<pw.MemoryImage?> _loadProfileImage(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final file = File(trimmed);
    if (!await file.exists()) {
      return null;
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    return pw.MemoryImage(bytes);
  }

  void _addExecutiveNoteCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required ArimoPdfFonts arimo,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final headerColor = _coverLetterHeaderPdf(coverLetter);
    final headerOnColor = _coverLetterHeaderOnPdf(coverLetter);
    final dividerColor = PdfColor.fromHex('#E5E7EB');
    final nameStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterNamePt(coverLetter),
      color: headerOnColor,
      fontFallback: fontFallback,
    );
    final headerMetaStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter),
      color: headerOnColor,
      fontFallback: fontFallback,
    );
    final headingStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w500,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );
    final bodyStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      lineHeight: 1.55,
      fontFallback: fontFallback,
    );
    final recipientStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w500,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );
    final signatureStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(40, 45, 40, 45),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: headerColor,
              borderRadius: pw.BorderRadius.circular(18),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(parsed.senderName, style: nameStyle),
                if (parsed.senderDetails.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    parsed.senderDetails.join('  |  '),
                    style: headerMetaStyle,
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Divider(color: dividerColor),
          pw.SizedBox(height: 10),
          pw.Text(parsed.recipientLines.join('\n'), style: recipientStyle),
          pw.SizedBox(height: 16),
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: bodyStyle,
            headingStyle: headingStyle,
            signatureStyle: signatureStyle,
          ),
        ],
      ),
    );
  }

  void _addClassicBusinessCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts garamond,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final (dateLine, _) = _classicLetterDatePrefix(parsed.senderLines);
    final bodyStyle = _coverLetterGaramondPdfStyle(
      garamond,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      lineHeight: 1.45,
      fontFallback: fontFallback,
    );
    final metaStyle = _coverLetterGaramondPdfStyle(
      garamond,
      weight: ResumeFontWeight.w500,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: PdfColor.fromHex('#3D4349'),
      lineHeight: 1.38,
      fontFallback: fontFallback,
    );
    final recipientStyle = _coverLetterGaramondPdfStyle(
      garamond,
      weight: ResumeFontWeight.w500,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      lineHeight: 1.38,
      fontFallback: fontFallback,
    );
    final headingStyle = _coverLetterGaramondPdfStyle(
      garamond,
      weight: ResumeFontWeight.w500,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );
    final signatureStyle = _coverLetterGaramondPdfStyle(
      garamond,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(40, 45, 40, 45),
        build: (context) => [
          if (dateLine != null) pw.Text(dateLine, style: metaStyle),
          if (dateLine != null) pw.SizedBox(height: 18),
          pw.Text(parsed.recipientLines.join('\n'), style: recipientStyle),
          pw.SizedBox(height: 18),
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: bodyStyle,
            headingStyle: headingStyle,
            signatureStyle: signatureStyle,
          ),
        ],
      ),
    );
  }

  /// Pulls a trailing `"Month D, YYYY"` line from [senderLines] for the letter date line.
  (String?, List<String>) _classicLetterDatePrefix(List<String> senderLines) {
    if (senderLines.isEmpty) {
      return (null, senderLines);
    }
    final last = senderLines.last.trim();
    if (!_coverLetterLineLooksLikeFormattedDate(last)) {
      return (null, senderLines);
    }
    final rest = senderLines.sublist(0, senderLines.length - 1);
    return (last, rest);
  }

  bool _coverLetterLineLooksLikeFormattedDate(String line) {
    final t = line.trim();
    return RegExp(
      r'^(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+\d{4}$',
    ).hasMatch(t);
  }

  void _addMinimalCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required ArimoPdfFonts arimo,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final nameStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterNamePt(coverLetter),
      color: accent,
      fontFallback: fontFallback,
    );
    final headingStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w500,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );
    final bodyStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      lineHeight: 1.55,
      fontFallback: fontFallback,
    );
    final mutedBodyStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter),
      color: PdfColor.fromHex('#5E6369'),
      fontFallback: fontFallback,
    );
    final recipientStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w500,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );
    final signatureStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(40, 45, 40, 45),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              parsed.senderName,
              textAlign: pw.TextAlign.center,
              style: nameStyle,
            ),
          ),
          if (parsed.senderDetails.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                parsed.senderDetails.join('  |  '),
                textAlign: pw.TextAlign.center,
                style: mutedBodyStyle,
              ),
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Container(height: 1, color: accent),
          pw.SizedBox(height: 18),
          pw.Text(parsed.recipientLines.join('\n'), style: recipientStyle),
          pw.SizedBox(height: 16),
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: bodyStyle,
            headingStyle: headingStyle,
            signatureStyle: signatureStyle,
          ),
        ],
      ),
    );
  }

  void _addSidebarCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required ArimoPdfFonts arimo,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final text = _pdfRgb(coverLetter.corporateColorPreset.titleColor);
    final muted = _pdfRgb(
      Color.lerp(
            coverLetter.corporateColorPreset.titleColor,
            const Color(0xFFFFFFFF),
            0.18,
          ) ??
          const Color(0xFF2A6F61),
    );
    final background = _pdfRgb(
      Color.lerp(
            const Color(0xFFFFFFFF),
            coverLetter.corporateColorPreset.headerColor,
            0.18,
          ) ??
          const Color(0xFFE7F4EC),
    );
    final senderDetails = _sidebarCoverLetterSenderDetails(parsed);
    final dateLine =
        parsed.senderDetails
            .cast<String?>()
            .firstWhere(
              (line) =>
                  line != null && _sidebarCoverLetterLineLooksLikeDate(line),
              orElse: () => null,
            )
            ?.trim() ??
        _pdfCoverLetterDateLabel(
          coverLetter.updatedAt,
          language: coverLetter.language,
        );
    final contactLine = senderDetails.join('  |  ');
    final nameStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterNamePt(coverLetter, 32),
      color: text,
      fontFallback: fontFallback,
    ).copyWith(letterSpacing: 0.35);
    final contactStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterHeadingPt(coverLetter, 13),
      color: muted,
      lineHeight: 1.35,
      fontFallback: fontFallback,
    );
    final dateStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: text,
      fontFallback: fontFallback,
    );
    final recipientStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterHeadingPt(coverLetter, 13),
      color: text,
      lineHeight: 1.42,
      fontFallback: fontFallback,
    );
    final greetingStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: text,
      fontFallback: fontFallback,
    );
    final bodyStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter),
      color: text,
      lineHeight: 1.55,
      fontFallback: fontFallback,
    );
    final closingStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterHeadingPt(coverLetter, 13),
      color: text,
      fontFallback: fontFallback,
    );
    final signatureStyle = _coverLetterArialPdfStyle(
      arimo,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterHeadingPt(coverLetter, 13),
      color: text,
      fontFallback: fontFallback,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.fromLTRB(44, 42, 44, 46),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: background),
          ),
        ),
        build: (context) => [
          pw.Text(parsed.senderName.toUpperCase(), style: nameStyle),
          if (contactLine.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(contactLine, style: contactStyle),
          ],
          pw.SizedBox(height: 18),
          pw.Container(height: 4, color: accent),
          pw.SizedBox(height: 34),
          pw.Text(dateLine, style: dateStyle),
          pw.SizedBox(height: 28),
          pw.Text(parsed.recipientLines.join('\n'), style: recipientStyle),
          pw.SizedBox(height: 32),
          pw.Text(parsed.greeting, style: greetingStyle),
          pw.SizedBox(height: 18),
          for (final paragraph in parsed.bodyParagraphs) ...[
            pw.Text(paragraph, style: bodyStyle),
            pw.SizedBox(height: 16),
          ],
          pw.Text(parsed.closing, style: closingStyle),
          pw.SizedBox(height: 10),
          pw.Text(parsed.signature, style: signatureStyle),
        ],
      ),
    );
  }

  List<String> _sidebarCoverLetterSenderDetails(
    _ParsedCoverLetterContent parsed,
  ) {
    return parsed.senderDetails
        .where((line) => !_sidebarCoverLetterLineLooksLikeDate(line))
        .toList();
  }

  bool _sidebarCoverLetterLineLooksLikeDate(String line) {
    final trimmed = line.trim();
    return trimmed == '[Date]' ||
        _coverLetterLineLooksLikeFormattedDate(trimmed) ||
        RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(trimmed);
  }

  String _pdfCoverLetterDateLabel(DateTime date, {required String language}) {
    final normalized = language.trim().toLowerCase();
    if (!normalized.startsWith('english')) {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    }

    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  pw.TextStyle _coverLetterArialPdfStyle(
    ArimoPdfFonts arimo, {
    required int weight,
    required double fontSize,
    PdfColor? color,
    double lineHeight = 1.45,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final normalizedWeight = ResumeFontWeight.normalize(weight);
    return arimoPdfTextStyle(
      arimo,
      normalizedWeight,
      fontSize: fontSize,
      color: color,
      lineSpacing: fontSize * (lineHeight - 1),
    ).copyWith(
      fontWeight: normalizedWeight >= ResumeFontWeight.w700
          ? pw.FontWeight.bold
          : pw.FontWeight.normal,
      fontFallback: fontFallback,
    );
  }

  pw.TextStyle _coverLetterGaramondPdfStyle(
    GaramondPdfFonts garamond, {
    required int weight,
    required double fontSize,
    PdfColor? color,
    double lineHeight = 1.45,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final normalizedWeight = ResumeFontWeight.normalize(weight);
    return garamondPdfTextStyle(
      garamond,
      normalizedWeight,
      fontSize: fontSize,
      color: color,
      lineSpacing: fontSize * (lineHeight - 1),
    ).copyWith(fontFallback: fontFallback);
  }

  List<pw.Widget> _buildCoverLetterBodyWithStyles(
    _ParsedCoverLetterContent parsed, {
    required pw.TextStyle bodyStyle,
    required pw.TextStyle headingStyle,
    required pw.TextStyle signatureStyle,
    pw.TextAlign bodyTextAlign = pw.TextAlign.left,
  }) {
    return [
      pw.Text(parsed.greeting, style: headingStyle, textAlign: bodyTextAlign),
      pw.SizedBox(height: 12),
      for (final paragraph in parsed.bodyParagraphs) ...[
        pw.Text(paragraph, style: bodyStyle, textAlign: bodyTextAlign),
        pw.SizedBox(height: 12),
      ],
      pw.Text(parsed.closing, style: headingStyle, textAlign: bodyTextAlign),
      pw.SizedBox(height: 20),
      pw.Text(
        parsed.signature,
        style: signatureStyle,
        textAlign: bodyTextAlign,
      ),
    ];
  }

  _ParsedCoverLetterContent _parseCoverLetterContent(String content) {
    final normalized = content.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const _ParsedCoverLetterContent(
        senderLines: <String>['[Your Name]'],
        recipientLines: <String>[
          'Hiring Manager',
          '[Company Name]',
          '[Company Address]',
          '[City, State, Zip Code]',
        ],
        greeting: 'Dear Hiring Manager,',
        bodyParagraphs: <String>[
          'Your generated cover letter will appear here.',
        ],
        closing: 'Sincerely,',
        signature: '[Your Name]',
      );
    }

    final sections = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (sections.length < 3) {
      return _ParsedCoverLetterContent(
        senderLines: const <String>['[Your Name]'],
        recipientLines: const <String>[
          'Hiring Manager',
          '[Company Name]',
          '[Company Address]',
          '[City, State, Zip Code]',
        ],
        greeting: 'Dear Hiring Manager,',
        bodyParagraphs: <String>[normalized],
        closing: 'Sincerely,',
        signature: '[Your Name]',
      );
    }

    final senderLines = _nonEmptyLines(sections.first);
    final recipientLines = sections.length > 1
        ? _nonEmptyLines(sections[1])
        : const <String>[];
    final greeting = sections.length > 2 ? sections[2] : 'Dear Hiring Manager,';
    final closing = sections.length > 4
        ? sections[sections.length - 2]
        : 'Sincerely,';
    final signature = sections.length > 5
        ? sections.last
        : senderLines.isNotEmpty
        ? senderLines.first
        : '[Your Name]';
    final bodyStart = sections.length > 2 ? 3 : 0;
    final bodyEnd = sections.length > 4 ? sections.length - 2 : sections.length;
    final bodyParagraphs = sections
        .sublist(bodyStart, bodyEnd)
        .where((item) => item.trim().isNotEmpty)
        .toList();

    return _ParsedCoverLetterContent(
      senderLines: senderLines.isEmpty
          ? const <String>['[Your Name]']
          : senderLines,
      recipientLines: recipientLines.isEmpty
          ? const <String>[
              'Hiring Manager',
              '[Company Name]',
              '[Company Address]',
              '[City, State, Zip Code]',
            ]
          : recipientLines,
      greeting: greeting,
      bodyParagraphs: bodyParagraphs.isEmpty
          ? <String>[normalized]
          : bodyParagraphs,
      closing: closing,
      signature: signature,
    );
  }

  List<String> _nonEmptyLines(String section) {
    return section
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _displayName(ResumeData resume) =>
      resume.fullName.trim().isEmpty ? 'Your Name' : resume.fullName.trim();

  String _resumeInitials(ResumeData resume) {
    final words = _displayName(
      resume,
    ).split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
    if (words.isEmpty) {
      return 'DA';
    }
    return words.map((part) => part[0].toUpperCase()).join();
  }

  List<String> _resumeContactItems(ResumeData resume) =>
      resume.resumeContactItems();

  List<String> _skillsForDisplay(ResumeData resume) {
    if (!resume.includeSkillsInResume) {
      return const [];
    }
    if (resume.skills.isNotEmpty) {
      return resume.skills;
    }
    return const <String>[];
  }

  pw.Widget _corporateHeadingText(
    String value, {
    PdfColor? color,
    GaramondPdfFonts? garamond,
  }) {
    final resolvedColor = color ?? PdfColor.fromHex('#50555C');
    final style = garamond != null
        ? garamondPdfTextStyle(
            garamond,
            ResumeTypography.darkHeaderSectionTitleWeight,
            fontSize: ResumeTypography.darkHeaderSectionTitlePt,
            color: resolvedColor,
          )
        : pw.TextStyle(
            fontSize: ResumeTypography.darkHeaderSectionTitlePt,
            fontWeight: pw.FontWeight.bold,
            color: resolvedColor,
          );
    return pw.Text(value, style: style);
  }

  List<pw.Widget> _twoColumnBulletRows(
    List<String> items, {
    double columnGap = 20,
    double itemBottom = 3,
    double fontSize = ResumeTypography.bodyPt,
    pw.TextStyle? bulletStyle,
  }) {
    final resolvedBulletStyle =
        bulletStyle ?? pw.TextStyle(color: PdfColors.black, fontSize: fontSize);
    final cleaned = items.where((item) => item.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) {
      return const <pw.Widget>[];
    }
    final leftCount = (cleaned.length / 2).ceil();
    return [
      for (var i = 0; i < leftCount; i++)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: itemBottom),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Bullet(text: cleaned[i], style: resolvedBulletStyle),
              ),
              pw.SizedBox(width: columnGap),
              pw.Expanded(
                child: i + leftCount < cleaned.length
                    ? pw.Bullet(
                        text: cleaned[i + leftCount],
                        style: resolvedBulletStyle,
                      )
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),
    ];
  }

  String _workSummaryText(WorkExperience item) {
    return '';
  }

  List<String> _workBulletLines(WorkExperience item) {
    final nonEmptyBullets = item.bullets
        .where((b) => b.trim().isNotEmpty)
        .toList();
    if (nonEmptyBullets.isNotEmpty) {
      return nonEmptyBullets;
    }
    final legacyDescription = item.description.trim();
    if (legacyDescription.isNotEmpty) {
      return [legacyDescription];
    }
    return const <String>[];
  }

  pw.Widget _corporateRoleCompanyText(String role, String company) {
    final style = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 15,
      color: PdfColors.black,
    );
    final value = '${role.ifEmpty('Role')} / ${company.ifEmpty('Company')}';
    return pw.Text(value, style: style);
  }

  pw.Widget _corporateStrokeLabelText(String value) {
    final style = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 15,
      color: PdfColors.black,
      lineSpacing: 0,
    );
    return pw.Text(value, style: style);
  }

  pw.Widget _buildHighlightedCorporateExperience(
    WorkExperience item,
    Set<String> highlightedBullets,
    PdfColor highlightColor, {
    GaramondPdfFonts? garamond,
    double bodyFontPt = ResumeTypography.bodyPt,
  }) {
    final roleCompany = garamond != null
        ? pw.Text(
            '${item.role.ifEmpty('Role')} / ${item.company.ifEmpty('Company')}',
            style: garamondPdfTextStyle(
              garamond,
              ResumeTypography.darkHeaderSubtitleWeight,
              fontSize: ResumeTypography.darkHeaderSubtitlePt,
              color: const PdfColor.fromInt(0xFF141414),
            ),
          )
        : _corporateRoleCompanyText(item.role, item.company);
    final dateStyle = garamond != null
        ? corporateBodyPdfTextStyle(
            garamond,
            bodyFontPt,
            color: PdfColor.fromHex('#666B71'),
            fontStyle: pw.FontStyle.italic,
          )
        : pw.TextStyle(
            color: PdfColor.fromHex('#666B71'),
            fontStyle: pw.FontStyle.italic,
            fontWeight: pw.FontWeight.normal,
            font: pw.Font.helveticaOblique(),
          );
    final bodyStyle = garamond != null
        ? corporateBodyPdfTextStyle(garamond, bodyFontPt)
        : pw.TextStyle(
            color: PdfColors.black,
            fontSize: bodyFontPt,
            lineSpacing: ResumeTypography.darkHeaderBodyPdfLineSpacingFor(
              bodyFontPt,
            ),
          );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(child: roleCompany),
            if (item.startDate.trim().isNotEmpty ||
                item.endDate.trim().isNotEmpty)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${item.startDate.trim()}${item.startDate.trim().isNotEmpty && item.endDate.trim().isNotEmpty ? ' - ' : ''}${item.endDate.trim()}',
                  style: dateStyle,
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 4),
        if (_workSummaryText(item).isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(_workSummaryText(item), style: bodyStyle),
        ],
        ...(() {
          final bullets = _workBulletLines(item);
          return bullets.asMap().entries.map((entry) {
            final index = entry.key;
            final bullet = entry.value;
            return pw.Padding(
              padding: pw.EdgeInsets.only(top: index == 0 ? 0 : 4),
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                color: highlightedBullets.contains(bullet)
                    ? highlightColor
                    : PdfColors.white,
                child: _highlightedPdfLineText(bullet, style: bodyStyle),
              ),
            );
          });
        })(),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _twoColumnBulletListWithHighlights(
    List<String> items,
    Set<String> highlightedSkills,
    PdfColor highlightColor, {
    double fontSize = ResumeTypography.bodyPt,
    pw.TextStyle? bulletStyle,
  }) {
    final resolvedBulletStyle =
        bulletStyle ?? pw.TextStyle(color: PdfColors.black, fontSize: fontSize);
    final cleaned = items.where((item) => item.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) {
      return pw.SizedBox();
    }
    final leftCount = (cleaned.length / 2).ceil();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < leftCount; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    color: highlightedSkills.contains(cleaned[i])
                        ? highlightColor
                        : PdfColors.white,
                    child: _highlightedPdfLineText(
                      cleaned[i],
                      style: resolvedBulletStyle,
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: i + leftCount < cleaned.length
                      ? pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          color:
                              highlightedSkills.contains(cleaned[i + leftCount])
                              ? highlightColor
                              : PdfColors.white,
                          child: _highlightedPdfLineText(
                            cleaned[i + leftCount],
                            style: resolvedBulletStyle,
                          ),
                        )
                      : pw.SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<pw.Widget> _twoColumnBulletRowsWithHighlights(
    List<String> items,
    Set<String> highlightedSkills,
    PdfColor highlightColor, {
    double columnGap = 20,
    double itemBottom = 3,
    double fontSize = ResumeTypography.bodyPt,
    pw.TextStyle? bulletStyle,
  }) {
    final resolvedBulletStyle =
        bulletStyle ?? pw.TextStyle(color: PdfColors.black, fontSize: fontSize);
    final cleaned = items.where((item) => item.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) {
      return const <pw.Widget>[];
    }
    final leftCount = (cleaned.length / 2).ceil();
    return [
      for (var i = 0; i < leftCount; i++)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: itemBottom),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  color: highlightedSkills.contains(cleaned[i])
                      ? highlightColor
                      : PdfColors.white,
                  child: _highlightedPdfLineText(
                    cleaned[i],
                    style: resolvedBulletStyle,
                  ),
                ),
              ),
              pw.SizedBox(width: columnGap),
              pw.Expanded(
                child: i + leftCount < cleaned.length
                    ? pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        color:
                            highlightedSkills.contains(cleaned[i + leftCount])
                            ? highlightColor
                            : PdfColors.white,
                        child: _highlightedPdfLineText(
                          cleaned[i + leftCount],
                          style: resolvedBulletStyle,
                        ),
                      )
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),
    ];
  }

  pw.Widget _buildCreativeProject(
    ProjectItem item, {
    GaramondPdfFonts? garamond,
    required PdfColor mutedColor,
    required double bodyPt,
    required double subtitlePt,
  }) {
    final bullets = _projectBulletLines(item);
    final titleStyle = garamond != null
        ? garamondPdfTextStyle(
            garamond,
            ResumeTypography.creativeSubtitleWeight,
            fontSize: subtitlePt,
          )
        : pw.TextStyle(fontSize: subtitlePt);
    final bodyColor = _creativeBodyTextColorPdf();
    final bodyStyle = garamond != null
        ? accentStripBodyPdfTextStyle(garamond, bodyPt, color: bodyColor)
        : pw.TextStyle(color: bodyColor, fontSize: bodyPt);
    final titleStyleWithColor = titleStyle.copyWith(color: bodyColor);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(item.title.ifEmpty('Project'), style: titleStyleWithColor),
          for (var i = 0; i < bullets.length; i++)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: i == 0 ? 2 : 3),
              child: pw.Bullet(text: bullets[i], style: bodyStyle),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildHighlightedCreativeExperience(
    WorkExperience item,
    Set<String> highlightedBullets,
    PdfColor highlightColor, {
    GaramondPdfFonts? garamond,
    required double bodyPt,
    required double subtitlePt,
  }) {
    return _buildCreativeExperience(
      item,
      garamond: garamond,
      highlightedBullets: highlightedBullets,
      highlightColor: highlightColor,
      bodyPt: bodyPt,
      subtitlePt: subtitlePt,
    );
  }

  pw.Widget _buildCreativeExperience(
    WorkExperience item, {
    GaramondPdfFonts? garamond,
    Set<String> highlightedBullets = const {},
    PdfColor? highlightColor,
    required double bodyPt,
    required double subtitlePt,
  }) {
    final bodyColor = _creativeBodyTextColorPdf();
    final subtitleStyle = garamond != null
        ? garamondPdfTextStyle(
            garamond,
            ResumeTypography.creativeSubtitleWeight,
            fontSize: subtitlePt,
            color: bodyColor,
          )
        : pw.TextStyle(fontSize: subtitlePt, color: bodyColor);
    final bodyStyle = garamond != null
        ? accentStripBodyPdfTextStyle(garamond, bodyPt, color: bodyColor)
        : pw.TextStyle(fontSize: bodyPt, color: bodyColor);
    final dateStyle = garamond != null
        ? accentStripBodyPdfTextStyle(
            garamond,
            bodyPt,
            color: bodyColor,
            fontStyle: pw.FontStyle.italic,
          )
        : pw.TextStyle(
            color: bodyColor,
            fontSize: bodyPt,
            fontStyle: pw.FontStyle.italic,
          );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: subtitleStyle,
                    children: [
                      pw.TextSpan(
                        text: item.role.ifEmpty('Role').toUpperCase(),
                      ),
                      pw.TextSpan(
                        text: ' / ${item.company.ifEmpty('Company')}',
                      ),
                    ],
                  ),
                ),
              ),
              if (item.startDate.trim().isNotEmpty ||
                  item.endDate.trim().isNotEmpty)
                pw.Text(
                  '${item.startDate.trim()}${item.startDate.trim().isNotEmpty && item.endDate.trim().isNotEmpty ? ' - ' : ''}${item.endDate.trim()}',
                  style: dateStyle,
                ),
            ],
          ),
          if (_workSummaryText(item).isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(_workSummaryText(item), style: bodyStyle),
          ],
          for (final bullet in _workBulletLines(item))
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: highlightColor != null
                  ? pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      color: highlightedBullets.contains(bullet)
                          ? highlightColor
                          : PdfColors.white,
                      child: _highlightedPdfLineText(bullet, style: bodyStyle),
                    )
                  : pw.Bullet(text: bullet, style: bodyStyle),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCorporateEducation(
    EducationItem item, {
    GaramondPdfFonts? garamond,
    double bodyFontPt = ResumeTypography.bodyPt,
  }) {
    // Same line as template card: `Institution  |  2014 - 2018`
    final titleLine = corporateEducationTitleLine(
      item.institution,
      item.startDate,
      item.endDate,
    );

    final titleStyle = garamond != null
        ? garamondPdfTextStyle(
            garamond,
            ResumeTypography.darkHeaderSubtitleWeight,
            fontSize: ResumeTypography.darkHeaderSubtitlePt,
            color: const PdfColor.fromInt(0xFF141414),
          ).copyWith(lineSpacing: 0)
        : pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 15,
            color: PdfColors.black,
            lineSpacing: 0,
          );
    final degreeStyle = garamond != null
        ? corporateBodyPdfTextStyle(garamond, bodyFontPt)
        : pw.TextStyle(
            fontSize: bodyFontPt,
            lineSpacing: ResumeTypography.darkHeaderBodyPdfLineSpacingFor(
              bodyFontPt,
            ),
          );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titleLine, style: titleStyle),
          pw.SizedBox(height: 4),
          pw.Text(item.degree.ifEmpty('Degree'), style: degreeStyle),
        ],
      ),
    );
  }

  pw.Widget _buildCompactProject(
    ProjectItem item, {
    double bodyFontPt = ResumeTypography.bodyPt,
  }) {
    final bullets = _projectBulletLines(item);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _corporateStrokeLabelText(item.title.ifEmpty('Project')),
          for (var i = 0; i < bullets.length; i++)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: i == 0 ? 2 : 3),
              child: pw.Bullet(
                text: bullets[i],
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: bodyFontPt,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildCompactProjectWidgets(
    ProjectItem item, {
    GaramondPdfFonts? garamond,
    double bodyFontPt = ResumeTypography.bodyPt,
    bool atsGaramondBody = false,
    bool atsModernFlowGaramondBody = false,
    bool atsExecutiveGaramondBody = false,
  }) {
    final bullets = _projectBulletLines(item);
    final subtitleWeight = atsGaramondBody
        ? ResumeTypography.atsStructuredSubtitleWeight
        : ResumeTypography.darkHeaderSubtitleWeight;
    final subtitlePt = atsGaramondBody
        ? ResumeTypography.atsStructuredSubtitlePt
        : ResumeTypography.darkHeaderSubtitlePt;
    final titleWidget = garamond != null
        ? pw.Text(
            item.title.ifEmpty('Project'),
            style: garamondPdfTextStyle(
              garamond,
              subtitleWeight,
              fontSize: subtitlePt,
              color: const PdfColor.fromInt(0xFF141414),
            ).copyWith(lineSpacing: 0),
          )
        : _corporateStrokeLabelText(item.title.ifEmpty('Project'));
    final bulletStyle = garamond != null
        ? (atsModernFlowGaramondBody
              ? atsModernFlowBodyPdfTextStyle(garamond, bodyFontPt)
              : atsExecutiveGaramondBody
              ? atsExecutiveBodyPdfTextStyle(garamond, bodyFontPt)
              : atsGaramondBody
              ? atsStructuredBodyPdfTextStyle(garamond, bodyFontPt)
              : corporateBodyPdfTextStyle(garamond, bodyFontPt))
        : pw.TextStyle(
            color: PdfColors.black,
            fontSize: bodyFontPt,
            lineSpacing: ResumeTypography.darkHeaderBodyPdfLineSpacingFor(
              bodyFontPt,
            ),
          );
    return [
      titleWidget,
      for (var i = 0; i < bullets.length; i++)
        pw.Padding(
          padding: pw.EdgeInsets.only(top: i == 0 ? 2 : 3),
          child: pw.Bullet(text: bullets[i], style: bulletStyle),
        ),
      pw.SizedBox(height: 8),
    ];
  }

  List<String> _projectBulletLines(ProjectItem item) {
    final nonEmptyBullets = item.bullets
        .where((b) => b.trim().isNotEmpty)
        .toList();
    if (nonEmptyBullets.isNotEmpty) {
      return nonEmptyBullets;
    }
    return [
      item.overview.trim(),
      item.impact.trim(),
    ].where((part) => part.isNotEmpty).toList();
  }

  Future<File> savePdfToDevice(ResumeData resume) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${directory.path}/exports');
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final safeName = _sanitizeFileName(
      resume.fullName.trim().isEmpty ? resume.title : resume.fullName,
    );
    final file = File(
      '${exportDirectory.path}/$safeName-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final bytes = await buildPdf(resume);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareResume(ResumeData resume) async {
    final file = await savePdfToDevice(resume);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${resume.title} resume',
      text: 'Shared from ResumeAI',
    );
  }

  Future<void> printResume(ResumeData resume) async {
    final bytes = await buildPdf(resume);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${_sanitizeFileName(resume.title)}.pdf',
      format: PdfPageFormat.a4,
    );
  }

  Future<File> saveCoverLetterPdfToDevice(CoverLetterData coverLetter) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${directory.path}/exports');
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final safeName = _sanitizeFileName(coverLetter.displayTitle);
    final file = File(
      '${exportDirectory.path}/$safeName-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final bytes = await buildCoverLetterPdf(coverLetter);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareCoverLetter(CoverLetterData coverLetter) async {
    final file = await saveCoverLetterPdfToDevice(coverLetter);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${coverLetter.displayTitle} cover letter',
      text: 'Shared from ResumeAI',
    );
  }

  Future<void> printCoverLetter(CoverLetterData coverLetter) async {
    final bytes = await buildCoverLetterPdf(coverLetter);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${_sanitizeFileName(coverLetter.displayTitle)}.pdf',
      format: PdfPageFormat.a4,
    );
  }

  String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .ifEmpty('resume');
  }
}

enum _CoverLetterScript {
  arabic,
  devanagari,
  bengali,
  hebrew,
  thai,
  japanese,
  korean,
  chinese,
  cyrillic,
  greek,
}

class _ParsedCoverLetterContent {
  const _ParsedCoverLetterContent({
    required this.senderLines,
    required this.recipientLines,
    required this.greeting,
    required this.bodyParagraphs,
    required this.closing,
    required this.signature,
  });

  final List<String> senderLines;
  final List<String> recipientLines;
  final String greeting;
  final List<String> bodyParagraphs;
  final String closing;
  final String signature;

  String get senderName =>
      senderLines.isEmpty ? '[Your Name]' : senderLines.first;

  List<String> get senderDetails =>
      senderLines.length <= 1 ? const <String>[] : senderLines.sublist(1);

  String get senderInitial {
    final normalized = senderName.trim();
    if (normalized.isEmpty || normalized.startsWith('[')) {
      return '';
    }
    return normalized.substring(0, 1).toUpperCase();
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
