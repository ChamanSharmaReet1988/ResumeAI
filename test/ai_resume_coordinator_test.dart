import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/ai_api_key_store.dart';
import 'package:resume_app/core/services/ai_resume_coordinator.dart';
import 'package:resume_app/core/services/apple_foundation_ai_service.dart';
import 'package:resume_app/core/services/cloud_ai_resume_service.dart';
import 'package:resume_app/core/services/resume_services.dart';

ResumeData _sampleResume() {
  return ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
    id: 'r1',
    title: 'Mobile Resume',
    jobTitle: 'Flutter Developer',
    summary: 'Builds Flutter apps.',
    skills: const ['Flutter', 'Dart'],
    workExperiences: const [
      WorkExperience(
        role: 'Flutter Developer',
        company: 'Acme',
        startDate: 'Jan 2024',
        endDate: 'Present',
        description: 'Builds mobile features.',
        bullets: ['Maintained Flutter modules.'],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses local AI when no API key is saved', () async {
    final keyStore = AiApiKeyStore.inMemory();
    final coordinator = AiResumeCoordinator(
      apiKeyStore: keyStore,
      localAi: LocalAiResumeService(),
      appleAi: AppleFoundationAiService(),
    );

    final outcome = await coordinator.createAtsResumeWithAi(
      sourceResume: _sampleResume(),
    );

    expect(outcome.engine, AiEngineKind.local);
    expect(outcome.result.resume.template, ResumeTemplate.atsLatexClassic);
    expect(outcome.result.appliedChanges, isNotEmpty);
  });

  test('prefers cloud API when a key is saved', () async {
    final keyStore = AiApiKeyStore.inMemory();
    await keyStore.save(
      provider: AiCloudProvider.openai,
      apiKey: 'sk-test-key-123456',
      model: 'gpt-4o-mini',
    );

    final mockClient = MockClient((request) async {
      expect(request.url.host, 'api.openai.com');
      return http.Response(
        '''
{
  "choices": [
    {
      "message": {
        "content": "{\\"jobTitle\\":\\"Flutter Developer\\",\\"summary\\":\\"Cloud rewritten summary.\\",\\"skills\\":[\\"Flutter\\",\\"Dart\\",\\"Firebase\\"],\\"workExperiences\\":[{\\"role\\":\\"Flutter Developer\\",\\"company\\":\\"Acme\\",\\"bullets\\":[\\"Shipped Flutter features with Firebase.\\"]}],\\"appliedChanges\\":[\\"Rewrote summary via OpenAI.\\"]}"
      }
    }
  ]
}
''',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final coordinator = AiResumeCoordinator(
      apiKeyStore: keyStore,
      localAi: LocalAiResumeService(),
      cloudAi: CloudAiResumeService(httpClient: mockClient),
      appleAi: AppleFoundationAiService(),
    );

    final outcome = await coordinator.createAtsResumeWithAi(
      sourceResume: _sampleResume(),
    );

    expect(outcome.engine, AiEngineKind.cloudApi);
    expect(outcome.result.resume.summary, 'Cloud rewritten summary.');
    expect(outcome.result.resume.skills, contains('Firebase'));
    expect(outcome.fallbackNotice, isNull);
  });

  test('falls back to local when cloud API fails', () async {
    final keyStore = AiApiKeyStore.inMemory();
    await keyStore.save(
      provider: AiCloudProvider.openai,
      apiKey: 'sk-bad-key',
    );

    final mockClient = MockClient((request) async {
      return http.Response(
        '{"error":{"message":"Incorrect API key"}}',
        401,
        headers: {'content-type': 'application/json'},
      );
    });

    final coordinator = AiResumeCoordinator(
      apiKeyStore: keyStore,
      localAi: LocalAiResumeService(),
      cloudAi: CloudAiResumeService(httpClient: mockClient),
      appleAi: AppleFoundationAiService(),
    );

    final outcome = await coordinator.createAtsResumeWithAi(
      sourceResume: _sampleResume(),
    );

    expect(outcome.engine, AiEngineKind.local);
    expect(outcome.fallbackNotice, isNotNull);
    expect(outcome.result.resume.template, ResumeTemplate.atsLatexClassic);
  });
}
