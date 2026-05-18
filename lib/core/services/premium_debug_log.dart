import 'package:flutter/foundation.dart';

/// Debug-only logs for Pro / StoreKit subscription checks.
abstract final class PremiumDebugLog {
  static const String _tag = '[Premium]';

  static void section(String title) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('$_tag ── $title ──');
  }

  static void log(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('$_tag $message');
  }

  static void logPair(String key, Object? value) {
    log('$key: $value');
  }
}
