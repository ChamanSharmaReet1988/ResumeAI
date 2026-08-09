import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/resume_models.dart';
import 'ai_api_key_store.dart';
import 'ai_ats_json_mapper.dart';
import 'resume_services.dart';

class CloudAiException implements Exception {
  CloudAiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Calls OpenAI or Gemini with the user's own API key.
class CloudAiResumeService {
  CloudAiResumeService({
    http.Client? httpClient,
    AiAtsJsonMapper mapper = const AiAtsJsonMapper(),
  }) : _httpClient = httpClient ?? http.Client(),
       _mapper = mapper;

  final http.Client _httpClient;
  final AiAtsJsonMapper _mapper;

  Future<ResumeImprovementResult> createAtsResumeWithAi({
    required AiApiKeyConfig config,
    required ResumeData sourceResume,
    String jobDescription = '',
    int attemptIndex = 0,
  }) async {
    if (!config.hasKey || config.provider == null) {
      throw CloudAiException('No API key configured.');
    }
    if (!sourceResume.hasMeaningfulContent) {
      throw ArgumentError('Select a saved resume with content first.');
    }

    final prompt = _mapper.buildPrompt(
      sourceResume: sourceResume,
      jobDescription: jobDescription,
      attemptIndex: attemptIndex,
    );

    final raw = switch (config.provider!) {
      AiCloudProvider.openai => await _callOpenAi(
        apiKey: config.apiKey.trim(),
        model: config.effectiveModel,
        prompt: prompt,
      ),
      AiCloudProvider.gemini => await _callGemini(
        apiKey: config.apiKey.trim(),
        model: config.effectiveModel,
        prompt: prompt,
      ),
    };

    return _mapper.mapResponse(
      sourceResume: sourceResume,
      rawResponse: raw,
      engineLabel: config.provider!.label,
    );
  }

  Future<void> testConnection(AiApiKeyConfig config) async {
    if (!config.hasKey || config.provider == null) {
      throw CloudAiException('Enter a provider and API key first.');
    }
    final probe = switch (config.provider!) {
      AiCloudProvider.openai => await _callOpenAi(
        apiKey: config.apiKey.trim(),
        model: config.effectiveModel,
        prompt:
            'Reply with exactly this JSON: {"ok":true}. No other text.',
        maxTokens: 32,
      ),
      AiCloudProvider.gemini => await _callGemini(
        apiKey: config.apiKey.trim(),
        model: config.effectiveModel,
        prompt:
            'Reply with exactly this JSON: {"ok":true}. No other text.',
        maxTokens: 32,
      ),
    };
    if (probe.trim().isEmpty) {
      throw CloudAiException('The API returned an empty response.');
    }
  }

  Future<String> _callOpenAi({
    required String apiKey,
    required String model,
    required String prompt,
    int maxTokens = 2500,
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'temperature': 0.4,
        'max_tokens': maxTokens,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content':
                'You rewrite resumes for ATS. Always respond with valid JSON only.',
          },
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudAiException(_errorMessage('OpenAI', response));
    }

    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw CloudAiException('Unexpected OpenAI response.');
    }
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      throw CloudAiException('OpenAI returned no choices.');
    }
    final message = choices.first is Map
        ? (choices.first as Map)['message']
        : null;
    final content = message is Map ? message['content']?.toString() : null;
    if (content == null || content.trim().isEmpty) {
      throw CloudAiException('OpenAI returned empty content.');
    }
    return content;
  }

  Future<String> _callGemini({
    required String apiKey,
    required String model,
    required String prompt,
    int maxTokens = 2500,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$apiKey',
    );
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': maxTokens,
          'responseMimeType': 'application/json',
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudAiException(_errorMessage('Gemini', response));
    }

    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw CloudAiException('Unexpected Gemini response.');
    }
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw CloudAiException('Gemini returned no candidates.');
    }
    final content = candidates.first is Map
        ? (candidates.first as Map)['content']
        : null;
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw CloudAiException('Gemini returned empty content.');
    }
    final text = parts.first is Map
        ? (parts.first as Map)['text']?.toString()
        : null;
    if (text == null || text.trim().isEmpty) {
      throw CloudAiException('Gemini returned empty content.');
    }
    return text;
  }

  String _errorMessage(String provider, http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final error = body['error'];
        if (error is Map && error['message'] != null) {
          return '$provider error: ${error['message']}';
        }
        if (body['message'] != null) {
          return '$provider error: ${body['message']}';
        }
      }
    } catch (_) {
      // Ignore parse failures and use status code.
    }
    return '$provider request failed (${response.statusCode}).';
  }
}
