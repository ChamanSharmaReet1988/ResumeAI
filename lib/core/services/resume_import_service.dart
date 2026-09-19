import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:xml/xml.dart';

import '../models/resume_models.dart';

class ImportedResumeFile {
  const ImportedResumeFile({
    required this.fileName,
    required this.resumeText,
    this.candidateResumeTexts = const [],
  });

  final String fileName;
  final String resumeText;
  final List<String> candidateResumeTexts;

  List<String> get allResumeTexts {
    final values = <String>[];
    final seen = <String>{};

    void add(String value) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return;
      }
      final dedupeKey = normalized
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();
      if (seen.add(dedupeKey)) {
        values.add(normalized);
      }
    }

    add(resumeText);
    for (final value in candidateResumeTexts) {
      add(value);
    }
    return values;
  }

  String get suggestedTitle {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName.trim();
    }
    return fileName.substring(0, dotIndex).trim();
  }
}

class ResumeImportException implements Exception {
  const ResumeImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ResumeImportService {
  const ResumeImportService();

  /// PDF-only cleanup of leftover list-marker glyphs. Exposed for tests.
  @visibleForTesting
  String sanitizePdfExtractedText(String text) => _sanitizePdfExtractedText(text);

  Future<ImportedResumeFile?> pickResumeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'docx', 'txt'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return importPlatformFile(result.files.single);
  }

  @visibleForTesting
  Future<ImportedResumeFile> importPlatformFile(PlatformFile file) async {
    final bytes = await _loadBytes(file);
    final extension = _extensionFor(file.name);
    final textCandidates = switch (extension) {
      'pdf' => _extractPdfTextCandidates(bytes),
      'docx' => [_extractDocxText(bytes)],
      'txt' => [_decodePlainText(bytes)],
      _ => throw const ResumeImportException(
        'Please upload a PDF, DOCX, or TXT resume.',
      ),
    };

    final normalizedCandidates = textCandidates
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (normalizedCandidates.isEmpty) {
      throw const ResumeImportException(
        'We could not extract readable text from that file. Try a text-based PDF, DOCX, or TXT resume.',
      );
    }

    return ImportedResumeFile(
      fileName: file.name,
      resumeText: normalizedCandidates.first,
      candidateResumeTexts: normalizedCandidates.skip(1).toList(),
    );
  }

  Future<Uint8List> _loadBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }

    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return File(path).readAsBytes();
    }

    throw const ResumeImportException(
      'Could not read that file from your device.',
    );
  }

  String _extensionFor(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _decodePlainText(Uint8List bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  List<String> _extractPdfTextCandidates(Uint8List bytes) {
    final document = sfpdf.PdfDocument(inputBytes: bytes);
    try {
      final extractor = sfpdf.PdfTextExtractor(document);
      final candidates = <String>[];
      final seen = <String>{};

      void addCandidate(String value) {
        final normalized = _sanitizePdfExtractedText(value).trim();
        if (normalized.isEmpty) {
          return;
        }
        final dedupeKey = normalized
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim()
            .toLowerCase();
        if (seen.add(dedupeKey)) {
          candidates.add(normalized);
        }
      }

      final textLines = extractor.extractTextLines();
      if (textLines.isNotEmpty) {
        // Columns first: on two-column resumes the top-sorted read interleaves
        // the sidebar with the main column and the parser cannot recover.
        addCandidate(_buildPdfSplitColumnText(textLines, document));
        addCandidate(_buildPdfTopSortedText(textLines));
        addCandidate(_buildPdfColumnAwareText(textLines, document));
      }

      // Some PDF writers (including this app's own exports) emit every word as
      // a separate text run, and the plain extractor then returns one word per
      // line. The line-based resume parser reads that as dozens of fake jobs,
      // so only fall back to it when the line-based reads produced nothing.
      final plainText = extractor.extractText();
      if (candidates.isEmpty || !_looksWordPerLine(plainText)) {
        addCandidate(plainText);
      }

      return candidates;
    } finally {
      document.dispose();
    }
  }

  bool _looksWordPerLine(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length < 8) {
      return false;
    }
    final words = lines.fold<int>(
      0,
      (total, line) => total + line.split(RegExp(r'\s+')).length,
    );
    return words / lines.length < 1.6;
  }

  static final _pdfDateOnlyLine = RegExp(
    r'^(?:(?:[A-Za-z]{3,9}\.?\s+)?\d{4}|present|current)'
    r'(?:\s*[-–—]+\s*(?:(?:[A-Za-z]{3,9}\.?\s+)?\d{4}|present|current))?$',
    caseSensitive: false,
  );

  String _buildPdfTopSortedText(List<sfpdf.TextLine> textLines) {
    final sorted = [...textLines]..sort(_comparePdfTextLines);
    final rows = <String>[];
    sfpdf.TextLine? previous;
    for (final line in sorted) {
      final text = _pdfLineText(line);
      // The extractor can split one visual row (a job title and its
      // right-aligned dates) into separate lines depending on font metrics,
      // so rejoin a dates-only line with the line at the same height. Other
      // same-height lines stay apart: in sidebar layouts they are different
      // columns.
      if (previous != null &&
          rows.isNotEmpty &&
          _pdfDateOnlyLine.hasMatch(text) &&
          previous.pageIndex == line.pageIndex &&
          line.bounds.left > previous.bounds.right &&
          (line.bounds.top - previous.bounds.top).abs() <
              math.max(previous.fontSize, line.fontSize) * 0.35) {
        rows[rows.length - 1] = '${rows.last} | $text';
      } else {
        rows.add(text);
      }
      previous = line;
    }
    return rows.join('\n');
  }

  /// Rebuilds a PDF text line from its words, marking wide horizontal gaps
  /// with " | ".
  ///
  /// The extractor merges everything at the same height into one line, so a
  /// two-column skills grid reads "Kotlin Jetpack Compose" and a right-aligned
  /// date sticks to the job title. A gap much wider than a normal space means
  /// separate items, which the resume parser already splits on "|".
  String _pdfLineText(sfpdf.TextLine line) {
    final words = line.wordCollection
        .where((word) => word.text.trim().isNotEmpty)
        .toList();
    if (words.length < 2) {
      return _sanitizePdfExtractedLine(line.text.trim());
    }
    // Letter-spaced headings ("S K I L L S") arrive as one run per letter, so
    // a fixed gap would split them into letters. Only on those lines, compare
    // each gap with the line's own typical gap.
    final kept = [...words];
    var droppedLeadingDingbat = false;
    while (kept.isNotEmpty && _isPdfDingbatToken(kept.first.text.trim())) {
      kept.removeAt(0);
      droppedLeadingDingbat = true;
    }
    while (kept.isNotEmpty && _isPdfDingbatToken(kept.last.text.trim())) {
      kept.removeLast();
    }
    if (kept.isEmpty) {
      return '';
    }

    final singleCharRuns = kept
        .where((word) => word.text.trim().length == 1)
        .length;
    final letterSpaced = singleCharRuns >= kept.length * 0.6;
    final gaps = <double>[
      for (var i = 1; i < kept.length; i++)
        kept[i].bounds.left - kept[i - 1].bounds.right,
    ]..sort();
    final medianGap = letterSpaced && gaps.isNotEmpty
        ? gaps[gaps.length ~/ 2]
        : 0.0;
    final buffer = StringBuffer(kept.first.text.trim());
    for (var i = 1; i < kept.length; i++) {
      final previous = kept[i - 1];
      final word = kept[i];
      final size = word.fontSize > 0 ? word.fontSize : word.bounds.height;
      final gap = word.bounds.left - previous.bounds.right;
      final spaceGap = math.max(size * 0.15, medianGap * 1.6);
      // Runs that touch belong to one token (an email drawn as
      // "name" "@" "gmail.com"), so only add a space for a visible gap.
      final separator = gap > math.max(size * 1.6, 12)
          ? ' | '
          : gap > spaceGap
          ? ' '
          : '';
      buffer
        ..write(separator)
        ..write(word.text.trim());
    }
    var text = buffer.toString();
    if (droppedLeadingDingbat && !RegExp(r'^[\-\u2022\*]').hasMatch(text)) {
      text = '- $text';
    }
    return _sanitizePdfExtractedLine(text);
  }

  /// Reads each page as separate columns when a vertical band of the page has
  /// no text crossing it — the shape of every sidebar or split layout.
  ///
  /// Returns an empty string when a page has no such band, so the caller can
  /// drop this candidate in favour of the top-sorted read.
  String _buildPdfSplitColumnText(
    List<sfpdf.TextLine> textLines,
    sfpdf.PdfDocument document,
  ) {
    final byPage = <int, List<sfpdf.TextLine>>{};
    for (final line in textLines) {
      byPage.putIfAbsent(line.pageIndex, () => <sfpdf.TextLine>[]).add(line);
    }

    final pageTexts = <String>[];
    var splitAnyPage = false;
    for (final pageIndex in byPage.keys.toList()..sort()) {
      final pageLines = [...byPage[pageIndex]!];
      final pageWidth = document.pages[pageIndex].size.width;
      final splitX = _pdfColumnSplitX(
        pageLines,
        pageWidth,
        document.pages[pageIndex].size.height,
      );
      if (splitX == null) {
        pageTexts.add(
          ([...pageLines]..sort(_comparePdfTextLines)).map(_pdfLineText).join('\n'),
        );
        continue;
      }
      splitAnyPage = true;
      // A line crossing the gutter is a full-width header (the nameplate), so
      // it leads, then the main column, then the sidebar.
      final header = pageLines
          .where((line) => line.bounds.left < splitX && line.bounds.right > splitX)
          .toList()
        ..sort(_comparePdfTextLines);
      final left = pageLines.where((line) => line.bounds.right <= splitX).toList()
        ..sort(_comparePdfTextLines);
      final right = pageLines.where((line) => line.bounds.left >= splitX).toList()
        ..sort(_comparePdfTextLines);
      pageTexts.add(
        [
          ...header.map(_pdfLineText),
          ...right.map(_pdfLineText),
          ...left.map(_pdfLineText),
        ].join('\n'),
      );
    }

    return splitAnyPage ? pageTexts.join('\n') : '';
  }

  /// X where a gutter separates two columns, or null when the page is one
  /// column. Looks for the widest vertical band that no line crosses.
  double? _pdfColumnSplitX(
    List<sfpdf.TextLine> pageLines,
    double pageWidth,
    double pageHeight,
  ) {
    final body = pageLines
        .where((line) => line.text.trim().isNotEmpty)
        .toList();
    if (body.length < 10) {
      return null;
    }

    double? bestX;
    var bestGap = 0.0;
    // Only a full-width header (the nameplate band at the top of the page)
    // may cross the gutter; body text crossing means this x cuts content.
    final headerBandBottom = pageHeight * 0.24;
    for (var x = pageWidth * 0.22; x <= pageWidth * 0.62; x += 4) {
      final crossesBody = body.any(
        (line) =>
            line.bounds.left < x &&
            line.bounds.right > x &&
            line.bounds.bottom > headerBandBottom,
      );
      if (crossesBody) {
        continue;
      }
      final leftLines = body.where((line) => line.bounds.right <= x).toList();
      final rightLines = body.where((line) => line.bounds.left >= x).toList();
      // Both sides need real content, or this is just a page margin.
      if (leftLines.length < 5 || rightLines.length < 8) {
        continue;
      }
      final leftEdge = leftLines
          .map((line) => line.bounds.right)
          .reduce((a, b) => a > b ? a : b);
      final rightEdge = rightLines
          .map((line) => line.bounds.left)
          .reduce((a, b) => a < b ? a : b);
      final gap = rightEdge - leftEdge;
      if (gap > bestGap) {
        bestGap = gap;
        bestX = x;
      }
    }

    // A real gutter is wider than the spaces inside a line of text.
    return bestGap >= 12 ? bestX : null;
  }

  String _buildPdfColumnAwareText(
    List<sfpdf.TextLine> textLines,
    sfpdf.PdfDocument document,
  ) {
    final byPage = <int, List<sfpdf.TextLine>>{};
    for (final line in textLines) {
      byPage.putIfAbsent(line.pageIndex, () => <sfpdf.TextLine>[]).add(line);
    }

    final pageTexts = <String>[];
    final pageIndexes = byPage.keys.toList()..sort();

    for (final pageIndex in pageIndexes) {
      final pageLines = [...byPage[pageIndex]!]..sort(_comparePdfTextLines);
      final pageWidth = document.pages[pageIndex].size.width;

      final leftThreshold = pageWidth * 0.30;
      final farRightThreshold = pageWidth * 0.42;
      final leftColumn = pageLines
          .where((line) => line.bounds.left <= leftThreshold)
          .toList();
      final mainColumn = pageLines
          .where((line) => line.bounds.left > leftThreshold)
          .toList();
      final hasLikelySidebar =
          leftColumn.length >= 3 &&
          mainColumn.length >= 3 &&
          mainColumn.any((line) => line.bounds.left >= farRightThreshold);

      final ordered = hasLikelySidebar
          ? [
              ...leftColumn..sort(_comparePdfTextLines),
              ...mainColumn..sort(_comparePdfTextLines),
            ]
          : pageLines;

      pageTexts.add(ordered.map(_pdfLineText).join('\n'));
    }

    return pageTexts.join('\n');
  }

  int _comparePdfTextLines(sfpdf.TextLine a, sfpdf.TextLine b) {
    final pageCompare = a.pageIndex.compareTo(b.pageIndex);
    if (pageCompare != 0) {
      return pageCompare;
    }

    final verticalDelta = (a.bounds.top - b.bounds.top).abs();
    if (verticalDelta > math.max(a.fontSize, b.fontSize) * 0.55) {
      return a.bounds.top.compareTo(b.bounds.top);
    }

    return a.bounds.left.compareTo(b.bounds.left);
  }

  /// PDF list markers often extract as a leftover glyph: Word PUA bullets,
  /// ZapfDingbats as "x", or a CJK lookalike such as "龱". Strip those only
  /// here so DOCX import is unchanged.
  String _sanitizePdfExtractedText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map(_sanitizePdfExtractedLine)
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  String _sanitizePdfExtractedLine(String line) {
    var value = stripPdfListMarkerLeftovers(line);
    if (value.isEmpty || _isPdfDingbatToken(value)) {
      return '';
    }

    final hadStandardMarker = RegExp(r'^[\-\u2022\*]\s*').hasMatch(value);
    final hadDingbatMarker = _pdfLeadingDingbat.hasMatch(value);
    value = value.replaceFirst(RegExp(r'^[\-\u2022\*]\s*'), '');
    value = value.replaceFirst(_pdfLeadingDingbat, '');
    value = value.replaceFirst(_pdfTrailingDingbat, '');
    value = stripPdfListMarkerLeftovers(value);
    if (value.isEmpty || _isPdfDingbatToken(value)) {
      return '';
    }
    if (hadStandardMarker || hadDingbatMarker) {
      return '- $value';
    }
    return value;
  }

  bool _isPdfDingbatToken(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final units = trimmed.runes.toList();
    if (units.length > 2) {
      return false;
    }
    if (_pdfSymbolDingbatToken.hasMatch(trimmed)) {
      return true;
    }
    // Lone CJK ideograph as a PDF list-marker leftover (screenshot: 龱).
    return units.length == 1 && units.first >= 0x4E00 && units.first <= 0x9FFF;
  }

  static final _pdfSymbolDingbatToken = RegExp(
    '^[${_pdfDingbatChars}xX]+\$',
  );

  static final _pdfLeadingDingbat = RegExp(
    '^(?:[$_pdfDingbatChars]|[xX](?=\\s))+\\s*',
  );

  static final _pdfTrailingDingbat = RegExp(
    '\\s*[$_pdfDingbatChars]+\\s*\$',
  );

  // Geometric bullets, ballot/cross marks, and Word PUA dingbats. Built as a
  // Dart string so \\u escapes become real code points before the regex runs.
  static const String _pdfDingbatChars =
      '\u00B7\u2022\u2023\u2043\u2219\u2327\u2573\u25A0-\u25FF'
      '\u2610-\u2613\u2713-\u2718\u00D7\u2A2F\uFFFD\uF000-\uF8FF';

  String _extractDocxText(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? documentFile;
    for (final file in archive.files) {
      if (file.name == 'word/document.xml') {
        documentFile = file;
        break;
      }
    }

    if (documentFile == null) {
      throw const ResumeImportException(
        'Could not read text from that DOCX file.',
      );
    }

    final content = documentFile.content as List<int>;
    final xmlString = utf8.decode(content, allowMalformed: true);
    final document = XmlDocument.parse(xmlString);
    final paragraphs = <String>[];

    for (final paragraph in document.findAllElements('w:p')) {
      final buffer = StringBuffer();
      for (final node in paragraph.descendants) {
        if (node is XmlElement && node.name.qualified == 'w:t') {
          buffer.write(node.innerText);
        } else if (node is XmlElement &&
            (node.name.qualified == 'w:tab' || node.name.qualified == 'w:br')) {
          buffer.write(' ');
        }
      }

      final text = buffer.toString().trim();
      if (text.isNotEmpty) {
        paragraphs.add(text);
      }
    }

    return paragraphs.join('\n').trim();
  }
}
