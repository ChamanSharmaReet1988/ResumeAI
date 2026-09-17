import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' show TtfParser;
import 'package:pdf/widgets.dart' as pw;

import '../../resume_font_weight.dart';
import '../../resume_text_font.dart';
import 'inter_pdf_fonts.dart';

/// Cached PDF themes so repeated exports do not reload font bytes.
/// Key: `fontName_bodyPt` (body pt affects default/bullet styles).
final Map<String, pw.ThemeData> resumePdfThemeCache = {};

final Expando<double> _pdfFontLineHeightEm = Expando();

/// Height of one line of [font] in ems (ascent − descent). The pdf package
/// advances each wrapped line by this height and only then adds
/// [pw.TextStyle.lineSpacing].
double pdfFontLineHeightEm(pw.Font font) {
  if (font is! pw.TtfFont) {
    return 1;
  }
  return _pdfFontLineHeightEm[font] ??= () {
    final parser = TtfParser(font.data);
    return (parser.ascent - parser.descent) / parser.unitsPerEm;
  }();
}

/// Turns a spacing written as `(lineHeight − 1) × fontSize` into the gap the
/// pdf package needs so lines really sit `lineHeight × fontSize` apart.
///
/// Without this, each font's own line height (about 1.2em for Inter, 1.3em
/// for Garamond) was added on top, and body text rendered at 1.4–1.7×.
/// Never goes below the font's natural line height.
double pdfLineSpacingForFont(
  pw.Font font,
  double fontSize,
  double? lineSpacing,
) {
  if (lineSpacing == null || lineSpacing <= 0) {
    return lineSpacing ?? 0;
  }
  return math.max(
    0,
    lineSpacing - (pdfFontLineHeightEm(font) - 1) * fontSize,
  );
}

/// Same [ResumeTextFont] choices as the in-app resume preview ([ResumePreviewCard]).
/// Embeds bundled TTFs so exported PDFs match the template typography instead of
/// built-in Helvetica.
///
/// [bodyFontPt] overrides default body size (11–13 pt); defaults to [ResumeTypography.bodyPt].
Future<pw.ThemeData> resumePdfThemeForBodyFont(
  ResumeTextFont font, {
  double? bodyFontPt,
}) async {
  final pt = bodyFontPt ?? ResumeTypography.bodyPt;
  final lineSpacing = ResumeTypography.bodyPdfLineSpacingFor(pt);
  final cacheKey = '${font.name}_$pt';
  final cached = resumePdfThemeCache[cacheKey];
  if (cached != null) {
    return cached;
  }
  try {
    final theme = await _buildEmbeddedFontTheme(
      font,
      bodyPt: pt,
      lineSpacing: lineSpacing,
    );
    resumePdfThemeCache[cacheKey] = theme;
    return theme;
  } catch (_) {
    final fallback = _fallbackHelveticaTheme(
      bodyPt: pt,
      lineSpacing: lineSpacing,
    );
    resumePdfThemeCache[cacheKey] = fallback;
    return fallback;
  }
}

pw.ThemeData _fallbackHelveticaTheme({
  required double bodyPt,
  required double lineSpacing,
}) {
  return pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    italic: pw.Font.helveticaOblique(),
    boldItalic: pw.Font.helveticaBoldOblique(),
  ).copyWith(
    defaultTextStyle: pw.TextStyle(
      fontSize: bodyPt,
      lineSpacing: lineSpacing,
    ),
    bulletStyle: pw.TextStyle(
      fontSize: bodyPt,
      lineSpacing: lineSpacing,
    ),
  );
}

Future<pw.ThemeData> _buildEmbeddedFontTheme(
  ResumeTextFont font, {
  required double bodyPt,
  required double lineSpacing,
}) async {
  final fonts = await _loadPdfFonts(font);
  final spacing = pdfLineSpacingForFont(fonts.base, bodyPt, lineSpacing);
  return pw.ThemeData.withFont(
    base: fonts.base,
    bold: fonts.bold,
    italic: fonts.italic,
    boldItalic: fonts.boldItalic,
  ).copyWith(
    defaultTextStyle: pw.TextStyle(
      fontSize: bodyPt,
      lineSpacing: spacing,
    ),
    bulletStyle: pw.TextStyle(
      fontSize: bodyPt,
      lineSpacing: spacing,
    ),
  );
}

class _PdfFontSlots {
  const _PdfFontSlots({
    required this.base,
    required this.bold,
    required this.italic,
    required this.boldItalic,
  });

  final pw.Font base;
  final pw.Font bold;
  final pw.Font italic;
  final pw.Font boldItalic;
}

Future<pw.Font> loadPdfTtf(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return pw.Font.ttf(data);
}

Future<_PdfFontSlots> _loadPdfFonts(ResumeTextFont font) async {
  switch (font) {
    case ResumeTextFont.inter:
      final inter = await loadInterPdfFonts();
      return _PdfFontSlots(
        base: inter.w400,
        bold: inter.fontFor(ResumeFontWeight.w800),
        italic: inter.italic,
        boldItalic: inter.fontFor(ResumeFontWeight.w800),
      );
    case ResumeTextFont.aptos:
      final f = await loadPdfTtf('assets/fonts/sourcesans3/SourceSans3-Variable.ttf');
      return _PdfFontSlots(base: f, bold: f, italic: f, boldItalic: f);
    case ResumeTextFont.calibri:
      final reg = await loadPdfTtf('assets/fonts/carlito/Carlito-Regular.ttf');
      final bold = await loadPdfTtf('assets/fonts/carlito/Carlito-Bold.ttf');
      final italic = await loadPdfTtf('assets/fonts/carlito/Carlito-Italic.ttf');
      return _PdfFontSlots(
        base: reg,
        bold: bold,
        italic: italic,
        boldItalic: bold,
      );
    case ResumeTextFont.arial:
      final upright = await loadPdfTtf('assets/fonts/arimo/Arimo-Variable.ttf');
      final italic = await loadPdfTtf('assets/fonts/arimo/Arimo-Italic.ttf');
      return _PdfFontSlots(
        base: upright,
        bold: upright,
        italic: italic,
        boldItalic: italic,
      );
  }
}

extension ResumePdfLineSpacing on pw.TextStyle {
  /// [copyWith] for `lineSpacing` written as `(lineHeight - 1) * fontSize`,
  /// corrected for this style's font like [pdfLineSpacingForFont].
  pw.TextStyle withResumeLineSpacing(double lineSpacing) => copyWith(
    lineSpacing: font == null
        ? lineSpacing
        : pdfLineSpacingForFont(
            font!,
            fontSize ?? ResumeTypography.bodyPt,
            lineSpacing,
          ),
  );
}
