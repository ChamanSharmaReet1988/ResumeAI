import 'dart:io';

import '../models/resume_models.dart';
import 'ai_api_key_store.dart';
import 'apple_foundation_ai_service.dart';
import 'cloud_ai_resume_service.dart';
import 'resume_services.dart';

enum AiEngineKind {
  cloudApi,
  appleOnDevice,
  local,
}

class AiAtsCreateOutcome {
  const AiAtsCreateOutcome({
    required this.result,
    required this.engine,
    this.fallbackNotice,
  });

  final ResumeImprovementResult result;
  final AiEngineKind engine;
  final String? fallbackNotice;
}

/// Routes ATS creation: API key → Apple on-device (iOS) → local.
class AiResumeCoordinator {
  AiResumeCoordinator({
    required AiApiKeyStore apiKeyStore,
    required LocalAiResumeService localAi,
    CloudAiResumeService? cloudAi,
    AppleFoundationAiService? appleAi,
  }) : _apiKeyStore = apiKeyStore,
       _localAi = localAi,
       _cloudAi = cloudAi ?? CloudAiResumeService(),
       _appleAi = appleAi ?? AppleFoundationAiService();

  final AiApiKeyStore _apiKeyStore;
  final LocalAiResumeService _localAi;
  final CloudAiResumeService _cloudAi;
  final AppleFoundationAiService _appleAi;

  Future<AiEngineKind> resolvePreferredEngine() async {
    if (!_apiKeyStore.isLoaded) {
      await _apiKeyStore.load();
    }
    if (_apiKeyStore.hasKey) {
      return AiEngineKind.cloudApi;
    }
    if (Platform.isIOS && await _appleAi.isAvailable()) {
      return AiEngineKind.appleOnDevice;
    }
    return AiEngineKind.local;
  }

  Future<AiAtsCreateOutcome> createAtsResumeWithAi({
    required ResumeData sourceResume,
    String jobDescription = '',
    int attemptIndex = 0,
  }) async {
    if (!_apiKeyStore.isLoaded) {
      await _apiKeyStore.load();
    }

    final config = _apiKeyStore.config;
    if (config.hasKey) {
      try {
        final result = await _cloudAi.createAtsResumeWithAi(
          config: config,
          sourceResume: sourceResume,
          jobDescription: jobDescription,
          attemptIndex: attemptIndex,
        );
        return AiAtsCreateOutcome(
          result: result,
          engine: AiEngineKind.cloudApi,
        );
      } catch (error) {
        final notice =
            'Cloud AI failed (${_shortError(error)}). Trying next option…';
        final fallback = await _createWithoutCloud(
          sourceResume: sourceResume,
          jobDescription: jobDescription,
          attemptIndex: attemptIndex,
        );
        return AiAtsCreateOutcome(
          result: fallback.result,
          engine: fallback.engine,
          fallbackNotice: notice,
        );
      }
    }

    return _createWithoutCloud(
      sourceResume: sourceResume,
      jobDescription: jobDescription,
      attemptIndex: attemptIndex,
    );
  }

  Future<AiAtsCreateOutcome> _createWithoutCloud({
    required ResumeData sourceResume,
    required String jobDescription,
    required int attemptIndex,
  }) async {
    if (Platform.isIOS) {
      try {
        if (await _appleAi.isAvailable()) {
          final result = await _appleAi.createAtsResumeWithAi(
            sourceResume: sourceResume,
            jobDescription: jobDescription,
            attemptIndex: attemptIndex,
          );
          return AiAtsCreateOutcome(
            result: result,
            engine: AiEngineKind.appleOnDevice,
          );
        }
      } catch (error) {
        final local = await _localAi.createAtsResumeWithAi(
          sourceResume: sourceResume,
          jobDescription: jobDescription,
          attemptIndex: attemptIndex,
        );
        return AiAtsCreateOutcome(
          result: local,
          engine: AiEngineKind.local,
          fallbackNotice: '${_friendlyError(error)} Used built-in AI.',
        );
      }
    }

    final local = await _localAi.createAtsResumeWithAi(
      sourceResume: sourceResume,
      jobDescription: jobDescription,
      attemptIndex: attemptIndex,
    );
    return AiAtsCreateOutcome(result: local, engine: AiEngineKind.local);
  }

  String _shortError(Object error) {
    final text = error.toString().trim();
    if (text.length <= 80) {
      return text;
    }
    return '${text.substring(0, 77)}...';
  }

  String _friendlyError(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) {
      return 'Apple on-device AI could not finish.';
    }
    // Avoid dumping opaque FoundationModels enum names into the snackbar.
    if (text.contains('FoundationModels.') ||
        text.contains("couldn't be completed") ||
        text.contains('couldn’t be completed')) {
      return 'Apple on-device AI could not finish.';
    }
    if (text.length <= 120) {
      return text.endsWith('.') ? text : '$text.';
    }
    return '${text.substring(0, 117)}...';
  }
}
