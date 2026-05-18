import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/services/premium_purchase_service.dart';

/// Wraps the app shell. Pro status is checked on launch (local StoreKit read only)
/// and when the user taps Restore purchases — not on every resume (avoids Apple ID prompts).
class PremiumSubscriptionWatcher extends StatefulWidget {
  const PremiumSubscriptionWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<PremiumSubscriptionWatcher> createState() =>
      _PremiumSubscriptionWatcherState();
}

class _PremiumSubscriptionWatcherState extends State<PremiumSubscriptionWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    final premium = context.read<PremiumPurchaseService>();
    premium.verifyPremiumLocally(reason: 'app_resume');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
