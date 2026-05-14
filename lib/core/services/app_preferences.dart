import 'package:hive_flutter/hive_flutter.dart';

/// Cross-session UI flags (Hive box `app_prefs`, or in-memory for tests).
class AppPreferences {
  AppPreferences._(
    this._getDismissed,
    this._setDismissed,
    this._getICloudAutoSyncEnabled,
    this._setICloudAutoSyncEnabled,
    this._getGoogleDriveAutoSyncEnabled,
    this._setGoogleDriveAutoSyncEnabled,
  );

  static const _resumeOrderNudgeDismissedKey = 'resume_order_nudge_dismissed';
  static const _iCloudAutoSyncEnabledKey = 'icloud_auto_sync_enabled';
  static const _googleDriveAutoSyncEnabledKey = 'google_drive_auto_sync_enabled';

  final bool Function() _getDismissed;
  final Future<void> Function(bool) _setDismissed;
  final bool Function() _getICloudAutoSyncEnabled;
  final Future<void> Function(bool) _setICloudAutoSyncEnabled;
  final bool Function() _getGoogleDriveAutoSyncEnabled;
  final Future<void> Function(bool) _setGoogleDriveAutoSyncEnabled;

  static Future<AppPreferences> open() async {
    final box = await Hive.openBox<dynamic>('app_prefs');
    if (!box.containsKey(_iCloudAutoSyncEnabledKey)) {
      await box.put(_iCloudAutoSyncEnabledKey, false);
    }
    if (!box.containsKey(_googleDriveAutoSyncEnabledKey)) {
      await box.put(_googleDriveAutoSyncEnabledKey, false);
    }
    return AppPreferences._(
      () => (box.get(_resumeOrderNudgeDismissedKey) as bool?) ?? false,
      (value) async => box.put(_resumeOrderNudgeDismissedKey, value),
      () {
        final v = box.get(_iCloudAutoSyncEnabledKey);
        return v is bool ? v : false;
      },
      (value) async => box.put(_iCloudAutoSyncEnabledKey, value),
      () {
        final v = box.get(_googleDriveAutoSyncEnabledKey);
        return v is bool ? v : false;
      },
      (value) async => box.put(_googleDriveAutoSyncEnabledKey, value),
    );
  }

  /// Ephemeral prefs for widget tests (no disk I/O).
  factory AppPreferences.inMemory({
    bool resumeOrderNudgeDismissed = false,
    bool iCloudAutoSyncEnabled = false,
    bool googleDriveAutoSyncEnabled = false,
  }) {
    var dismissed = resumeOrderNudgeDismissed;
    var iCloudAuto = iCloudAutoSyncEnabled;
    var driveAuto = googleDriveAutoSyncEnabled;
    return AppPreferences._(
      () => dismissed,
      (value) async {
        dismissed = value;
      },
      () => iCloudAuto,
      (value) async {
        iCloudAuto = value;
      },
      () => driveAuto,
      (value) async {
        driveAuto = value;
      },
    );
  }

  bool get resumeOrderNudgeDismissed => _getDismissed();
  bool get iCloudAutoSyncEnabled => _getICloudAutoSyncEnabled();
  bool get googleDriveAutoSyncEnabled => _getGoogleDriveAutoSyncEnabled();

  Future<void> setResumeOrderNudgeDismissed(bool value) => _setDismissed(value);

  Future<void> setICloudAutoSyncEnabled(bool value) =>
      _setICloudAutoSyncEnabled(value);

  Future<void> setGoogleDriveAutoSyncEnabled(bool value) =>
      _setGoogleDriveAutoSyncEnabled(value);
}
