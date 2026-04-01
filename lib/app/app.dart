import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/resume_import_service.dart';
import '../core/services/resume_services.dart';
import '../features/shared/view_models.dart';
import '../features/shell/app_shell.dart';
import 'app_theme.dart';

class ResumeApp extends StatelessWidget {
  const ResumeApp({super.key, required this.repository});

  final ResumeRepository repository;

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;

    return MultiProvider(
      providers: [
        Provider<ResumeRepository>.value(value: repository),
        Provider<ResumeImportService>(
          create: (_) => const ResumeImportService(),
        ),
        Provider<LocalAiResumeService>(create: (_) => LocalAiResumeService()),
        Provider<ResumePdfService>(create: (_) => ResumePdfService()),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(),
        ),
        ChangeNotifierProvider<ResumeLibraryViewModel>(
          create: (_) =>
              ResumeLibraryViewModel(repository: repository)..loadResumes(),
        ),
        ChangeNotifierProvider<CoverLetterLibraryViewModel>(
          create: (_) =>
              CoverLetterLibraryViewModel(repository: repository)
                ..loadCoverLetters(),
        ),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'ResumeAI',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppTheme.lightTheme(platform),
            darkTheme: AppTheme.darkTheme(platform),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
