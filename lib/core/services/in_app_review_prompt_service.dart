import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

/// System in-app review (Apple stars sheet / Play In-App Review).
///
/// Flow: after the user shares once, show the rate popup the next time they
/// land on Home for the 2nd visit (not immediately after create or share).
/// The OS may still suppress the sheet based on its own quota.
class InAppReviewPromptService {
  InAppReviewPromptService({
    Future<bool> Function()? readRatingCompleted,
    Future<void> Function()? writeRatingCompleted,
    Future<bool> Function()? readHasShared,
    Future<void> Function()? writeHasShared,
    Future<void> Function()? openStoreListing,
    Future<void> Function()? requestNativeReview,
    Future<Box<dynamic>> Function()? openBox,
    Future<int> Function()? readHomeVisitCount,
    Future<void> Function(int count)? writeHomeVisitCount,
    FlutterSecureStorage? secureStorage,
  }) {
    _readRatingCompleted =
        readRatingCompleted ?? (() => _defaultReadRatingCompleted());
    _writeRatingCompleted =
        writeRatingCompleted ?? (() => _defaultWriteRatingCompleted());
    _readHasShared = readHasShared ?? (() => _defaultReadHasShared());
    _writeHasShared = writeHasShared ?? (() => _defaultWriteHasShared());
    _openStoreListing = openStoreListing ?? _defaultOpenStoreListing;
    _requestNativeReview =
        requestNativeReview ?? _defaultRequestNativeReview;
    _openBox = openBox ?? _defaultOpenBox;
    _readHomeVisitCount =
        readHomeVisitCount ?? (() => _defaultReadHomeVisitCount());
    _writeHomeVisitCount =
        writeHomeVisitCount ?? ((count) => _defaultWriteHomeVisitCount(count));
    _secureStorage =
        secureStorage ??
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
            synchronizable: true,
          ),
        );
  }

  static const int templatesTabIndex = 1;
  static const String appStoreId = '6768385894';
  static const String _boxName = 'app_prefs';
  static const String _ratedKey = 'in_app_review_completed';
  static const String _hasSharedKey = 'in_app_review_has_shared';
  static const String _homeVisitCountKey = 'in_app_review_home_visit_count';
  static const int _minHomeVisitsBeforePrompt = 2;

  late final Future<bool> Function() _readRatingCompleted;
  late final Future<void> Function() _writeRatingCompleted;
  late final Future<bool> Function() _readHasShared;
  late final Future<void> Function() _writeHasShared;
  late final Future<void> Function() _openStoreListing;
  late final Future<void> Function() _requestNativeReview;
  late final Future<Box<dynamic>> Function() _openBox;
  late final Future<int> Function() _readHomeVisitCount;
  late final Future<void> Function(int count) _writeHomeVisitCount;
  late final FlutterSecureStorage _secureStorage;

  bool _promptInFlight = false;
  bool _skippedUntilNextHomeVisit = false;
  int _homeVisitCount = 0;
  bool _homeVisitCountHydrated = false;
  bool? _hasSharedCached;

  static Future<Box<dynamic>> _defaultOpenBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  Future<bool> _defaultReadRatingCompleted() async {
    try {
      final durable = await _secureStorage.read(key: _ratedKey);
      if (durable == 'true') {
        return true;
      }
    } catch (error, stackTrace) {
      _debugLog('read secure rating flag failed: $error\n$stackTrace');
    }
    try {
      final box = await _openBox();
      return (box.get(_ratedKey) as bool?) ?? false;
    } catch (error, stackTrace) {
      _debugLog('read hive rating flag failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> _defaultWriteRatingCompleted() async {
    try {
      await _secureStorage.write(key: _ratedKey, value: 'true');
    } catch (error, stackTrace) {
      _debugLog('write secure rating flag failed: $error\n$stackTrace');
    }
    try {
      final box = await _openBox();
      await box.put(_ratedKey, true);
    } catch (error, stackTrace) {
      _debugLog('write hive rating flag failed: $error\n$stackTrace');
    }
  }

  Future<bool> _defaultReadHasShared() async {
    try {
      final box = await _openBox();
      return (box.get(_hasSharedKey) as bool?) ?? false;
    } catch (error) {
      _debugLog('read has-shared flag failed: $error');
      return false;
    }
  }

  Future<void> _defaultWriteHasShared() async {
    try {
      final box = await _openBox();
      await box.put(_hasSharedKey, true);
    } catch (error) {
      _debugLog('write has-shared flag failed: $error');
    }
  }

  Future<int> _defaultReadHomeVisitCount() async {
    try {
      final box = await _openBox();
      return (box.get(_homeVisitCountKey) as int?) ?? 0;
    } catch (error) {
      _debugLog('read home visit count failed: $error');
      return _homeVisitCount;
    }
  }

  Future<void> _defaultWriteHomeVisitCount(int count) async {
    try {
      final box = await _openBox();
      await box.put(_homeVisitCountKey, count);
    } catch (error) {
      _debugLog('write home visit count failed: $error');
    }
  }

  static Future<void> _defaultOpenStoreListing() async {
    final review = InAppReview.instance;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await review.openStoreListing(appStoreId: appStoreId);
    } else {
      await review.openStoreListing();
    }
  }

  static Future<void> _defaultRequestNativeReview() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
      return;
    }
    await _defaultOpenStoreListing();
  }

  Future<bool> hasCompletedRating() => _readRatingCompleted();

  Future<void> markRatingCompleted() => _writeRatingCompleted();

  Future<void> openStoreListing() => _openStoreListing();

  /// Shows Apple / Google’s system rating UI when available.
  Future<void> requestNativeReview() => _requestNativeReview();

  Future<bool> hasSharedOnce() async {
    final cached = _hasSharedCached;
    if (cached != null) {
      return cached;
    }
    final value = await _readHasShared();
    _hasSharedCached = value;
    return value;
  }

  /// Records that the user shared at least once (does not show the rate UI).
  Future<void> markSharedOnce() async {
    if (await hasSharedOnce()) {
      return;
    }
    await _writeHasShared();
    _hasSharedCached = true;
  }

  /// Call when the Home tab becomes active so a deferred prompt can show again.
  void onArrivedAtHome() {
    _skippedUntilNextHomeVisit = false;
  }

  /// Do not show again until the next Home visit.
  void deferUntilNextHomeVisit() {
    _skippedUntilNextHomeVisit = true;
  }

  /// Counts this Home appearance. First launch is visit 1; visit 2+ can show
  /// the rate prompt after a share.
  Future<int> recordHomeVisit() async {
    if (!_homeVisitCountHydrated) {
      _homeVisitCount = await _readHomeVisitCount();
      _homeVisitCountHydrated = true;
    }
    _homeVisitCount += 1;
    await _writeHomeVisitCount(_homeVisitCount);
    return _homeVisitCount;
  }

  Future<int> _resolvedHomeVisitCount() async {
    if (_homeVisitCountHydrated) {
      return _homeVisitCount;
    }
    _homeVisitCount = await _readHomeVisitCount();
    _homeVisitCountHydrated = true;
    return _homeVisitCount;
  }

  /// Returns true when Home should present the system rating prompt.
  ///
  /// Requires: at least one resume, one prior share, and 2nd+ Home visit.
  Future<bool> claimHomePrompt({required int resumeCount}) async {
    if (_promptInFlight ||
        _skippedUntilNextHomeVisit ||
        resumeCount < 1) {
      return false;
    }
    if (!await hasSharedOnce()) {
      return false;
    }
    if (await _resolvedHomeVisitCount() < _minHomeVisitsBeforePrompt) {
      return false;
    }
    _promptInFlight = true;
    if (await hasCompletedRating()) {
      _promptInFlight = false;
      return false;
    }
    return true;
  }

  /// Call after a successful share — unlocks Home rate on the 2nd visit.
  /// Does not show the rating UI immediately.
  Future<void> promptAfterShare() async {
    await markSharedOnce();
  }

  /// PDF download no longer shows the rate UI; share + 2nd Home does.
  /// Kept so existing call sites stay safe / no-op for prompting.
  Future<void> promptAfterValueMoment() async {
    // Intentionally no immediate prompt. Rate shows on 2nd Home after share.
  }

  void endPromptOffer() {
    _promptInFlight = false;
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint('InAppReviewPromptService: $message');
      return true;
    }());
  }
}
