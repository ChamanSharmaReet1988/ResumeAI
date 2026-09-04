import 'package:flutter/foundation.dart';

/// Platform monetization split:
/// - Android: everything free + ads (no IAP)
/// - iOS: Pro subscription (IAP), no ads
abstract final class PlatformMonetization {
  static bool get isAndroidAdsModel {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static bool get isIapEnabled => !isAndroidAdsModel;

  static bool get showsAds => isAndroidAdsModel;
}
