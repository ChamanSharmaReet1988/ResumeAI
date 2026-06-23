import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;

import '../models/resume_models.dart';
import 'profile_image_storage.dart';

/// One row in the Google Drive backup list (same shape as iCloud summaries).
class GoogleDriveResumeSummary {
  const GoogleDriveResumeSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.driveFileId,
    this.isCoverLetter = false,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Drive file id (not the resume JSON `id`).
  final String driveFileId;

  /// When true, this row refers to a cover letter JSON in `CoverLetters/`.
  final bool isCoverLetter;
}

/// Builds JSON for Drive upload with an embedded profile photo (iCloud parity).
Future<Map<String, dynamic>> buildResumeUploadPayload(ResumeData resume) async {
  final json = Map<String, dynamic>.from(resume.toJson());
  final resolvedPath = await ProfileImageStorage.resolvePath(
    resume.profileImagePath,
    resume.id,
  );
  if (resolvedPath.isEmpty) {
    return json;
  }

  final file = File(resolvedPath);
  if (!await file.exists()) {
    return json;
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    return json;
  }

  json['profileImagePath'] = '';
  json['profileImageBase64'] = base64Encode(bytes);
  final ext = ProfileImageStorage.extensionFromPath(resolvedPath);
  json['profileImageExtension'] = ext.startsWith('.') ? ext.substring(1) : ext;
  return json;
}

/// Parses resume JSON from Drive and restores an embedded profile photo.
Future<ResumeData> resumeFromDrivePayload(Map<String, dynamic> json) async {
  var resume = ResumeData.fromJson(json);

  final imageBase64 = json['profileImageBase64'] as String?;
  if (imageBase64 == null || imageBase64.isEmpty) {
    return resume;
  }

  final extension = (json['profileImageExtension'] as String? ?? 'jpg')
      .trim()
      .toLowerCase();
  final path = await ProfileImageStorage.saveBytes(
    base64Decode(imageBase64),
    resumeId: resume.id,
    extension: extension.startsWith('.') ? extension : '.$extension',
  );
  return resume.copyWith(profileImagePath: path);
}

/// Display title for a cover letter summary (matches iCloud native logic).
String coverLetterDisplayTitleFromJson(Map<String, dynamic> json) {
  final rawTitle = (json['title'] as String? ?? '').trim();
  if (rawTitle.isNotEmpty) {
    return rawTitle;
  }
  final role = (json['role'] as String? ?? '').trim();
  final company = (json['company'] as String? ?? '').trim();
  final joined = [role, company].where((part) => part.isNotEmpty).join(' · ');
  return joined.isEmpty ? 'Untitled Cover Letter' : joined;
}

/// Resume backup to a **ResumeApp** folder on Google Drive using the
/// `drive.file` scope (files created by this app only).
class GoogleDriveResumeService {
  GoogleDriveResumeService();

  static const _folderName = 'ResumeApp';
  static const _coverLettersFolderName = 'CoverLetters';
  static const _scopes = <String>[gdrive.DriveApi.driveFileScope];

  GoogleSignInAccount? _account;

  /// Avoids a Drive folder lookup on every list/upload after the first.
  String? _cachedResumeAppFolderId;
  String? _cachedCoverLettersFolderId;

  /// Returns true if the user is already authenticated and Drive scope is
  /// granted without showing UI.
  Future<bool> hasAuthorizedSession() async {
    final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
    if (account == null) {
      return false;
    }
    final authz = await account.authorizationClient.authorizationForScopes(_scopes);
    if (authz == null) {
      return false;
    }
    _account = account;
    return true;
  }

  /// Interactive Google sign-in + Drive authorization.
  Future<void> signIn() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError('Google Sign-In is not available on this platform.');
    }
    _cachedResumeAppFolderId = null;
    _cachedCoverLettersFolderId = null;
    final account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    await account.authorizationClient.authorizeScopes(_scopes);
    _account = account;
  }

  Future<void> signOut() async {
    _account = null;
    _cachedResumeAppFolderId = null;
    _cachedCoverLettersFolderId = null;
    await GoogleSignIn.instance.signOut();
  }

  Future<gdrive.DriveApi> _api() async {
    final account = _account;
    if (account == null) {
      throw StateError('Not signed in to Google Drive.');
    }
    final authz = await account.authorizationClient.authorizationForScopes(_scopes) ??
        await account.authorizationClient.authorizeScopes(_scopes);
    final client = authz.authClient(scopes: _scopes);
    return gdrive.DriveApi(client);
  }

  Future<String> _folderId(gdrive.DriveApi api) async {
    final cached = _cachedResumeAppFolderId;
    if (cached != null) {
      return cached;
    }
    final escapedName = _folderName.replaceAll("'", r"\'");
    final list = await api.files.list(
      q: "name='$escapedName' and mimeType='application/vnd.google-apps.folder' "
          "and 'root' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    final existing = list.files;
    if (existing != null && existing.isNotEmpty) {
      final id = existing.first.id!;
      _cachedResumeAppFolderId = id;
      return id;
    }
    final created = await api.files.create(
      gdrive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = <String>['root'],
    );
    final id = created.id;
    if (id == null || id.isEmpty) {
      throw const FormatException('Could not create ResumeApp folder on Drive.');
    }
    _cachedResumeAppFolderId = id;
    return id;
  }

  Future<String> _coverLettersFolderId(
    gdrive.DriveApi api,
    String resumeAppFolderId,
  ) async {
    final cached = _cachedCoverLettersFolderId;
    if (cached != null) {
      return cached;
    }
    final escapedName = _coverLettersFolderName.replaceAll("'", r"\'");
    final list = await api.files.list(
      q: "name='$escapedName' and mimeType='application/vnd.google-apps.folder' "
          "and '$resumeAppFolderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    final existing = list.files;
    if (existing != null && existing.isNotEmpty) {
      final id = existing.first.id!;
      _cachedCoverLettersFolderId = id;
      return id;
    }
    final created = await api.files.create(
      gdrive.File()
        ..name = _coverLettersFolderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = <String>[resumeAppFolderId],
    );
    final id = created.id;
    if (id == null || id.isEmpty) {
      throw const FormatException(
        'Could not create CoverLetters folder on Drive.',
      );
    }
    _cachedCoverLettersFolderId = id;
    return id;
  }

  /// One `files.list` for all `.json` files in [folderId] (used to batch uploads).
  Future<Map<String, String>> _jsonFileIdsByName(
    gdrive.DriveApi api,
    String folderId,
  ) async {
    final list = await api.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name,mimeType)',
    );
    final map = <String, String>{};
    for (final f in list.files ?? const <gdrive.File>[]) {
      final name = f.name;
      final id = f.id;
      if (name != null &&
          name.endsWith('.json') &&
          id != null &&
          f.mimeType != 'application/vnd.google-apps.folder') {
        map[name] = id;
      }
    }
    return map;
  }

  GoogleDriveResumeSummary _summaryFromFile(
    gdrive.File f, {
    required bool isCoverLetter,
  }) {
    final name = f.name!;
    final itemId = name.replaceFirst(RegExp(r'\.json$'), '');
    final props = f.appProperties ?? const <String, String>{};
    final defaultTitle =
        isCoverLetter ? 'Untitled Cover Letter' : ResumeData.defaultTitle;
    final title = (props['title']?.trim().isNotEmpty ?? false)
        ? props['title']!.trim()
        : defaultTitle;
    final propUpdated = props['updatedAt'] != null
        ? DateTime.tryParse(props['updatedAt']!)
        : null;
    final updated = propUpdated ?? f.modifiedTime ?? DateTime.now();
    final created = f.createdTime ?? updated;
    return GoogleDriveResumeSummary(
      id: itemId,
      title: title,
      createdAt: created,
      updatedAt: updated,
      driveFileId: f.id!,
      isCoverLetter: isCoverLetter,
    );
  }

  Future<List<GoogleDriveResumeSummary>> listResumes() async {
    final api = await _api();
    final folderId = await _folderId(api);
    final resumeList = await api.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name,mimeType,modifiedTime,appProperties,createdTime)',
    );
    final out = <GoogleDriveResumeSummary>[];
    for (final f in resumeList.files ?? const <gdrive.File>[]) {
      final name = f.name;
      if (name == null ||
          !name.endsWith('.json') ||
          f.mimeType == 'application/vnd.google-apps.folder') {
        continue;
      }
      final resumeId = name.replaceFirst(RegExp(r'\.json$'), '');
      if (resumeId.isEmpty) {
        continue;
      }
      out.add(_summaryFromFile(f, isCoverLetter: false));
    }

    final coverFolderId = await _coverLettersFolderId(api, folderId);
    final coverList = await api.files.list(
      q: "'$coverFolderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name,mimeType,modifiedTime,appProperties,createdTime)',
    );
    for (final f in coverList.files ?? const <gdrive.File>[]) {
      final name = f.name;
      if (name == null ||
          !name.endsWith('.json') ||
          f.mimeType == 'application/vnd.google-apps.folder') {
        continue;
      }
      final letterId = name.replaceFirst(RegExp(r'\.json$'), '');
      if (letterId.isEmpty) {
        continue;
      }
      out.add(_summaryFromFile(f, isCoverLetter: true));
    }

    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  Future<List<String>> uploadResumes(List<ResumeData> resumes) async {
    if (resumes.isEmpty) {
      return const [];
    }
    final api = await _api();
    final folderId = await _folderId(api);
    final existingByName = await _jsonFileIdsByName(api, folderId);
    await Future.wait(
      resumes.map(
        (resume) => _upsertResume(
          api,
          folderId,
          resume,
          existingIdsByFilename: existingByName,
        ),
      ),
    );
    return resumes.map((r) => r.id).toList();
  }

  Future<List<String>> uploadCoverLetters(
    List<CoverLetterData> coverLetters,
  ) async {
    if (coverLetters.isEmpty) {
      return const [];
    }
    final api = await _api();
    final folderId = await _folderId(api);
    final coverFolderId = await _coverLettersFolderId(api, folderId);
    final existingByName = await _jsonFileIdsByName(api, coverFolderId);
    await Future.wait(
      coverLetters.map(
        (letter) => _upsertCoverLetter(
          api,
          coverFolderId,
          letter,
          existingIdsByFilename: existingByName,
        ),
      ),
    );
    return coverLetters.map((c) => c.id).toList();
  }

  Future<void> _upsertResume(
    gdrive.DriveApi api,
    String folderId,
    ResumeData resume, {
    Map<String, String>? existingIdsByFilename,
  }) async {
    final filename = '${resume.id}.json';
    String? fileId = existingIdsByFilename?[filename];
    if (fileId == null && existingIdsByFilename == null) {
      final escaped = filename.replaceAll("'", r"\'");
      final existing = await api.files.list(
        q: "name='$escaped' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id)',
      );
      fileId = existing.files?.firstOrNull?.id;
    }
    final payload = await buildResumeUploadPayload(resume);
    final bytes = utf8.encode(jsonEncode(payload));
    final media = gdrive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );
    final meta = gdrive.File()
      ..name = filename
      ..mimeType = 'application/json'
      ..appProperties = <String, String>{
        'title': resume.title,
        'updatedAt': resume.updatedAt.toIso8601String(),
      };

    if (fileId != null) {
      await api.files.update(
        meta,
        fileId,
        uploadMedia: media,
      );
    } else {
      meta.parents = <String>[folderId];
      await api.files.create(
        meta,
        uploadMedia: media,
      );
    }
  }

  Future<void> _upsertCoverLetter(
    gdrive.DriveApi api,
    String folderId,
    CoverLetterData letter, {
    Map<String, String>? existingIdsByFilename,
  }) async {
    final filename = '${letter.id}.json';
    String? fileId = existingIdsByFilename?[filename];
    if (fileId == null && existingIdsByFilename == null) {
      final escaped = filename.replaceAll("'", r"\'");
      final existing = await api.files.list(
        q: "name='$escaped' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id)',
      );
      fileId = existing.files?.firstOrNull?.id;
    }
    final title = coverLetterDisplayTitleFromJson(letter.toJson());
    final bytes = utf8.encode(jsonEncode(letter.toJson()));
    final media = gdrive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );
    final meta = gdrive.File()
      ..name = filename
      ..mimeType = 'application/json'
      ..appProperties = <String, String>{
        'title': title,
        'updatedAt': letter.updatedAt.toIso8601String(),
        'isCoverLetter': 'true',
      };

    if (fileId != null) {
      await api.files.update(
        meta,
        fileId,
        uploadMedia: media,
      );
    } else {
      meta.parents = <String>[folderId];
      await api.files.create(
        meta,
        uploadMedia: media,
      );
    }
  }

  Future<Map<String, dynamic>> _downloadJson(String driveFileId) async {
    final api = await _api();
    final media = await api.files.get(
      driveFileId,
      downloadOptions: gdrive.DownloadOptions.fullMedia,
    ) as gdrive.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    final text = utf8.decode(builder.takeBytes());
    final map = jsonDecode(text);
    if (map is! Map) {
      throw const FormatException('Invalid JSON from Drive.');
    }
    return Map<String, dynamic>.from(map);
  }

  Future<ResumeData> downloadResume(String resumeId, String driveFileId) async {
    final json = await _downloadJson(driveFileId);
    return resumeFromDrivePayload(json);
  }

  Future<CoverLetterData> downloadCoverLetter(
    String coverLetterId,
    String driveFileId,
  ) async {
    final json = await _downloadJson(driveFileId);
    return CoverLetterData.fromJson(json);
  }

  Future<void> deleteResume(String driveFileId) async {
    await _deleteDriveFile(driveFileId);
  }

  Future<void> deleteCoverLetter(String driveFileId) async {
    await _deleteDriveFile(driveFileId);
  }

  Future<void> _deleteDriveFile(String driveFileId) async {
    final api = await _api();
    await api.files.delete(driveFileId);
  }
}
