import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../resume_font_weight.dart';
import '../../resume_text_font.dart';
import 'resume_pdf_theme.dart';

/// Embedded Calibri-style fonts for PDF (Carlito + open-weight companions).
///
/// Carlito only provides regular (400) and bold (700). Lighter and mid weights
/// use bundled Nunito files so 300–800 each render with a distinct face.
class CalibriPdfFonts {
  CalibriPdfFonts._({
    required Map<int, pw.Font> upright,
    required pw.Font italic,
  }) : _upright = upright,
       italic = italic;

  final Map<int, pw.Font> _upright;
  final pw.Font italic;

  pw.Font fontFor(int weight, {bool useItalic = false}) {
    if (useItalic) {
      return italic;
    }
    final key = ResumeFontWeight.normalize(weight);
    final font = _upright[key];
    if (font != null) {
      return font;
    }
    return _upright[ResumeFontWeight.w400]!;
  }

  pw.Font get w400 => fontFor(ResumeFontWeight.w400);

  pw.Font get w700 => fontFor(ResumeFontWeight.w700);
}

pw.TextStyle calibriPdfTextStyle(
  CalibriPdfFonts fonts,
  int weight, {
  double? fontSize,
  PdfColor? color,
  double? lineSpacing,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) {
  final useItalic = fontStyle == pw.FontStyle.italic;
  final font = fonts.fontFor(weight, useItalic: useItalic);
  return pw.TextStyle(
    inherit: false,
    color: color ?? PdfColors.black,
    font: font,
    fontNormal: font,
    fontBold: font,
    fontItalic: font,
    fontBoldItalic: font,
    fontSize: fontSize ?? ResumeTypography.bodyPt,
    fontWeight: pw.FontWeight.normal,
    fontStyle: useItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
    letterSpacing: 0,
    wordSpacing: 1,
    lineSpacing: lineSpacing ?? 0,
    height: 1,
    decoration: pw.TextDecoration.none,
    decorationStyle: pw.TextDecorationStyle.solid,
    decorationThickness: 1,
    renderingMode: PdfTextRenderingMode.fill,
  );
}

pw.TextStyle calibriBodyPdfTextStyle(
  CalibriPdfFonts fonts,
  double bodyFontPt, {
  int weight = ResumeFontWeight.w400,
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    calibriPdfTextStyle(
      fonts,
      weight,
      fontSize: bodyFontPt,
      color: color,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyFontPt),
      fontStyle: fontStyle,
    );

pw.TextStyle calibriCreativeBodyPdfTextStyle(
  CalibriPdfFonts fonts,
  double bodyFontPt, {
  int weight = ResumeFontWeight.w400,
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    calibriPdfTextStyle(
      fonts,
      weight,
      fontSize: bodyFontPt,
      color: color,
      lineSpacing: ResumeTypography.creativeBodyPdfLineSpacingFor(bodyFontPt),
      fontStyle: fontStyle,
    );

pw.TextStyle calibriClassicSidebarBodyPdfTextStyle(
  CalibriPdfFonts fonts,
  double bodyFontPt, {
  int weight = ResumeFontWeight.w400,
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    calibriPdfTextStyle(
      fonts,
      weight,
      fontSize: bodyFontPt,
      color: color,
      lineSpacing:
          ResumeTypography.classicSidebarBodyPdfLineSpacingFor(bodyFontPt),
      fontStyle: fontStyle,
    );

/// Dark Header avatar initials — 36pt, weight 600.
pw.TextStyle darkHeaderInitialsPdfStyle(
  CalibriPdfFonts fonts,
  PdfColor color,
) =>
    calibriPdfTextStyle(
      fonts,
      ResumeTypography.darkHeaderInitialsWeight,
      fontSize: ResumeTypography.darkHeaderInitialsPt,
      color: color,
    );

Future<CalibriPdfFonts> loadCalibriPdfFonts() async {
  final upright = <int, pw.Font>{
    ResumeFontWeight.w300: await loadPdfTtf('assets/fonts/nunito/Nunito-Light.ttf'),
    ResumeFontWeight.w400: await loadPdfTtf(
      'assets/fonts/carlito/Carlito-Regular.ttf',
    ),
    ResumeFontWeight.w500: await loadPdfTtf('assets/fonts/nunito/Nunito-Medium.ttf'),
    ResumeFontWeight.w600: await loadPdfTtf(
      'assets/fonts/nunito/Nunito-SemiBold.ttf',
    ),
    ResumeFontWeight.w700: await loadPdfTtf('assets/fonts/carlito/Carlito-Bold.ttf'),
    ResumeFontWeight.w800: await loadPdfTtf(
      'assets/fonts/nunito/Nunito-ExtraBold.ttf',
    ),
  };
  final italic = await loadPdfTtf('assets/fonts/carlito/Carlito-Italic.ttf');
  return CalibriPdfFonts._(upright: upright, italic: italic);
}

Future<pw.ThemeData> resumePdfThemeForCalibri(
  CalibriPdfFonts fonts, {
  required double bodyFontPt,
  double bodyLineHeight = ResumeTypography.bodyTextLineHeight,
}) async {
  final lineSpacing = bodyFontPt * (bodyLineHeight - 1);
  final cacheKey =
      'calibri_${bodyFontPt.toStringAsFixed(1)}_${bodyLineHeight.toStringAsFixed(2)}';
  final cached = resumePdfThemeCache[cacheKey];
  if (cached != null) {
    return cached;
  }
  final bodyStyle = calibriPdfTextStyle(
    fonts,
    ResumeFontWeight.w400,
    fontSize: bodyFontPt,
    lineSpacing: lineSpacing,
  );
  final theme = pw.ThemeData.withFont(
    base: fonts.w400,
    bold: fonts.fontFor(ResumeFontWeight.w800),
    italic: fonts.italic,
    boldItalic: fonts.fontFor(ResumeFontWeight.w800),
  ).copyWith(
    defaultTextStyle: bodyStyle,
    bulletStyle: bodyStyle,
  );
  resumePdfThemeCache[cacheKey] = theme;
  return theme;
}
