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
    this._getIsPremium,
    this._setIsPremium,
    this._getDebugPremiumOverrideEnabled,
    this._setDebugPremiumOverrideEnabled,
  );

  static const _resumeOrderNudgeDismissedKey = 'resume_order_nudge_dismissed';
  static const _iCloudAutoSyncEnabledKey = 'icloud_auto_sync_enabled';
  static const _googleDriveAutoSyncEnabledKey = 'google_drive_auto_sync_enabled';
  static const _isPremiumKey = 'is_premium';
  static const _debugPremiumOverrideEnabledKey =
      'debug_premium_override_enabled';

  final bool Function() _getDismissed;
  final Future<void> Function(bool) _setDismissed;
  final bool Function() _getICloudAutoSyncEnabled;
  final Future<void> Function(bool) _setICloudAutoSyncEnabled;
  final bool Function() _getGoogleDriveAutoSyncEnabled;
  final Future<void> Function(bool) _setGoogleDriveAutoSyncEnabled;
  final bool Function() _getIsPremium;
  final Future<void> Function(bool) _setIsPremium;
  final bool Function() _getDebugPremiumOverrideEnabled;
  final Future<void> Function(bool) _setDebugPremiumOverrideEnabled;

  static Future<AppPreferences> open() async {
    final box = await Hive.openBox<dynamic>('app_prefs');
    if (!box.containsKey(_iCloudAutoSyncEnabledKey)) {
      await box.put(_iCloudAutoSyncEnabledKey, false);
    }
    if (!box.containsKey(_googleDriveAutoSyncEnabledKey)) {
      await box.put(_googleDriveAutoSyncEnabledKey, false);
    }
    if (!box.containsKey(_isPremiumKey)) {
      await box.put(_isPremiumKey, false);
    }
    if (!box.containsKey(_debugPremiumOverrideEnabledKey)) {
      await box.put(_debugPremiumOverrideEnabledKey, false);
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
      () {
        final v = box.get(_isPremiumKey);
        return v is bool ? v : false;
      },
      (value) async => box.put(_isPremiumKey, value),
      () {
        final v = box.get(_debugPremiumOverrideEnabledKey);
        return v is bool ? v : false;
      },
      (value) async => box.put(_debugPremiumOverrideEnabledKey, value),
    );
  }

  /// Ephemeral prefs for widget tests (no disk I/O).
  factory AppPreferences.inMemory({
    bool resumeOrderNudgeDismissed = false,
    bool iCloudAutoSyncEnabled = false,
    bool googleDriveAutoSyncEnabled = false,
    bool isPremium = false,
    bool debugPremiumOverrideEnabled = false,
  }) {
    var dismissed = resumeOrderNudgeDismissed;
    var iCloudAuto = iCloudAutoSyncEnabled;
    var driveAuto = googleDriveAutoSyncEnabled;
    var premium = isPremium;
    var debugPremiumOverride = debugPremiumOverrideEnabled;
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
      () => premium,
      (value) async {
        premium = value;
      },
      () => debugPremiumOverride,
      (value) async {
        debugPremiumOverride = value;
      },
    );
  }

  bool get resumeOrderNudgeDismissed => _getDismissed();
  bool get iCloudAutoSyncEnabled => _getICloudAutoSyncEnabled();
  bool get googleDriveAutoSyncEnabled => _getGoogleDriveAutoSyncEnabled();
  bool get isPremium => _getIsPremium();
  bool get debugPremiumOverrideEnabled => _getDebugPremiumOverrideEnabled();

  Future<void> setResumeOrderNudgeDismissed(bool value) => _setDismissed(value);

  Future<void> setICloudAutoSyncEnabled(bool value) =>
      _setICloudAutoSyncEnabled(value);

  Future<void> setGoogleDriveAutoSyncEnabled(bool value) =>
      _setGoogleDriveAutoSyncEnabled(value);

  Future<void> setIsPremium(bool value) => _setIsPremium(value);

  Future<void> setDebugPremiumOverrideEnabled(bool value) =>
      _setDebugPremiumOverrideEnabled(value);
}
