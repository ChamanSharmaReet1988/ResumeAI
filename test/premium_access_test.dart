import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/premium_access.dart';

void main() {
  group('PremiumAccess', () {
    test('all resume layouts are free', () {
      for (final template in ResumeTemplate.values) {
        expect(
          PremiumAccess.resumeTemplateRequiresPremium(template),
          isFalse,
          reason: '$template should be free',
        );
      }
    });

    test('all cover letter layouts are free', () {
      for (final template in CoverLetterTemplate.values) {
        expect(
          PremiumAccess.coverLetterTemplateRequiresPremium(template),
          isFalse,
          reason: '$template should be free',
        );
      }
    });

    test('all template tiles are free', () {
      expect(
        PremiumAccess.templateTileRequiresPremium('ats-structured'),
        isFalse,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('ats-latex-classic'),
        isFalse,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('profile-sidebar'),
        isFalse,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('minimal-letter'),
        isFalse,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('sidebar-letter'),
        isFalse,
      );
    });

    test('AI ATS create requires Pro', () {
      expect(PremiumAccess.atsAiCreateRequiresPremium, isTrue);
    });

    test('cloud backup still requires Pro', () {
      expect(PremiumAccess.iCloudBackupRequiresPremium, isTrue);
      expect(PremiumAccess.googleDriveBackupRequiresPremium, isTrue);
    });
  });
}
