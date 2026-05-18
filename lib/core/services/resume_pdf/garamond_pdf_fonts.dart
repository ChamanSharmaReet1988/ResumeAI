import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../resume_font_weight.dart';
import '../../resume_text_font.dart';
import 'resume_pdf_theme.dart';

/// EB Garamond (bundled as Garamond) for accent-strip headings in PDF export.
///
/// The variable font files do not honor [pw.FontWeight.bold] in the PDF engine, so
/// we load instanced static faces per weight (400–800).
class GaramondPdfFonts {
  GaramondPdfFonts._({
    required Map<int, pw.Font> upright,
    required Map<int, pw.Font> italic,
  }) : _upright = upright,
       _italic = italic;

  final Map<int, pw.Font> _upright;
  final Map<int, pw.Font> _italic;

  pw.Font fontFor(int weight, {bool useItalic = false}) {
    final key = ResumeFontWeight.normalize(weight);
    final map = useItalic ? _italic : _upright;
    return map[key] ?? map[ResumeFontWeight.w400]!;
  }

  pw.Font get w400 => fontFor(ResumeFontWeight.w400);

  pw.Font get w700 => fontFor(ResumeFontWeight.w700);
}

pw.TextStyle atsStructuredBodyPdfTextStyle(
  GaramondPdfFonts fonts,
  double bodyPt, {
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    garamondPdfTextStyle(
      fonts,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: bodyPt,
      color: color,
      lineSpacing: ResumeTypography.bodyPdfLineSpacingFor(bodyPt),
      fontStyle: fontStyle,
    );

pw.TextStyle atsModernFlowBodyPdfTextStyle(
  GaramondPdfFonts fonts,
  double bodyPt, {
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    garamondPdfTextStyle(
      fonts,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: bodyPt,
      color: color,
      lineSpacing: ResumeTypography.atsModernFlowBodyPdfLineSpacingFor(bodyPt),
      fontStyle: fontStyle,
    );

pw.TextStyle atsExecutiveBodyPdfTextStyle(
  GaramondPdfFonts fonts,
  double bodyPt, {
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    garamondPdfTextStyle(
      fonts,
      ResumeTypography.atsStructuredBodyWeight,
      fontSize: bodyPt,
      color: color,
      lineSpacing: ResumeTypography.atsExecutiveBodyPdfLineSpacingFor(bodyPt),
      fontStyle: fontStyle,
    );

pw.TextStyle accentStripBodyPdfTextStyle(
  GaramondPdfFonts fonts,
  double bodyPt, {
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    garamondPdfTextStyle(
      fonts,
      ResumeTypography.accentStripBodyWeight,
      fontSize: bodyPt,
      color: color,
      lineSpacing: ResumeTypography.creativeBodyPdfLineSpacingFor(bodyPt),
      fontStyle: fontStyle,
    );

/// Corporate (template 1) body — Garamond Regular at [darkHeaderBodyWeight].
pw.TextStyle corporateBodyPdfTextStyle(
  GaramondPdfFonts fonts,
  double bodyPt, {
  PdfColor? color,
  pw.FontStyle fontStyle = pw.FontStyle.normal,
}) =>
    accentStripBodyPdfTextStyle(
      fonts,
      bodyPt,
      color: color,
      fontStyle: fontStyle,
    );

pw.TextStyle darkHeaderInitialsGaramondPdfStyle(
  GaramondPdfFonts fonts,
  PdfColor color,
) =>
    garamondPdfTextStyle(
      fonts,
      ResumeTypography.darkHeaderInitialsWeight,
      fontSize: ResumeTypography.darkHeaderInitialsPt,
      color: color,
    );

pw.TextStyle garamondPdfTextStyle(
  GaramondPdfFonts fonts,
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

Future<GaramondPdfFonts> loadGaramondPdfFonts() async {
  final upright = <int, pw.Font>{
    ResumeFontWeight.w400: await loadPdfTtf(
      'assets/fonts/garamond/Garamond-Regular.ttf',
    ),
    ResumeFontWeight.w500: await loadPdfTtf(
      'assets/fonts/garamond/Garamond-Medium.ttf',
    ),
    ResumeFontWeight.w600: await loadPdfTtf(
      'assets/fonts/garamond/Garamond-SemiBold.ttf',
    ),
    ResumeFontWeight.w700: await loadPdfTtf(
      'assets/fonts/garamond/Garamond-Bold.ttf',
    ),
    ResumeFontWeight.w800: await loadPdfTtf(
      'assets/fonts/garamond/Garamond-ExtraBold.ttf',
    ),
  };
  final italic = <int, pw.Font>{
    ResumeFontWeight.w400: await loadPdfTtf(
      'assets/fonts/garamond/Garamond-Italic.ttf',
    ),
    ResumeFontWeight.w700: await loadPdfTtf(
      'assets/fonts/garamond/Garamond-BoldItalic.ttf',
    ),
  };
  return GaramondPdfFonts._(upright: upright, italic: italic);
}
