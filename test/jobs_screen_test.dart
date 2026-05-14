import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/job_search_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/jobs/jobs_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';

class _FakeJobsRepository implements ResumeRepository {
  _FakeJobsRepository({required this.resumes});

  final List<ResumeData> resumes;

  @override
  void configureICloudAutoSync({
    required AppPreferences appPreferences,
    required ICloudResumeService service,
  }) {}

  @override
  Future<void> deleteCoverLetter(String id) async {}

  @override
  Future<void> deleteResume(String id) async {}

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => const [];

  @override
  Future<List<ResumeData>> loadResumes() async => resumes;

  @override
  Future<void> upsertCoverLetter(CoverLetterData coverLetter) async {}

  @override
  Future<void> upsertResume(
    ResumeData resume, {
    bool scheduleAutoSync = true,
  }) async {}
}

class _FakeJobSearchService extends JobSearchService {
  @override
  Future<List<JobPosting>> fetchLatestJobs({
    required String query,
    String? location,
  }) async {
    final normalizedLocation = (location == null || location.trim().isEmpty)
        ? 'Remote'
        : location.trim();
    return [
      JobPosting(
        title: query,
        company: 'Example Co',
        location: normalizedLocation,
        applyUrl:
            'https://example.com/jobs/${query.toLowerCase().replaceAll(' ', '-')}',
        source: 'Remotive',
        postedAt: DateTime.now().toUtc(),
        tags: {query.toLowerCase()},
      ),
    ];
  }
}

void main() {
  testWidgets('jobs screen follows the shared selected resume', (tester) async {
    final firstResume = ResumeData.empty(template: ResumeTemplate.corporate)
        .copyWith(
          id: 'resume-1',
          title: 'Flutter Resume',
          jobTitle: 'Flutter Developer',
          skills: const ['Flutter', 'Dart', 'Testing'],
        );
    final secondResume = ResumeData.empty(template: ResumeTemplate.corporate)
        .copyWith(
          id: 'resume-2',
          title: 'Data Resume',
          jobTitle: 'Data Analyst',
          skills: const ['SQL', 'Analytics', 'Excel'],
        );

    final library = ResumeLibraryViewModel(
      repository: _FakeJobsRepository(resumes: [firstResume, secondResume]),
    );
    await library.loadResumes();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeLibraryViewModel>.value(value: library),
          Provider<JobSearchService>.value(value: _FakeJobSearchService()),
        ],
        child: const MaterialApp(home: Scaffold(body: JobsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('jobs-resume-picker-resume-1')),
      findsOneWidget,
    );
    expect(find.text('Flutter Developer'), findsWidgets);

    library.selectResume(secondResume.id);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('jobs-resume-picker-resume-2')),
      findsOneWidget,
    );
    expect(find.text('Data Analyst'), findsWidgets);
    expect(find.text('Flutter Developer'), findsNothing);
    expect(find.textContaining('SQL'), findsNothing);
  });
}
