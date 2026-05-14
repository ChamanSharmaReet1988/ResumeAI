import 'package:hive_flutter/hive_flutter.dart';

/// Cross-session UI flags (Hive box `app_prefs`, or in-memory for tests).
class AppPreferences {
  AppPreferences._(
    this._getDismissed,
    this._setDismissed,
    this._getICloudAutoSyncEnabled,
    this._setICloudAutoSyncEnabled,
  );

  static const _resumeOrderNudgeDismissedKey = 'resume_order_nudge_dismissed';
  static const _iCloudAutoSyncEnabledKey = 'icloud_auto_sync_enabled';

  final bool Function() _getDismissed;
  final Future<void> Function(bool) _setDismissed;
  final bool Function() _getICloudAutoSyncEnabled;
  final Future<void> Function(bool) _setICloudAutoSyncEnabled;

  static Future<AppPreferences> open() async {
    final box = await Hive.openBox<dynamic>('app_prefs');
    if (!box.containsKey(_iCloudAutoSyncEnabledKey)) {
      await box.put(_iCloudAutoSyncEnabledKey, false);
    }
    return AppPreferences._(
      () => (box.get(_resumeOrderNudgeDismissedKey) as bool?) ?? false,
      (value) async => box.put(_resumeOrderNudgeDismissedKey, value),
      () {
        final v = box.get(_iCloudAutoSyncEnabledKey);
        return v is bool ? v : false;
      },
      (value) async => box.put(_iCloudAutoSyncEnabledKey, value),
    );
  }

  /// Ephemeral prefs for widget tests (no disk I/O).
  factory AppPreferences.inMemory({
    bool resumeOrderNudgeDismissed = false,
    bool iCloudAutoSyncEnabled = false,
  }) {
    var dismissed = resumeOrderNudgeDismissed;
    var autoSyncEnabled = iCloudAutoSyncEnabled;
    return AppPreferences._(
      () => dismissed,
      (value) async {
        dismissed = value;
      },
      () => autoSyncEnabled,
      (value) async {
        autoSyncEnabled = value;
      },
    );
  }

  bool get resumeOrderNudgeDismissed => _getDismissed();
  bool get iCloudAutoSyncEnabled => _getICloudAutoSyncEnabled();

  Future<void> setResumeOrderNudgeDismissed(bool value) => _setDismissed(value);

  Future<void> setICloudAutoSyncEnabled(bool value) =>
      _setICloudAutoSyncEnabled(value);
}
