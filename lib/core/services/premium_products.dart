/// Store product identifiers for ResumeAI Pro subscriptions.
abstract final class PremiumProducts {
  static const String week = 'gp_pro_week';
  static const String month = 'gp_pro_month';
  static const String year = 'gp_pro_year';

  static const List<String> subscriptionIds = [week, month, year];

  static String planTitleFor(String? productId) {
    return switch (productId) {
      week => 'Weekly',
      month => 'Monthly',
      year => 'Yearly',
      _ => 'Pro',
    };
  }

  /// Short label for settings and sheets (e.g. "Monthly plan").
  static String planLabelFor(String? productId) {
    final title = planTitleFor(productId);
    if (title == 'Pro') {
      return 'ResumeApp Pro';
    }
    return '$title plan';
  }

  /// Body copy for the already-subscribed bottom sheet.
  static String alreadySubscribedMessage({
    required String? productId,
    bool debugOverride = false,
  }) {
    if (debugOverride) {
      return 'Developer Pro override is on. All Pro features are unlocked '
          'for testing on this device.';
    }
    return switch (productId) {
      week =>
        'You have an active weekly subscription. All Pro templates, iCloud '
            'backup, and premium features are included.',
      month =>
        'You have an active monthly subscription. All Pro templates, iCloud '
            'backup, and premium features are included.',
      year =>
        'You have an active yearly subscription. All Pro templates, iCloud '
            'backup, and premium features are included.',
      _ =>
        'You have an active ResumeApp Pro subscription. All premium features '
            'are included in your plan.',
    };
  }

  /// Body copy shown when the user tries to buy while another active plan
  /// already exists on the same store account.
  static String restoreInsteadMessage({required String? productId}) {
    return switch (productId) {
      week =>
        'A weekly subscription was found for this Apple ID or Google account. '
            'Use Restore to activate it on this device instead of buying again.',
      month =>
        'A monthly subscription was found for this Apple ID or Google account. '
            'Use Restore to activate it on this device instead of buying again.',
      year =>
        'A yearly subscription was found for this Apple ID or Google account. '
            'Use Restore to activate it on this device instead of buying again.',
      _ =>
        'An active ResumeApp Pro subscription was found for this Apple ID or '
            'Google account. Use Restore to activate it on this device '
            'instead of buying again.',
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

const List<PremiumPlanDefinition> kPremiumPlanDefinitions = [
  PremiumPlanDefinition(
    productId: PremiumProducts.week,
    title: 'Weekly',
    subtitle: 'Short-term access',
  ),
  PremiumPlanDefinition(
    productId: PremiumProducts.month,
    title: 'Monthly',
    subtitle: 'Pay month to month',
  ),
  PremiumPlanDefinition(
    productId: PremiumProducts.year,
    title: 'Yearly',
    subtitle: 'Best value',
    recommended: true,
  ),
];

const List<String> kPremiumBenefits = [
  'Unlock every professional and ATS resume layout beyond the free templates',
  'Back up and sync resumes with iCloud',
];

/// Highlighted on Go Premium — upcoming Pro content shipped in a future release.
const String kPremiumUpcomingUpdateBadge = 'Coming in the next update';
const String kPremiumUpcomingUpdateMessage =
    'New resume layouts and modern templates, included with Pro.';

/// Savings line under the yearly plan (vs 12× monthly). `null` if prices are missing.
String? premiumYearlySavingsLabel({
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
  return 'Save $percent% with yearly billing';
}
