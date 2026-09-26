import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resume_app/app/app_theme.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/app_preferences.dart';
import 'package:resume_app/core/services/google_drive_resume_service.dart';
import 'package:resume_app/core/services/icloud_resume_service.dart';
import 'package:resume_app/core/services/premium_purchase_service.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:resume_app/features/builder/resume_builder_screen.dart';
import 'package:resume_app/features/shared/view_models.dart';
import 'package:resume_app/features/templates/templates_screen.dart';
import 'package:resume_app/l10n/app_localizations.dart';

/// Play Store phone screenshot size (9:16).
const _phonePhysical = Size(1080, 1920);
const _phoneLogicalWidth = 390.0;
const _phoneDpr = 1080.0 / _phoneLogicalWidth; // ~2.769
const _phoneLogicalHeight = 1920.0 / _phoneDpr;
const _phoneLogical = Size(_phoneLogicalWidth, _phoneLogicalHeight);

Future<void> _loadStoreScreenshotFonts() async {
  Future<ByteData> fromFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  Future<void> loadFamily(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }

  await loadFamily('Nunito', [
    'assets/fonts/nunito/Nunito-Regular.ttf',
    'assets/fonts/nunito/Nunito-Medium.ttf',
    'assets/fonts/nunito/Nunito-SemiBold.ttf',
    'assets/fonts/nunito/Nunito-Bold.ttf',
    'assets/fonts/nunito/Nunito-ExtraBold.ttf',
  ]);
  await loadFamily('Outfit', [
    'assets/fonts/outfit/Outfit-Regular.ttf',
    'assets/fonts/outfit/Outfit-Medium.ttf',
    'assets/fonts/outfit/Outfit-SemiBold.ttf',
    'assets/fonts/outfit/Outfit-Bold.ttf',
  ]);

  final materialIconsPath =
      '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(materialIconsPath).existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(fromFile(materialIconsPath));
    await loader.load();
  }
}

class _FakeRepository implements ResumeRepository {
  @override
  void configureGoogleDriveAutoSync({
    required AppPreferences appPreferences,
    required GoogleDriveResumeService service,
    bool Function()? hasPremium,
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
  Future<void> deleteResume(String id) async {}

  @override
  Future<List<CoverLetterData>> loadCoverLetters() async => const [];

  @override
  Future<List<ResumeData>> loadResumes() async => const [];

  @override
  Future<void> upsertCoverLetter(
    CoverLetterData coverLetter, {
    bool scheduleAutoSync = true,
  }) async {}

  @override
  Future<void> upsertResume(
    ResumeData resume, {
    bool scheduleAutoSync = true,
  }) async {}
}

void main() {
  final enabled = Platform.environment['CAPTURE_STORE_SCREENSHOTS'] == '1';

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!enabled) {
      return;
    }
    await _loadStoreScreenshotFonts();
  });

  Future<void> preparePhoneSurface(WidgetTester tester) async {
    tester.view.physicalSize = Size(
      _phoneLogical.width * _phoneDpr,
      _phoneLogical.height * _phoneDpr,
    );
    tester.view.devicePixelRatio = _phoneDpr;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'capture Android templates screen screenshot',
    (tester) async {
      await preparePhoneSurface(tester);

      final library = ResumeLibraryViewModel(repository: _FakeRepository());
      final prefs = AppPreferences.inMemory(isPremium: true);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResumeLibraryViewModel>.value(
              value: library,
            ),
            Provider<ResumePdfService>(create: (_) => ResumePdfService()),
            ChangeNotifierProvider<PremiumPurchaseService>(
              create: (_) => PremiumPurchaseService.inMemory(
                appPreferences: prefs,
                isPremium: true,
              ),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(TargetPlatform.android),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RepaintBoundary(
              key: const ValueKey('store-screenshot-root'),
              child: Scaffold(
                body: const SafeArea(
                  child: TemplatesScreen(onCreateResume: _noop),
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: 1,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_customize_outlined),
                      selectedIcon: Icon(Icons.dashboard_customize_rounded),
                      label: 'Templates',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.auto_awesome_outlined),
                      selectedIcon: Icon(Icons.auto_awesome_rounded),
                      label: 'AI Resume',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byKey(const ValueKey('store-screenshot-root')),
        matchesGoldenFile(
          '../store_screenshots/android/01_resume_templates.png',
        ),
      );
    },
    skip: !enabled,
  );

  testWidgets(
    'capture Android resume builder screen screenshot',
    (tester) async {
      await preparePhoneSurface(tester);

      final viewModel = ResumeEditorViewModel(
        repository: _FakeRepository(),
        aiService: LocalAiResumeService(),
        pdfService: ResumePdfService(),
        seedResume:
            ResumeData.empty(template: ResumeTemplate.corporate).copyWith(
          title: 'Product Manager Resume',
          fullName: 'Alex Morgan',
          jobTitle: 'Senior Product Manager',
          email: 'alex.morgan@email.com',
          phone: '+1 (415) 555-0198',
          location: 'San Francisco, CA',
          summary:
              'Product leader with 8+ years shipping B2B SaaS features that grow retention and revenue.',
          workExperiences: [
            WorkExperience(
              role: 'Senior Product Manager',
              company: 'Northstar Labs',
              startDate: 'Jan 2021',
              endDate: 'Present',
              description: '',
              bullets: const [
                'Led roadmap for analytics suite used by 120k monthly active users.',
                'Increased trial-to-paid conversion by 18% through onboarding redesign.',
              ],
            ),
          ],
          education: const [
            EducationItem(
              institution: 'University of California, Berkeley',
              degree: 'B.S. Business Administration',
              startDate: '2012',
              endDate: '2016',
            ),
          ],
          skills: const [
            'Product Strategy',
            'Roadmapping',
            'User Research',
            'A/B Testing',
            'SQL',
          ],
          projects: const [
            ProjectItem(
              title: 'Customer Insights Hub',
              bullets: [
                'Built cross-functional research repository adopted by Design and Growth.',
              ],
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResumeEditorViewModel>.value(
              value: viewModel,
            ),
            Provider<AppPreferences>.value(
              value: AppPreferences.inMemory(isPremium: true),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(TargetPlatform.android),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RepaintBoundary(
              key: ValueKey('store-screenshot-root'),
              child: ResumeBuilderScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byKey(const ValueKey('store-screenshot-root')),
        matchesGoldenFile('../store_screenshots/android/02_resume_builder.png'),
      );
    },
    skip: !enabled,
  );
}

void _noop() {}
