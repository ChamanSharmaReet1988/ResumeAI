import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/analytics_events.dart';

void main() {
  test('prefixes android analytics event names', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      platformAnalyticsEventName('resume_created'),
      'resumeapp_android_resume_created',
    );
    expect(
      platformAnalyticsEventName('resumeapp_android_resume_created'),
      'resumeapp_android_resume_created',
    );
  });

  test('prefixes ios analytics event names', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      platformAnalyticsEventName('resume_created'),
      'resumeapp_ios_resume_created',
    );
  });

  test('all analytics event constants fit firebase 40-char limit with android prefix', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    const events = [
      AnalyticsEvents.resumeCreated,
      AnalyticsEvents.resumeExportedPdf,
      AnalyticsEvents.resumeSharedPdf,
      AnalyticsEvents.resumeSharedDocx,
      AnalyticsEvents.resumeTemplateSelected,
      AnalyticsEvents.coverLetterCreated,
      AnalyticsEvents.coverLetterSharedPdf,
      AnalyticsEvents.coverLetterTemplateSelected,
      AnalyticsEvents.premiumPurchaseStarted,
      AnalyticsEvents.premiumPurchaseSuccess,
      AnalyticsEvents.premiumRestoreSuccess,
      AnalyticsEvents.iCloudBackupSync,
      AnalyticsEvents.deepLinkOpen,
    ];

    for (final event in events) {
      final full = platformAnalyticsEventName(event);
      expect(full.length, lessThanOrEqualTo(40), reason: full);
      expect(full.startsWith('resumeapp_android_'), isTrue);
    }
  });
}
