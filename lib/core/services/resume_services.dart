import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../corporate_resume_style.dart';
import '../models/resume_models.dart';
import '../resume_text_font.dart';
import 'resume_pdf/resume_pdf_theme.dart';

part 'resume_pdf/resume_pdf_template_pages.dart';
part 'resume_pdf/resume_pdf_highlighted_pages.dart';

PdfColor _pdfRgb(Color c) => PdfColor(c.r, c.g, c.b);

PdfColor _corporateTitlePdf(ResumeData resume) =>
    _pdfRgb(resume.corporateColorPreset.titleColor);

PdfColor _corporateHeaderPdf(ResumeData resume) =>
    _pdfRgb(resume.corporateColorPreset.headerColor);

pw.Widget _pwCustomSectionBody(CustomSectionItem item) {
  switch (item.layoutMode) {
    case CustomSectionLayoutMode.summary:
      return pw.Text(item.content.trim());
    case CustomSectionLayoutMode.bullets:
      final lines = item.bullets.where((b) => b.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        return pw.SizedBox();
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: i == 0 ? 2 : 3),
              child: pw.Bullet(
                text: lines[i].trim(),
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: ResumeTypography.bodyPt,
                ),
              ),
            ),
        ],
      );
  }
}

pw.Widget _creativeAvatarIconPlaceholder({
  double width = 96,
  double height = 112,
  String initials = 'DA',
  required PdfColor backgroundColor,
  PdfColor textColor = const PdfColor(0.9098, 0.3647, 0.0157),
}) {
  final bgColor = PdfColor(
    backgroundColor.red,
    backgroundColor.green,
    backgroundColor.blue,
    _creativeAvatarBackgroundOpacity,
  );

  return pw.Container(
    width: width,
    height: height,
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(2),
      color: bgColor,
    ),
    alignment: pw.Alignment.center,
    child: pw.Text(
      initials,
      style: pw.TextStyle(
        color: textColor,
        fontSize: width * 0.28,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

const double _creativeSidebarRailWidthPt = 161.0;
const double _creativeSidebarContentWidthPt = 123.0;
const double _creativeSidebarGapPt = 28.0;
const double _creativeAvatarWidthPt = 105.6;
const double _creativeAvatarHeightPt = 123.2;
const double _creativeMainColumnInsetPt =
    _creativeSidebarContentWidthPt + _creativeSidebarGapPt;
const double _creativeSectionGapPt = 20.0;
const double _creativeHeadingBodyGapPt = 8.0;
const double _creativeSidebarDividerGapPt = 20.0;
const double _creativeNameFontPt = 30.0;
const double _creativeAvatarBackgroundOpacity = 0.4;

const double _classicSidebarRailWidthPt = 145.0;
const double _classicSidebarContentWidthPt = 112.0;
const double _classicSidebarMainInsetPt = 159.0;
const double _classicSidebarAvatarSizePt = 88.0;
const double _classicSidebarSectionGapPt = 18.0;
const double _classicSidebarHeadingGapPt = 6.0;
const double _classicSidebarSectionBottomPt = 14.0;

PdfColor _creativeSidebarRailColorPdf(ResumeData resume) =>
    _pdfRgb(resume.creativeRailColor);

PdfColor _creativeSidebarAccentColorPdf(ResumeData resume) =>
    _pdfRgb(resume.creativeAccentColor);

PdfColor _creativeTitleColorPdf(ResumeData resume) =>
    _pdfRgb(resume.creativeTitleColor);

PdfColor _creativeSidebarLineColorPdf() => PdfColor.fromHex('#CDBAAC');

PdfColor _creativeSidebarMutedColorPdf() => PdfColor.fromHex('#5F656C');

PdfColor _classicSidebarRailColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarRailColor);

PdfColor _classicSidebarAccentColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarAccentColor);

PdfColor _classicSidebarTitleColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarTitleColor);

PdfColor _classicSidebarMutedColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarMutedColor);

PdfColor _classicSidebarDividerColorPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarDividerColor);

PdfColor _classicSidebarSectionBorderPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarSectionBorderColor);

PdfColor _classicSidebarAvatarFillPdf(ResumeData resume) =>
    _pdfRgb(resume.classicSidebarAvatarFillColor);

pw.PageTheme _creativeSidebarPageTheme({
  required PdfColor railColor,
  pw.Widget? firstPageSidebar,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) {
  return pw.PageTheme(
    pageFormat: pageFormat,
    margin: const pw.EdgeInsets.fromLTRB(24, 18, 24, 30),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: context.pageNumber == 1
          ? pw.Stack(
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      width: _creativeSidebarRailWidthPt,
                      color: railColor,
                    ),
                    pw.Expanded(child: pw.Container(color: PdfColors.white)),
                  ],
                ),
                if (firstPageSidebar != null)
                  pw.Positioned(left: 24, top: 18, child: firstPageSidebar),
              ],
            )
          : pw.Container(color: PdfColors.white),
    ),
  );
}

pw.Widget _creativeSectionHeadingRow({
  required String title,
  required PdfColor titleColor,
  required PdfColor lineColor,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: ResumeTypography.darkHeaderSectionTitlePt,
          fontWeight: pw.FontWeight.bold,
          color: titleColor,
          letterSpacing: 0.15,
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Expanded(child: pw.Container(height: 1.2, color: lineColor)),
    ],
  );
}

pw.Widget _creativeMainColumnChild(pw.Widget child) {
  return _CreativePageAwareInset(child: child);
}

pw.Widget _classicSidebarMainColumnChild(pw.Widget child) {
  return _ClassicSidebarPageAwareInset(child: child);
}

class _CreativePageAwareInset extends pw.SingleChildWidget {
  _CreativePageAwareInset({required pw.Widget child}) : super(child: child);

  double _leftInsetFor(pw.Context context) =>
      context.pageNumber == 1 ? _creativeMainColumnInsetPt : 0;

  // ignore: must_call_super
  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final leftInset = _leftInsetFor(context);

    if (child != null) {
      final childConstraints = constraints.deflate(
        pw.EdgeInsets.only(left: leftInset),
      );
      child!.layout(context, childConstraints, parentUsesSize: parentUsesSize);
      assert(child!.box != null);
      box = constraints.constrainRect(
        width: child!.box!.width + leftInset,
        height: child!.box!.height,
      );
      return;
    }

    box = constraints.constrainRect(width: leftInset, height: 0);
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);

    final leftInset = _leftInsetFor(context);
    if (child == null) {
      return;
    }

    final mat = context.canvas.getTransform();
    mat.translateByDouble(box!.x + leftInset, box!.y, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(mat);
    child!.paint(context);
    context.canvas.restoreContext();
  }
}

class _ClassicSidebarPageAwareInset extends pw.SingleChildWidget {
  _ClassicSidebarPageAwareInset({required pw.Widget child}) : super(child: child);

  double _leftInsetFor(pw.Context context) =>
      context.pageNumber == 1 ? _classicSidebarMainInsetPt : 0;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final leftInset = _leftInsetFor(context);

    if (child != null) {
      final childConstraints = constraints.deflate(
        pw.EdgeInsets.only(left: leftInset),
      );
      child!.layout(context, childConstraints, parentUsesSize: parentUsesSize);
      assert(child!.box != null);
      box = constraints.constrainRect(
        width: child!.box!.width + leftInset,
        height: child!.box!.height,
      );
      return;
    }

    box = constraints.constrainRect(width: leftInset, height: 0);
  }

  // ignore: must_call_super
  @override
  void paint(pw.Context context) {
    final leftInset = _leftInsetFor(context);

    if (child == null) {
      return;
    }

    if (leftInset == 0) {
      super.paint(context);
      return;
    }

    final mat = context.canvas.getTransform();
    mat.translateByDouble(box!.x + leftInset, box!.y, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(mat);
    child!.paint(context);
    context.canvas.restoreContext();
  }
}

pw.Widget _creativeSidebarContactRow(
  String value, {
  required PdfColor iconColor,
  required PdfColor textColor,
  double fontSize = 10.5,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 7,
          height: 7,
          margin: const pw.EdgeInsets.only(top: 3, right: 6),
          decoration: pw.BoxDecoration(
            color: iconColor,
            borderRadius: pw.BorderRadius.circular(1.5),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(color: textColor, fontSize: fontSize),
          ),
        ),
      ],
    ),
  );
}

pw.PageTheme _classicSidebarPageTheme({
  required ResumeData resume,
  required PdfColor railColor,
  required PdfColor dividerColor,
  required PdfColor accentColor,
  required PdfColor titleColor,
  required PdfColor mutedColor,
  required double bodyPt,
  pw.MemoryImage? profileImage,
  Set<String> highlightedSkills = const <String>{},
  PdfColor? highlightColor,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) {
  return pw.PageTheme(
    pageFormat: pageFormat,
    margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 28),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: context.pageNumber == 1
          ? pw.Stack(
              children: [
                pw.Positioned(
                  left: 24,
                  top: 20,
                  bottom: 28,
                  child: pw.Container(
                    width: _classicSidebarRailWidthPt,
                    color: railColor,
                  ),
                ),
                pw.Positioned(
                  left: 40,
                  top: 32,
                  child: _classicSidebarPanel(
                    resume: resume,
                    accentColor: accentColor,
                    dividerColor: dividerColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    bodyPt: bodyPt,
                    profileImage: profileImage,
                    highlightedSkills: highlightedSkills,
                    highlightColor: highlightColor,
                    pageNumber: context.pageNumber,
                  ),
                ),
              ],
            )
          : pw.SizedBox(),
    ),
  );
}

pw.Widget _classicSidebarPanel({
  required ResumeData resume,
  required PdfColor accentColor,
  required PdfColor dividerColor,
  required PdfColor titleColor,
  required PdfColor mutedColor,
  required double bodyPt,
  pw.MemoryImage? profileImage,
  Set<String> highlightedSkills = const <String>{},
  PdfColor? highlightColor,
  int pageNumber = 1,
}) {
  const skillsPerPage = 6;
  final allSkills = resume.skillsForResume
      .where((item) => item.trim().isNotEmpty)
      .toList();
  final start = ((pageNumber - 1).clamp(0, 1000000)) * skillsPerPage;
  final skills = start < allSkills.length
      ? allSkills.skip(start).take(skillsPerPage).toList()
      : const <String>[];
  final isFirstPage = pageNumber <= 1;
  final languages = _classicSidebarLanguageLines(resume).take(4).toList();

  return pw.SizedBox(
    width: _classicSidebarContentWidthPt,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (isFirstPage && profileImage != null)
          pw.ClipOval(
            child: pw.SizedBox(
              width: _classicSidebarAvatarSizePt,
              height: _classicSidebarAvatarSizePt,
              child: pw.Image(profileImage, fit: pw.BoxFit.cover),
            ),
          )
        else if (isFirstPage)
          pw.Container(
            width: _classicSidebarAvatarSizePt,
            height: _classicSidebarAvatarSizePt,
            decoration: pw.BoxDecoration(
              color: _classicSidebarAvatarFillPdf(resume),
              shape: pw.BoxShape.circle,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              _classicSidebarInitials(resume),
              style: pw.TextStyle(
                color: titleColor,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        if (isFirstPage) pw.SizedBox(height: _classicSidebarSectionGapPt),
        if (isFirstPage)
          pw.Container(height: 1.2, color: dividerColor),
        if (isFirstPage) pw.SizedBox(height: 10),
        if (skills.isNotEmpty)
          _classicSidebarListSection(
            title: 'Skills',
            items: skills,
            titleColor: titleColor,
            bulletColor: accentColor,
            textColor: titleColor,
            fontSize: bodyPt,
            highlightedItems: highlightedSkills,
            highlightColor: highlightColor,
            showTitle: isFirstPage,
            itemBottom: 0,
          ),
        if (isFirstPage && languages.isNotEmpty) ...[
          pw.SizedBox(height: _classicSidebarSectionGapPt),
          pw.Container(height: 1.2, color: dividerColor),
          pw.SizedBox(height: 10),
          _classicSidebarListSection(
            title: 'Languages',
            items: languages,
            titleColor: titleColor,
            bulletColor: accentColor,
            textColor: mutedColor,
            fontSize: bodyPt,
          ),
        ],
      ],
    ),
  );
}

pw.Widget _classicSidebarListSection({
  required String title,
  required List<String> items,
  required PdfColor titleColor,
  required PdfColor bulletColor,
  required PdfColor textColor,
  required double fontSize,
  Set<String> highlightedItems = const <String>{},
  PdfColor? highlightColor,
  bool showTitle = true,
  double itemBottom = 8,
}) {
  final visibleItems = items.where((item) => item.trim().isNotEmpty).toList();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (showTitle)
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: titleColor,
            fontSize: ResumeTypography.darkHeaderSectionTitlePt,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      if (showTitle) pw.SizedBox(height: 8),
      if (visibleItems.isEmpty)
        pw.Text(
          'Add items',
          style: pw.TextStyle(color: textColor, fontSize: fontSize),
        )
      else
        for (final item in visibleItems)
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: itemBottom),
            child: _classicBulletRow(
              text: item,
              bulletColor: bulletColor,
              textColor: textColor,
              fontSize: fontSize,
              backgroundColor: highlightedItems.contains(item)
                  ? highlightColor
                  : null,
            ),
          ),
    ],
  );
}

pw.Widget _classicBulletRow({
  required String text,
  required PdfColor bulletColor,
  required PdfColor textColor,
  required double fontSize,
  PdfColor? backgroundColor,
}) {
  final row = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '•',
        style: pw.TextStyle(
          color: bulletColor,
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Expanded(
        child: pw.Text(
          text,
          style: pw.TextStyle(color: textColor, fontSize: fontSize),
        ),
      ),
    ],
  );

  if (backgroundColor == null) {
    return row;
  }
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    color: backgroundColor,
    child: row,
  );
}

List<String> _classicSidebarLanguageLines(ResumeData resume) {
  final section = _classicSidebarLanguagesSection(resume);
  if (section == null) {
    return const <String>[];
  }
  if (section.layoutMode == CustomSectionLayoutMode.bullets) {
    return section.bullets.where((item) => item.trim().isNotEmpty).toList();
  }
  return section.content
      .split(RegExp(r'[\n,]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _classicSidebarInitials(ResumeData resume) {
  final name = resume.fullName.trim().isEmpty
      ? 'Your Name'
      : resume.fullName.trim();
  final words = name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (words.isEmpty) {
    return 'DA';
  }
  return words.map((part) => part[0].toUpperCase()).join();
}

CustomSectionItem? _classicSidebarLanguagesSection(ResumeData resume) {
  for (final item in resume.visibleCustomSections) {
    if (item.title.trim().toLowerCase() == 'languages') {
      return item;
    }
  }
  return null;
}

List<CustomSectionItem> _classicSidebarMainCustomSections(ResumeData resume) {
  final languages = _classicSidebarLanguagesSection(resume);
  var skippedLanguages = false;
  return resume.visibleCustomSections.where((item) {
    if (!skippedLanguages && identical(item, languages)) {
      skippedLanguages = true;
      return false;
    }
    return true;
  }).toList();
}

pw.Widget _creativeSidebarEducationEntry(
  EducationItem item, {
  required PdfColor titleColor,
  required PdfColor mutedColor,
  double bodyFontPt = ResumeTypography.bodyPt,
}) {
  final dates = [
    item.startDate.trim(),
    item.endDate.trim(),
  ].where((value) => value.isNotEmpty).join(' - ');

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          item.degree.ifEmpty('Degree'),
          style: pw.TextStyle(
            color: titleColor,
            fontSize: bodyFontPt,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          item.institution.ifEmpty('Institution'),
          style: pw.TextStyle(color: mutedColor, fontSize: bodyFontPt - 0.3),
        ),
        if (dates.isNotEmpty) ...[
          pw.SizedBox(height: 1.5),
          pw.Text(
            dates,
            style: pw.TextStyle(color: mutedColor, fontSize: bodyFontPt - 0.8),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _creativeFirstPageSidebar({
  required ResumeData resume,
  required List<String> contactItems,
  required PdfColor accentColor,
  required PdfColor lineColor,
  required PdfColor mutedColor,
  required double bodyPt,
  pw.MemoryImage? profileImage,
}) {
  return pw.SizedBox(
    width: _creativeSidebarContentWidthPt,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        profileImage != null
            ? pw.Container(
                width: _creativeAvatarWidthPt,
                height: _creativeAvatarHeightPt,
                child: pw.Image(profileImage, fit: pw.BoxFit.cover),
              )
            : _creativeAvatarIconPlaceholder(
                width: _creativeAvatarWidthPt,
                height: _creativeAvatarHeightPt,
                initials: _creativeSidebarInitials(resume),
                backgroundColor: _pdfRgb(resume.creativeAvatarBackgroundColor),
                textColor: accentColor,
              ),
        if (contactItems.isNotEmpty) ...[
          pw.SizedBox(height: _creativeSectionGapPt),
          pw.Container(height: 1.2, color: lineColor),
          pw.SizedBox(height: _creativeSidebarDividerGapPt),
          for (final item in contactItems)
            _creativeSidebarContactRow(
              item,
              iconColor: accentColor,
              textColor: mutedColor,
              fontSize: bodyPt,
            ),
        ],
      ],
    ),
  );
}

String _creativeSidebarInitials(ResumeData resume) {
  final name = resume.fullName.trim().isEmpty
      ? 'Your Name'
      : resume.fullName.trim();
  final words = name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (words.isEmpty) {
    return 'DA';
  }
  return words.map((part) => part[0].toUpperCase()).join();
}

class ResumeRepository {
  ResumeRepository._(this._resumeBox, this._coverLetterBox);

  final Box<dynamic> _resumeBox;
  final Box<dynamic> _coverLetterBox;

  static Future<ResumeRepository> create() async {
    await Hive.initFlutter();
    final resumeBox = await Hive.openBox<dynamic>('resume_library');
    final coverLetterBox = await Hive.openBox<dynamic>('cover_letter_library');
    return ResumeRepository._(resumeBox, coverLetterBox);
  }

  Future<List<ResumeData>> loadResumes() async {
    final items =
        _resumeBox.values
            .whereType<Map>()
            .map((item) => ResumeData.fromJson(Map<String, dynamic>.from(item)))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> upsertResume(ResumeData resume) async {
    await _resumeBox.put(resume.id, resume.toJson());
  }

  Future<void> deleteResume(String id) async {
    await _resumeBox.delete(id);
  }

  Future<List<CoverLetterData>> loadCoverLetters() async {
    final items =
        _coverLetterBox.values
            .whereType<Map>()
            .map(
              (item) =>
                  CoverLetterData.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {
    await _coverLetterBox.put(coverLetter.id, coverLetter.toJson());
  }

  Future<void> deleteCoverLetter(String id) async {
    await _coverLetterBox.delete(id);
  }
}

class ResumeImprovementResult {
  const ResumeImprovementResult({
    required this.resume,
    required this.appliedChanges,
  });

  final ResumeData resume;
  final List<String> appliedChanges;
}

class LocalAiResumeService {
  Future<String> generateSummary(ResumeData resume) async {
    return _simulate(() => _buildSummary(resume));
  }

  Future<List<String>> generateJobBullets({
    required String role,
    required String company,
    required String targetJobTitle,
  }) async {
    return _simulate(
      () => _buildJobBullets(
        role: role,
        company: company,
        targetJobTitle: targetJobTitle,
      ),
    );
  }

  Future<List<String>> suggestSkills({
    required ResumeData resume,
    String? targetJobTitle,
  }) async {
    return _simulate(
      () => _resumeSkillSuggestions(
        resume: resume,
        targetJobTitle: targetJobTitle,
      ),
    );
  }

  Future<List<String>> improveResume(ResumeData resume) async {
    return _simulate(() {
      final analysis = _buildAnalysis(resume: resume, jobDescription: '');
      final tips = <String>[
        ...analysis.improvements,
        if (resume.summary.trim().isEmpty)
          'Add a 2-3 sentence summary so recruiters understand your value immediately.',
        if (resume.visibleProjects.isEmpty)
          'Include at least one project with a measurable outcome to increase credibility.',
      ];

      return tips.toSet().take(6).toList();
    });
  }

  Future<ResumeAnalysis> analyzeResume({
    required ResumeData resume,
    String jobDescription = '',
  }) async {
    return _simulate(
      () => _buildAnalysis(resume: resume, jobDescription: jobDescription),
    );
  }

  Future<ResumeAnalysis> analyzeResumeText({
    required String resumeText,
    String jobDescription = '',
  }) async {
    return _simulate(
      () => _buildTextAnalysis(
        resumeText: resumeText,
        jobDescription: jobDescription,
      ),
    );
  }

  Future<List<String>> generateProofGapPrompts({
    required String resumeText,
    String jobDescription = '',
  }) async {
    return _simulate(
      () => _buildProofGapPrompts(
        resumeText: resumeText,
        jobDescription: jobDescription,
      ),
    );
  }

  ResumeData parseImportedResumeText({
    required String resumeText,
    required ResumeTemplate template,
    String sourceTitle = '',
    List<String> candidateResumeTexts = const [],
  }) {
    final normalizedCandidates = <String>[];
    final seen = <String>{};

    for (final candidate in [resumeText, ...candidateResumeTexts]) {
      final normalized = candidate.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final dedupeKey = normalized
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();
      if (seen.add(dedupeKey)) {
        normalizedCandidates.add(normalized);
      }
    }

    ResumeData? bestResume;
    var bestScore = -1;
    for (final candidate in normalizedCandidates) {
      final parsed = _buildResumeFromImportedText(
        resumeText: candidate,
        template: template,
        sourceTitle: sourceTitle,
      );
      final score = _scoreImportedResumeParse(parsed, candidate);
      if (score > bestScore) {
        bestScore = score;
        bestResume = parsed;
      }
    }

    return bestResume ??
        _buildResumeFromImportedText(
          resumeText: resumeText,
          template: template,
          sourceTitle: sourceTitle,
        );
  }

  Future<ResumeImprovementResult> improveResumeForAts({
    required ResumeData resume,
    String jobDescription = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final normalizedSummary = resume.summary.trim();
    final normalizedJobDescription = jobDescription.trim();
    final currentSkills = resume.skills.toSet();
    final targetJobTitle = resume.jobTitle.trim().isEmpty
        ? resume.title
        : resume.jobTitle;
    final analysis = _buildAnalysis(
      resume: resume,
      jobDescription: normalizedJobDescription,
    );
    final missingKeywords = analysis.missingSkills;
    final appliedChanges = <String>[];

    var updatedSummary = normalizedSummary;
    if (updatedSummary.length < 90) {
      updatedSummary = _buildSummary(resume);
      if (missingKeywords.isNotEmpty) {
        updatedSummary =
            '$updatedSummary Focused on ${missingKeywords.take(2).join(' and ')}.';
      }
      appliedChanges.add(
        'Refreshed the summary to be stronger and more ATS-friendly.',
      );
    }

    final suggestedSkills = {
      ..._resumeSkillSuggestions(
        resume: resume,
        targetJobTitle: targetJobTitle,
      ),
      ...missingKeywords.take(4),
    };
    final mergedSkills = [...currentSkills, ...suggestedSkills]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final cappedSkills = mergedSkills.take(50).toList();
    if (cappedSkills.length > resume.skills.length) {
      appliedChanges.add(
        'Added relevant skills and missing keywords from the target role.',
      );
    }

    var workChanged = false;
    final updatedWork = resume.workExperiences.map((item) {
      final hasWeakBullets =
          item.bullets.where((bullet) => bullet.trim().length > 45).length < 2;
      final needsBulletSupport =
          !item.isBlank && (item.bullets.isEmpty || hasWeakBullets);
      if (!needsBulletSupport) {
        return item;
      }

      workChanged = true;
      final improvedBullets = {
        ...item.bullets.where((bullet) => bullet.trim().isNotEmpty),
        ..._buildJobBullets(
          role: item.role,
          company: item.company,
          targetJobTitle: targetJobTitle,
        ),
      }.toList();

      return item.copyWith(bullets: improvedBullets);
    }).toList();
    if (workChanged) {
      appliedChanges.add(
        'Strengthened work experience bullets with clearer action language.',
      );
    }

    if (appliedChanges.isEmpty) {
      appliedChanges.add(
        'Your selected resume was already strong, so no direct ATS fixes were needed.',
      );
    }

    return ResumeImprovementResult(
      resume: resume.copyWith(
        summary: updatedSummary,
        skills: cappedSkills,
        workExperiences: updatedWork,
        updatedAt: DateTime.now(),
      ),
      appliedChanges: appliedChanges,
    );
  }

  Future<String> generateCoverLetter({
    required ResumeData resume,
    required String company,
    required String role,
    String skillToHighlight = '',
    String language = '',
  }) async {
    return _simulate(() {
      final fullName = resume.fullName.trim().isEmpty
          ? '[Your Name]'
          : resume.fullName.trim();
      final addressLine = '[Your Address]';
      final cityLine = resume.location.trim().isEmpty
          ? '[City, State, Zip Code]'
          : resume.location.trim();
      final emailLine = resume.email.trim().isEmpty
          ? '[Email Address]'
          : resume.email.trim();
      final phoneLine = resume.phone.trim().isEmpty
          ? '[Phone Number]'
          : resume.phone.trim();
      final currentDate = _formatCoverLetterDate(DateTime.now());
      final companyName = company.trim().isEmpty ? 'Dekh Company' : company;
      final roleName = role.trim().isEmpty ? 'Heheh' : role;
      final highlightedSkill = skillToHighlight.trim().isNotEmpty
          ? skillToHighlight.trim()
          : resume.skills.take(1).join();
      final primarySkill = highlightedSkill.isEmpty
          ? roleName
          : highlightedSkill;
      final resumeStrength = resume.summary.trim().isNotEmpty
          ? resume.summary.trim()
          : 'I bring a thoughtful, reliable approach to planning, communication, and execution.';
      final firstExperience = resume.visibleWorkExperiences.isNotEmpty
          ? resume.visibleWorkExperiences.first
          : null;
      final experienceLabel = [
        firstExperience?.role.trim() ?? '',
        firstExperience?.company.trim() ?? '',
      ].where((item) => item.isNotEmpty).join(' at ');
      final experienceSource = experienceLabel.isEmpty
          ? 'my previous work experience'
          : 'my work as $experienceLabel';
      var experienceBullet = '';
      if (firstExperience != null) {
        for (final bullet in firstExperience.bullets) {
          if (bullet.trim().isNotEmpty) {
            experienceBullet = bullet.trim();
            break;
          }
        }
      }
      final experienceSentence = experienceBullet.isEmpty
          ? 'I have a proven track record of delivering thoughtful work, adapting quickly, and contributing positively to team goals.'
          : 'For example, $experienceBullet';
      final languageParagraph = language.trim().isEmpty
          ? ''
          : '\n\nI can also collaborate confidently in ${language.trim()}, which helps me communicate clearly across teams and deliver a strong candidate experience.';

      return '$fullName\n'
          '$addressLine\n'
          '$cityLine\n'
          '$emailLine\n'
          '$phoneLine\n'
          '$currentDate\n\n'
          'Hiring Manager\n'
          '$companyName\n'
          '[Company Address]\n'
          '[City, State, Zip Code]\n\n'
          'Dear Hiring Manager,\n\n'
          'I am writing to express my interest in the $roleName position at $companyName. I believe that my skills and experience make me a strong fit for this role.\n\n'
          'With a strong background in $primarySkill, I am confident in my ability to contribute positively to the team at $companyName. Through $experienceSource, I have developed practical experience, sound judgment, and a clear understanding of how to deliver results. $experienceSentence\n\n'
          '$resumeStrength\n\n'
          'I possess strong communication, problem-solving, and analytical skills, and I enjoy working in collaborative environments where I can learn quickly and add value from day one.$languageParagraph\n\n'
          'I am excited about the opportunity to bring my experience in $primarySkill to $companyName and contribute to the continued success of the team. Thank you for considering my application. I look forward to the possibility of discussing my application further.\n\n'
          'Sincerely,\n\n'
          '$fullName';
    });
  }

  String _formatCoverLetterDate(DateTime date) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<JobDescriptionInsights> analyzeJobDescription({
    required String jobDescription,
    required ResumeData resume,
  }) async {
    return _simulate(() {
      final keywords = _extractKeywords(jobDescription).take(8).toList();
      final haystack = [
        resume.jobTitle,
        resume.summary,
        ...resume.skills,
        ...resume.visibleWorkExperiences.expand((item) => item.bullets),
      ].join(' ').toLowerCase();

      final missing = keywords
          .where((keyword) => !haystack.contains(keyword.toLowerCase()))
          .take(5)
          .toList();

      final summary = keywords.isEmpty
          ? 'Add a job description to extract ATS keywords and compare them with your resume.'
          : 'The posting emphasizes ${keywords.take(3).join(', ')}. '
                '${missing.isEmpty ? 'Your resume already reflects the top terms well.' : 'Consider adding ${missing.take(2).join(' and ')} where it is truthful and relevant.'}';

      return JobDescriptionInsights(
        summary: summary,
        keywords: keywords,
        missingSkills: missing,
      );
    });
  }

  ResumeAnalysis _buildAnalysis({
    required ResumeData resume,
    required String jobDescription,
  }) {
    var score = 32;
    final improvements = <String>[];
    final strengths = <String>[];
    final weakDescriptions = <String>[];

    if (resume.fullName.trim().isNotEmpty) {
      score += 8;
    } else {
      improvements.add(
        'Add your full name to create a complete resume header.',
      );
    }

    if (resume.email.trim().isNotEmpty && resume.phone.trim().isNotEmpty) {
      score += 10;
      strengths.add('Includes reachable contact information.');
    } else {
      improvements.add(
        'Add both email and phone so recruiters can contact you quickly.',
      );
    }

    if (resume.summary.trim().length > 90) {
      score += 10;
      strengths.add('Summary introduces value clearly.');
    } else {
      improvements.add(
        'Strengthen the summary with 2-3 lines focused on outcomes and target role.',
      );
    }

    if (resume.visibleWorkExperiences.isNotEmpty) {
      score += 16;
      strengths.add('Work experience section is present.');
      for (final experience in resume.visibleWorkExperiences) {
        final bulletStrength = experience.bullets
            .where((item) => item.length > 45)
            .length;
        if (bulletStrength < 2 && experience.description.trim().length < 60) {
          weakDescriptions.add(
            '${experience.role.trim().isEmpty ? 'Experience entry' : experience.role.trim()} needs stronger, outcome-focused bullets.',
          );
        }
      }
    } else {
      improvements.add(
        'Add at least one work experience entry, internship, or freelance project.',
      );
    }

    if (resume.skills.length >= 6) {
      score += 10;
      strengths.add('Skill inventory is broad enough for ATS matching.');
    } else {
      improvements.add(
        'Expand the skills section with tools, methods, and domain keywords.',
      );
    }

    if (resume.visibleEducation.isNotEmpty) {
      score += 6;
    } else {
      improvements.add('Add education details to complete the profile.');
    }

    if (resume.visibleProjects.isNotEmpty) {
      score += 8;
      strengths.add('Projects add proof of execution.');
    } else {
      improvements.add(
        'Include 1-2 projects with impact metrics or user outcomes.',
      );
    }

    final keywords = _extractKeywords(jobDescription).take(10).toList();
    final resumeText = [
      resume.jobTitle,
      resume.summary,
      ...resume.skills,
      ...resume.visibleWorkExperiences.expand((item) => item.bullets),
    ].join(' ').toLowerCase();

    final missingSkills = keywords
        .where((keyword) => !resumeText.contains(keyword.toLowerCase()))
        .take(5)
        .toList();

    if (keywords.isNotEmpty) {
      if (missingSkills.isEmpty) {
        score += 12;
        strengths.add('Good alignment with the target job description.');
      } else {
        score += 5;
        improvements.add(
          'Mirror more relevant job-description keywords where they are truthful.',
        );
      }
    }

    score = score.clamp(0, 100);

    return ResumeAnalysis(
      score: score,
      atsCompatibility: score / 100,
      missingSkills: missingSkills,
      weakDescriptions: weakDescriptions,
      strengths: strengths,
      improvements: improvements.toSet().toList(),
    );
  }

  ResumeAnalysis _buildTextAnalysis({
    required String resumeText,
    required String jobDescription,
  }) {
    final normalized = resumeText.trim();
    if (normalized.isEmpty) {
      return const ResumeAnalysis(
        score: 0,
        atsCompatibility: 0,
        missingSkills: [],
        weakDescriptions: [],
        strengths: [],
        improvements: ['Paste your current resume text to run the analyser.'],
      );
    }

    final lower = normalized.toLowerCase();
    var score = 28;
    final improvements = <String>[];
    final strengths = <String>[];
    final weakDescriptions = <String>[];

    if (RegExp(r'[\w\.-]+@[\w\.-]+\.\w+').hasMatch(normalized)) {
      score += 8;
      strengths.add('Includes an email address.');
    } else {
      improvements.add('Add a clear email address to the resume header.');
    }

    if (RegExp(r'(\+\d{1,3}[\s-]?)?(\d[\s-]?){10,}').hasMatch(normalized)) {
      score += 8;
      strengths.add('Includes a phone number.');
    } else {
      improvements.add('Add a phone number recruiters can reach easily.');
    }

    if (_containsAny(lower, ['summary', 'profile', 'objective'])) {
      score += 10;
      strengths.add('Includes a professional summary section.');
    } else {
      improvements.add(
        'Add a short summary near the top to frame your value quickly.',
      );
    }

    if (_containsAny(lower, ['experience', 'employment', 'work history'])) {
      score += 14;
      strengths.add('Work experience is present.');
    } else {
      improvements.add(
        'Include work experience or equivalent project experience.',
      );
    }

    if (_containsAny(lower, ['education'])) {
      score += 6;
    } else {
      improvements.add('Add education details to round out the resume.');
    }

    if (_containsAny(lower, ['skills'])) {
      score += 8;
    } else {
      improvements.add('Create a dedicated skills section for ATS matching.');
    }

    final bulletCount = RegExp(
      r'^[\-\u2022\*]',
      multiLine: true,
    ).allMatches(normalized).length;
    if (bulletCount >= 3) {
      score += 10;
      strengths.add('Uses bullet points for scan-friendly reading.');
    } else {
      improvements.add(
        'Use more bullet points so achievements are easier to scan.',
      );
    }

    final metricCount = RegExp(
      r'\b\d+[%+xXkKmM]?\b',
    ).allMatches(normalized).length;
    if (metricCount >= 3) {
      score += 10;
      strengths.add('Contains measurable results or scope indicators.');
    } else {
      weakDescriptions.add(
        'Several claims still need numbers, percentages, scale, or concrete outcomes.',
      );
      improvements.add(
        'Add metrics like revenue, time saved, users, accuracy, or growth.',
      );
    }

    final keywords = _extractKeywords(jobDescription).take(10).toList();
    final missingSkills = keywords
        .where((keyword) => !lower.contains(keyword.toLowerCase()))
        .take(5)
        .toList();

    if (keywords.isNotEmpty) {
      if (missingSkills.isEmpty) {
        score += 12;
        strengths.add('Matches the target job description well.');
      } else {
        score += 4;
        improvements.add(
          'Mirror more truthful target-job keywords in your resume content.',
        );
      }
    }

    score = score.clamp(0, 100);

    return ResumeAnalysis(
      score: score,
      atsCompatibility: score / 100,
      missingSkills: missingSkills,
      weakDescriptions: weakDescriptions,
      strengths: strengths,
      improvements: improvements.toSet().toList(),
    );
  }

  List<String> _buildProofGapPrompts({
    required String resumeText,
    required String jobDescription,
  }) {
    final prompts = <String>[];
    final normalized = resumeText.trim();
    final lower = normalized.toLowerCase();
    final metricCount = RegExp(
      r'\b\d+[%+xXkKmM]?\b',
    ).allMatches(normalized).length;

    if (metricCount < 3) {
      prompts.add(
        'Which bullet can you quantify with a number, percentage, revenue impact, time saved, or users affected?',
      );
    }

    if (!_containsAny(lower, [
      'led',
      'owned',
      'built',
      'launched',
      'improved',
    ])) {
      prompts.add(
        'Where can you replace generic language with a stronger action verb like built, led, launched, improved, or reduced?',
      );
    }

    if (_containsAny(lower, ['team player', 'hardworking', 'responsible'])) {
      prompts.add(
        'Which vague phrase like "team player" or "responsible for" can you replace with a specific result or example?',
      );
    }

    final missingKeywords = _extractKeywords(jobDescription)
        .where((keyword) => !lower.contains(keyword.toLowerCase()))
        .take(2)
        .toList();
    if (missingKeywords.isNotEmpty) {
      prompts.add(
        'Which project or job entry best proves ${missingKeywords.join(' and ')} so you can add that evidence truthfully?',
      );
    }

    if (!_containsAny(lower, ['skills'])) {
      prompts.add(
        'What tools, platforms, or methods should be pulled into a dedicated skills section for easier ATS matching?',
      );
    }

    if (prompts.isEmpty) {
      prompts.add(
        'Your resume already reads strongly. Next, review each major claim and ask: what proof would make this even more believable to a recruiter?',
      );
    }

    return prompts.take(4).toList();
  }

  ResumeData _buildResumeFromImportedText({
    required String resumeText,
    required ResumeTemplate template,
    required String sourceTitle,
  }) {
    final normalizedText = resumeText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    final lines = normalizedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final sections = _splitImportedResumeSections(lines);
    final headerLines = sections['header'] ?? const <String>[];
    final summaryLines = sections['summary'] ?? const <String>[];
    final skillsLines = sections['skills'] ?? const <String>[];
    final experienceLines =
        sections['experience']
            ?.where((line) => line.trim().isNotEmpty)
            .toList() ??
        _fallbackImportedExperienceLines(lines);
    final educationLines =
        sections['education']
            ?.where((line) => line.trim().isNotEmpty)
            .toList() ??
        _fallbackImportedEducationLines(lines);
    final projectLines =
        sections['projects']
            ?.where((line) => line.trim().isNotEmpty)
            .toList() ??
        _fallbackImportedProjectLines(lines);

    final fallbackTitle = _cleanImportedTitle(sourceTitle);
    final fullName = _inferImportedFullName(headerLines, fallbackTitle);
    final jobTitle = _inferImportedJobTitle(
      headerLines: headerLines,
      experienceLines: experienceLines,
      fallbackTitle: fallbackTitle,
    );

    return ResumeData.empty(template: template.userFacingTemplate).copyWith(
      title: _normalizeImportedResumeTitle(
        sourceTitle: fallbackTitle,
        fullName: fullName,
        jobTitle: jobTitle,
      ),
      fullName: fullName,
      jobTitle: jobTitle,
      email:
          _firstRegexMatch(normalizedText, RegExp(r'[\w\.-]+@[\w\.-]+\.\w+')) ??
          '',
      phone: _extractImportedPhone(normalizedText),
      location: _inferImportedLocation(headerLines),
      website: _extractImportedWebsite(normalizedText),
      summary: _collectImportedSummary(
        summaryLines: summaryLines,
        headerLines: headerLines,
        allLines: lines,
      ),
      workExperiences: _extractImportedWorkExperiences(
        experienceLines: experienceLines,
        fallbackJobTitle: jobTitle,
      ),
      education: _extractImportedEducation(educationLines),
      skills: _extractImportedSkills(
        skillLines: skillsLines,
        resumeText: normalizedText,
      ).take(50).toList(),
      projects: _extractImportedProjects(projectLines),
      customSections: _extractImportedCustomSections(sections),
      githubLink: _extractImportedLink(normalizedText, 'github.com'),
      linkedinLink: _extractImportedLink(normalizedText, 'linkedin.com'),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, List<String>> _splitImportedResumeSections(List<String> lines) {
    final sections = <String, List<String>>{'header': <String>[]};
    var currentSection = 'header';

    for (final line in lines) {
      final headingData = _matchImportedSectionHeadingData(line);
      if (headingData != null) {
        currentSection = headingData.$1;
        sections.putIfAbsent(currentSection, () => <String>[]);
        if (headingData.$2.isNotEmpty) {
          sections[currentSection]!.add(headingData.$2);
        }
        continue;
      }

      sections.putIfAbsent(currentSection, () => <String>[]).add(line);
    }

    return sections;
  }

  String? _matchImportedSectionHeading(String line) {
    return _matchImportedSectionHeadingData(line)?.$1;
  }

  static const Map<String, String> _importedSectionHeadingMap = {
    'professional summary': 'summary',
    'career summary': 'summary',
    'executive summary': 'summary',
    'summary': 'summary',
    'profile': 'summary',
    'objective': 'summary',
    'technical skills': 'skills',
    'core competencies': 'skills',
    'key competencies': 'skills',
    'core skills': 'skills',
    'key skills': 'skills',
    'tools and technologies': 'skills',
    'tools & technologies': 'skills',
    'technologies': 'skills',
    'skills': 'skills',
    'professional experience': 'experience',
    'project experience': 'experience',
    'employment history': 'experience',
    'work experience': 'experience',
    'work history': 'experience',
    'career history': 'experience',
    'experience': 'experience',
    'employment': 'experience',
    'education and training': 'education',
    'academic background': 'education',
    'academic qualifications': 'education',
    'education': 'education',
    'selected projects': 'projects',
    'personal projects': 'projects',
    'academic projects': 'projects',
    'projects': 'projects',
    'project': 'projects',
    'certifications': 'certifications',
    'certification': 'certifications',
    'licenses': 'certifications',
    'languages': 'languages',
    'awards': 'awards',
    'honors': 'awards',
    'publications': 'publications',
    'volunteer experience': 'volunteer',
    'volunteer': 'volunteer',
    'activities': 'activities',
  };

  (String, String)? _matchImportedSectionHeadingData(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z& ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    for (final entry in _importedSectionHeadingMap.entries) {
      if (normalized == entry.key) {
        return (entry.value, '');
      }

      final aliasPattern = entry.key.split(' ').map(RegExp.escape).join(r'\s+');
      final prefixMatch = RegExp(
        '^$aliasPattern(?:\\s*[:\\-–—|]\\s*|\\s{2,})(.+)\$',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (prefixMatch != null) {
        return (entry.value, prefixMatch.group(1)?.trim() ?? '');
      }
    }

    return null;
  }

  String _inferImportedFullName(
    List<String> headerLines,
    String fallbackTitle,
  ) {
    for (final line in headerLines.take(3)) {
      if (_isImportedContactLine(line)) {
        continue;
      }
      final cleaned = line.trim();
      final wordCount = cleaned.split(RegExp(r'\s+')).length;
      if (cleaned.length <= 40 && wordCount <= 4) {
        return _toTitleCase(cleaned);
      }
    }

    final fallback = fallbackTitle
        .replaceAll(RegExp(r'\bresume\b', caseSensitive: false), '')
        .trim();
    return fallback.isEmpty ? '' : _toTitleCase(fallback);
  }

  String _inferImportedJobTitle({
    required List<String> headerLines,
    required List<String> experienceLines,
    required String fallbackTitle,
  }) {
    for (final line in headerLines.skip(1).take(3)) {
      if (_isImportedContactLine(line)) {
        continue;
      }
      if (line.split(RegExp(r'\s+')).length <= 8) {
        return line.trim();
      }
    }

    for (final line in experienceLines.take(3)) {
      if (_isImportedBulletLine(line) || _isImportedContactLine(line)) {
        continue;
      }
      final role = _extractImportedRole(line);
      if (role.isNotEmpty) {
        return role;
      }
    }

    return fallbackTitle
        .replaceAll(RegExp(r'\bresume\b', caseSensitive: false), '')
        .trim();
  }

  String _inferImportedLocation(List<String> headerLines) {
    for (final line in headerLines) {
      if (!_isImportedContactLine(line) && line.contains(',')) {
        return line.trim();
      }

      final segments = line.split('|').map((item) => item.trim());
      for (final segment in segments) {
        if (segment.contains(',') &&
            !_isImportedContactLine(segment) &&
            !segment.contains('@')) {
          return segment;
        }
      }
    }
    return '';
  }

  String _collectImportedSummary({
    required List<String> summaryLines,
    required List<String> headerLines,
    required List<String> allLines,
  }) {
    if (summaryLines.isNotEmpty) {
      return summaryLines.take(3).join(' ').trim();
    }

    final fallbackLines = allLines
        .where((line) {
          if (headerLines.contains(line)) {
            return false;
          }
          if (_matchImportedSectionHeading(line) != null) {
            return false;
          }
          if (_isImportedContactLine(line)) {
            return false;
          }
          return line.split(RegExp(r'\s+')).length >= 8;
        })
        .take(2);

    return fallbackLines.join(' ').trim();
  }

  List<String> _extractImportedSkills({
    required List<String> skillLines,
    required String resumeText,
  }) {
    final values = <String>{};
    final sources = skillLines.isNotEmpty
        ? skillLines
        : _extractKeywords(resumeText).take(10).toList();

    for (final source in sources) {
      final normalized = source
          .replaceAll('•', ',')
          .replaceAll('|', ',')
          .replaceAll('·', ',');
      for (final item in normalized.split(',')) {
        final cleaned = item.replaceAll(RegExp(r'^[\-\*\u2022]\s*'), '').trim();
        if (cleaned.isEmpty) {
          continue;
        }
        if (_matchImportedSectionHeading(cleaned) != null) {
          continue;
        }
        if (cleaned.split(RegExp(r'\s+')).length > 4) {
          continue;
        }
        values.add(cleaned);
      }
    }

    return values.toList();
  }

  List<WorkExperience> _extractImportedWorkExperiences({
    required List<String> experienceLines,
    required String fallbackJobTitle,
  }) {
    if (experienceLines.isEmpty) {
      return const [WorkExperience.empty()];
    }

    final entries = <List<String>>[];
    var current = <String>[];
    var sawBullet = false;

    for (final line in experienceLines) {
      final isBullet = _isImportedBulletLine(line);
      final currentHeaderCount = current
          .where((item) => !_isImportedBulletLine(item))
          .length;

      if (current.isNotEmpty &&
          !isBullet &&
          _looksLikeImportedExperienceHeader(line) &&
          (sawBullet || currentHeaderCount >= 2)) {
        entries.add(current);
        current = <String>[line];
        sawBullet = false;
        continue;
      }

      current.add(line);
      if (isBullet) {
        sawBullet = true;
      }
    }

    if (current.isNotEmpty) {
      entries.add(current);
    }

    final items = entries
        .map(
          (entry) => _buildImportedWorkExperience(
            entry,
            fallbackJobTitle: fallbackJobTitle,
          ),
        )
        .where((item) => !item.isBlank)
        .toList();

    return items.isEmpty ? const [WorkExperience.empty()] : items;
  }

  List<EducationItem> _extractImportedEducation(List<String> educationLines) {
    if (educationLines.isEmpty) {
      return const [EducationItem.empty()];
    }

    final entries = <List<String>>[];
    var current = <String>[];

    for (final line in educationLines) {
      if (current.isNotEmpty &&
          _looksLikeImportedEducationHeader(line) &&
          _educationEntryLooksComplete(current)) {
        entries.add(current);
        current = <String>[line];
        continue;
      }
      current.add(line);
    }

    if (current.isNotEmpty) {
      entries.add(current);
    }

    final items = entries
        .map(_buildImportedEducationItem)
        .where((item) => !item.isBlank)
        .toList();

    return items.isEmpty ? const [EducationItem.empty()] : items;
  }

  List<ProjectItem> _extractImportedProjects(List<String> projectLines) {
    if (projectLines.isEmpty) {
      return const [ProjectItem.empty()];
    }

    final entries = <List<String>>[];
    var current = <String>[];
    var sawBullet = false;

    for (final line in projectLines) {
      final isBullet = _isImportedBulletLine(line);
      if (current.isNotEmpty &&
          !isBullet &&
          _looksLikeImportedProjectHeader(line) &&
          sawBullet) {
        entries.add(current);
        current = <String>[line];
        sawBullet = false;
        continue;
      }

      current.add(line);
      if (isBullet) {
        sawBullet = true;
      }
    }

    if (current.isNotEmpty) {
      entries.add(current);
    }

    final items = entries
        .map(_buildImportedProjectItem)
        .where((item) => !item.isBlank)
        .toList();

    return items.isEmpty ? const [ProjectItem.empty()] : items;
  }

  List<CustomSectionItem> _extractImportedCustomSections(
    Map<String, List<String>> sections,
  ) {
    const customSectionTitles = <String, String>{
      'certifications': 'Certifications',
      'languages': 'Languages',
      'awards': 'Awards',
      'publications': 'Publications',
      'volunteer': 'Volunteer Experience',
      'activities': 'Activities',
    };

    final items = <CustomSectionItem>[];
    for (final entry in customSectionTitles.entries) {
      final lines = sections[entry.key] ?? const <String>[];
      if (lines.isEmpty) {
        continue;
      }

      final bullets = lines
          .where(_isImportedBulletLine)
          .map(_stripImportedBullet)
          .where((line) => line.isNotEmpty)
          .toList();
      final content = lines
          .where((line) => !_isImportedBulletLine(line))
          .join('\n')
          .trim();

      final item = bullets.isNotEmpty
          ? CustomSectionItem(
              title: entry.value,
              content: content,
              layoutMode: CustomSectionLayoutMode.bullets,
              bullets: bullets,
            )
          : CustomSectionItem(
              title: entry.value,
              content: content,
              layoutMode: CustomSectionLayoutMode.summary,
            );

      if (!item.isBlank) {
        items.add(item);
      }
    }

    return items;
  }

  List<String> _fallbackImportedExperienceLines(List<String> lines) {
    final collected = <String>[];
    var started = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }

      if (!started) {
        if (_looksLikeImportedExperienceHeader(line) &&
            _looksLikeExperienceEntryStart(lines, i)) {
          started = true;
          collected.add(line);
        }
        continue;
      }

      if (_isFallbackSectionBoundary(line, stopAtProjects: true) ||
          _looksLikeEducationEntryStart(lines, i)) {
        break;
      }

      collected.add(line);
    }

    return collected;
  }

  List<String> _fallbackImportedEducationLines(List<String> lines) {
    final collected = <String>[];
    var started = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }

      if (!started) {
        if (_looksLikeEducationEntryStart(lines, i)) {
          started = true;
          collected.add(line);
        }
        continue;
      }

      if (_isFallbackSectionBoundary(line, stopAtProjects: true)) {
        break;
      }

      collected.add(line);
    }

    return collected;
  }

  List<String> _fallbackImportedProjectLines(List<String> lines) {
    final collected = <String>[];
    var started = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }

      if (!started) {
        final lower = line.toLowerCase();
        if (lower.contains('project') &&
            !_isImportedContactLine(line) &&
            !_looksLikeImportedDateLine(line)) {
          started = true;
          collected.add(line);
        }
        continue;
      }

      if (_isFallbackSectionBoundary(line, stopAtProjects: false)) {
        break;
      }

      collected.add(line);
    }

    return collected;
  }

  bool _looksLikeExperienceEntryStart(List<String> lines, int index) {
    return _hasLookAheadMatch(lines, index, _looksLikeImportedDateLine, 2) ||
        _hasLookAheadMatch(lines, index, _isImportedBulletLine, 3);
  }

  bool _looksLikeEducationEntryStart(List<String> lines, int index) {
    final line = lines[index].trim();
    final lower = line.toLowerCase();
    final hasEducationKeyword = RegExp(
      r'(bachelor|master|diploma|degree|b\.tech|btech|mba|bsc|msc|ba|bs|phd|certificate|certification|associate)',
      caseSensitive: false,
    ).hasMatch(line);

    if (hasEducationKeyword) {
      return _hasLookAheadMatch(lines, index, _looksLikeImportedDateLine, 3) ||
          _hasLookAheadMatch(
            lines,
            index,
            (candidate) =>
                candidate.contains('University') ||
                candidate.contains('College') ||
                candidate.contains('Institute') ||
                candidate.contains('School'),
            2,
          );
    }

    return (lower.contains('university') ||
            lower.contains('college') ||
            lower.contains('institute') ||
            lower.contains('school')) &&
        _hasLookAheadMatch(lines, index, _looksLikeImportedDateLine, 2);
  }

  bool _hasLookAheadMatch(
    List<String> lines,
    int startIndex,
    bool Function(String line) predicate,
    int lookAhead,
  ) {
    final end = math.min(lines.length, startIndex + lookAhead + 1);
    for (var i = startIndex + 1; i < end; i++) {
      if (predicate(lines[i].trim())) {
        return true;
      }
    }
    return false;
  }

  bool _isFallbackSectionBoundary(String line, {required bool stopAtProjects}) {
    final heading = _matchImportedSectionHeading(line);
    if (heading == null) {
      return false;
    }

    if (heading == 'summary' ||
        heading == 'skills' ||
        heading == 'experience') {
      return false;
    }

    if (!stopAtProjects && heading == 'projects') {
      return false;
    }

    return true;
  }

  String _cleanImportedTitle(String sourceTitle) {
    final withoutExtension = sourceTitle.replaceFirst(
      RegExp(r'\.[a-z0-9]+$', caseSensitive: false),
      '',
    );
    return withoutExtension
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeImportedResumeTitle({
    required String sourceTitle,
    required String fullName,
    required String jobTitle,
  }) {
    if (sourceTitle.isNotEmpty) {
      return sourceTitle;
    }
    if (jobTitle.isNotEmpty) {
      return '$jobTitle Resume';
    }
    if (fullName.isNotEmpty) {
      return '$fullName Resume';
    }
    return ResumeData.defaultTitle;
  }

  int _scoreImportedResumeParse(ResumeData resume, String sourceText) {
    var score = 0;

    if (resume.fullName.trim().isNotEmpty &&
        !resume.fullName.contains('@') &&
        !RegExp(r'\d').hasMatch(resume.fullName)) {
      score += 10;
    }
    if (resume.jobTitle.trim().isNotEmpty) {
      score += 8;
    }
    if (resume.email.trim().isNotEmpty) {
      score += 8;
    }
    if (resume.phone.trim().isNotEmpty) {
      score += 6;
    }
    if (resume.location.trim().isNotEmpty) {
      score += 4;
    }
    if (resume.website.trim().isNotEmpty) {
      score += 3;
    }
    if (resume.githubLink.trim().isNotEmpty) {
      score += 2;
    }
    if (resume.linkedinLink.trim().isNotEmpty) {
      score += 2;
    }
    if (resume.summary.trim().length >= 60) {
      score += 12;
    } else if (resume.summary.trim().isNotEmpty) {
      score += 5;
    }

    for (final item in resume.visibleWorkExperiences) {
      score += 12;
      if (item.role.trim().isNotEmpty) {
        score += 4;
      }
      if (item.company.trim().isNotEmpty) {
        score += 4;
      }
      if (item.startDate.trim().isNotEmpty || item.endDate.trim().isNotEmpty) {
        score += 3;
      }
      score += math.min(
        4,
        item.bullets.where((b) => b.trim().isNotEmpty).length,
      );
    }

    for (final item in resume.visibleEducation) {
      score += 10;
      if (item.degree.trim().isNotEmpty) {
        score += 4;
      }
      if (item.institution.trim().isNotEmpty) {
        score += 4;
      }
    }

    score += math.min(20, resume.skills.length * 2);

    for (final item in resume.visibleProjects) {
      score += 8;
      if (item.title.trim().isNotEmpty) {
        score += 4;
      }
      score += math.min(
        3,
        item.bullets.where((b) => b.trim().isNotEmpty).length,
      );
    }

    score += resume.visibleCustomSections.length * 3;

    final lower = sourceText.toLowerCase();
    if (_containsAny(lower, const ['experience', 'work experience']) &&
        resume.visibleWorkExperiences.isEmpty) {
      score -= 12;
    }
    if (_containsAny(lower, const ['education']) &&
        resume.visibleEducation.isEmpty) {
      score -= 10;
    }
    if (_containsAny(lower, const ['skills', 'core competencies']) &&
        resume.skills.isEmpty) {
      score -= 10;
    }
    if (_containsAny(lower, const ['projects', 'project']) &&
        resume.visibleProjects.isEmpty) {
      score -= 8;
    }
    if (_containsAny(lower, const ['summary', 'profile']) &&
        resume.summary.trim().isEmpty) {
      score -= 8;
    }

    return score;
  }

  bool _isImportedContactLine(String line) {
    return line.contains('@') ||
        RegExp(r'(https?:\/\/|www\.)', caseSensitive: false).hasMatch(line) ||
        RegExp(r'(\+\d{1,3}[\s-]?)?(\d[\s-]?){10,}').hasMatch(line);
  }

  bool _isImportedBulletLine(String line) {
    return RegExp(r'^\s*[\-\u2022\*]').hasMatch(line);
  }

  String _stripImportedBullet(String line) {
    return line.replaceFirst(RegExp(r'^\s*[\-\u2022\*]\s*'), '').trim();
  }

  bool _looksLikeImportedExperienceHeader(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty ||
        _isImportedBulletLine(cleaned) ||
        _looksLikeImportedDateLine(cleaned)) {
      return false;
    }

    final wordCount = cleaned.split(RegExp(r'\s+')).length;
    if (cleaned.contains('|') || cleaned.contains(' / ')) {
      return true;
    }
    if (RegExp(r'\bat\b', caseSensitive: false).hasMatch(cleaned)) {
      return true;
    }

    return wordCount <= 8 && !cleaned.endsWith('.');
  }

  bool _looksLikeImportedProjectHeader(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty ||
        _isImportedBulletLine(cleaned) ||
        _looksLikeImportedDateLine(cleaned)) {
      return false;
    }

    return cleaned.split(RegExp(r'\s+')).length <= 10 && !cleaned.endsWith('.');
  }

  bool _looksLikeImportedEducationHeader(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty || _looksLikeImportedDateLine(cleaned)) {
      return false;
    }

    return RegExp(
          r'(bachelor|master|diploma|degree|b\.tech|btech|mba|bsc|msc|ba|bs|phd|certificate|certification|associate)',
          caseSensitive: false,
        ).hasMatch(cleaned) ||
        (cleaned.split(RegExp(r'\s+')).length <= 8 && !cleaned.endsWith('.'));
  }

  bool _educationEntryLooksComplete(List<String> lines) {
    return lines.length >= 2 && lines.any(_looksLikeImportedDateLine);
  }

  WorkExperience _buildImportedWorkExperience(
    List<String> entry, {
    required String fallbackJobTitle,
  }) {
    final bulletLines = entry
        .where(_isImportedBulletLine)
        .map(_stripImportedBullet)
        .where((line) => line.isNotEmpty)
        .take(8)
        .toList();
    final detailLines = entry
        .where((line) => !_isImportedBulletLine(line))
        .toList();

    var role = fallbackJobTitle;
    var company = '';
    var startDate = '';
    var endDate = '';
    final descriptionLines = <String>[];

    for (final line in detailLines) {
      if (_looksLikeImportedDateLine(line)) {
        final dates = _extractImportedDates(line);
        if (startDate.isEmpty && dates.$1.isNotEmpty) {
          startDate = dates.$1;
        }
        if (endDate.isEmpty && dates.$2.isNotEmpty) {
          endDate = dates.$2;
        }
        continue;
      }

      if (role == fallbackJobTitle || role.trim().isEmpty) {
        role = _extractImportedRole(line).ifEmpty(fallbackJobTitle);
        company = _extractImportedCompany(line);
        continue;
      }

      if (company.isEmpty &&
          line.split(RegExp(r'\s+')).length <= 8 &&
          !line.endsWith('.')) {
        company = line.trim();
        continue;
      }

      descriptionLines.add(line);
    }

    final description = descriptionLines.take(2).join(' ').trim();
    return WorkExperience(
      role: role.ifEmpty(fallbackJobTitle),
      company: company,
      startDate: startDate,
      endDate: endDate,
      description: description,
      bullets: bulletLines,
      layoutMode: WorkExperienceLayoutMode.bullets,
    );
  }

  EducationItem _buildImportedEducationItem(List<String> entry) {
    final combined = entry.join(' | ');
    final dates = _extractImportedDates(combined);
    final score =
        _firstRegexMatch(
          combined,
          RegExp(
            r'\b\d+(?:\.\d+)?\s*(?:cgpa|gpa|%|percent)\b',
            caseSensitive: false,
          ),
        ) ??
        '';
    final degree = entry.firstWhere(
      (line) => RegExp(
        r'(bachelor|master|diploma|degree|b\.tech|btech|mba|bsc|msc|ba|bs|phd|certificate|certification|associate)',
        caseSensitive: false,
      ).hasMatch(line),
      orElse: () => entry.first,
    );
    final institution = entry.firstWhere(
      (line) =>
          line != degree && !_looksLikeImportedDateLine(line) && line != score,
      orElse: () => '',
    );

    return EducationItem(
      institution: institution,
      degree: degree,
      startDate: dates.$1,
      endDate: dates.$2,
      score: score,
    );
  }

  ProjectItem _buildImportedProjectItem(List<String> entry) {
    final bullets = entry
        .where(_isImportedBulletLine)
        .map(_stripImportedBullet)
        .where((line) => line.isNotEmpty)
        .take(6)
        .toList();
    final detailLines = entry
        .where((line) => !_isImportedBulletLine(line))
        .toList();
    final title = detailLines.isNotEmpty ? detailLines.first.trim() : 'Project';
    final overview = detailLines.skip(1).take(2).join(' ').trim();

    return ProjectItem(title: title, overview: overview, bullets: bullets);
  }

  bool _looksLikeImportedDateLine(String line) {
    return RegExp(
      r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\b(?:19|20)\d{2}\b|present|current)',
      caseSensitive: false,
    ).hasMatch(line);
  }

  (String, String) _extractImportedDates(String line) {
    final matches = RegExp(
      r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\b(?:19|20)\d{2}\b|present|current)',
      caseSensitive: false,
    ).allMatches(line).map((match) => match.group(0)!.trim()).toList();

    if (matches.isEmpty) {
      return ('', '');
    }

    if (matches.length == 1) {
      final only = matches.first;
      final normalized =
          RegExp(r'^(present|current)$', caseSensitive: false).hasMatch(only)
          ? 'Present'
          : only;
      return ('', normalized);
    }

    final start = matches.first;
    final rawEnd = matches[1];
    final end =
        RegExp(r'^(present|current)$', caseSensitive: false).hasMatch(rawEnd)
        ? 'Present'
        : rawEnd;
    return (start, end);
  }

  String _extractImportedRole(String line) {
    final cleaned = line.trim();
    if (cleaned.contains('|')) {
      return cleaned.split('|').first.trim();
    }
    if (RegExp(r'\bat\b', caseSensitive: false).hasMatch(cleaned)) {
      return cleaned
          .split(RegExp(r'\bat\b', caseSensitive: false))
          .first
          .trim();
    }
    return cleaned;
  }

  String _extractImportedCompany(String line) {
    final cleaned = line.trim();
    if (cleaned.contains('|')) {
      final parts = cleaned.split('|').map((part) => part.trim()).toList();
      if (parts.length >= 2) {
        return parts[1];
      }
    }
    if (RegExp(r'\bat\b', caseSensitive: false).hasMatch(cleaned)) {
      final parts = cleaned.split(RegExp(r'\bat\b', caseSensitive: false));
      if (parts.length >= 2) {
        return parts[1].trim();
      }
    }
    return '';
  }

  String _extractImportedPhone(String text) {
    return _firstRegexMatch(
          text,
          RegExp(r'(\+\d{1,3}[\s-]?)?(\d[\s-]?){10,}'),
        ) ??
        '';
  }

  String _extractImportedWebsite(String text) {
    final matches = RegExp(
      r'((?:https?:\/\/|www\.)[^\s]+)',
      caseSensitive: false,
    ).allMatches(text);

    for (final match in matches) {
      final value = match.group(0)?.trim() ?? '';
      final lower = value.toLowerCase();
      if (lower.contains('linkedin.com') || lower.contains('github.com')) {
        continue;
      }
      return value;
    }

    return '';
  }

  String _extractImportedLink(String text, String domain) {
    final regex = RegExp(
      '((?:(?:https?:\\/\\/|www\\.)?[^\\s|]*${RegExp.escape(domain)}[^\\s|]*))',
      caseSensitive: false,
    );
    return _firstRegexMatch(text, regex) ?? '';
  }

  String? _firstRegexMatch(String text, RegExp pattern) {
    final match = pattern.firstMatch(text);
    return match?.group(0);
  }

  String _toTitleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length <= 2
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _buildSummary(ResumeData resume) {
    final title = resume.jobTitle.trim().isEmpty
        ? 'professional candidate'
        : resume.jobTitle.trim();
    final primarySkills = resume.skills.take(4).join(', ');
    final experienceCount = math.max(1, resume.visibleWorkExperiences.length);

    return '${resume.fullName.trim().isEmpty ? 'Results-driven' : resume.fullName.trim()} '
        'is a $title with $experienceCount standout experience ${experienceCount == 1 ? 'entry' : 'stories'} '
        'across delivery, collaboration, and measurable execution. '
        '${primarySkills.isEmpty ? 'Combines strong communication, problem solving, and ownership to create polished outcomes.' : 'Brings $primarySkills to build polished outcomes with real business impact.'} '
        'Ready to contribute quickly in fast-moving teams.';
  }

  List<String> _buildJobBullets({
    required String role,
    required String company,
    required String targetJobTitle,
  }) {
    final focus = _jobTitleSkillSuggestions(targetJobTitle).take(3).join(', ');
    final normalizedRole = role.trim().isEmpty
        ? 'team member'
        : role.trim().toLowerCase();
    final normalizedCompany = company.trim().isEmpty
        ? 'the company'
        : company.trim();

    return [
      'Led $normalizedRole initiatives at $normalizedCompany, improving delivery quality through clearer prioritization and faster stakeholder alignment.',
      'Translated business needs into repeatable workflows and documentation, helping the team move faster with fewer revision cycles.',
      'Partnered cross-functionally to launch customer-facing improvements, using $focus to strengthen outcomes and communicate impact.',
    ];
  }

  List<String> _resumeSkillSuggestions({
    required ResumeData resume,
    String? targetJobTitle,
  }) {
    final suggestions = <String>[];
    final titleSources = <String>[];
    final seenTitleSources = <String>{};

    void addTitleSource(String value, {bool ignoreDefaultTitle = false}) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      if (ignoreDefaultTitle && trimmed == ResumeData.defaultTitle) {
        return;
      }

      if (seenTitleSources.add(trimmed.toLowerCase())) {
        titleSources.add(trimmed);
      }
    }

    addTitleSource(resume.title, ignoreDefaultTitle: true);
    addTitleSource(resume.jobTitle);
    addTitleSource(targetJobTitle ?? '');

    void addSuggestions(Iterable<String> values) {
      for (final value in values) {
        if (!suggestions.contains(value)) {
          suggestions.add(value);
        }
      }
    }

    // 1. Role-based skills from each work experience job title.
    for (final item in resume.visibleWorkExperiences) {
      addSuggestions(_jobTitleSkillSuggestions(item.role));
    }

    // 2. Keywords from work experience text (role, company, description, bullets).
    final workOnlyContext = resume.visibleWorkExperiences
        .expand(
          (item) => [
            item.role,
            item.company,
            item.description,
            ...item.bullets,
          ],
        )
        .where((item) => item.trim().isNotEmpty)
        .join(' ')
        .toLowerCase();
    _addSkillsMatchingContext(workOnlyContext, addSuggestions);

    // 3. Full resume: summary, education, projects, target role, etc.
    final combinedContext = <String>[
      ...titleSources,
      resume.summary,
      ...resume.skills,
      ...resume.visibleWorkExperiences.expand(
        (item) => [item.role, item.company, item.description, ...item.bullets],
      ),
      ...resume.visibleEducation.expand(
        (item) => [
          item.institution,
          item.degree,
          item.startDate,
          item.endDate,
          item.score,
        ],
      ),
      ...resume.visibleProjects.expand(
        (item) => [
          item.title,
          item.subtitle,
          item.overview,
          item.impact,
          ...item.bullets,
        ],
      ),
      ...resume.visibleCustomSections.expand(
        (section) => [
          section.title,
          if (section.layoutMode == CustomSectionLayoutMode.summary)
            section.content
          else
            ...section.bullets,
        ],
      ),
    ].where((item) => item.trim().isNotEmpty).join(' ').toLowerCase();

    _addSkillsMatchingContext(combinedContext, addSuggestions);

    // 4. Document title and target job title (deduped).
    for (final titleSource in titleSources) {
      addSuggestions(_jobTitleSkillSuggestions(titleSource));
    }

    if (suggestions.isEmpty) {
      addSuggestions(const [
        'Communication',
        'Problem Solving',
        'Cross-functional Collaboration',
      ]);
    }

    return suggestions.take(8).toList();
  }

  List<String> _jobTitleSkillSuggestions(String jobTitle) {
    final normalized = jobTitle.toLowerCase();
    final suggestions = <String>{'Communication', 'Problem Solving'};

    if (normalized.contains('designer')) {
      suggestions.addAll([
        'Figma',
        'Design Systems',
        'User Research',
        'Wireframing',
        'Prototyping',
        'Accessibility',
      ]);
    } else if (normalized.contains('product')) {
      suggestions.addAll([
        'Product Strategy',
        'Stakeholder Management',
        'Roadmapping',
        'A/B Testing',
        'SQL',
        'Analytics',
        'Experiment Design',
      ]);
    } else if (normalized.contains('data scientist') ||
        normalized.contains('data science') ||
        normalized.contains('machine learning') ||
        normalized.contains(' ml ') ||
        normalized.startsWith('ml ') ||
        normalized.contains('research scientist')) {
      suggestions.addAll([
        'Python',
        'SQL',
        'Machine Learning',
        'Statistics',
        'Experiment Design',
        'Data Visualization',
      ]);
    } else if (normalized.contains('analyst') ||
        normalized.contains('analytics')) {
      suggestions.addAll([
        'SQL',
        'Analytics',
        'Data Visualization',
        'A/B Testing',
        'Excel',
        'Dashboarding',
      ]);
    } else if (normalized.contains('devops') ||
        normalized.contains('sre') ||
        normalized.contains('platform engineer') ||
        normalized.contains('site reliability')) {
      suggestions.addAll([
        'CI/CD',
        'Docker',
        'Kubernetes',
        'AWS',
        'Infrastructure as Code',
        'Monitoring',
      ]);
    } else if (normalized.contains('qa') ||
        normalized.contains('quality engineer') ||
        normalized.contains('test engineer')) {
      suggestions.addAll([
        'Unit Testing',
        'Test Automation',
        'CI/CD',
        'Documentation',
      ]);
    } else if (normalized.contains('intern') ||
        normalized.contains('student') ||
        normalized.contains('undergraduate') ||
        normalized.contains('graduate') ||
        normalized.contains('fresher')) {
      suggestions.addAll([
        'Data Structures and Algorithms',
        'Object-Oriented Programming',
        'SQL',
        'Git',
        'Unit Testing',
        'Debugging',
      ]);
    } else if (normalized.contains('engineer') ||
        normalized.contains('developer')) {
      suggestions.addAll([
        'Flutter',
        'Dart',
        'REST APIs',
        'State Management',
        'CI/CD',
        'Unit Testing',
      ]);
    } else if (normalized.contains('marketing')) {
      suggestions.addAll([
        'Campaign Strategy',
        'SEO',
        'Content Planning',
        'Performance Marketing',
        'CRM',
      ]);
    } else {
      suggestions.addAll([
        'Project Management',
        'Cross-functional Collaboration',
        'Documentation',
        'Presentation Skills',
      ]);
    }

    return suggestions.toList();
  }

  /// Keyword-based skills inferred from free text (job descriptions, bullets, etc.).
  void _addSkillsMatchingContext(
    String contextLower,
    void Function(Iterable<String>) addSuggestions,
  ) {
    if (_containsAny(contextLower, ['flutter', 'dart'])) {
      addSuggestions(['Flutter', 'Dart']);
    }
    if (_containsAny(contextLower, ['mobile', 'android', 'ios', 'app store'])) {
      addSuggestions(['Mobile App Development']);
    }
    if (_containsAny(contextLower, ['rest api', 'restful', 'api', 'graphql'])) {
      addSuggestions(['REST APIs', 'API Integration']);
    }
    if (_containsAny(contextLower, [
      'provider',
      'bloc',
      'riverpod',
      'state management',
    ])) {
      addSuggestions(['State Management']);
    }
    if (_containsAny(contextLower, ['firebase'])) {
      addSuggestions(['Firebase']);
    }
    if (_containsAny(contextLower, ['unit test', 'widget test', 'testing'])) {
      addSuggestions(['Unit Testing']);
    }
    if (_containsAny(contextLower, [
      'deploy',
      'release',
      'ci/cd',
      'pipeline',
    ])) {
      addSuggestions(['CI/CD']);
    }
    if (_containsAny(contextLower, ['react', 'next.js', 'nextjs'])) {
      addSuggestions(['React']);
    }
    if (_containsAny(contextLower, ['javascript'])) {
      addSuggestions(['JavaScript']);
    }
    if (_containsAny(contextLower, ['typescript'])) {
      addSuggestions(['TypeScript']);
    }
    if (_containsAny(contextLower, ['figma', 'wireframe', 'prototype'])) {
      addSuggestions(['Figma', 'Wireframing', 'Prototyping']);
    }
    if (_containsAny(contextLower, [
      'design system',
      'ui kit',
      'component library',
    ])) {
      addSuggestions(['Design Systems']);
    }
    if (_containsAny(contextLower, [
      'user research',
      'user interview',
      'usability',
    ])) {
      addSuggestions(['User Research']);
    }
    if (_containsAny(contextLower, ['sql', 'query', 'database', 'warehouse'])) {
      addSuggestions(['SQL', 'Data Analysis']);
    }
    if (_containsAny(contextLower, [
      'dashboard',
      'analytics',
      'metric',
      'kpi',
    ])) {
      addSuggestions(['Analytics', 'Dashboarding']);
    }
    if (_containsAny(contextLower, ['a/b test', 'ab test', 'experiment'])) {
      addSuggestions(['A/B Testing', 'Experiment Design']);
    }
    if (_containsAny(contextLower, [
      'roadmap',
      'product strategy',
      'backlog',
    ])) {
      addSuggestions(['Roadmapping', 'Product Strategy']);
    }
    if (_containsAny(contextLower, [
      'stakeholder',
      'client',
      'cross-functional',
      'cross functional',
    ])) {
      addSuggestions([
        'Stakeholder Management',
        'Cross-functional Collaboration',
      ]);
    }
    if (_containsAny(contextLower, [
      'document',
      'documentation',
      'report',
      'spec',
    ])) {
      addSuggestions(['Documentation']);
    }
    if (_containsAny(contextLower, [
      'launch',
      'delivery',
      'deliver',
      'execution',
    ])) {
      addSuggestions(['Project Management', 'Execution']);
    }
    if (_containsAny(contextLower, [
      'process improvement',
      'workflow',
      'automation',
      'streamline',
    ])) {
      addSuggestions(['Process Improvement']);
    }
    if (_containsAny(contextLower, [
      'presentation',
      'presented',
      'training',
      'enablement',
    ])) {
      addSuggestions(['Presentation Skills']);
    }
    if (_containsAny(contextLower, ['seo', 'campaign', 'content', 'crm'])) {
      addSuggestions(['SEO', 'Campaign Strategy', 'Content Planning']);
    }
  }

  bool _containsAny(String value, List<String> needles) {
    for (final needle in needles) {
      if (value.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  Iterable<String> _extractKeywords(String input) sync* {
    final commonWords = {
      'with',
      'that',
      'from',
      'this',
      'your',
      'their',
      'will',
      'have',
      'about',
      'using',
      'years',
      'ability',
      'team',
      'work',
      'role',
      'experience',
      'responsible',
      'preferred',
      'required',
    };

    final matches = RegExp(r'[A-Za-z][A-Za-z+/&-]{3,}').allMatches(input);
    final unique = <String>{};
    for (final match in matches) {
      final keyword = match.group(0)!.trim();
      final lower = keyword.toLowerCase();
      if (!commonWords.contains(lower) && unique.add(keyword)) {
        yield keyword;
      }
    }
  }

  Future<T> _simulate<T>(T Function() action) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return action();
  }
}

class ResumePdfService {
  Future<Uint8List> buildPdf(ResumeData resume) async {
    final bodyFont = ResumeTextFont.calibri;
    final corporateBodyPt = resume.effectiveBodyFontPt.toDouble();
    final document = pw.Document(
      theme: await resumePdfThemeForBodyFont(
        bodyFont,
        bodyFontPt: corporateBodyPt,
      ),
    );
    final profileImage = await _loadProfileImage(resume.profileImagePath);

    switch (resume.template) {
      case ResumeTemplate.corporate:
        _addCorporateTemplatePage(document, resume, profileImage: profileImage);
        break;
      case ResumeTemplate.creative:
        _addCreativeTemplatePage(document, resume, profileImage: profileImage);
        break;
      case ResumeTemplate.classicSidebar:
        _addClassicSidebarTemplatePage(
          document,
          resume,
          profileImage: profileImage,
        );
        break;
    }

    return document.save();
  }

  Future<Uint8List> buildHighlightedResumePdf({
    required ResumeData resume,
    bool highlightSummary = false,
    Set<String> highlightedSkills = const {},
    Map<int, Set<String>> highlightedBulletsByExperience = const {},
  }) async {
    final bodyFont = ResumeTextFont.calibri;
    final corporateBodyPt = resume.effectiveBodyFontPt.toDouble();
    final document = pw.Document(
      theme: await resumePdfThemeForBodyFont(
        bodyFont,
        bodyFontPt: corporateBodyPt,
      ),
    );
    switch (resume.template) {
      case ResumeTemplate.corporate:
        _addHighlightedCorporateTemplatePage(
          document,
          resume,
          highlightSummary: highlightSummary,
          highlightedSkills: highlightedSkills,
          highlightedBulletsByExperience: highlightedBulletsByExperience,
        );
        break;
      case ResumeTemplate.creative:
        _addHighlightedCreativeTemplatePage(
          document,
          resume,
          highlightSummary: highlightSummary,
          highlightedSkills: highlightedSkills,
          highlightedBulletsByExperience: highlightedBulletsByExperience,
        );
        break;
      case ResumeTemplate.classicSidebar:
        _addHighlightedClassicSidebarTemplatePage(
          document,
          resume,
          highlightSummary: highlightSummary,
          highlightedSkills: highlightedSkills,
          highlightedBulletsByExperience: highlightedBulletsByExperience,
        );
        break;
    }

    return document.save();
  }

  Future<Uint8List> buildCoverLetterPdf(CoverLetterData coverLetter) async {
    final document = pw.Document(
      theme: await resumePdfThemeForBodyFont(ResumeTextFont.inter),
    );
    final parsed = _parseCoverLetterContent(coverLetter.content);

    switch (coverLetter.template) {
      case CoverLetterTemplate.executiveNote:
        _addExecutiveNoteCoverLetterPage(document, parsed);
        break;
      case CoverLetterTemplate.minimalLetter:
        _addMinimalCoverLetterPage(document, parsed);
        break;
      case CoverLetterTemplate.sidebarLetter:
        _addSidebarCoverLetterPage(document, parsed);
        break;
    }

    return document.save();
  }

  Future<pw.MemoryImage?> _loadProfileImage(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final file = File(trimmed);
    if (!await file.exists()) {
      return null;
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    return pw.MemoryImage(bytes);
  }

  void _addExecutiveNoteCoverLetterPage(
    pw.Document document,
    _ParsedCoverLetterContent parsed,
  ) {
    final headerColor = PdfColor.fromHex('#1F2937');
    final dividerColor = PdfColor.fromHex('#E5E7EB');

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(28, 22, 28, 28),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: headerColor,
              borderRadius: pw.BorderRadius.circular(18),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  parsed.senderName,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (parsed.senderDetails.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    parsed.senderDetails.join('  |  '),
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Divider(color: dividerColor),
          pw.SizedBox(height: 10),
          _buildCoverLetterRecipientBlock(parsed),
          pw.SizedBox(height: 16),
          ..._buildCoverLetterBody(parsed),
        ],
      ),
    );
  }

  void _addMinimalCoverLetterPage(
    pw.Document document,
    _ParsedCoverLetterContent parsed,
  ) {
    final accent = PdfColor.fromHex('#9A6B2F');

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(32, 26, 32, 28),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              parsed.senderName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 25,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
          ),
          if (parsed.senderDetails.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                parsed.senderDetails.join('  |  '),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#5E6369'),
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Container(height: 1, color: accent),
          pw.SizedBox(height: 18),
          _buildCoverLetterRecipientBlock(parsed),
          pw.SizedBox(height: 16),
          ..._buildCoverLetterBody(parsed),
        ],
      ),
    );
  }

  void _addSidebarCoverLetterPage(
    pw.Document document,
    _ParsedCoverLetterContent parsed,
  ) {
    final accent = PdfColor.fromHex('#E39A3A');
    final dark = PdfColor.fromHex('#161616');

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 28),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 150,
                padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 18),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FAF4EB'),
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: accent, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 44,
                      height: 44,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: dark,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        parsed.senderInitial,
                        style: pw.TextStyle(
                          color: accent,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    pw.Text(
                      parsed.senderName,
                      style: pw.TextStyle(
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    for (final line in parsed.senderDetails)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Text(
                          line,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColor.fromHex('#4B4F55'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildCoverLetterRecipientBlock(parsed),
                    pw.SizedBox(height: 16),
                    ..._buildCoverLetterBody(parsed),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCoverLetterRecipientBlock(_ParsedCoverLetterContent parsed) {
    return pw.Text(
      parsed.recipientLines.join('\n'),
      style: pw.TextStyle(
        fontSize: 11,
        color: PdfColor.fromHex('#4B4F55'),
        height: 1.45,
      ),
    );
  }

  List<pw.Widget> _buildCoverLetterBody(_ParsedCoverLetterContent parsed) {
    final bodyStyle = pw.TextStyle(
      fontSize: 11.5,
      height: 1.6,
      color: PdfColor.fromHex('#202327'),
    );

    return [
      pw.Text(
        parsed.greeting,
        style: bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 12),
      for (final paragraph in parsed.bodyParagraphs) ...[
        pw.Text(paragraph, style: bodyStyle),
        pw.SizedBox(height: 12),
      ],
      pw.Text(parsed.closing, style: bodyStyle),
      pw.SizedBox(height: 20),
      pw.Text(
        parsed.signature,
        style: bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
      ),
    ];
  }

  _ParsedCoverLetterContent _parseCoverLetterContent(String content) {
    final normalized = content.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const _ParsedCoverLetterContent(
        senderLines: <String>['[Your Name]'],
        recipientLines: <String>[
          'Hiring Manager',
          '[Company Name]',
          '[Company Address]',
          '[City, State, Zip Code]',
        ],
        greeting: 'Dear Hiring Manager,',
        bodyParagraphs: <String>[
          'Your generated cover letter will appear here.',
        ],
        closing: 'Sincerely,',
        signature: '[Your Name]',
      );
    }

    final sections = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (sections.length < 3) {
      return _ParsedCoverLetterContent(
        senderLines: const <String>['[Your Name]'],
        recipientLines: const <String>[
          'Hiring Manager',
          '[Company Name]',
          '[Company Address]',
          '[City, State, Zip Code]',
        ],
        greeting: 'Dear Hiring Manager,',
        bodyParagraphs: <String>[normalized],
        closing: 'Sincerely,',
        signature: '[Your Name]',
      );
    }

    final senderLines = _nonEmptyLines(sections.first);
    final recipientLines = sections.length > 1
        ? _nonEmptyLines(sections[1])
        : const <String>[];
    final greeting = sections.length > 2 ? sections[2] : 'Dear Hiring Manager,';
    final closing = sections.length > 4
        ? sections[sections.length - 2]
        : 'Sincerely,';
    final signature = sections.length > 5
        ? sections.last
        : senderLines.isNotEmpty
        ? senderLines.first
        : '[Your Name]';
    final bodyStart = sections.length > 2 ? 3 : 0;
    final bodyEnd = sections.length > 4 ? sections.length - 2 : sections.length;
    final bodyParagraphs = sections
        .sublist(bodyStart, bodyEnd)
        .where((item) => item.trim().isNotEmpty)
        .toList();

    return _ParsedCoverLetterContent(
      senderLines: senderLines.isEmpty
          ? const <String>['[Your Name]']
          : senderLines,
      recipientLines: recipientLines.isEmpty
          ? const <String>[
              'Hiring Manager',
              '[Company Name]',
              '[Company Address]',
              '[City, State, Zip Code]',
            ]
          : recipientLines,
      greeting: greeting,
      bodyParagraphs: bodyParagraphs.isEmpty
          ? <String>[normalized]
          : bodyParagraphs,
      closing: closing,
      signature: signature,
    );
  }

  List<String> _nonEmptyLines(String section) {
    return section
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _displayName(ResumeData resume) =>
      resume.fullName.trim().isEmpty ? 'Your Name' : resume.fullName.trim();

  String _resumeInitials(ResumeData resume) {
    final words = _displayName(
      resume,
    ).split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
    if (words.isEmpty) {
      return 'DA';
    }
    return words.map((part) => part[0].toUpperCase()).join();
  }

  List<String> _resumeContactItems(ResumeData resume) {
    return [
      resume.location.trim(),
      resume.phone.trim(),
      resume.website.trim(),
      resume.githubLink.trim(),
      resume.linkedinLink.trim(),
    ].where((item) => item.isNotEmpty).toList();
  }

  List<String> _skillsForDisplay(ResumeData resume) {
    if (!resume.includeSkillsInResume) {
      return const [];
    }
    if (resume.skills.isNotEmpty) {
      return resume.skills;
    }
    return const <String>[];
  }

  pw.Widget _corporateSection({
    required String title,
    required PdfColor lineColor,
    required pw.Widget child,
    PdfColor? sectionTitleColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: _corporateHeadingText(
            title.toUpperCase(),
            color: sectionTitleColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: child,
        ),
        pw.SizedBox(height: 10),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(
            30,
            0,
            30,
            ResumeTypography.sectionGapPdfPt,
          ),
          child: pw.Container(height: 2, color: lineColor),
        ),
      ],
    );
  }

  pw.Widget _corporateHeadingText(String value, {PdfColor? color}) {
    final style = pw.TextStyle(
      fontSize: ResumeTypography.darkHeaderSectionTitlePt,
      fontWeight: pw.FontWeight.bold,
      color: color ?? PdfColor.fromHex('#50555C'),
    );
    return pw.Text(value, style: style);
  }

  List<pw.Widget> _twoColumnBulletRows(
    List<String> items, {
    double columnGap = 20,
    double itemBottom = 3,
    double fontSize = ResumeTypography.bodyPt,
  }) {
    final cleaned = items.where((item) => item.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) {
      return const <pw.Widget>[];
    }
    final leftCount = (cleaned.length / 2).ceil();
    return [
      for (var i = 0; i < leftCount; i++)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: itemBottom),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Bullet(
                  text: cleaned[i],
                  style: pw.TextStyle(
                    color: PdfColors.black,
                    fontSize: fontSize,
                  ),
                ),
              ),
              pw.SizedBox(width: columnGap),
              pw.Expanded(
                child: i + leftCount < cleaned.length
                    ? pw.Bullet(
                        text: cleaned[i + leftCount],
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontSize: fontSize,
                        ),
                      )
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),
    ];
  }

  pw.Widget _twoColumnBulletList(
    List<String> items, {
    double columnGap = 20,
    double itemBottom = 3,
    double fontSize = ResumeTypography.bodyPt,
  }) {
    final rows = _twoColumnBulletRows(
      items,
      columnGap: columnGap,
      itemBottom: itemBottom,
      fontSize: fontSize,
    );
    if (rows.isEmpty) {
      return pw.SizedBox();
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: rows,
    );
  }

  String _workSummaryText(WorkExperience item) {
    return '';
  }

  List<String> _workBulletLines(WorkExperience item) {
    final nonEmptyBullets = item.bullets
        .where((b) => b.trim().isNotEmpty)
        .toList();
    if (nonEmptyBullets.isNotEmpty) {
      return nonEmptyBullets;
    }
    final legacyDescription = item.description.trim();
    if (legacyDescription.isNotEmpty) {
      return [legacyDescription];
    }
    return const <String>[];
  }

  pw.Widget _corporateRoleCompanyText(String role, String company) {
    final style = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 15,
      color: PdfColors.black,
    );
    final value = '${role.ifEmpty('Role')} / ${company.ifEmpty('Company')}';
    return pw.Text(value, style: style);
  }

  pw.Widget _corporateStrokeLabelText(String value) {
    final style = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 15,
      color: PdfColors.black,
      lineSpacing: 0,
    );
    return pw.Text(value, style: style);
  }

  pw.Widget _buildHighlightedCorporateExperience(
    WorkExperience item,
    Set<String> highlightedBullets,
    PdfColor highlightColor, {
    double bodyFontPt = ResumeTypography.bodyPt,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: _corporateRoleCompanyText(item.role, item.company),
            ),
            if (item.startDate.trim().isNotEmpty ||
                item.endDate.trim().isNotEmpty)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${item.startDate.trim()}${item.startDate.trim().isNotEmpty && item.endDate.trim().isNotEmpty ? ' - ' : ''}${item.endDate.trim()}',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#666B71'),
                    fontStyle: pw.FontStyle.italic,
                    fontWeight: pw.FontWeight.normal,
                    font: pw.Font.helveticaOblique(),
                  ),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 4),
        if (_workSummaryText(item).isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(_workSummaryText(item)),
        ],
        ...(() {
          final bullets = _workBulletLines(item);
          return bullets.asMap().entries.map((entry) {
            final index = entry.key;
            final bullet = entry.value;
            return pw.Padding(
              padding: pw.EdgeInsets.only(top: index == 0 ? 0 : 4),
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                color: highlightedBullets.contains(bullet)
                    ? highlightColor
                    : PdfColors.white,
                child: pw.Bullet(
                  text: bullet,
                  style: pw.TextStyle(
                    color: PdfColors.black,
                    fontSize: bodyFontPt,
                  ),
                ),
              ),
            );
          });
        })(),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _highlightedAtsNoticeBar(PdfColor highlightColor) {
    return pw.Container(
      width: double.infinity,
      color: highlightColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: pw.Text(
        'Highlighted sections show AI ATS changes.',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#5B4A00'),
        ),
      ),
    );
  }

  pw.Widget _twoColumnBulletListWithHighlights(
    List<String> items,
    Set<String> highlightedSkills,
    PdfColor highlightColor, {
    double fontSize = ResumeTypography.bodyPt,
  }) {
    final cleaned = items.where((item) => item.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) {
      return pw.SizedBox();
    }
    final leftCount = (cleaned.length / 2).ceil();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < leftCount; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    color: highlightedSkills.contains(cleaned[i])
                        ? highlightColor
                        : PdfColors.white,
                    child: pw.Bullet(
                      text: cleaned[i],
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: i + leftCount < cleaned.length
                      ? pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          color:
                              highlightedSkills.contains(cleaned[i + leftCount])
                              ? highlightColor
                              : PdfColors.white,
                          child: pw.Bullet(
                            text: cleaned[i + leftCount],
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              fontSize: fontSize,
                            ),
                          ),
                        )
                      : pw.SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _buildHighlightedCreativeExperience(
    WorkExperience item,
    Set<String> highlightedBullets,
    PdfColor highlightColor, {
    double bodyFontPt = ResumeTypography.bodyPt,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyFontPt + 2,
                    ),
                    children: [
                      pw.TextSpan(
                        text: item.role.ifEmpty('Role').toUpperCase(),
                      ),
                      pw.TextSpan(
                        text: ' / ${item.company.ifEmpty('Company')}',
                      ),
                    ],
                  ),
                ),
              ),
              if (item.startDate.trim().isNotEmpty ||
                  item.endDate.trim().isNotEmpty)
                pw.Text(
                  '${item.startDate.trim()}${item.startDate.trim().isNotEmpty && item.endDate.trim().isNotEmpty ? ' - ' : ''}${item.endDate.trim()}',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#555B61'),
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
            ],
          ),
          if (_workSummaryText(item).isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(_workSummaryText(item)),
          ],
          for (final bullet in _workBulletLines(item))
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                color: highlightedBullets.contains(bullet)
                    ? highlightColor
                    : PdfColors.white,
                child: pw.Bullet(
                  text: bullet,
                  style: pw.TextStyle(
                    color: PdfColors.black,
                    fontSize: bodyFontPt,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCreativeExperience(
    WorkExperience item, {
    double bodyFontPt = ResumeTypography.bodyPt,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: bodyFontPt + 2,
                    ),
                    children: [
                      pw.TextSpan(
                        text: item.role.ifEmpty('Role').toUpperCase(),
                      ),
                      pw.TextSpan(
                        text: ' / ${item.company.ifEmpty('Company')}',
                      ),
                    ],
                  ),
                ),
              ),
              if (item.startDate.trim().isNotEmpty ||
                  item.endDate.trim().isNotEmpty)
                pw.Text(
                  '${item.startDate.trim()}${item.startDate.trim().isNotEmpty && item.endDate.trim().isNotEmpty ? ' - ' : ''}${item.endDate.trim()}',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#555B61'),
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
            ],
          ),
          if (_workSummaryText(item).isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(_workSummaryText(item)),
          ],
          for (final bullet in _workBulletLines(item))
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Bullet(
                text: bullet,
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: bodyFontPt,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCorporateEducation(
    EducationItem item, {
    double bodyFontPt = ResumeTypography.bodyPt,
  }) {
    // Same line as template card: `Institution  |  2014 - 2018`
    final titleLine = corporateEducationTitleLine(
      item.institution,
      item.startDate,
      item.endDate,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titleLine,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 15,
              color: PdfColors.black,
              lineSpacing: 0,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            item.degree.ifEmpty('Degree'),
            style: pw.TextStyle(fontSize: bodyFontPt),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactProject(
    ProjectItem item, {
    double bodyFontPt = ResumeTypography.bodyPt,
  }) {
    final bullets = _projectBulletLines(item);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _corporateStrokeLabelText(item.title.ifEmpty('Project')),
          for (var i = 0; i < bullets.length; i++)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: i == 0 ? 2 : 3),
              child: pw.Bullet(
                text: bullets[i],
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: bodyFontPt,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _projectBulletLines(ProjectItem item) {
    final nonEmptyBullets = item.bullets
        .where((b) => b.trim().isNotEmpty)
        .toList();
    if (nonEmptyBullets.isNotEmpty) {
      return nonEmptyBullets;
    }
    return [
      item.overview.trim(),
      item.impact.trim(),
    ].where((part) => part.isNotEmpty).toList();
  }

  Future<File> savePdfToDevice(ResumeData resume) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${directory.path}/exports');
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final safeName = _sanitizeFileName(
      resume.fullName.trim().isEmpty ? resume.title : resume.fullName,
    );
    final file = File(
      '${exportDirectory.path}/$safeName-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final bytes = await buildPdf(resume);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareResume(ResumeData resume) async {
    final file = await savePdfToDevice(resume);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${resume.title} resume',
      text: 'Shared from ResumeAI',
    );
  }

  Future<void> printResume(ResumeData resume) async {
    final bytes = await buildPdf(resume);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${_sanitizeFileName(resume.title)}.pdf',
      format: PdfPageFormat.a4,
    );
  }

  Future<File> saveCoverLetterPdfToDevice(CoverLetterData coverLetter) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${directory.path}/exports');
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final safeName = _sanitizeFileName(coverLetter.displayTitle);
    final file = File(
      '${exportDirectory.path}/$safeName-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final bytes = await buildCoverLetterPdf(coverLetter);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareCoverLetter(CoverLetterData coverLetter) async {
    final file = await saveCoverLetterPdfToDevice(coverLetter);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${coverLetter.displayTitle} cover letter',
      text: 'Shared from ResumeAI',
    );
  }

  Future<void> printCoverLetter(CoverLetterData coverLetter) async {
    final bytes = await buildCoverLetterPdf(coverLetter);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${_sanitizeFileName(coverLetter.displayTitle)}.pdf',
      format: PdfPageFormat.a4,
    );
  }

  String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .ifEmpty('resume');
  }
}

class _ParsedCoverLetterContent {
  const _ParsedCoverLetterContent({
    required this.senderLines,
    required this.recipientLines,
    required this.greeting,
    required this.bodyParagraphs,
    required this.closing,
    required this.signature,
  });

  final List<String> senderLines;
  final List<String> recipientLines;
  final String greeting;
  final List<String> bodyParagraphs;
  final String closing;
  final String signature;

  String get senderName =>
      senderLines.isEmpty ? '[Your Name]' : senderLines.first;

  List<String> get senderDetails =>
      senderLines.length <= 1 ? const <String>[] : senderLines.sublist(1);

  String get senderInitial {
    final normalized = senderName.trim();
    return normalized.isEmpty ? 'A' : normalized.substring(0, 1).toUpperCase();
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
