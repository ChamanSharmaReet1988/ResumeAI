import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/premium_store_messages.dart';
import 'package:resume_app/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('maps StoreKit technical errors to friendly text', () {
    expect(
      PremiumStoreMessages.friendly(
        l10n: l10n,
        rawMessage: 'StoreKit: Failed to get response from platform.',
        fallback: PremiumStoreMessages.productsUnavailable(l10n),
      ),
      PremiumStoreMessages.productsUnavailable(l10n),
    );
    expect(
      PremiumStoreMessages.friendly(
        l10n: l10n,
        rawMessage: 'SKError payment cancelled',
      ),
      l10n.premiumPurchaseCanceled,
    );
    expect(
      PremiumStoreMessages.friendly(
        l10n: l10n,
        rawMessage: 'some unknown PlatformException(code: xyz)',
      ),
      isNot(contains('PlatformException')),
    );
  });

  test('maps restore-without-purchase cases to no-subscription message', () {
    expect(
      PremiumStoreMessages.friendly(
        l10n: l10n,
        rawMessage: 'No active subscription was found for this Apple ID.',
        fallback: PremiumStoreMessages.restoreFailed(l10n),
      ),
      PremiumStoreMessages.noSubscriptionToRestore(l10n),
    );
    expect(
      PremiumStoreMessages.friendly(
        l10n: l10n,
        rawMessage: 'BillingClient: item not owned',
        fallback: PremiumStoreMessages.restoreFailed(l10n),
      ),
      PremiumStoreMessages.noSubscriptionToRestore(l10n),
    );
  });
}
