import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_id.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('id'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ResumeAI'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get tabTemplates;

  /// No description provided for @tabAiResume.
  ///
  /// In en, this message translates to:
  /// **'AI Resume'**
  String get tabAiResume;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languagePortugueseBrazil.
  ///
  /// In en, this message translates to:
  /// **'Português (Brasil)'**
  String get languagePortugueseBrazil;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @iCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'iCloud Backup'**
  String get iCloudBackup;

  /// No description provided for @googleDriveBackup.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Backup'**
  String get googleDriveBackup;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @youAreProUser.
  ///
  /// In en, this message translates to:
  /// **'You are a Pro user'**
  String get youAreProUser;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @versionWithBuild.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String versionWithBuild(String version, String build);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @languageAffectsAppOnly.
  ///
  /// In en, this message translates to:
  /// **'Changes app menus and labels only. Your resume content stays as written.'**
  String get languageAffectsAppOnly;

  /// No description provided for @homeSegmentResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeSegmentResume;

  /// No description provided for @homeSegmentCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get homeSegmentCoverLetter;

  /// No description provided for @noResumesYet.
  ///
  /// In en, this message translates to:
  /// **'No resumes yet'**
  String get noResumesYet;

  /// No description provided for @noResumesYetBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the add button to create your first resume.'**
  String get noResumesYetBody;

  /// No description provided for @noCoverLettersYet.
  ///
  /// In en, this message translates to:
  /// **'No cover letters yet'**
  String get noCoverLettersYet;

  /// No description provided for @noCoverLettersYetBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the add button to create your first cover letter.'**
  String get noCoverLettersYetBody;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @deleteResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete resume?'**
  String get deleteResumeTitle;

  /// No description provided for @deleteResumeMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This action cannot be undone.'**
  String deleteResumeMessage(String title);

  /// No description provided for @deleteCoverLetterTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete cover letter?'**
  String get deleteCoverLetterTitle;

  /// No description provided for @deleteCoverLetterMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This action cannot be undone.'**
  String deleteCoverLetterMessage(String title);

  /// No description provided for @renameResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename resume'**
  String get renameResumeTitle;

  /// No description provided for @duplicateResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate resume'**
  String get duplicateResumeTitle;

  /// No description provided for @resumeRenamed.
  ///
  /// In en, this message translates to:
  /// **'Resume renamed.'**
  String get resumeRenamed;

  /// No description provided for @resumeDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Resume duplicated.'**
  String get resumeDuplicated;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume title'**
  String get resumeTitle;

  /// No description provided for @enterResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter resume title'**
  String get enterResumeTitle;

  /// No description provided for @coverLetterTitle.
  ///
  /// In en, this message translates to:
  /// **'Cover letter title'**
  String get coverLetterTitle;

  /// No description provided for @updatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedDate(String date);

  /// No description provided for @titleWithCopySuffix.
  ///
  /// In en, this message translates to:
  /// **'{title} (Copy)'**
  String titleWithCopySuffix(String title);

  /// No description provided for @untitledResume.
  ///
  /// In en, this message translates to:
  /// **'Untitled Resume'**
  String get untitledResume;

  /// No description provided for @untitledCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'Untitled Cover Letter'**
  String get untitledCoverLetter;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @resumeAppPro.
  ///
  /// In en, this message translates to:
  /// **'ResumeApp Pro'**
  String get resumeAppPro;

  /// No description provided for @chooseAPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get chooseAPlan;

  /// No description provided for @premiumLegalAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Use and Privacy Policy.'**
  String get premiumLegalAgreement;

  /// No description provided for @subscriptionFound.
  ///
  /// In en, this message translates to:
  /// **'Subscription found'**
  String get subscriptionFound;

  /// No description provided for @processingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processingEllipsis;

  /// No description provided for @checkingYourSubscription.
  ///
  /// In en, this message translates to:
  /// **'Checking your subscription…'**
  String get checkingYourSubscription;

  /// No description provided for @completingYourPurchase.
  ///
  /// In en, this message translates to:
  /// **'Completing your purchase…'**
  String get completingYourPurchase;

  /// No description provided for @restoringYourSubscription.
  ///
  /// In en, this message translates to:
  /// **'Restoring your subscription…'**
  String get restoringYourSubscription;

  /// No description provided for @pleaseWaitDoNotClose.
  ///
  /// In en, this message translates to:
  /// **'Please wait. Do not close the app.'**
  String get pleaseWaitDoNotClose;

  /// No description provided for @premiumWelcomeCongratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get premiumWelcomeCongratulations;

  /// No description provided for @premiumWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'ResumeApp Pro is active on your {planLabel}. Premium templates and {backup} are now unlocked.'**
  String premiumWelcomeBody(String planLabel, String backup);

  /// No description provided for @premiumBenefitUnlockLayouts.
  ///
  /// In en, this message translates to:
  /// **'Unlock every ATS resume layout and AI ATS create'**
  String get premiumBenefitUnlockLayouts;

  /// No description provided for @premiumBenefitBackupIcloud.
  ///
  /// In en, this message translates to:
  /// **'Back up and sync resumes with iCloud'**
  String get premiumBenefitBackupIcloud;

  /// No description provided for @premiumBenefitBackupGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Back up and sync resumes with Google Drive'**
  String get premiumBenefitBackupGoogleDrive;

  /// No description provided for @premiumUpcomingUpdateBadge.
  ///
  /// In en, this message translates to:
  /// **'Coming in the next update'**
  String get premiumUpcomingUpdateBadge;

  /// No description provided for @premiumUpcomingUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'New resume layouts and modern templates, included with Pro.'**
  String get premiumUpcomingUpdateMessage;

  /// No description provided for @planWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get planWeekly;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @planPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get planPro;

  /// No description provided for @planSubtitleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Short-term access'**
  String get planSubtitleWeekly;

  /// No description provided for @planSubtitleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Pay month to month'**
  String get planSubtitleMonthly;

  /// No description provided for @planSubtitleYearly.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get planSubtitleYearly;

  /// No description provided for @planLabelNamed.
  ///
  /// In en, this message translates to:
  /// **'{title} plan'**
  String planLabelNamed(String title);

  /// No description provided for @savePercentWithYearlyBilling.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}% with yearly billing'**
  String savePercentWithYearlyBilling(int percent);

  /// No description provided for @priceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get priceUnavailable;

  /// No description provided for @storeAccountGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google account'**
  String get storeAccountGoogle;

  /// No description provided for @storeAccountApple.
  ///
  /// In en, this message translates to:
  /// **'Apple ID'**
  String get storeAccountApple;

  /// No description provided for @alreadySubscribedDebugOverride.
  ///
  /// In en, this message translates to:
  /// **'Developer Pro override is on. All Pro features are unlocked for testing on this device.'**
  String get alreadySubscribedDebugOverride;

  /// No description provided for @alreadySubscribedWeekly.
  ///
  /// In en, this message translates to:
  /// **'You have an active weekly subscription. All Pro templates, {backup}, and premium features are included.'**
  String alreadySubscribedWeekly(String backup);

  /// No description provided for @alreadySubscribedMonthly.
  ///
  /// In en, this message translates to:
  /// **'You have an active monthly subscription. All Pro templates, {backup}, and premium features are included.'**
  String alreadySubscribedMonthly(String backup);

  /// No description provided for @alreadySubscribedYearly.
  ///
  /// In en, this message translates to:
  /// **'You have an active yearly subscription. All Pro templates, {backup}, and premium features are included.'**
  String alreadySubscribedYearly(String backup);

  /// No description provided for @alreadySubscribedGeneric.
  ///
  /// In en, this message translates to:
  /// **'You have an active ResumeApp Pro subscription. All premium features are included in your plan.'**
  String get alreadySubscribedGeneric;

  /// No description provided for @restoreInsteadWeekly.
  ///
  /// In en, this message translates to:
  /// **'A weekly subscription was found for this {account}. Use Restore to activate it on this device instead of buying again.'**
  String restoreInsteadWeekly(String account);

  /// No description provided for @restoreInsteadMonthly.
  ///
  /// In en, this message translates to:
  /// **'A monthly subscription was found for this {account}. Use Restore to activate it on this device instead of buying again.'**
  String restoreInsteadMonthly(String account);

  /// No description provided for @restoreInsteadYearly.
  ///
  /// In en, this message translates to:
  /// **'A yearly subscription was found for this {account}. Use Restore to activate it on this device instead of buying again.'**
  String restoreInsteadYearly(String account);

  /// No description provided for @restoreInsteadGeneric.
  ///
  /// In en, this message translates to:
  /// **'An active ResumeApp Pro subscription was found for this {account}. Use Restore to activate it on this device instead of buying again.'**
  String restoreInsteadGeneric(String account);

  /// No description provided for @premiumPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not complete your purchase. Please try again.'**
  String get premiumPurchaseFailed;

  /// No description provided for @premiumRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not restore your subscription. Please try again.'**
  String get premiumRestoreFailed;

  /// No description provided for @noSubscriptionToRestoreGoogle.
  ///
  /// In en, this message translates to:
  /// **'No active subscription was found for this Google account.'**
  String get noSubscriptionToRestoreGoogle;

  /// No description provided for @noSubscriptionToRestoreApple.
  ///
  /// In en, this message translates to:
  /// **'No active subscription was found for this Apple ID.'**
  String get noSubscriptionToRestoreApple;

  /// No description provided for @premiumStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not available on this device right now.'**
  String get premiumStoreUnavailable;

  /// No description provided for @premiumConnectFailedGoogle.
  ///
  /// In en, this message translates to:
  /// **'We could not connect to Google Play. Please try again later.'**
  String get premiumConnectFailedGoogle;

  /// No description provided for @premiumConnectFailedApple.
  ///
  /// In en, this message translates to:
  /// **'We could not connect to the App Store. Please try again later.'**
  String get premiumConnectFailedApple;

  /// No description provided for @premiumVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not verify your subscription. Please try again.'**
  String get premiumVerifyFailed;

  /// No description provided for @premiumProductsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans are not available right now. Please try again later.'**
  String get premiumProductsUnavailable;

  /// No description provided for @premiumPurchaseCanceled.
  ///
  /// In en, this message translates to:
  /// **'Purchase canceled.'**
  String get premiumPurchaseCanceled;

  /// No description provided for @hideKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get hideKeyboard;

  /// No description provided for @selectResumeWithContentFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a saved resume with content first.'**
  String get selectResumeWithContentFirst;

  /// No description provided for @aiAtsIntro.
  ///
  /// In en, this message translates to:
  /// **'Select a resume and AI will create a ChatGPT/Claude-style ATS resume. Each time you tap Create again, AI further optimizes the same ATS draft. Job description is optional.'**
  String get aiAtsIntro;

  /// No description provided for @aiEngineUsingCloudApi.
  ///
  /// In en, this message translates to:
  /// **'Using your API key (cloud AI)'**
  String get aiEngineUsingCloudApi;

  /// No description provided for @aiEngineUsingAppleIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Using Apple Intelligence (on-device)'**
  String get aiEngineUsingAppleIntelligence;

  /// No description provided for @aiEngineUsingBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Using built-in AI'**
  String get aiEngineUsingBuiltIn;

  /// No description provided for @aiApiKeySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI API key'**
  String get aiApiKeySettingsTitle;

  /// No description provided for @aiApiKeySettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Add your own OpenAI or Gemini API key to generate stronger ATS resumes. The key stays on this device. If no key is saved, iPhone uses Apple Intelligence when available, otherwise built-in AI.'**
  String get aiApiKeySettingsIntro;

  /// No description provided for @aiApiKeyConfiguredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved: {provider}'**
  String aiApiKeyConfiguredSubtitle(String provider);

  /// No description provided for @aiApiKeyMissingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — use your own OpenAI or Gemini key'**
  String get aiApiKeyMissingSubtitle;

  /// No description provided for @aiProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiProviderLabel;

  /// No description provided for @aiApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get aiApiKeyLabel;

  /// No description provided for @aiApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your secret API key'**
  String get aiApiKeyHint;

  /// No description provided for @aiModelOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Model (optional)'**
  String get aiModelOptionalLabel;

  /// No description provided for @aiApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an API key first.'**
  String get aiApiKeyRequired;

  /// No description provided for @aiApiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved on this device.'**
  String get aiApiKeySaved;

  /// No description provided for @aiApiKeyRemoved.
  ///
  /// In en, this message translates to:
  /// **'API key removed.'**
  String get aiApiKeyRemoved;

  /// No description provided for @aiApiKeyTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'API key works.'**
  String get aiApiKeyTestSuccess;

  /// No description provided for @aiApiKeySavedMasked.
  ///
  /// In en, this message translates to:
  /// **'Saved key: {maskedKey}'**
  String aiApiKeySavedMasked(String maskedKey);

  /// No description provided for @saveAiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Save API key'**
  String get saveAiApiKey;

  /// No description provided for @testAiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Test API key'**
  String get testAiApiKey;

  /// No description provided for @removeAiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Remove API key'**
  String get removeAiApiKey;

  /// No description provided for @noResumeAvailable.
  ///
  /// In en, this message translates to:
  /// **'No resume available right now.'**
  String get noResumeAvailable;

  /// No description provided for @createResumeThenGenerateAts.
  ///
  /// In en, this message translates to:
  /// **'Create a resume first, then come back here to generate an ATS version.'**
  String get createResumeThenGenerateAts;

  /// No description provided for @selectResume.
  ///
  /// In en, this message translates to:
  /// **'Select resume'**
  String get selectResume;

  /// No description provided for @jobDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Job description (optional)'**
  String get jobDescriptionOptional;

  /// No description provided for @jobDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a job post to tailor the ATS resume, or leave blank.'**
  String get jobDescriptionHint;

  /// No description provided for @createAtsResume.
  ///
  /// In en, this message translates to:
  /// **'Create ATS resume'**
  String get createAtsResume;

  /// No description provided for @furtherOptimizeAtsPass.
  ///
  /// In en, this message translates to:
  /// **'Further optimize ATS (pass {pass})'**
  String furtherOptimizeAtsPass(int pass);

  /// No description provided for @appliedChanges.
  ///
  /// In en, this message translates to:
  /// **'Applied changes'**
  String get appliedChanges;

  /// No description provided for @showAtsResume.
  ///
  /// In en, this message translates to:
  /// **'Show ATS resume'**
  String get showAtsResume;

  /// No description provided for @saveOptimizedResume.
  ///
  /// In en, this message translates to:
  /// **'Save optimized resume'**
  String get saveOptimizedResume;

  /// No description provided for @saveOptimizedResumePrompt.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save this as a new copy or replace \"{sourceTitle}\"?'**
  String saveOptimizedResumePrompt(String sourceTitle);

  /// No description provided for @newCopy.
  ///
  /// In en, this message translates to:
  /// **'New copy'**
  String get newCopy;

  /// No description provided for @existingResume.
  ///
  /// In en, this message translates to:
  /// **'Existing resume'**
  String get existingResume;

  /// No description provided for @resumePreview.
  ///
  /// In en, this message translates to:
  /// **'Resume preview'**
  String get resumePreview;

  /// No description provided for @highlightedSummaryChange.
  ///
  /// In en, this message translates to:
  /// **'Highlighted summary change'**
  String get highlightedSummaryChange;

  /// No description provided for @highlightedSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Highlighted skills: {skills}'**
  String highlightedSkillsLabel(String skills);

  /// No description provided for @atsTitleSuffix.
  ///
  /// In en, this message translates to:
  /// **' (ATS)'**
  String get atsTitleSuffix;

  /// No description provided for @optimizedTitleSuffix.
  ///
  /// In en, this message translates to:
  /// **' (Optimized)'**
  String get optimizedTitleSuffix;

  /// No description provided for @professionalResumes.
  ///
  /// In en, this message translates to:
  /// **'Professional Resumes'**
  String get professionalResumes;

  /// No description provided for @atsResumes.
  ///
  /// In en, this message translates to:
  /// **'ATS Resumes'**
  String get atsResumes;

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use template'**
  String get useTemplate;

  /// No description provided for @templateCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get templateCorporate;

  /// No description provided for @templateCorporateCaption.
  ///
  /// In en, this message translates to:
  /// **'Bold top band with compact professional sections.'**
  String get templateCorporateCaption;

  /// No description provided for @templateProfileSidebar.
  ///
  /// In en, this message translates to:
  /// **'Profile Sidebar'**
  String get templateProfileSidebar;

  /// No description provided for @templateProfileSidebarCaption.
  ///
  /// In en, this message translates to:
  /// **'Profile-led layout with strong visual anchors.'**
  String get templateProfileSidebarCaption;

  /// No description provided for @templateClassicSidebar.
  ///
  /// In en, this message translates to:
  /// **'Classic Sidebar'**
  String get templateClassicSidebar;

  /// No description provided for @templateClassicSidebarCaption.
  ///
  /// In en, this message translates to:
  /// **'Soft left rail with photo-led identity and structured sections.'**
  String get templateClassicSidebarCaption;

  /// No description provided for @templateAccentStrip.
  ///
  /// In en, this message translates to:
  /// **'Accent Strip'**
  String get templateAccentStrip;

  /// No description provided for @templateAccentStripCaption.
  ///
  /// In en, this message translates to:
  /// **'Bold left stripe with an oversized nameplate and clean sections.'**
  String get templateAccentStripCaption;

  /// No description provided for @templateStructuredAts.
  ///
  /// In en, this message translates to:
  /// **'Structured ATS'**
  String get templateStructuredAts;

  /// No description provided for @templateStructuredAtsCaption.
  ///
  /// In en, this message translates to:
  /// **'Gray section bands and a centered header for parsers.'**
  String get templateStructuredAtsCaption;

  /// No description provided for @templateLatexClassicAts.
  ///
  /// In en, this message translates to:
  /// **'LaTeX Classic ATS'**
  String get templateLatexClassicAts;

  /// No description provided for @templateLatexClassicAtsCaption.
  ///
  /// In en, this message translates to:
  /// **'Academic ruled sections inspired by classic LaTeX resumes.'**
  String get templateLatexClassicAtsCaption;

  /// No description provided for @templateModernFlowAts.
  ///
  /// In en, this message translates to:
  /// **'Modern Flow ATS'**
  String get templateModernFlowAts;

  /// No description provided for @templateModernFlowAtsCaption.
  ///
  /// In en, this message translates to:
  /// **'Centered contact row with a logical section sequence.'**
  String get templateModernFlowAtsCaption;

  /// No description provided for @templateExecutiveAts.
  ///
  /// In en, this message translates to:
  /// **'Executive ATS'**
  String get templateExecutiveAts;

  /// No description provided for @templateExecutiveAtsCaption.
  ///
  /// In en, this message translates to:
  /// **'Uppercase headings and two-column keyword skills.'**
  String get templateExecutiveAtsCaption;

  /// No description provided for @templateCenterClassicAts.
  ///
  /// In en, this message translates to:
  /// **'Center Classic ATS'**
  String get templateCenterClassicAts;

  /// No description provided for @templateCenterClassicAtsCaption.
  ///
  /// In en, this message translates to:
  /// **'Centered name, pipe tagline, and ruled single-column sections.'**
  String get templateCenterClassicAtsCaption;

  /// No description provided for @templateProfessionalBlueAts.
  ///
  /// In en, this message translates to:
  /// **'Professional Blue ATS'**
  String get templateProfessionalBlueAts;

  /// No description provided for @templateProfessionalBlueAtsCaption.
  ///
  /// In en, this message translates to:
  /// **'Blue accent headings with right-aligned contact and skills grid.'**
  String get templateProfessionalBlueAtsCaption;

  /// No description provided for @templateExecutiveNote.
  ///
  /// In en, this message translates to:
  /// **'Executive Note'**
  String get templateExecutiveNote;

  /// No description provided for @templateExecutiveNoteCaption.
  ///
  /// In en, this message translates to:
  /// **'Clean professional cover letter with a strong header block.'**
  String get templateExecutiveNoteCaption;

  /// No description provided for @templateMinimalLetter.
  ///
  /// In en, this message translates to:
  /// **'Minimal Letter'**
  String get templateMinimalLetter;

  /// No description provided for @templateMinimalLetterCaption.
  ///
  /// In en, this message translates to:
  /// **'Centered header with airy spacing and left-aligned body.'**
  String get templateMinimalLetterCaption;

  /// No description provided for @templateMintLetter.
  ///
  /// In en, this message translates to:
  /// **'Mint Letter'**
  String get templateMintLetter;

  /// No description provided for @templateMintLetterCaption.
  ///
  /// In en, this message translates to:
  /// **'Oversized name, soft mint background, and a clean modern letter body.'**
  String get templateMintLetterCaption;

  /// No description provided for @templateClassicBusiness.
  ///
  /// In en, this message translates to:
  /// **'Classic Business'**
  String get templateClassicBusiness;

  /// No description provided for @templateClassicBusinessCaption.
  ///
  /// In en, this message translates to:
  /// **'Traditional business letter: date, recipient block, and left-aligned body.'**
  String get templateClassicBusinessCaption;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto sync'**
  String get autoSync;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @alreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Already downloaded'**
  String get alreadyDownloaded;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @syncToIcloud.
  ///
  /// In en, this message translates to:
  /// **'Sync to iCloud'**
  String get syncToIcloud;

  /// No description provided for @syncToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Sync to Google Drive'**
  String get syncToGoogleDrive;

  /// No description provided for @iCloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'iCloud is not available on this device right now. Make sure iCloud Drive is enabled and you are signed in with the correct Apple ID.'**
  String get iCloudUnavailable;

  /// No description provided for @noItemsInIcloud.
  ///
  /// In en, this message translates to:
  /// **'No resumes or cover letters are stored in iCloud yet.'**
  String get noItemsInIcloud;

  /// No description provided for @noItemsOnDrive.
  ///
  /// In en, this message translates to:
  /// **'No resumes or cover letters are stored on Drive yet.'**
  String get noItemsOnDrive;

  /// No description provided for @resumesInIcloud.
  ///
  /// In en, this message translates to:
  /// **'Resumes in iCloud'**
  String get resumesInIcloud;

  /// No description provided for @coverLettersInIcloud.
  ///
  /// In en, this message translates to:
  /// **'Cover letters in iCloud'**
  String get coverLettersInIcloud;

  /// No description provided for @resumesInGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Resumes in Google Drive'**
  String get resumesInGoogleDrive;

  /// No description provided for @coverLettersInGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Cover letters in Google Drive'**
  String get coverLettersInGoogleDrive;

  /// No description provided for @googleDriveBackupIntro.
  ///
  /// In en, this message translates to:
  /// **'Back up resumes and cover letters to a ResumeApp folder on your Google Drive. Only files created by this app are accessible.'**
  String get googleDriveBackupIntro;

  /// No description provided for @googleDrivePermissionHint.
  ///
  /// In en, this message translates to:
  /// **'On the Google page that opens next, under \"Select what ResumeApp can access\", check the box next to Google Drive (files used with this app), then tap Continue. Without that box, Drive backup cannot work.'**
  String get googleDrivePermissionHint;

  /// No description provided for @googleDriveLooksLikeThis.
  ///
  /// In en, this message translates to:
  /// **'It looks like this:'**
  String get googleDriveLooksLikeThis;

  /// No description provided for @googleDrivePermissionExampleSemantics.
  ///
  /// In en, this message translates to:
  /// **'Example Google screen: Select what ResumeApp can access, with the Google Drive row and checkbox.'**
  String get googleDrivePermissionExampleSemantics;

  /// No description provided for @noLocalItemsToSync.
  ///
  /// In en, this message translates to:
  /// **'No local resumes or cover letters available to sync.'**
  String get noLocalItemsToSync;

  /// No description provided for @everythingUpToDateIcloud.
  ///
  /// In en, this message translates to:
  /// **'Everything is already up to date in iCloud.'**
  String get everythingUpToDateIcloud;

  /// No description provided for @everythingUpToDateGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Everything is already up to date on Google Drive.'**
  String get everythingUpToDateGoogleDrive;

  /// No description provided for @couldNotLoadIcloudItems.
  ///
  /// In en, this message translates to:
  /// **'Could not load iCloud items: {error}'**
  String couldNotLoadIcloudItems(String error);

  /// No description provided for @couldNotSyncToIcloud.
  ///
  /// In en, this message translates to:
  /// **'Could not sync to iCloud: {error}'**
  String couldNotSyncToIcloud(String error);

  /// No description provided for @couldNotDeleteFromIcloud.
  ///
  /// In en, this message translates to:
  /// **'Could not delete from iCloud: {error}'**
  String couldNotDeleteFromIcloud(String error);

  /// No description provided for @couldNotDownloadWithError.
  ///
  /// In en, this message translates to:
  /// **'Could not download: {error}'**
  String couldNotDownloadWithError(String error);

  /// No description provided for @syncedSummaryToIcloud.
  ///
  /// In en, this message translates to:
  /// **'Synced {summary} to iCloud.'**
  String syncedSummaryToIcloud(String summary);

  /// No description provided for @syncedSummaryWithSkippedIcloud.
  ///
  /// In en, this message translates to:
  /// **'Synced {summary}. {skipped} left untouched.'**
  String syncedSummaryWithSkippedIcloud(String summary, String skipped);

  /// No description provided for @syncedSummaryToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Synced {summary} to Google Drive.'**
  String syncedSummaryToGoogleDrive(String summary);

  /// No description provided for @syncedSummaryWithSkippedDrive.
  ///
  /// In en, this message translates to:
  /// **'Synced {summary}. {skipped} left untouched.'**
  String syncedSummaryWithSkippedDrive(String summary, String skipped);

  /// No description provided for @resumeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 resume} other{{count} resumes}}'**
  String resumeCountLabel(int count);

  /// No description provided for @coverLetterCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cover letter} other{{count} cover letters}}'**
  String coverLetterCountLabel(int count);

  /// No description provided for @newerIcloudItemsUntouched.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 newer iCloud item} other{{count} newer iCloud items}}'**
  String newerIcloudItemsUntouched(int count);

  /// No description provided for @newerDriveItemsUntouched.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 newer Drive item} other{{count} newer Drive items}}'**
  String newerDriveItemsUntouched(int count);

  /// No description provided for @listJoinAnd.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String listJoinAnd(String first, String second);

  /// No description provided for @deleteFromIcloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from iCloud?'**
  String get deleteFromIcloudTitle;

  /// No description provided for @deleteFromIcloudMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from iCloud? This will not delete the copy on this device.'**
  String deleteFromIcloudMessage(String title);

  /// No description provided for @deleteFromIcloud.
  ///
  /// In en, this message translates to:
  /// **'Delete from iCloud'**
  String get deleteFromIcloud;

  /// No description provided for @deleteDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Delete {type}'**
  String deleteDocumentType(String type);

  /// No description provided for @documentTypeResume.
  ///
  /// In en, this message translates to:
  /// **'resume'**
  String get documentTypeResume;

  /// No description provided for @documentTypeCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'cover letter'**
  String get documentTypeCoverLetter;

  /// No description provided for @removedFromIcloud.
  ///
  /// In en, this message translates to:
  /// **'Removed {title} from iCloud.'**
  String removedFromIcloud(String title);

  /// No description provided for @downloadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {title}.'**
  String downloadedTitle(String title);

  /// No description provided for @googleSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available on this device.'**
  String get googleSignInUnavailable;

  /// No description provided for @couldNotSignInGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in to Google Drive right now. Try again.'**
  String get couldNotSignInGoogleDrive;

  /// No description provided for @couldNotLoadGoogleDriveItems.
  ///
  /// In en, this message translates to:
  /// **'Could not load your Google Drive items right now. Try again.'**
  String get couldNotLoadGoogleDriveItems;

  /// No description provided for @couldNotSyncGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Could not sync to Google Drive right now. Try again.'**
  String get couldNotSyncGoogleDrive;

  /// No description provided for @couldNotDownloadFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Could not download this item from Google Drive. Try again.'**
  String get couldNotDownloadFromGoogleDrive;

  /// No description provided for @couldNotRemoveFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this item from Google Drive. Try again.'**
  String get couldNotRemoveFromGoogleDrive;

  /// No description provided for @removeFromGoogleDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Google Drive?'**
  String get removeFromGoogleDriveTitle;

  /// No description provided for @removeFromGoogleDriveMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from Google Drive? This will not delete the copy on this device.'**
  String removeFromGoogleDriveMessage(String title);

  /// No description provided for @removeFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Remove from Google Drive'**
  String get removeFromGoogleDrive;

  /// No description provided for @removeDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Remove {type}'**
  String removeDocumentType(String type);

  /// No description provided for @removedFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Removed {title} from Google Drive.'**
  String removedFromGoogleDrive(String title);

  /// No description provided for @googleSignInNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not configured for this build. Add your debug and release SHA-1 fingerprints in Firebase (see android/GOOGLE_SIGN_IN_SETUP.md), re-download google-services.json, and rebuild.'**
  String get googleSignInNotConfigured;

  /// No description provided for @couldNotOpenGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Could not open the Google sign-in screen. Try again.'**
  String get couldNotOpenGoogleSignIn;

  /// No description provided for @googleSignInInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was interrupted. Try again.'**
  String get googleSignInInterrupted;

  /// No description provided for @unableToLoadPage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load page'**
  String get unableToLoadPage;

  /// No description provided for @couldNotLoadThisPage.
  ///
  /// In en, this message translates to:
  /// **'Could not load this page.'**
  String get couldNotLoadThisPage;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @shareAppSubject.
  ///
  /// In en, this message translates to:
  /// **'ResumeApp'**
  String get shareAppSubject;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out ResumeApp to create, optimize, and share professional resumes on iPhone. Get it on the App Store: {url}'**
  String shareAppMessage(String url);

  /// No description provided for @feedbackEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'ResumeApp Feedback'**
  String get feedbackEmailSubject;

  /// No description provided for @noMailAppFound.
  ///
  /// In en, this message translates to:
  /// **'No mail app found. Please configure a mail app.'**
  String get noMailAppFound;

  /// No description provided for @couldNotOpenMailApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open mail app. Please try again.'**
  String get couldNotOpenMailApp;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link right now.'**
  String get couldNotOpenLink;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @sectionPersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get sectionPersonalInformation;

  /// No description provided for @sectionWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'Work Experience'**
  String get sectionWorkExperience;

  /// No description provided for @sectionEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get sectionEducation;

  /// No description provided for @sectionSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get sectionSkills;

  /// No description provided for @sectionProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get sectionProjects;

  /// No description provided for @personalInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformationTitle;

  /// No description provided for @workExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Work experience'**
  String get workExperienceTitle;

  /// No description provided for @categoryNumber.
  ///
  /// In en, this message translates to:
  /// **'Category {number}'**
  String categoryNumber(int number);

  /// No description provided for @pdfSavedTo.
  ///
  /// In en, this message translates to:
  /// **'PDF saved to {path}'**
  String pdfSavedTo(String path);

  /// No description provided for @unableToGenerateSummary.
  ///
  /// In en, this message translates to:
  /// **'Unable to generate a professional summary right now.'**
  String get unableToGenerateSummary;

  /// No description provided for @summaryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Summary updated'**
  String get summaryUpdated;

  /// No description provided for @summaryAdded.
  ///
  /// In en, this message translates to:
  /// **'Summary added'**
  String get summaryAdded;

  /// No description provided for @skillAlreadyInList.
  ///
  /// In en, this message translates to:
  /// **'This skill is already in your list.'**
  String get skillAlreadyInList;

  /// No description provided for @addBulletPoint.
  ///
  /// In en, this message translates to:
  /// **'Add bullet point'**
  String get addBulletPoint;

  /// No description provided for @appearsFirstOnYourResume.
  ///
  /// In en, this message translates to:
  /// **'Appears first on your resume'**
  String get appearsFirstOnYourResume;

  /// No description provided for @appearsOnYourResumeAt.
  ///
  /// In en, this message translates to:
  /// **'Appears at position {position} on your resume'**
  String appearsOnYourResumeAt(int position);

  /// No description provided for @hideFromResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide from resume?'**
  String get hideFromResumeTitle;

  /// No description provided for @hideFromResumeMessage.
  ///
  /// In en, this message translates to:
  /// **'{sectionName} will not be shown on your resume or in exported PDFs. You can show it again anytime using the button next to the section title.'**
  String hideFromResumeMessage(String sectionName);

  /// No description provided for @hideFromResume.
  ///
  /// In en, this message translates to:
  /// **'Hide from resume'**
  String get hideFromResume;

  /// No description provided for @showOnResume.
  ///
  /// In en, this message translates to:
  /// **'Show on resume'**
  String get showOnResume;

  /// No description provided for @chooseMonthAndYear.
  ///
  /// In en, this message translates to:
  /// **'Choose month and year'**
  String get chooseMonthAndYear;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @selectEndMonthAndYear.
  ///
  /// In en, this message translates to:
  /// **'Select end month and year'**
  String get selectEndMonthAndYear;

  /// No description provided for @selectStartMonthAndYear.
  ///
  /// In en, this message translates to:
  /// **'Select start month and year'**
  String get selectStartMonthAndYear;

  /// No description provided for @selectEndYear.
  ///
  /// In en, this message translates to:
  /// **'Select end year'**
  String get selectEndYear;

  /// No description provided for @selectStartYear.
  ///
  /// In en, this message translates to:
  /// **'Select start year'**
  String get selectStartYear;

  /// No description provided for @newSection.
  ///
  /// In en, this message translates to:
  /// **'New section'**
  String get newSection;

  /// No description provided for @newSectionTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Certifications, Languages, Awards…'**
  String get newSectionTitleHint;

  /// No description provided for @sectionTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get sectionTypeNormal;

  /// No description provided for @sectionTypeNormalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Summary or bullet points'**
  String get sectionTypeNormalSubtitle;

  /// No description provided for @sectionTypeAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get sectionTypeAdvance;

  /// No description provided for @sectionTypeAdvanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Project-style entries with title and bullets'**
  String get sectionTypeAdvanceSubtitle;

  /// No description provided for @removeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove section?'**
  String get removeSectionTitle;

  /// No description provided for @removeSectionMessage.
  ///
  /// In en, this message translates to:
  /// **'This section will be removed from your resume. You can add a new custom section with Add anytime.'**
  String get removeSectionMessage;

  /// No description provided for @unableToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to pick image right now.'**
  String get unableToPickImage;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @previousField.
  ///
  /// In en, this message translates to:
  /// **'Previous field'**
  String get previousField;

  /// No description provided for @nextField.
  ///
  /// In en, this message translates to:
  /// **'Next field'**
  String get nextField;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @targetJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Target job title'**
  String get targetJobTitle;

  /// No description provided for @githubLink.
  ///
  /// In en, this message translates to:
  /// **'GitHub link'**
  String get githubLink;

  /// No description provided for @linkedinLink.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn link'**
  String get linkedinLink;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @websiteOrPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Website or portfolio'**
  String get websiteOrPortfolio;

  /// No description provided for @professionalSummary.
  ///
  /// In en, this message translates to:
  /// **'Professional summary'**
  String get professionalSummary;

  /// No description provided for @personalInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with identity, contact details, target role, and a short positioning summary.'**
  String get personalInformationSubtitle;

  /// No description provided for @suggestSummary.
  ///
  /// In en, this message translates to:
  /// **'Suggest summary'**
  String get suggestSummary;

  /// No description provided for @resumeOrder.
  ///
  /// In en, this message translates to:
  /// **'Resume order'**
  String get resumeOrder;

  /// No description provided for @resumeOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Entries stay in this order. Use arrows to move your strongest role to top.'**
  String get resumeOrderBody;

  /// No description provided for @experienceNumber.
  ///
  /// In en, this message translates to:
  /// **'Experience {number}'**
  String experienceNumber(int number);

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @deleteExperience.
  ///
  /// In en, this message translates to:
  /// **'Delete experience'**
  String get deleteExperience;

  /// No description provided for @deleteWorkExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete work experience?'**
  String get deleteWorkExperienceTitle;

  /// No description provided for @deleteWorkExperienceMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove this job and all of its bullet points. This cannot be undone.'**
  String get deleteWorkExperienceMessage;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @monthYearHint.
  ///
  /// In en, this message translates to:
  /// **'Month/year'**
  String get monthYearHint;

  /// No description provided for @monthYearOrPresentHint.
  ///
  /// In en, this message translates to:
  /// **'Month/year or Present'**
  String get monthYearOrPresentHint;

  /// No description provided for @bulletNumber.
  ///
  /// In en, this message translates to:
  /// **'Bullet {number}'**
  String bulletNumber(int number);

  /// No description provided for @removeBulletTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove bullet?'**
  String get removeBulletTitle;

  /// No description provided for @removeBulletFromJob.
  ///
  /// In en, this message translates to:
  /// **'This bullet will be removed from this job.'**
  String get removeBulletFromJob;

  /// No description provided for @addExperience.
  ///
  /// In en, this message translates to:
  /// **'Add experience'**
  String get addExperience;

  /// No description provided for @educationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include your degree, institution, and study timeline.'**
  String get educationSubtitle;

  /// No description provided for @educationNumber.
  ///
  /// In en, this message translates to:
  /// **'Education {number}'**
  String educationNumber(int number);

  /// No description provided for @moveEducationUp.
  ///
  /// In en, this message translates to:
  /// **'Move education up'**
  String get moveEducationUp;

  /// No description provided for @moveEducationDown.
  ///
  /// In en, this message translates to:
  /// **'Move education down'**
  String get moveEducationDown;

  /// No description provided for @deleteEducationEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete education entry'**
  String get deleteEducationEntry;

  /// No description provided for @deleteEducationEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete education entry?'**
  String get deleteEducationEntryTitle;

  /// No description provided for @deleteEducationEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove this school and degree from your resume. This cannot be undone.'**
  String get deleteEducationEntryMessage;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// No description provided for @degree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get degree;

  /// No description provided for @startYear.
  ///
  /// In en, this message translates to:
  /// **'Start year'**
  String get startYear;

  /// No description provided for @endYear.
  ///
  /// In en, this message translates to:
  /// **'End year'**
  String get endYear;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get selectYear;

  /// No description provided for @marksScore.
  ///
  /// In en, this message translates to:
  /// **'Marks / score'**
  String get marksScore;

  /// No description provided for @marksScoreHint.
  ///
  /// In en, this message translates to:
  /// **'8.6 CGPA, 92, or 780/800'**
  String get marksScoreHint;

  /// No description provided for @addEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get addEducation;

  /// No description provided for @showScoreAsPercent.
  ///
  /// In en, this message translates to:
  /// **'Show as percent'**
  String get showScoreAsPercent;

  /// No description provided for @skillsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add job-specific tools and keywords. Choose a simple list, or categorise skills under headings (for example Languages, Tools).'**
  String get skillsSubtitle;

  /// No description provided for @skillsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} skills'**
  String skillsCount(int count);

  /// No description provided for @simpleList.
  ///
  /// In en, this message translates to:
  /// **'Simple list'**
  String get simpleList;

  /// No description provided for @categorised.
  ///
  /// In en, this message translates to:
  /// **'Categorised'**
  String get categorised;

  /// No description provided for @addASkill.
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get addASkill;

  /// No description provided for @addSkillHelper.
  ///
  /// In en, this message translates to:
  /// **'Type to see suggestions or add your own skill'**
  String get addSkillHelper;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Programming Languages, Tools, Frameworks, etc.'**
  String get categoryHint;

  /// No description provided for @moveCategoryUp.
  ///
  /// In en, this message translates to:
  /// **'Move category up'**
  String get moveCategoryUp;

  /// No description provided for @moveCategoryDown.
  ///
  /// In en, this message translates to:
  /// **'Move category down'**
  String get moveCategoryDown;

  /// No description provided for @removeCategory.
  ///
  /// In en, this message translates to:
  /// **'Remove category'**
  String get removeCategory;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove this category and all of its skills. This cannot be undone.'**
  String get deleteCategoryMessage;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @projectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showcase standout side projects, product launches, or portfolio work with clear outcomes.'**
  String get projectsSubtitle;

  /// No description provided for @projectNumber.
  ///
  /// In en, this message translates to:
  /// **'Project {number}'**
  String projectNumber(int number);

  /// No description provided for @moveProjectUp.
  ///
  /// In en, this message translates to:
  /// **'Move project up'**
  String get moveProjectUp;

  /// No description provided for @moveProjectDown.
  ///
  /// In en, this message translates to:
  /// **'Move project down'**
  String get moveProjectDown;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// No description provided for @deleteProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get deleteProjectTitle;

  /// No description provided for @deleteProjectMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove this project and all of its bullet points. This cannot be undone.'**
  String get deleteProjectMessage;

  /// No description provided for @projectTitle.
  ///
  /// In en, this message translates to:
  /// **'Project title'**
  String get projectTitle;

  /// No description provided for @enterBulletPoint.
  ///
  /// In en, this message translates to:
  /// **'Enter a bullet point'**
  String get enterBulletPoint;

  /// No description provided for @removeBulletFromProject.
  ///
  /// In en, this message translates to:
  /// **'This bullet will be removed from this project.'**
  String get removeBulletFromProject;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get addProject;

  /// No description provided for @customSectionProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add entries with a title and bullet points, like the Projects section.'**
  String get customSectionProjectsSubtitle;

  /// No description provided for @removeSection.
  ///
  /// In en, this message translates to:
  /// **'Remove section'**
  String get removeSection;

  /// No description provided for @bulletPoints.
  ///
  /// In en, this message translates to:
  /// **'Bullet points'**
  String get bulletPoints;

  /// No description provided for @customSectionSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Write the section as a short paragraph for your resume.'**
  String get customSectionSummaryHint;

  /// No description provided for @entryNumber.
  ///
  /// In en, this message translates to:
  /// **'Entry {number}'**
  String entryNumber(int number);

  /// No description provided for @moveEntryUp.
  ///
  /// In en, this message translates to:
  /// **'Move entry up'**
  String get moveEntryUp;

  /// No description provided for @moveEntryDown.
  ///
  /// In en, this message translates to:
  /// **'Move entry down'**
  String get moveEntryDown;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntry;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove this entry and all of its bullet points. This cannot be undone.'**
  String get deleteEntryMessage;

  /// No description provided for @removeBulletFromEntry.
  ///
  /// In en, this message translates to:
  /// **'This bullet will be removed from this entry.'**
  String get removeBulletFromEntry;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntry;

  /// No description provided for @livePreview.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get livePreview;

  /// No description provided for @exportActions.
  ///
  /// In en, this message translates to:
  /// **'Export actions'**
  String get exportActions;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @shareResume.
  ///
  /// In en, this message translates to:
  /// **'Share resume'**
  String get shareResume;

  /// No description provided for @resumeScore.
  ///
  /// In en, this message translates to:
  /// **'Resume score'**
  String get resumeScore;

  /// No description provided for @atsCompatibilitySummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ATS compatibility {percent}% with 1 missing skill gap.} other{ATS compatibility {percent}% with {count} missing skill gaps.}}'**
  String atsCompatibilitySummary(int percent, int count);

  /// No description provided for @unableToOpenShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Unable to open share sheet right now.'**
  String get unableToOpenShareSheet;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose template'**
  String get chooseTemplate;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @colorAndFont.
  ///
  /// In en, this message translates to:
  /// **'Color & Font'**
  String get colorAndFont;

  /// No description provided for @sharedFromResumeAi.
  ///
  /// In en, this message translates to:
  /// **'Shared from ResumeAI'**
  String get sharedFromResumeAi;

  /// No description provided for @unableToLoadPdfPreview.
  ///
  /// In en, this message translates to:
  /// **'Unable to load PDF preview right now.'**
  String get unableToLoadPdfPreview;

  /// No description provided for @shareFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get shareFormatPdf;

  /// No description provided for @shareFormatDocx.
  ///
  /// In en, this message translates to:
  /// **'DOCX'**
  String get shareFormatDocx;

  /// No description provided for @coverLetterHeading.
  ///
  /// In en, this message translates to:
  /// **'Cover letter'**
  String get coverLetterHeading;

  /// No description provided for @coverLetterEditorIntro.
  ///
  /// In en, this message translates to:
  /// **'This page creates a cover letter draft from the details below. Add the company name, job position name, one or more skills to highlight, and a language you want to mention, then tap Create cover letter to open the full draft on the next screen.'**
  String get coverLetterEditorIntro;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyName;

  /// No description provided for @jobPositionName.
  ///
  /// In en, this message translates to:
  /// **'Job position name'**
  String get jobPositionName;

  /// No description provided for @skillToHighlight.
  ///
  /// In en, this message translates to:
  /// **'Skill to highlight'**
  String get skillToHighlight;

  /// No description provided for @creatingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creatingEllipsis;

  /// No description provided for @createCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'Create cover letter'**
  String get createCoverLetter;

  /// No description provided for @coverLetterContentHeading.
  ///
  /// In en, this message translates to:
  /// **'Cover letter content'**
  String get coverLetterContentHeading;

  /// No description provided for @coverLetterContentIntro.
  ///
  /// In en, this message translates to:
  /// **'Your cover letter draft is ready. Review the full content below, edit anything you want, and your changes will be saved automatically.'**
  String get coverLetterContentIntro;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @coverLetterContentHint.
  ///
  /// In en, this message translates to:
  /// **'Your generated cover letter will appear here.'**
  String get coverLetterContentHint;

  /// No description provided for @clLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English (English)'**
  String get clLangEnglish;

  /// No description provided for @clLangArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic (العربية)'**
  String get clLangArabic;

  /// No description provided for @clLangBengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali (বাংলা)'**
  String get clLangBengali;

  /// No description provided for @clLangChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese, Mandarin (中文)'**
  String get clLangChinese;

  /// No description provided for @clLangDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch (Nederlands)'**
  String get clLangDutch;

  /// No description provided for @clLangFrench.
  ///
  /// In en, this message translates to:
  /// **'French (Français)'**
  String get clLangFrench;

  /// No description provided for @clLangGerman.
  ///
  /// In en, this message translates to:
  /// **'German (Deutsch)'**
  String get clLangGerman;

  /// No description provided for @clLangHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi (हिन्दी)'**
  String get clLangHindi;

  /// No description provided for @clLangItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian (Italiano)'**
  String get clLangItalian;

  /// No description provided for @clLangJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese (日本語)'**
  String get clLangJapanese;

  /// No description provided for @clLangKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean (한국어)'**
  String get clLangKorean;

  /// No description provided for @clLangPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese (Português)'**
  String get clLangPortuguese;

  /// No description provided for @clLangRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian (Русский)'**
  String get clLangRussian;

  /// No description provided for @clLangSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish (Español)'**
  String get clLangSpanish;

  /// No description provided for @clLangTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish (Türkçe)'**
  String get clLangTurkish;

  /// No description provided for @clLangUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu (اردو)'**
  String get clLangUrdu;

  /// No description provided for @clLangVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese (Tiếng Việt)'**
  String get clLangVietnamese;

  /// No description provided for @showPercentOnResume.
  ///
  /// In en, this message translates to:
  /// **'Tap to show % on resume'**
  String get showPercentOnResume;

  /// No description provided for @hidePercentOnResume.
  ///
  /// In en, this message translates to:
  /// **'Showing % on resume — tap to hide'**
  String get hidePercentOnResume;

  /// No description provided for @removeBullet.
  ///
  /// In en, this message translates to:
  /// **'Remove bullet'**
  String get removeBullet;

  /// No description provided for @alreadySubscribedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already subscribed'**
  String get alreadySubscribedTitle;

  /// No description provided for @youreOnPlan.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the {planLabel}'**
  String youreOnPlan(String planLabel);

  /// No description provided for @premiumPlanNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'That plan is not available yet. Pull to refresh.'**
  String get premiumPlanNotAvailableYet;

  /// No description provided for @premiumCouldNotStartPurchase.
  ///
  /// In en, this message translates to:
  /// **'Could not start the purchase. Please try again.'**
  String get premiumCouldNotStartPurchase;

  /// No description provided for @premiumSubscriptionRestored.
  ///
  /// In en, this message translates to:
  /// **'Your Premium subscription has been restored.'**
  String get premiumSubscriptionRestored;

  /// No description provided for @premiumRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Premium restored successfully.'**
  String get premiumRestoredSuccessfully;

  /// No description provided for @welcomeToResumeAppPro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ResumeApp Pro!'**
  String get welcomeToResumeAppPro;

  /// No description provided for @jobsCreateResumeFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a resume first to see job matches.'**
  String get jobsCreateResumeFirst;

  /// No description provided for @jobsShowingLatestHint.
  ///
  /// In en, this message translates to:
  /// **'Showing latest jobs from last 7 days based on the selected resume role and location.'**
  String get jobsShowingLatestHint;

  /// No description provided for @jobsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No jobs found for this resume in last 7 days.'**
  String get jobsNoneFound;

  /// No description provided for @jobsLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more jobs...'**
  String get jobsLoadingMore;

  /// No description provided for @jobsScrollForMore.
  ///
  /// In en, this message translates to:
  /// **'Scroll down to load more'**
  String get jobsScrollForMore;

  /// No description provided for @jobsLiveUnavailableBackup.
  ///
  /// In en, this message translates to:
  /// **'Live jobs unavailable, showing backup results.'**
  String get jobsLiveUnavailableBackup;

  /// No description provided for @couldNotOpenJobLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open job link right now.'**
  String get couldNotOpenJobLink;

  /// No description provided for @jobsPostedJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get jobsPostedJustNow;

  /// No description provided for @jobsPostedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String jobsPostedHoursAgo(int hours);

  /// No description provided for @jobsPostedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String jobsPostedDaysAgo(int days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'id', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'id':
      return AppLocalizationsId();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
