import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/shell/app_shell.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeAppShellRepository implements ResumeRepository {
  final List<ResumeData> resumes = [];
  final List<CoverLetterData> coverLetters = [];

  @override
  Future<void> deleteCoverLetter(String id) async {
    coverLetters.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteResume(String id) async {
    resumes.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => coverLetters;

  @override
  Future<List<ResumeData>> loadResumes() async => resumes;

  @override
  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {
    coverLetters.removeWhere((item) => item.id == coverLetter.id);
    coverLetters.add(coverLetter);
  }

  @override
  Future<void> upsertResume(ResumeData resume) async {
    resumes.removeWhere((item) => item.id == resume.id);
    resumes.add(resume);
  }
}

void main() {
  testWidgets(
    'resume add button prompts for title before opening the builder',
    (tester) async {
      final repository = _FakeAppShellRepository();
      final resumeLibrary = ResumeLibraryViewModel(repository: repository);
      final coverLetterLibrary = CoverLetterLibraryViewModel(
        repository: repository,
      );

      await resumeLibrary.loadResumes();
      await coverLetterLibrary.loadCoverLetters();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ResumeImportService>.value(value: ResumeImportService()),
            Provider<ResumeRepository>.value(value: repository),
            Provider<AppPreferences>.value(value: AppPreferences.inMemory()),
            Provider<LocalAiResumeService>.value(value: LocalAiResumeService()),
            Provider<ResumePdfService>.value(value: ResumePdfService()),
            ChangeNotifierProvider<ResumeLibraryViewModel>.value(
              value: resumeLibrary,
            ),
            ChangeNotifierProvider<CoverLetterLibraryViewModel>.value(
              value: coverLetterLibrary,
            ),
            ChangeNotifierProvider<SettingsViewModel>(
              create: (_) => SettingsViewModel(),
            ),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Resume title'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('resume-title-dialog-field')),
        'Product Designer Resume',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Product Designer Resume'), findsOneWidget);
      expect(find.text('Resume title'), findsNothing);
    },
  );

  testWidgets(
    'cover letter add button prompts for title before opening the editor',
    (tester) async {
      final repository = _FakeAppShellRepository();
      final resumeLibrary = ResumeLibraryViewModel(repository: repository);
      final coverLetterLibrary = CoverLetterLibraryViewModel(
        repository: repository,
      );

      await resumeLibrary.loadResumes();
      await coverLetterLibrary.loadCoverLetters();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ResumeImportService>.value(value: ResumeImportService()),
            Provider<ResumeRepository>.value(value: repository),
            Provider<AppPreferences>.value(value: AppPreferences.inMemory()),
            Provider<LocalAiResumeService>.value(value: LocalAiResumeService()),
            Provider<ResumePdfService>.value(value: ResumePdfService()),
            ChangeNotifierProvider<ResumeLibraryViewModel>.value(
              value: resumeLibrary,
            ),
            ChangeNotifierProvider<CoverLetterLibraryViewModel>.value(
              value: coverLetterLibrary,
            ),
            ChangeNotifierProvider<SettingsViewModel>(
              create: (_) => SettingsViewModel(),
            ),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cover Letter').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Cover letter title'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('cover-letter-title-dialog-field')),
        'Retail Sales Application',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Retail Sales Application'), findsOneWidget);
      expect(find.text('Cover letter title'), findsNothing);
    },
  );
}
