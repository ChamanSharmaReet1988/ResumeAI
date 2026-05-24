import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/premium_purchase_service.dart';

void main() {
  test('consumePremiumWelcomePending is one-shot', () {
    final prefs = AppPreferences.inMemory();
    final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

    expect(service.consumePremiumWelcomePending(), isFalse);
    expect(service.consumePremiumWelcomePending(), isFalse);
  });

  test('purchase_stream grant persists premium and queues welcome once', () async {
    final prefs = AppPreferences.inMemory(isPremium: false);
    final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

    await service.applyEntitlementForTest(
      true,
      reason: 'purchase_stream_purchased',
    );

    expect(prefs.isPremium, isTrue);
    expect(service.isPremium, isTrue);
    expect(service.hasPremiumWelcomePending, isTrue);
    expect(service.consumePremiumWelcomePending(), isTrue);
    expect(service.consumePremiumWelcomePending(), isFalse);
  });

  test('silent verify does not queue welcome dialog', () async {
    final prefs = AppPreferences.inMemory(isPremium: false);
    final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

    await service.applyEntitlementForTest(true, reason: 'app_launch');

    expect(prefs.isPremium, isTrue);
    expect(service.hasPremiumWelcomePending, isFalse);
  });
}
