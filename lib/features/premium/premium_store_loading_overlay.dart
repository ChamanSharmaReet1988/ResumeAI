import 'package:flutter/material.dart';

/// Full-screen blocker while purchase or restore is in progress.
class PremiumStoreLoadingOverlay extends StatelessWidget {
  const PremiumStoreLoadingOverlay({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AbsorbPointer(
      child: ColoredBox(
        color: colorScheme.surface.withValues(alpha: 0.96),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please wait. Do not close the app.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
