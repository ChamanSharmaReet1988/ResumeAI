import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/premium_purchase_service.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/shell/app_shell.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeAppShellRepository implements ResumeRepository {
  final List<ResumeData> resumes = [];
  final List<CoverLetterData> coverLetters = [];

  @override
  void configureGoogleDriveAutoSync({
    required AppPreferences appPreferences,
    required GoogleDriveResumeService service,
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
          providers: [
            Provider<ResumeImportService>.value(value: ResumeImportService()),
            Provider<ResumeRepository>.value(value: repository),
            Provider<AppPreferences>.value(value: appPreferences),
            ChangeNotifierProvider<PremiumPurchaseService>.value(
              value: premiumPurchaseService,
            ),
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

      final appPreferences = AppPreferences.inMemory();
      final premiumPurchaseService = PremiumPurchaseService.inMemory(
        appPreferences: appPreferences,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ResumeImportService>.value(value: ResumeImportService()),
            Provider<ResumeRepository>.value(value: repository),
            Provider<AppPreferences>.value(value: appPreferences),
            ChangeNotifierProvider<PremiumPurchaseService>.value(
              value: premiumPurchaseService,
            ),
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
          providers: [
            Provider<ResumeImportService>.value(value: ResumeImportService()),
            Provider<ResumeRepository>.value(value: repository),
            Provider<AppPreferences>.value(value: appPreferences),
            ChangeNotifierProvider<PremiumPurchaseService>.value(
              value: premiumPurchaseService,
            ),
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

      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);

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
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Use template'), findsNothing);
    },
  );

  testWidgets(
    'template use flow returns to home when preview is dismissed',
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
          providers: [
            Provider<ResumeImportService>.value(value: ResumeImportService()),
            Provider<ResumeRepository>.value(value: repository),
            Provider<AppPreferences>.value(value: appPreferences),
            ChangeNotifierProvider<PremiumPurchaseService>.value(
              value: premiumPurchaseService,
            ),
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

      for (var step = 0; step < 4; step++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('resume-pdf-preview')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('resume-pdf-preview')), findsNothing);
      expect(find.byKey(const Key('resume-step-pages')), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Use template'), findsNothing);
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
          providers: [
            Provider<ResumeImportService>.value(value: ResumeImportService()),
            Provider<ResumeRepository>.value(value: repository),
            Provider<AppPreferences>.value(value: appPreferences),
            ChangeNotifierProvider<PremiumPurchaseService>.value(
              value: premiumPurchaseService,
            ),
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
      expect(find.byType(FloatingActionButton), findsOneWidget);
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
          providers: [
            Provider<ResumeImportService>.value(value: ResumeImportService()),
            Provider<ResumeRepository>.value(value: repository),
            Provider<AppPreferences>.value(value: appPreferences),
            ChangeNotifierProvider<PremiumPurchaseService>.value(
              value: premiumPurchaseService,
            ),
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

      await tester.tap(find.text('Retail Sales Application'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
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
      expect(find.byType(FloatingActionButton), findsOneWidget);
    },
  );
}
