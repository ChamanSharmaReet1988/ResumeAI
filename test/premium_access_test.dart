import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/premium_access.dart';

void main() {
  group('PremiumAccess', () {
    test('first two templates in each resume section stay free', () {
      for (final template in PremiumAccess.freeResumeTemplates) {
        expect(
          PremiumAccess.resumeTemplateRequiresPremium(template),
          isFalse,
          reason: '$template should be free',
        );
      }
      expect(PremiumAccess.templateTileRequiresPremium('dark-header'), isFalse);
      expect(PremiumAccess.templateTileRequiresPremium('accent-strip'), isFalse);
      expect(
        PremiumAccess.templateTileRequiresPremium('ats-structured'),
        isFalse,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('ats-latex-classic'),
        isFalse,
      );
      expect(PremiumAccess.templateTileRequiresPremium('modern-line'), isFalse);
      expect(
        PremiumAccess.templateTileRequiresPremium('split-contact'),
        isFalse,
      );
    });

    test('later templates in each resume section require Pro', () {
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.classicSidebar),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.creative),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.atsModernFlow),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.harbor),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.typeplate),
        isTrue,
      );
      expect(PremiumAccess.templateTileRequiresPremium('classic-sidebar'), isTrue);
      expect(PremiumAccess.templateTileRequiresPremium('harbor'), isTrue);
      expect(PremiumAccess.templateTileRequiresPremium('typeplate'), isTrue);
      expect(PremiumAccess.templateTileRequiresPremium('ats-clean-sans'), isTrue);
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

    test('AI ATS create stays free on Android test host', () {
      expect(PremiumAccess.atsAiCreateRequiresPremium, isFalse);
    });

    test('cloud backup requires Pro when IAP is enabled', () {
      expect(PremiumAccess.iCloudBackupRequiresPremium, isTrue);
      expect(PremiumAccess.googleDriveBackupRequiresPremium, isTrue);
    });
  });
}
