import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../core/services/analytics_events.dart';
import '../../core/services/premium_products.dart';
import '../../core/services/premium_purchase_service.dart';
import '../../core/services/premium_store_messages.dart';
import '../settings/legal_web_view_screen.dart';
import '../shell/app_shell_scope.dart';
import 'premium_store_loading_overlay.dart';
import 'premium_welcome_dialog.dart';

enum _PremiumSuccessSource { purchase, restore }

class GoPremiumScreen extends StatefulWidget {
  const GoPremiumScreen({super.key});

  @override
  State<GoPremiumScreen> createState() => _GoPremiumScreenState();
}

class _GoPremiumScreenState extends State<GoPremiumScreen> {
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://sites.google.com/mindplexapp.com/resumeapp/privacy-policy',
  );
  static final Uri _termsOfUseUri = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  String? _selectedProductId = PremiumProducts.year;
  bool _didPop = false;
  bool _isCompletingLeave = false;
  bool _isFullScreenLoading = false;
  String _loadingMessage = 'Processing…';
  bool _waitingForStoreResult = false;
  bool _showWelcomeOnSuccess = false;
  _PremiumSuccessSource? _pendingSuccessSource;
  PremiumPurchaseService? _premium;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final premium = context.read<PremiumPurchaseService>();
      if (premium.hasConfirmedPremiumStatus) {
        unawaited(_completeAndLeave(premium));
        return;
      }
      unawaited(premium.refreshProducts());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final premium = context.read<PremiumPurchaseService>();
    if (!identical(_premium, premium)) {
      _premium?.removeListener(_onPremiumServiceUpdated);
      _premium = premium;
      premium.addListener(_onPremiumServiceUpdated);
    }
  }

  @override
  void dispose() {
    _premium?.removeListener(_onPremiumServiceUpdated);
    super.dispose();
  }

  void _onPremiumServiceUpdated() {
    if (!_waitingForStoreResult || !mounted) {
      return;
    }
    final premium = context.read<PremiumPurchaseService>();
    if (premium.isPurchasing || premium.isRestoring) {
      if (_isFullScreenLoading) {
        setState(() {
          _loadingMessage = premium.isRestoring
              ? 'Restoring your subscription…'
              : 'Completing your purchase…';
        });
      }
      return;
    }

    if (premium.isPremium) {
      unawaited(_completeAndLeave(premium));
      return;
    }

    _endLoadingWithFailure(premium);
  }

  void _startFullScreenLoading(String message) {
    setState(() {
      _isFullScreenLoading = true;
      _loadingMessage = message;
      _waitingForStoreResult = true;
    });
  }

  void _endLoadingWithFailure(PremiumPurchaseService premium) {
    if (!mounted) {
      return;
    }
    _showWelcomeOnSuccess = false;
    final failureSource = _pendingSuccessSource;
    _pendingSuccessSource = null;
    setState(() {
      _isFullScreenLoading = false;
      _waitingForStoreResult = false;
    });

    final error = premium.errorMessage;
    final status = premium.statusMessage;
    if (error != null && error.isNotEmpty) {
      _showMessage(
        PremiumStoreMessages.friendly(
          rawMessage: error,
          fallback: failureSource == _PremiumSuccessSource.restore
              ? PremiumStoreMessages.restoreFailed
              : PremiumStoreMessages.purchaseFailed,
        ),
        isError: true,
      );
    } else if (status != null &&
        status.isNotEmpty &&
        !_isPendingPurchaseStatus(status)) {
      _showMessage(status);
    }
    premium.clearMessages();
  }

  bool _isPendingPurchaseStatus(String status) {
    return status.toLowerCase().contains('pending');
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  bool _hasImmediateFailureState(PremiumPurchaseService premium) {
    final error = premium.errorMessage;
    if (error != null && error.isNotEmpty) {
      return true;
    }
    final status = premium.statusMessage;
    if (status == null || status.isEmpty) {
      return false;
    }
    return !_isPendingPurchaseStatus(status);
  }

  Future<void> _completeAndLeave(PremiumPurchaseService premium) async {
    if (_didPop || _isCompletingLeave || !mounted) {
      return;
    }
    _isCompletingLeave = true;

    final successSource = _pendingSuccessSource;
    _pendingSuccessSource = null;
    setState(() {
      _isFullScreenLoading = false;
      _waitingForStoreResult = false;
    });

    if (successSource == _PremiumSuccessSource.purchase) {
      await logAnalyticsEvent(
        context,
        AnalyticsEvents.premiumPurchaseSuccess,
        parameters: premiumPlanAnalytics(premium.activeSubscriptionProductId),
      );
    } else if (successSource == _PremiumSuccessSource.restore) {
      await logAnalyticsEvent(
        context,
        AnalyticsEvents.premiumRestoreSuccess,
        parameters: premiumPlanAnalytics(premium.activeSubscriptionProductId),
      );
    }
    if (!mounted || _didPop) {
      _isCompletingLeave = false;
      return;
    }

    final shouldShowWelcome =
        _showWelcomeOnSuccess || premium.hasPremiumWelcomePending;
    _showWelcomeOnSuccess = false;
    if (shouldShowWelcome) {
      premium.consumePremiumWelcomePending();
      final planLabel = premiumWelcomePlanLabel(
        premium.activeSubscriptionProductId,
      );
      await showPremiumWelcomeDialog(context, planLabel: planLabel);
    } else {
      premium.consumePremiumWelcomePending();
    }

    if (!mounted || _didPop) {
      _isCompletingLeave = false;
      return;
    }

    _didPop = true;
    _isCompletingLeave = false;
    AppShellScope.goToSettings(context);
    Navigator.of(context).pop(true);
  }

  Future<void> _showAlreadySubscribedDialog(
    PremiumPurchaseService premium,
    String productId,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Subscription found'),
          content: Text(
            PremiumProducts.restoreInsteadMessage(productId: productId),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onContinuePressed(PremiumPurchaseService premium) async {
    if (_selectedProductId == null || _isFullScreenLoading) {
      return;
    }
    premium.clearMessages();
    setState(() {
      _isFullScreenLoading = true;
      _loadingMessage = 'Checking your subscription…';
      _waitingForStoreResult = false;
    });
    final existingProductId = await premium.resolveCurrentStoreSubscription(
      reason: 'purchase_preflight',
    );
    if (!mounted) {
      return;
    }
    if (existingProductId != null) {
      setState(() {
        _isFullScreenLoading = false;
        _waitingForStoreResult = false;
      });
      await _showAlreadySubscribedDialog(premium, existingProductId);
      return;
    }
    _showWelcomeOnSuccess = true;
    _pendingSuccessSource = _PremiumSuccessSource.purchase;
    await logAnalyticsEvent(
      context,
      AnalyticsEvents.premiumPurchaseStarted,
      parameters: premiumPlanAnalytics(_selectedProductId),
    );
    _startFullScreenLoading('Completing your purchase…');
    await premium.buy(_selectedProductId!);
    if (!mounted || !_waitingForStoreResult) {
      return;
    }
    if (!premium.isPurchasing &&
        !premium.isPremium &&
        _hasImmediateFailureState(premium)) {
      _endLoadingWithFailure(premium);
    }
  }

  Future<void> _onRestorePressed(PremiumPurchaseService premium) async {
    if (_isFullScreenLoading) {
      return;
    }
    premium.clearMessages();
    _showWelcomeOnSuccess = true;
    _pendingSuccessSource = _PremiumSuccessSource.restore;
    _startFullScreenLoading('Restoring your subscription…');
    await premium.restorePurchases();
    if (!mounted || _didPop) {
      return;
    }
    if (!premium.isRestoring &&
        !premium.isPremium &&
        _hasImmediateFailureState(premium)) {
      _endLoadingWithFailure(premium);
    }
  }

  Future<void> _openLegalPage({required String title, required Uri uri}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalWebViewScreen(title: title, url: uri.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<PremiumPurchaseService>(
      builder: (context, premium, _) {
        return PopScope(
          canPop: !_isFullScreenLoading,
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: !_isFullScreenLoading,
                  title: const Text('Go Premium'),
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ResumeApp Pro',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final benefit in kPremiumBenefits)
                                _BenefitRow(
                                  text: benefit,
                                  color: colorScheme.primary,
                                ),
                              const SizedBox(height: 16),
                              const _PremiumUpcomingHighlight(),
                              const SizedBox(height: 28),
                              Text(
                                'Choose a plan',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (premium.isLoadingProducts)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else ...[
                                for (final plan in kPremiumPlanDefinitions)
                                  _PlanCard(
                                    definition: plan,
                                    product: premium.productFor(plan.productId),
                                    savingsLabel:
                                        plan.productId == PremiumProducts.year
                                        ? premiumYearlySavingsLabel(
                                            yearlyPrice: premium
                                                .productFor(
                                                  PremiumProducts.year,
                                                )
                                                ?.rawPrice,
                                            monthlyPrice: premium
                                                .productFor(
                                                  PremiumProducts.month,
                                                )
                                                ?.rawPrice,
                                          )
                                        : null,
                                    selected:
                                        _selectedProductId == plan.productId,
                                    onTap: _isFullScreenLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedProductId =
                                                  plan.productId;
                                            });
                                          },
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              onPressed:
                                  _isFullScreenLoading ||
                                      premium.isLoadingProducts ||
                                      _selectedProductId == null
                                  ? null
                                  : () => _onContinuePressed(premium),
                              child: const Text('Continue'),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _isFullScreenLoading
                                  ? null
                                  : () => _onRestorePressed(premium),
                              child: const Text('Restore'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By continuing, you agree to our Terms of Use and Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 4,
                              children: [
                                TextButton(
                                  onPressed: _isFullScreenLoading
                                      ? null
                                      : () => _openLegalPage(
                                          title: 'Terms of Use',
                                          uri: _termsOfUseUri,
                                        ),
                                  child: const Text('Terms of Use'),
                                ),
                                TextButton(
                                  onPressed: _isFullScreenLoading
                                      ? null
                                      : () => _openLegalPage(
                                          title: 'Privacy Policy',
                                          uri: _privacyPolicyUri,
                                        ),
                                  child: const Text('Privacy Policy'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isFullScreenLoading)
                PremiumStoreLoadingOverlay(message: _loadingMessage),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumUpcomingHighlight extends StatelessWidget {
  const _PremiumUpcomingHighlight();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: isDark ? 0.35 : 0.28,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: colorScheme.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kPremiumUpcomingUpdateBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kPremiumUpcomingUpdateMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    height: 1.25,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.32),
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
    this.savingsLabel,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlanDefinition definition;
  final ProductDetails? product;
  final String? savingsLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final priceLabel = product?.price ?? '—';

    return Padding(
      padding: EdgeInsets.only(bottom: savingsLabel != null ? 6 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: selected
                ? colorScheme.primaryContainer.withValues(
                    alpha: isDark ? 0.45 : 0.35,
                  )
                : theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(
                            alpha: isDark ? 0.45 : 0.65,
                          ),
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
                          color: colorScheme.onSurface,
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
          if (savingsLabel != null) ...[
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                savingsLabel!,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w300,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
