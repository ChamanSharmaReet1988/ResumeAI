import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/android_ads_service.dart';

void main() {
  setUp(AndroidAdsService.resetForTest);

  test('preview interstitial every 4th open', () {
    expect(AndroidAdsConfig.previewInterstitialEveryNthOpen, 4);
    expect(
      AndroidAdsConfig.interstitialEveryNthOpenFor(AndroidAdPlacement.preview),
      4,
    );
    for (var open = 1; open <= 12; open++) {
      final shouldShow = open % 4 == 0;
      expect(
        open % AndroidAdsConfig.previewInterstitialEveryNthOpen == 0,
        shouldShow,
        reason: 'preview open $open',
      );
    }
  });

  test('templates interstitial every 3rd open', () {
    expect(AndroidAdsConfig.templatesInterstitialEveryNthOpen, 3);
    expect(
      AndroidAdsConfig.interstitialEveryNthOpenFor(
        AndroidAdPlacement.templates,
      ),
      3,
    );
    for (var open = 1; open <= 9; open++) {
      final shouldShow = open % 3 == 0;
      expect(
        open % AndroidAdsConfig.templatesInterstitialEveryNthOpen == 0,
        shouldShow,
        reason: 'templates open $open',
      );
    }
  });

  test('templates and preview placements are independent', () {
    var templates = 0;
    var preview = 0;

    bool bump(AndroidAdPlacement placement) {
      if (placement == AndroidAdPlacement.templates) {
        templates += 1;
        return templates %
                AndroidAdsConfig.templatesInterstitialEveryNthOpen ==
            0;
      }
      preview += 1;
      return preview % AndroidAdsConfig.previewInterstitialEveryNthOpen == 0;
    }

    expect(bump(AndroidAdPlacement.templates), isFalse); // 1
    expect(bump(AndroidAdPlacement.templates), isFalse); // 2
    expect(bump(AndroidAdPlacement.preview), isFalse); // preview 1
    expect(bump(AndroidAdPlacement.templates), isTrue); // templates 3
    expect(bump(AndroidAdPlacement.preview), isFalse); // preview 2
    expect(bump(AndroidAdPlacement.preview), isFalse); // preview 3
    expect(bump(AndroidAdPlacement.preview), isTrue); // preview 4
  });

  test('open counts start at zero after reset', () {
    expect(AndroidAdsService.openCountFor(AndroidAdPlacement.templates), 0);
    expect(AndroidAdsService.openCountFor(AndroidAdPlacement.preview), 0);
  });

  test('templates interstitial unit ids are configured', () {
    expect(
      AndroidAdsConfig.androidTemplatesInterstitialAdUnitId,
      'ca-app-pub-4326780099537551/3087154686',
    );
    expect(
      AndroidAdsConfig.iosTemplatesInterstitialAdUnitId,
      'ca-app-pub-4326780099537551/3712523993',
    );
  });
}
