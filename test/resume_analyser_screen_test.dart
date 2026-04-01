import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/ai/ai_assistance_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeAnalyserRepository implements ResumeRepository {
  _FakeAnalyserRepository({required this.resumes});

  final List<ResumeData> resumes;

  @override
  Future<void> deleteCoverLetter(String id) async {}

  @override
  Future<void> deleteResume(String id) async {
    resumes.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => const [];

  @override
  Future<List<ResumeData>> loadResumes() async => resumes;

  @override
  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {}

  @override
  Future<void> upsertResume(ResumeData resume) async {
    resumes.removeWhere((item) => item.id == resume.id);
    resumes.add(resume);
  }
}

class _FakeResumeImportService extends ResumeImportService {
  const _FakeResumeImportService({this.file});

  final ImportedResumeFile? file;

  @override
  Future<ImportedResumeFile?> pickResumeFile() async => file;
}

Finder _fieldByLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
    description: 'TextField with label $label',
  );
}

void main() {
  testWidgets(
    'resume analyser uploads a resume and improves it against a job description',
    (tester) async {
      const importedResume = ImportedResumeFile(
        fileName: 'diya-retail-resume.pdf',
        resumeText: '''
DIYA AGARWAL
Retail Sales Associate
d.agarwal@example.com | +91 9876543210 | New Delhi, India

SUMMARY
Customer-focused retail sales professional with solid understanding of retail dynamics, marketing, and customer service.

SKILLS
Cash register operation, Inventory management, POS system operation, Retail merchandising expertise

EXPERIENCE
Retail Sales Associate | ZARA
- Increased monthly sales 10% by effectively upselling and cross-selling products.
- Prevented store losses by identifying and investigating concerns.

EDUCATION
Diploma in Financial Accounting
Oxford Software Institute
2016
''',
      );
      final repository = _FakeAnalyserRepository(resumes: []);
      final library = ResumeLibraryViewModel(repository: repository);
      await library.loadResumes();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ResumeImportService>.value(
              value: _FakeResumeImportService(file: importedResume),
            ),
            Provider<ResumeRepository>.value(value: repository),
            Provider<LocalAiResumeService>.value(value: LocalAiResumeService()),
            Provider<ResumePdfService>.value(value: ResumePdfService()),
            ChangeNotifierProvider<ResumeLibraryViewModel>.value(
              value: library,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ResumeAnalyserScreen(onOpenResumeBuilder: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resume analyser'), findsOneWidget);
      expect(find.byKey(const Key('upload-resume-button')), findsOneWidget);
      expect(find.byKey(const Key('improve-resume-ai-button')), findsOneWidget);
      expect(find.text('ATS scan'), findsNothing);

      await tester.tap(find.byKey(const Key('upload-resume-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        _fieldByLabel('Job description'),
        'Hiring a Flutter mobile engineer with REST APIs, Firebase, analytics, and stakeholder communication experience.',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('improve-resume-ai-button')),
      );
      await tester.tap(find.byKey(const Key('improve-resume-ai-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final savedResume = repository.resumes.single;
      expect(savedResume.summary.trim(), isNotEmpty);
      expect(savedResume.skills, isNotEmpty);
      expect(savedResume.workExperiences.first.bullets, isNotEmpty);
      expect(find.text('Applied changes'), findsOneWidget);
      expect(find.text('Improved resume PDF'), findsOneWidget);
    },
  );
}
