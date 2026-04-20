import 'package:hive_flutter/hive_flutter.dart';

/// Cross-session UI flags (Hive box `app_prefs`, or in-memory for tests).
class AppPreferences {
  AppPreferences._(this._getDismissed, this._setDismissed);

  static const _resumeOrderNudgeDismissedKey = 'resume_order_nudge_dismissed';

  final bool Function() _getDismissed;
  final Future<void> Function(bool) _setDismissed;

  static Future<AppPreferences> open() async {
    final box = await Hive.openBox<dynamic>('app_prefs');
    return AppPreferences._(
      () => (box.get(_resumeOrderNudgeDismissedKey) as bool?) ?? false,
      (value) async => box.put(_resumeOrderNudgeDismissedKey, value),
    );
  }

  /// Ephemeral prefs for widget tests (no disk I/O).
  factory AppPreferences.inMemory({bool resumeOrderNudgeDismissed = false}) {
    var dismissed = resumeOrderNudgeDismissed;
    return AppPreferences._(
      () => dismissed,
      (value) async {
        dismissed = value;
      },
    );
  }

  bool get resumeOrderNudgeDismissed => _getDismissed();

  Future<void> setResumeOrderNudgeDismissed(bool value) =>
      _setDismissed(value);
}
