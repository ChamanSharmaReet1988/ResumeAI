// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ResumeAI';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTemplates => 'Templates';

  @override
  String get tabAiResume => 'AI Resume';

  @override
  String get tabSettings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get appLanguage => 'App language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortugueseBrazil => 'Português (Brasil)';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get iCloudBackup => 'iCloud Backup';

  @override
  String get googleDriveBackup => 'Google Drive Backup';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get youAreProUser => 'You are a Pro user';

  @override
  String get feedback => 'Feedback';

  @override
  String get rateApp => 'Rate App';

  @override
  String get ratePromptTitle => 'Enjoying ResumeAI?';

  @override
  String get ratePromptBody =>
      'If this app is helping you, a quick rating would mean a lot.';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get shareApp => 'Share App';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get versionLabel => 'Version';

  @override
  String versionWithBuild(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get ok => 'OK';

  @override
  String get languageAffectsAppOnly =>
      'Changes app menus and labels only. Your resume content stays as written.';

  @override
  String get homeSegmentResume => 'Resume';

  @override
  String get homeSegmentCoverLetter => 'Cover Letter';

  @override
  String get noResumesYet => 'No resumes yet';

  @override
  String get noResumesYetBody =>
      'Tap Create new to start from scratch, or Upload resume to fill in your details from an existing file.';

  @override
  String get noCoverLettersYet => 'No cover letters yet';

  @override
  String get noCoverLettersYetBody =>
      'Tap Create new to write your first cover letter.';

  @override
  String get homeCreateNew => 'Create new';

  @override
  String get homeUploadResume => 'Upload resume';

  @override
  String get uploadResumeFailed =>
      'Could not upload that resume. Please try again.';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionDelete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get deleteResumeTitle => 'Delete resume?';

  @override
  String deleteResumeMessage(String title) {
    return 'Delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get deleteCoverLetterTitle => 'Delete cover letter?';

  @override
  String deleteCoverLetterMessage(String title) {
    return 'Delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get renameResumeTitle => 'Rename resume';

  @override
  String get duplicateResumeTitle => 'Duplicate resume';

  @override
  String get resumeRenamed => 'Resume renamed.';

  @override
  String get resumeDuplicated => 'Resume duplicated.';

  @override
  String get resumeTitle => 'Resume title';

  @override
  String get enterResumeTitle => 'Enter resume title';

  @override
  String get coverLetterTitle => 'Cover letter title';

  @override
  String updatedDate(String date) {
    return 'Updated $date';
  }

  @override
  String titleWithCopySuffix(String title) {
    return '$title (Copy)';
  }

  @override
  String get untitledResume => 'Untitled Resume';

  @override
  String get untitledCoverLetter => 'Untitled Cover Letter';

  @override
  String get save => 'Save';

  @override
  String get continueAction => 'Continue';

  @override
  String get restore => 'Restore';

  @override
  String get resumeAppPro => 'ResumeApp Pro';

  @override
  String get chooseAPlan => 'Choose a plan';

  @override
  String get unlockProOnce => 'One-time unlock';

  @override
  String get premiumLegalAgreement =>
      'By continuing, you agree to our Terms of Use and Privacy Policy.';

  @override
  String get subscriptionFound => 'Subscription found';

  @override
  String get processingEllipsis => 'Processing…';

  @override
  String get checkingYourSubscription => 'Checking your subscription…';

  @override
  String get completingYourPurchase => 'Completing your purchase…';

  @override
  String get restoringYourSubscription => 'Restoring your subscription…';

  @override
  String get pleaseWaitDoNotClose => 'Please wait. Do not close the app.';

  @override
  String get premiumWelcomeCongratulations => 'Congratulations!';

  @override
  String premiumWelcomeBody(String planLabel, String backup) {
    return 'ResumeApp Pro is active on your $planLabel. Ads are removed, and AI Resume plus $backup are unlocked.';
  }

  @override
  String get premiumBenefitRemoveAds => 'Remove all ads';

  @override
  String get premiumBenefitUnlockLayouts =>
      'Unlock AI Resume — create and refine ATS resumes with AI';

  @override
  String get premiumBenefitBackupIcloud =>
      'Back up and sync resumes with iCloud';

  @override
  String get premiumBenefitBackupGoogleDrive =>
      'Back up and sync resumes with Google Drive';

  @override
  String get premiumUpcomingUpdateBadge => 'Coming in the next update';

  @override
  String get premiumUpcomingUpdateMessage =>
      'New resume layouts and modern templates, included with Pro.';

  @override
  String get planLifetime => 'Lifetime';

  @override
  String get planSubtitleLifetime => 'One-time purchase · \$1.99';

  @override
  String get planPro => 'Pro';

  @override
  String planLabelNamed(String title) {
    return '$title plan';
  }

  @override
  String get priceUnavailable => '—';

  @override
  String get storeAccountGoogle => 'Google account';

  @override
  String get storeAccountApple => 'Apple ID';

  @override
  String get alreadySubscribedDebugOverride =>
      'Developer Pro override is on. All Pro features are unlocked for testing on this device.';

  @override
  String alreadySubscribedLifetime(String backup) {
    return 'You have ResumeApp Pro (Lifetime). Ads are removed, and AI Resume plus $backup are unlocked.';
  }

  @override
  String get alreadySubscribedGeneric =>
      'You have an active ResumeApp Pro subscription. All premium features are included in your plan.';

  @override
  String restoreInsteadLifetime(String account) {
    return 'ResumeApp Pro (Lifetime) was found for this $account. Use Restore to activate it on this device instead of buying again.';
  }

  @override
  String restoreInsteadGeneric(String account) {
    return 'An active ResumeApp Pro subscription was found for this $account. Use Restore to activate it on this device instead of buying again.';
  }

  @override
  String get premiumPurchaseFailed =>
      'We could not complete your purchase. Please try again.';

  @override
  String get premiumRestoreFailed =>
      'We could not restore your subscription. Please try again.';

  @override
  String get noSubscriptionToRestoreGoogle =>
      'No active subscription was found for this Google account.';

  @override
  String get noSubscriptionToRestoreApple =>
      'No active subscription was found for this Apple ID.';

  @override
  String get premiumStoreUnavailable =>
      'Purchases are not available on this device right now.';

  @override
  String get premiumConnectFailedGoogle =>
      'We could not connect to Google Play. Please try again later.';

  @override
  String get premiumConnectFailedApple =>
      'We could not connect to the App Store. Please try again later.';

  @override
  String get premiumVerifyFailed =>
      'We could not verify your subscription. Please try again.';

  @override
  String get premiumProductsUnavailable =>
      'Subscription plans are not available right now. Please try again later.';

  @override
  String get premiumPurchaseCanceled => 'Purchase canceled.';

  @override
  String get hideKeyboard => 'Hide keyboard';

  @override
  String get selectResumeWithContentFirst =>
      'Select a saved resume with content first.';

  @override
  String get aiAtsIntro =>
      'Select a resume and AI will create an ATS-optimized version. Add your API key in Settings for stronger results, or use built-in AI. Job description is optional. Tap Create again to further refine.';

  @override
  String get aiEngineUsingCloudApi => 'Using your API key (cloud AI)';

  @override
  String get aiEngineUsingAppleIntelligence =>
      'Using Apple Intelligence (on-device)';

  @override
  String get aiEngineUsingBuiltIn => 'Using built-in AI';

  @override
  String get aiApiKeySettingsTitle => 'AI API key';

  @override
  String get aiApiKeySettingsIntro =>
      'Add your own OpenAI or Gemini API key to generate stronger ATS resumes. The key stays on this device. If no key is saved, iPhone uses Apple Intelligence when available, otherwise built-in AI.';

  @override
  String aiApiKeyConfiguredSubtitle(String provider) {
    return 'Saved: $provider';
  }

  @override
  String get aiApiKeyMissingSubtitle =>
      'Optional — use your own OpenAI or Gemini key';

  @override
  String get aiProviderLabel => 'Provider';

  @override
  String get aiApiKeyLabel => 'API key';

  @override
  String get aiApiKeyHint => 'Paste your secret API key';

  @override
  String get aiModelOptionalLabel => 'Model (optional)';

  @override
  String get aiApiKeyRequired => 'Enter an API key first.';

  @override
  String get aiApiKeySaved => 'API key saved on this device.';

  @override
  String get aiApiKeyRemoved => 'API key removed.';

  @override
  String get aiApiKeyTestSuccess => 'API key works.';

  @override
  String aiApiKeySavedMasked(String maskedKey) {
    return 'Saved key: $maskedKey';
  }

  @override
  String get saveAiApiKey => 'Save API key';

  @override
  String get testAiApiKey => 'Test API key';

  @override
  String get removeAiApiKey => 'Remove API key';

  @override
  String get noResumeAvailable => 'No resume available right now.';

  @override
  String get createResumeThenGenerateAts =>
      'Create a resume first, then come back here to generate an ATS version.';

  @override
  String get selectResume => 'Select resume';

  @override
  String get jobDescriptionOptional => 'Job description (optional)';

  @override
  String get jobDescriptionHint =>
      'Paste a job post to tailor the ATS resume, or leave blank.';

  @override
  String get createAtsResume => 'Create ATS resume';

  @override
  String furtherOptimizeAtsPass(int pass) {
    return 'Further optimize ATS (pass $pass)';
  }

  @override
  String get appliedChanges => 'Applied changes';

  @override
  String get showAtsResume => 'Show ATS resume';

  @override
  String get saveOptimizedResume => 'Save optimized resume';

  @override
  String saveOptimizedResumePrompt(String sourceTitle) {
    return 'Do you want to save this as a new copy or replace \"$sourceTitle\"?';
  }

  @override
  String get newCopy => 'New copy';

  @override
  String get existingResume => 'Existing resume';

  @override
  String get resumePreview => 'Resume preview';

  @override
  String get highlightedSummaryChange => 'Highlighted summary change';

  @override
  String highlightedSkillsLabel(String skills) {
    return 'Highlighted skills: $skills';
  }

  @override
  String get atsTitleSuffix => ' (ATS)';

  @override
  String get optimizedTitleSuffix => ' (Optimized)';

  @override
  String get allResumes => 'All';

  @override
  String get professionalResumes => 'Professional Resumes';

  @override
  String get atsResumes => 'ATS Resumes';

  @override
  String get useTemplate => 'Use template';

  @override
  String get templateCorporate => 'Corporate';

  @override
  String get templateCorporateCaption =>
      'Bold top band with compact professional sections.';

  @override
  String get templateProfileSidebar => 'Profile Sidebar';

  @override
  String get templateProfileSidebarCaption =>
      'Profile-led layout with strong visual anchors.';

  @override
  String get templateClassicSidebar => 'Classic Sidebar';

  @override
  String get templateClassicSidebarCaption =>
      'Soft left rail with photo-led identity and structured sections.';

  @override
  String get templateAccentStrip => 'Accent Strip';

  @override
  String get templateAccentStripCaption =>
      'Bold left stripe with an oversized nameplate and clean sections.';

  @override
  String get templateHeaderSidebar => 'Header Sidebar';

  @override
  String get templateHeaderSidebarCaption =>
      'Photo-led nameplate with a navy details rail and skill bars.';

  @override
  String get templateSlateSidebar => 'Slate Sidebar';

  @override
  String get templateSlateSidebarCaption =>
      'Dark photo sidebar with contact and expertise, and dated sections.';

  @override
  String get templateTimelineProfile => 'Timeline Profile';

  @override
  String get templateTimelineProfileCaption =>
      'Navy photo header with a contact sidebar and timeline sections.';

  @override
  String get templateSoftHeader => 'Soft Header';

  @override
  String get templateSoftHeaderCaption =>
      'Tinted header band with a centred name and a split two-column body.';

  @override
  String get templateBlueDiagonal => 'Blue Diagonal';

  @override
  String get templateBlueDiagonalCaption =>
      'Colour corners with a photo column and timeline sections.';

  @override
  String get templateStructuredAts => 'Structured ATS';

  @override
  String get templateStructuredAtsCaption =>
      'Gray section bands and a centered header for parsers.';

  @override
  String get templateLatexClassicAts => 'LaTeX Classic ATS';

  @override
  String get templateLatexClassicAtsCaption =>
      'Academic ruled sections inspired by classic LaTeX resumes.';

  @override
  String get templateModernFlowAts => 'Modern Flow ATS';

  @override
  String get templateModernFlowAtsCaption =>
      'Centered contact row with a logical section sequence.';

  @override
  String get templateExecutiveAts => 'Executive ATS';

  @override
  String get templateExecutiveAtsCaption =>
      'Uppercase headings and two-column keyword skills.';

  @override
  String get templateCenterClassicAts => 'Center Classic ATS';

  @override
  String get templateCenterClassicAtsCaption =>
      'Centered name, pipe tagline, and ruled single-column sections.';

  @override
  String get templateProfessionalBlueAts => 'Professional Blue ATS';

  @override
  String get templateProfessionalBlueAtsCaption =>
      'Blue accent headings with right-aligned contact and skills grid.';

  @override
  String get templateClassicCvAts => 'Classic CV ATS';

  @override
  String get templateClassicCvAtsCaption =>
      'Centered name, personal-details grid, and left-labeled ruled sections.';

  @override
  String get templateCleanSansAts => 'Clean Sans ATS';

  @override
  String get templateCleanSansAtsCaption =>
      'Bold uppercase name, right-aligned contact, and two-column skills.';

  @override
  String get templateExecutiveNote => 'Executive Note';

  @override
  String get templateExecutiveNoteCaption =>
      'Clean professional cover letter with a strong header block.';

  @override
  String get templateMinimalLetter => 'Minimal Letter';

  @override
  String get templateMinimalLetterCaption =>
      'Centered header with airy spacing and left-aligned body.';

  @override
  String get templateMintLetter => 'Mint Letter';

  @override
  String get templateMintLetterCaption =>
      'Oversized name, soft mint background, and a clean modern letter body.';

  @override
  String get templateClassicBusiness => 'Classic Business';

  @override
  String get templateClassicBusinessCaption =>
      'Traditional business letter: date, recipient block, and left-aligned body.';

  @override
  String get autoSync => 'Auto sync';

  @override
  String get sync => 'Sync';

  @override
  String get download => 'Download';

  @override
  String get alreadyDownloaded => 'Already downloaded';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get syncToIcloud => 'Sync to iCloud';

  @override
  String get syncToGoogleDrive => 'Sync to Google Drive';

  @override
  String get iCloudUnavailable =>
      'iCloud is not available on this device right now. Make sure iCloud Drive is enabled and you are signed in with the correct Apple ID.';

  @override
  String get noItemsInIcloud =>
      'No resumes or cover letters are stored in iCloud yet.';

  @override
  String get noItemsOnDrive =>
      'No resumes or cover letters are stored on Drive yet.';

  @override
  String get resumesInIcloud => 'Resumes in iCloud';

  @override
  String get coverLettersInIcloud => 'Cover letters in iCloud';

  @override
  String get resumesInGoogleDrive => 'Resumes in Google Drive';

  @override
  String get coverLettersInGoogleDrive => 'Cover letters in Google Drive';

  @override
  String get googleDriveBackupIntro =>
      'Back up resumes and cover letters to a ResumeApp folder on your Google Drive. Only files created by this app are accessible.';

  @override
  String get googleDrivePermissionHint =>
      'On the Google page that opens next, under \"Select what ResumeApp can access\", check the box next to Google Drive (files used with this app), then tap Continue. Without that box, Drive backup cannot work.';

  @override
  String get googleDriveLooksLikeThis => 'It looks like this:';

  @override
  String get googleDrivePermissionExampleSemantics =>
      'Example Google screen: Select what ResumeApp can access, with the Google Drive row and checkbox.';

  @override
  String get noLocalItemsToSync =>
      'No local resumes or cover letters available to sync.';

  @override
  String get everythingUpToDateIcloud =>
      'Everything is already up to date in iCloud.';

  @override
  String get everythingUpToDateGoogleDrive =>
      'Everything is already up to date on Google Drive.';

  @override
  String couldNotLoadIcloudItems(String error) {
    return 'Could not load iCloud items: $error';
  }

  @override
  String couldNotSyncToIcloud(String error) {
    return 'Could not sync to iCloud: $error';
  }

  @override
  String couldNotDeleteFromIcloud(String error) {
    return 'Could not delete from iCloud: $error';
  }

  @override
  String couldNotDownloadWithError(String error) {
    return 'Could not download: $error';
  }

  @override
  String syncedSummaryToIcloud(String summary) {
    return 'Synced $summary to iCloud.';
  }

  @override
  String syncedSummaryWithSkippedIcloud(String summary, String skipped) {
    return 'Synced $summary. $skipped left untouched.';
  }

  @override
  String syncedSummaryToGoogleDrive(String summary) {
    return 'Synced $summary to Google Drive.';
  }

  @override
  String syncedSummaryWithSkippedDrive(String summary, String skipped) {
    return 'Synced $summary. $skipped left untouched.';
  }

  @override
  String resumeCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resumes',
      one: '1 resume',
    );
    return '$_temp0';
  }

  @override
  String coverLetterCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cover letters',
      one: '1 cover letter',
    );
    return '$_temp0';
  }

  @override
  String newerIcloudItemsUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count newer iCloud items',
      one: '1 newer iCloud item',
    );
    return '$_temp0';
  }

  @override
  String newerDriveItemsUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count newer Drive items',
      one: '1 newer Drive item',
    );
    return '$_temp0';
  }

  @override
  String listJoinAnd(String first, String second) {
    return '$first and $second';
  }

  @override
  String get deleteFromIcloudTitle => 'Delete from iCloud?';

  @override
  String deleteFromIcloudMessage(String title) {
    return 'Remove \"$title\" from iCloud? This will not delete the copy on this device.';
  }

  @override
  String get deleteFromIcloud => 'Delete from iCloud';

  @override
  String deleteDocumentType(String type) {
    return 'Delete $type';
  }

  @override
  String get documentTypeResume => 'resume';

  @override
  String get documentTypeCoverLetter => 'cover letter';

  @override
  String removedFromIcloud(String title) {
    return 'Removed $title from iCloud.';
  }

  @override
  String downloadedTitle(String title) {
    return 'Downloaded $title.';
  }

  @override
  String get googleSignInUnavailable =>
      'Google sign-in is not available on this device.';

  @override
  String get couldNotSignInGoogleDrive =>
      'Could not sign in to Google Drive right now. Try again.';

  @override
  String get couldNotLoadGoogleDriveItems =>
      'Could not load your Google Drive items right now. Try again.';

  @override
  String get couldNotSyncGoogleDrive =>
      'Could not sync to Google Drive right now. Try again.';

  @override
  String get couldNotDownloadFromGoogleDrive =>
      'Could not download this item from Google Drive. Try again.';

  @override
  String get couldNotRemoveFromGoogleDrive =>
      'Could not remove this item from Google Drive. Try again.';

  @override
  String get removeFromGoogleDriveTitle => 'Remove from Google Drive?';

  @override
  String removeFromGoogleDriveMessage(String title) {
    return 'Remove \"$title\" from Google Drive? This will not delete the copy on this device.';
  }

  @override
  String get removeFromGoogleDrive => 'Remove from Google Drive';

  @override
  String removeDocumentType(String type) {
    return 'Remove $type';
  }

  @override
  String removedFromGoogleDrive(String title) {
    return 'Removed $title from Google Drive.';
  }

  @override
  String get googleSignInNotConfigured =>
      'Google Sign-In is not configured for this build. Add your debug and release SHA-1 fingerprints in Firebase (see android/GOOGLE_SIGN_IN_SETUP.md), re-download google-services.json, and rebuild.';

  @override
  String get couldNotOpenGoogleSignIn =>
      'Could not open the Google sign-in screen. Try again.';

  @override
  String get googleSignInInterrupted =>
      'Google sign-in was interrupted. Try again.';

  @override
  String get unableToLoadPage => 'Unable to load page';

  @override
  String get couldNotLoadThisPage => 'Could not load this page.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get shareAppSubject => 'ResumeApp';

  @override
  String shareAppMessage(String url) {
    return 'Check out ResumeAI to create, optimize, and share professional resumes. Download it here: $url';
  }

  @override
  String get feedbackEmailSubject => 'ResumeApp Feedback';

  @override
  String get noMailAppFound =>
      'No mail app found. Please configure a mail app.';

  @override
  String get couldNotOpenMailApp =>
      'Could not open mail app. Please try again.';

  @override
  String get couldNotOpenLink => 'Could not open link right now.';

  @override
  String get add => 'Add';

  @override
  String get addSection => 'Add section';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get hide => 'Hide';

  @override
  String get remove => 'Remove';

  @override
  String get preview => 'Preview';

  @override
  String get share => 'Share';

  @override
  String get print => 'Print';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get template => 'Template';

  @override
  String get color => 'Color';

  @override
  String get title => 'Title';

  @override
  String get type => 'Type';

  @override
  String get year => 'Year';

  @override
  String get summary => 'Summary';

  @override
  String get category => 'Category';

  @override
  String get present => 'Present';

  @override
  String get language => 'Language';

  @override
  String get sectionPersonalInformation => 'Personal Information';

  @override
  String get sectionWorkExperience => 'Work Experience';

  @override
  String get sectionEducation => 'Education';

  @override
  String get sectionSkills => 'Skills';

  @override
  String get sectionProjects => 'Projects';

  @override
  String get personalInformationTitle => 'Personal information';

  @override
  String get workExperienceTitle => 'Work experience';

  @override
  String categoryNumber(int number) {
    return 'Category $number';
  }

  @override
  String pdfSavedTo(String path) {
    return 'PDF saved to $path';
  }

  @override
  String get unableToGenerateSummary =>
      'Unable to generate a professional summary right now.';

  @override
  String get summaryUpdated => 'Summary updated';

  @override
  String get summaryAdded => 'Summary added';

  @override
  String get skillAlreadyInList => 'This skill is already in your list.';

  @override
  String get addBulletPoint => 'Add bullet point';

  @override
  String get appearsFirstOnYourResume => 'Appears first on your resume';

  @override
  String appearsOnYourResumeAt(int position) {
    return 'Appears at position $position on your resume';
  }

  @override
  String get hideFromResumeTitle => 'Hide from resume?';

  @override
  String hideFromResumeMessage(String sectionName) {
    return '$sectionName will not be shown on your resume or in exported PDFs. You can show it again anytime using the button next to the section title.';
  }

  @override
  String get hideFromResume => 'Hide from resume';

  @override
  String get showOnResume => 'Show on resume';

  @override
  String get chooseMonthAndYear => 'Choose month and year';

  @override
  String get clearDate => 'Clear date';

  @override
  String get selectEndMonthAndYear => 'Select end month and year';

  @override
  String get selectStartMonthAndYear => 'Select start month and year';

  @override
  String get selectEndYear => 'Select end year';

  @override
  String get selectStartYear => 'Select start year';

  @override
  String get newSection => 'New section';

  @override
  String get newSectionTitleHint => 'e.g. Certifications, Awards';

  @override
  String get sectionTypeNormal => 'Normal';

  @override
  String get sectionTypeNormalSubtitle => 'Summary or bullet points';

  @override
  String get sectionTypeAdvance => 'Advance';

  @override
  String get sectionTypeAdvanceSubtitle =>
      'Project-style entries with title and bullets';

  @override
  String get removeSectionTitle => 'Remove section?';

  @override
  String get removeSectionMessage =>
      'This section will be removed from your resume. You can add a new custom section with Add section anytime.';

  @override
  String get unableToPickImage => 'Unable to pick image right now.';

  @override
  String get camera => 'Camera';

  @override
  String get library => 'Library';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get tapToChangePhoto => 'Tap to change photo';

  @override
  String get previousField => 'Previous field';

  @override
  String get nextField => 'Next field';

  @override
  String get fullName => 'Full name';

  @override
  String get targetJobTitle => 'Target job title';

  @override
  String get githubLink => 'GitHub link';

  @override
  String get linkedinLink => 'LinkedIn link';

  @override
  String get email => 'Email';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get location => 'City';

  @override
  String get websiteOrPortfolio => 'Website or portfolio';

  @override
  String get professionalSummary => 'Professional summary';

  @override
  String get personalInformationSubtitle =>
      'Start with your name, email, phone, and city. Add LinkedIn, a website, or a photo if you want.';

  @override
  String get addMoreOptional => 'Add more (optional)';

  @override
  String get suggestSummary => 'Suggest summary';

  @override
  String get suggestSummaryAddDetailsTitle => 'Add a few details first';

  @override
  String get suggestSummaryMissingNameAndTitle =>
      'Enter your full name and target job title first, then try Suggest summary again.';

  @override
  String get suggestSummaryMissingName =>
      'Enter your full name first, then try Suggest summary again.';

  @override
  String get suggestSummaryMissingTitle =>
      'Enter your target job title first, then try Suggest summary again.';

  @override
  String get suggestSummaryExperienceTitle => 'Years of experience';

  @override
  String get suggestSummaryExperienceBody =>
      'How many years of experience do you have?';

  @override
  String get suggestSummaryExperienceLabel => 'Years';

  @override
  String get suggestSummaryExperienceHint => 'e.g. 5';

  @override
  String get resumeOrder => 'Resume order';

  @override
  String get resumeOrderBody =>
      'Entries stay in this order. Use arrows to move your strongest role to top.';

  @override
  String get reorderSections => 'Reorder sections';

  @override
  String get reorderSectionsBody =>
      'Hold and drag a section, like Work Experience, to change where it appears on your resume.';

  @override
  String get reorderSectionTooltip => 'Hold and drag to reorder';

  @override
  String experienceNumber(int number) {
    return 'Experience $number';
  }

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get deleteExperience => 'Delete experience';

  @override
  String get deleteWorkExperienceTitle => 'Delete work experience?';

  @override
  String get deleteWorkExperienceMessage =>
      'This will remove this job and all of its bullet points. This cannot be undone.';

  @override
  String get role => 'Role';

  @override
  String get company => 'Company';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get monthYearHint => 'Month/year';

  @override
  String get monthYearOrPresentHint => 'Month/year or Present';

  @override
  String bulletNumber(int number) {
    return 'Bullet $number';
  }

  @override
  String get removeBulletTitle => 'Remove bullet?';

  @override
  String get removeBulletFromJob =>
      'This bullet will be removed from this job.';

  @override
  String get addExperience => 'Add experience';

  @override
  String get educationSubtitle =>
      'Include your degree, institution, and study timeline.';

  @override
  String educationNumber(int number) {
    return 'Education $number';
  }

  @override
  String get moveEducationUp => 'Move education up';

  @override
  String get moveEducationDown => 'Move education down';

  @override
  String get deleteEducationEntry => 'Delete education entry';

  @override
  String get deleteEducationEntryTitle => 'Delete education entry?';

  @override
  String get deleteEducationEntryMessage =>
      'This will remove this school and degree from your resume. This cannot be undone.';

  @override
  String get institution => 'Institution';

  @override
  String get degree => 'Degree';

  @override
  String get startYear => 'Start year';

  @override
  String get endYear => 'End year';

  @override
  String get selectYear => 'Select year';

  @override
  String get marksScore => 'Marks / score';

  @override
  String get marksScoreHint => '8.6 CGPA, 92, or 780/800';

  @override
  String get addEducation => 'Add education';

  @override
  String get showScoreAsPercent => 'Show as percent';

  @override
  String get skillsSubtitle =>
      'Add job-specific tools and keywords. Choose a simple list, or categorise skills under headings (for example Languages, Tools).';

  @override
  String skillsCount(int count) {
    return '$count skills';
  }

  @override
  String get simpleList => 'Simple list';

  @override
  String get categorised => 'Categorised';

  @override
  String get addASkill => 'Add a skill';

  @override
  String get addSkillHelper => 'Type to see suggestions or add your own skill';

  @override
  String get skillEfficiency => 'Efficiency';

  @override
  String skillEfficiencyPercent(int percent) {
    return '$percent%';
  }

  @override
  String get categoryHint => 'e.g. Languages, Tools';

  @override
  String get moveCategoryUp => 'Move category up';

  @override
  String get moveCategoryDown => 'Move category down';

  @override
  String get removeCategory => 'Remove category';

  @override
  String get deleteCategoryTitle => 'Delete category?';

  @override
  String get deleteCategoryMessage =>
      'This will remove this category and all of its skills. This cannot be undone.';

  @override
  String get addCategory => 'Add category';

  @override
  String get projectsSubtitle =>
      'Showcase standout side projects, product launches, or portfolio work with clear outcomes.';

  @override
  String projectNumber(int number) {
    return 'Project $number';
  }

  @override
  String get moveProjectUp => 'Move project up';

  @override
  String get moveProjectDown => 'Move project down';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get deleteProjectTitle => 'Delete project?';

  @override
  String get deleteProjectMessage =>
      'This will remove this project and all of its bullet points. This cannot be undone.';

  @override
  String get projectTitle => 'Project title';

  @override
  String get enterBulletPoint => 'Enter a bullet point';

  @override
  String get removeBulletFromProject =>
      'This bullet will be removed from this project.';

  @override
  String get addProject => 'Add project';

  @override
  String get customSectionProjectsSubtitle =>
      'Add entries with a title and bullet points, like the Projects section.';

  @override
  String get removeSection => 'Remove section';

  @override
  String get bulletPoints => 'Bullet points';

  @override
  String get customSectionSummaryHint =>
      'Write the section as a short paragraph for your resume.';

  @override
  String entryNumber(int number) {
    return 'Entry $number';
  }

  @override
  String get moveEntryUp => 'Move entry up';

  @override
  String get moveEntryDown => 'Move entry down';

  @override
  String get deleteEntry => 'Delete entry';

  @override
  String get deleteEntryTitle => 'Delete entry?';

  @override
  String get deleteEntryMessage =>
      'This will remove this entry and all of its bullet points. This cannot be undone.';

  @override
  String get removeBulletFromEntry =>
      'This bullet will be removed from this entry.';

  @override
  String get addEntry => 'Add entry';

  @override
  String get livePreview => 'Live preview';

  @override
  String get exportActions => 'Export actions';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get shareResume => 'Share resume';

  @override
  String get resumeScore => 'Resume score';

  @override
  String atsCompatibilitySummary(int percent, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ATS compatibility $percent% with $count missing skill gaps.',
      one: 'ATS compatibility $percent% with 1 missing skill gap.',
    );
    return '$_temp0';
  }

  @override
  String get unableToOpenShareSheet => 'Unable to open share sheet right now.';

  @override
  String get chooseTemplate => 'Choose template';

  @override
  String get fontSize => 'Font size';

  @override
  String get resumeFont => 'Font';

  @override
  String get colorAndFont => 'Color & Font';

  @override
  String get sharedFromResumeAi => 'Shared from ResumeAI';

  @override
  String get unableToLoadPdfPreview => 'Unable to load PDF preview right now.';

  @override
  String get shareFormatPdf => 'PDF';

  @override
  String get shareFormatDocx => 'DOCX';

  @override
  String get coverLetterHeading => 'Cover letter';

  @override
  String get coverLetterEditorIntro =>
      'This page creates a cover letter draft from the details below. Add the company name, job position name, one or more skills to highlight, and a language you want to mention, then tap Create cover letter to open the full draft on the next screen.';

  @override
  String get companyName => 'Company name';

  @override
  String get jobPositionName => 'Job position name';

  @override
  String get skillToHighlight => 'Skill to highlight';

  @override
  String get creatingEllipsis => 'Creating...';

  @override
  String get createCoverLetter => 'Create cover letter';

  @override
  String get coverLetterContentHeading => 'Cover letter content';

  @override
  String get coverLetterContentIntro =>
      'Your cover letter draft is ready. Review the full content below, edit anything you want, and your changes will be saved automatically.';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get coverLetterContentHint =>
      'Your generated cover letter will appear here.';

  @override
  String get clLangEnglish => 'English (English)';

  @override
  String get clLangArabic => 'Arabic (العربية)';

  @override
  String get clLangBengali => 'Bengali (বাংলা)';

  @override
  String get clLangChinese => 'Chinese, Mandarin (中文)';

  @override
  String get clLangDutch => 'Dutch (Nederlands)';

  @override
  String get clLangFrench => 'French (Français)';

  @override
  String get clLangGerman => 'German (Deutsch)';

  @override
  String get clLangHindi => 'Hindi (हिन्दी)';

  @override
  String get clLangItalian => 'Italian (Italiano)';

  @override
  String get clLangJapanese => 'Japanese (日本語)';

  @override
  String get clLangKorean => 'Korean (한국어)';

  @override
  String get clLangPortuguese => 'Portuguese (Português)';

  @override
  String get clLangRussian => 'Russian (Русский)';

  @override
  String get clLangSpanish => 'Spanish (Español)';

  @override
  String get clLangTurkish => 'Turkish (Türkçe)';

  @override
  String get clLangUrdu => 'Urdu (اردو)';

  @override
  String get clLangVietnamese => 'Vietnamese (Tiếng Việt)';

  @override
  String get showPercentOnResume => 'Tap to show % on resume';

  @override
  String get hidePercentOnResume => 'Showing % on resume — tap to hide';

  @override
  String get removeBullet => 'Remove bullet';

  @override
  String get alreadySubscribedTitle => 'Already subscribed';

  @override
  String youreOnPlan(String planLabel) {
    return 'You\'re on the $planLabel';
  }

  @override
  String get premiumPlanNotAvailableYet =>
      'That plan is not available yet. Pull to refresh.';

  @override
  String get premiumCouldNotStartPurchase =>
      'Could not start the purchase. Please try again.';

  @override
  String get premiumSubscriptionRestored =>
      'Your Premium subscription has been restored.';

  @override
  String get premiumRestoredSuccessfully => 'Premium restored successfully.';

  @override
  String get welcomeToResumeAppPro => 'Welcome to ResumeApp Pro!';

  @override
  String get jobsCreateResumeFirst =>
      'Create a resume first to see job matches.';

  @override
  String get jobsShowingLatestHint =>
      'Showing latest jobs from last 7 days based on the selected resume role and location.';

  @override
  String get jobsNoneFound => 'No jobs found for this resume in last 7 days.';

  @override
  String get jobsLoadingMore => 'Loading more jobs...';

  @override
  String get jobsScrollForMore => 'Scroll down to load more';

  @override
  String get jobsLiveUnavailableBackup =>
      'Live jobs unavailable, showing backup results.';

  @override
  String get couldNotOpenJobLink => 'Could not open job link right now.';

  @override
  String get jobsPostedJustNow => 'just now';

  @override
  String jobsPostedHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String jobsPostedDaysAgo(int days) {
    return '${days}d ago';
  }
}
