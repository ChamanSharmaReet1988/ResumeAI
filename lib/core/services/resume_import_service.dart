import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:xml/xml.dart';

class ImportedResumeFile {
  const ImportedResumeFile({required this.fileName, required this.resumeText});

  final String fileName;
  final String resumeText;

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
    final resumeText = switch (extension) {
      'pdf' => _extractPdfText(bytes),
      'docx' => _extractDocxText(bytes),
      'txt' => _decodePlainText(bytes),
      _ => throw const ResumeImportException(
        'Please upload a PDF, DOCX, or TXT resume.',
      ),
    };

    final normalizedText = resumeText.trim();
    if (normalizedText.isEmpty) {
      throw const ResumeImportException(
        'We could not extract readable text from that file. Try a text-based PDF, DOCX, or TXT resume.',
      );
    }

    return ImportedResumeFile(fileName: file.name, resumeText: normalizedText);
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

  String _extractPdfText(Uint8List bytes) {
    final document = sfpdf.PdfDocument(inputBytes: bytes);
    try {
      final text = sfpdf.PdfTextExtractor(document).extractText();
      return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    } finally {
      document.dispose();
    }
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

    final content = documentFile.content;
    if (content is! List<int>) {
      throw const ResumeImportException(
        'Could not read text from that DOCX file.',
      );
    }

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
