import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/home/home_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';
import 'package:resume_app/l10n/app_localizations.dart';

class _FakeHomeRepository implements ResumeRepository {
  _FakeHomeRepository({required this.resumes, this.coverLetters = const []});

  final List<ResumeData> resumes;
  final List<CoverLetterData> coverLetters;

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

void main() {
  testWidgets('resume card opens the editor on tap', (
    tester,
  ) async {
    final resume = ResumeData.empty(template: ResumeTemplate.corporate)
        .copyWith(
          id: 'resume-1',
          title: 'Product Designer Resume',
          fullName: 'Avery Lee',
          jobTitle: 'Product Designer',
        );
    final repository = _FakeHomeRepository(resumes: [resume]);
    final resumeLibrary = ResumeLibraryViewModel(repository: repository);
    final coverLetterLibrary = CoverLetterLibraryViewModel(
      repository: repository,
    );
    await resumeLibrary.loadResumes();
    await coverLetterLibrary.loadCoverLetters();

    ResumeData? openedForEdit;
    ResumeData? openedForPreview;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeLibraryViewModel>.value(
            value: resumeLibrary,
          ),
          ChangeNotifierProvider<CoverLetterLibraryViewModel>.value(
            value: coverLetterLibrary,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeScreen(
              currentSegment: HomeSegment.resumes,
              onSegmentChanged: (_) {},
              onOpenResume: (value) => openedForEdit = value,
              onPreviewResume: (value) => openedForPreview = value,
              onPreviewCoverLetter: (_) {},
              onEditCoverLetter: (_) {},
              onCreateResume: () {},
              onUploadResume: () {},
              onCreateCoverLetter: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resume-card-arrow-resume-1')), findsOneWidget);

    await tester.tap(find.text('Product Designer Resume'));
    await tester.pumpAndSettle();

    // No action sheet any more: the tap goes straight to the editor, where
    // rename / duplicate / delete now live in the top-right menu.
    expect(find.text('Open'), findsNothing);
    expect(find.text('Rename'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Duplicate'), findsNothing);

    expect(openedForEdit?.id, resume.id);
    expect(openedForPreview, isNull);
  });

  testWidgets('cover letter card opens the editor on tap', (
    tester,
  ) async {
    final coverLetter = CoverLetterData.empty().copyWith(
      id: 'cover-1',
      title: 'Retail Sales Application',
      company: 'Zara',
      role: 'Retail Sales Associate',
      content: 'Generated cover letter content',
    );
    final repository = _FakeHomeRepository(
      resumes: const [],
      coverLetters: [coverLetter],
    );
    final resumeLibrary = ResumeLibraryViewModel(repository: repository);
    final coverLetterLibrary = CoverLetterLibraryViewModel(
      repository: repository,
    );
    await resumeLibrary.loadResumes();
    await coverLetterLibrary.loadCoverLetters();

    CoverLetterData? previewedCoverLetter;
    CoverLetterData? editedCoverLetter;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeLibraryViewModel>.value(
            value: resumeLibrary,
          ),
          ChangeNotifierProvider<CoverLetterLibraryViewModel>.value(
            value: coverLetterLibrary,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeScreen(
              currentSegment: HomeSegment.coverLetters,
              onSegmentChanged: (_) {},
              onOpenResume: (_) {},
              onPreviewResume: (_) {},
              onPreviewCoverLetter: (value) => previewedCoverLetter = value,
              onEditCoverLetter: (value) => editedCoverLetter = value,
              onCreateResume: () {},
              onUploadResume: () {},
              onCreateCoverLetter: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('cover-letter-card-arrow-cover-1')),
      findsOneWidget,
    );

    await tester.tap(find.text('Retail Sales Application'));
    await tester.pumpAndSettle();

    // No action sheet any more — the tap goes straight to the editor.
    expect(find.text('Open'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);

    expect(editedCoverLetter?.id, coverLetter.id);
    expect(previewedCoverLetter, isNull);
  });

  testWidgets('resume cards stretch to the available screen width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final resume = ResumeData.empty(template: ResumeTemplate.corporate)
        .copyWith(
          id: 'resume-1',
          title: 'Product Designer Resume',
          fullName: 'Avery Lee',
          jobTitle: 'Product Designer',
        );
    final repository = _FakeHomeRepository(resumes: [resume]);
    final resumeLibrary = ResumeLibraryViewModel(repository: repository);
    final coverLetterLibrary = CoverLetterLibraryViewModel(
      repository: repository,
    );
    await resumeLibrary.loadResumes();
    await coverLetterLibrary.loadCoverLetters();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeLibraryViewModel>.value(
            value: resumeLibrary,
          ),
          ChangeNotifierProvider<CoverLetterLibraryViewModel>.value(
            value: coverLetterLibrary,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeScreen(
              currentSegment: HomeSegment.resumes,
              onSegmentChanged: (_) {},
              onOpenResume: (_) {},
              onPreviewResume: (_) {},
              onPreviewCoverLetter: (_) {},
              onEditCoverLetter: (_) {},
              onCreateResume: () {},
              onUploadResume: () {},
              onCreateCoverLetter: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardSize = tester.getSize(find.byType(Card).first);
    expect(cardSize.width, 760);
  });
  testWidgets('long press shows rename, duplicate and delete without open', (
    tester,
  ) async {
    final resume = ResumeData.empty(template: ResumeTemplate.corporate)
        .copyWith(id: 'resume-1', title: 'Product Designer Resume');
    final repository = _FakeHomeRepository(resumes: [resume]);
    final resumeLibrary = ResumeLibraryViewModel(repository: repository);
    final coverLetterLibrary = CoverLetterLibraryViewModel(
      repository: repository,
    );
    await resumeLibrary.loadResumes();
    await coverLetterLibrary.loadCoverLetters();

    ResumeData? opened;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeLibraryViewModel>.value(
            value: resumeLibrary,
          ),
          ChangeNotifierProvider<CoverLetterLibraryViewModel>.value(
            value: coverLetterLibrary,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeScreen(
              currentSegment: HomeSegment.resumes,
              onSegmentChanged: (_) {},
              onOpenResume: (value) => opened = value,
              onPreviewResume: (_) {},
              onPreviewCoverLetter: (_) {},
              onEditCoverLetter: (_) {},
              onCreateResume: () {},
              onUploadResume: () {},
              onCreateCoverLetter: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Product Designer Resume'));
    await tester.pumpAndSettle();

    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(opened, isNull, reason: 'long press must not open the editor');

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('rename-resume-title-field')),
      'Renamed Resume',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Renamed Resume'), findsOneWidget);
  });
}
