import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/ai/ai_assistance_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeAnalyserRepository implements ResumeRepository {
  _FakeAnalyserRepository({required this.resumes});

  final List<ResumeData> resumes;

  @override
  void configureGoogleDriveAutoSync({
    required AppPreferences appPreferences,
    required GoogleDriveResumeService service,
  }) {}

  @override
  void configureICloudAutoSync({
    required AppPreferences appPreferences,
    required ICloudResumeService service,
  }) {}

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
  Future<void> upsertCoverLetter(
    CoverLetterData coverLetter, {
    bool scheduleAutoSync = true,
  }) async {}

  @override
  Future<void> upsertResume(
    ResumeData resume, {
    bool scheduleAutoSync = true,
  }) async {
    resumes.removeWhere((item) => item.id == resume.id);
    resumes.add(resume);
  }
}

Finder _fieldByLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
    description: 'TextField with label $label',
  );
}

void main() {
  testWidgets(
    'resume analyser shows a no-resume nudge and routes to home when tapped',
    (tester) async {
      final repository = _FakeAnalyserRepository(resumes: []);
      final library = ResumeLibraryViewModel(repository: repository);
      await library.loadResumes();

      var wentHome = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ResumeRepository>.value(value: repository),
            Provider<LocalAiResumeService>.value(value: LocalAiResumeService()),
            Provider<ResumePdfService>.value(value: ResumePdfService()),
            ChangeNotifierProvider<ResumeLibraryViewModel>.value(
              value: library,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ResumeAnalyserScreen(
                onOpenResumeBuilder: () {},
                onGoToHomeTab: () => wentHome = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No resume available right now.'), findsOneWidget);
      expect(
        find.byKey(const Key('optimize-empty-go-home-button')),
        findsOneWidget,
      );
      expect(find.text('Create a resume'), findsNothing);
      expect(find.text('Go to Home'), findsNothing);

      await tester.tap(find.byKey(const Key('optimize-empty-go-home-button')));
      await tester.pumpAndSettle();

      expect(wentHome, isTrue);
    },
  );

  testWidgets(
    'resume analyser opens preview, asks for a title on new copy, and clears the optimize screen on return',
    (tester) async {
      final untouchedResume =
          ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
            id: 'resume-1',
            title: 'Product Resume',
            jobTitle: 'Product Designer',
            summary:
                'Designs mobile flows and prototypes for consumer products.',
            skills: const ['Figma', 'Wireframing'],
            updatedAt: DateTime(2026, 1, 1),
          );
      final selectedResume =
          ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
            id: 'resume-2',
            title: 'Mobile Resume',
            jobTitle: 'Flutter Developer',
            summary: 'Builds Flutter apps for Android and iOS.',
            skills: const ['Flutter', 'Dart'],
            workExperiences: const [
              WorkExperience(
                role: 'Flutter Developer',
                company: 'Acme',
                startDate: 'Jan 2024',
                endDate: 'Present',
                description: 'Builds mobile features.',
                bullets: ['Maintained Flutter modules.'],
              ),
            ],
            updatedAt: DateTime(2026, 1, 2),
          );

      final repository = _FakeAnalyserRepository(
        resumes: [untouchedResume, selectedResume],
      );
      final library = ResumeLibraryViewModel(repository: repository);
      await library.loadResumes();
      library.selectResume(selectedResume.id);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
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

      expect(find.byKey(const Key('tailor-resume-selector')), findsOneWidget);
      expect(find.byKey(const Key('tailor-resume-ai-button')), findsOneWidget);
      expect(find.byKey(const Key('upload-resume-button')), findsNothing);

      await tester.enterText(
        _fieldByLabel('Job description'),
        'Hiring a Flutter mobile engineer with REST APIs, Firebase, analytics, and stakeholder communication experience.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tailor-resume-ai-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final unchangedSelectedResume = repository.resumes.singleWhere(
        (item) => item.id == selectedResume.id,
      );
      final unchangedUntouchedResume = repository.resumes.singleWhere(
        (item) => item.id == untouchedResume.id,
      );

      expect(unchangedSelectedResume.updatedAt, selectedResume.updatedAt);
      expect(unchangedUntouchedResume.updatedAt, untouchedResume.updatedAt);
      expect(find.text('Applied changes'), findsOneWidget);
      expect(
        find.byKey(const Key('show-optimized-resume-button')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('show-optimized-resume-button')),
      );
      await tester.tap(find.byKey(const Key('show-optimized-resume-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('save-optimized-resume-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('save-optimized-resume-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('save-optimized-new-copy-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('save-optimized-new-copy-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('optimized-resume-title-dialog-field')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('optimized-resume-title-dialog-field')),
        'Mobile Resume ATS Copy',
      );
      await tester.tap(
        find.byKey(const Key('optimized-resume-title-dialog-save-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 300));

      final savedSelectedResume = repository.resumes.singleWhere(
        (item) => item.id == selectedResume.id,
      );
      final savedUntouchedResume = repository.resumes.singleWhere(
        (item) => item.id == untouchedResume.id,
      );
      final savedCopy = repository.resumes.singleWhere(
        (item) => item.title == 'Mobile Resume ATS Copy',
      );

      expect(savedSelectedResume.updatedAt, selectedResume.updatedAt);
      expect(savedUntouchedResume.updatedAt, untouchedResume.updatedAt);
      expect(savedCopy.id, isNot(selectedResume.id));
      expect(savedCopy.skills, isNotEmpty);
      expect(savedCopy.summary, isNot(equals(selectedResume.summary)));
      expect(savedCopy.workExperiences.first.bullets, isNotEmpty);
      expect(
        savedCopy.workExperiences.first.bullets.join(' '),
        anyOf(
          contains('Firebase'),
          contains('REST APIs'),
          contains('analytics'),
        ),
      );
      expect(find.text('Applied changes'), findsNothing);
      expect(
        find.byKey(const Key('show-optimized-resume-button')),
        findsNothing,
      );
      final jobDescriptionField = tester.widget<TextField>(
        _fieldByLabel('Job description'),
      );
      expect(jobDescriptionField.controller?.text ?? '', isEmpty);
    },
  );
}
