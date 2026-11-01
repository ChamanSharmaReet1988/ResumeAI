import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'platform_monetization.dart';

/// AdMob config for Android + iOS. No-ops on web.
abstract final class AndroidAdsConfig {
  static const androidAppId = 'ca-app-pub-4326780099537551~1798944583';
  static const iosAppId = 'ca-app-pub-4326780099537551~5871431827';

  static const _debugInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _debugBanner = 'ca-app-pub-3940256099942544/6300978111';

  /// Debug builds use Google’s sample ad units so the live AdMob account is not
  /// filled with test traffic. Release builds always use production units.
  static const useProductionAdUnitsInDebug = false;

  // —— Android production units ——
  static const androidPreviewInterstitialAdUnitId =
      'ca-app-pub-4326780099537551/2864614244';
  static const androidTemplatesInterstitialAdUnitId =
      'ca-app-pub-4326780099537551/3087154686';
  static const androidTemplatesBannerAdUnitId =
      'ca-app-pub-4326780099537551/6374346359';
  static const androidSettingsBannerAdUnitId =
      'ca-app-pub-4326780099537551/7581767617';

  /// Android Home banner.
  static const androidHomeBannerAdUnitId =
      'ca-app-pub-4326780099537551/1505163054';

  /// Android AI Resume banner.
  static const androidAiResumeBannerAdUnitId =
      'ca-app-pub-4326780099537551/8215709938';

  // —— iOS production units ——
  static const iosPreviewInterstitialAdUnitId =
      'ca-app-pub-4326780099537551/1652347183';
  static const iosTemplatesInterstitialAdUnitId =
      'ca-app-pub-4326780099537551/3712523993';
  static const iosHomeBannerAdUnitId = 'ca-app-pub-4326780099537551/5755243724';
  static const iosTemplatesBannerAdUnitId =
      'ca-app-pub-4326780099537551/7998263686';
  static const iosSettingsBannerAdUnitId =
      'ca-app-pub-4326780099537551/1695016111';

  /// Preview / create-resume full-screen ads (not used after share).
  static const previewInterstitialEveryNthOpen = 4;

  /// Templates tab: full-screen ad on every 2nd visit.
  static const templatesInterstitialEveryNthOpen = 2;

  static int interstitialEveryNthOpenFor(AndroidAdPlacement placement) {
    return switch (placement) {
      AndroidAdPlacement.preview => previewInterstitialEveryNthOpen,
      AndroidAdPlacement.templates => templatesInterstitialEveryNthOpen,
      AndroidAdPlacement.createResume => 1,
    };
  }

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
        AndroidBannerPlacement.settings => iosSettingsBannerAdUnitId,
        // No iOS AI Resume banner unit yet.
        AndroidBannerPlacement.aiResume => iosTemplatesBannerAdUnitId,
      };
    }
    return switch (placement) {
      AndroidBannerPlacement.home => androidHomeBannerAdUnitId,
      AndroidBannerPlacement.templates => androidTemplatesBannerAdUnitId,
      AndroidBannerPlacement.settings => androidSettingsBannerAdUnitId,
      AndroidBannerPlacement.aiResume => androidAiResumeBannerAdUnitId,
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
        // No third production unit; reuse the preview interstitial.
        AndroidAdPlacement.createResume => iosPreviewInterstitialAdUnitId,
      };
    }
    return switch (placement) {
      AndroidAdPlacement.templates => androidTemplatesInterstitialAdUnitId,
      AndroidAdPlacement.preview => androidPreviewInterstitialAdUnitId,
      AndroidAdPlacement.createResume => androidPreviewInterstitialAdUnitId,
    };
  }

  /// First visit to the resume create screen is free; every visit after that
  /// shows a full-screen ad.
  static bool shouldShowCreateResumeInterstitial(int openCount) =>
      openCount >= 2;

  /// New installs see no full-screen ads for this long (banners still show).
  static const newUserGracePeriod = Duration(days: 3);

  /// Full-screen ads shown at most this many times per app session.
  static const maxInterstitialsPerSession = 1;

  /// Whether a full-screen ad may show now, before the per-placement rules.
  static bool allowsInterstitial({
    required DateTime now,
    required DateTime? firstLaunchAt,
    required int shownThisSession,
  }) {
    if (shownThisSession >= maxInterstitialsPerSession) {
      return false;
    }
    if (firstLaunchAt != null &&
        now.difference(firstLaunchAt) < newUserGracePeriod) {
      return false;
    }
    return true;
  }
}

/// Where an interstitial may be requested from.
enum AndroidAdPlacement { templates, preview, createResume }

/// Banner placements.
enum AndroidBannerPlacement { home, templates, settings, aiResume }

class AndroidAdsService {
  AndroidAdsService._();

  static bool _initialized = false;

  /// When true (iOS Pro), banners and interstitials are suppressed.
  static bool Function()? isPremiumActive;

  /// Install time for the new-user grace period; null means no grace.
  static DateTime? firstLaunchAt;

  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static int _interstitialsShownThisSession = 0;
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
    firstLaunchAt = null;
    clock = DateTime.now;
    _interstitialsShownThisSession = 0;
    for (final placement in AndroidAdPlacement.values) {
      _interstitials[placement]?.dispose();
      _interstitials[placement] = null;
      _isLoadingInterstitial[placement] = false;
      _openCounts[placement] = 0;
    }
  }

  static bool get _adsSuppressedByPremium => isPremiumActive?.call() ?? false;

  @visibleForTesting
  static int get interstitialsShownThisSession =>
      _interstitialsShownThisSession;

  /// Grace period and per-session cap, shared by every full-screen placement.
  @visibleForTesting
  static bool get interstitialAllowedNow => AndroidAdsConfig.allowsInterstitial(
    now: clock(),
    firstLaunchAt: firstLaunchAt,
    shownThisSession: _interstitialsShownThisSession,
  );

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

  /// Records an open for [placement] and shows an interstitial on every Nth
  /// open (templates tab: 2nd).
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
    final everyNth = AndroidAdsConfig.interstitialEveryNthOpenFor(placement);
    final shouldShow = nextCount % everyNth == 0;
    if (!shouldShow || !interstitialAllowedNow) {
      unawaitedLoadInterstitial(placement);
      return;
    }

    final ad = _interstitials[placement];
    if (ad == null) {
      unawaitedLoadInterstitial(placement);
      return;
    }
    _interstitials[placement] = null;
    _interstitialsShownThisSession += 1;
    await ad.show();
  }

  /// Resume create screen: skip the first visit, then show a full-screen ad
  /// on every later visit. Waits until the ad is dismissed.
  static Future<void> showCreateResumeInterstitial() async {
    if (!PlatformMonetization.showsAds ||
        !_initialized ||
        _adsSuppressedByPremium) {
      return;
    }

    const placement = AndroidAdPlacement.createResume;
    final nextCount = (_openCounts[placement] ?? 0) + 1;
    _openCounts[placement] = nextCount;
    if (!AndroidAdsConfig.shouldShowCreateResumeInterstitial(nextCount) ||
        !interstitialAllowedNow) {
      unawaitedLoadInterstitial(placement);
      return;
    }

    final ad = _interstitials[placement];
    if (ad == null) {
      unawaitedLoadInterstitial(placement);
      return;
    }
    _interstitials[placement] = null;
    _interstitialsShownThisSession += 1;
    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaitedLoadInterstitial(placement);
        if (!dismissed.isCompleted) {
          dismissed.complete();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        unawaitedLoadInterstitial(placement);
        if (!dismissed.isCompleted) {
          dismissed.complete();
        }
      },
    );
    try {
      await ad.show();
    } catch (_) {
      ad.dispose();
      unawaitedLoadInterstitial(placement);
      return;
    }
    await dismissed.future;
  }
}
