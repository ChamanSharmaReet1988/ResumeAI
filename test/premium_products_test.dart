import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/premium_products.dart';

void main() {
  test('alreadySubscribedMessage uses plan-specific copy', () {
    expect(
      PremiumProducts.alreadySubscribedMessage(productId: PremiumProducts.month),
      contains('monthly subscription'),
    );
    expect(
      PremiumProducts.alreadySubscribedMessage(productId: PremiumProducts.week),
      contains('weekly subscription'),
    );
    expect(
      PremiumProducts.alreadySubscribedMessage(productId: PremiumProducts.year),
      contains('yearly subscription'),
    );
  });

  test('planLabelFor formats plan name', () {
    expect(
      PremiumProducts.planLabelFor(PremiumProducts.month),
      'Monthly plan',
    );
  });
}
