import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/services/premium_products.dart';

/// Celebration dialog after a successful purchase or restore.
Future<void> showPremiumWelcomeDialog(
  BuildContext context, {
  required String planLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return PremiumWelcomeDialog(planLabel: planLabel);
    },
  );
}

class PremiumWelcomeDialog extends StatefulWidget {
  const PremiumWelcomeDialog({super.key, required this.planLabel});

  final String planLabel;

  @override
  State<PremiumWelcomeDialog> createState() => _PremiumWelcomeDialogState();
}

class _PremiumWelcomeDialogState extends State<PremiumWelcomeDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final horizontalInset = size.width < 380 ? 18.0 : 28.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 28,
                  maxBlastForce: 28,
                  minBlastForce: 12,
                  gravity: 0.2,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                    colorScheme.tertiary,
                    const Color(0xFFFFD54F),
                    const Color(0xFF81C784),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.celebration_rounded,
                          size: 52,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Congratulations!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ResumeApp Pro is active on your ${widget.planLabel}. '
                          'Premium templates and iCloud backup are now unlocked.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String premiumWelcomePlanLabel(String? productId) {
  return PremiumProducts.planLabelFor(productId);
}
