import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:xml/xml.dart';

import '../models/resume_models.dart';
import 'resume_pdf_data.dart';
import 'resume_services.dart' show LocalAiResumeService;

class ImportedResumeFile {
  const ImportedResumeFile({
    required this.fileName,
    required this.resumeText,
    this.candidateResumeTexts = const [],
    this.exportedResumeJson,
  });

  final String fileName;
  final String resumeText;
  final List<String> candidateResumeTexts;

  /// The resume stored in a PDF this app exported, when it still matches the
  /// PDF's text (see `resume_pdf_data.dart`).
  final String? exportedResumeJson;

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

  /// [onFilePicked] runs once the user has chosen a file, before it is read
  /// and parsed — the moment to show a loading state, since the picker itself
  /// should not be covered by one.
  Future<ImportedResumeFile?> pickResumeFile({
    Future<void> Function()? onFilePicked,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'docx', 'txt'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    await onFilePicked?.call();
    return importPlatformFile(result.files.single);
  }

  @visibleForTesting
  Future<ImportedResumeFile> importPlatformFile(PlatformFile file) async {
    final bytes = await _loadBytes(file);
    final extension = _extensionFor(file.name);
    if (extension != 'pdf' && extension != 'docx' && extension != 'txt') {
      throw const ResumeImportException(
        'Please upload a PDF, DOCX, or TXT resume.',
      );
    }
    // Reading a PDF tries several column strategies and is slow; run it off
    // the UI thread so the loading indicator keeps moving while it works.
    final textCandidates = await Isolate.run(
      () => _extractTextCandidates(extension, bytes),
    );
    final exportedResumeJson = extension == 'pdf' && hasResumePdfData(bytes)
        ? await Isolate.run(() => _readExportedResume(bytes))
        : null;

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
      exportedResumeJson: exportedResumeJson,
    );
  }

  String? _readExportedResume(Uint8List bytes) {
    final document = sfpdf.PdfDocument(inputBytes: bytes);
    try {
      return readResumePdfData(
        bytes,
        sfpdf.PdfTextExtractor(document).extractText(),
      );
    } finally {
      document.dispose();
    }
  }

  List<String> _extractTextCandidates(String extension, Uint8List bytes) =>
      switch (extension) {
        'pdf' => _extractPdfTextCandidates(bytes),
        'docx' => [_extractDocxText(bytes)],
        _ => [_decodePlainText(bytes)],
      };

  /// Turns an imported file into a resume, off the UI thread. Parsing runs a
  /// lot of pattern matching over every candidate text, which is slow enough
  /// on a phone to freeze the screen if done in place.
  Future<ResumeData> parseInBackground(
    ImportedResumeFile file, {
    required ResumeTemplate template,
  }) {
    final resumeText = file.resumeText;
    final candidates = file.candidateResumeTexts;
    final exportedResumeJson = file.exportedResumeJson;
    final title = file.suggestedTitle;
    return Isolate.run(
      () => LocalAiResumeService().parseImportedResumeText(
        resumeText: resumeText,
        candidateResumeTexts: candidates,
        exportedResumeJson: exportedResumeJson,
        template: template,
        sourceTitle: title,
      ),
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

      String plainText;
      try {
        plainText = extractor.extractText();
      } catch (_) {
        plainText = '';
      }

      // Some documents make the line extractor throw (a RangeError inside
      // syncfusion). One failing strategy must not abort the import, so the
      // draw-order and plain-text reads below still get their chance.
      List<sfpdf.TextLine> textLines;
      try {
        textLines = extractor.extractTextLines();
      } catch (_) {
        textLines = const <sfpdf.TextLine>[];
        try {
          addCandidate(
            _buildPdfDrawOrderText(
              plainText,
              extractor.extractText(layoutText: true),
            ),
          );
        } catch (_) {
          // Fall through to the plain-text read.
        }
      }
      if (textLines.isNotEmpty) {
        // Columns first: on two-column resumes the top-sorted read interleaves
        // the sidebar with the main column and the parser cannot recover.
        for (final build in [
          () => _buildPdfSplitColumnText(textLines, document),
          () => _buildPdfTopSortedText(textLines),
          () => _buildPdfColumnAwareText(textLines, document),
        ]) {
          try {
            addCandidate(
              _restoreGarbledWords(
                _restoreDroppedMonths(build(), plainText),
                plainText,
              ),
            );
          } catch (_) {
            // Skip this reading strategy and keep the others.
          }
        }
      }

      // Some PDF writers (including this app's own exports) emit every word as
      // a separate text run, and the plain extractor then returns one word per
      // line. The line-based resume parser reads that as dozens of fake jobs,
      // so only fall back to it when the line-based reads produced nothing.
      if (plainText.isNotEmpty &&
          (candidates.isEmpty || !_looksWordPerLine(plainText))) {
        addCandidate(plainText);
      }

      return candidates;
    } finally {
      document.dispose();
    }
  }

  static const _pdfMonthPattern =
      r'(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?';

  /// The line extractor can lose a word at the start of a line ("Jan 2021 -
  /// Present" reads "2021 - Present") that the plain read still has, so a range
  /// opening on a bare year takes its month back from there.
  String _restoreDroppedMonths(String text, String plainText) {
    final plain = plainText.replaceAll(RegExp(r'\s+'), ' ');
    final rows = text.split('\n');
    for (var i = 0; i < rows.length; i++) {
      // The month is not lost when it just wrapped: "... | January" above.
      final above = i == 0 ? '' : rows[i - 1];
      rows[i] = rows[i].replaceAllMapped(
        RegExp(
          r'(?<![A-Za-z.] ?)\b(?:19|20)\d{2} [-–—] '
          '(?:(?:$_pdfMonthPattern )?\\d{4}|present|current|now)',
          caseSensitive: false,
        ),
        (match) {
          final range = match.group(0)!;
          final month = RegExp(
            '\\b($_pdfMonthPattern) ${RegExp.escape(range)}',
            caseSensitive: false,
          ).firstMatch(plain);
          final wrapped =
              month != null &&
              match.start == 0 &&
              above.toLowerCase().endsWith(month.group(1)!.toLowerCase());
          return month == null || wrapped
              ? range
              : '${month.group(1)} $range';
        },
      );
    }
    return rows.join('\n');
  }

  /// The line extractor can also cut a word short ("redesign t improved"). A
  /// word the plain read does not have takes its place back from there, when
  /// the same two neighbours surround a longer word holding it.
  String _restoreGarbledWords(String text, String plainText) {
    final plain = plainText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final known = plain.toSet();
    return text
        .split('\n')
        .map((row) {
          final words = row.split(' ');
          for (var i = 1; i < words.length - 1; i++) {
            if (known.contains(words[i]) || words[i] == '|') {
              continue;
            }
            for (var k = 1; k < plain.length - 1; k++) {
              if (plain[k - 1] == words[i - 1] &&
                  plain[k + 1] == words[i + 1] &&
                  plain[k].contains(words[i])) {
                words[i] = plain[k];
                break;
              }
            }
          }
          return words.join(' ');
        })
        .join('\n');
  }

  /// Rows in drawing order, for when the line extractor fails. The layout read
  /// knows where rows end but loses the spaces; the plain read has the words
  /// but not the rows. Together they give the text without any positions, and
  /// returns an empty string when the two reads disagree.
  String _buildPdfDrawOrderText(String plainText, String layoutText) {
    final words = plainText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    var next = 0;
    final rows = <String>[];
    for (final line in layoutText.split(RegExp(r'[\r\n]+'))) {
      var rest = line.replaceAll(RegExp(r'\s+'), '');
      final row = <String>[];
      while (rest.isNotEmpty) {
        if (next >= words.length || !rest.startsWith(words[next])) {
          return '';
        }
        rest = rest.substring(words[next].length);
        row.add(words[next++]);
      }
      if (row.isNotEmpty) {
        rows.addAll(_splitDrawOrderRow(row));
      }
    }
    return _mainColumnFirst(_repairDrawOrderRows(rows)).join('\n');
  }

  /// Puts back what running rows together broke: a bullet alone on its row
  /// belongs to the next one, and the title before a dates row can be stuck to
  /// the end of the line above ("... rural regions Android Developer").
  List<String> _repairDrawOrderRows(List<String> rows) {
    final repaired = <String>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row == '\u2022' && i + 1 < rows.length) {
        rows[i + 1] = '\u2022 ${rows[i + 1]}';
        continue;
      }
      // "Infosys Maintained internal tools.", below a dates row and a title.
      final company = RegExp(
        r'^((?:[A-Z]\S* )+)([A-Z][a-z]+ [a-z].*[.!?])$',
      ).firstMatch(row);
      if (company != null &&
          repaired.length >= 2 &&
          _pdfDateRange.hasMatch(
            repaired[repaired.length - 2].replaceFirst('(', ''),
          )) {
        repaired
          ..add(company.group(1)!.trim())
          ..add(company.group(2)!);
        continue;
      }
      final title =
          i + 1 < rows.length &&
              _pdfDateRange.hasMatch(rows[i + 1].replaceFirst('(', ''))
          ? _pdfTrailingTitleStart(row)
          : null;
      if (title == null) {
        repaired.add(row);
      } else {
        repaired
          ..add(row.substring(0, title).trim())
          ..add(row.substring(title));
      }
    }
    return repaired;
  }

  /// Where a row's trailing title starts, or null if it has none: the last run
  /// of capitalised words after a lowercase word, from a word ending in a comma
  /// if the run has one ("... of Technology Bombay B.Tech, Computer Science").
  int? _pdfTrailingTitleStart(String row) {
    final run = RegExp(
      r'(?<=(?:^|\s)[a-z][^\s]* )(?:[A-Z][^\s]* )*[A-Z][^\s]*$',
    ).firstMatch(row);
    if (run == null) {
      return null;
    }
    final comma = RegExp(r'[^\s]+, ').firstMatch(run.group(0)!);
    return run.start + (comma?.start ?? 0);
  }

  /// Some layouts draw the sidebar first, leaving the name after the contact
  /// lines and skills where it cannot be found. Starts from the name instead:
  /// the short rows just before a heading, once a sidebar has been read.
  List<String> _mainColumnFirst(List<String> rows) {
    final firstHeading = rows.indexWhere(_isPdfHeadingRow);
    final sidebarFirst =
        firstHeading >= 0 &&
        rows
            .take(firstHeading)
            .every((row) => RegExp(r'^[A-Z]{1,3}$').hasMatch(row));
    if (!sidebarFirst) {
      return rows;
    }
    bool isNameplateRow(String row) =>
        !row.startsWith('\u2022') &&
        !_isPdfHeadingRow(row) &&
        !RegExp(r'[@/\d,]').hasMatch(row) &&
        row.split(' ').length <= 6;
    for (var i = firstHeading + 2; i < rows.length; i++) {
      if (_isPdfHeadingRow(rows[i]) &&
          isNameplateRow(rows[i - 1]) &&
          (isNameplateRow(rows[i - 2]) || i - 2 == firstHeading)) {
        final start = isNameplateRow(rows[i - 2]) ? i - 2 : i - 1;
        return [...rows.sublist(start), ...rows.sublist(0, start)];
      }
    }
    return rows;
  }

  bool _isPdfHeadingRow(String row) {
    final words = row.split(' ');
    return _pdfHeadingLengthAt(words, 0) == words.length;
  }

  static const _pdfSectionHeadings = <List<String>>[
    ['Professional', 'Summary'],
    ['Summary'],
    ['Profile'],
    ['About', 'Me'],
    ['Objective'],
    ['Work', 'Experience'],
    ['Professional', 'Experience'],
    ['Experience'],
    ['Education'],
    ['Skills'],
    ['Projects'],
    ['Contact'],
    ['Details'],
    ['Certifications'],
    ['Languages'],
  ];

  static final _pdfDateRange = RegExp(
    '^(?:(?:$_pdfMonthPattern )?\\d{4}) [-\u2013\u2014] '
    '(?:(?:$_pdfMonthPattern )?\\d{4}|present|current|now)',
    caseSensitive: false,
  );

  /// The layout read sometimes runs several visual rows into one. Breaks a row
  /// at what cannot share a row: bullets, section headings and date ranges.
  List<String> _splitDrawOrderRow(List<String> words) {
    final rows = <List<String>>[<String>[]];
    void breakRow() {
      if (rows.last.isNotEmpty) {
        rows.add(<String>[]);
      }
    }

    for (var i = 0; i < words.length;) {
      final heading = _pdfHeadingLengthAt(words, i);
      if (heading > 0) {
        breakRow();
        rows.last.addAll(words.sublist(i, i + heading));
        breakRow();
        i += heading;
        continue;
      }
      final range = _pdfDateRange.stringMatch(
        words.skip(i).join(' ').replaceFirst(RegExp(r'^\('), ''),
      );
      if (range != null) {
        breakRow();
        final length = range.split(' ').length;
        rows.last.addAll(words.sublist(i, i + length));
        breakRow();
        i += length;
        continue;
      }
      if (words[i] == '\u2022') {
        breakRow();
      }
      rows.last.add(words[i]);
      // A finished sentence followed by a dated title is a new entry.
      if (RegExp(r'[.!?]$').hasMatch(words[i]) &&
          words.skip(i + 1).any((word) => RegExp(r'^\d{4}$').hasMatch(word))) {
        breakRow();
      }
      i++;
    }
    return rows
        .where((row) => row.isNotEmpty)
        .map((row) => row.join(' '))
        .toList();
  }

  /// Length of the section heading starting at [index] in [words], or 0. Inside
  /// a row only an all-caps heading counts, or one that ends the row and is not
  /// part of a phrase like "Head of Education".
  int _pdfHeadingLengthAt(List<String> words, int index) {
    for (final heading in _pdfSectionHeadings) {
      final end = index + heading.length;
      if (end > words.length) {
        continue;
      }
      final found = words.sublist(index, end);
      final isUpper = found.join() == heading.join().toUpperCase();
      if (!isUpper && found.join() != heading.join()) {
        continue;
      }
      final isWholeRow = index == 0 && end == words.length;
      // "Contact +91 98200 11223", "Infosys Skills Kotlin Java": these are not
      // words a sentence capitalises.
      final opensList = const {
        'Contact',
        'Details',
        'Skills',
      }.contains(found.join(' '));
      final endsRow =
          index > 0 &&
          (end == words.length || opensList) &&
          !const {
            'of',
            'in',
            'and',
            'for',
            'the',
            '&',
          }.contains(words[index - 1].toLowerCase());
      if (isUpper || isWholeRow || endsRow || (index == 0 && opensList)) {
        return heading.length;
      }
    }
    return 0;
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
    return _sanitizePdfExtractedLine(_datesAfterTitle(text));
  }

  /// Date-column layouts read "2019 - 2021 | Project Lead"; the parser expects
  /// the title first, as every other layout gives it.
  static final RegExp _leadingDateRange = RegExp(
    r'^((?:[A-Za-z]{3,9}\.?\s+)?\d{4}\s*[-\u2013\u2014]\s*'
    r'(?:(?:[A-Za-z]{3,9}\.?\s+)?\d{4}|Present|Current|Now))'
    r'\s*(?:\|\s*)?([A-Za-z].*)$',
    caseSensitive: false,
  );

  String _datesAfterTitle(String text) {
    final match = _leadingDateRange.firstMatch(text);
    if (match == null) return text;
    return '${match.group(2)} | ${match.group(1)}';
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
    // Read after every page's main column, so a section running onto the next
    // page is not cut in two by the sidebar beside it.
    final sidebarTexts = <String>[];
    // Except a sidebar holding the name: that one opens the document.
    var nameplateText = '';
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
      // it leads. The main column is the one with more text, on whichever side
      // that is.
      final header = pageLines
          .where((line) => line.bounds.left < splitX && line.bounds.right > splitX)
          .toList()
        ..sort(_comparePdfTextLines);
      final left = pageLines.where((line) => line.bounds.right <= splitX).toList()
        ..sort(_comparePdfTextLines);
      final right = pageLines.where((line) => line.bounds.left >= splitX).toList()
        ..sort(_comparePdfTextLines);
      int textLength(List<sfpdf.TextLine> lines) =>
          lines.fold(0, (total, line) => total + line.text.length);
      // A monogram in an avatar circle can be set larger than the name.
      double largestType(List<sfpdf.TextLine> lines) => lines
          .where((line) => !RegExp(r'^[A-Z]{1,3}$').hasMatch(line.text.trim()))
          .fold(0.0, (largest, line) => math.max(largest, line.fontSize));
      final main = textLength(right) >= textLength(left) ? right : left;
      final sidebar = identical(main, right) ? left : right;
      final sidebarText = sidebar.map(_pdfLineText).join('\n');
      pageTexts.add([...header, ...main].map(_pdfLineText).join('\n'));
      if (pageTexts.length == 1 && largestType(sidebar) > largestType(main)) {
        nameplateText = sidebarText;
      } else {
        sidebarTexts.add(sidebarText);
      }
    }

    return splitAnyPage
        ? [nameplateText, ...pageTexts, ...sidebarTexts]
              .where((text) => text.isNotEmpty)
              .join('\n')
        : '';
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
    for (var x = pageWidth * 0.22; x <= pageWidth * 0.7; x += 4) {
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
      // Both sides need real content, or this is just a page margin. The
      // sidebar can be on either side.
      if (math.min(leftLines.length, rightLines.length) < 4 ||
          math.max(leftLines.length, rightLines.length) < 8) {
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
