import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/resume_builder_section_order.dart';
import '../models/resume_models.dart';
import 'firebase_app_services.dart';
import 'premium_products.dart';

abstract final class AnalyticsEvents {
  static const String resumeCreated = 'resume_created';
  static const String resumeExportedPdf = 'resume_exported_pdf';
  static const String resumeSharedPdf = 'resume_shared_pdf';
  static const String resumeSharedDocx = 'resume_shared_docx';
  // Kept ≤22 chars so `resumeapp_android_` + name stays within Firebase's 40-char limit.
  static const String resumeTemplateSelected = 'resume_tpl_selected';
  static const String resumeSectionViewed = 'resume_section_view';
  static const String coverLetterCreated = 'cover_letter_created';
  static const String coverLetterSharedPdf = 'cover_letter_shared_pdf';
  static const String coverLetterTemplateSelected = 'cover_tpl_selected';
  static const String premiumPurchaseStarted = 'premium_buy_start';
  static const String premiumPurchaseSuccess = 'premium_buy_success';
  static const String premiumRestoreSuccess = 'premium_restore_ok';
  static const String iCloudBackupSync = 'icloud_backup_sync';
  static const String deepLinkOpen = 'deep_link_open';
}

/// Prefixes event names for Analytics: `resumeapp_ios_*` / `resumeapp_android_*`.
String platformAnalyticsEventName(String baseName) {
  final trimmed = baseName.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  if (trimmed.startsWith('resumeapp_ios_') ||
      trimmed.startsWith('resumeapp_android_')) {
    return trimmed;
  }
  final prefix = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? 'resumeapp_ios_'
      : 'resumeapp_android_';
  final full = '$prefix$trimmed';
  // Firebase Analytics event names are limited to 40 characters.
  if (full.length <= 40) {
    return full;
  }
  return full.substring(0, 40);
}

Future<void> logAnalyticsEvent(
  BuildContext context,
  String name, {
  Map<String, Object?> parameters = const {},
}) async {
  try {
    await context.read<FirebaseAppServices>().logEvent(
          name,
          parameters: _normalizedAnalyticsParameters(parameters),
        );
  } catch (_) {
    // Analytics must never block user flows.
  }
}

Map<String, Object> resumeTemplateAnalytics(ResumeTemplate template) => {
      'template_id': template.name,
      'template_name': template.label,
    };

Map<String, Object> resumeBuilderSectionAnalytics({
  required int step,
  required String? sectionId,
  required List<CustomSectionItem> customSections,
}) {
  final id = step <= 0 || sectionId == null ? 'personal' : sectionId;
  return {
    'section_id': id,
    'section_name': resumeBuilderSectionAnalyticsName(
      step: step,
      sectionId: sectionId,
      customSections: customSections,
    ),
  };
}

/// Stable English names for Analytics (not localized).
String resumeBuilderSectionAnalyticsName({
  required int step,
  required String? sectionId,
  required List<CustomSectionItem> customSections,
}) {
  if (step <= 0 || sectionId == null) {
    return 'Personal Information';
  }
  switch (sectionId) {
    case ResumeBuilderSectionIds.work:
      return 'Work Experience';
    case ResumeBuilderSectionIds.education:
      return 'Education';
    case ResumeBuilderSectionIds.skills:
      return 'Skills';
    case ResumeBuilderSectionIds.projects:
      return 'Projects';
    default:
      final index = ResumeBuilderSectionIds.customIndex(sectionId);
      if (index != null &&
          index >= 0 &&
          index < customSections.length) {
        final title = customSections[index].title.trim();
        if (title.isNotEmpty) {
          return title.length > 80 ? title.substring(0, 80) : title;
        }
      }
      return 'Custom Section';
  }
}

Map<String, Object> coverLetterTemplateAnalytics(
  CoverLetterTemplate template,
) => {
      'template_id': template.name,
      'template_name': template.label,
    };

Map<String, Object> premiumPlanAnalytics(String? productId) => {
      'plan_id': productId ?? 'unknown',
      'plan_name': PremiumProducts.planTitleFor(productId),
    };

Map<String, Object> _normalizedAnalyticsParameters(
  Map<String, Object?> raw,
) {
  final normalized = <String, Object>{};
  raw.forEach((key, value) {
    if (value == null) {
      return;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      normalized[key] = trimmed;
      return;
    }
    if (value is bool) {
      normalized[key] = value ? 1 : 0;
      return;
    }
    if (value is int || value is double) {
      normalized[key] = value;
    }
  });
  return normalized;
}
