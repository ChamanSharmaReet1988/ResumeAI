import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/premium_access.dart';

void main() {
  group('PremiumAccess', () {
    test('first half of each template section is free', () {
      for (final id in [
        'modern-line', 'split-contact', 'meridian', 'ledger', // top picks
        'creative-aurora', 'creative-ink-panel', 'creative-sunset',
        'creative-sage-frame', 'creative-terrazzo',
        'creative-dotfield', // creative
        'dark-header', 'accent-strip', 'profile-sidebar', 'classic-sidebar',
        'header-sidebar', 'slate-sidebar', 'timeline-profile', 'summit',
        'folio', // professional
        'ats-structured', 'ats-latex-classic', 'ats-modern-flow',
        'ats-executive', 'ats-bold-rule', 'ats-compact', // ATS
      ]) {
        expect(
          PremiumAccess.templateTileRequiresPremium(id),
          isFalse,
          reason: '$id should be free',
        );
      }
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.corporate),
        isFalse,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.atsStructured,
        ),
        isFalse,
      );
    });

    test('second half of each template section needs Pro', () {
      expect(PremiumAccess.premiumTemplateTileIds, hasLength(25));
      expect(PremiumAccess.premiumResumeTemplates, hasLength(25));
      for (final id in PremiumAccess.premiumTemplateTileIds) {
        expect(PremiumAccess.templateTileRequiresPremium(id), isTrue);
      }
      for (final template in PremiumAccess.premiumResumeTemplates) {
        expect(PremiumAccess.resumeTemplateRequiresPremium(template), isTrue);
      }
      expect(PremiumAccess.templateTileRequiresPremium('harbor'), isTrue);
      expect(
        PremiumAccess.templateTileRequiresPremium('creative-wave'),
        isTrue,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('ats-clean-sans'),
        isTrue,
      );
      for (final id in [
        'keystone', 'cadence', 'creative-orbit', 'creative-prism', 'beacon',
        'vertex', 'ats-focus', 'ats-double-rule',
      ]) {
        expect(PremiumAccess.templateTileRequiresPremium(id), isTrue);
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
