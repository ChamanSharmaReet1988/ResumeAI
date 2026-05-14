import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/cover_letters/cover_letter_editor_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeCoverLetterRepository implements ResumeRepository {
  final List<CoverLetterData> savedCoverLetters = [];

  @override
  void configureICloudAutoSync({
    required AppPreferences appPreferences,
    required ICloudResumeService service,
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
  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {
    savedCoverLetters.add(coverLetter);
  }

  @override
  Future<void> upsertResume(
    ResumeData resume, {
    bool scheduleAutoSync = true,
  }) async {}
}

Finder _textFieldByLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
    description: 'TextField with label $label',
  );
}

void main() {
  testWidgets('create cover letter opens the content screen with generated content', (
    tester,
  ) async {
    final repository = _FakeCoverLetterRepository();
    final viewModel = CoverLetterEditorViewModel(
      repository: repository,
      aiService: LocalAiResumeService(),
      resumeContext: ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
        fullName: 'Avery Lee',
        jobTitle: 'Product Designer',
        summary:
            'This exact summary text should not be copied directly into the cover letter body.',
        skills: const ['UX research', 'Prototyping', 'Stakeholder management'],
        workExperiences: const [
          WorkExperience(
            role: 'Product Designer',
            company: 'North Studio',
            startDate: '2023',
            endDate: 'Present',
            description:
                'Led cross-functional design work and research planning for web and mobile products.',
            bullets: [
              'Worked with product managers and engineers to improve onboarding flows.',
            ],
          ),
        ],
      ),
      seedCoverLetter: CoverLetterData.empty(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ResumePdfService>.value(value: ResumePdfService()),
          ChangeNotifierProvider<CoverLetterEditorViewModel>.value(
            value: viewModel,
          ),
        ],
        child: const MaterialApp(home: CoverLetterEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(_textFieldByLabel('Company name'), findsOneWidget);
    expect(_textFieldByLabel('Job position name'), findsOneWidget);
    expect(_textFieldByLabel('Skill to highlight'), findsOneWidget);
    expect(
      find.byKey(const Key('cover-letter-language-dropdown')),
      findsOneWidget,
    );
    expect(_textFieldByLabel('Cover letter content'), findsNothing);

    await tester.enterText(_textFieldByLabel('Company name'), 'Acme Labs');
    await tester.enterText(
      _textFieldByLabel('Job position name'),
      'Senior Product Designer',
    );
    await tester.enterText(
      _textFieldByLabel('Skill to highlight'),
      'UX research',
    );
    await tester.tap(find.byKey(const Key('cover-letter-skill-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      _textFieldByLabel('Skill to highlight'),
      'Prototyping',
    );
    await tester.tap(find.byKey(const Key('cover-letter-skill-add-button')));
    await tester.pumpAndSettle();
    final languageDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('cover-letter-language-dropdown')),
    );
    languageDropdown.onChanged?.call('Hindi (हिन्दी)');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create cover letter'));
    await tester.tap(find.text('Create cover letter'));
    await tester.pump();
    expect(find.byKey(const Key('create-cover-letter-loader')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.savedCoverLetters, hasLength(1));
    final saved = repository.savedCoverLetters.single;
    expect(saved.company, 'Acme Labs');
    expect(saved.role, 'Senior Product Designer');
    expect(saved.skillToHighlight, 'UX research, Prototyping');
    expect(saved.language, 'Hindi (हिन्दी)');
    expect(_textFieldByLabel('Cover letter content'), findsOneWidget);
    expect(saved.content, contains('[Your Name]'));
    expect(saved.content, contains('भर्ती प्रबंधक'));
    expect(saved.content, contains('Acme Labs'));
    expect(saved.content, contains('Senior Product Designer'));
    expect(saved.content, contains('UX research और Prototyping'));
    expect(saved.content, contains('हिन्दी'));
    expect(saved.content, contains('आदरणीय भर्ती प्रबंधक,'));
    expect(saved.content, isNot(contains('Dear Hiring Manager,')));
    expect(saved.content, isNot(contains('Avery Lee')));
    expect(
      saved.content,
      isNot(
        contains(
          'This exact summary text should not be copied directly into the cover letter body.',
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('preview-cover-letter-button')),
    );
    await tester.tap(find.byKey(const Key('preview-cover-letter-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('cover-letter-preview-screen')),
      findsOneWidget,
    );
    expect(find.textContaining('आदरणीय भर्ती प्रबंधक,'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Template'), findsOneWidget);

    await tester.tap(find.text('Template'));
    await tester.pumpAndSettle();

    final minimalLetterTile = find.byKey(
      const Key('template-tile-minimal-letter'),
    );
    await tester.ensureVisible(minimalLetterTile);
    await tester.tap(minimalLetterTile);
    await tester.pumpAndSettle();

    expect(viewModel.coverLetter.template, CoverLetterTemplate.minimalLetter);
  });
}
