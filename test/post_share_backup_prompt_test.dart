import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/features/shared/post_share_backup_prompt.dart';
import 'package:resume_app/l10n/app_localizations.dart';

void main() {
  testWidgets('shows drive backup prompt once then never again', (tester) async {
    final prefs = AppPreferences.inMemory();

    Future<void> pumpPrompt() {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Provider<AppPreferences>.value(
            value: prefs,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => showPostShareBackupPromptIfNeeded(context),
                      child: const Text('share'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    await pumpPrompt();
    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();

    expect(find.text('Keep your resume safe'), findsOneWidget);
    expect(
      find.textContaining('Google Drive'),
      findsWidgets,
    );

    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();
    expect(prefs.postShareBackupPromptDismissed, isTrue);

    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your resume safe'), findsNothing);
  });

  testWidgets('skips prompt when drive auto-sync already on', (tester) async {
    final prefs = AppPreferences.inMemory(googleDriveAutoSyncEnabled: true);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Provider<AppPreferences>.value(
          value: prefs,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showPostShareBackupPromptIfNeeded(context),
                    child: const Text('share'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your resume safe'), findsNothing);
    expect(prefs.postShareBackupPromptDismissed, isTrue);
  });
}
