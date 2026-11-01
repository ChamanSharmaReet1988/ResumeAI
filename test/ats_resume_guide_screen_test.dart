import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/features/ai/ats_resume_guide_screen.dart';
import 'package:resume_app/l10n/app_localizations.dart';

void main() {
  testWidgets('ATS guide shows every section with bullets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AtsResumeGuideScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ATS-Friendly Resume Guide'), findsOneWidget);

    const titles = [
      '1. What an ATS really does',
      '2. Use a layout the ATS can read',
      '3. Use standard section headings',
      '4. Contact details, job titles, and dates',
      '5. Match keywords from the job post',
      '6. Write bullets that show results',
      '7. Make your Skills section searchable',
      '8. Save and send the right file',
      '9. Check before you apply',
      '10. Do it faster in this app',
    ];
    final list = find.byKey(const Key('ats-guide-list'));
    for (final title in titles) {
      await tester.scrollUntilVisible(
        find.text(title),
        300,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(title), findsOneWidget);
    }
    // Bullet markers are rendered separately from the bullet text.
    expect(find.text('•'), findsWidgets);
  });
}
