import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../resume_font_weight.dart';
import '../../resume_text_font.dart';
import 'resume_pdf_theme.dart';

/// Embedded Arimo (Arial metric match) for PDF export.
class ArimoPdfFonts {
  ArimoPdfFonts._({required pw.Font variable}) : _variable = variable;

  final pw.Font _variable;

  pw.Font fontFor(int weight, {bool useItalic = false}) => _variable;

  pw.Font get w400 => _variable;
}

pw.TextStyle arimoPdfTextStyle(
  ArimoPdfFonts fonts,
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

pw.TextStyle atsCenterClassicBodyPdfTextStyle(
  ArimoPdfFonts fonts,
  double bodyPt, {
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    arimoPdfTextStyle(
      fonts,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: bodyPt,
      color: color,
      lineSpacing: ResumeTypography.atsCenterClassicBodyPdfLineSpacingFor(bodyPt),
      fontStyle: fontStyle,
    );

pw.TextStyle atsProfessionalBlueBodyPdfTextStyle(
  ArimoPdfFonts fonts,
  double bodyPt, {
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    arimoPdfTextStyle(
      fonts,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: bodyPt,
      color: color,
      lineSpacing:
          ResumeTypography.atsProfessionalBlueBodyPdfLineSpacingFor(bodyPt),
      fontStyle: fontStyle,
    );

Future<ArimoPdfFonts> loadArimoPdfFonts() async {
  final variable = await loadPdfTtf('assets/fonts/arimo/Arimo-Variable.ttf');
  return ArimoPdfFonts._(variable: variable);
}

Future<pw.ThemeData> resumePdfThemeForArimo(
  ArimoPdfFonts fonts, {
  required double bodyFontPt,
  required double bodyLineHeight,
}) async {
  final cacheKey =
      'arimo_${bodyFontPt.toStringAsFixed(1)}_${bodyLineHeight.toStringAsFixed(2)}';
  final cached = resumePdfThemeCache[cacheKey];
  if (cached != null) {
    return cached;
  }
  final lineSpacing = bodyFontPt * (bodyLineHeight - 1);
  final bodyStyle = arimoPdfTextStyle(
    fonts,
    ResumeFontWeight.w400,
    fontSize: bodyFontPt,
    lineSpacing: lineSpacing,
  );
  final theme = pw.ThemeData.withFont(
    base: fonts.w400,
    bold: fonts.w400,
    italic: fonts.w400,
    boldItalic: fonts.w400,
  ).copyWith(
    defaultTextStyle: bodyStyle,
    bulletStyle: bodyStyle,
  );
  resumePdfThemeCache[cacheKey] = theme;
  return theme;
}
