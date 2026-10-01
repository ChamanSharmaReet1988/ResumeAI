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
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/ai/ai_assistance_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeResumeImportService extends ResumeImportService {
  const _FakeResumeImportService(this.file);

  final ImportedResumeFile? file;

  @override
  Future<ImportedResumeFile?> pickResumeFile({
    Future<void> Function()? onFilePicked,
  }) async => file;
}

List<SingleChildWidget> _analyserProviders({
  required ResumeRepository repository,
  required ResumeLibraryViewModel library,
  bool isPremium = true,
  ResumeImportService? importService,
}) {
  final localAi = LocalAiResumeService();
  final keyStore = AiApiKeyStore.inMemory();
  final appPreferences = AppPreferences.inMemory(isPremium: isPremium);
  return <SingleChildWidget>[
    Provider<ResumeRepository>.value(value: repository),
    Provider<LocalAiResumeService>.value(value: localAi),
    Provider<ResumeImportService>.value(
      value: importService ?? const ResumeImportService(),
    ),
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
    'AI Resume tab shows Check ATS and Enhance Resume like Home/Templates',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeAnalyserRepository(resumes: []);
      final library = ResumeLibraryViewModel(repository: repository);
      await library.loadResumes();

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

      expect(find.byKey(const Key('ai-resume-segmented-button')), findsOneWidget);
      expect(find.text('Check ATS'), findsWidgets);
      expect(find.text('Enhance Resume'), findsOneWidget);
      expect(find.byKey(const Key('ai-resume-upload-button')), findsOneWidget);
      expect(find.byKey(const Key('check-ats-button')), findsOneWidget);
      expect(find.byKey(const Key('create-ats-resume-ai-button')), findsNothing);
      expect(_fieldByLabel('Job description (optional)'), findsNothing);
      expect(find.text('Create a resume'), findsNothing);
      expect(find.text('Go to Home'), findsNothing);

      await tester.tap(find.text('Enhance Resume'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create-ats-resume-ai-button')), findsOneWidget);
      expect(find.text('Optimize'), findsOneWidget);
      expect(_fieldByLabel('Job description (optional)'), findsOneWidget);
      expect(find.byKey(const Key('check-ats-button')), findsNothing);
      expect(find.byKey(const Key('ai-library-resume-selector')), findsNothing);
      expect(find.byKey(const Key('ai-resume-or-divider')), findsNothing);
      expect(find.text('Select from app resume list'), findsNothing);
    },
  );

  testWidgets(
    'Check ATS uploads a resume and shows an ATS score',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeAnalyserRepository(resumes: []);
      final library = ResumeLibraryViewModel(repository: repository);
      await library.loadResumes();
      const importService = _FakeResumeImportService(
        ImportedResumeFile(
          fileName: 'jane-doe.pdf',
          resumeText: '''
Jane Doe
jane@example.com
+1 555 123 4567

Summary
Flutter developer building mobile apps.

Experience
Flutter Developer, Acme
- Shipped Android and iOS features that improved delivery speed by 20%.

Education
B.S. Computer Science

Skills
Flutter, Dart, Firebase
''',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _analyserProviders(
            repository: repository,
            library: library,
            importService: importService,
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

      await tester.tap(find.byKey(const Key('ai-resume-upload-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Using jane-doe.pdf'), findsOneWidget);
      final usingFileStyle = tester
          .widget<Text>(find.byKey(const Key('ai-resume-using-file-label')))
          .style;
      expect(usingFileStyle?.fontWeight, FontWeight.w400);
      expect(usingFileStyle?.fontSize, 12);
      expect(find.byKey(const Key('ats-check-results-card')), findsOneWidget);
      expect(find.text('ATS results'), findsOneWidget);
      expect(find.text('Resume score'), findsOneWidget);
    },
  );

  testWidgets(
    'Enhance Resume uploads a resume then shows ATS preview on Show Resume',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      final repository = _FakeAnalyserRepository(resumes: [untouchedResume]);
      final library = ResumeLibraryViewModel(repository: repository);
      await library.loadResumes();
      const importService = _FakeResumeImportService(
        ImportedResumeFile(
          fileName: 'mobile-resume.pdf',
          resumeText: '''
Alex Rivera
Flutter Developer
alex@example.com

Summary
Builds Flutter apps for Android and iOS.

Experience
Flutter Developer, Acme, Jan 2024 - Present
- Maintained Flutter modules.

Skills
Flutter, Dart
''',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _analyserProviders(
            repository: repository,
            library: library,
            importService: importService,
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

      expect(find.byKey(const Key('ai-library-resume-selector')), findsOneWidget);
      expect(find.byKey(const Key('ai-resume-or-divider')), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Select from app resume list'), findsWidgets);

      await tester.tap(find.text('Enhance Resume'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-library-resume-selector')), findsOneWidget);
      expect(find.byKey(const Key('ai-resume-or-divider')), findsOneWidget);
      expect(
        find.byKey(const Key('create-ats-resume-ai-button')),
        findsOneWidget,
      );
      expect(find.text('Optimize'), findsOneWidget);
      expect(find.text('Create ATS'), findsNothing);
      expect(find.byKey(const Key('ai-resume-upload-button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('ai-resume-upload-button')));
      await tester.pumpAndSettle();

      expect(find.text('Using mobile-resume.pdf'), findsOneWidget);
      final usingFileStyle = tester
          .widget<Text>(find.byKey(const Key('ai-resume-using-file-label')))
          .style;
      expect(usingFileStyle?.fontWeight, FontWeight.w400);
      expect(usingFileStyle?.fontSize, 12);

      await tester.enterText(
        _fieldByLabel('Job description (optional)'),
        'Hiring a Flutter mobile engineer with REST APIs, Firebase, analytics, and stakeholder communication experience.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-ats-resume-ai-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(untouchedResume.updatedAt, DateTime(2026, 1, 1));
      expect(find.text('Applied changes'), findsOneWidget);
      expect(
        find.byKey(const Key('show-created-ats-resume-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('created-ats-resume-preview')),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(const Key('show-created-ats-resume-button')),
      );
      await tester.tap(find.byKey(const Key('show-created-ats-resume-button')));
      await tester.pumpAndSettle();

      expect(find.text('Resume preview'), findsOneWidget);
      expect(
        find.byKey(const Key('created-ats-resume-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('show-created-ats-resume-button')),
        findsNothing,
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

      final savedUntouchedResume = repository.resumes.singleWhere(
        (item) => item.id == untouchedResume.id,
      );
      final savedCopy = repository.resumes.singleWhere(
        (item) => item.title == 'Mobile Resume ATS Copy',
      );

      expect(savedUntouchedResume.updatedAt, untouchedResume.updatedAt);
      expect(savedCopy.template, ResumeTemplate.atsLatexClassic);
      expect(savedCopy.skills, isNotEmpty);
      expect(savedCopy.workExperiences, isNotEmpty);
      final savedBullets = savedCopy.workExperiences.first.bullets.join(' ');
      expect(savedBullets, contains('Maintained Flutter modules.'));
      expect(savedBullets, isNot(contains('Firebase')));
      expect(savedCopy.skills, isNot(contains('Firebase')));
      expect(find.text('Applied changes'), findsNothing);
      expect(
        find.byKey(const Key('created-ats-resume-preview')),
        findsNothing,
      );
      final jobDescriptionField = tester.widget<TextField>(
        _fieldByLabel('Job description (optional)'),
      );
      expect(jobDescriptionField.controller?.text ?? '', isEmpty);
    },
  );

  testWidgets(
    'upload and app resume list clear each other',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final savedResume =
          ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
            id: 'resume-1',
            title: 'Product Resume',
            jobTitle: 'Product Designer',
            summary: 'Designs mobile flows for consumer products.',
            skills: const ['Figma', 'Wireframing'],
            workExperiences: const [
              WorkExperience(
                role: 'Product Designer',
                company: 'Studio',
                startDate: '2023',
                endDate: 'Present',
                description: 'Designs product flows.',
                bullets: ['Shipped onboarding screens.'],
              ),
            ],
            updatedAt: DateTime(2026, 1, 1),
          );
      final repository = _FakeAnalyserRepository(resumes: [savedResume]);
      final library = ResumeLibraryViewModel(repository: repository);
      await library.loadResumes();
      const importService = _FakeResumeImportService(
        ImportedResumeFile(
          fileName: 'jane-doe.pdf',
          resumeText: '''
Jane Doe
jane@example.com

Summary
Flutter developer.

Experience
Developer, Acme
- Built apps.

Skills
Flutter, Dart
''',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _analyserProviders(
            repository: repository,
            library: library,
            importService: importService,
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

      await tester.tap(find.byKey(const Key('ai-library-resume-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product Resume').last);
      await tester.pumpAndSettle();

      expect(find.text('Using jane-doe.pdf'), findsNothing);
      expect(find.text('Product Resume'), findsWidgets);

      await tester.tap(find.byKey(const Key('ai-resume-upload-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Using jane-doe.pdf'), findsOneWidget);
      expect(find.text('Product Resume'), findsNothing);
    },
  );
}
