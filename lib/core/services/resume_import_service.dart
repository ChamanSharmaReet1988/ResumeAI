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

      addCandidate(extractor.extractText());

      final textLines = extractor.extractTextLines();
      if (textLines.isNotEmpty) {
        addCandidate(_buildPdfTopSortedText(textLines));
        addCandidate(_buildPdfColumnAwareText(textLines, document));
      }

      return candidates;
    } finally {
      document.dispose();
    }
  }

  String _buildPdfTopSortedText(List<sfpdf.TextLine> textLines) {
    final sorted = [...textLines]..sort(_comparePdfTextLines);
    return sorted.map((line) => line.text.trim()).join('\n');
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
