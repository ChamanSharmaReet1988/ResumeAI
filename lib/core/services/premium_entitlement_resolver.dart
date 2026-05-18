import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  static const MethodChannel _storeKitEntitlementChannel = MethodChannel(
    'resume_app/storekit_entitlements',
  );

  /// Returns `true` only when the store reports an active subscription.
  ///
  /// On iOS (StoreKit 2), checks subscription [expirationDate] on transactions.
  /// On Android, queries Play Billing for active subscription purchases.
  static Future<bool> hasActiveSubscription(InAppPurchase inAppPurchase) async {
    final productId = await resolveActiveProductId(inAppPurchase);
    return productId != null;
  }

  /// Product ID of the user's current Pro plan, if any.
  ///
  /// When several subscriptions are active (e.g. sandbox history), prefers
  /// [preferredProductId] from the purchase stream, otherwise the most recently
  /// purchased active plan — not the one with the farthest expiration date.
  static Future<String?> resolveActiveProductId(
    InAppPurchase inAppPurchase, {
    String reason = 'unknown',
    String? preferredProductId,
    bool requestAppStoreSync = false,
  }) async {
    if (kIsWeb) {
      PremiumDebugLog.log('resolveActiveProductId($reason): web → no product');
      return null;
    }

    PremiumDebugLog.section('Store entitlement check ($reason)');

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _iosActiveProductId(
          reason: reason,
          preferredProductId: preferredProductId,
          requestAppStoreSync: requestAppStoreSync,
        );
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _androidActiveProductId(
          inAppPurchase,
          reason: reason,
          preferredProductId: preferredProductId,
        );
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

  static Future<String?> _iosActiveProductId({
    required String reason,
    String? preferredProductId,
    required bool requestAppStoreSync,
  }) async {
    PremiumDebugLog.logPair('platform', 'iOS');

    if (requestAppStoreSync) {
      try {
        PremiumDebugLog.log('Calling AppStore.sync() before reading entitlements…');
        await AppStore().sync();
        PremiumDebugLog.log('AppStore.sync() completed');
      } catch (error) {
        PremiumDebugLog.log('AppStore.sync() failed: $error');
      }
    }

    final currentEntitlements = await _currentIosEntitlements();
    if (currentEntitlements != null) {
      return _resolveCurrentIosEntitlements(
        currentEntitlements,
        preferredProductId: preferredProductId,
      );
    }

    final supportsSk2 = await SKRequestMaker.supportsStoreKit2();
    PremiumDebugLog.logPair('storeKit2Supported', supportsSk2);

    if (!supportsSk2) {
      PremiumDebugLog.log(
        'StoreKit2 not available; cannot resolve active product ($reason)',
      );
      return null;
    }

    final transactions = await SK2Transaction.transactions();
    final now = DateTime.now();
    final activeByProductId = <String, DateTime>{};
    String? fallbackProductId;
    DateTime? fallbackExpiry;

    PremiumDebugLog.logPair(
      'storeKit2TransactionCount',
      transactions.length,
    );
    PremiumDebugLog.logPair('checkTimeUtc', now.toUtc().toIso8601String());
    if (preferredProductId != null) {
      PremiumDebugLog.logPair('preferredProductId', preferredProductId);
    }

    var subscriptionRow = 0;
    for (final transaction in transactions) {
      if (!PremiumProducts.subscriptionIds.contains(transaction.productId)) {
        continue;
      }

      subscriptionRow++;
      final expiresAt = _parseStoreKit2Timestamp(transaction.expirationDate);
      final isActive = expiresAt != null && expiresAt.isAfter(now);
      final purchasedAt = _parseStoreKit2Timestamp(transaction.purchaseDate);

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

      if (fallbackExpiry == null || expiresAt.isAfter(fallbackExpiry)) {
        fallbackExpiry = expiresAt;
        fallbackProductId = transaction.productId;
      }

      final purchaseMoment =
          purchasedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final existing = activeByProductId[transaction.productId];
      if (existing == null || purchaseMoment.isAfter(existing)) {
        activeByProductId[transaction.productId] = purchaseMoment;
      }
    }

    if (subscriptionRow == 0) {
      PremiumDebugLog.log(
        'No StoreKit2 transactions matched subscription product IDs '
        '${PremiumProducts.subscriptionIds}',
      );
    }

    if (preferredProductId != null &&
        activeByProductId.containsKey(preferredProductId)) {
      PremiumDebugLog.logPair('activeProductId', preferredProductId);
      PremiumDebugLog.log('Selected preferred product from purchase stream');
      return preferredProductId;
    }

    String? bestProductId;
    DateTime? bestPurchaseAt;
    for (final entry in activeByProductId.entries) {
      if (bestPurchaseAt == null || entry.value.isAfter(bestPurchaseAt)) {
        bestPurchaseAt = entry.value;
        bestProductId = entry.key;
      }
    }

    final resolved = bestProductId ?? fallbackProductId;
    PremiumDebugLog.logPair('activeProductId', resolved ?? 'none');
    PremiumDebugLog.logPair(
      'activePurchaseUtc',
      bestPurchaseAt?.toUtc().toIso8601String() ?? 'none',
    );
    PremiumDebugLog.logPair('isProFromStore', resolved != null);

    return resolved;
  }

  static Future<List<_IosCurrentEntitlement>?> _currentIosEntitlements() async {
    try {
      final raw = await _storeKitEntitlementChannel.invokeMethod<List<dynamic>>(
        'getCurrentSubscriptionEntitlements',
      );
      final rows = <_IosCurrentEntitlement>[];
      for (final item in raw ?? const <dynamic>[]) {
        if (item is! Map) {
          continue;
        }
        final row = _IosCurrentEntitlement.fromChannelMap(item);
        if (row == null) {
          continue;
        }
        rows.add(row);
      }
      return rows;
    } on MissingPluginException {
      PremiumDebugLog.log(
        'StoreKit entitlement channel missing; falling back to SK2 transaction history',
      );
      return null;
    } on PlatformException catch (error) {
      PremiumDebugLog.log(
        'StoreKit entitlement channel failed '
        '(${error.code}): ${error.message ?? "unknown"}; '
        'falling back to SK2 transaction history',
      );
      return null;
    }
  }

  static String? _resolveCurrentIosEntitlements(
    List<_IosCurrentEntitlement> entitlements, {
    String? preferredProductId,
  }) {
    final now = DateTime.now();
    final activeRows = <_IosCurrentEntitlement>[];

    PremiumDebugLog.logPair('storeKitCurrentEntitlementCount', entitlements.length);
    PremiumDebugLog.logPair('checkTimeUtc', now.toUtc().toIso8601String());
    if (preferredProductId != null) {
      PremiumDebugLog.logPair('preferredProductId', preferredProductId);
    }

    var subscriptionRow = 0;
    for (final entitlement in entitlements) {
      if (!PremiumProducts.subscriptionIds.contains(entitlement.productId)) {
        continue;
      }
      subscriptionRow++;
      final expiresAt = entitlement.expirationDate;
      final isActive = _isIosEntitlementActive(entitlement, now);
      PremiumDebugLog.log(
        '  current entitlement #$subscriptionRow '
        'productId=${entitlement.productId} '
        'originalTransactionId=${entitlement.originalTransactionId} '
        'purchaseDate=${entitlement.purchaseDate.toUtc().toIso8601String()} '
        'expirationDate=${expiresAt?.toUtc().toIso8601String() ?? "none"} '
        'statusState=${entitlement.statusState ?? "unknown"} '
        'willAutoRenew=${entitlement.willAutoRenew?.toString() ?? "unknown"} '
        'expirationReason=${entitlement.expirationReason ?? "none"} '
        'renewalOffButStillActive=${isActive && entitlement.willAutoRenew == false} '
        'active=$isActive '
        'transactionId=${entitlement.transactionId}',
      );
      if (isActive) {
        activeRows.add(entitlement);
      }
    }

    if (subscriptionRow == 0) {
      PremiumDebugLog.log(
        'No current entitlements matched subscription product IDs '
        '${PremiumProducts.subscriptionIds}',
      );
    }

    if (preferredProductId != null) {
      for (final entitlement in activeRows) {
        if (entitlement.productId == preferredProductId) {
          PremiumDebugLog.logPair('activeProductId', preferredProductId);
          PremiumDebugLog.log('Selected preferred product from current entitlements');
          return preferredProductId;
        }
      }
    }

    activeRows.sort(
      (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
    );
    final resolved = activeRows.isEmpty ? null : activeRows.first.productId;
    PremiumDebugLog.logPair('activeProductId', resolved ?? 'none');
    PremiumDebugLog.logPair('isProFromStore', resolved != null);
    return resolved;
  }

  static bool _isIosEntitlementActive(
    _IosCurrentEntitlement entitlement,
    DateTime now,
  ) {
    final state = entitlement.statusState;
    final expiresAt = entitlement.expirationDate;
    final hasFutureExpiry = expiresAt != null && expiresAt.isAfter(now);

    if (state == 'expired' || state == 'revoked') {
      return false;
    }
    if (state == 'subscribed' ||
        state == 'inGracePeriod' ||
        state == 'inBillingRetryPeriod') {
      return hasFutureExpiry || expiresAt == null;
    }
    return hasFutureExpiry;
  }

  static Future<String?> _androidActiveProductId(
    InAppPurchase inAppPurchase, {
    required String reason,
    String? preferredProductId,
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
    GooglePlayPurchaseDetails? preferredPurchase;
    var latestPurchaseTime = 0;
    var subscriptionRow = 0;

    if (preferredProductId != null) {
      PremiumDebugLog.logPair('preferredProductId', preferredProductId);
    }

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
      if (purchase.productID == preferredProductId) {
        preferredPurchase = purchase;
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

    final productId = preferredPurchase?.productID ?? latestPurchase?.productID;
    if (preferredPurchase != null) {
      PremiumDebugLog.log('Selected preferred product from purchase stream');
    }
    PremiumDebugLog.logPair('activeProductId', productId ?? 'none');
    PremiumDebugLog.logPair('isProFromStore', productId != null);

    return productId;
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

class _IosCurrentEntitlement {
  const _IosCurrentEntitlement({
    required this.productId,
    required this.transactionId,
    required this.originalTransactionId,
    required this.purchaseDate,
    required this.expirationDate,
    required this.statusState,
    required this.willAutoRenew,
    required this.expirationReason,
  });

  final String productId;
  final String transactionId;
  final String originalTransactionId;
  final DateTime purchaseDate;
  final DateTime? expirationDate;
  final String? statusState;
  final bool? willAutoRenew;
  final String? expirationReason;

  static _IosCurrentEntitlement? fromChannelMap(Map<dynamic, dynamic> map) {
    final productId = map['productId'] as String?;
    final transactionId = map['transactionId'] as String?;
    final originalTransactionId = map['originalTransactionId'] as String?;
    final purchaseDateRaw = map['purchaseDate'] as String?;
    if (productId == null ||
        transactionId == null ||
        originalTransactionId == null ||
        purchaseDateRaw == null) {
      return null;
    }
    final purchaseDate = DateTime.tryParse(purchaseDateRaw);
    if (purchaseDate == null) {
      return null;
    }
    final expirationRaw = map['expirationDate'] as String?;
    return _IosCurrentEntitlement(
      productId: productId,
      transactionId: transactionId,
      originalTransactionId: originalTransactionId,
      purchaseDate: purchaseDate,
      expirationDate: expirationRaw == null
          ? null
          : DateTime.tryParse(expirationRaw),
      statusState: map['statusState'] as String?,
      willAutoRenew: map['willAutoRenew'] as bool?,
      expirationReason: map['expirationReason'] as String?,
    );
  }
}
