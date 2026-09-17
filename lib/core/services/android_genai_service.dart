import 'dart:io';

import 'package:flutter/services.dart';

import '../models/resume_models.dart';

class AndroidGenAiException implements Exception {
  AndroidGenAiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Android Gemini Nano bridge via ML Kit GenAI Prompt API (AICore).
class AndroidGenAiService {
  AndroidGenAiService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('resume_app/android_genai');

  final MethodChannel _channel;

  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) {
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

  Future<String> generateProfessionalSummary({
    required ResumeData resume,
    int? yearsOfExperience,
  }) async {
    if (!Platform.isAndroid) {
      throw AndroidGenAiException(
        'Android on-device AI is only available on Android.',
      );
    }

    final prompt = buildProfessionalSummaryPrompt(
      resume: resume,
      yearsOfExperience: yearsOfExperience,
    );

    try {
      final raw = await _channel.invokeMethod<String>(
        'generateText',
        <String, dynamic>{'prompt': prompt},
      );
      final cleaned = _cleanSummary(raw);
      if (cleaned.isEmpty) {
        throw AndroidGenAiException(
          'Android on-device AI returned an empty response.',
        );
      }
      return cleaned;
    } on MissingPluginException {
      throw AndroidGenAiException(
        'Android on-device AI is not available in this build.',
      );
    } on PlatformException catch (error) {
      throw AndroidGenAiException(_messageForPlatformError(error));
    }
  }

  static String buildProfessionalSummaryPrompt({
    required ResumeData resume,
    int? yearsOfExperience,
  }) {
    final name = resume.fullName.trim();
    final title = resume.jobTitle.trim();
    final years = yearsOfExperience;
    final skills = resume.skills
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(8)
        .join(', ');
    final experience = resume.visibleWorkExperiences
        .where((item) => !item.isBlank)
        .take(3)
        .map((item) {
          final role = item.role.trim().isEmpty ? title : item.role.trim();
          final company = item.company.trim();
          final header = [
            role,
            if (company.isNotEmpty) 'at $company',
          ].join(' ');
          return header.trim();
        })
        .where((line) => line.isNotEmpty)
        .join('; ');

    final facts = <String>[
      if (name.isNotEmpty) 'Name: $name',
      if (title.isNotEmpty) 'Target job title: $title',
      if (years != null && years >= 0) 'Years of experience: $years',
      if (skills.isNotEmpty) 'Skills: $skills',
      if (experience.isNotEmpty) 'Recent roles: $experience',
    ];

    return '''
Write a professional resume summary of 3 to 5 short sentences in first person.
Use only these facts. Do not invent employers, degrees, tools, or dates.
Return plain text only, with no title, markdown, or bullet points.

${facts.join('\n')}
''';
  }

  String _cleanSummary(String? raw) {
    var text = (raw ?? '').trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:\w+)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return text.trim();
  }

  String _messageForPlatformError(PlatformException error) {
    switch (error.code) {
      case 'android_ai_unavailable':
      case 'android_ai_unsupported':
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Gemini Nano is not available on this device.';
      case 'android_ai_assets':
        return 'Android on-device AI is still downloading.';
      case 'android_ai_busy':
        return 'Android on-device AI is busy right now.';
      case 'android_ai_background':
        return 'Android on-device AI can only run while the app is open.';
      default:
        final message = error.message?.trim() ?? '';
        if (message.isNotEmpty) {
          return message;
        }
        return 'Android on-device AI could not finish.';
    }
  }
}
