import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'platform_monetization.dart';

/// Android-only full-screen interstitial ads. No-ops on iOS / web.
abstract final class AndroidAdsConfig {
  static const androidAppId = 'ca-app-pub-4326780099537551~1798944583';

  static const interstitialAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-4326780099537551/2864614244';
}

class AndroidAdsService {
  AndroidAdsService._();

  static bool _initialized = false;
  static InterstitialAd? _interstitial;
  static bool _isLoadingInterstitial = false;

  static Future<void> initialize() async {
    if (!PlatformMonetization.showsAds || _initialized) {
      return;
    }
    await MobileAds.instance.initialize();
    _initialized = true;
    unawaitedLoadInterstitial();
  }

  static void unawaitedLoadInterstitial() {
    if (!PlatformMonetization.showsAds || !_initialized) {
      return;
    }
    if (_interstitial != null || _isLoadingInterstitial) {
      return;
    }
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AndroidAdsConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _isLoadingInterstitial = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              unawaitedLoadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitial = null;
              unawaitedLoadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isLoadingInterstitial = false;
          _interstitial = null;
        },
      ),
    );
  }

  /// Shows a full-screen interstitial when one is loaded.
  static Future<void> showInterstitialIfReady() async {
    if (!PlatformMonetization.showsAds || !_initialized) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      unawaitedLoadInterstitial();
      return;
    }
    _interstitial = null;
    await ad.show();
  }
}
