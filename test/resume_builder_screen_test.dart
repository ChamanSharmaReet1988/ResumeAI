import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/builder/resume_builder_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeResumeRepository implements ResumeRepository {
  final List<ResumeData> savedResumes = [];
  final List<CoverLetterData> savedCoverLetters = [];

  @override
  Future<void> deleteCoverLetter(String id) async {}

  @override
  Future<void> deleteResume(String id) async {}

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => const [];

  @override
  Future<List<ResumeData>> loadResumes() async => const [];

  @override
  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {
    savedCoverLetters.add(coverLetter);
  }

  @override
  Future<void> upsertResume(ResumeData resume) async {
    savedResumes.add(resume);
  }
}

void main() {
  late ResumeEditorViewModel viewModel;
  late _FakeResumeRepository repository;

  setUp(() {
    repository = _FakeResumeRepository();
    viewModel = ResumeEditorViewModel(
      repository: repository,
      aiService: LocalAiResumeService(),
      pdfService: ResumePdfService(),
      seedResume: ResumeData.empty(template: ResumeTemplate.modern).copyWith(
        title: 'My Resume',
        fullName: 'Test User',
        jobTitle: 'Flutter Developer',
        email: 'test@example.com',
        phone: '1234567890',
        summary: 'A short summary for testing.',
      ),
    );
    viewModel.setStep(1);
  });

  test('skills are capped at 50', () async {
    for (var index = 0; index < ResumeEditorViewModel.maxSkills; index++) {
      expect(viewModel.addSkill('Skill $index'), isTrue);
    }

    expect(viewModel.resume.skills.length, ResumeEditorViewModel.maxSkills);
    expect(viewModel.addSkill('Overflow Skill'), isFalse);

    await viewModel.suggestSkills();

    expect(viewModel.resume.skills.length, ResumeEditorViewModel.maxSkills);
    expect(viewModel.resume.skills, isNot(contains('Overflow Skill')));
  });

  Future<void> pumpBuilder(
    WidgetTester tester, {
    Size size = const Size(1440, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<ResumeEditorViewModel>.value(
        value: viewModel,
        child: const MaterialApp(home: ResumeBuilderScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('generate bullets adds AI bullets without throwing', (
    tester,
  ) async {
    await pumpBuilder(tester);

    await tester.tap(find.text('Generate bullets'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Led'), findsWidgets);
  });

  testWidgets('manual add bullet appends bullet without throwing', (
    tester,
  ) async {
    await pumpBuilder(tester);

    await tester.tap(find.text('Add bullet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Built a new feature');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Built a new feature'), findsWidgets);
  });

  testWidgets('work experience can be reordered from the builder', (
    tester,
  ) async {
    viewModel.updateResume(
      (resume) => resume.copyWith(
        workExperiences: const [
          WorkExperience(
            role: 'First role',
            company: 'Alpha',
            startDate: '2024',
            endDate: 'Present',
            description: 'First description',
            bullets: [],
          ),
          WorkExperience(
            role: 'Second role',
            company: 'Beta',
            startDate: '2022',
            endDate: '2024',
            description: 'Second description',
            bullets: [],
          ),
        ],
      ),
    );

    await pumpBuilder(tester);

    expect(find.text('Appears first on your resume'), findsOneWidget);
    expect(find.text('Appears 2nd on your resume'), findsOneWidget);

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.tap(find.byTooltip('Move down').first);
    await tester.pumpAndSettle();

    expect(viewModel.resume.workExperiences.first.company, 'Beta');
    expect(find.text('Second role'), findsWidgets);
  });

  testWidgets('end date picker supports Present preset', (tester) async {
    viewModel.updateResume(
      (resume) => resume.copyWith(
        workExperiences: const [
          WorkExperience(
            role: 'Flutter Developer',
            company: 'Acme',
            startDate: 'Jan 2024',
            endDate: '',
            description: 'Builds features',
            bullets: [],
          ),
        ],
      ),
    );

    await pumpBuilder(tester);

    await tester.tap(find.byKey(const Key('work-end-date-0')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Present'));
    await tester.pumpAndSettle();

    expect(viewModel.resume.workExperiences.first.endDate, 'Present');
  });

  testWidgets('education can be reordered from the builder', (tester) async {
    viewModel.setStep(2);
    viewModel.updateResume(
      (resume) => resume.copyWith(
        education: const [
          EducationItem(
            institution: 'Alpha University',
            degree: 'B.Tech',
            year: '2024',
            score: '8.5 CGPA',
            details: 'Alpha details',
          ),
          EducationItem(
            institution: 'Beta Institute',
            degree: 'M.Tech',
            year: '2025',
            score: '9.1 CGPA',
            details: 'Beta details',
          ),
        ],
      ),
    );

    await pumpBuilder(tester);

    expect(find.text('Appears first on your resume'), findsOneWidget);
    expect(find.text('Appears 2nd on your resume'), findsOneWidget);

    await tester.tap(find.byTooltip('Move education down').first);
    await tester.pumpAndSettle();

    expect(viewModel.resume.education.first.institution, 'Beta Institute');
    expect(find.text('Beta Institute'), findsWidgets);
  });

  testWidgets(
    'work date picker uses month and year UI and defaults to completion year',
    (tester) async {
      viewModel.updateResume(
        (resume) => resume.copyWith(
          workExperiences: const [
            WorkExperience(
              role: 'Flutter Developer',
              company: 'Acme',
              startDate: '',
              endDate: '',
              description: 'Builds features',
              bullets: [],
            ),
          ],
          education: const [
            EducationItem(
              institution: 'Test University',
              degree: 'B.Tech',
              year: '2024',
              score: '8.6 CGPA',
              details: '',
            ),
          ],
        ),
      );

      await pumpBuilder(tester);

      await tester.tap(find.byKey(const Key('work-start-date-0')));
      await tester.pumpAndSettle();

      expect(find.text('Select start month and year'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(
        viewModel.resume.workExperiences.first.startDate,
        endsWith('2024'),
      );
    },
  );

  testWidgets('completion year field opens a year picker', (tester) async {
    viewModel.setStep(2);

    await pumpBuilder(tester);

    await tester.tap(find.byKey(const Key('education-completion-year-0')));
    await tester.pumpAndSettle();

    expect(find.byType(YearPicker), findsOneWidget);
  });

  testWidgets('continue scrolls the next category to the top', (tester) async {
    viewModel.setStep(0);

    await pumpBuilder(tester, size: const Size(800, 700));

    final verticalScrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.vertical,
        )
        .first;
    final verticalScrollView = tester.widget<SingleChildScrollView>(
      verticalScrollable,
    );
    final verticalScrollController = verticalScrollView.controller!;

    await tester.drag(verticalScrollable, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(verticalScrollController.offset, greaterThan(0));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(viewModel.currentStep, 1);
    expect(verticalScrollController.offset, 0);
  });

  testWidgets('selected category chip scrolls into view on continue', (
    tester,
  ) async {
    viewModel.setStep(0);

    await pumpBuilder(tester, size: const Size(520, 700));

    final horizontalScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    final horizontalScrollView = tester.widget<SingleChildScrollView>(
      horizontalScrollable,
    );
    final horizontalScrollController = horizontalScrollView.controller!;

    expect(horizontalScrollController.offset, 0);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(viewModel.currentStep, 1);
    expect(horizontalScrollController.offset, greaterThan(0));
  });

  testWidgets('continue saves the current draft before moving on', (
    tester,
  ) async {
    viewModel.setStep(0);

    await pumpBuilder(tester);

    await tester.enterText(find.byType(TextField).at(1), 'Saved Name');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(viewModel.currentStep, 1);
    expect(repository.savedResumes, isNotEmpty);
    expect(repository.savedResumes.last.fullName, 'Saved Name');
  });
}
