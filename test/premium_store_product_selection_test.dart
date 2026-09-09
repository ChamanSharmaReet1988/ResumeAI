import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:resume_app/core/services/premium_products.dart';
import 'package:resume_app/core/services/premium_store_product_selection.dart';

void main() {
  test('collapseSubscriptionProducts keeps lifetime iOS product', () {
    final iosProduct = ProductDetails(
      id: PremiumProducts.lifetime,
      title: 'Lifetime',
      description: 'Lifetime plan',
      price: r'$1.99',
      rawPrice: 1.99,
      currencyCode: 'USD',
    );

    final collapsed = PremiumStoreProductSelection.collapseSubscriptionProducts(
      [iosProduct],
    );

    expect(collapsed, [iosProduct]);
    expect(
      PremiumStoreProductSelection.displayPriceFor(
        PremiumProducts.lifetime,
        [iosProduct],
      ),
      r'$1.99',
    );
    expect(
      PremiumStoreProductSelection.displayRawPriceFor(
        PremiumProducts.lifetime,
        [iosProduct],
      ),
      1.99,
    );
  });

  test('ignores unknown product ids', () {
    final unknown = ProductDetails(
      id: 'gp_pro_month',
      title: 'Monthly',
      description: 'Legacy',
      price: r'$4.99',
      rawPrice: 4.99,
      currencyCode: 'USD',
    );

    expect(
      PremiumStoreProductSelection.collapseSubscriptionProducts([unknown]),
      isEmpty,
    );
  });
}
