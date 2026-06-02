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

  test(
    'purchase_stream grant persists premium and queues welcome once',
    () async {
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
    },
  );

  test('silent verify does not unlock premium from free state', () async {
    final prefs = AppPreferences.inMemory(isPremium: false);
    final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

    await service.applyEntitlementForTest(true, reason: 'app_launch');

    expect(prefs.isPremium, isFalse);
    expect(service.hasPremiumWelcomePending, isFalse);
  });

  test(
    'fresh install does not auto-unlock premium from silent entitlement',
    () async {
      final prefs = AppPreferences.inMemory(
        isPremium: false,
        premiumManualRestoreRequired: true,
      );
      final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

      await service.applyEntitlementForTest(true, reason: 'app_launch');

      expect(prefs.isPremium, isFalse);
      expect(service.isPremium, isFalse);
      expect(prefs.premiumManualRestoreRequired, isTrue);
    },
  );

  test('manual restore clears fresh-install gate and grants premium', () async {
    final prefs = AppPreferences.inMemory(
      isPremium: false,
      premiumManualRestoreRequired: true,
    );
    final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

    await service.applyEntitlementForTest(true, reason: 'manual_restore');

    expect(prefs.isPremium, isTrue);
    expect(service.isPremium, isTrue);
    expect(prefs.premiumManualRestoreRequired, isFalse);
  });

  test(
    'non-fresh install still does not auto-unlock premium from silent entitlement',
    () async {
      final prefs = AppPreferences.inMemory(
        isPremium: false,
        premiumManualRestoreRequired: false,
      );
      final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

      await service.applyEntitlementForTest(true, reason: 'app_resume');

      expect(prefs.isPremium, isFalse);
      expect(service.isPremium, isFalse);
    },
  );

  test(
    'passive purchase stream does not auto-unlock premium from free state',
    () async {
      final prefs = AppPreferences.inMemory(isPremium: false);
      final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

      await service.applyEntitlementForTest(
        true,
        reason: 'passive_purchase_stream_restored',
      );

      expect(prefs.isPremium, isFalse);
      expect(service.isPremium, isFalse);
    },
  );

  test('silent verify keeps premium when user is already premium', () async {
    final prefs = AppPreferences.inMemory(isPremium: true);
    final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

    await service.applyEntitlementForTest(true, reason: 'app_resume');

    expect(prefs.isPremium, isTrue);
    expect(service.isPremium, isTrue);
  });

  test('first silent entitlement miss keeps existing premium access', () async {
    final prefs = AppPreferences.inMemory(isPremium: true);
    final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

    await service.applyEntitlementForTest(
      false,
      reason: 'app_resume',
      conservativeRevoke: true,
    );

    expect(prefs.isPremium, isTrue);
    expect(service.isPremium, isTrue);
    expect(prefs.premiumEntitlementMissStreak, 1);
  });

  test(
    'second consecutive silent entitlement miss revokes premium access',
    () async {
      final prefs = AppPreferences.inMemory(isPremium: true);
      final service = PremiumPurchaseService.inMemory(appPreferences: prefs);

      await service.applyEntitlementForTest(
        false,
        reason: 'app_resume',
        conservativeRevoke: true,
      );
      await service.applyEntitlementForTest(
        false,
        reason: 'app_resume',
        conservativeRevoke: true,
      );

      expect(prefs.isPremium, isFalse);
      expect(service.isPremium, isFalse);
      expect(prefs.premiumEntitlementMissStreak, 0);
    },
  );
}
