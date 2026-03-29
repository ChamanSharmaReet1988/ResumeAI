import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/shared/view_models.dart';
import 'package:resume_app/features/templates/templates_screen.dart';

class _FakeTemplatesRepository implements ResumeRepository {
  @override
  Future<void> deleteCoverLetter(String id) async {}

  @override
  Future<void> deleteResume(String id) async {}

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => const [];

  @override
  Future<List<ResumeData>> loadResumes() async => const [];

  @override
  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {}

  @override
  Future<void> upsertResume(ResumeData resume) async {}
}

void main() {
  testWidgets(
    'templates screen uses a two-column grid and opens template preview on a new screen',
    (tester) async {
      final library = ResumeLibraryViewModel(
        repository: _FakeTemplatesRepository(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ResumeLibraryViewModel>.value(
          value: library,
          child: const MaterialApp(
            home: Scaffold(body: TemplatesScreen(onCreateResume: _noop)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(
        find.byKey(const Key('template-grid')),
      );
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      final childrenDelegate =
          gridView.childrenDelegate as SliverChildBuilderDelegate;

      expect(delegate.crossAxisCount, 2);
      expect(childrenDelegate.childCount, 6);
      expect(
        find.byKey(const Key('template-image-dark-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-centered-classic')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-profile-sidebar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-copper-serif')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-split-banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-monogram-sidebar')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('selected-template-preview')), findsNothing);

      final splitBannerTile = find.byKey(
        const Key('template-tile-split-banner'),
      );
      await tester.ensureVisible(splitBannerTile);
      await tester.tap(splitBannerTile);
      await tester.pumpAndSettle();

      expect(find.text('Split Banner'), findsOneWidget);
      expect(
        find.byKey(const Key('template-detail-preview-split-banner')),
        findsOneWidget,
      );
    },
  );
}

void _noop() {}
