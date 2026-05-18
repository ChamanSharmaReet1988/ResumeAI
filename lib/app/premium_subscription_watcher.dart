import 'package:flutter/widgets.dart';

/// Wraps the app shell. Pro status is checked on launch (local StoreKit read only)
/// and when the user taps Restore purchases — not on every resume (avoids Apple ID prompts).
class PremiumSubscriptionWatcher extends StatefulWidget {
  const PremiumSubscriptionWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<PremiumSubscriptionWatcher> createState() =>
      _PremiumSubscriptionWatcherState();
}

class _PremiumSubscriptionWatcherState extends State<PremiumSubscriptionWatcher> {
  @override
  Widget build(BuildContext context) => widget.child;
}
