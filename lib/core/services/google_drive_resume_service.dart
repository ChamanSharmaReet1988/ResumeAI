import 'dart:convert';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;

import '../models/resume_models.dart';

/// One row in the Google Drive backup list (same shape as iCloud summaries).
class GoogleDriveResumeSummary {
  const GoogleDriveResumeSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.driveFileId,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Drive file id (not the resume JSON `id`).
  final String driveFileId;
}

/// Resume backup to a **ResumeApp** folder on Google Drive using the
/// `drive.file` scope (files created by this app only).
class GoogleDriveResumeService {
  GoogleDriveResumeService();

  static const _folderName = 'ResumeApp';
  static const _scopes = <String>[gdrive.DriveApi.driveFileScope];

  GoogleSignInAccount? _account;

  /// Avoids a Drive folder lookup on every list/upload after the first.
  String? _cachedResumeAppFolderId;

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
    final account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    await account.authorizationClient.authorizeScopes(_scopes);
    _account = account;
  }

  Future<void> signOut() async {
    _account = null;
    _cachedResumeAppFolderId = null;
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

  /// One `files.list` for all `.json` files in [folderId] (used to batch uploads).
  Future<Map<String, String>> _jsonFileIdsByName(
    gdrive.DriveApi api,
    String folderId,
  ) async {
    final list = await api.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    final map = <String, String>{};
    for (final f in list.files ?? const <gdrive.File>[]) {
      final name = f.name;
      final id = f.id;
      if (name != null && name.endsWith('.json') && id != null) {
        map[name] = id;
      }
    }
    return map;
  }

  Future<List<GoogleDriveResumeSummary>> listResumes() async {
    final api = await _api();
    final folderId = await _folderId(api);
    final list = await api.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name,mimeType,modifiedTime,appProperties,createdTime)',
    );
    final out = <GoogleDriveResumeSummary>[];
    for (final f in list.files ?? const <gdrive.File>[]) {
      final name = f.name;
      if (name == null || !name.endsWith('.json')) {
        continue;
      }
      final resumeId = name.replaceFirst(RegExp(r'\.json$'), '');
      if (resumeId.isEmpty) {
        continue;
      }
      final props = f.appProperties ?? const <String, String>{};
      final title = (props['title']?.trim().isNotEmpty ?? false)
          ? props['title']!.trim()
          : ResumeData.defaultTitle;
      // Prefer logical resume `updatedAt` from metadata. Drive's `modifiedTime`
      // is "last upload" and stays ahead of local `ResumeData.updatedAt` after
      // sync, which would wrongly show the Download button as enabled.
      final propUpdated = props['updatedAt'] != null
          ? DateTime.tryParse(props['updatedAt']!)
          : null;
      final updated = propUpdated ?? f.modifiedTime ?? DateTime.now();
      final created = f.createdTime ?? updated;
      out.add(
        GoogleDriveResumeSummary(
          id: resumeId,
          title: title,
          createdAt: created,
          updatedAt: updated,
          driveFileId: f.id!,
        ),
      );
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
    final bytes = utf8.encode(jsonEncode(resume.toJson()));
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

  Future<ResumeData> downloadResume(String resumeId, String driveFileId) async {
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
      throw const FormatException('Invalid resume JSON from Drive.');
    }
    return ResumeData.fromJson(Map<String, dynamic>.from(map));
  }
}
