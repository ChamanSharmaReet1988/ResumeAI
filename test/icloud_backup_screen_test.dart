import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/premium_purchase_service.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/settings/icloud_backup_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

Widget _icloudTestApp({
  required ResumeRepository repository,
  required ICloudResumeService service,
  required ResumeLibraryViewModel resumeLibrary,
  AppPreferences? preferences,
}) {
  final prefs = preferences ?? AppPreferences.inMemory();
  return MultiProvider(
    providers: [
      Provider<AppPreferences>.value(value: prefs),
      Provider<ResumeRepository>.value(value: repository),
      Provider<ICloudResumeService>.value(value: service),
      ChangeNotifierProvider<PremiumPurchaseService>(
        create: (_) => PremiumPurchaseService.inMemory(
          appPreferences: prefs,
          isPremium: true,
        ),
      ),
      ChangeNotifierProvider<ResumeLibraryViewModel>.value(value: resumeLibrary),
      ChangeNotifierProvider<CoverLetterLibraryViewModel>(
        create: (_) => CoverLetterLibraryViewModel(repository: repository),
      ),
    ],
    child: const MaterialApp(home: ICloudBackupScreen()),
  );
}

class _FakeICloudRepository implements ResumeRepository {
  _FakeICloudRepository({required this.resumes});

  final List<ResumeData> resumes;

  @override
  void configureGoogleDriveAutoSync({
    required AppPreferences appPreferences,
    required GoogleDriveResumeService service,
  }) {}

  @override
  void configureICloudAutoSync({
    required AppPreferences appPreferences,
    required ICloudResumeService service,
    bool Function()? hasPremium,
  }) {}

  @override
  Future<void> deleteCoverLetter(String id) async {}

  @override
  Future<void> deleteResume(String id) async {
    resumes.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => const [];

  @override
  Future<List<ResumeData>> loadResumes() async =>
      List<ResumeData>.from(resumes);

  @override
  Future<void> upsertCoverLetter(
    CoverLetterData coverLetter, {
    bool scheduleAutoSync = true,
  }) async {}

  @override
  Future<void> upsertResume(
    ResumeData resume, {
    bool scheduleAutoSync = true,
  }) async {
    resumes.removeWhere((item) => item.id == resume.id);
    resumes.add(resume);
  }
}

class _FakeICloudResumeService implements ICloudResumeService {
  _FakeICloudResumeService({required this.cloudPayloads, bool available = true})
    : cloudSummaries = cloudPayloads.values
          .map(
            (resume) => ICloudResumeSummary(
              id: resume.id,
              title: resume.title,
              createdAt: resume.createdAt,
              updatedAt: resume.updatedAt,
              isDownloaded: true,
              isCoverLetter: false,
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
  Future<CoverLetterData> downloadCoverLetter(String id) async {
    throw UnimplementedError();
  }

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
            isCoverLetter: false,
          ),
        )
        .toList();
    return ids;
  }

  @override
  Future<List<String>> uploadCoverLetters(List<CoverLetterData> coverLetters) async =>
      coverLetters.map((c) => c.id).toList();

  final List<({String id, bool isCoverLetter})> deletedItems = [];

  @override
  Future<void> deleteFromICloud({
    required String id,
    required bool isCoverLetter,
  }) async {
    deletedItems.add((id: id, isCoverLetter: isCoverLetter));
    cloudSummaries = cloudSummaries
        .where(
          (item) => !(item.id == id && item.isCoverLetter == isCoverLetter),
        )
        .toList();
    cloudPayloads.remove(id);
  }
}

void main() {
  testWidgets('downloads newer iCloud resume into local storage', (
    tester,
  ) async {
    final localResume = ResumeData.empty(template: ResumeTemplate.corporate)
        .copyWith(
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
      _icloudTestApp(
        repository: repository,
        service: service,
        resumeLibrary: library,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cloud Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(repository.resumes.single.title, 'Cloud Resume');
    expect(repository.resumes.single.summary, 'Cloud summary');
    expect(repository.resumes.single.lastSyncedAt, isNotNull);
  });

  testWidgets(
    'sync uploads only local resumes that are not older than iCloud',
    (tester) async {
      final localNewer = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(
            id: 'resume-1',
            title: 'Newer Local',
            updatedAt: DateTime(2026, 5, 12),
          );
      final localOnly = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(
            id: 'resume-2',
            title: 'Local Only',
            updatedAt: DateTime(2026, 5, 11),
          );
      final localOlder = ResumeData.empty(template: ResumeTemplate.corporate)
          .copyWith(
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
        cloudPayloads: {cloudNewer.id: cloudNewer, cloudOlder.id: cloudOlder},
      );

      await tester.pumpWidget(
        _icloudTestApp(
          repository: repository,
          service: service,
          resumeLibrary: library,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sync'));
      await tester.pumpAndSettle();

      expect(service.uploadedBatches, hasLength(1));
      expect(
        service.uploadedBatches.single,
        containsAll(['resume-1', 'resume-2']),
      );
      expect(service.uploadedBatches.single, isNot(contains('resume-3')));
    },
  );

  testWidgets('auto sync switch persists to app preferences', (tester) async {
    final repository = _FakeICloudRepository(resumes: const []);
    final library = ResumeLibraryViewModel(repository: repository);
    await library.loadResumes();
    final service = _FakeICloudResumeService(cloudPayloads: const {});
    final preferences = AppPreferences.inMemory();

    await tester.pumpWidget(
      _icloudTestApp(
        repository: repository,
        service: service,
        resumeLibrary: library,
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();

    expect(preferences.iCloudAutoSyncEnabled, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(preferences.iCloudAutoSyncEnabled, isTrue);
  });
}
