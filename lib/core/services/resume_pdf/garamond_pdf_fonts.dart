import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../resume_font_weight.dart';
import '../../resume_text_font.dart';
import 'resume_pdf_theme.dart';

/// EB Garamond (bundled as Garamond) for accent-strip headings in PDF export.
class GaramondPdfFonts {
  GaramondPdfFonts._({required this.upright, required this.italic});

  final pw.Font upright;
  final pw.Font italic;

  pw.Font fontFor(int weight, {bool useItalic = false}) {
    if (useItalic) {
      return italic;
    }
    return upright;
  }
}

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
  final normalized = ResumeFontWeight.normalize(weight);
  final pdfWeight = normalized >= ResumeFontWeight.w700
      ? pw.FontWeight.bold
      : pw.FontWeight.normal;

  return pw.TextStyle(
    inherit: false,
    color: color ?? PdfColors.black,
    font: font,
    fontNormal: font,
    fontBold: font,
    fontItalic: fonts.italic,
    fontBoldItalic: fonts.italic,
    fontSize: fontSize ?? ResumeTypography.bodyPt,
    fontWeight: pdfWeight,
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
  final upright = await loadPdfTtf('assets/fonts/garamond/Garamond-Variable.ttf');
  final italic = await loadPdfTtf(
    'assets/fonts/garamond/Garamond-Italic-Variable.ttf',
  );
  return GaramondPdfFonts._(upright: upright, italic: italic);
}
