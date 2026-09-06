import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.destinationFor', () {
    test('parses App Store custom scheme', () {
      expect(
        DeepLinkService.destinationFor(Uri.parse('resumeai://templates')),
        DeepLinkDestination.templates,
      );
      expect(
        DeepLinkService.destinationFor(Uri.parse('resumeai:///templates')),
        DeepLinkDestination.templates,
      );
    });

    test('parses Firebase Hosting https links', () {
      expect(
        DeepLinkService.destinationFor(
          Uri.parse('https://resumeapp-be8a3.web.app/templates'),
        ),
        DeepLinkDestination.templates,
      );
      expect(
        DeepLinkService.destinationFor(
          Uri.parse('https://resumeapp-be8a3.firebaseapp.com/templates/'),
        ),
        DeepLinkDestination.templates,
      );
    });

    test('parses screen query param', () {
      expect(
        DeepLinkService.destinationFor(
          Uri.parse('https://resumeapp-be8a3.web.app/open?screen=templates'),
        ),
        DeepLinkDestination.templates,
      );
    });

    test('ignores unrelated links', () {
      expect(
        DeepLinkService.destinationFor(Uri.parse('https://example.com/templates')),
        isNull,
      );
      expect(
        DeepLinkService.destinationFor(Uri.parse('resumeai://settings')),
        isNull,
      );
      expect(DeepLinkService.destinationFor(null), isNull);
    });

    test('app store event deep link constant is valid', () {
      expect(
        DeepLinkService.destinationFor(
          Uri.parse(DeepLinkService.appStoreEventDeepLink),
        ),
        DeepLinkDestination.templates,
      );
    });
  });

  group('DeepLinkService pending destination', () {
    test('takePendingDestination clears value', () {
      final service = DeepLinkService(enablePlatformLinks: false);
      service.seedPendingForTest(DeepLinkDestination.templates);
      expect(service.takePendingDestination(), DeepLinkDestination.templates);
      expect(service.takePendingDestination(), isNull);
    });
  });
}
