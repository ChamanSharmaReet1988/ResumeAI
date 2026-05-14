import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/settings/icloud_backup_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeICloudRepository implements ResumeRepository {
  _FakeICloudRepository({required this.resumes});

  final List<ResumeData> resumes;

  @override
  Future<void> deleteCoverLetter(String id) async {}

  @override
  Future<void> deleteResume(String id) async {
    resumes.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => const [];

  @override
  Future<List<ResumeData>> loadResumes() async => List<ResumeData>.from(resumes);

  @override
  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {}

  @override
  Future<void> upsertResume(ResumeData resume) async {
    resumes.removeWhere((item) => item.id == resume.id);
    resumes.add(resume);
  }
}

class _FakeICloudResumeService implements ICloudResumeService {
  _FakeICloudResumeService({
    required this.cloudPayloads,
    bool available = true,
  }) : cloudSummaries = cloudPayloads.values
           .map(
             (resume) => ICloudResumeSummary(
               id: resume.id,
               title: resume.title,
               createdAt: resume.createdAt,
               updatedAt: resume.updatedAt,
               isDownloaded: true,
             ),
           )
           .toList(),
       _available = available;

  final bool _available;
  final Map<String, ResumeData> cloudPayloads;
  final List<List<String>> uploadedBatches = [];
  List<ICloudResumeSummary> cloudSummaries;

  @override
  Future<ResumeData> downloadResume(String id) async => cloudPayloads[id]!;

  @override
  Future<bool> isAvailable() async => _available;

  @override
  Future<List<ICloudResumeSummary>> listResumes() async =>
      List<ICloudResumeSummary>.from(cloudSummaries);

  @override
  Future<List<String>> uploadResumes(List<ResumeData> resumes) async {
    final ids = resumes.map((item) => item.id).toList();
    uploadedBatches.add(ids);
    final syncedAt = DateTime.now();
    for (final resume in resumes) {
      final synced = resume.copyWith(lastSyncedAt: syncedAt);
      cloudPayloads[resume.id] = synced;
    }
    cloudSummaries = cloudPayloads.values
        .map(
          (resume) => ICloudResumeSummary(
            id: resume.id,
            title: resume.title,
            createdAt: resume.createdAt,
            updatedAt: resume.updatedAt,
            isDownloaded: true,
          ),
        )
        .toList();
    return ids;
  }
}

void main() {
  testWidgets('downloads newer iCloud resume into local storage', (
    tester,
  ) async {
    final localResume = ResumeData.empty(
      template: ResumeTemplate.corporate,
    ).copyWith(
      id: 'resume-1',
      title: 'Local Resume',
      summary: 'Local summary',
      updatedAt: DateTime(2026, 5, 10),
    );
    final cloudResume = localResume.copyWith(
      title: 'Cloud Resume',
      summary: 'Cloud summary',
      updatedAt: DateTime(2026, 5, 12),
    );
    final repository = _FakeICloudRepository(resumes: [localResume]);
    final library = ResumeLibraryViewModel(repository: repository);
    await library.loadResumes();
    final service = _FakeICloudResumeService(
      cloudPayloads: {cloudResume.id: cloudResume},
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ResumeRepository>.value(value: repository),
          Provider<ICloudResumeService>.value(value: service),
          ChangeNotifierProvider<ResumeLibraryViewModel>.value(value: library),
        ],
        child: const MaterialApp(home: ICloudBackupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(repository.resumes.single.title, 'Cloud Resume');
    expect(repository.resumes.single.summary, 'Cloud summary');
    expect(repository.resumes.single.lastSyncedAt, isNotNull);
  });

  testWidgets('sync uploads only local resumes that are not older than iCloud', (
    tester,
  ) async {
    final localNewer = ResumeData.empty(
      template: ResumeTemplate.corporate,
    ).copyWith(
      id: 'resume-1',
      title: 'Newer Local',
      updatedAt: DateTime(2026, 5, 12),
    );
    final localOnly = ResumeData.empty(
      template: ResumeTemplate.corporate,
    ).copyWith(
      id: 'resume-2',
      title: 'Local Only',
      updatedAt: DateTime(2026, 5, 11),
    );
    final localOlder = ResumeData.empty(
      template: ResumeTemplate.corporate,
    ).copyWith(
      id: 'resume-3',
      title: 'Older Local',
      updatedAt: DateTime(2026, 5, 10),
    );
    final cloudNewer = localOlder.copyWith(updatedAt: DateTime(2026, 5, 13));
    final cloudOlder = localNewer.copyWith(updatedAt: DateTime(2026, 5, 9));

    final repository = _FakeICloudRepository(
      resumes: [localNewer, localOnly, localOlder],
    );
    final library = ResumeLibraryViewModel(repository: repository);
    await library.loadResumes();
    final service = _FakeICloudResumeService(
      cloudPayloads: {
        cloudNewer.id: cloudNewer,
        cloudOlder.id: cloudOlder,
      },
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ResumeRepository>.value(value: repository),
          Provider<ICloudResumeService>.value(value: service),
          ChangeNotifierProvider<ResumeLibraryViewModel>.value(value: library),
        ],
        child: const MaterialApp(home: ICloudBackupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sync to iCloud'));
    await tester.pumpAndSettle();

    expect(service.uploadedBatches, hasLength(1));
    expect(service.uploadedBatches.single, containsAll(['resume-1', 'resume-2']));
    expect(service.uploadedBatches.single, isNot(contains('resume-3')));
  });
}
