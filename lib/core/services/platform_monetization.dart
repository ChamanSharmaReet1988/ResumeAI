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

  /// Master switch for banners and interstitials. Ads are off on every
  /// platform for now; Pro unlocks premium templates instead. Set to true to
  /// bring ads back (they stay disabled in debug builds either way).
  static const adsEnabled = false;

  /// Android banners only, on the AdMob account in [AndroidAdsConfig]. Full-
  /// screen ads stay behind [adsEnabled].
  static const androidBannersEnabled = true;

  /// Android full-screen ads, on the same account as the banners. iOS stays
  /// behind [adsEnabled].
  static const androidInterstitialsEnabled = true;

  static bool get showsAndroidInterstitials =>
      showsAds ||
      (androidInterstitialsEnabled && !kDebugMode && isAndroidAdsModel);

  /// Banners + interstitials on Android and iOS. Disabled in debug builds.
  static bool get showsAds {
    if (!adsEnabled || kIsWeb || kDebugMode) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Banners: wherever [showsAds] is on, and on Android with
  /// [androidBannersEnabled]. Disabled in debug builds.
  static bool get showsBanners {
    if (showsAds) {
      return true;
    }
    return androidBannersEnabled && !kDebugMode && isAndroidAdsModel;
  }

  /// Home top banner. Hidden for Pro (no ads).
  static bool get showsHomeBanner => showsBanners;

  /// Settings top banner. Hidden for Pro (no ads).
  static bool get showsSettingsBanner => showsBanners;

  /// AI Resume top banner. Hidden for Pro (no ads).
  static bool get showsAiResumeBanner => showsBanners;
}
