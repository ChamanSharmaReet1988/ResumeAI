import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'app/app.dart';
import 'core/config/google_sign_in_config.dart';
import 'core/services/app_preferences.dart';
import 'core/services/premium_purchase_service.dart';
import 'core/services/firebase_app_services.dart';
import 'core/services/google_drive_resume_service.dart';
import 'core/services/icloud_resume_service.dart';
import 'core/services/resume_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? GoogleSignInConfig.iosClientId
            : null,
        serverClientId: GoogleSignInConfig.androidServerClientId,
      );
    } catch (error, stackTrace) {
      assert(() {
        debugPrint('GoogleSignIn.initialize failed: $error\n$stackTrace');
        return true;
      }());
    }
  }
  final repository = await ResumeRepository.create();
  final appPreferences = await AppPreferences.open();
  final googleDriveResumeService = GoogleDriveResumeService();
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // Ignore the deprecation here intentionally; this is a targeted fallback
    // for real-device product lookup failures coming from the StoreKit2 path.
    // ignore: deprecated_member_use
    await InAppPurchaseStoreKitPlatform.enableStoreKit1();
    InAppPurchaseStoreKitPlatform.registerPlatform();
  }
  final premiumPurchaseService = PremiumPurchaseService(
    appPreferences: appPreferences,
  );
  repository.configureGoogleDriveAutoSync(
    appPreferences: appPreferences,
    service: googleDriveResumeService,
    hasPremium: () => premiumPurchaseService.isPremium,
  );
  repository.configureICloudAutoSync(
    appPreferences: appPreferences,
    service: const MethodChannelICloudResumeService(),
    hasPremium: () => premiumPurchaseService.isPremium,
  );
  await premiumPurchaseService.initialize();

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
      premiumPurchaseService: premiumPurchaseService,
      firebaseServices: firebaseServices,
      googleDriveResumeService: googleDriveResumeService,
    ),
  );
}
