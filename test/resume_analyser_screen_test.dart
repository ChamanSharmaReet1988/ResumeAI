import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/app_localizations.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/ai_api_key_store.dart';
import 'package:resume_app/core/services/ai_resume_coordinator.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/premium_purchase_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/ai/ai_assistance_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

List<SingleChildWidget> _analyserProviders({
  required ResumeRepository repository,
  required ResumeLibraryViewModel library,
  bool isPremium = true,
}) {
  final localAi = LocalAiResumeService();
  final keyStore = AiApiKeyStore.inMemory();
  final appPreferences = AppPreferences.inMemory(isPremium: isPremium);
  return <SingleChildWidget>[
    Provider<ResumeRepository>.value(value: repository),
    Provider<LocalAiResumeService>.value(value: localAi),
    ChangeNotifierProvider<AiApiKeyStore>.value(value: keyStore),
    Provider<AiResumeCoordinator>(
      create: (_) => AiResumeCoordinator(
        apiKeyStore: keyStore,
        localAi: localAi,
      ),
    ),
    Provider<ResumePdfService>.value(value: ResumePdfService()),
    ChangeNotifierProvider<ResumeLibraryViewModel>.value(value: library),
    ChangeNotifierProvider<PremiumPurchaseService>(
      create: (_) => PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
        isPremium: isPremium,
      ),
    ),
  ];
}

class _FakeAnalyserRepository implements ResumeRepository {
  _FakeAnalyserRepository({required this.resumes});

  final List<ResumeData> resumes;

  @override
  void configureGoogleDriveAutoSync({
    required AppPreferences appPreferences,
    required GoogleDriveResumeService service,
    bool Function()? hasPremium,
  }) {}

  @override
  void configureICloudAutoSync({
    required AppPreferences appPreferences,
    required ICloudResumeService service,
    bool Function()? hasPremium,
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
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeAnalyserRepository(resumes: []);
      final library = ResumeLibraryViewModel(repository: repository);
      await library.loadResumes();

      var wentHome = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: _analyserProviders(
            repository: repository,
            library: library,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
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

      expect(
        tester
            .getSize(find.byKey(const Key('optimize-empty-go-home-button')))
            .width,
        tester.getSize(find.byType(TextField)).width,
      );

      await tester.tap(find.byKey(const Key('optimize-empty-go-home-button')));
      await tester.pumpAndSettle();

      expect(wentHome, isTrue);
    },
  );

  testWidgets(
    'AI screen creates an ATS resume copy from a selected resume',
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
          providers: _analyserProviders(
            repository: repository,
            library: library,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ResumeAnalyserScreen(onOpenResumeBuilder: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tailor-resume-selector')), findsOneWidget);
      expect(
        find.byKey(const Key('create-ats-resume-ai-button')),
        findsOneWidget,
      );
      expect(find.text('Optimize'), findsNothing);
      expect(find.text('Create ATS'), findsNothing);
      expect(find.byKey(const Key('upload-resume-button')), findsNothing);

      await tester.enterText(
        _fieldByLabel('Job description (optional)'),
        'Hiring a Flutter mobile engineer with REST APIs, Firebase, analytics, and stakeholder communication experience.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-ats-resume-ai-button')));
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
        find.byKey(const Key('show-created-ats-resume-button')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('show-created-ats-resume-button')),
      );
      await tester.tap(find.byKey(const Key('show-created-ats-resume-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('save-optimized-resume-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('save-optimized-resume-button')));
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
      expect(savedCopy.template, ResumeTemplate.atsLatexClassic);
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
        find.byKey(const Key('show-created-ats-resume-button')),
        findsNothing,
      );
      final jobDescriptionField = tester.widget<TextField>(
        _fieldByLabel('Job description (optional)'),
      );
      expect(jobDescriptionField.controller?.text ?? '', isEmpty);
    },
  );
}
