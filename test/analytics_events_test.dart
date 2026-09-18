import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_builder_section_order.dart';
import 'package:resume_app/core/models/resume_models.dart';
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
      AnalyticsEvents.resumeSectionViewed,
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

  test('resume builder section events use readable names', () {
    expect(
      resumeBuilderSectionAnalyticsName(
        step: 0,
        sectionId: null,
        customSections: const [],
      ),
      'Personal Information',
    );
    expect(
      resumeBuilderSectionAnalyticsName(
        step: 1,
        sectionId: ResumeBuilderSectionIds.work,
        customSections: const [],
      ),
      'Work Experience',
    );
    expect(
      resumeBuilderSectionAnalyticsName(
        step: 2,
        sectionId: ResumeBuilderSectionIds.skills,
        customSections: const [],
      ),
      'Skills',
    );
    expect(
      resumeBuilderSectionAnalytics(
        step: 1,
        sectionId: ResumeBuilderSectionIds.work,
        customSections: const [],
      ),
      {'section_id': 'work', 'section_name': 'Work Experience'},
    );
    expect(
      resumeTemplateAnalytics(ResumeTemplate.headerSidebar)['template_name'],
      'Header Sidebar',
    );
  });
}
