import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';

void main() {
  group('educationScoreDisplayLabel', () {
    test('appends % when toggle is on', () {
      const item = EducationItem(
        institution: 'School',
        degree: 'B.Tech',
        startDate: '2020',
        endDate: '2024',
        score: '92',
        showScoreAsPercent: true,
      );

      expect(educationScoreDisplayLabel(item), '92%');
    });

    test('omits % when toggle is off', () {
      const item = EducationItem(
        institution: 'School',
        degree: 'B.Tech',
        startDate: '2020',
        endDate: '2024',
        score: '92',
        showScoreAsPercent: false,
      );

      expect(educationScoreDisplayLabel(item), '92');
    });

    test('does not double % when score already ends with %', () {
      const item = EducationItem(
        institution: 'School',
        degree: 'B.Tech',
        startDate: '2020',
        endDate: '2024',
        score: '92%',
        showScoreAsPercent: true,
      );

      expect(educationScoreDisplayLabel(item), '92%');
    });

    test('returns empty for blank score', () {
      const item = EducationItem(
        institution: 'School',
        degree: 'B.Tech',
        startDate: '2020',
        endDate: '2024',
      );

      expect(educationScoreDisplayLabel(item), isEmpty);
    });
  });

  group('EducationItem JSON', () {
    test('persists showScoreAsPercent', () {
      const item = EducationItem(
        institution: 'School',
        degree: 'B.Tech',
        startDate: '2020',
        endDate: '2024',
        score: '88',
        showScoreAsPercent: true,
      );

      final restored = EducationItem.fromJson(item.toJson());

      expect(restored.showScoreAsPercent, isTrue);
      expect(restored.score, '88');
      expect(educationScoreDisplayLabel(restored), '88%');
    });

    test('migrates legacy scores ending with %', () {
      final restored = EducationItem.fromJson({
        'institution': 'School',
        'degree': 'B.Tech',
        'startDate': '2020',
        'endDate': '2024',
        'score': '91%',
      });

      expect(restored.score, '91');
      expect(restored.showScoreAsPercent, isTrue);
      expect(educationScoreDisplayLabel(restored), '91%');
    });
  });
}
