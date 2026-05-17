/// Store product identifiers for ResumeAI Pro subscriptions.
abstract final class PremiumProducts {
  static const String week = 'gp_pro_week';
  static const String month = 'gp_pro_month';
  static const String year = 'gp_pro_year';

  static const List<String> subscriptionIds = [
    week,
    month,
    year,
  ];
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

const List<String> kFreeTierIncludes = [
  'Corporate professional template',
  'Structured ATS template',
  'PDF export',
];
