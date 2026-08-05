import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/premium_products.dart';
import 'package:resume_app/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('alreadySubscribedMessage uses plan-specific copy', () {
    expect(
      PremiumProducts.alreadySubscribedMessage(
        productId: PremiumProducts.month,
        l10n: l10n,
      ),
      contains('monthly subscription'),
    );
    expect(
      PremiumProducts.alreadySubscribedMessage(
        productId: PremiumProducts.week,
        l10n: l10n,
      ),
      contains('weekly subscription'),
    );
    expect(
      PremiumProducts.alreadySubscribedMessage(
        productId: PremiumProducts.year,
        l10n: l10n,
      ),
      contains('yearly subscription'),
    );
  });

  test('planLabelFor formats plan name', () {
    expect(
      PremiumProducts.planLabelFor(PremiumProducts.month, l10n),
      'Monthly plan',
    );
  });
}
