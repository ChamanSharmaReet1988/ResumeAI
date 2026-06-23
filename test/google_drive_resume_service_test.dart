import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/profile_image_storage.dart';

class _FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationSupportPath() async => root.path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gdrive_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('coverLetterDisplayTitleFromJson', () {
    test('uses title when present', () {
      expect(
        coverLetterDisplayTitleFromJson(<String, dynamic>{'title': 'My Letter'}),
        'My Letter',
      );
    });

    test('falls back to role and company', () {
      expect(
        coverLetterDisplayTitleFromJson(<String, dynamic>{
          'role': 'Engineer',
          'company': 'Acme',
        }),
        'Engineer · Acme',
      );
    });

    test('uses untitled when empty', () {
      expect(
        coverLetterDisplayTitleFromJson(const <String, dynamic>{}),
        'Untitled Cover Letter',
      );
    });
  });

  group('buildResumeUploadPayload', () {
    test('embeds profile image as base64', () async {
      final resumeId = 'resume-photo';
      final imageDir = await ProfileImageStorage.profileDirectory();
      final imageFile = File('${imageDir.path}/$resumeId.png');
      await imageFile.writeAsBytes(<int>[1, 2, 3, 4]);

      final resume = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(
            id: resumeId,
            profileImagePath: imageFile.path,
          );

      final payload = await buildResumeUploadPayload(resume);

      expect(payload['profileImagePath'], '');
      expect(payload['profileImageBase64'], isNotEmpty);
      expect(payload['profileImageExtension'], 'png');
      expect(base64Decode(payload['profileImageBase64'] as String), <int>[1, 2, 3, 4]);
    });

    test('leaves payload unchanged when no profile image', () async {
      final resume = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(id: 'no-photo');

      final payload = await buildResumeUploadPayload(resume);

      expect(payload.containsKey('profileImageBase64'), isFalse);
      expect(payload['profileImagePath'], '');
    });
  });

  group('resumeFromDrivePayload', () {
    test('restores profile image to managed storage', () async {
      const resumeId = 'restore-photo';
      final bytes = <int>[9, 8, 7, 6];
      final json = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(id: resumeId)
          .toJson()
        ..['profileImagePath'] = ''
        ..['profileImageBase64'] = base64Encode(bytes)
        ..['profileImageExtension'] = 'jpg';

      final restored = await resumeFromDrivePayload(json);

      expect(restored.profileImagePath, isNotEmpty);
      expect(
        File(restored.profileImagePath).readAsBytesSync(),
        bytes,
      );
    });

    test('returns resume unchanged when no embedded image', () async {
      final json = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(id: 'plain')
          .toJson();

      final restored = await resumeFromDrivePayload(json);

      expect(restored.id, 'plain');
      expect(restored.profileImagePath, '');
    });
  });
}
