import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../resume_text_font.dart';

/// Cached PDF themes so repeated exports do not reload font bytes.
final Map<ResumeTextFont, pw.ThemeData> _resumePdfThemeCache = {};

/// Same [ResumeTextFont] choices as the in-app resume preview ([ResumePreviewCard]).
/// Embeds bundled TTFs so exported PDFs match the template typography instead of
/// built-in Helvetica.
Future<pw.ThemeData> resumePdfThemeForBodyFont(ResumeTextFont font) async {
  final cached = _resumePdfThemeCache[font];
  if (cached != null) {
    return cached;
  }
  try {
    final theme = await _buildEmbeddedFontTheme(font);
    _resumePdfThemeCache[font] = theme;
    return theme;
  } catch (_) {
    return _fallbackHelveticaTheme();
  }
}

pw.ThemeData _fallbackHelveticaTheme() {
  return pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    italic: pw.Font.helveticaOblique(),
    boldItalic: pw.Font.helveticaBoldOblique(),
  ).copyWith(
    defaultTextStyle: pw.TextStyle(fontSize: ResumeTypography.bodyPt),
    bulletStyle: pw.TextStyle(fontSize: ResumeTypography.bodyPt),
  );
}

Future<pw.ThemeData> _buildEmbeddedFontTheme(ResumeTextFont font) async {
  final fonts = await _loadPdfFonts(font);
  return pw.ThemeData.withFont(
    base: fonts.base,
    bold: fonts.bold,
    italic: fonts.italic,
    boldItalic: fonts.boldItalic,
  ).copyWith(
    defaultTextStyle: pw.TextStyle(fontSize: ResumeTypography.bodyPt),
    bulletStyle: pw.TextStyle(fontSize: ResumeTypography.bodyPt),
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

Future<pw.Font> _ttf(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return pw.Font.ttf(data);
}

Future<_PdfFontSlots> _loadPdfFonts(ResumeTextFont font) async {
  switch (font) {
    case ResumeTextFont.inter:
      final f = await _ttf('assets/fonts/inter/Inter-Variable.ttf');
      return _PdfFontSlots(base: f, bold: f, italic: f, boldItalic: f);
    case ResumeTextFont.aptos:
      final f = await _ttf('assets/fonts/sourcesans3/SourceSans3-Variable.ttf');
      return _PdfFontSlots(base: f, bold: f, italic: f, boldItalic: f);
    case ResumeTextFont.calibri:
      final reg = await _ttf('assets/fonts/carlito/Carlito-Regular.ttf');
      final bold = await _ttf('assets/fonts/carlito/Carlito-Bold.ttf');
      return _PdfFontSlots(base: reg, bold: bold, italic: reg, boldItalic: bold);
    case ResumeTextFont.arial:
      final f = await _ttf('assets/fonts/arimo/Arimo-Variable.ttf');
      return _PdfFontSlots(base: f, bold: f, italic: f, boldItalic: f);
    case ResumeTextFont.helvetica:
      final f = await _ttf('assets/fonts/worksans/WorkSans-Variable.ttf');
      return _PdfFontSlots(base: f, bold: f, italic: f, boldItalic: f);
  }
}
