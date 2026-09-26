part of 'package:resume_app/core/services/resume_services.dart';

/// Four professional and four creative cover letter layouts, sharing the
/// typography helpers used by the original letters.
extension _ResumePdfCoverLetterExtraPages on ResumePdfService {
  /// Shared text styles so each layout only describes its own header.
  ({
    pw.TextStyle name,
    pw.TextStyle meta,
    pw.TextStyle heading,
    pw.TextStyle body,
    pw.TextStyle signature,
  })
  _coverLetterExtraStyles(
    CoverLetterData coverLetter,
    GaramondPdfFonts fonts,
    List<pw.Font> fontFallback, {
    required PdfColor accent,
    PdfColor? metaColor,
    double nameScale = 1,
  }) {
    return (
      name: _coverLetterPdfStyle(
        fonts,
        weight: ResumeFontWeight.w700,
        fontSize: _coverLetterNamePt(coverLetter) * nameScale,
        color: accent,
        fontFallback: fontFallback,
      ),
      meta: _coverLetterPdfStyle(
        fonts,
        weight: ResumeFontWeight.w400,
        fontSize: _coverLetterBodyPt(coverLetter),
        color: metaColor ?? PdfColor.fromHex('#5E6369'),
        fontFallback: fontFallback,
      ),
      heading: _coverLetterPdfStyle(
        fonts,
        weight: ResumeFontWeight.w500,
        fontSize: _coverLetterHeadingPt(coverLetter),
        color: _coverLetterBodyTextPdf(),
        fontFallback: fontFallback,
      ),
      body: _coverLetterPdfStyle(
        fonts,
        weight: ResumeFontWeight.w400,
        fontSize: _coverLetterBodyPt(coverLetter),
        color: _coverLetterBodyTextPdf(),
        lineHeight: 1.55,
        fontFallback: fontFallback,
      ),
      signature: _coverLetterPdfStyle(
        fonts,
        weight: ResumeFontWeight.w700,
        fontSize: _coverLetterHeadingPt(coverLetter),
        color: _coverLetterBodyTextPdf(),
        fontFallback: fontFallback,
      ),
    );
  }

  /// Dark header band with the name and contact details reversed out of it.
  void _addCorporateHeaderCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts fonts,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final styles = _coverLetterExtraStyles(
      coverLetter,
      fonts,
      fontFallback,
      accent: PdfColors.white,
      metaColor: PdfColor.fromHex('#E2E8F0'),
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(40, 0, 40, 40),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            color: accent,
            padding: const pw.EdgeInsets.fromLTRB(32, 34, 32, 30),
            margin: const pw.EdgeInsets.only(left: -40, right: -40, bottom: 26),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(parsed.senderName.toUpperCase(), style: styles.name),
                if (parsed.senderDetails.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    parsed.senderDetails.join('   •   '),
                    style: styles.meta,
                  ),
                ],
              ],
            ),
          ),
          if (parsed.recipientLines.isNotEmpty) ...[
            pw.Text(
              parsed.recipientLines.join('\n'),
              style: styles.heading,
            ),
            pw.SizedBox(height: 16),
          ],
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: styles.body,
            headingStyle: styles.heading,
            signatureStyle: styles.signature,
          ),
        ],
      ),
    );
  }

  /// Name on the left, contact details boxed on the right.
  void _addBoxedContactCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts fonts,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final styles = _coverLetterExtraStyles(
      coverLetter,
      fonts,
      fontFallback,
      accent: accent,
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  parsed.senderName.toUpperCase(),
                  style: styles.name,
                ),
              ),
              if (parsed.senderDetails.isNotEmpty) ...[
                pw.SizedBox(width: 18),
                pw.Container(
                  width: 190,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: accent, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final detail in parsed.senderDetails)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Text(detail, style: styles.meta),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(height: 2, color: accent),
          pw.SizedBox(height: 20),
          if (parsed.recipientLines.isNotEmpty) ...[
            pw.Text(parsed.recipientLines.join('\n'), style: styles.heading),
            pw.SizedBox(height: 16),
          ],
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: styles.body,
            headingStyle: styles.heading,
            signatureStyle: styles.signature,
          ),
        ],
      ),
    );
  }

  /// Centred serif letterhead with a rule under the name.
  void _addSerifFormalCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts fonts,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final (dateLine, _) = _classicLetterDatePrefix(parsed.senderLines);
    final nameStyle = _coverLetterPdfStyle(
      fonts,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterNamePt(coverLetter),
      color: accent,
      fontFallback: fontFallback,
    );
    final metaStyle = _coverLetterPdfStyle(
      fonts,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter),
      color: PdfColor.fromHex('#4B5563'),
      fontFallback: fontFallback,
    );
    final headingStyle = _coverLetterPdfStyle(
      fonts,
      weight: ResumeFontWeight.w500,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );
    final bodyStyle = _coverLetterPdfStyle(
      fonts,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      lineHeight: 1.6,
      fontFallback: fontFallback,
    );
    final signatureStyle = _coverLetterPdfStyle(
      fonts,
      weight: ResumeFontWeight.w700,
      fontSize: _coverLetterHeadingPt(coverLetter),
      color: _coverLetterBodyTextPdf(),
      fontFallback: fontFallback,
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(52, 44, 52, 44),
        build: (context) => [
          pw.Center(
            child: pw.Text(parsed.senderName.toUpperCase(), style: nameStyle),
          ),
          if (parsed.senderDetails.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                parsed.senderDetails.join('   ·   '),
                style: metaStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Container(height: 0.9, color: accent),
          pw.SizedBox(height: 22),
          if (dateLine != null) ...[
            pw.Text(dateLine, style: headingStyle),
            pw.SizedBox(height: 16),
          ],
          if (parsed.recipientLines.isNotEmpty) ...[
            pw.Text(parsed.recipientLines.join('\n'), style: headingStyle),
            pw.SizedBox(height: 18),
          ],
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

  /// Circular monogram beside the name block.
  void _addMonogramCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts fonts,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final styles = _coverLetterExtraStyles(
      coverLetter,
      fonts,
      fontFallback,
      accent: accent,
      nameScale: 0.92,
    );
    final initials = _coverLetterInitials(parsed.senderName);

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(44, 44, 44, 40),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 64,
                height: 64,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: accent,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text(
                  initials,
                  style: _coverLetterPdfStyle(
                    fonts,
                    weight: ResumeFontWeight.w700,
                    fontSize: _coverLetterNamePt(coverLetter) * 0.8,
                    color: PdfColors.white,
                    fontFallback: fontFallback,
                  ),
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(parsed.senderName, style: styles.name),
                    if (parsed.senderDetails.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        parsed.senderDetails.join('   •   '),
                        style: styles.meta,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 26),
          if (parsed.recipientLines.isNotEmpty) ...[
            pw.Text(parsed.recipientLines.join('\n'), style: styles.heading),
            pw.SizedBox(height: 16),
          ],
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: styles.body,
            headingStyle: styles.heading,
            signatureStyle: styles.signature,
          ),
        ],
      ),
    );
  }

  /// Two-tone banner across the top of the page.
  void _addGradientBannerCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts fonts,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final deep = _pdfMix(accent, PdfColors.black, 0.45);
    final styles = _coverLetterExtraStyles(
      coverLetter,
      fonts,
      fontFallback,
      accent: PdfColors.white,
      metaColor: PdfColors.white,
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(44, 0, 44, 40),
        build: (context) => [
          // The banner bleeds to both page edges via negative margins on the
          // banner itself; inside a pw.Stack those margins are ignored, so the
          // stack lives within the bleeding container instead.
          pw.Container(
            width: double.infinity,
            height: 132,
            color: accent,
            margin: const pw.EdgeInsets.only(
              left: -44,
              right: -44,
              bottom: 28,
            ),
            child: pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                pw.Positioned(
                  left: 0,
                  bottom: 0,
                  child: pw.Container(width: 165, height: 16, color: deep),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(44, 34, 44, 0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        parsed.senderName.toUpperCase(),
                        style: styles.name,
                      ),
                      if (parsed.senderDetails.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(
                          parsed.senderDetails.join('   •   '),
                          style: styles.meta,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (parsed.recipientLines.isNotEmpty) ...[
            pw.Text(parsed.recipientLines.join('\n'), style: styles.heading),
            pw.SizedBox(height: 16),
          ],
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: styles.body,
            headingStyle: styles.heading,
            signatureStyle: styles.signature,
          ),
        ],
      ),
    );
  }

  /// Tinted side panel carrying the contact details.
  void _addSidePanelCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts fonts,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final panel = _pdfMix(accent, PdfColors.white, 0.86);
    final styles = _coverLetterExtraStyles(
      coverLetter,
      fonts,
      fontFallback,
      accent: accent,
    );
    const panelWidth = 190.0;
    final panelTextStyle = _coverLetterPdfStyle(
      fonts,
      weight: ResumeFontWeight.w400,
      fontSize: _coverLetterBodyPt(coverLetter) - 1.4,
      color: PdfColor.fromHex('#4B5563'),
      fontFallback: fontFallback,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(panelWidth + 34, 44, 44, 44),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: pw.Container(width: panelWidth, color: panel),
                ),
                if (context.pageNumber == 1 && parsed.senderDetails.isNotEmpty)
                  pw.Positioned(
                    left: 24,
                    top: 120,
                    child: pw.SizedBox(
                      width: panelWidth - 44,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Details arrive as one joined line; the narrow
                          // panel reads better with one item per row.
                          for (final detail in parsed.senderDetails
                              .expand((line) => line.split(RegExp(r'\s*[|·•]\s*')))
                              .map((line) => line.trim())
                              .where((line) => line.isNotEmpty))
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Text(detail, style: panelTextStyle),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        build: (context) => [
          pw.Text(parsed.senderName.toUpperCase(), style: styles.name),
          pw.SizedBox(height: 10),
          pw.Container(width: 64, height: 3, color: accent),
          pw.SizedBox(height: 24),
          if (parsed.recipientLines.isNotEmpty) ...[
            pw.Text(parsed.recipientLines.join('\n'), style: styles.heading),
            pw.SizedBox(height: 16),
          ],
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: styles.body,
            headingStyle: styles.heading,
            signatureStyle: styles.signature,
          ),
        ],
      ),
    );
  }

  /// Thin accent frame drawn around the whole page.
  void _addOutlineFrameCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts fonts,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final styles = _coverLetterExtraStyles(
      coverLetter,
      fonts,
      fontFallback,
      accent: accent,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(60, 58, 60, 58),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(28),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: accent, width: 1.2),
                ),
              ),
            ),
          ),
        ),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              parsed.senderName.toUpperCase(),
              style: styles.name,
            ),
          ),
          if (parsed.senderDetails.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                parsed.senderDetails.join('   •   '),
                style: styles.meta,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
          pw.SizedBox(height: 24),
          if (parsed.recipientLines.isNotEmpty) ...[
            pw.Text(parsed.recipientLines.join('\n'), style: styles.heading),
            pw.SizedBox(height: 16),
          ],
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: styles.body,
            headingStyle: styles.heading,
            signatureStyle: styles.signature,
          ),
        ],
      ),
    );
  }

  /// Row of accent dots under the nameplate.
  void _addDotGridCoverLetterPage(
    pw.Document document,
    CoverLetterData coverLetter,
    _ParsedCoverLetterContent parsed, {
    required GaramondPdfFonts fonts,
    List<pw.Font> fontFallback = const <pw.Font>[],
  }) {
    final accent = _coverLetterHeaderPdf(coverLetter);
    final styles = _coverLetterExtraStyles(
      coverLetter,
      fonts,
      fontFallback,
      accent: accent,
    );

    pw.Widget dots(int count, double size, double opacityStep) => pw.Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) pw.SizedBox(width: 6),
          pw.Container(
            width: size,
            height: size,
            decoration: pw.BoxDecoration(
              color: _pdfMix(accent, PdfColors.white, i * opacityStep),
              shape: pw.BoxShape.circle,
            ),
          ),
        ],
      ],
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(44, 44, 44, 40),
        build: (context) => [
          dots(6, 9, 0.12),
          pw.SizedBox(height: 18),
          pw.Text(parsed.senderName.toUpperCase(), style: styles.name),
          if (parsed.senderDetails.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              parsed.senderDetails.join('   •   '),
              style: styles.meta,
            ),
          ],
          pw.SizedBox(height: 26),
          if (parsed.recipientLines.isNotEmpty) ...[
            pw.Text(parsed.recipientLines.join('\n'), style: styles.heading),
            pw.SizedBox(height: 16),
          ],
          ..._buildCoverLetterBodyWithStyles(
            parsed,
            bodyStyle: styles.body,
            headingStyle: styles.heading,
            signatureStyle: styles.signature,
          ),
        ],
      ),
    );
  }
}

/// Up to two initials for the monogram letterhead.
String _coverLetterInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return 'CL';
  }
  return parts.map((part) => part[0].toUpperCase()).join();
}

/// Blends [a] towards [b] by [t] (0–1).
PdfColor _pdfMix(PdfColor a, PdfColor b, double t) => PdfColor(
  a.red + (b.red - a.red) * t,
  a.green + (b.green - a.green) * t,
  a.blue + (b.blue - a.blue) * t,
);
