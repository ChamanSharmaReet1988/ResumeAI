import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:xml/xml.dart';

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
        final normalized = value
            .replaceAll('\r\n', '\n')
            .replaceAll('\r', '\n')
            .trim();
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

  String _buildPdfTopSortedText(List<sfpdf.TextLine> textLines) {
    final sorted = [...textLines]..sort(_comparePdfTextLines);
    return sorted.map(_pdfLineText).join('\n');
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
      return line.text.trim();
    }
    final buffer = StringBuffer(words.first.text.trim());
    for (var i = 1; i < words.length; i++) {
      final previous = words[i - 1];
      final word = words[i];
      final size = word.fontSize > 0 ? word.fontSize : word.bounds.height;
      final gap = word.bounds.left - previous.bounds.right;
      // Runs that touch belong to one token (an email drawn as
      // "name" "@" "gmail.com"), so only add a space for a visible gap.
      final separator = gap > math.max(size * 1.6, 12)
          ? ' | '
          : gap > size * 0.15
          ? ' '
          : '';
      buffer
        ..write(separator)
        ..write(word.text.trim());
    }
    return buffer.toString();
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

      pageTexts.add(ordered.map((line) => line.text.trim()).join('\n'));
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
