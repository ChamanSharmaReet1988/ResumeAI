import 'package:flutter/foundation.dart';

/// Platform monetization:
/// - Android: free + ads (no IAP)
/// - iOS: Pro subscription (IAP) + ads
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

  static bool get isIapEnabled => !isAndroidAdsModel;

  /// Banners + interstitials on Android and iOS.
  static bool get showsAds {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Preview top banner exists on Android only (no iOS preview banner unit).
  static bool get showsPreviewBanner => isAndroidAdsModel;

  /// Home top banner exists on iOS only.
  static bool get showsHomeBanner => isIos;

  /// Settings top banner on Android and iOS.
  static bool get showsSettingsBanner => showsAds;
}
