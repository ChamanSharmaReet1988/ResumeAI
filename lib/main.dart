import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'app/app.dart';
import 'core/config/google_sign_in_config.dart';
import 'core/services/android_ads_service.dart';
import 'core/services/app_preferences.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/premium_purchase_service.dart';
import 'core/services/firebase_app_services.dart';
import 'core/services/google_drive_resume_service.dart';
import 'core/services/icloud_resume_service.dart';
import 'core/services/platform_monetization.dart';
import 'core/services/resume_services.dart';

/// Startup work that talks to a platform plugin can hang rather than throw —
/// StoreKit and Firebase both can, and from Xcode on a simulator they often
/// do. Nothing before [runApp] may block the first frame forever, so every
/// such step runs through here and gives up after [timeout].
Future<T?> _bootstrapStep<T>(
  String label,
  Future<T> Function() run, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  try {
    return await run().timeout(timeout);
  } on TimeoutException {
    assert(() {
      debugPrint('Startup step "$label" timed out after ${timeout.inSeconds}s; '
          'continuing without it.');
      return true;
    }());
    return null;
  } catch (error, stackTrace) {
    assert(() {
      debugPrint('Startup step "$label" failed: $error\n$stackTrace');
      return true;
    }());
    return null;
  }
}

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0x00000000),
          systemNavigationBarColor: Color(0x00000000),
          systemNavigationBarDividerColor: Color(0x00000000),
          systemNavigationBarContrastEnforced: false,
        ),
      );
    }
    if (!kIsWeb) {
      await _bootstrapStep(
        'GoogleSignIn.initialize',
        () => GoogleSignIn.instance.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? GoogleSignInConfig.iosClientId
              : null,
          serverClientId: GoogleSignInConfig.androidServerClientId,
        ),
      );
    }
    final repository = await ResumeRepository.create();
    final appPreferences = await AppPreferences.open();
    final googleDriveResumeService = GoogleDriveResumeService();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Ignore the deprecation here intentionally; this is a targeted fallback
      // for real-device product lookup failures coming from the StoreKit2 path.
      // ignore: deprecated_member_use
      await _bootstrapStep(
        'StoreKit1 fallback',
        InAppPurchaseStoreKitPlatform.enableStoreKit1,
      );
      InAppPurchaseStoreKitPlatform.registerPlatform();
    }
    final premiumPurchaseService = PremiumPurchaseService(
      appPreferences: appPreferences,
      // Android is ads + free; IAP only on iOS.
      enableStore: PlatformMonetization.isIapEnabled,
    );
    repository.configureGoogleDriveAutoSync(
      appPreferences: appPreferences,
      service: googleDriveResumeService,
      hasPremium: () =>
          PlatformMonetization.isAndroidAdsModel ||
          premiumPurchaseService.isPremium,
    );
    repository.configureICloudAutoSync(
      appPreferences: appPreferences,
      service: const MethodChannelICloudResumeService(),
      hasPremium: () =>
          PlatformMonetization.isAndroidAdsModel ||
          premiumPurchaseService.isPremium,
    );
    // Product lookup reaches the App Store; on a simulator or an unsigned
    // device it can never answer, which used to leave the app on its splash.
    await _bootstrapStep(
      'PremiumPurchaseService.initialize',
      premiumPurchaseService.initialize,
      timeout: const Duration(seconds: 8),
    );
    AndroidAdsService.isPremiumActive = () =>
        PlatformMonetization.isIapEnabled && premiumPurchaseService.isPremium;
    await _bootstrapStep(
      'AndroidAdsService.initialize',
      AndroidAdsService.initialize,
    );

    final firebaseServices =
        await _bootstrapStep(
          'FirebaseAppServices.initialize',
          FirebaseAppServices.initialize,
          timeout: const Duration(seconds: 8),
        ) ??
        FirebaseAppServices.disabled();
    if (!firebaseServices.isEnabled && kDebugMode) {
      debugPrint(
        'Firebase is disabled. Add google-services.json and '
        'GoogleService-Info.plist to enable Analytics, Crashlytics, and Remote '
        'Config.',
      );
    }
    final deepLinkService = DeepLinkService(firebase: firebaseServices);
    await _bootstrapStep(
      'DeepLinkService.start',
      deepLinkService.start,
      timeout: const Duration(seconds: 4),
    );
    runApp(
      ResumeApp(
        repository: repository,
        appPreferences: appPreferences,
        premiumPurchaseService: premiumPurchaseService,
        firebaseServices: firebaseServices,
        googleDriveResumeService: googleDriveResumeService,
        deepLinkService: deepLinkService,
      ),
    );
  }, (error, stack) {
    // Zone errors after Firebase init are forwarded to Crashlytics.
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Uncaught zone error: $error\n$stack');
      }
    }
  });
}
