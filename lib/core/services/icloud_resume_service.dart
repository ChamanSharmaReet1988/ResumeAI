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
  });

  factory ICloudResumeSummary.fromMap(Map<Object?, Object?> map) {
    final updatedAt =
        DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now();
    return ICloudResumeSummary(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? ResumeData.defaultTitle,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? updatedAt,
      updatedAt: updatedAt,
      isDownloaded: map['isDownloaded'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDownloaded;
}

abstract class ICloudResumeService {
  const ICloudResumeService();

  Future<bool> isAvailable();

  Future<List<ICloudResumeSummary>> listResumes();

  Future<List<String>> uploadResumes(List<ResumeData> resumes);

  Future<ResumeData> downloadResume(String id);
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
  Future<ResumeData> downloadResume(String id) async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'downloadResume',
      <String, Object?>{'id': id},
    );
    if (raw == null) {
      throw const FormatException('No resume payload returned from iCloud.');
    }

    return ResumeData.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
