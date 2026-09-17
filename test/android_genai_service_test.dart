import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/android_genai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a compact on-device summary prompt from resume facts', () {
    final prompt = AndroidGenAiService.buildProfessionalSummaryPrompt(
      resume: ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
        fullName: 'Jane Doe',
        jobTitle: 'Flutter Developer',
        skills: const ['Flutter', 'Dart'],
        workExperiences: const [
          WorkExperience(
            role: 'Flutter Developer',
            company: 'Acme',
            startDate: '2023',
            endDate: 'Present',
            description: '',
            bullets: [],
          ),
        ],
      ),
      yearsOfExperience: 5,
    );

    expect(prompt, contains('Jane Doe'));
    expect(prompt, contains('Flutter Developer'));
    expect(prompt, contains('Years of experience: 5'));
    expect(prompt, contains('Acme'));
    expect(prompt, contains('plain text'));
  });

  test('reports Android on-device AI as unavailable in widget tests', () async {
    final service = AndroidGenAiService(
      channel: const MethodChannel('resume_app/android_genai'),
    );

    expect(await service.isAvailable(), isFalse);
  });
}
