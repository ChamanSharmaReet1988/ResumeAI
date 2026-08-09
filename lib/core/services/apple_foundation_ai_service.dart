import 'dart:io';

import 'package:flutter/services.dart';

import '../models/resume_models.dart';
import 'ai_ats_json_mapper.dart';
import 'resume_services.dart';

class AppleFoundationAiException implements Exception {
  AppleFoundationAiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// iOS Apple Intelligence / Foundation Models bridge.
class AppleFoundationAiService {
  AppleFoundationAiService({
    MethodChannel? channel,
    AiAtsJsonMapper mapper = const AiAtsJsonMapper(),
  }) : _channel = channel ?? const MethodChannel('resume_app/apple_foundation_ai'),
       _mapper = mapper;

  final MethodChannel _channel;
  final AiAtsJsonMapper _mapper;

  Future<bool> isAvailable() async {
    if (!Platform.isIOS) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<ResumeImprovementResult> createAtsResumeWithAi({
    required ResumeData sourceResume,
    String jobDescription = '',
    int attemptIndex = 0,
  }) async {
    if (!Platform.isIOS) {
      throw AppleFoundationAiException(
        'Apple on-device AI is only available on iPhone/iPad.',
      );
    }
    if (!sourceResume.hasMeaningfulContent) {
      throw ArgumentError('Select a saved resume with content first.');
    }

    // On-device models have a small context window; keep the prompt compact.
    final prompt = _mapper.buildPrompt(
      sourceResume: sourceResume,
      jobDescription: jobDescription,
      attemptIndex: attemptIndex,
      compact: true,
    );

    try {
      final raw = await _channel.invokeMethod<String>(
        'generateText',
        <String, dynamic>{'prompt': prompt},
      );
      if (raw == null || raw.trim().isEmpty) {
        throw AppleFoundationAiException(
          'Apple on-device AI returned an empty response.',
        );
      }
      return _mapper.mapResponse(
        sourceResume: sourceResume,
        rawResponse: raw,
        engineLabel: 'Apple Intelligence',
      );
    } on MissingPluginException {
      throw AppleFoundationAiException(
        'Apple on-device AI is not available in this build.',
      );
    } on PlatformException catch (error) {
      throw AppleFoundationAiException(_messageForPlatformError(error));
    }
  }

  String _messageForPlatformError(PlatformException error) {
    switch (error.code) {
      case 'apple_ai_guardrail':
        return 'Apple Intelligence blocked this resume content.';
      case 'apple_ai_context':
        return 'This resume is too long for Apple on-device AI.';
      case 'apple_ai_rate_limited':
        return 'Apple on-device AI is busy right now.';
      case 'apple_ai_assets':
        return 'Apple Intelligence model assets are not ready.';
      case 'apple_ai_refusal':
        return 'Apple Intelligence declined this request.';
      case 'apple_ai_language':
        return 'Apple on-device AI does not support this language yet.';
      case 'apple_ai_unavailable':
      case 'apple_ai_unsupported':
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Apple Intelligence is not available on this device.';
      default:
        final message = error.message?.trim() ?? '';
        if (message.isNotEmpty && !message.contains('FoundationModels.')) {
          return message;
        }
        return 'Apple on-device AI could not finish.';
    }
  }
}
