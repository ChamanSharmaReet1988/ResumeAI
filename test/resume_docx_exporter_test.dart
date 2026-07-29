import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_docx_exporter.dart';

void main() {
  test('ResumeDocxExporter builds a valid zip-based DOCX', () {
    final resume = ResumeData.empty(template: ResumeTemplate.atsLatexClassic)
        .copyWith(
          fullName: 'Alex Example',
          jobTitle: 'Flutter Developer',
          email: 'alex@example.com',
          phone: '1234567890',
          summary: 'Builds mobile apps with Flutter and Dart.',
          skills: const ['Flutter', 'Dart', 'Firebase'],
          workExperiences: const [
            WorkExperience(
              role: 'Flutter Developer',
              company: 'Acme',
              startDate: '2023',
              endDate: 'Present',
              description: 'Ships mobile features.',
              bullets: ['Built Flutter modules.', 'Improved release quality.'],
            ),
          ],
        );

    final bytes = const ResumeDocxExporter().buildBytes(resume);

    expect(bytes.length, greaterThan(100));
    // ZIP local file header signature: PK\x03\x04
    expect(bytes[0], 0x50);
    expect(bytes[1], 0x4b);
    expect(bytes[2], 0x03);
    expect(bytes[3], 0x04);
  });
}
