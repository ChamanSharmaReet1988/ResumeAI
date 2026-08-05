import 'package:flutter/foundation.dart';
import 'package:resume_app/l10n/app_localizations.dart';

/// User-facing copy for App Store / Play Billing errors (never raw StoreKit text).
abstract final class PremiumStoreMessages {
  static String purchaseFailed(AppLocalizations l10n) =>
      l10n.premiumPurchaseFailed;

  static String restoreFailed(AppLocalizations l10n) =>
      l10n.premiumRestoreFailed;

  static String noSubscriptionToRestore(AppLocalizations l10n) =>
      defaultTargetPlatform == TargetPlatform.android
      ? l10n.noSubscriptionToRestoreGoogle
      : l10n.noSubscriptionToRestoreApple;

  static String storeUnavailable(AppLocalizations l10n) =>
      l10n.premiumStoreUnavailable;

  static String connectFailed(AppLocalizations l10n) =>
      defaultTargetPlatform == TargetPlatform.android
      ? l10n.premiumConnectFailedGoogle
      : l10n.premiumConnectFailedApple;

  static String verifyFailed(AppLocalizations l10n) => l10n.premiumVerifyFailed;

  static String productsUnavailable(AppLocalizations l10n) =>
      l10n.premiumProductsUnavailable;

  static String purchaseCanceled(AppLocalizations l10n) =>
      l10n.premiumPurchaseCanceled;

  static String planNotAvailableYet(AppLocalizations l10n) =>
      l10n.premiumPlanNotAvailableYet;

  static String couldNotStartPurchase(AppLocalizations l10n) =>
      l10n.premiumCouldNotStartPurchase;

  static String subscriptionRestored(AppLocalizations l10n) =>
      l10n.premiumSubscriptionRestored;

  static String restoredSuccessfully(AppLocalizations l10n) =>
      l10n.premiumRestoredSuccessfully;

  static String welcomeToPro(AppLocalizations l10n) =>
      l10n.welcomeToResumeAppPro;

  /// Maps a raw store error to safe UI text. Technical details stay in debug logs.
  static String friendly({
    required AppLocalizations l10n,
    String? rawMessage,
    Object? error,
    String? fallback,
  }) {
    final resolvedFallback = fallback ?? purchaseFailed(l10n);
    final raw = (rawMessage ?? error?.toString() ?? '').trim();
    if (raw.isEmpty) {
      return resolvedFallback;
    }

    if (kDebugMode) {
      debugPrint('[Premium] Raw store error: $raw');
    }

    final lower = raw.toLowerCase();

    if (_looksCanceled(lower)) {
      return purchaseCanceled(l10n);
    }

    if (lower.contains('no active subscription was found') ||
        lower.contains('nothing to restore') ||
        lower.contains('item not owned') ||
        lower.contains('product not owned') ||
        lower.contains('not owned by the user') ||
        lower.contains('user does not own')) {
      return noSubscriptionToRestore(l10n);
    }

    if (lower.contains('not available') &&
        (lower.contains('purchase') || lower.contains('billing'))) {
      return storeUnavailable(l10n);
    }

    final restoreFailedMessage = restoreFailed(l10n);
    final connectFailedMessage = connectFailed(l10n);
    final verifyFailedMessage = verifyFailed(l10n);
    final productsUnavailableMessage = productsUnavailable(l10n);

    if (lower.contains('failed to get response from platform') ||
        lower.contains('storekit') ||
        lower.contains('skerror') ||
        lower.contains('store_kit') ||
        lower.contains('in_app_purchase') ||
        lower.contains('platformexception') ||
        lower.contains('pigeonerror') ||
        lower.contains('billingclient') ||
        lower.contains('play store')) {
      if (resolvedFallback == restoreFailedMessage) {
        return restoreFailedMessage;
      }
      if (resolvedFallback == connectFailedMessage) {
        return connectFailedMessage;
      }
      if (resolvedFallback == verifyFailedMessage) {
        return verifyFailedMessage;
      }
      if (resolvedFallback == productsUnavailableMessage) {
        return productsUnavailableMessage;
      }
      return purchaseFailed(l10n);
    }

    if (lower.contains('network') ||
        lower.contains('internet') ||
        lower.contains('offline') ||
        lower.contains('connection')) {
      return connectFailedMessage;
    }

    if (lower.contains('restore')) {
      return restoreFailedMessage;
    }

    if (lower.contains('product') &&
        (lower.contains('not found') || lower.contains('invalid'))) {
      return productsUnavailableMessage;
    }

    // Do not pass through unknown technical strings.
    return resolvedFallback;
  }

  static bool _looksCanceled(String lower) {
    return lower.contains('cancel') ||
        lower.contains('user denied') ||
        lower.contains('payment cancelled') ||
        lower.contains('payment canceled');
  }
}
