import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

/// Shows the platform in-app review dialog from the Templates tab.
///
/// - First Templates visit → prompt once
/// - Then after every 3 additional Templates visits → prompt again
///
/// Uses Apple's review popup on iOS and Google Play's on Android when available.
class InAppReviewPromptService {
  InAppReviewPromptService({
    Future<bool> Function()? isReviewAvailable,
    Future<void> Function()? requestReview,
    Future<Box<dynamic>> Function()? openBox,
  }) {
    _isReviewAvailable =
        isReviewAvailable ?? () => InAppReview.instance.isAvailable();
    _requestReview =
        requestReview ?? () => InAppReview.instance.requestReview();
    _openBox = openBox ?? _defaultOpenBox;
  }

  static const int templatesTabIndex = 1;
  static const int _visitsBeforeRepeatPrompt = 3;
  static const String _boxName = 'app_prefs';
  static const String _hasPromptedOnceKey = 'review_prompt_has_shown_once';
  static const String _visitsSincePromptKey =
      'review_prompt_visits_since_last';

  late final Future<bool> Function() _isReviewAvailable;
  late final Future<void> Function() _requestReview;
  late final Future<Box<dynamic>> Function() _openBox;

  static Future<Box<dynamic>> _defaultOpenBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  /// Call when the user selects the Templates tab.
  Future<void> handleTemplatesTabSelected() async {
    try {
      final box = await _openBox();
      final hasPromptedOnce =
          (box.get(_hasPromptedOnceKey) as bool?) ?? false;

      if (!hasPromptedOnce) {
        await _requestNativeReview();
        await box.put(_hasPromptedOnceKey, true);
        await box.put(_visitsSincePromptKey, 0);
        return;
      }

      final visitsSincePrompt =
          ((box.get(_visitsSincePromptKey) as int?) ?? 0) + 1;
      await box.put(_visitsSincePromptKey, visitsSincePrompt);

      if (visitsSincePrompt >= _visitsBeforeRepeatPrompt) {
        await _requestNativeReview();
        await box.put(_visitsSincePromptKey, 0);
      }
    } catch (error, stackTrace) {
      assert(() {
        debugPrint(
          'InAppReviewPromptService failed: $error\n$stackTrace',
        );
        return true;
      }());
    }
  }

  Future<void> _requestNativeReview() async {
    try {
      if (await _isReviewAvailable()) {
        await _requestReview();
      }
    } catch (error, stackTrace) {
      assert(() {
        debugPrint('requestReview failed: $error\n$stackTrace');
        return true;
      }());
    }
  }
}
