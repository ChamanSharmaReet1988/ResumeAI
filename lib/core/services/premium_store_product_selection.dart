import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'premium_debug_log.dart';
import 'premium_products.dart';

/// Picks Play Store purchase offers and resolves paywall display prices.
///
/// Google Play returns multiple offers per subscription (base plan, trials,
/// intro pricing). [ProductDetails.price] often reflects only the first phase
/// (e.g. free trial). Display prices are resolved across every offer.
abstract final class PremiumStoreProductSelection {
  static const Map<String, List<String>> _expectedBillingPeriods = {
    PremiumProducts.week: ['P1W', 'P7D'],
    PremiumProducts.month: ['P1M'],
    PremiumProducts.year: ['P1Y'],
  };

  /// One purchase-ready product per subscription id.
  static List<ProductDetails> collapseSubscriptionProducts(
    List<ProductDetails> products,
  ) {
    final collapsed = <ProductDetails>[];
    for (final id in PremiumProducts.subscriptionIds) {
      final purchaseProduct = purchaseProductFor(id, products);
      if (purchaseProduct != null) {
        collapsed.add(purchaseProduct);
      }
    }
    return collapsed;
  }

  /// Paywall price label for [productId] using every loaded store offer.
  static String? displayPriceFor(
    String productId,
    List<ProductDetails> allProducts,
  ) {
    final phase = _bestDisplayPhase(productId, allProducts);
    if (phase != null) {
      return phase.formattedPrice;
    }

    final product = _firstProduct(productId, allProducts);
    return product?.price;
  }

  /// Numeric recurring price for savings math.
  static double? displayRawPriceFor(
    String productId,
    List<ProductDetails> allProducts,
  ) {
    final phase = _bestDisplayPhase(productId, allProducts);
    if (phase != null) {
      return phase.priceAmountMicros / 1000000.0;
    }

    final product = _firstProduct(productId, allProducts);
    return product?.rawPrice;
  }

  /// Product passed to Play Billing when the user taps Continue.
  static ProductDetails? purchaseProductFor(
    String productId,
    List<ProductDetails> allProducts,
  ) {
    final group = _productsForId(productId, allProducts);
    if (group.isEmpty) {
      return null;
    }
    if (group.length == 1) {
      return group.first;
    }

    final androidOffers =
        group.whereType<GooglePlayProductDetails>().toList(growable: false);
    if (androidOffers.isEmpty) {
      return group.first;
    }

    for (final offer in androidOffers) {
      final wrapper = _subscriptionOffer(offer);
      if (wrapper != null && _isBasePlanOffer(wrapper)) {
        return offer;
      }
    }

    GooglePlayProductDetails? best;
    var bestMicros = 0;
    for (final offer in androidOffers) {
      final phase = _bestDisplayPhase(productId, [offer]);
      final micros = phase?.priceAmountMicros ?? 0;
      if (micros > bestMicros) {
        bestMicros = micros;
        best = offer;
      }
    }

    return best ?? androidOffers.first;
  }

  static void logResolvedPrices(List<ProductDetails> allProducts) {
    if (!kDebugMode) {
      return;
    }

    PremiumDebugLog.section('Premium paywall price resolution');
    for (final id in PremiumProducts.subscriptionIds) {
      final group = _productsForId(id, allProducts);
      PremiumDebugLog.log('productId=$id offerCount=${group.length}');
      for (final product in group) {
        if (product is GooglePlayProductDetails) {
          final offers =
              product.productDetails.subscriptionOfferDetails ?? const [];
          for (var i = 0; i < offers.length; i++) {
            final offer = offers[i];
            for (final phase in offer.pricingPhases) {
              PremiumDebugLog.log(
                '  offer[$i] basePlan=${offer.basePlanId} '
                'offerId=${offer.offerId ?? "base"} '
                'period=${phase.billingPeriod} '
                'price=${phase.formattedPrice} '
                'micros=${phase.priceAmountMicros} '
                'mode=${phase.recurrenceMode.name}',
              );
            }
          }
        } else {
          PremiumDebugLog.log('  iOS price=${product.price} raw=${product.rawPrice}');
        }
      }
      PremiumDebugLog.logPair(
        'displayPrice',
        displayPriceFor(id, allProducts) ?? 'none',
      );
      PremiumDebugLog.logPair(
        'purchaseOfferPrice',
        purchaseProductFor(id, allProducts)?.price ?? 'none',
      );
    }
  }

  static ProductDetails? _firstProduct(
    String productId,
    List<ProductDetails> allProducts,
  ) {
    for (final product in allProducts) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  static List<ProductDetails> _productsForId(
    String productId,
    List<ProductDetails> allProducts,
  ) {
    return allProducts
        .where((product) => product.id == productId)
        .toList(growable: false);
  }

  static PricingPhaseWrapper? _bestDisplayPhase(
    String productId,
    List<ProductDetails> allProducts,
  ) {
    final expectedPeriods = _expectedBillingPeriods[productId] ?? const [];
    PricingPhaseWrapper? bestPeriodMatch;
    var bestPeriodMatchMicros = 0;
    PricingPhaseWrapper? bestInfinite;
    var bestInfiniteMicros = 0;
    PricingPhaseWrapper? bestPaid;
    var bestPaidMicros = 0;

    for (final product in _productsForId(productId, allProducts)) {
      if (product is! GooglePlayProductDetails) {
        continue;
      }

      for (final offer in product.productDetails.subscriptionOfferDetails ??
          const <SubscriptionOfferDetailsWrapper>[]) {
        for (final phase in offer.pricingPhases) {
          if (phase.priceAmountMicros <= 0) {
            continue;
          }

          final periodMatches = expectedPeriods.isEmpty ||
              expectedPeriods.any(
                (expected) =>
                    _normalizePeriod(phase.billingPeriod) ==
                    _normalizePeriod(expected),
              );

          if (periodMatches && phase.priceAmountMicros > bestPeriodMatchMicros) {
            bestPeriodMatchMicros = phase.priceAmountMicros;
            bestPeriodMatch = phase;
          }

          if (phase.recurrenceMode == RecurrenceMode.infiniteRecurring &&
              phase.priceAmountMicros > bestInfiniteMicros) {
            bestInfiniteMicros = phase.priceAmountMicros;
            bestInfinite = phase;
          }

          if (phase.priceAmountMicros > bestPaidMicros) {
            bestPaidMicros = phase.priceAmountMicros;
            bestPaid = phase;
          }
        }
      }
    }

    return bestPeriodMatch ?? bestInfinite ?? bestPaid;
  }

  static String _normalizePeriod(String period) => period.toUpperCase();

  static bool _isBasePlanOffer(SubscriptionOfferDetailsWrapper offer) {
    final offerId = offer.offerId;
    return offerId == null || offerId.isEmpty;
  }

  static SubscriptionOfferDetailsWrapper? _subscriptionOffer(
    GooglePlayProductDetails details,
  ) {
    final index = details.subscriptionIndex;
    final offers = details.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) {
      return null;
    }
    return offers[index];
  }
}
