import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/app_localizations.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/ai_api_key_store.dart';
import 'package:resume_app/core/services/ai_resume_coordinator.dart';
import 'package:resume_app/core/services/android_genai_service.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/deep_link_service.dart';
import 'package:resume_app/core/services/firebase_app_services.dart';
import 'package:resume_app/core/services/premium_purchase_service.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/in_app_review_prompt_service.dart';
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/shell/app_shell.dart';
import 'package:resume_app/features/shared/view_models.dart';

List<SingleChildWidget> _appShellProviders({
  required ResumeRepository repository,
  required ResumeLibraryViewModel resumeLibrary,
  required CoverLetterLibraryViewModel coverLetterLibrary,
  required AppPreferences appPreferences,
  required PremiumPurchaseService premiumPurchaseService,
  ResumeImportService? importService,
  FirebaseAppServices? firebase,
}) {
  final localAi = LocalAiResumeService();
  final keyStore = AiApiKeyStore.inMemory();
  return [
    if (firebase != null) Provider<FirebaseAppServices>.value(value: firebase),
    Provider<ResumeImportService>.value(
      value: importService ?? ResumeImportService(),
    ),
    Provider<ResumeRepository>.value(value: repository),
    Provider<AppPreferences>.value(value: appPreferences),
    Provider<DeepLinkService>.value(
      value: DeepLinkService(enablePlatformLinks: false),
    ),
    ChangeNotifierProvider<PremiumPurchaseService>.value(
      value: premiumPurchaseService,
    ),
    Provider<LocalAiResumeService>.value(value: localAi),
    Provider<AndroidGenAiService>(create: (_) => AndroidGenAiService()),
    ChangeNotifierProvider<AiApiKeyStore>.value(value: keyStore),
    Provider<AiResumeCoordinator>(
      create: (_) => AiResumeCoordinator(
        apiKeyStore: keyStore,
        localAi: localAi,
      ),
    ),
    Provider<InAppReviewPromptService>.value(
      value: InAppReviewPromptService(
        readRatingCompleted: () async => true,
        writeRatingCompleted: () async {},
        readHasShared: () async => false,
        writeHasShared: () async {},
        openStoreListing: () async {},
        readHomeVisitCount: () async => 0,
        writeHomeVisitCount: (_) async {},
      ),
    ),
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
  ];
}

class _FakeAppShellRepository implements ResumeRepository {
  final List<ResumeData> resumes = [];
  final List<CoverLetterData> coverLetters = [];

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
  Future<void> upsertCoverLetter(
    CoverLetterData coverLetter, {
    bool scheduleAutoSync = true,
  }) async {
    coverLetters.removeWhere((item) => item.id == coverLetter.id);
    coverLetters.add(coverLetter);
  }

  @override
  Future<void> upsertResume(
    ResumeData resume, {
    bool scheduleAutoSync = true,
  }) async {
    resumes.removeWhere((item) => item.id == resume.id);
    resumes.add(resume);
  }
}

/// Records the analytics events the app logs, instead of sending them.
class _RecordingFirebaseServices implements FirebaseAppServices {
  final List<String> events = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(name);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the file picker. Calls the picked-file hook like the real
/// one, then holds until [finish] so a test can look at the screen mid-import.
class _PausedImportService extends ResumeImportService {
  final Completer<void> _release = Completer<void>();

  void finish() => _release.complete();

  @override
  Future<ImportedResumeFile?> pickResumeFile({
    Future<void> Function()? onFilePicked,
  }) async {
    await onFilePicked?.call();
    await _release.future;
    return const ImportedResumeFile(
      fileName: 'Priya Raman.pdf',
      resumeText: 'Priya Raman\nMarketing Manager\npriya@email.com',
    );
  }

  // Real isolates do not complete under the widget tester's fake clock, so
  // parse in place here; the isolate path has its own test.
  @override
  Future<ResumeData> parseInBackground(
    ImportedResumeFile file, {
    required ResumeTemplate template,
  }) async => LocalAiResumeService().parseImportedResumeText(
    resumeText: file.resumeText,
    candidateResumeTexts: file.candidateResumeTexts,
    template: template,
    sourceTitle: file.suggestedTitle,
  );
}

void _ignoreRenderOverflowErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) {
      return;
    }
    originalOnError?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = originalOnError;
  });
}

void main() {
  testWidgets(
    'tablet shell shows navigation rail destination icons',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repository = _FakeAppShellRepository();
      final resumeLibrary = ResumeLibraryViewModel(repository: repository);
      final coverLetterLibrary = CoverLetterLibraryViewModel(
        repository: repository,
      );
      await resumeLibrary.loadResumes();
      await coverLetterLibrary.loadCoverLetters();

      final appPreferences = AppPreferences.inMemory();
      final premiumPurchaseService = PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _appShellProviders(
            repository: repository,
            resumeLibrary: resumeLibrary,
            coverLetterLibrary: coverLetterLibrary,
            appPreferences: appPreferences,
            premiumPurchaseService: premiumPurchaseService,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      final icons = tester.widgetList<Icon>(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.byType(Icon),
        ),
      );
      expect(icons, isNotEmpty);
      for (final icon in icons) {
        expect(icon.size ?? 24, greaterThan(0));
        expect(icon.icon, isNotNull);
      }
    },
  );

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

      final appPreferences = AppPreferences.inMemory();
      final premiumPurchaseService = PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _appShellProviders(
            repository: repository,
            resumeLibrary: resumeLibrary,
            coverLetterLibrary: coverLetterLibrary,
            appPreferences: appPreferences,
            premiumPurchaseService: premiumPurchaseService,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-create-new-button')));
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

      final appPreferences = AppPreferences.inMemory();
      final premiumPurchaseService = PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _appShellProviders(
            repository: repository,
            resumeLibrary: resumeLibrary,
            coverLetterLibrary: coverLetterLibrary,
            appPreferences: appPreferences,
            premiumPurchaseService: premiumPurchaseService,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cover Letter').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-create-new-button')));
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

  testWidgets(
    'template use flow returns to home when builder is dismissed',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _ignoreRenderOverflowErrors();

      final repository = _FakeAppShellRepository();
      final resumeLibrary = ResumeLibraryViewModel(repository: repository);
      final coverLetterLibrary = CoverLetterLibraryViewModel(
        repository: repository,
      );

      await resumeLibrary.loadResumes();
      await coverLetterLibrary.loadCoverLetters();

      final appPreferences = AppPreferences.inMemory(isPremium: true);
      final premiumPurchaseService = PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
        isPremium: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _appShellProviders(
            repository: repository,
            resumeLibrary: resumeLibrary,
            coverLetterLibrary: coverLetterLibrary,
            appPreferences: appPreferences,
            premiumPurchaseService: premiumPurchaseService,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-create-new-button')), findsNothing);

      final templateTile = find.byKey(
        const Key('template-tile-profile-sidebar'),
      );
      await tester.ensureVisible(templateTile);
      await tester.tap(templateTile);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('use-template-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('resume-step-pages')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('resume-step-pages')), findsNothing);
      expect(find.byKey(const Key('home-create-new-button')), findsOneWidget);
      expect(find.text('Use template'), findsNothing);
    },
  );

  testWidgets(
    'template use flow returns to the editor when preview is dismissed',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _ignoreRenderOverflowErrors();

      final repository = _FakeAppShellRepository();
      final resumeLibrary = ResumeLibraryViewModel(repository: repository);
      final coverLetterLibrary = CoverLetterLibraryViewModel(
        repository: repository,
      );

      await resumeLibrary.loadResumes();
      await coverLetterLibrary.loadCoverLetters();

      final appPreferences = AppPreferences.inMemory(isPremium: true);
      final premiumPurchaseService = PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
        isPremium: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _appShellProviders(
            repository: repository,
            resumeLibrary: resumeLibrary,
            coverLetterLibrary: coverLetterLibrary,
            appPreferences: appPreferences,
            premiumPurchaseService: premiumPurchaseService,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle();

      final templateTile = find.byKey(
        const Key('template-tile-profile-sidebar'),
      );
      await tester.ensureVisible(templateTile);
      await tester.tap(templateTile);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('use-template-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('resume-pdf-preview')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('resume-pdf-preview')), findsNothing);
      // Back from the preview stays in the editor rather than closing it.
      expect(find.text('Preview'), findsOneWidget);
      expect(find.byKey(const Key('home-create-new-button')), findsNothing);
    },
  );

  testWidgets(
    'new cover letter flow returns to home when preview is dismissed',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _ignoreRenderOverflowErrors();

      final repository = _FakeAppShellRepository();
      final resumeLibrary = ResumeLibraryViewModel(repository: repository);
      final coverLetterLibrary = CoverLetterLibraryViewModel(
        repository: repository,
      );

      await resumeLibrary.loadResumes();
      await coverLetterLibrary.loadCoverLetters();

      final appPreferences = AppPreferences.inMemory(isPremium: true);
      final premiumPurchaseService = PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
        isPremium: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _appShellProviders(
            repository: repository,
            resumeLibrary: resumeLibrary,
            coverLetterLibrary: coverLetterLibrary,
            appPreferences: appPreferences,
            premiumPurchaseService: premiumPurchaseService,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cover Letter').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-create-new-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('cover-letter-title-dialog-field')),
        'Retail Sales Application',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Company name',
        ),
        'Acme Labs',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Job position name',
        ),
        'Senior Product Designer',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Skill to highlight',
        ),
        'UX research',
      );
      await tester.tap(find.byKey(const Key('cover-letter-skill-add-button')));
      await tester.pumpAndSettle();

      final languageDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('cover-letter-language-dropdown')),
      );
      languageDropdown.onChanged?.call('English (English)');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create cover letter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('preview-cover-letter-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cover-letter-preview-screen')),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cover-letter-preview-screen')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('preview-cover-letter-button')),
        findsNothing,
      );
      expect(find.text('Create cover letter'), findsNothing);
      expect(find.byKey(const Key('home-create-new-button')), findsOneWidget);
    },
  );

  testWidgets(
    'edit cover letter flow returns to home when preview is dismissed',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _ignoreRenderOverflowErrors();

      final repository = _FakeAppShellRepository();
      final existingCoverLetter = CoverLetterData.empty().copyWith(
        id: 'cover-existing',
        title: 'Retail Sales Application',
        company: 'Zara',
        role: 'Retail Sales Associate',
        content: 'Generated cover letter content for preview.',
      );
      repository.coverLetters.add(existingCoverLetter);

      final resumeLibrary = ResumeLibraryViewModel(repository: repository);
      final coverLetterLibrary = CoverLetterLibraryViewModel(
        repository: repository,
      );

      await resumeLibrary.loadResumes();
      await coverLetterLibrary.loadCoverLetters();

      final appPreferences = AppPreferences.inMemory(isPremium: true);
      final premiumPurchaseService = PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
        isPremium: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: _appShellProviders(
            repository: repository,
            resumeLibrary: resumeLibrary,
            coverLetterLibrary: coverLetterLibrary,
            appPreferences: appPreferences,
            premiumPurchaseService: premiumPurchaseService,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cover Letter').first);
      await tester.pumpAndSettle();

      // Tapping the card now opens the editor directly.
      await tester.tap(find.text('Retail Sales Application'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('preview-cover-letter-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('preview-cover-letter-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cover-letter-preview-screen')),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cover-letter-preview-screen')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('preview-cover-letter-button')),
        findsNothing,
      );
      expect(find.text('Cover letter content'), findsNothing);
      expect(find.byKey(const Key('home-create-new-button')), findsOneWidget);
    },
  );
  testWidgets('uploading a resume shows a loading dialog while it processes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    _ignoreRenderOverflowErrors();

    final repository = _FakeAppShellRepository();
    final resumeLibrary = ResumeLibraryViewModel(repository: repository);
    final coverLetterLibrary = CoverLetterLibraryViewModel(
      repository: repository,
    );
    await resumeLibrary.loadResumes();
    await coverLetterLibrary.loadCoverLetters();
    final appPreferences = AppPreferences.inMemory(isPremium: true);
    final premiumPurchaseService = PremiumPurchaseService.inMemory(
      appPreferences: appPreferences,
      isPremium: true,
    );
    final importService = _PausedImportService();

    await tester.pumpWidget(
      MultiProvider(
        providers: _appShellProviders(
          repository: repository,
          resumeLibrary: resumeLibrary,
          coverLetterLibrary: coverLetterLibrary,
          appPreferences: appPreferences,
          premiumPurchaseService: premiumPurchaseService,
          importService: importService,
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reading your resume\u2026'), findsNothing);

    await tester.tap(find.byKey(const Key('home-upload-resume-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The file has been chosen but is not processed yet: loading is visible
    // and cannot be dismissed by tapping outside it.
    expect(find.text('Reading your resume\u2026'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text('Reading your resume\u2026'), findsOneWidget);

    // Processing finishes: the loading goes away and the builder opens.
    importService.finish();
    await tester.pumpAndSettle();
    expect(find.text('Reading your resume\u2026'), findsNothing);
    expect(find.text('Preview'), findsOneWidget);
  });
  /// Uploads a resume, edits nothing, and goes back to Home.
  Future<_RecordingFirebaseServices> uploadAndReturnHome(
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    _ignoreRenderOverflowErrors();

    final repository = _FakeAppShellRepository();
    final resumeLibrary = ResumeLibraryViewModel(repository: repository);
    final coverLetterLibrary = CoverLetterLibraryViewModel(
      repository: repository,
    );
    await resumeLibrary.loadResumes();
    await coverLetterLibrary.loadCoverLetters();
    final appPreferences = AppPreferences.inMemory(isPremium: true);
    final premiumPurchaseService = PremiumPurchaseService.inMemory(
      appPreferences: appPreferences,
      isPremium: true,
    );
    final importService = _PausedImportService();
    final firebase = _RecordingFirebaseServices();

    await tester.pumpWidget(
      MultiProvider(
        providers: _appShellProviders(
          repository: repository,
          resumeLibrary: resumeLibrary,
          coverLetterLibrary: coverLetterLibrary,
          appPreferences: appPreferences,
          premiumPurchaseService: premiumPurchaseService,
          importService: importService,
          firebase: firebase,
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-upload-resume-button')));
    await tester.pump();
    importService.finish();
    await tester.pumpAndSettle();

    // In the editor now. Nothing is asked until the user leaves it.
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('How did the upload go?'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    return firebase;
  }

  testWidgets('back on home after an upload, asks how it went — good', (
    tester,
  ) async {
    final firebase = await uploadAndReturnHome(tester);

    expect(find.text('How did the upload go?'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Bad'), findsOneWidget);

    await tester.tap(find.byKey(const Key('upload-feedback-good')));
    await tester.pumpAndSettle();

    expect(find.text('How did the upload go?'), findsNothing);
    expect(
      firebase.events.where((e) => e.startsWith('resume_upload_')),
      ['resume_upload_good'],
    );
  });

  testWidgets('back on home after an upload — bad', (tester) async {
    final firebase = await uploadAndReturnHome(tester);

    await tester.tap(find.byKey(const Key('upload-feedback-bad')));
    await tester.pumpAndSettle();

    expect(
      firebase.events.where((e) => e.startsWith('resume_upload_')),
      ['resume_upload_bad'],
    );
  });

  testWidgets('dismissing the upload question logs nothing', (tester) async {
    final firebase = await uploadAndReturnHome(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('How did the upload go?'), findsNothing);
    expect(firebase.events.where((e) => e.startsWith('resume_upload_')), isEmpty);
  });
  testWidgets('the loader stays up long enough to be seen on a fast import', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    _ignoreRenderOverflowErrors();

    final repository = _FakeAppShellRepository();
    final resumeLibrary = ResumeLibraryViewModel(repository: repository);
    final coverLetterLibrary = CoverLetterLibraryViewModel(
      repository: repository,
    );
    await resumeLibrary.loadResumes();
    await coverLetterLibrary.loadCoverLetters();
    final appPreferences = AppPreferences.inMemory(isPremium: true);
    final premiumPurchaseService = PremiumPurchaseService.inMemory(
      appPreferences: appPreferences,
      isPremium: true,
    );
    final importService = _PausedImportService()..finish(); // instant import

    await tester.pumpWidget(
      MultiProvider(
        providers: _appShellProviders(
          repository: repository,
          resumeLibrary: resumeLibrary,
          coverLetterLibrary: coverLetterLibrary,
          appPreferences: appPreferences,
          premiumPurchaseService: premiumPurchaseService,
          importService: importService,
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-upload-resume-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Import finished instantly, yet the loader is already on screen...
    expect(find.text('Reading your resume\u2026'), findsOneWidget);

    // ...and still there partway through its minimum time.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reading your resume\u2026'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Reading your resume\u2026'), findsNothing);
    expect(find.text('Preview'), findsOneWidget);
  });
}
