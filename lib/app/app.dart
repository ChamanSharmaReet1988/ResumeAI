import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/app_localizations.dart';

import '../core/services/ai_api_key_store.dart';
import '../core/services/ai_resume_coordinator.dart';
import '../core/services/apple_foundation_ai_service.dart';
import '../core/services/app_preferences.dart';
import '../core/services/cloud_ai_resume_service.dart';
import '../core/services/premium_purchase_service.dart';
import '../core/services/firebase_app_services.dart';
import '../core/services/google_drive_resume_service.dart';
import '../core/services/icloud_resume_service.dart';
import '../core/services/job_search_service.dart';
import '../core/services/resume_import_service.dart';
import '../core/services/resume_services.dart';
import '../features/shared/view_models.dart';
import '../features/shell/app_shell.dart';
import 'app_theme.dart';
import 'premium_subscription_watcher.dart';
import 'vertical_edge_bounce.dart';

class ResumeApp extends StatelessWidget {
  const ResumeApp({
    super.key,
    required this.repository,
    required this.appPreferences,
    required this.premiumPurchaseService,
    required this.firebaseServices,
    required this.googleDriveResumeService,
    this.aiApiKeyStore,
  });

  final ResumeRepository repository;
  final AppPreferences appPreferences;
  final PremiumPurchaseService premiumPurchaseService;
  final FirebaseAppServices firebaseServices;
  final GoogleDriveResumeService googleDriveResumeService;
  final AiApiKeyStore? aiApiKeyStore;

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;

    return MultiProvider(
      providers: [
        Provider<ResumeRepository>.value(value: repository),
        Provider<AppPreferences>.value(value: appPreferences),
        ChangeNotifierProvider<PremiumPurchaseService>.value(
          value: premiumPurchaseService,
        ),
        Provider<FirebaseAppServices>.value(value: firebaseServices),
        Provider<ICloudResumeService>(
          create: (_) => const MethodChannelICloudResumeService(),
        ),
        Provider<GoogleDriveResumeService>.value(
          value: googleDriveResumeService,
        ),
        Provider<ResumeImportService>(
          create: (_) => const ResumeImportService(),
        ),
        Provider<JobSearchService>(create: (_) => JobSearchService()),
        Provider<LocalAiResumeService>(create: (_) => LocalAiResumeService()),
        Provider<CloudAiResumeService>(create: (_) => CloudAiResumeService()),
        Provider<AppleFoundationAiService>(
          create: (_) => AppleFoundationAiService(),
        ),
        ChangeNotifierProvider<AiApiKeyStore>(
          create: (_) => (aiApiKeyStore ?? AiApiKeyStore())..load(),
        ),
        Provider<AiResumeCoordinator>(
          create: (context) => AiResumeCoordinator(
            apiKeyStore: context.read<AiApiKeyStore>(),
            localAi: context.read<LocalAiResumeService>(),
            cloudAi: context.read<CloudAiResumeService>(),
            appleAi: context.read<AppleFoundationAiService>(),
          ),
        ),
        Provider<ResumePdfService>(create: (_) => ResumePdfService()),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(preferences: appPreferences),
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
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            navigatorObservers: [
              if (firebaseServices.analyticsObserver != null)
                firebaseServices.analyticsObserver!,
            ],
            scrollBehavior: const VerticalEdgeBounceScrollBehavior(),
            themeMode: settings.themeMode,
            theme: AppTheme.lightTheme(platform),
            darkTheme: AppTheme.darkTheme(platform),
            locale: settings.materialLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeListResolutionCallback: (locales, supported) {
              for (final locale in locales ?? const <Locale>[]) {
                for (final supportedLocale in supported) {
                  if (supportedLocale.languageCode != locale.languageCode) {
                    continue;
                  }
                  if (supportedLocale.countryCode == null ||
                      supportedLocale.countryCode!.isEmpty ||
                      supportedLocale.countryCode == locale.countryCode) {
                    return supportedLocale;
                  }
                }
                if (locale.languageCode == 'pt') {
                  return const Locale('pt');
                }
              }
              return const Locale('en');
            },
            home: const PremiumSubscriptionWatcher(
              child: AppShell(),
            ),
          );
        },
      ),
    );
  }
}
