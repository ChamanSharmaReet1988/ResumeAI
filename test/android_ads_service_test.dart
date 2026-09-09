import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/android_ads_service.dart';

void main() {
  setUp(AndroidAdsService.resetForTest);

  test('shows interstitial on every 3rd open', () {
    expect(AndroidAdsConfig.interstitialShowEveryNthOpen, 3);
    for (var open = 1; open <= 9; open++) {
      final shouldShow =
          open % AndroidAdsConfig.interstitialShowEveryNthOpen == 0;
      expect(shouldShow, open % 3 == 0, reason: 'open $open');
    }
  });

  test('templates and preview placements are independent', () {
    var templates = 0;
    var preview = 0;

    bool bump(AndroidAdPlacement placement) {
      if (placement == AndroidAdPlacement.templates) {
        templates += 1;
        return templates % AndroidAdsConfig.interstitialShowEveryNthOpen == 0;
      }
      preview += 1;
      return preview % AndroidAdsConfig.interstitialShowEveryNthOpen == 0;
    }

    expect(bump(AndroidAdPlacement.templates), isFalse); // 1
    expect(bump(AndroidAdPlacement.templates), isFalse); // 2
    expect(bump(AndroidAdPlacement.preview), isFalse); // preview 1
    expect(bump(AndroidAdPlacement.templates), isTrue); // templates 3
    expect(bump(AndroidAdPlacement.preview), isFalse); // preview 2
    expect(bump(AndroidAdPlacement.preview), isTrue); // preview 3
  });

  test('open counts start at zero after reset', () {
    expect(AndroidAdsService.openCountFor(AndroidAdPlacement.templates), 0);
    expect(AndroidAdsService.openCountFor(AndroidAdPlacement.preview), 0);
  });
}
