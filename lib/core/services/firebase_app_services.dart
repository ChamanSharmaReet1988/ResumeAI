import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Safe Firebase bootstrap for apps that may not yet have native config files.
///
/// The app continues to run if Firebase is not configured on the platform.
class FirebaseAppServices {
  FirebaseAppServices._({
    required this.isEnabled,
    this.analytics,
    this.analyticsObserver,
    this.remoteConfig,
  });

  final bool isEnabled;
  final FirebaseAnalytics? analytics;
  final FirebaseAnalyticsObserver? analyticsObserver;
  final FirebaseRemoteConfig? remoteConfig;

  static const Map<String, Object> _defaultRemoteConfigValues = {
    'resume_templates_enabled': true,
    'cover_letter_templates_enabled': true,
    'optimize_resume_enabled': true,
  };

  static Future<FirebaseAppServices> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final analytics = FirebaseAnalytics.instance;
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(_defaultRemoteConfigValues);
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 12),
        ),
      );

      unawaited(_warmRemoteConfig(remoteConfig));

      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      _installCrashlyticsHandlers();

      return FirebaseAppServices._(
        isEnabled: true,
        analytics: analytics,
        analyticsObserver: FirebaseAnalyticsObserver(analytics: analytics),
        remoteConfig: remoteConfig,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Firebase initialization skipped: $error');
        debugPrint('$stackTrace');
      }
      return FirebaseAppServices._(isEnabled: false);
    }
  }

  static void _installCrashlyticsHandlers() {
    final previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterErrorHandler?.call(details);
      unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
    };

    final previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
      );
      final wasHandled = previousPlatformOnError?.call(error, stack) ?? false;
      return wasHandled || true;
    };
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final analytics = this.analytics;
    if (analytics == null) {
      return;
    }
    await analytics.logEvent(name: name, parameters: parameters);
  }

  String getString(String key, {String fallback = ''}) {
    return remoteConfig?.getString(key) ?? fallback;
  }

  bool getBool(String key, {bool fallback = false}) {
    return remoteConfig?.getBool(key) ?? fallback;
  }

  int getInt(String key, {int fallback = 0}) {
    return remoteConfig?.getInt(key) ?? fallback;
  }

  double getDouble(String key, {double fallback = 0}) {
    return remoteConfig?.getDouble(key) ?? fallback;
  }

  Future<bool> refreshRemoteConfig() async {
    final remoteConfig = this.remoteConfig;
    if (remoteConfig == null) {
      return false;
    }
    return remoteConfig.fetchAndActivate();
  }

  static Future<bool> _warmRemoteConfig(
    FirebaseRemoteConfig remoteConfig,
  ) async {
    try {
      return await remoteConfig.fetchAndActivate();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Remote Config fetch skipped: $error');
      }
      return false;
    }
  }
}
