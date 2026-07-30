import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/resume_builder_section_order.dart';
import '../models/resume_models.dart';

/// Builds a plain, ATS-friendly DOCX (single column, headings, bullets).
class ResumeDocxExporter {
  const ResumeDocxExporter();

  Future<File> saveToDevice(ResumeData resume) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${directory.path}/exports');
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final safeName = _sanitizeFileName(
      resume.fullName.trim().isEmpty ? resume.title : resume.fullName,
    );
    final file = File(
      '${exportDirectory.path}/$safeName-${DateTime.now().millisecondsSinceEpoch}.docx',
    );
    await file.writeAsBytes(buildBytes(resume), flush: true);
    return file;
  }

  Uint8List buildBytes(ResumeData resume) {
    final documentXml = _buildDocumentXml(resume);
    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypesXml))
      ..addFile(ArchiveFile.string('_rels/.rels', _relsXml))
      ..addFile(ArchiveFile.string('word/document.xml', documentXml))
      ..addFile(
        ArchiveFile.string('word/_rels/document.xml.rels', _documentRelsXml),
      );

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  String _buildDocumentXml(ResumeData resume) {
    final buffer = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">',
      )
      ..write('<w:body>');

    final name = resume.fullName.trim().isEmpty
        ? (resume.title.trim().isEmpty ? 'Resume' : resume.title.trim())
        : resume.fullName.trim();
    buffer.write(_paragraph(name, bold: true, sizeHalfPoints: 32, center: true));

    final jobTitle = resume.jobTitle.trim();
    if (jobTitle.isNotEmpty) {
      buffer.write(
        _paragraph(jobTitle, bold: true, sizeHalfPoints: 22, center: true),
      );
    }

    final contact = _contactLine(resume);
    if (contact.isNotEmpty) {
      buffer.write(_paragraph(contact, sizeHalfPoints: 18, center: true));
    }
    buffer.write(_emptyParagraph());

    final summary = resume.summary.trim();
    if (summary.isNotEmpty) {
      buffer.write(_sectionHeading('Professional Summary'));
      buffer.write(_paragraph(summary, sizeHalfPoints: 20));
      buffer.write(_emptyParagraph());
    }

    for (final id in previewBodySectionOrder(resume, followOrder: true)) {
      final customIndex = ResumeBuilderSectionIds.customIndex(id);
      if (customIndex != null) {
        if (customIndex < 0 || customIndex >= resume.customSections.length) {
          continue;
        }
        final section = resume.customSections[customIndex];
        if (section.isBlank) {
          continue;
        }
        final title = section.title.trim().isEmpty
            ? 'Additional'
            : section.title.trim();
        buffer.write(_sectionHeading(title));
        switch (section.layoutMode) {
          case CustomSectionLayoutMode.summary:
            final content = section.content.trim();
            if (content.isNotEmpty) {
              buffer.write(_paragraph(content, sizeHalfPoints: 20));
            }
          case CustomSectionLayoutMode.bullets:
            for (final bullet in section.bullets) {
              final text = bullet.trim();
              if (text.isEmpty) {
                continue;
              }
              buffer.write(_bullet(text));
            }
          case CustomSectionLayoutMode.projects:
            for (final entry in section.visibleProjectEntries) {
              final entryTitle = entry.title.trim();
              if (entryTitle.isNotEmpty) {
                buffer.write(
                  _paragraph(entryTitle, bold: true, sizeHalfPoints: 20),
                );
              }
              for (final bullet in entry.bullets) {
                final text = bullet.trim();
                if (text.isEmpty) {
                  continue;
                }
                buffer.write(_bullet(text));
              }
            }
        }
        buffer.write(_emptyParagraph());
        continue;
      }

      switch (id) {
        case ResumeBuilderSectionIds.work:
          if (!resume.includeWorkInResume) {
            break;
          }
          final work = resume.visibleWorkExperiences;
          if (work.isEmpty) {
            break;
          }
          buffer.write(_sectionHeading('Work Experience'));
          for (final item in work) {
            final roleCompany = [
              if (item.role.trim().isNotEmpty) item.role.trim(),
              if (item.company.trim().isNotEmpty) item.company.trim(),
            ].join(' — ');
            if (roleCompany.isNotEmpty) {
              buffer.write(
                _paragraph(roleCompany, bold: true, sizeHalfPoints: 20),
              );
            }
            final dates = _dateRange(item.startDate, item.endDate);
            if (dates.isNotEmpty) {
              buffer.write(
                _paragraph(dates, italics: true, sizeHalfPoints: 18),
              );
            }
            final description = item.description.trim();
            if (description.isNotEmpty) {
              buffer.write(_paragraph(description, sizeHalfPoints: 20));
            }
            for (final bullet in item.bullets) {
              final text = bullet.trim();
              if (text.isEmpty) {
                continue;
              }
              buffer.write(_bullet(text));
            }
            buffer.write(_emptyParagraph());
          }
        case ResumeBuilderSectionIds.education:
          if (!resume.includeEducationInResume) {
            break;
          }
          final education = resume.education
              .where((item) => !item.isBlank)
              .toList();
          if (education.isEmpty) {
            break;
          }
          buffer.write(_sectionHeading('Education'));
          for (final item in education) {
            final heading = [
              if (item.degree.trim().isNotEmpty) item.degree.trim(),
              if (item.institution.trim().isNotEmpty) item.institution.trim(),
            ].join(' — ');
            if (heading.isNotEmpty) {
              buffer.write(
                _paragraph(heading, bold: true, sizeHalfPoints: 20),
              );
            }
            final meta = [
              if (_dateRange(item.startDate, item.endDate).isNotEmpty)
                _dateRange(item.startDate, item.endDate),
              if (item.score.trim().isNotEmpty)
                item.showScoreAsPercent
                    ? 'Score: ${item.score.trim()}%'
                    : 'Score: ${item.score.trim()}',
            ].where((part) => part.isNotEmpty).join(' · ');
            if (meta.isNotEmpty) {
              buffer.write(
                _paragraph(meta, italics: true, sizeHalfPoints: 18),
              );
            }
            buffer.write(_emptyParagraph());
          }
        case ResumeBuilderSectionIds.skills:
          if (!resume.includeSkillsInResume) {
            break;
          }
          if (resume.showCategorisedSkills) {
            final groups = resume.skillGroupsForResume;
            if (groups.isEmpty) {
              break;
            }
            buffer.write(_sectionHeading('Skills'));
            for (final group in groups) {
              final heading = group.heading.trim();
              final skills = group.skillsCommaSeparated.trim();
              if (heading.isNotEmpty && skills.isNotEmpty) {
                buffer.write(
                  _paragraph('$heading: $skills', sizeHalfPoints: 20),
                );
              } else if (skills.isNotEmpty) {
                buffer.write(_paragraph(skills, sizeHalfPoints: 20));
              }
            }
            buffer.write(_emptyParagraph());
          } else {
            final skills = resume.skillsLinesForDisplay
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .join(', ');
            if (skills.isEmpty) {
              break;
            }
            buffer.write(_sectionHeading('Skills'));
            buffer.write(_paragraph(skills, sizeHalfPoints: 20));
            buffer.write(_emptyParagraph());
          }
        case ResumeBuilderSectionIds.projects:
          if (!resume.includeProjectsInResume) {
            break;
          }
          final projects =
              resume.projects.where((item) => !item.isBlank).toList();
          if (projects.isEmpty) {
            break;
          }
          buffer.write(_sectionHeading('Projects'));
          for (final item in projects) {
            final title = item.title.trim();
            if (title.isNotEmpty) {
              buffer.write(_paragraph(title, bold: true, sizeHalfPoints: 20));
            }
            final subtitle = item.subtitle.trim();
            if (subtitle.isNotEmpty) {
              buffer.write(
                _paragraph(subtitle, italics: true, sizeHalfPoints: 18),
              );
            }
            for (final part in [item.overview, item.impact]) {
              final text = part.trim();
              if (text.isNotEmpty) {
                buffer.write(_paragraph(text, sizeHalfPoints: 20));
              }
            }
            for (final bullet in item.bullets) {
              final text = bullet.trim();
              if (text.isEmpty) {
                continue;
              }
              buffer.write(_bullet(text));
            }
            buffer.write(_emptyParagraph());
          }
      }
    }

    buffer
      ..write(
        '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/>'
        '<w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/>'
        '</w:sectPr>',
      )
      ..write('</w:body></w:document>');
    return buffer.toString();
  }

  String _contactLine(ResumeData resume) {
    return [
      if (resume.email.trim().isNotEmpty) resume.email.trim(),
      if (resume.phone.trim().isNotEmpty) resume.phone.trim(),
      if (resume.location.trim().isNotEmpty) resume.location.trim(),
      if (resume.website.trim().isNotEmpty) resume.website.trim(),
      if (resume.linkedinLink.trim().isNotEmpty) resume.linkedinLink.trim(),
      if (resume.githubLink.trim().isNotEmpty) resume.githubLink.trim(),
    ].join(' | ');
  }

  String _dateRange(String start, String end) {
    final startText = start.trim();
    final endText = end.trim();
    if (startText.isEmpty && endText.isEmpty) {
      return '';
    }
    if (startText.isEmpty) {
      return endText;
    }
    if (endText.isEmpty) {
      return startText;
    }
    return '$startText – $endText';
  }

  String _sectionHeading(String title) {
    return _paragraph(
      title.toUpperCase(),
      bold: true,
      sizeHalfPoints: 22,
      after: 60,
    );
  }

  String _bullet(String text) => _paragraph('• $text', sizeHalfPoints: 20);

  String _emptyParagraph() => _paragraph('', sizeHalfPoints: 18, after: 40);

  String _paragraph(
    String text, {
    bool bold = false,
    bool italics = false,
    bool center = false,
    int sizeHalfPoints = 20,
    int after = 80,
  }) {
    final runProps = StringBuffer('<w:rPr><w:sz w:val="$sizeHalfPoints"/>');
    if (bold) {
      runProps.write('<w:b/>');
    }
    if (italics) {
      runProps.write('<w:i/>');
    }
    runProps.write('</w:rPr>');

    final paragraphProps = StringBuffer('<w:pPr><w:spacing w:after="$after"/>');
    if (center) {
      paragraphProps.write('<w:jc w:val="center"/>');
    }
    paragraphProps.write('</w:pPr>');

    if (text.isEmpty) {
      return '<w:p>$paragraphProps</w:p>';
    }

    return '<w:p>$paragraphProps'
        '<w:r>$runProps<w:t xml:space="preserve">${_escapeXml(text)}</w:t></w:r>'
        '</w:p>';
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static const String _contentTypesXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

  static const String _relsXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const String _documentRelsXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';
}
