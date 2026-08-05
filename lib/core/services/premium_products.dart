import 'package:flutter/foundation.dart';
import 'package:resume_app/l10n/app_localizations.dart';

/// Store product identifiers for ResumeAI Pro subscriptions.
///
/// The same IDs are configured in App Store Connect (iOS) and Google Play
/// Console (Android).
abstract final class PremiumProducts {
  static const String week = 'gp_pro_week';
  static const String month = 'gp_pro_month';
  static const String year = 'gp_pro_year';

  static const List<String> subscriptionIds = [week, month, year];

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
      week => 'Weekly',
      month => 'Monthly',
      year => 'Yearly',
      _ => 'Pro',
    };
  }

  static String localizedPlanTitleFor(
    String? productId,
    AppLocalizations l10n,
  ) {
    return switch (productId) {
      week => l10n.planWeekly,
      month => l10n.planMonthly,
      year => l10n.planYearly,
      _ => l10n.planPro,
    };
  }

  /// Short label for settings and sheets (e.g. "Monthly plan").
  static String planLabelFor(String? productId, AppLocalizations l10n) {
    final title = localizedPlanTitleFor(productId, l10n);
    if (productId != week && productId != month && productId != year) {
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
      week => l10n.alreadySubscribedWeekly(backup),
      month => l10n.alreadySubscribedMonthly(backup),
      year => l10n.alreadySubscribedYearly(backup),
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
      week => l10n.restoreInsteadWeekly(account),
      month => l10n.restoreInsteadMonthly(account),
      year => l10n.restoreInsteadYearly(account),
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
    productId: PremiumProducts.week,
    title: l10n.planWeekly,
    subtitle: l10n.planSubtitleWeekly,
  ),
  PremiumPlanDefinition(
    productId: PremiumProducts.month,
    title: l10n.planMonthly,
    subtitle: l10n.planSubtitleMonthly,
  ),
  PremiumPlanDefinition(
    productId: PremiumProducts.year,
    title: l10n.planYearly,
    subtitle: l10n.planSubtitleYearly,
    recommended: true,
  ),
];

List<String> premiumBenefits(AppLocalizations l10n) => [
  l10n.premiumBenefitUnlockLayouts,
  defaultTargetPlatform == TargetPlatform.android
      ? l10n.premiumBenefitBackupGoogleDrive
      : l10n.premiumBenefitBackupIcloud,
];

String premiumUpcomingUpdateBadge(AppLocalizations l10n) =>
    l10n.premiumUpcomingUpdateBadge;

String premiumUpcomingUpdateMessage(AppLocalizations l10n) =>
    l10n.premiumUpcomingUpdateMessage;

/// Savings line under the yearly plan (vs 12× monthly). `null` if prices are missing.
String? premiumYearlySavingsLabel({
  required AppLocalizations l10n,
  required double? yearlyPrice,
  required double? monthlyPrice,
}) {
  if (yearlyPrice == null ||
      monthlyPrice == null ||
      yearlyPrice <= 0 ||
      monthlyPrice <= 0) {
    return null;
  }
  final monthlyBilledYearly = monthlyPrice * 12;
  if (monthlyBilledYearly <= yearlyPrice) {
    return null;
  }
  final percent = ((1 - yearlyPrice / monthlyBilledYearly) * 100).round().clamp(
    1,
    99,
  );
  return l10n.savePercentWithYearlyBilling(percent);
}
