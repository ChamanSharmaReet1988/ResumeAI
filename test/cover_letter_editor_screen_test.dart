import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/cover_letters/cover_letter_editor_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeCoverLetterRepository implements ResumeRepository {
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
  Future<void> upsertResume(ResumeData resume) async {}
}

Finder _textFieldByLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
    description: 'TextField with label $label',
  );
}

void main() {
  testWidgets(
    'create cover letter opens the content screen with generated content',
    (tester) async {
      final repository = _FakeCoverLetterRepository();
      final viewModel = CoverLetterEditorViewModel(
        repository: repository,
        aiService: LocalAiResumeService(),
        resumeContext: ResumeData.empty(template: ResumeTemplate.corporate)
            .copyWith(
              fullName: 'Avery Lee',
              jobTitle: 'Product Designer',
              skills: const [
                'UX research',
                'Prototyping',
                'Stakeholder management',
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
      expect(_textFieldByLabel('Language'), findsOneWidget);
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
      await tester.enterText(_textFieldByLabel('Language'), 'English');

      await tester.ensureVisible(find.text('Create cover letter'));
      await tester.tap(find.text('Create cover letter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(repository.savedCoverLetters, hasLength(1));
      final saved = repository.savedCoverLetters.single;
      expect(saved.company, 'Acme Labs');
      expect(saved.role, 'Senior Product Designer');
      expect(saved.skillToHighlight, 'UX research');
      expect(saved.language, 'English');
      expect(_textFieldByLabel('Cover letter content'), findsOneWidget);
      expect(saved.content, contains('Avery Lee'));
      expect(saved.content, contains('Hiring Manager'));
      expect(saved.content, contains('Acme Labs'));
      expect(saved.content, contains('Senior Product Designer position'));
      expect(saved.content, contains('UX research'));
      expect(saved.content, contains('English'));
      expect(saved.content, contains('Dear Hiring Manager,'));

      await tester.ensureVisible(find.byKey(const Key('preview-cover-letter-button')));
      await tester.tap(find.byKey(const Key('preview-cover-letter-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cover-letter-preview-screen')), findsOneWidget);
      expect(find.textContaining('Dear Hiring Manager,'), findsOneWidget);

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Choose template'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);

      await tester.tap(find.text('Choose template'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Minimal Letter'));
      await tester.pumpAndSettle();

      expect(viewModel.coverLetter.template, CoverLetterTemplate.minimalLetter);
    },
  );
}
