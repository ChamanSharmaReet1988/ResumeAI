import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/services/app_preferences.dart';
import 'core/services/resume_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await ResumeRepository.create();
  final appPreferences = await AppPreferences.open();
  runApp(
    ResumeApp(repository: repository, appPreferences: appPreferences),
  );
}
