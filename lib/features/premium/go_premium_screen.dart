import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../core/services/premium_products.dart';
import '../../core/services/premium_purchase_service.dart';

class GoPremiumScreen extends StatefulWidget {
  const GoPremiumScreen({super.key});

  @override
  State<GoPremiumScreen> createState() => _GoPremiumScreenState();
}

class _GoPremiumScreenState extends State<GoPremiumScreen> {
  String? _selectedProductId = PremiumProducts.year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final premium = context.read<PremiumPurchaseService>();
      if (premium.isPremium) {
        Navigator.of(context).pop(true);
        return;
      }
      unawaited(premium.refreshProducts());
    });
  }

  void _onPremiumActivated(PremiumPurchaseService premium) {
    if (!premium.isPremium || !mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<PremiumPurchaseService>(
      builder: (context, premium, _) {
        if (premium.isPremium) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onPremiumActivated(premium);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Go Premium'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Included free',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in kFreeTierIncludes)
                          _BenefitRow(
                            text: item,
                            color: colorScheme.onSurfaceVariant,
                            icon: Icons.check_rounded,
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'ResumeApp Pro',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final benefit in kPremiumBenefits)
                          _BenefitRow(
                            text: benefit,
                            color: colorScheme.primary,
                          ),
                        const SizedBox(height: 22),
                        Text(
                          'Choose a plan',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (premium.isLoadingProducts)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else ...[
                          for (final plan in kPremiumPlanDefinitions)
                            _PlanCard(
                              definition: plan,
                              product: premium.productFor(plan.productId),
                              selected: _selectedProductId == plan.productId,
                              onTap: () {
                                setState(() {
                                  _selectedProductId = plan.productId;
                                });
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: premium.isPurchasing ||
                                premium.isLoadingProducts ||
                                _selectedProductId == null
                            ? null
                            : () async {
                                premium.clearMessages();
                                await premium.buy(_selectedProductId!);
                                if (!context.mounted) {
                                  return;
                                }
                                final message = premium.errorMessage;
                                if (message != null && message.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor:
                                          colorScheme.error,
                                    ),
                                  );
                                  premium.clearMessages();
                                }
                              },
                        child: premium.isPurchasing
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Continue'),
                      ),
                      TextButton(
                        onPressed: premium.isRestoring
                            ? null
                            : () => premium.restorePurchases(),
                        child: const Text('Restore purchases'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.text,
    required this.color,
    this.icon = Icons.check_circle_rounded,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.definition,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlanDefinition definition;
  final ProductDetails? product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priceLabel = product?.price ?? '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.07)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    definition.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  priceLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
