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
    'templates screen switches between resume and cover letter template grids',
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
      expect(childrenDelegate.childCount, 3);
      expect(
        find.byKey(const Key('template-segmented-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-dark-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-profile-sidebar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-classic-sidebar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-executive-note')),
        findsNothing,
      );

      final profileSidebarTile = find.byKey(
        const Key('template-tile-profile-sidebar'),
      );
      await tester.ensureVisible(profileSidebarTile);
      await tester.tap(profileSidebarTile);
      await tester.pumpAndSettle();

      expect(find.text('Profile Sidebar'), findsOneWidget);
      expect(
        find.byKey(const Key('template-detail-preview-profile-sidebar')),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('template-segmented-button')),
      );
      await tester.tap(find.text('Cover Letter'));
      await tester.pumpAndSettle();

      final coverLetterGrid = tester.widget<GridView>(
        find.byKey(const Key('template-grid')),
      );
      final coverLetterChildrenDelegate =
          coverLetterGrid.childrenDelegate as SliverChildBuilderDelegate;
      expect(coverLetterChildrenDelegate.childCount, 3);
      expect(
        find.byKey(const Key('template-image-executive-note')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-minimal-letter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('template-image-sidebar-letter')),
        findsOneWidget,
      );

      final sidebarLetterTile = find.byKey(
        const Key('template-tile-sidebar-letter'),
      );
      await tester.ensureVisible(sidebarLetterTile);
      await tester.tap(sidebarLetterTile);
      await tester.pumpAndSettle();

      expect(find.text('Sidebar Letter'), findsOneWidget);
      expect(
        find.byKey(const Key('template-detail-preview-sidebar-letter')),
        findsOneWidget,
      );
    },
  );
}

void _noop() {}
