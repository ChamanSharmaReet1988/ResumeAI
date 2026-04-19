/// Default type scale for resume content (preview + PDF). Font family defaults to
/// [ResumeTextFont.inter] on [ResumeData.resumeTextFont].
abstract final class ResumeTypography {
  static const double bodyPt = 11;
  static const double headingPt = 13;
  static const double namePt = 17;

  /// In-app preview cards use a slightly smaller name when [compact] to reduce overflow.
  static double nameSizePreview(bool compact) => compact ? 14 : namePt;
}

/// User-facing resume body typefaces. Bundled files use open licenses (OFL / Apache).
///
/// **Calibri, Arial, Helvetica, Aptos** are common office fonts; we ship metric- or
/// style-compatible open fonts registered in [flutterFontFamily]. Exported PDFs
/// embed the same bundled TTFs as the PDF export so typography matches
/// the in-app template preview.
enum ResumeTextFont { inter, aptos, calibri, arial, helvetica }

extension ResumeTextFontX on ResumeTextFont {
  /// Label shown in the UI (matches common resume font names).
  String get label => switch (this) {
    ResumeTextFont.inter => 'Inter',
    ResumeTextFont.aptos => 'Aptos',
    ResumeTextFont.calibri => 'Calibri',
    ResumeTextFont.arial => 'Arial',
    ResumeTextFont.helvetica => 'Helvetica',
  };

  /// Must match `family:` in [pubspec.yaml] for the bundled font files.
  String get flutterFontFamily => switch (this) {
    ResumeTextFont.inter => 'Inter',
    ResumeTextFont.aptos => 'Source Sans 3',
    ResumeTextFont.calibri => 'Carlito',
    ResumeTextFont.arial => 'Arimo',
    ResumeTextFont.helvetica => 'Work Sans',
  };

  /// Short note for pickers (optional).
  String get hint => switch (this) {
    ResumeTextFont.inter => 'Modern UI font',
    ResumeTextFont.aptos => 'Office-style sans (Source Sans 3)',
    ResumeTextFont.calibri => 'Metric match: Carlito',
    ResumeTextFont.arial => 'Metric match: Arimo',
    ResumeTextFont.helvetica => 'Clean grotesque: Work Sans',
  };
}

ResumeTextFont resumeTextFontFromStorage(String? raw) {
  if (raw == null || raw.isEmpty) {
    return ResumeTextFont.inter;
  }
  for (final value in ResumeTextFont.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return ResumeTextFont.inter;
}
