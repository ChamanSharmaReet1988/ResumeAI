import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_theme.dart';
import 'core/services/android_ads_service.dart';
import 'core/services/app_preferences.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/premium_purchase_service.dart';
import 'core/services/firebase_app_services.dart';
import 'core/services/google_drive_resume_service.dart';
import 'core/services/icloud_resume_service.dart';
import 'core/services/platform_monetization.dart';
import 'core/services/resume_services.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(
          AppTheme.overlayStyleFor(Brightness.light),
        );
      }
      final repository = await ResumeRepository.create();
      final appPreferences = await AppPreferences.open();
      final googleDriveResumeService = GoogleDriveResumeService();
      final premiumPurchaseService = PremiumPurchaseService(
        appPreferences: appPreferences,
        enableStore: PlatformMonetization.isIapEnabled,
      );
      repository.configureGoogleDriveAutoSync(
        appPreferences: appPreferences,
        service: googleDriveResumeService,
        hasPremium: () => premiumPurchaseService.isPremium,
      );
      repository.configureICloudAutoSync(
        appPreferences: appPreferences,
        service: const MethodChannelICloudResumeService(),
        hasPremium: () => premiumPurchaseService.isPremium,
      );
      AndroidAdsService.isPremiumActive = () =>
          premiumPurchaseService.isPremium;
      AndroidAdsService.firstLaunchAt = appPreferences.firstLaunchAt;

      runApp(
        ResumeApp(
          repository: repository,
          appPreferences: appPreferences,
          premiumPurchaseService: premiumPurchaseService,
          firebaseServices: FirebaseAppServices.disabled(),
          googleDriveResumeService: googleDriveResumeService,
          deepLinkService: DeepLinkService(
            firebase: FirebaseAppServices.disabled(),
          ),
          deferPlatformStartup: true,
        ),
      );
    },
    (error, stack) {
      // Zone errors after Firebase init are forwarded to Crashlytics.
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {
        if (kDebugMode) {
          debugPrint('Uncaught zone error: $error\n$stack');
        }
      }
    },
  );
}
