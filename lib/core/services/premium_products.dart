import 'package:flutter/foundation.dart';
import 'package:resume_app/l10n/app_localizations.dart';

/// Store product identifiers for ResumeAI Pro.
///
/// One-time (non-consumable) lifetime unlock only.
abstract final class PremiumProducts {
  /// One-time Pro unlock (App Store price should be $1.99).
  static const String lifetime = 'resume_builder_one_time';

  /// Products shown / offered on the paywall.
  static const List<String> purchaseProductIds = [lifetime];

  /// All IDs queried from the store.
  static const List<String> productIds = [lifetime];

  /// @Deprecated — use [productIds]. Kept for call-site compatibility.
  static const List<String> subscriptionIds = productIds;

  /// @Deprecated — use [productIds].
  static const List<String> allProductIds = productIds;

  static bool isKnownProductId(String productId) =>
      productIds.contains(productId);

  static String storeAccountLabel(AppLocalizations l10n) =>
      defaultTargetPlatform == TargetPlatform.android
      ? l10n.storeAccountGoogle
      : l10n.storeAccountApple;

  static String backupSyncBenefit(AppLocalizations l10n) =>
      defaultTargetPlatform == TargetPlatform.android
      ? l10n.googleDriveBackup
      : l10n.iCloudBackup;

  /// English plan title for analytics (stable across locales).
  static String planTitleFor(String? productId) {
    return switch (productId) {
      lifetime => 'Lifetime',
      _ => 'Pro',
    };
  }

  static String localizedPlanTitleFor(
    String? productId,
    AppLocalizations l10n,
  ) {
    return switch (productId) {
      lifetime => l10n.planLifetime,
      _ => l10n.planPro,
    };
  }

  /// Short label for settings and sheets (e.g. "Lifetime plan").
  static String planLabelFor(String? productId, AppLocalizations l10n) {
    final title = localizedPlanTitleFor(productId, l10n);
    if (!isKnownProductId(productId ?? '')) {
      return l10n.resumeAppPro;
    }
    return l10n.planLabelNamed(title);
  }

  /// Body copy for the already-subscribed bottom sheet.
  static String alreadySubscribedMessage({
    required String? productId,
    required AppLocalizations l10n,
    bool debugOverride = false,
  }) {
    if (debugOverride) {
      return l10n.alreadySubscribedDebugOverride;
    }
    final backup = backupSyncBenefit(l10n);
    return switch (productId) {
      lifetime => l10n.alreadySubscribedLifetime(backup),
      _ => l10n.alreadySubscribedGeneric,
    };
  }

  /// Body copy shown when the user tries to buy while another active plan
  /// already exists on the same store account.
  static String restoreInsteadMessage({
    required String? productId,
    required AppLocalizations l10n,
  }) {
    final account = storeAccountLabel(l10n);
    return switch (productId) {
      lifetime => l10n.restoreInsteadLifetime(account),
      _ => l10n.restoreInsteadGeneric(account),
    };
  }
}

/// Display metadata for paywall plans (prices come from the store when loaded).
class PremiumPlanDefinition {
  const PremiumPlanDefinition({
    required this.productId,
    required this.title,
    required this.subtitle,
    this.recommended = false,
  });

  final String productId;
  final String title;
  final String subtitle;
  final bool recommended;
}

List<PremiumPlanDefinition> premiumPlanDefinitions(AppLocalizations l10n) => [
  PremiumPlanDefinition(
    productId: PremiumProducts.lifetime,
    title: l10n.planLifetime,
    subtitle: l10n.planSubtitleLifetime,
    recommended: true,
  ),
];

List<String> premiumBenefits(AppLocalizations l10n) => [
  l10n.premiumBenefitRemoveAds,
  l10n.premiumBenefitUnlockLayouts,
  defaultTargetPlatform == TargetPlatform.android
      ? l10n.premiumBenefitBackupGoogleDrive
      : l10n.premiumBenefitBackupIcloud,
];

String premiumUpcomingUpdateBadge(AppLocalizations l10n) =>
    l10n.premiumUpcomingUpdateBadge;

String premiumUpcomingUpdateMessage(AppLocalizations l10n) =>
    l10n.premiumUpcomingUpdateMessage;
