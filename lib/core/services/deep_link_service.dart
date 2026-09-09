import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'analytics_events.dart';
import 'firebase_app_services.dart';

/// Destinations that store / marketing deep links can open.
enum DeepLinkDestination {
  templates,
}

/// Handles App Store / Play deep links into ResumeAI.
///
/// Supported URLs:
/// - Custom scheme (use this in App Store Connect): `resumeai://templates`
/// - Firebase Hosting Universal Links:
///   `https://resumeapp-be8a3.web.app/templates`
///   `https://resumeapp-be8a3.firebaseapp.com/templates`
///
/// Note: Firebase Dynamic Links is shut down. This uses App Links /
/// Universal Links + a custom scheme, with Firebase Analytics logging.
class DeepLinkService {
  DeepLinkService({
    AppLinks? appLinks,
    FirebaseAppServices? firebase,
    bool enablePlatformLinks = true,
  }) : _appLinks = appLinks ?? AppLinks(),
       _firebase = firebase,
       _enablePlatformLinks = enablePlatformLinks;

  static const String urlScheme = 'resumeai';
  static const String templatesPath = 'templates';
  static const List<String> httpsHosts = [
    'resumeapp-be8a3.web.app',
    'resumeapp-be8a3.firebaseapp.com',
  ];

  /// Paste this into App Store Connect → In-App Event → Deep Link.
  static const String appStoreEventDeepLink = '$urlScheme://$templatesPath';

  final AppLinks _appLinks;
  final FirebaseAppServices? _firebase;
  final bool _enablePlatformLinks;

  final StreamController<DeepLinkDestination> _destinationsController =
      StreamController<DeepLinkDestination>.broadcast();

  StreamSubscription<Uri>? _uriSubscription;
  DeepLinkDestination? _pending;
  bool _started = false;
  String? _lastHandledLink;

  /// Emits destinations for warm starts (app already running).
  Stream<DeepLinkDestination> get destinations =>
      _destinationsController.stream;

  /// Cold-start / first-launch destination, if any.
  DeepLinkDestination? get pendingDestination => _pending;

  /// Takes and clears any pending cold-start destination.
  DeepLinkDestination? takePendingDestination() {
    final value = _pending;
    _pending = null;
    return value;
  }

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    if (!_enablePlatformLinks) {
      return;
    }

    try {
      final initial = await _appLinks.getInitialLink();
      final initialDestination = destinationFor(initial);
      if (initialDestination != null && initial != null) {
        _rememberHandled(initial);
        _pending = initialDestination;
        await _logOpen(initialDestination, initial, coldStart: true);
      }
    } catch (error, stackTrace) {
      assert(() {
        debugPrint('DeepLinkService initial link failed: $error\n$stackTrace');
        return true;
      }());
    }

    _uriSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (_wasAlreadyHandled(uri)) {
          return;
        }
        final destination = destinationFor(uri);
        if (destination == null) {
          return;
        }
        _rememberHandled(uri);
        _pending = destination;
        unawaited(_logOpen(destination, uri, coldStart: false));
        if (!_destinationsController.isClosed) {
          _destinationsController.add(destination);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        assert(() {
          debugPrint('DeepLinkService stream error: $error\n$stackTrace');
          return true;
        }());
      },
    );
  }

  void _rememberHandled(Uri uri) {
    _lastHandledLink = uri.toString();
  }

  bool _wasAlreadyHandled(Uri uri) {
    return _lastHandledLink == uri.toString();
  }

  @visibleForTesting
  void seedPendingForTest(DeepLinkDestination destination) {
    _pending = destination;
  }

  @visibleForTesting
  void emitForTest(DeepLinkDestination destination) {
    _pending = destination;
    if (!_destinationsController.isClosed) {
      _destinationsController.add(destination);
    }
  }

  static DeepLinkDestination? destinationFor(Uri? uri) {
    if (uri == null) {
      return null;
    }

    final pathSegments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .map((segment) => segment.trim().toLowerCase())
        .toList(growable: false);
    final host = uri.host.trim().toLowerCase();
    final scheme = uri.scheme.trim().toLowerCase();

    final screenQuery = uri.queryParameters['screen']?.trim().toLowerCase();
    if (screenQuery == templatesPath) {
      return DeepLinkDestination.templates;
    }

    if (scheme == urlScheme) {
      // resumeai://templates  OR  resumeai:///templates
      if (host == templatesPath || pathSegments.contains(templatesPath)) {
        return DeepLinkDestination.templates;
      }
      return null;
    }

    if (scheme == 'https' || scheme == 'http') {
      if (!httpsHosts.contains(host)) {
        return null;
      }
      if (pathSegments.contains(templatesPath)) {
        return DeepLinkDestination.templates;
      }
    }

    return null;
  }

  Future<void> _logOpen(
    DeepLinkDestination destination,
    Uri? uri, {
    required bool coldStart,
  }) async {
    final firebase = _firebase;
    if (firebase == null || !firebase.isEnabled) {
      return;
    }
    try {
      await firebase.logEvent(
        AnalyticsEvents.deepLinkOpen,
        parameters: {
          'destination': destination.name,
          'cold_start': coldStart ? 1 : 0,
          if (uri != null) 'link_host': uri.host.isEmpty ? uri.scheme : uri.host,
          if (uri != null) 'link_path': uri.path,
        },
      );
    } catch (_) {
      // Analytics must never block navigation.
    }
  }

  Future<void> dispose() async {
    await _uriSubscription?.cancel();
    _uriSubscription = null;
    await _destinationsController.close();
  }
}
