import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:intl/intl.dart';

import 'premium_debug_log.dart';
import 'premium_products.dart';

/// Resolves whether the user currently has an active Pro subscription.
abstract final class PremiumEntitlementResolver {
  /// Returns `true` only when the store reports an active subscription.
  ///
  /// On iOS (StoreKit 2), checks subscription [expirationDate] on transactions.
  /// On Android, queries Play Billing for active subscription purchases.
  static Future<bool> hasActiveSubscription(InAppPurchase inAppPurchase) async {
    final productId = await resolveActiveProductId(inAppPurchase);
    return productId != null;
  }

  /// Product ID of the active subscription with the latest renewal, if any.
  static Future<String?> resolveActiveProductId(
    InAppPurchase inAppPurchase, {
    String reason = 'unknown',
  }) async {
    if (kIsWeb) {
      PremiumDebugLog.log('resolveActiveProductId($reason): web → no product');
      return null;
    }

    PremiumDebugLog.section('Store entitlement check ($reason)');

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _iosActiveProductId(reason: reason);
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _androidActiveProductId(inAppPurchase, reason: reason);
      }
      PremiumDebugLog.log(
        'resolveActiveProductId($reason): unsupported platform',
      );
    } catch (error, stackTrace) {
      PremiumDebugLog.log('resolveActiveProductId($reason) FAILED: $error');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
    }
    return null;
  }

  static Future<String?> _iosActiveProductId({required String reason}) async {
    final supportsSk2 = await SKRequestMaker.supportsStoreKit2();
    PremiumDebugLog.logPair('platform', 'iOS');
    PremiumDebugLog.logPair('storeKit2Supported', supportsSk2);

    if (!supportsSk2) {
      PremiumDebugLog.log(
        'StoreKit2 not available; cannot resolve active product ($reason)',
      );
      return null;
    }

    if (_shouldSyncWithAppStore(reason)) {
      try {
        PremiumDebugLog.log('Calling AppStore.sync() before reading entitlements…');
        await AppStore().sync();
        PremiumDebugLog.log('AppStore.sync() completed');
      } catch (error) {
        PremiumDebugLog.log('AppStore.sync() failed: $error');
      }
    }

    final transactions = await SK2Transaction.transactions();
    final now = DateTime.now();
    String? bestProductId;
    DateTime? bestExpiry;

    PremiumDebugLog.logPair(
      'storeKit2TransactionCount',
      transactions.length,
    );
    PremiumDebugLog.logPair('checkTimeUtc', now.toUtc().toIso8601String());

    var subscriptionRow = 0;
    for (final transaction in transactions) {
      if (!PremiumProducts.subscriptionIds.contains(transaction.productId)) {
        continue;
      }

      subscriptionRow++;
      final expiresAt = _parseStoreKit2Timestamp(transaction.expirationDate);
      final isActive = expiresAt != null && expiresAt.isAfter(now);

      PremiumDebugLog.log(
        '  SK2 txn #$subscriptionRow '
        'productId=${transaction.productId} '
        'purchaseDate=${transaction.purchaseDate} '
        'expirationDate=${transaction.expirationDate ?? "none"} '
        'parsedExpiry=${expiresAt?.toUtc().toIso8601String() ?? "none"} '
        'active=$isActive '
        'transactionId=${transaction.id}',
      );

      if (!isActive) {
        continue;
      }
      if (bestExpiry == null || expiresAt.isAfter(bestExpiry)) {
        bestExpiry = expiresAt;
        bestProductId = transaction.productId;
      }
    }

    if (subscriptionRow == 0) {
      PremiumDebugLog.log(
        'No StoreKit2 transactions matched subscription product IDs '
        '${PremiumProducts.subscriptionIds}',
      );
    }

    PremiumDebugLog.logPair('activeProductId', bestProductId ?? 'none');
    PremiumDebugLog.logPair(
      'activeExpiresUtc',
      bestExpiry?.toUtc().toIso8601String() ?? 'none',
    );
    PremiumDebugLog.logPair('isProFromStore', bestProductId != null);

    return bestProductId;
  }

  static Future<String?> _androidActiveProductId(
    InAppPurchase inAppPurchase, {
    required String reason,
  }) async {
    PremiumDebugLog.logPair('platform', 'Android');

    final addition = inAppPurchase
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();

    if (response.error != null) {
      PremiumDebugLog.log(
        'Play Billing queryPastPurchases error ($reason): '
        '${response.error!.code} ${response.error!.message}',
      );
      return null;
    }

    PremiumDebugLog.logPair(
      'playBillingPastPurchaseCount',
      response.pastPurchases.length,
    );

    GooglePlayPurchaseDetails? latestPurchase;
    var latestPurchaseTime = 0;
    var subscriptionRow = 0;

    for (final purchase in response.pastPurchases) {
      if (!PremiumProducts.subscriptionIds.contains(purchase.productID)) {
        continue;
      }

      subscriptionRow++;
      final billing = purchase.billingClientPurchase;
      final isPurchased =
          billing.purchaseState == PurchaseStateWrapper.purchased;

      PremiumDebugLog.log(
        '  Play purchase #$subscriptionRow '
        'productId=${purchase.productID} '
        'status=${purchase.status.name} '
        'purchaseState=${billing.purchaseState.name} '
        'isAutoRenewing=${billing.isAutoRenewing} '
        'purchaseTimeMs=${billing.purchaseTime} '
        'countsAsActive=$isPurchased',
      );

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }
      if (!isPurchased) {
        continue;
      }
      if (billing.purchaseTime >= latestPurchaseTime) {
        latestPurchaseTime = billing.purchaseTime;
        latestPurchase = purchase;
      }
    }

    if (subscriptionRow == 0) {
      PremiumDebugLog.log(
        'No Play Billing purchases matched subscription product IDs '
        '${PremiumProducts.subscriptionIds}',
      );
    }

    final productId = latestPurchase?.productID;
    PremiumDebugLog.logPair('activeProductId', productId ?? 'none');
    PremiumDebugLog.logPair('isProFromStore', productId != null);

    return productId;
  }

  /// Only for user-initiated restore — [AppStore.sync] shows an Apple ID prompt.
  static bool _shouldSyncWithAppStore(String reason) {
    return reason == 'manual_restore';
  }

  static DateTime? _parseStoreKit2Timestamp(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw);
    } catch (_) {
      final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
      return DateTime.tryParse(normalized);
    }
  }
}
