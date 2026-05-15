import 'dart:io';

import 'package:flutter/services.dart';

import '../models/resume_models.dart';

class ICloudResumeSummary {
  const ICloudResumeSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.isDownloaded,
    required this.isCoverLetter,
  });

  factory ICloudResumeSummary.fromMap(Map<Object?, Object?> map) {
    final updatedAt =
        DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now();
    final isCoverLetter = map['isCoverLetter'] as bool? ?? false;
    final rawTitle = map['title'] as String? ?? '';
    final title = rawTitle.trim().isNotEmpty
        ? rawTitle.trim()
        : (isCoverLetter ? 'Untitled Cover Letter' : ResumeData.defaultTitle);
    return ICloudResumeSummary(
      id: map['id'] as String? ?? '',
      title: title,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? updatedAt,
      updatedAt: updatedAt,
      isDownloaded: map['isDownloaded'] as bool? ?? false,
      isCoverLetter: isCoverLetter,
    );
  }

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDownloaded;

  /// When true, this row refers to a cover letter JSON in iCloud `CoverLetters/`.
  final bool isCoverLetter;
}

abstract class ICloudResumeService {
  const ICloudResumeService();

  Future<bool> isAvailable();

  /// Resumes and cover letters stored under iCloud (native merges both folders).
  Future<List<ICloudResumeSummary>> listResumes();

  Future<List<String>> uploadResumes(List<ResumeData> resumes);

  Future<List<String>> uploadCoverLetters(List<CoverLetterData> coverLetters);

  Future<ResumeData> downloadResume(String id);

  Future<CoverLetterData> downloadCoverLetter(String id);

  Future<void> deleteFromICloud({
    required String id,
    required bool isCoverLetter,
  });
}

class MethodChannelICloudResumeService implements ICloudResumeService {
  const MethodChannelICloudResumeService();

  static const MethodChannel _channel = MethodChannel(
    'resume_app/icloud_resumes',
  );

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) {
      return false;
    }
    try {
      final isAvailable =
          await _channel.invokeMethod<bool>('isAvailable') ?? false;
      return isAvailable;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<ICloudResumeSummary>> listResumes() async {
    if (!Platform.isIOS) {
      return const [];
    }
    try {
      final raw =
          await _channel.invokeListMethod<Map<Object?, Object?>>(
            'listResumes',
          ) ??
          const <Map<Object?, Object?>>[];
      final items = raw.map(ICloudResumeSummary.fromMap).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  @override
  Future<List<String>> uploadResumes(List<ResumeData> resumes) async {
    if (!Platform.isIOS || resumes.isEmpty) {
      return const [];
    }

    final raw =
        await _channel.invokeListMethod<dynamic>(
          'uploadResumes',
          <String, Object?>{
            'resumes': resumes.map((resume) => resume.toJson()).toList(),
          },
        ) ??
        const <dynamic>[];

    return raw.map((item) => item.toString()).toList();
  }

  @override
  Future<List<String>> uploadCoverLetters(List<CoverLetterData> coverLetters) async {
    if (!Platform.isIOS || coverLetters.isEmpty) {
      return const [];
    }

    final raw =
        await _channel.invokeListMethod<dynamic>(
          'uploadCoverLetters',
          <String, Object?>{
            'coverLetters': coverLetters.map((c) => c.toJson()).toList(),
          },
        ) ??
        const <dynamic>[];

    return raw.map((item) => item.toString()).toList();
  }

  @override
  Future<ResumeData> downloadResume(String id) async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'downloadResume',
      <String, Object?>{'id': id, 'isCoverLetter': false},
    );
    if (raw == null) {
      throw const FormatException('No resume payload returned from iCloud.');
    }

    return ResumeData.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<CoverLetterData> downloadCoverLetter(String id) async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'downloadResume',
      <String, Object?>{'id': id, 'isCoverLetter': true},
    );
    if (raw == null) {
      throw const FormatException('No cover letter payload returned from iCloud.');
    }

    return CoverLetterData.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<void> deleteFromICloud({
    required String id,
    required bool isCoverLetter,
  }) async {
    if (!Platform.isIOS || id.isEmpty) {
      return;
    }
    await _channel.invokeMethod<void>(
      'deleteFromICloud',
      <String, Object?>{'id': id, 'isCoverLetter': isCoverLetter},
    );
  }
}
