import 'package:flutter/foundation.dart';

/// User-facing copy for App Store / Play Billing errors (never raw StoreKit text).
abstract final class PremiumStoreMessages {
  static const String purchaseFailed =
      'We could not complete your purchase. Please try again.';
  static const String restoreFailed =
      'We could not restore your subscription. Please try again.';
  static const String storeUnavailable =
      'Purchases are not available on this device right now.';
  static const String connectFailed =
      'We could not connect to the App Store. Please try again later.';
  static const String verifyFailed =
      'We could not verify your subscription. Please try again.';
  static const String productsUnavailable =
      'Subscription plans are not available right now. Please try again later.';

  /// Maps a raw store error to safe UI text. Technical details stay in debug logs.
  static String friendly({
    String? rawMessage,
    Object? error,
    String fallback = purchaseFailed,
  }) {
    final raw = (rawMessage ?? error?.toString() ?? '').trim();
    if (raw.isEmpty) {
      return fallback;
    }

    if (kDebugMode) {
      debugPrint('[Premium] Raw store error: $raw');
    }

    final lower = raw.toLowerCase();

    if (_looksCanceled(lower)) {
      return 'Purchase canceled.';
    }

    if (lower.contains('not available') &&
        (lower.contains('purchase') || lower.contains('billing'))) {
      return storeUnavailable;
    }

    if (lower.contains('failed to get response from platform') ||
        lower.contains('storekit') ||
        lower.contains('skerror') ||
        lower.contains('store_kit') ||
        lower.contains('in_app_purchase') ||
        lower.contains('platformexception') ||
        lower.contains('pigeonerror') ||
        lower.contains('billingclient') ||
        lower.contains('play store')) {
      if (fallback == restoreFailed) {
        return restoreFailed;
      }
      if (fallback == connectFailed) {
        return connectFailed;
      }
      if (fallback == verifyFailed) {
        return verifyFailed;
      }
      if (fallback == productsUnavailable) {
        return productsUnavailable;
      }
      return purchaseFailed;
    }

    if (lower.contains('network') ||
        lower.contains('internet') ||
        lower.contains('offline') ||
        lower.contains('connection')) {
      return connectFailed;
    }

    if (lower.contains('restore')) {
      return restoreFailed;
    }

    if (lower.contains('product') &&
        (lower.contains('not found') || lower.contains('invalid'))) {
      return productsUnavailable;
    }

    // Do not pass through unknown technical strings.
    return fallback;
  }

  static bool _looksCanceled(String lower) {
    return lower.contains('cancel') ||
        lower.contains('user denied') ||
        lower.contains('payment cancelled') ||
        lower.contains('payment canceled');
  }
}
