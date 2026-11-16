import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../models/resume_models.dart';
import '../models/resume_builder_section_order.dart';

/// A copy of what an exported resume PDF prints, stored in the file's XMP
/// metadata so re-uploading it restores the resume exactly instead of working
/// it out from the page layout.
///
/// Only text that is printed on the page goes in, so a hidden section or a
/// field a template leaves out never travels with a shared PDF. The copy also
/// records a fingerprint of the printed text: if the PDF is edited afterwards
/// the two no longer match, and the upload reads the page as usual.
const _openTag = '<resumeai:resume>';
const _closeTag = '</resumeai:resume>';
const _maxEncodedLength = 256 * 1024;

/// Below this share of the resume's text found on the page, the page text is
/// not reliable (a script the PDF font cannot print, say) or the template
/// leaves out too much for the copy to stand in for the resume.
const _minPrintedShare = 0.9;

/// Letters and digits only, lower case, so comparing text is not thrown by line
/// wraps, spacing or upper-case headings.
String _squash(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

/// FNV-1a. Only has to notice edits; nothing here is a security boundary.
String _fingerprint(String printedText) {
  var hash = 0x811c9dc5;
  for (final unit in _squash(printedText).codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16);
}

/// What [resume] prints, or null when too little of it could be found on the
/// page to trust the copy.
Map<String, dynamic>? _printedCopy(ResumeData resume, String printedText) {
  final printed = _squash(printedText);
  var totalLength = 0;
  var keptLength = 0;
  String kept(String value) {
    final squashed = _squash(value);
    totalLength += squashed.length;
    if (squashed.isEmpty || !printed.contains(squashed)) {
      return '';
    }
    keptLength += squashed.length;
    return value;
  }

  // Both ends of a range have to print together: "2017" alone says nothing when
  // another job also started in 2017.
  (String, String) keptDates(String start, String end) {
    if (start.trim().isEmpty || end.trim().isEmpty) {
      return (kept(start), kept(end));
    }
    final range = _squash('$start$end');
    totalLength += range.length;
    if (!printed.contains(range)) {
      return ('', '');
    }
    keptLength += range.length;
    return (start, end);
  }

  Map<String, String> datesOf(String start, String end) {
    final (keptStart, keptEnd) = keptDates(start, end);
    return {'startDate': keptStart, 'endDate': keptEnd};
  }

  List<String> keptAll(Iterable<String> values) =>
      values.map(kept).where((value) => value.isNotEmpty).toList();
  // A section that printed none of its text stays out altogether.
  bool hasText(Map<String, dynamic> item) => item.values.any(
    (value) =>
        (value is String &&
            value.isNotEmpty &&
            value != 'bullets' &&
            value != 'summary') ||
        (value is List && value.isNotEmpty),
  );

  final customIndexes = <int, int>{};
  final customSections = <Map<String, dynamic>>[];
  for (var i = 0; i < resume.customSections.length; i++) {
    final item = resume.customSections[i];
    if (item.isBlank) continue;
    customIndexes[i] = customSections.length;
    customSections.add({
      'title': kept(item.title),
      'content': kept(item.content),
      'subtitle': kept(item.subtitle),
      ...datesOf(item.startDate, item.endDate),
      'layoutMode': item.layoutMode.name,
      'showEntryDetails': item.showEntryDetails,
      'bullets': keptAll(item.bullets),
      'projectEntries': [
        for (final entry in item.visibleProjectEntries)
          {
            'title': kept(entry.title),
            'subtitle': kept(entry.subtitle),
            'overview': kept(entry.overview),
            'impact': kept(entry.impact),
            'bullets': keptAll(entry.bullets),
          },
      ],
      'entries': [
        for (final entry in item.visibleEntries)
          {
            'name': kept(entry.name),
            'company': kept(entry.company),
            'period': kept(entry.period),
            ...datesOf(entry.startDate, entry.endDate),
            'summary': kept(entry.summary),
          },
      ],
    });
  }
  final order = <String>[];
  for (final id in resume.effectiveBuilderSectionOrder) {
    if (!id.startsWith('custom:')) {
      order.add(id);
      continue;
    }
    final index = customIndexes[int.tryParse(id.substring(7))];
    if (index != null) {
      order.add(ResumeBuilderSectionIds.custom(index));
    }
  }

  final fullName = kept(resume.fullName);
  final copy = {
    'fullName': fullName,
    'jobTitle': kept(resume.jobTitle),
    'email': kept(resume.email),
    'phone': kept(resume.phone),
    'location': kept(resume.location),
    'website': kept(resume.website),
    'githubLink': kept(resume.githubLink),
    'linkedinLink': kept(resume.linkedinLink),
    'summary': kept(resume.summary),
    'workExperiences': [
      for (final item in resume.visibleWorkExperiences)
        {
          'role': kept(item.role),
          'company': kept(item.company),
          ...datesOf(item.startDate, item.endDate),
          'description': kept(item.description),
          'bullets': keptAll(item.bullets),
          'layoutMode': item.layoutMode.name,
        },
    ].where(hasText).toList(),
    'education': [
      for (final item in resume.visibleEducation)
        {
          'institution': kept(item.institution),
          'degree': kept(item.degree),
          ...datesOf(item.startDate, item.endDate),
          'description': kept(item.description),
          'score': kept(item.score),
          'showScoreAsPercent': item.showScoreAsPercent,
        },
    ].where(hasText).toList(),
    'skills': keptAll(resume.skillsForResume),
    'useSkillSubheadings': resume.useSkillSubheadings,
    'skillGroups': [
      for (final group in resume.skillGroupsForResume)
        {'heading': kept(group.heading), 'skills': keptAll(group.skills)},
    ],
    'projects': [
      for (final item in resume.visibleProjects)
        {
          'title': kept(item.title),
          'subtitle': kept(item.subtitle),
          'overview': kept(item.overview),
          'impact': kept(item.impact),
          'bullets': keptAll(item.bullets),
        },
    ].where(hasText).toList(),
    'customSections': customSections,
    'sectionTitles': {
      for (final entry in resume.sectionTitles.entries)
        if (kept(entry.value).isNotEmpty) entry.key: entry.value,
    },
    'builderSectionOrder': order,
  };
  if (fullName.isEmpty ||
      (totalLength > 0 && keptLength / totalLength < _minPrintedShare)) {
    return null;
  }
  return copy;
}

/// The XMP block to store in the PDF of [resume], given the text its pages
/// print. Null when nothing could be read from the pages to compare against.
XmlDocument? resumePdfDataBlock(ResumeData resume, String printedText) {
  if (_squash(printedText).isEmpty) {
    return null;
  }
  final copy = _printedCopy(resume, printedText);
  if (copy == null) {
    return null;
  }
  final encoded = base64.encode(
    utf8.encode(
      jsonEncode({
        'version': 1,
        'printed': _fingerprint(printedText),
        'resume': copy,
      }),
    ),
  );
  if (encoded.length > _maxEncodedLength) {
    return null;
  }
  return XmlDocument.parse(
    '<x:xmpmeta xmlns:x="adobe:ns:meta/">'
    '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
    '<rdf:Description rdf:about="" xmlns:resumeai="urn:resumeai:export:1">'
    '$_openTag$encoded$_closeTag'
    '</rdf:Description></rdf:RDF></x:xmpmeta>',
  );
}

/// Whether [pdfBytes] carries a data block at all, without reading the pages.
bool hasResumePdfData(Uint8List pdfBytes) =>
    latin1.decode(pdfBytes, allowInvalid: true).contains(_openTag);

/// The resume stored in [pdfBytes] as a JSON string, or null when there is none
/// or the PDF's [printedText] has changed since it was exported. Uploaded files
/// can hold anything, so anything unexpected just means "read the page".
String? readResumePdfData(Uint8List pdfBytes, String printedText) {
  try {
    final file = latin1.decode(pdfBytes, allowInvalid: true);
    final start = file.indexOf(_openTag);
    if (start < 0) {
      return null;
    }
    final end = file.indexOf(_closeTag, start);
    final encodedStart = start + _openTag.length;
    if (end < 0 || end - encodedStart > _maxEncodedLength) {
      return null;
    }
    final data = jsonDecode(
      utf8.decode(base64.decode(file.substring(encodedStart, end))),
    );
    if (data is! Map ||
        data['version'] != 1 ||
        data['printed'] != _fingerprint(printedText) ||
        data['resume'] is! Map) {
      return null;
    }
    return jsonEncode(data['resume']);
  } catch (_) {
    return null;
  }
}
