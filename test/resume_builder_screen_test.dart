import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/builder/resume_builder_screen.dart';
import 'package:resume_app/features/builder/resume_preview_screen.dart';
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
      seedResume: ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
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

    viewModel.dispose();
  });

  Future<void> pumpBuilder(
    WidgetTester tester, {
    Size size = const Size(1440, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeEditorViewModel>(
            create: (_) => viewModel,
          ),
          Provider<AppPreferences>.value(
            value: AppPreferences.inMemory(),
          ),
        ],
        child: const MaterialApp(home: ResumeBuilderScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpPreview(
    WidgetTester tester, {
    Size size = const Size(1440, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<ResumeEditorViewModel>(
        create: (_) => viewModel,
        child: const MaterialApp(home: ResumePreviewScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder textFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == label,
      description: 'TextField with label $label',
    );
  }

  testWidgets('work experience step shows role field', (tester) async {
    await pumpBuilder(tester);

    expect(textFieldByLabel('Role'), findsWidgets);
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

  testWidgets('projects no longer show a subtitle or stack field', (
    tester,
  ) async {
    viewModel.setStep(4);

    await pumpBuilder(tester);

    expect(find.text('Subtitle or stack'), findsNothing);
    expect(find.text('Project title'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
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

  testWidgets('Add chip opens new section dialog', (tester) async {
    viewModel.setStep(4);
    await pumpBuilder(tester);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New section'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets(
    'custom section category saves title and content on the resume',
    (tester) async {
      viewModel.addCustomSectionWithTitle('Certifications');
      viewModel.setStep(5);

      await pumpBuilder(tester);

      expect(find.text('Resume Preview'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('custom-section-content-0')),
        'Google UX Certificate, AWS Cloud Practitioner',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(viewModel.resume.customSections, hasLength(1));
      expect(viewModel.resume.customSections.first.title, 'Certifications');
      expect(
        viewModel.resume.customSections.first.content,
        'Google UX Certificate, AWS Cloud Practitioner',
      );
    },
  );

  testWidgets('custom sections can be reordered via view model', (tester) async {
    viewModel.updateResume(
      (resume) => resume.copyWith(
        customSections: const [
          CustomSectionItem(title: 'First section', content: 'First content'),
          CustomSectionItem(title: 'Second section', content: 'Second content'),
        ],
      ),
    );

    viewModel.moveCustomSectionDown(0);

    expect(viewModel.resume.customSections.first.title, 'Second section');

    await pumpBuilder(tester);
    expect(find.text('Second section'), findsWidgets);
  });

  testWidgets('projects can be reordered from the builder', (tester) async {
    viewModel.setStep(4);
    viewModel.updateResume(
      (resume) => resume.copyWith(
        projects: const [
          ProjectItem(
            title: 'First project',
            subtitle: '',
            overview: 'First overview',
            impact: 'Flutter',
          ),
          ProjectItem(
            title: 'Second project',
            subtitle: '',
            overview: 'Second overview',
            impact: 'Firebase',
          ),
        ],
      ),
    );

    await pumpBuilder(tester);

    expect(find.text('Appears first on your resume'), findsOneWidget);
    expect(find.text('Appears 2nd on your resume'), findsOneWidget);

    await tester.tap(find.byTooltip('Move project down').first);
    await tester.pumpAndSettle();

    expect(viewModel.resume.projects.first.title, 'Second project');
    expect(find.text('Second project'), findsWidgets);
  });

  testWidgets('save opens the separate preview screen', (tester) async {
    viewModel.setStep(4);

    await pumpBuilder(tester);

    expect(find.text('Save'), findsNothing);

    await tester.tap(find.text('Preview'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('My Resume'), findsWidgets);
    expect(find.byKey(const Key('resume-pdf-preview')), findsOneWidget);
    expect(find.text('ATS score'), findsNothing);
  });

  testWidgets('preview screen bottom bar opens template picker', (
    tester,
  ) async {
    await pumpPreview(tester);

    await tester.tap(find.text('Template'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('template-grid')), findsOneWidget);
    expect(find.text('Choose template'), findsOneWidget);

    await tester.tap(find.byKey(const Key('template-image-centered-classic')));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(viewModel.resume.template, ResumeTemplate.minimal);
  });

  testWidgets('preview back returns to the resume builder', (tester) async {
    viewModel.setStep(5);
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeEditorViewModel>.value(
            value: viewModel,
          ),
          Provider<AppPreferences>.value(
            value: AppPreferences.inMemory(),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ResumeBuilderScreen(),
                        ),
                      );
                    },
                    child: const Text('Home screen'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home screen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preview'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('resume-pdf-preview')), findsOneWidget);
    expect(find.text('ATS score'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsNothing);
    expect(find.byKey(const Key('resume-pdf-preview')), findsNothing);
    expect(find.text('Preview'), findsOneWidget);
  });

  testWidgets('continue scrolls the next category to the top', (tester) async {
    viewModel.setStep(0);

    await pumpBuilder(tester, size: const Size(800, 700));

    final verticalScrollable = find.byKey(const Key('step-scroll-0'));
    final verticalScrollView = tester.widget<SingleChildScrollView>(
      verticalScrollable,
    );
    final currentStepScrollController = verticalScrollView.controller!;

    await tester.drag(verticalScrollable, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(currentStepScrollController.offset, greaterThan(0));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final nextStepScrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('step-scroll-1')),
    );
    final nextStepScrollController = nextStepScrollView.controller!;

    expect(viewModel.currentStep, 1);
    expect(nextStepScrollController.offset, 0);
  });

  testWidgets(
    'personal info has no resume title field and blank title still saves as untitled',
    (tester) async {
      viewModel.dispose();
      repository = _FakeResumeRepository();
      viewModel = ResumeEditorViewModel(
        repository: repository,
        aiService: LocalAiResumeService(),
        pdfService: ResumePdfService(),
        seedResume: ResumeData.empty(template: ResumeTemplate.corporate),
      );
      viewModel.setStep(0);

      await pumpBuilder(tester, size: const Size(800, 700));

      expect(find.text('Resume title'), findsNothing);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(viewModel.currentStep, 1);
      expect(viewModel.resume.title, ResumeData.defaultTitle);
      expect(repository.savedResumes.last.title, ResumeData.defaultTitle);
    },
  );

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

  testWidgets('edit screen selects work step from category chips', (
    tester,
  ) async {
    viewModel.setStep(0);

    await pumpBuilder(tester, size: const Size(520, 700));

    await tester.tap(find.text('Work Experience'));
    await tester.pumpAndSettle();

    expect(viewModel.currentStep, 1);
    expect(find.text('Work experience'), findsOneWidget);
  });

  testWidgets('continue saves the current draft before moving on', (
    tester,
  ) async {
    viewModel.setStep(0);

    await pumpBuilder(tester);

    await tester.enterText(textFieldByLabel('Full name'), 'Saved Name');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(viewModel.currentStep, 1);
    expect(repository.savedResumes, isNotEmpty);
    expect(repository.savedResumes.last.fullName, 'Saved Name');
  });

  testWidgets('editing a field auto-saves the draft', (tester) async {
    viewModel.setStep(0);

    await pumpBuilder(tester);

    await tester.enterText(textFieldByLabel('Full name'), 'Auto Saved Name');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(repository.savedResumes, isNotEmpty);
    expect(repository.savedResumes.last.fullName, 'Auto Saved Name');
  });
}
