import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/premium_access.dart';

void main() {
  group('PremiumAccess resume templates', () {
    test('all professional layouts are free', () {
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.corporate),
        isFalse,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.creative),
        isFalse,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.classicSidebar,
        ),
        isFalse,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(ResumeTemplate.accentStrip),
        isFalse,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.detailsSidebar,
        ),
        isFalse,
      );
    });

    test('all ATS layouts require Pro', () {
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.atsStructured,
        ),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.atsLatexClassic,
        ),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.atsModernFlow,
        ),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.atsExecutive,
        ),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.atsCenterClassic,
        ),
        isTrue,
      );
      expect(
        PremiumAccess.resumeTemplateRequiresPremium(
          ResumeTemplate.atsProfessionalBlue,
        ),
        isTrue,
      );
    });

    test('professional tiles are free and ATS tiles require Pro', () {
      expect(
        PremiumAccess.templateTileRequiresPremium('profile-sidebar'),
        isFalse,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('accent-strip'),
        isFalse,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('ats-structured'),
        isTrue,
      );
      expect(
        PremiumAccess.templateTileRequiresPremium('ats-latex-classic'),
        isTrue,
      );
    });

    test('AI ATS create requires Pro', () {
      expect(PremiumAccess.atsAiCreateRequiresPremium, isTrue);
    });
  });
}
