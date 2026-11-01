import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../core/config/google_sign_in_config.dart';
import '../core/services/android_ads_service.dart';
import '../core/services/deep_link_service.dart';
import '../core/services/firebase_app_services.dart';
import '../core/services/premium_purchase_service.dart';

/// Startup work that talks to a platform plugin can hang rather than throw —
/// StoreKit and Firebase both can, and from Xcode on a simulator they often
/// do. These steps run after the first frame so they cannot freeze splash.
Future<T?> bootstrapStep<T>(
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

/// AdMob, Firebase, billing, Google Sign-In, and deep links — after first frame.
Future<FirebaseAppServices> startDeferredPlatformServices({
  required PremiumPurchaseService premiumPurchaseService,
  required DeepLinkService deepLinkService,
}) async {
  if (!kIsWeb) {
    await bootstrapStep(
      'GoogleSignIn.initialize',
      () => GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? GoogleSignInConfig.iosClientId
            : null,
        serverClientId: GoogleSignInConfig.androidServerClientId,
      ),
    );
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // Targeted fallback for real-device product lookup failures from StoreKit2.
    await bootstrapStep(
      'StoreKit1 fallback',
      // ignore: deprecated_member_use
      () => InAppPurchaseStoreKitPlatform.enableStoreKit1(),
    );
    InAppPurchaseStoreKitPlatform.registerPlatform();
  }
  await bootstrapStep(
    'PremiumPurchaseService.initialize',
    premiumPurchaseService.initialize,
    timeout: const Duration(seconds: 8),
  );
  await bootstrapStep(
    'AndroidAdsService.initialize',
    AndroidAdsService.initialize,
  );

  final firebaseServices =
      await bootstrapStep(
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
  await bootstrapStep(
    'DeepLinkService.start',
    deepLinkService.start,
    timeout: const Duration(seconds: 4),
  );
  return firebaseServices;
}
