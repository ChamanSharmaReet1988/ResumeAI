import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/premium_products.dart';
import 'package:resume_app/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('alreadySubscribedMessage uses lifetime copy', () {
    expect(
      PremiumProducts.alreadySubscribedMessage(
        productId: PremiumProducts.lifetime,
        l10n: l10n,
      ),
      contains('Lifetime'),
    );
  });

  test('planLabelFor formats lifetime plan name', () {
    expect(
      PremiumProducts.planLabelFor(PremiumProducts.lifetime, l10n),
      'Lifetime plan',
    );
  });

  test('only lifetime product is offered', () {
    expect(PremiumProducts.productIds, [PremiumProducts.lifetime]);
    expect(PremiumProducts.purchaseProductIds, [PremiumProducts.lifetime]);
    expect(
      premiumPlanDefinitions(l10n).single.productId,
      PremiumProducts.lifetime,
    );
  });
}
