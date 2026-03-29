import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/home/home_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeHomeRepository implements ResumeRepository {
  _FakeHomeRepository({required this.resumes, this.coverLetters = const []});

  final List<ResumeData> resumes;
  final List<CoverLetterData> coverLetters;

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
  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {}

  @override
  Future<void> upsertResume(ResumeData resume) async {
    resumes.removeWhere((item) => item.id == resume.id);
    resumes.add(resume);
  }
}

void main() {
  testWidgets('resume card opens actions and preview uses the open option', (
    tester,
  ) async {
    final resume = ResumeData.empty(template: ResumeTemplate.modern).copyWith(
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
          home: Scaffold(
            body: HomeScreen(
              currentSegment: HomeSegment.resumes,
              onSegmentChanged: (_) {},
              onOpenResume: (value) => openedForEdit = value,
              onPreviewResume: (value) => openedForPreview = value,
              onOpenCoverLetter: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resume-card-arrow-resume-1')), findsOneWidget);

    await tester.tap(find.text('Product Designer Resume'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(openedForPreview?.id, resume.id);
    expect(openedForEdit, isNull);
  });

  testWidgets('resume card duplicate option creates a copied resume', (
    tester,
  ) async {
    final resume = ResumeData.empty(template: ResumeTemplate.modern).copyWith(
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
          home: Scaffold(
            body: HomeScreen(
              currentSegment: HomeSegment.resumes,
              onSegmentChanged: (_) {},
              onOpenResume: (_) {},
              onPreviewResume: (_) {},
              onOpenCoverLetter: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Product Designer Resume'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(resumeLibrary.resumes, hasLength(2));
    expect(
      resumeLibrary.resumes.any(
        (item) => item.title == 'Product Designer Resume (Copy)',
      ),
      isTrue,
    );
    expect(find.text('Resume duplicated.'), findsOneWidget);
  });

  testWidgets('cover letter card matches resume card tap flow', (tester) async {
    final coverLetter = CoverLetterData.empty().copyWith(
      id: 'cover-1',
      title: 'Retail Sales Application',
      company: 'Zara',
      role: 'Retail Sales Associate',
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

    CoverLetterData? openedCoverLetter;

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
          home: Scaffold(
            body: HomeScreen(
              currentSegment: HomeSegment.coverLetters,
              onSegmentChanged: (_) {},
              onOpenResume: (_) {},
              onPreviewResume: (_) {},
              onOpenCoverLetter: (value) => openedCoverLetter = value,
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

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(openedCoverLetter?.id, coverLetter.id);
  });

  testWidgets('resume cards stretch to the available screen width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final resume = ResumeData.empty(template: ResumeTemplate.modern).copyWith(
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
          home: Scaffold(
            body: HomeScreen(
              currentSegment: HomeSegment.resumes,
              onSegmentChanged: (_) {},
              onOpenResume: (_) {},
              onPreviewResume: (_) {},
              onOpenCoverLetter: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardSize = tester.getSize(find.byType(Card).first);
    expect(cardSize.width, 760);
  });
}
