import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/builder/resume_builder_screen.dart';
import 'package:resume_app/features/builder/resume_preview_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';
import 'package:resume_app/l10n/app_localizations.dart';

class _FakeResumeRepository implements ResumeRepository {
  final List<ResumeData> savedResumes = [];
  final List<CoverLetterData> savedCoverLetters = [];

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
  Future<void> deleteResume(String id) async {}

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => const [];

  @override
  Future<List<ResumeData>> loadResumes() async => const [];

  @override
  Future<void> upsertCoverLetter(
    CoverLetterData coverLetter, {
    bool scheduleAutoSync = true,
  }) async {
    savedCoverLetters.add(coverLetter);
  }

  @override
  Future<void> upsertResume(
    ResumeData resume, {
    bool scheduleAutoSync = true,
  }) async {
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

  test('skills can grow without hard cap', () async {
    for (var index = 0; index < 80; index++) {
      expect(viewModel.addSkill('Skill $index'), isTrue);
    }

    expect(viewModel.resume.skills.length, 80);
    expect(viewModel.addSkill('Overflow Skill'), isTrue);

    await viewModel.suggestSkills();

    expect(viewModel.resume.skills.length, greaterThan(80));
    expect(viewModel.resume.skills, contains('Overflow Skill'));

    viewModel.dispose();
  });

  Future<void> pumpBuilder(
    WidgetTester tester, {
    Size size = const Size(1440, 1200),
    AppPreferences? preferences,
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
            value: preferences ?? AppPreferences.inMemory(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResumeBuilderScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSection(WidgetTester tester, int step) async {
    await tester.tap(find.byKey(Key('builder-section-$step')));
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResumePreviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder textFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
      description: 'TextField with label $label',
    );
  }

  testWidgets('work experience step shows role field', (tester) async {
    await pumpBuilder(tester);
    await openSection(tester, 1);

    expect(textFieldByLabel('Role'), findsWidgets);
  });

  testWidgets('builder shows every section in one vertical list', (tester) async {
    viewModel.setStep(0);
    await pumpBuilder(tester, size: const Size(800, 1100));

    expect(find.text('Personal Information'), findsWidgets);
    expect(find.text('Work Experience'), findsWidgets);
    expect(find.text('Education'), findsWidgets);
    expect(find.text('Skills'), findsWidgets);
    expect(find.text('Projects'), findsWidgets);
    expect(textFieldByLabel('Full name'), findsNothing);
    expect(textFieldByLabel('Role'), findsNothing);

    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();

    expect(viewModel.currentStep, 3);
    expect(textFieldByLabel('Add a skill'), findsOneWidget);
    expect(find.text('Personal Information'), findsNothing);
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
    await openSection(tester, 1);

    expect(find.text('Appears first on your resume'), findsOneWidget);
    expect(
      find.text('Appears at position 2 on your resume'),
      findsOneWidget,
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.tap(find.byTooltip('Move down').first);
    await tester.pumpAndSettle();

    expect(viewModel.resume.workExperiences.first.company, 'Beta');
    expect(find.text('Second role'), findsWidgets);
  });

  testWidgets('edit mode can reorder, hide default sections, and delete custom sections', (
    tester,
  ) async {
    viewModel.addCustomSectionWithTitle('Certifications');

    await pumpBuilder(tester);

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Add section'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
    expect(find.byKey(const Key('builder-section-hide-1')), findsNothing);
    expect(find.byKey(const Key('builder-section-delete-5')), findsNothing);

    await tester.tap(find.byKey(const Key('builder-edit-sections-button')));
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(5));
    expect(find.byKey(const Key('builder-section-hide-1')), findsOneWidget);
    expect(find.byKey(const Key('builder-section-hide-0')), findsNothing);
    expect(find.byKey(const Key('builder-section-delete-1')), findsNothing);
    expect(find.byKey(const Key('builder-section-delete-5')), findsOneWidget);

    await tester.tap(find.byKey(const Key('builder-section-hide-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();

    expect(viewModel.resume.includeWorkInResume, isFalse);

    await tester.tap(find.byKey(const Key('builder-section-delete-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(viewModel.resume.customSections, isEmpty);
    expect(find.text('Certifications'), findsNothing);
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
    await openSection(tester, 1);

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
            startDate: '2020',
            endDate: '2024',
          ),
          EducationItem(
            institution: 'Beta Institute',
            degree: 'M.Tech',
            startDate: '2023',
            endDate: '2025',
          ),
        ],
      ),
    );

    await pumpBuilder(tester);
    await openSection(tester, 2);

    expect(find.text('Appears first on your resume'), findsOneWidget);
    expect(
      find.text('Appears at position 2 on your resume'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Move education down').first);
    await tester.pumpAndSettle();

    expect(viewModel.resume.education.first.institution, 'Beta Institute');
    expect(find.text('Beta Institute'), findsWidgets);
  });

  testWidgets('projects show bullet points input only', (tester) async {
    viewModel.setStep(4);

    await pumpBuilder(tester);
    await openSection(tester, 4);

    expect(find.text('Subtitle or stack'), findsNothing);
    expect(find.text('Project title'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    expect(find.text('Tools & Technologies'), findsNothing);
    expect(find.text('Bullet 1'), findsNothing);
    expect(find.text('Add bullet point'), findsOneWidget);
  });

  testWidgets(
    'work date picker uses month and year UI and defaults to education end year',
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
              startDate: '2020',
              endDate: '2024',
            ),
          ],
        ),
      );

      await pumpBuilder(tester);
      await openSection(tester, 1);

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

  testWidgets('education end year field opens year picker', (tester) async {
    viewModel.setStep(2);

    await pumpBuilder(tester);
    await openSection(tester, 2);

    await tester.tap(find.byKey(const Key('education-end-date-0')));
    await tester.pumpAndSettle();

    expect(find.text('Select end year'), findsOneWidget);
    expect(find.byType(YearPicker), findsOneWidget);
  });

  testWidgets('Add chip opens new section dialog', (tester) async {
    viewModel.setStep(4);
    await pumpBuilder(tester);

    await tester.tap(find.text('Add section'));
    await tester.pumpAndSettle();

    expect(find.text('New section'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Advance'), findsOneWidget);
    final okButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'OK'),
    );
    expect(okButton.onPressed, isNull);

    await tester.enterText(textFieldByLabel('Title'), 'Certifications');
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'OK')).onPressed,
      isNotNull,
    );
  });

  testWidgets('Advance custom section uses project-style entries', (
    tester,
  ) async {
    viewModel.addCustomSectionWithTitle(
      'Case Studies',
      layoutMode: CustomSectionLayoutMode.projects,
    );
    viewModel.setStep(5);

    await pumpBuilder(tester);
    await openSection(tester, 5);

    expect(find.text('Case Studies'), findsWidgets);
    expect(find.text('Entry 1'), findsOneWidget);
    expect(find.text('Add entry'), findsOneWidget);
    expect(find.byKey(const Key('custom-section-project-title-0-0')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('custom-section-project-title-0-0')),
      'Mobile Banking App',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(viewModel.resume.customSections, hasLength(1));
    expect(
      viewModel.resume.customSections.first.layoutMode,
      CustomSectionLayoutMode.projects,
    );
    expect(
      viewModel.resume.customSections.first.projectEntries.first.title,
      'Mobile Banking App',
    );
  });

  testWidgets('custom section category saves title and content on the resume', (
    tester,
  ) async {
    viewModel.addCustomSectionWithTitle('Certifications');
    viewModel.setStep(5);

    await pumpBuilder(tester);
    await openSection(tester, 5);

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
  });

  testWidgets('custom sections can be reordered via view model', (
    tester,
  ) async {
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
    await openSection(tester, 4);

    expect(find.text('Appears first on your resume'), findsOneWidget);
    expect(
      find.text('Appears at position 2 on your resume'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Move project down').first);
    await tester.pumpAndSettle();

    expect(viewModel.resume.projects.first.title, 'Second project');
    expect(find.text('Second project'), findsWidgets);
  });

  testWidgets('preview is available on the first step and returns to the builder', (
    tester,
  ) async {
    viewModel.setStep(0);

    await pumpBuilder(tester);

    await tester.tap(find.byKey(const Key('builder-preview-button')));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('resume-pdf-preview')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resume-pdf-preview')), findsNothing);
    expect(find.byKey(const Key('builder-preview-button')), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
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

    await tester.tap(find.byKey(const Key('template-image-profile-sidebar')));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(viewModel.resume.template, ResumeTemplate.creative);
  });

  testWidgets('preview back returns to the home screen', (tester) async {
    viewModel.setStep(5);
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeEditorViewModel>.value(value: viewModel),
          Provider<AppPreferences>.value(value: AppPreferences.inMemory()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    expect(find.text('Home screen'), findsOneWidget);
    expect(find.byKey(const Key('resume-pdf-preview')), findsNothing);
    expect(find.text('Preview'), findsNothing);
  });

  testWidgets('tapping a section opens its fields on a new screen', (
    tester,
  ) async {
    viewModel.setStep(0);

    await pumpBuilder(tester, size: const Size(800, 700));

    expect(textFieldByLabel('Full name'), findsNothing);
    expect(textFieldByLabel('Role'), findsNothing);

    await openSection(tester, 1);

    expect(viewModel.currentStep, 1);
    expect(textFieldByLabel('Role'), findsWidgets);
    expect(find.byKey(const Key('step-scroll-1')), findsOneWidget);
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

      await openSection(tester, 1);

      expect(viewModel.currentStep, 1);
      expect(viewModel.resume.title, ResumeData.defaultTitle);
      expect(repository.savedResumes.last.title, ResumeData.defaultTitle);
    },
  );

  testWidgets(
    'personal step shows core fields first and hides extras under add more',
    (tester) async {
      viewModel.setStep(0);

      await pumpBuilder(tester, size: const Size(800, 1100));
      await openSection(tester, 0);

      expect(textFieldByLabel('Full name'), findsOneWidget);
      expect(textFieldByLabel('Email'), findsOneWidget);
      expect(textFieldByLabel('Phone number'), findsOneWidget);
      expect(textFieldByLabel('City'), findsOneWidget);
      expect(find.text('Add more (optional)'), findsOneWidget);
      expect(textFieldByLabel('LinkedIn link'), findsNothing);
      expect(textFieldByLabel('Website or portfolio'), findsNothing);
      expect(find.text('Profile photo'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('personal-add-more')));
      await tester.tap(find.byKey(const Key('personal-add-more')));
      await tester.pumpAndSettle();

      expect(textFieldByLabel('LinkedIn link'), findsOneWidget);
      expect(textFieldByLabel('Website or portfolio'), findsOneWidget);
      expect(find.text('Profile photo'), findsOneWidget);
    },
  );

  testWidgets('personal optional fields start open when already filled', (
    tester,
  ) async {
    viewModel.setStep(0);
    viewModel.updateResume(
      (resume) => resume.copyWith(
        linkedinLink: 'linkedin.com/in/test-user',
      ),
    );

    await pumpBuilder(tester, size: const Size(800, 1100));
    await openSection(tester, 0);

    expect(textFieldByLabel('LinkedIn link'), findsOneWidget);
    expect(textFieldByLabel('Website or portfolio'), findsOneWidget);
    expect(find.text('Profile photo'), findsOneWidget);
  });

  testWidgets('suggest summary asks for name and title before generating', (
    tester,
  ) async {
    viewModel.setStep(0);
    viewModel.updateResume(
      (resume) => resume.copyWith(
        fullName: '',
        jobTitle: '',
        summary: '',
      ),
    );

    await pumpBuilder(tester, size: const Size(800, 1100));
    await openSection(tester, 0);

    await tester.ensureVisible(
      find.byKey(const Key('generate-summary-ai-button')),
    );
    await tester.tap(find.byKey(const Key('generate-summary-ai-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('suggest-summary-missing-dialog')), findsOneWidget);
    expect(
      find.text(
        'Enter your full name and target job title first, then try Suggest summary again.',
      ),
      findsOneWidget,
    );
    expect(viewModel.resume.summary, isEmpty);
  });

  testWidgets('suggest summary fills the professional summary field', (
    tester,
  ) async {
    viewModel.setStep(0);
    viewModel.updateResume(
      (resume) => resume.copyWith(summary: ''),
    );

    await pumpBuilder(tester, size: const Size(800, 1100));
    await openSection(tester, 0);

    expect(find.byKey(const Key('generate-summary-ai-button')), findsOneWidget);
    expect(
      find.text(
        'Uses your name, target job title, work experience, and skills. Add those first for a stronger summary.',
      ),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(const Key('generate-summary-ai-button')),
    );
    await tester.tap(find.byKey(const Key('generate-summary-ai-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('suggest-summary-experience-dialog')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('suggest-summary-experience-field')),
      '5',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('suggest-summary-experience-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(viewModel.resume.summary.trim(), isNotEmpty);
    expect(viewModel.resume.summary, contains('5 years of experience'));
    expect(find.text('Summary added'), findsOneWidget);
  });

  testWidgets('section list stays visible until a section is opened', (
    tester,
  ) async {
    viewModel.setStep(0);

    await pumpBuilder(tester, size: const Size(520, 700));

    expect(find.text('Work Experience'), findsWidgets);
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Add section'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
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
    await openSection(tester, 0);

    await tester.enterText(textFieldByLabel('Full name'), 'Saved Name');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(repository.savedResumes, isNotEmpty);
    expect(repository.savedResumes.last.fullName, 'Saved Name');
  });

  testWidgets('editing a field auto-saves the draft', (tester) async {
    viewModel.setStep(0);

    await pumpBuilder(tester);
    await openSection(tester, 0);

    await tester.enterText(textFieldByLabel('Full name'), 'Auto Saved Name');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(repository.savedResumes, isNotEmpty);
    expect(repository.savedResumes.last.fullName, 'Auto Saved Name');
  });

  testWidgets('education score % toggle updates resume JSON', (tester) async {
    viewModel.setStep(2);
    viewModel.updateResume(
      (resume) => resume.copyWith(
        education: const [
          EducationItem(
            institution: 'Alpha University',
            degree: 'B.Tech',
            startDate: '2020',
            endDate: '2024',
            score: '92',
          ),
        ],
      ),
    );

    await pumpBuilder(tester);
    await openSection(tester, 2);

    expect(viewModel.resume.education.first.showScoreAsPercent, isFalse);

    await tester.tap(find.text('%'));
    await tester.pumpAndSettle();

    expect(viewModel.resume.education.first.showScoreAsPercent, isTrue);
    expect(educationScoreDisplayLabel(viewModel.resume.education.first), '92%');

    await tester.tap(find.text('%'));
    await tester.pumpAndSettle();

    expect(viewModel.resume.education.first.showScoreAsPercent, isFalse);
    expect(educationScoreDisplayLabel(viewModel.resume.education.first), '92');
  });

  testWidgets('added skills show one row with an efficiency slider', (
    tester,
  ) async {
    viewModel.setStep(3);
    await pumpBuilder(tester);
    await openSection(tester, 3);

    await tester.enterText(textFieldByLabel('Add a skill'), 'Flutter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Flutter'), findsWidgets);
    expect(find.byType(Slider), findsNothing);
    expect(find.byKey(const Key('skill-efficiency-Flutter-4')), findsOneWidget);
    expect(viewModel.resume.proficiencyForSkill('Flutter'), 70);

    await tester.tap(find.byKey(const Key('skill-efficiency-Flutter-5')));
    await tester.pump();

    expect(viewModel.resume.proficiencyForSkill('Flutter'), 100);
  });
}
