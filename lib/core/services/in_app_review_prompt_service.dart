import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

/// Home-screen rating prompt using the system in-app review UI
/// (Apple’s default stars sheet / Play In-App Review).
///
/// Shows when the user has exactly one resume and has not marked rating done
/// (e.g. via Settings → Rate App). Retries each Home visit; the OS may still
/// suppress the sheet based on its own quota.
class InAppReviewPromptService {
  InAppReviewPromptService({
    Future<bool> Function()? readRatingCompleted,
    Future<void> Function()? writeRatingCompleted,
    Future<void> Function()? openStoreListing,
    Future<void> Function()? requestNativeReview,
    Future<Box<dynamic>> Function()? openBox,
    FlutterSecureStorage? secureStorage,
  }) {
    _readRatingCompleted =
        readRatingCompleted ?? (() => _defaultReadRatingCompleted());
    _writeRatingCompleted =
        writeRatingCompleted ?? (() => _defaultWriteRatingCompleted());
    _openStoreListing = openStoreListing ?? _defaultOpenStoreListing;
    _requestNativeReview =
        requestNativeReview ?? _defaultRequestNativeReview;
    _openBox = openBox ?? _defaultOpenBox;
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

  late final Future<bool> Function() _readRatingCompleted;
  late final Future<void> Function() _writeRatingCompleted;
  late final Future<void> Function() _openStoreListing;
  late final Future<void> Function() _requestNativeReview;
  late final Future<Box<dynamic>> Function() _openBox;
  late final FlutterSecureStorage _secureStorage;

  bool _promptInFlight = false;
  bool _skippedUntilNextHomeVisit = false;

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

  /// Call when the Home tab becomes active so a deferred prompt can show again.
  void onArrivedAtHome() {
    _skippedUntilNextHomeVisit = false;
  }

  /// Do not show again until the next Home visit.
  void deferUntilNextHomeVisit() {
    _skippedUntilNextHomeVisit = true;
  }

  /// Returns true when Home should present the system rating prompt.
  Future<bool> claimHomePrompt({required int resumeCount}) async {
    if (_promptInFlight ||
        _skippedUntilNextHomeVisit ||
        resumeCount != 1) {
      return false;
    }
    _promptInFlight = true;
    if (await hasCompletedRating()) {
      _promptInFlight = false;
      return false;
    }
    return true;
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
