import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:resume_app/core/services/premium_products.dart';
import 'package:resume_app/core/services/premium_store_product_selection.dart';

ProductDetailsWrapper _subscriptionWrapper({
  required String productId,
  required List<SubscriptionOfferDetailsWrapper> offers,
}) {
  return ProductDetailsWrapper(
    description: 'Pro access',
    name: productId,
    productId: productId,
    productType: ProductType.subs,
    title: productId,
    subscriptionOfferDetails: offers,
  );
}

PricingPhaseWrapper _phase({
  required String formattedPrice,
  required int priceAmountMicros,
  String billingPeriod = 'P1M',
  RecurrenceMode recurrenceMode = RecurrenceMode.infiniteRecurring,
}) {
  return PricingPhaseWrapper(
    billingCycleCount: 0,
    billingPeriod: billingPeriod,
    formattedPrice: formattedPrice,
    priceAmountMicros: priceAmountMicros,
    priceCurrencyCode: 'INR',
    recurrenceMode: recurrenceMode,
  );
}

List<ProductDetails> _allOffers(ProductDetailsWrapper wrapper) {
  return GooglePlayProductDetails.fromProductDetails(wrapper);
}

void main() {
  test('displayPriceFor uses recurring phase instead of free trial', () {
    final wrapper = _subscriptionWrapper(
      productId: PremiumProducts.month,
      offers: [
        SubscriptionOfferDetailsWrapper(
          basePlanId: 'monthly-base',
          offerId: 'free-trial',
          offerTags: const [],
          offerIdToken: 'trial-token',
          pricingPhases: [
            _phase(
              formattedPrice: 'Free',
              priceAmountMicros: 0,
              billingPeriod: 'P1M',
            ),
            _phase(
              formattedPrice: '₹299.00',
              priceAmountMicros: 299000000,
              billingPeriod: 'P1M',
            ),
          ],
        ),
      ],
    );
    final all = _allOffers(wrapper);

    expect(
      PremiumStoreProductSelection.displayPriceFor(
        PremiumProducts.month,
        all,
      ),
      '₹299.00',
    );
    expect(
      PremiumStoreProductSelection.displayRawPriceFor(
        PremiumProducts.month,
        all,
      ),
      299.0,
    );
  });

  test('displayPriceFor picks matching billing period across offers', () {
    final wrapper = _subscriptionWrapper(
      productId: PremiumProducts.month,
      offers: [
        SubscriptionOfferDetailsWrapper(
          basePlanId: 'monthly-base',
          offerId: 'intro',
          offerTags: const [],
          offerIdToken: 'intro-token',
          pricingPhases: [
            _phase(
              formattedPrice: '₹49.00',
              priceAmountMicros: 49000000,
              billingPeriod: 'P1M',
            ),
          ],
        ),
        SubscriptionOfferDetailsWrapper(
          basePlanId: 'monthly-base',
          offerTags: const [],
          offerIdToken: 'base-token',
          pricingPhases: [
            _phase(
              formattedPrice: '₹299.00',
              priceAmountMicros: 299000000,
              billingPeriod: 'P1M',
            ),
          ],
        ),
      ],
    );
    final all = _allOffers(wrapper);

    expect(
      PremiumStoreProductSelection.displayPriceFor(
        PremiumProducts.month,
        all,
      ),
      '₹299.00',
    );
    expect(
      PremiumStoreProductSelection.purchaseProductFor(
        PremiumProducts.month,
        all,
      )?.price,
      '₹299.00',
    );
  });

  test('displayPriceFor uses weekly billing period for weekly plan', () {
    final wrapper = _subscriptionWrapper(
      productId: PremiumProducts.week,
      offers: [
        SubscriptionOfferDetailsWrapper(
          basePlanId: 'weekly-base',
          offerTags: const [],
          offerIdToken: 'base-token',
          pricingPhases: [
            _phase(
              formattedPrice: '₹99.00',
              priceAmountMicros: 99000000,
              billingPeriod: 'P1W',
            ),
          ],
        ),
      ],
    );
    final all = _allOffers(wrapper);

    expect(
      PremiumStoreProductSelection.displayPriceFor(
        PremiumProducts.week,
        all,
      ),
      '₹99.00',
    );
  });

  test('collapseSubscriptionProducts keeps iOS products unchanged', () {
    final iosProduct = ProductDetails(
      id: PremiumProducts.year,
      title: 'Yearly',
      description: 'Yearly plan',
      price: r'$49.99',
      rawPrice: 49.99,
      currencyCode: 'USD',
    );

    final collapsed = PremiumStoreProductSelection.collapseSubscriptionProducts(
      [iosProduct],
    );

    expect(collapsed, [iosProduct]);
    expect(
      PremiumStoreProductSelection.displayPriceFor(
        PremiumProducts.year,
        [iosProduct],
      ),
      r'$49.99',
    );
  });
}
