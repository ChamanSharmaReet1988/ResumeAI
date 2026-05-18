import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/resume_models.dart';
import 'firebase_app_services.dart';
import 'premium_products.dart';

abstract final class AnalyticsEvents {
  static const String resumeCreated = 'resume_created';
  static const String resumeExportedPdf = 'resume_exported_pdf';
  static const String resumeSharedPdf = 'resume_shared_pdf';
  static const String resumeTemplateSelected = 'resume_template_selected';
  static const String coverLetterCreated = 'cover_letter_created';
  static const String coverLetterSharedPdf = 'cover_letter_shared_pdf';
  static const String coverLetterTemplateSelected =
      'cover_letter_template_selected';
  static const String premiumPurchaseStarted = 'premium_purchase_started';
  static const String premiumPurchaseSuccess = 'premium_purchase_success';
  static const String premiumRestoreSuccess = 'premium_restore_success';
  static const String iCloudBackupSync = 'icloud_backup_sync';
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
