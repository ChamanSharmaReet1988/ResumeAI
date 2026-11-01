import 'package:flutter/foundation.dart';

/// Platform monetization:
/// - Android and iOS: ads by default; $1.99 one-time Pro removes ads.
///   Templates, AI Resume, and backup stay free.
abstract final class PlatformMonetization {
  static bool get isAndroidAdsModel {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static bool get isIos {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// One-time Pro is offered on Android and iOS.
  static bool get isIapEnabled {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Banners + interstitials on Android and iOS. Disabled in debug builds.
  static bool get showsAds {
    if (kIsWeb || kDebugMode) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Home top banner on Android and iOS.
  static bool get showsHomeBanner => showsAds;

  /// Settings top banner on Android and iOS.
  static bool get showsSettingsBanner => showsAds;

  /// AI Resume top banner on Android and iOS. Hidden for Pro (no ads).
  /// Follows [showsAds] so debug builds stay ad-free.
  static bool get showsAiResumeBanner => showsAds;
}
