import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Persists profile photos under Application Support so they survive app restarts.
class ProfileImageStorage {
  ProfileImageStorage._();

  static const String subdirectory = 'profile_images';
  static const List<String> _extensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
  ];

  static Future<Directory> profileDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}/$subdirectory');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static bool isManagedPath(String path) => path.contains('/$subdirectory/');

  static String extensionFromPath(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return '.jpg';
    }
    final ext = path.substring(dotIndex).toLowerCase();
    if (_extensions.contains(ext)) {
      return ext;
    }
    return '.jpg';
  }

  static Future<String> saveFromXFile(
    XFile picked, {
    required String resumeId,
  }) async {
    final bytes = await picked.readAsBytes();
    return saveBytes(
      bytes,
      resumeId: resumeId,
      extension: extensionFromPath(picked.path),
    );
  }

  static Future<String> saveBytes(
    List<int> bytes, {
    required String resumeId,
    required String extension,
  }) async {
    final dir = await profileDirectory();
    final normalizedExt = extension.startsWith('.')
        ? extension.toLowerCase()
        : '.${extension.toLowerCase()}';

    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      final matchesResume =
          name.startsWith('$resumeId.') || name.startsWith('${resumeId}_');
      if (!matchesResume) {
        continue;
      }
      final ext = extensionFromPath(name);
      if (_extensions.contains(ext)) {
        await entity.delete();
      }
    }

    final version = DateTime.now().microsecondsSinceEpoch;
    final target = File('${dir.path}/${resumeId}_$version$normalizedExt');
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  /// Returns an on-disk path for [resumeId], repairing stale absolute paths.
  static Future<String> resolvePath(String storedPath, String resumeId) async {
    final trimmed = storedPath.trim();
    if (trimmed.isNotEmpty) {
      final file = File(trimmed);
      if (await file.exists()) {
        return trimmed;
      }
    }

    try {
      final dir = await profileDirectory();
      for (final ext in _extensions) {
        final candidate = File('${dir.path}/$resumeId$ext');
        if (await candidate.exists()) {
          return candidate.path;
        }
      }

      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('$resumeId.') || name.startsWith('${resumeId}_')) {
          return entity.path;
        }
      }
    } catch (_) {
      // path_provider unavailable (e.g. widget tests) — keep stored path.
    }

    return trimmed;
  }

  static Future<void> deleteForResume(
    String resumeId, {
    String? knownPath,
  }) async {
    final trimmed = knownPath?.trim() ?? '';
    if (trimmed.isNotEmpty && isManagedPath(trimmed)) {
      final file = File(trimmed);
      if (file.existsSync()) {
        await file.delete();
      }
    }

    final dir = await profileDirectory();
    for (final ext in _extensions) {
      final file = File('${dir.path}/$resumeId$ext');
      if (file.existsSync()) {
        await file.delete();
      }
    }

    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('$resumeId.') || name.startsWith('${resumeId}_')) {
        await entity.delete();
      }
    }
  }

  static Future<String> copyForResume({
    required String sourceResumeId,
    required String newResumeId,
    String sourceStoredPath = '',
  }) async {
    final sourcePath = await resolvePath(sourceStoredPath, sourceResumeId);
    if (sourcePath.isEmpty) {
      return '';
    }
    final file = File(sourcePath);
    if (!await file.exists()) {
      return '';
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return '';
    }
    return saveBytes(
      bytes,
      resumeId: newResumeId,
      extension: extensionFromPath(sourcePath),
    );
  }
}
