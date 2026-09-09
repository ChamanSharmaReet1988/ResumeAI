import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'platform_monetization.dart';

/// AdMob config for Android + iOS. No-ops on web.
abstract final class AndroidAdsConfig {
  static const androidAppId = 'ca-app-pub-4326780099537551~1798944583';
  static const iosAppId = 'ca-app-pub-4326780099537551~5871431827';

  static const _debugInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const _debugBanner = 'ca-app-pub-3940256099942544/6300978111';

  /// Temporary: use real AdMob units in debug so ads can be verified on device.
  /// Set back to `false` before release if you prefer Google test units in debug.
  static const useProductionAdUnitsInDebug = true;

  // —— Android production units ——
  static const androidPreviewInterstitialAdUnitId =
      'ca-app-pub-4326780099537551/2864614244';
  static const androidTemplatesInterstitialAdUnitId =
      'ca-app-pub-4326780099537551/3087154686';
  static const androidTemplatesBannerAdUnitId =
      'ca-app-pub-4326780099537551/1505163054';
  static const androidPreviewBannerAdUnitId =
      'ca-app-pub-4326780099537551/6374346359';

  // —— iOS production units ——
  static const iosPreviewInterstitialAdUnitId =
      'ca-app-pub-4326780099537551/1652347183';
  static const iosTemplatesInterstitialAdUnitId =
      'ca-app-pub-4326780099537551/3712523993';
  static const iosHomeBannerAdUnitId =
      'ca-app-pub-4326780099537551/5755243724';
  static const iosTemplatesBannerAdUnitId =
      'ca-app-pub-4326780099537551/7998263686';

  /// Show an interstitial on every Nth open of a placement (templates / preview).
  static const interstitialShowEveryNthOpen = 3;

  static bool get _useDebugTestUnits =>
      kDebugMode && !useProductionAdUnitsInDebug;

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String bannerAdUnitIdFor(AndroidBannerPlacement placement) {
    if (_useDebugTestUnits) {
      return _debugBanner;
    }
    if (_isIos) {
      return switch (placement) {
        AndroidBannerPlacement.home => iosHomeBannerAdUnitId,
        AndroidBannerPlacement.templates => iosTemplatesBannerAdUnitId,
        // No iOS preview banner unit — callers should not request it.
        AndroidBannerPlacement.preview => iosTemplatesBannerAdUnitId,
      };
    }
    return switch (placement) {
      AndroidBannerPlacement.templates => androidTemplatesBannerAdUnitId,
      AndroidBannerPlacement.preview => androidPreviewBannerAdUnitId,
      // No Android home banner unit configured.
      AndroidBannerPlacement.home => androidTemplatesBannerAdUnitId,
    };
  }

  static String interstitialAdUnitIdFor(AndroidAdPlacement placement) {
    if (_useDebugTestUnits) {
      return _debugInterstitial;
    }
    if (_isIos) {
      return switch (placement) {
        AndroidAdPlacement.templates => iosTemplatesInterstitialAdUnitId,
        AndroidAdPlacement.preview => iosPreviewInterstitialAdUnitId,
      };
    }
    return switch (placement) {
      AndroidAdPlacement.templates => androidTemplatesInterstitialAdUnitId,
      AndroidAdPlacement.preview => androidPreviewInterstitialAdUnitId,
    };
  }
}

/// Where an interstitial may be requested from.
enum AndroidAdPlacement {
  templates,
  preview,
}

/// Banner placements.
enum AndroidBannerPlacement {
  home,
  templates,
  preview,
}

class AndroidAdsService {
  AndroidAdsService._();

  static bool _initialized = false;
  /// When true (iOS Pro), banners and interstitials are suppressed.
  static bool Function()? isPremiumActive;
  static final Map<AndroidAdPlacement, InterstitialAd?> _interstitials = {
    for (final placement in AndroidAdPlacement.values) placement: null,
  };
  static final Map<AndroidAdPlacement, bool> _isLoadingInterstitial = {
    for (final placement in AndroidAdPlacement.values) placement: false,
  };
  static final Map<AndroidAdPlacement, int> _openCounts = {
    for (final placement in AndroidAdPlacement.values) placement: 0,
  };

  static bool get isInitialized => _initialized;

  @visibleForTesting
  static int openCountFor(AndroidAdPlacement placement) =>
      _openCounts[placement] ?? 0;

  @visibleForTesting
  static void resetForTest() {
    _initialized = false;
    for (final placement in AndroidAdPlacement.values) {
      _interstitials[placement]?.dispose();
      _interstitials[placement] = null;
      _isLoadingInterstitial[placement] = false;
      _openCounts[placement] = 0;
    }
  }

  static bool get _adsSuppressedByPremium => isPremiumActive?.call() ?? false;

  static Future<void> initialize() async {
    if (!PlatformMonetization.showsAds || _initialized) {
      return;
    }
    await MobileAds.instance.initialize();
    _initialized = true;
    if (_adsSuppressedByPremium) {
      return;
    }
    for (final placement in AndroidAdPlacement.values) {
      unawaitedLoadInterstitial(placement);
    }
  }

  static void unawaitedLoadInterstitial([AndroidAdPlacement? placement]) {
    if (!PlatformMonetization.showsAds ||
        !_initialized ||
        _adsSuppressedByPremium) {
      return;
    }
    if (placement != null) {
      _loadInterstitial(placement);
      return;
    }
    for (final value in AndroidAdPlacement.values) {
      _loadInterstitial(value);
    }
  }

  static void _loadInterstitial(AndroidAdPlacement placement) {
    if (_interstitials[placement] != null ||
        _isLoadingInterstitial[placement] == true) {
      return;
    }
    _isLoadingInterstitial[placement] = true;
    InterstitialAd.load(
      adUnitId: AndroidAdsConfig.interstitialAdUnitIdFor(placement),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitials[placement] = ad;
          _isLoadingInterstitial[placement] = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitials[placement] = null;
              unawaitedLoadInterstitial(placement);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitials[placement] = null;
              unawaitedLoadInterstitial(placement);
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isLoadingInterstitial[placement] = false;
          _interstitials[placement] = null;
        },
      ),
    );
  }

  /// Records an open for [placement] and shows an interstitial on every
  /// [AndroidAdsConfig.interstitialShowEveryNthOpen]th open (3rd, 6th, …).
  static Future<void> showInterstitialIfReady({
    required AndroidAdPlacement placement,
  }) async {
    if (!PlatformMonetization.showsAds ||
        !_initialized ||
        _adsSuppressedByPremium) {
      return;
    }

    final nextCount = (_openCounts[placement] ?? 0) + 1;
    _openCounts[placement] = nextCount;
    final shouldShow =
        nextCount % AndroidAdsConfig.interstitialShowEveryNthOpen == 0;
    if (!shouldShow) {
      unawaitedLoadInterstitial(placement);
      return;
    }

    final ad = _interstitials[placement];
    if (ad == null) {
      unawaitedLoadInterstitial(placement);
      return;
    }
    _interstitials[placement] = null;
    await ad.show();
  }
}
