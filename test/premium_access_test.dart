import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/premium_access.dart';

void main() {
  group('PremiumAccess', () {
    test('every resume template is free', () {
      for (final template in ResumeTemplate.values) {
        expect(
          PremiumAccess.resumeTemplateRequiresPremium(template),
          isFalse,
          reason: '$template should be free',
        );
      }
      expect(PremiumAccess.templateTileRequiresPremium('dark-header'), isFalse);
      expect(PremiumAccess.templateTileRequiresPremium('classic-sidebar'), isFalse);
      expect(PremiumAccess.templateTileRequiresPremium('harbor'), isFalse);
      expect(PremiumAccess.templateTileRequiresPremium('typeplate'), isFalse);
      expect(PremiumAccess.templateTileRequiresPremium('ats-clean-sans'), isFalse);
      expect(PremiumAccess.templateTileRequiresPremium('creative-arc'), isFalse);
      expect(
        PremiumAccess.templateTileRequiresPremium('creative-chevron'),
        isFalse,
      );
      expect(PremiumAccess.templateTileRequiresPremium('creative-wave'), isFalse);
    });

    test('all cover letter layouts are free', () {
      for (final template in CoverLetterTemplate.values) {
        expect(
          PremiumAccess.coverLetterTemplateRequiresPremium(template),
          isFalse,
          reason: '$template should be free',
        );
      }
      expect(
        PremiumAccess.templateTileRequiresPremium('minimal-letter'),
        isFalse,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('sidebar-letter'),
        isFalse,
      );
    });

    test('AI ATS create stays free', () {
      expect(PremiumAccess.atsAiCreateRequiresPremium, isFalse);
    });

    test('cloud backup stays free', () {
      expect(PremiumAccess.iCloudBackupRequiresPremium, isFalse);
      expect(PremiumAccess.googleDriveBackupRequiresPremium, isFalse);
    });
  });
}
