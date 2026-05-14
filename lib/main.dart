import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/services/app_preferences.dart';
import 'core/services/firebase_app_services.dart';
import 'core/services/icloud_resume_service.dart';
import 'core/services/resume_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await ResumeRepository.create();
  final appPreferences = await AppPreferences.open();
  repository.configureICloudAutoSync(
    appPreferences: appPreferences,
    service: const MethodChannelICloudResumeService(),
  );
  final firebaseServices = await FirebaseAppServices.initialize();
  if (!firebaseServices.isEnabled && kDebugMode) {
    debugPrint(
      'Firebase is disabled. Add google-services.json and '
      'GoogleService-Info.plist to enable Analytics, Crashlytics, and Remote '
      'Config.',
    );
  }
  runApp(
    ResumeApp(
      repository: repository,
      appPreferences: appPreferences,
      firebaseServices: firebaseServices,
    ),
  );
}
