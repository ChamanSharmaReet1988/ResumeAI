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

  test('templates interstitial every 2nd open', () {
    expect(AndroidAdsConfig.templatesInterstitialEveryNthOpen, 2);
    expect(
      AndroidAdsConfig.interstitialEveryNthOpenFor(
        AndroidAdPlacement.templates,
      ),
      2,
    );
    for (var open = 1; open <= 8; open++) {
      final shouldShow = open % 2 == 0;
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
    expect(bump(AndroidAdPlacement.templates), isTrue); // 2
    expect(bump(AndroidAdPlacement.preview), isFalse); // preview 1
    expect(bump(AndroidAdPlacement.templates), isFalse); // templates 3
    expect(bump(AndroidAdPlacement.preview), isFalse); // preview 2
    expect(bump(AndroidAdPlacement.preview), isFalse); // preview 3
    expect(bump(AndroidAdPlacement.preview), isTrue); // preview 4
  });

  test('open counts start at zero after reset', () {
    expect(AndroidAdsService.openCountFor(AndroidAdPlacement.templates), 0);
    expect(AndroidAdsService.openCountFor(AndroidAdPlacement.preview), 0);
    expect(AndroidAdsService.openCountFor(AndroidAdPlacement.createResume), 0);
  });

  test('create resume interstitial skips the first visit then always shows', () {
    expect(AndroidAdsConfig.shouldShowCreateResumeInterstitial(1), isFalse);
    expect(AndroidAdsConfig.shouldShowCreateResumeInterstitial(2), isTrue);
    expect(AndroidAdsConfig.shouldShowCreateResumeInterstitial(3), isTrue);
    expect(AndroidAdsConfig.shouldShowCreateResumeInterstitial(8), isTrue);
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
