// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'ResumeAI';

  @override
  String get tabHome => 'Beranda';

  @override
  String get tabTemplates => 'Template';

  @override
  String get tabAiResume => 'CV AI';

  @override
  String get tabSettings => 'Pengaturan';

  @override
  String get appearance => 'Tampilan';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get appLanguage => 'Bahasa aplikasi';

  @override
  String get languageSystemDefault => 'Default sistem';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortugueseBrazil => 'Português (Brasil)';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get iCloudBackup => 'Cadangan iCloud';

  @override
  String get googleDriveBackup => 'Cadangan Google Drive';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get youAreProUser => 'Anda pengguna Pro';

  @override
  String get feedback => 'Masukan';

  @override
  String get rateApp => 'Nilai aplikasi';

  @override
  String get ratePromptTitle => 'Suka ResumeAI?';

  @override
  String get ratePromptBody =>
      'Jika aplikasi ini membantu, penilaian singkat sangat berarti bagi kami.';

  @override
  String get maybeLater => 'Nanti saja';

  @override
  String get shareApp => 'Bagikan aplikasi';

  @override
  String get privacyPolicy => 'Kebijakan privasi';

  @override
  String get termsOfUse => 'Syarat penggunaan';

  @override
  String get versionLabel => 'Versi';

  @override
  String versionWithBuild(String version, String build) {
    return 'Versi $version ($build)';
  }

  @override
  String get ok => 'OK';

  @override
  String get languageAffectsAppOnly =>
      'Hanya mengubah menu dan teks aplikasi. Isi resume Anda tetap seperti yang ditulis.';

  @override
  String get homeSegmentResume => 'Resume';

  @override
  String get homeSegmentCoverLetter => 'Surat lamaran';

  @override
  String get noResumesYet => 'Belum ada resume';

  @override
  String get noResumesYetBody =>
      'Ketuk tombol tambah untuk membuat resume pertama Anda.';

  @override
  String get noCoverLettersYet => 'Belum ada surat lamaran';

  @override
  String get noCoverLettersYetBody =>
      'Ketuk tombol tambah untuk membuat surat lamaran pertama Anda.';

  @override
  String get actionOpen => 'Buka';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionRename => 'Ubah nama';

  @override
  String get actionDuplicate => 'Duplikat';

  @override
  String get actionDelete => 'Hapus';

  @override
  String get cancel => 'Batal';

  @override
  String get create => 'Buat';

  @override
  String get deleteResumeTitle => 'Hapus resume?';

  @override
  String deleteResumeMessage(String title) {
    return 'Hapus \"$title\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get deleteCoverLetterTitle => 'Hapus surat lamaran?';

  @override
  String deleteCoverLetterMessage(String title) {
    return 'Hapus \"$title\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get renameResumeTitle => 'Ubah nama resume';

  @override
  String get duplicateResumeTitle => 'Duplikat resume';

  @override
  String get resumeRenamed => 'Resume diganti namanya.';

  @override
  String get resumeDuplicated => 'Resume diduplikasi.';

  @override
  String get resumeTitle => 'Judul resume';

  @override
  String get enterResumeTitle => 'Masukkan judul resume';

  @override
  String get coverLetterTitle => 'Judul surat lamaran';

  @override
  String updatedDate(String date) {
    return 'Diperbarui $date';
  }

  @override
  String titleWithCopySuffix(String title) {
    return '$title (Salinan)';
  }

  @override
  String get untitledResume => 'Resume tanpa judul';

  @override
  String get untitledCoverLetter => 'Surat lamaran tanpa judul';

  @override
  String get save => 'Simpan';

  @override
  String get continueAction => 'Lanjutkan';

  @override
  String get restore => 'Pulihkan';

  @override
  String get resumeAppPro => 'ResumeApp Pro';

  @override
  String get chooseAPlan => 'Pilih paket';

  @override
  String get premiumLegalAgreement =>
      'Dengan melanjutkan, Anda menyetujui Syarat Penggunaan dan Kebijakan Privasi kami.';

  @override
  String get subscriptionFound => 'Langganan ditemukan';

  @override
  String get processingEllipsis => 'Memproses…';

  @override
  String get checkingYourSubscription => 'Memeriksa langganan Anda…';

  @override
  String get completingYourPurchase => 'Menyelesaikan pembelian Anda…';

  @override
  String get restoringYourSubscription => 'Memulihkan langganan Anda…';

  @override
  String get pleaseWaitDoNotClose => 'Harap tunggu. Jangan tutup aplikasi.';

  @override
  String get premiumWelcomeCongratulations => 'Selamat!';

  @override
  String premiumWelcomeBody(String planLabel, String backup) {
    return 'ResumeApp Pro aktif pada $planLabel Anda. Template Premium dan $backup kini terbuka.';
  }

  @override
  String get premiumBenefitUnlockLayouts =>
      'Buka AI Resume — buat dan sempurnakan resume ATS dengan AI';

  @override
  String get premiumBenefitBackupIcloud =>
      'Cadangkan dan sinkronkan resume dengan iCloud';

  @override
  String get premiumBenefitBackupGoogleDrive =>
      'Cadangkan dan sinkronkan resume dengan Google Drive';

  @override
  String get premiumUpcomingUpdateBadge => 'Hadir di pembaruan berikutnya';

  @override
  String get premiumUpcomingUpdateMessage =>
      'Tata letak resume baru dan template modern, termasuk dalam Pro.';

  @override
  String get planWeekly => 'Mingguan';

  @override
  String get planMonthly => 'Bulanan';

  @override
  String get planYearly => 'Tahunan';

  @override
  String get planPro => 'Pro';

  @override
  String get planSubtitleWeekly => 'Akses jangka pendek';

  @override
  String get planSubtitleMonthly => 'Bayar bulanan';

  @override
  String get planSubtitleYearly => 'Nilai terbaik';

  @override
  String planLabelNamed(String title) {
    return 'Paket $title';
  }

  @override
  String savePercentWithYearlyBilling(int percent) {
    return 'Hemat $percent% dengan penagihan tahunan';
  }

  @override
  String get priceUnavailable => '—';

  @override
  String get storeAccountGoogle => 'akun Google';

  @override
  String get storeAccountApple => 'Apple ID';

  @override
  String get alreadySubscribedDebugOverride =>
      'Override Pro pengembang aktif. Semua fitur Pro terbuka untuk pengujian di perangkat ini.';

  @override
  String alreadySubscribedWeekly(String backup) {
    return 'Anda memiliki langganan mingguan aktif. Semua template Pro, $backup, dan fitur premium sudah termasuk.';
  }

  @override
  String alreadySubscribedMonthly(String backup) {
    return 'Anda memiliki langganan bulanan aktif. Semua template Pro, $backup, dan fitur premium sudah termasuk.';
  }

  @override
  String alreadySubscribedYearly(String backup) {
    return 'Anda memiliki langganan tahunan aktif. Semua template Pro, $backup, dan fitur premium sudah termasuk.';
  }

  @override
  String get alreadySubscribedGeneric =>
      'Anda memiliki langganan ResumeApp Pro aktif. Semua fitur premium termasuk dalam paket Anda.';

  @override
  String restoreInsteadWeekly(String account) {
    return 'Langganan mingguan ditemukan untuk $account ini. Gunakan Pulihkan untuk mengaktifkannya di perangkat ini alih-alih membeli lagi.';
  }

  @override
  String restoreInsteadMonthly(String account) {
    return 'Langganan bulanan ditemukan untuk $account ini. Gunakan Pulihkan untuk mengaktifkannya di perangkat ini alih-alih membeli lagi.';
  }

  @override
  String restoreInsteadYearly(String account) {
    return 'Langganan tahunan ditemukan untuk $account ini. Gunakan Pulihkan untuk mengaktifkannya di perangkat ini alih-alih membeli lagi.';
  }

  @override
  String restoreInsteadGeneric(String account) {
    return 'Langganan ResumeApp Pro aktif ditemukan untuk $account ini. Gunakan Pulihkan untuk mengaktifkannya di perangkat ini alih-alih membeli lagi.';
  }

  @override
  String get premiumPurchaseFailed =>
      'Kami tidak dapat menyelesaikan pembelian Anda. Silakan coba lagi.';

  @override
  String get premiumRestoreFailed =>
      'Kami tidak dapat memulihkan langganan Anda. Silakan coba lagi.';

  @override
  String get noSubscriptionToRestoreGoogle =>
      'Tidak ada langganan aktif yang ditemukan untuk akun Google ini.';

  @override
  String get noSubscriptionToRestoreApple =>
      'Tidak ada langganan aktif yang ditemukan untuk Apple ID ini.';

  @override
  String get premiumStoreUnavailable =>
      'Pembelian tidak tersedia di perangkat ini saat ini.';

  @override
  String get premiumConnectFailedGoogle =>
      'Kami tidak dapat terhubung ke Google Play. Silakan coba lagi nanti.';

  @override
  String get premiumConnectFailedApple =>
      'Kami tidak dapat terhubung ke App Store. Silakan coba lagi nanti.';

  @override
  String get premiumVerifyFailed =>
      'Kami tidak dapat memverifikasi langganan Anda. Silakan coba lagi.';

  @override
  String get premiumProductsUnavailable =>
      'Paket langganan tidak tersedia saat ini. Silakan coba lagi nanti.';

  @override
  String get premiumPurchaseCanceled => 'Pembelian dibatalkan.';

  @override
  String get hideKeyboard => 'Sembunyikan keyboard';

  @override
  String get selectResumeWithContentFirst =>
      'Pilih dulu resume tersimpan yang berisi konten.';

  @override
  String get aiAtsIntro =>
      'Pilih resume dan AI akan membuat versi ATS yang dioptimalkan. Tambahkan kunci API di Pengaturan untuk hasil lebih kuat, atau gunakan AI bawaan. Deskripsi pekerjaan bersifat opsional. Ketuk Buat lagi untuk menyempurnakan.';

  @override
  String get aiEngineUsingCloudApi => 'Menggunakan kunci API Anda (AI cloud)';

  @override
  String get aiEngineUsingAppleIntelligence =>
      'Menggunakan Apple Intelligence (di perangkat)';

  @override
  String get aiEngineUsingBuiltIn => 'Menggunakan AI bawaan';

  @override
  String get aiApiKeySettingsTitle => 'Kunci API AI';

  @override
  String get aiApiKeySettingsIntro =>
      'Tambahkan kunci API OpenAI atau Gemini Anda sendiri untuk membuat resume ATS yang lebih kuat. Kunci tetap di perangkat ini. Jika tidak ada kunci, iPhone memakai Apple Intelligence bila tersedia; jika tidak, AI bawaan.';

  @override
  String aiApiKeyConfiguredSubtitle(String provider) {
    return 'Tersimpan: $provider';
  }

  @override
  String get aiApiKeyMissingSubtitle =>
      'Opsional — gunakan kunci OpenAI atau Gemini Anda';

  @override
  String get aiProviderLabel => 'Penyedia';

  @override
  String get aiApiKeyLabel => 'Kunci API';

  @override
  String get aiApiKeyHint => 'Tempel kunci API rahasia Anda';

  @override
  String get aiModelOptionalLabel => 'Model (opsional)';

  @override
  String get aiApiKeyRequired => 'Masukkan kunci API terlebih dahulu.';

  @override
  String get aiApiKeySaved => 'Kunci API disimpan di perangkat ini.';

  @override
  String get aiApiKeyRemoved => 'Kunci API dihapus.';

  @override
  String get aiApiKeyTestSuccess => 'Kunci API berfungsi.';

  @override
  String aiApiKeySavedMasked(String maskedKey) {
    return 'Kunci tersimpan: $maskedKey';
  }

  @override
  String get saveAiApiKey => 'Simpan kunci API';

  @override
  String get testAiApiKey => 'Uji kunci API';

  @override
  String get removeAiApiKey => 'Hapus kunci API';

  @override
  String get noResumeAvailable => 'Belum ada resume tersedia saat ini.';

  @override
  String get createResumeThenGenerateAts =>
      'Buat resume terlebih dahulu, lalu kembali ke sini untuk membuat versi ATS.';

  @override
  String get selectResume => 'Pilih resume';

  @override
  String get jobDescriptionOptional => 'Deskripsi pekerjaan (opsional)';

  @override
  String get jobDescriptionHint =>
      'Tempel lowongan untuk menyesuaikan resume ATS, atau biarkan kosong.';

  @override
  String get createAtsResume => 'Buat resume ATS';

  @override
  String furtherOptimizeAtsPass(int pass) {
    return 'Optimalkan ATS lebih lanjut (putaran $pass)';
  }

  @override
  String get appliedChanges => 'Perubahan yang diterapkan';

  @override
  String get showAtsResume => 'Tampilkan resume ATS';

  @override
  String get saveOptimizedResume => 'Simpan resume yang dioptimalkan';

  @override
  String saveOptimizedResumePrompt(String sourceTitle) {
    return 'Apakah Anda ingin menyimpan ini sebagai salinan baru atau mengganti \"$sourceTitle\"?';
  }

  @override
  String get newCopy => 'Salinan baru';

  @override
  String get existingResume => 'Resume yang ada';

  @override
  String get resumePreview => 'Pratinjau resume';

  @override
  String get highlightedSummaryChange => 'Perubahan ringkasan yang disorot';

  @override
  String highlightedSkillsLabel(String skills) {
    return 'Keterampilan yang disorot: $skills';
  }

  @override
  String get atsTitleSuffix => ' (ATS)';

  @override
  String get optimizedTitleSuffix => ' (Dioptimalkan)';

  @override
  String get professionalResumes => 'Resume profesional';

  @override
  String get atsResumes => 'Resume ATS';

  @override
  String get useTemplate => 'Gunakan template';

  @override
  String get templateCorporate => 'Korporat';

  @override
  String get templateCorporateCaption =>
      'Pita atas tegas dengan bagian profesional yang ringkas.';

  @override
  String get templateProfileSidebar => 'Bilah sisi profil';

  @override
  String get templateProfileSidebarCaption =>
      'Tata letak berfokus profil dengan jangkar visual yang kuat.';

  @override
  String get templateClassicSidebar => 'Bilah sisi klasik';

  @override
  String get templateClassicSidebarCaption =>
      'Rel kiri lembut dengan identitas berfoto dan bagian terstruktur.';

  @override
  String get templateAccentStrip => 'Garis aksen';

  @override
  String get templateAccentStripCaption =>
      'Garis kiri tegas dengan nama besar dan bagian yang rapi.';

  @override
  String get templateStructuredAts => 'ATS terstruktur';

  @override
  String get templateStructuredAtsCaption =>
      'Pita bagian abu-abu dan header terpusat untuk parser.';

  @override
  String get templateLatexClassicAts => 'ATS klasik LaTeX';

  @override
  String get templateLatexClassicAtsCaption =>
      'Bagian beraturan ala resume LaTeX klasik.';

  @override
  String get templateModernFlowAts => 'ATS alur modern';

  @override
  String get templateModernFlowAtsCaption =>
      'Baris kontak terpusat dengan urutan bagian yang logis.';

  @override
  String get templateExecutiveAts => 'ATS eksekutif';

  @override
  String get templateExecutiveAtsCaption =>
      'Judul huruf besar dan keterampilan dua kolom.';

  @override
  String get templateCenterClassicAts => 'ATS klasik terpusat';

  @override
  String get templateCenterClassicAtsCaption =>
      'Nama terpusat, tagline berpipa, dan bagian satu kolom.';

  @override
  String get templateProfessionalBlueAts => 'ATS biru profesional';

  @override
  String get templateProfessionalBlueAtsCaption =>
      'Judul aksen biru dengan kontak rata kanan dan kisi keterampilan.';

  @override
  String get templateExecutiveNote => 'Catatan eksekutif';

  @override
  String get templateExecutiveNoteCaption =>
      'Surat lamaran profesional dengan blok header yang kuat.';

  @override
  String get templateMinimalLetter => 'Surat minimal';

  @override
  String get templateMinimalLetterCaption =>
      'Header terpusat dengan jarak lega dan isi rata kiri.';

  @override
  String get templateMintLetter => 'Surat mint';

  @override
  String get templateMintLetterCaption =>
      'Nama besar, latar mint lembut, dan isi surat modern yang rapi.';

  @override
  String get templateClassicBusiness => 'Bisnis klasik';

  @override
  String get templateClassicBusinessCaption =>
      'Surat bisnis tradisional: tanggal, blok penerima, dan isi rata kiri.';

  @override
  String get autoSync => 'Sinkronisasi otomatis';

  @override
  String get sync => 'Sinkronkan';

  @override
  String get download => 'Unduh';

  @override
  String get alreadyDownloaded => 'Sudah diunduh';

  @override
  String get signOut => 'Keluar';

  @override
  String get signInWithGoogle => 'Masuk dengan Google';

  @override
  String get syncToIcloud => 'Sinkronkan ke iCloud';

  @override
  String get syncToGoogleDrive => 'Sinkronkan ke Google Drive';

  @override
  String get iCloudUnavailable =>
      'iCloud tidak tersedia di perangkat ini saat ini. Pastikan iCloud Drive diaktifkan dan Anda masuk dengan Apple ID yang benar.';

  @override
  String get noItemsInIcloud =>
      'Belum ada resume atau surat lamaran di iCloud.';

  @override
  String get noItemsOnDrive => 'Belum ada resume atau surat lamaran di Drive.';

  @override
  String get resumesInIcloud => 'Resume di iCloud';

  @override
  String get coverLettersInIcloud => 'Surat lamaran di iCloud';

  @override
  String get resumesInGoogleDrive => 'Resume di Google Drive';

  @override
  String get coverLettersInGoogleDrive => 'Surat lamaran di Google Drive';

  @override
  String get googleDriveBackupIntro =>
      'Cadangkan resume dan surat lamaran ke folder ResumeApp di Google Drive Anda. Hanya file yang dibuat oleh aplikasi ini yang dapat diakses.';

  @override
  String get googleDrivePermissionHint =>
      'Di halaman Google yang terbuka berikutnya, di bawah \"Pilih yang dapat diakses ResumeApp\", centang kotak di samping Google Drive (file yang digunakan dengan aplikasi ini), lalu ketuk Lanjutkan. Tanpa kotak itu, cadangan Drive tidak dapat berfungsi.';

  @override
  String get googleDriveLooksLikeThis => 'Tampilannya seperti ini:';

  @override
  String get googleDrivePermissionExampleSemantics =>
      'Contoh layar Google: Pilih yang dapat diakses ResumeApp, dengan baris Google Drive dan kotak centang.';

  @override
  String get noLocalItemsToSync =>
      'Tidak ada resume atau surat lamaran lokal untuk disinkronkan.';

  @override
  String get everythingUpToDateIcloud => 'Semuanya sudah terbaru di iCloud.';

  @override
  String get everythingUpToDateGoogleDrive =>
      'Semuanya sudah terbaru di Google Drive.';

  @override
  String couldNotLoadIcloudItems(String error) {
    return 'Tidak dapat memuat item iCloud: $error';
  }

  @override
  String couldNotSyncToIcloud(String error) {
    return 'Tidak dapat menyinkronkan ke iCloud: $error';
  }

  @override
  String couldNotDeleteFromIcloud(String error) {
    return 'Tidak dapat menghapus dari iCloud: $error';
  }

  @override
  String couldNotDownloadWithError(String error) {
    return 'Tidak dapat mengunduh: $error';
  }

  @override
  String syncedSummaryToIcloud(String summary) {
    return '$summary disinkronkan ke iCloud.';
  }

  @override
  String syncedSummaryWithSkippedIcloud(String summary, String skipped) {
    return '$summary disinkronkan. $skipped dibiarkan utuh.';
  }

  @override
  String syncedSummaryToGoogleDrive(String summary) {
    return '$summary disinkronkan ke Google Drive.';
  }

  @override
  String syncedSummaryWithSkippedDrive(String summary, String skipped) {
    return '$summary disinkronkan. $skipped dibiarkan utuh.';
  }

  @override
  String resumeCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resume',
      one: '1 resume',
    );
    return '$_temp0';
  }

  @override
  String coverLetterCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count surat lamaran',
      one: '1 surat lamaran',
    );
    return '$_temp0';
  }

  @override
  String newerIcloudItemsUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item iCloud yang lebih baru',
      one: '1 item iCloud yang lebih baru',
    );
    return '$_temp0';
  }

  @override
  String newerDriveItemsUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item Drive yang lebih baru',
      one: '1 item Drive yang lebih baru',
    );
    return '$_temp0';
  }

  @override
  String listJoinAnd(String first, String second) {
    return '$first dan $second';
  }

  @override
  String get deleteFromIcloudTitle => 'Hapus dari iCloud?';

  @override
  String deleteFromIcloudMessage(String title) {
    return 'Hapus \"$title\" dari iCloud? Ini tidak akan menghapus salinan di perangkat ini.';
  }

  @override
  String get deleteFromIcloud => 'Hapus dari iCloud';

  @override
  String deleteDocumentType(String type) {
    return 'Hapus $type';
  }

  @override
  String get documentTypeResume => 'resume';

  @override
  String get documentTypeCoverLetter => 'surat lamaran';

  @override
  String removedFromIcloud(String title) {
    return '$title dihapus dari iCloud.';
  }

  @override
  String downloadedTitle(String title) {
    return '$title diunduh.';
  }

  @override
  String get googleSignInUnavailable =>
      'Masuk Google tidak tersedia di perangkat ini.';

  @override
  String get couldNotSignInGoogleDrive =>
      'Tidak dapat masuk ke Google Drive saat ini. Coba lagi.';

  @override
  String get couldNotLoadGoogleDriveItems =>
      'Tidak dapat memuat item Google Drive Anda saat ini. Coba lagi.';

  @override
  String get couldNotSyncGoogleDrive =>
      'Tidak dapat menyinkronkan ke Google Drive saat ini. Coba lagi.';

  @override
  String get couldNotDownloadFromGoogleDrive =>
      'Tidak dapat mengunduh item ini dari Google Drive. Coba lagi.';

  @override
  String get couldNotRemoveFromGoogleDrive =>
      'Tidak dapat menghapus item ini dari Google Drive. Coba lagi.';

  @override
  String get removeFromGoogleDriveTitle => 'Hapus dari Google Drive?';

  @override
  String removeFromGoogleDriveMessage(String title) {
    return 'Hapus \"$title\" dari Google Drive? Ini tidak akan menghapus salinan di perangkat ini.';
  }

  @override
  String get removeFromGoogleDrive => 'Hapus dari Google Drive';

  @override
  String removeDocumentType(String type) {
    return 'Hapus $type';
  }

  @override
  String removedFromGoogleDrive(String title) {
    return '$title dihapus dari Google Drive.';
  }

  @override
  String get googleSignInNotConfigured =>
      'Google Sign-In belum dikonfigurasi untuk build ini. Tambahkan sidik jari SHA-1 debug dan rilis di Firebase (lihat android/GOOGLE_SIGN_IN_SETUP.md), unduh ulang google-services.json, lalu bangun ulang.';

  @override
  String get couldNotOpenGoogleSignIn =>
      'Tidak dapat membuka layar masuk Google. Coba lagi.';

  @override
  String get googleSignInInterrupted => 'Masuk Google terputus. Coba lagi.';

  @override
  String get unableToLoadPage => 'Tidak dapat memuat halaman';

  @override
  String get couldNotLoadThisPage => 'Tidak dapat memuat halaman ini.';

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get shareAppSubject => 'ResumeApp';

  @override
  String shareAppMessage(String url) {
    return 'Coba ResumeAI untuk membuat, mengoptimalkan, dan membagikan resume profesional. Unduh di sini: $url';
  }

  @override
  String get feedbackEmailSubject => 'Masukan ResumeApp';

  @override
  String get noMailAppFound =>
      'Aplikasi email tidak ditemukan. Silakan konfigurasi aplikasi email.';

  @override
  String get couldNotOpenMailApp =>
      'Tidak dapat membuka aplikasi email. Coba lagi.';

  @override
  String get couldNotOpenLink => 'Tidak dapat membuka tautan saat ini.';

  @override
  String get add => 'Tambah';

  @override
  String get back => 'Kembali';

  @override
  String get done => 'Selesai';

  @override
  String get hide => 'Sembunyikan';

  @override
  String get remove => 'Hapus';

  @override
  String get preview => 'Pratinjau';

  @override
  String get share => 'Bagikan';

  @override
  String get print => 'Cetak';

  @override
  String get dismiss => 'Tutup';

  @override
  String get template => 'Templat';

  @override
  String get color => 'Warna';

  @override
  String get title => 'Judul';

  @override
  String get type => 'Jenis';

  @override
  String get year => 'Tahun';

  @override
  String get summary => 'Ringkasan';

  @override
  String get category => 'Kategori';

  @override
  String get present => 'Sekarang';

  @override
  String get language => 'Bahasa';

  @override
  String get sectionPersonalInformation => 'Informasi pribadi';

  @override
  String get sectionWorkExperience => 'Pengalaman kerja';

  @override
  String get sectionEducation => 'Pendidikan';

  @override
  String get sectionSkills => 'Keterampilan';

  @override
  String get sectionProjects => 'Proyek';

  @override
  String get personalInformationTitle => 'Informasi pribadi';

  @override
  String get workExperienceTitle => 'Pengalaman kerja';

  @override
  String categoryNumber(int number) {
    return 'Kategori $number';
  }

  @override
  String pdfSavedTo(String path) {
    return 'PDF disimpan ke $path';
  }

  @override
  String get unableToGenerateSummary =>
      'Tidak dapat membuat ringkasan profesional saat ini.';

  @override
  String get summaryUpdated => 'Ringkasan diperbarui';

  @override
  String get summaryAdded => 'Ringkasan ditambahkan';

  @override
  String get skillAlreadyInList => 'Keterampilan ini sudah ada di daftar Anda.';

  @override
  String get addBulletPoint => 'Tambah poin';

  @override
  String get appearsFirstOnYourResume => 'Muncul pertama di resume Anda';

  @override
  String appearsOnYourResumeAt(int position) {
    return 'Muncul di posisi $position di resume Anda';
  }

  @override
  String get hideFromResumeTitle => 'Sembunyikan dari resume?';

  @override
  String hideFromResumeMessage(String sectionName) {
    return '$sectionName tidak akan ditampilkan di resume atau PDF yang diekspor. Anda dapat menampilkannya lagi kapan saja menggunakan tombol di samping judul bagian.';
  }

  @override
  String get hideFromResume => 'Sembunyikan dari resume';

  @override
  String get showOnResume => 'Tampilkan di resume';

  @override
  String get chooseMonthAndYear => 'Pilih bulan dan tahun';

  @override
  String get clearDate => 'Hapus tanggal';

  @override
  String get selectEndMonthAndYear => 'Pilih bulan dan tahun akhir';

  @override
  String get selectStartMonthAndYear => 'Pilih bulan dan tahun mulai';

  @override
  String get selectEndYear => 'Pilih tahun akhir';

  @override
  String get selectStartYear => 'Pilih tahun mulai';

  @override
  String get newSection => 'Bagian baru';

  @override
  String get newSectionTitleHint => 'Sertifikasi, Bahasa, Penghargaan…';

  @override
  String get sectionTypeNormal => 'Normal';

  @override
  String get sectionTypeNormalSubtitle => 'Ringkasan atau poin';

  @override
  String get sectionTypeAdvance => 'Lanjutan';

  @override
  String get sectionTypeAdvanceSubtitle =>
      'Entri gaya proyek dengan judul dan poin';

  @override
  String get removeSectionTitle => 'Hapus bagian?';

  @override
  String get removeSectionMessage =>
      'Bagian ini akan dihapus dari resume Anda. Anda dapat menambahkan bagian khusus baru dengan Tambah kapan saja.';

  @override
  String get unableToPickImage => 'Tidak dapat memilih gambar saat ini.';

  @override
  String get camera => 'Kamera';

  @override
  String get library => 'Galeri';

  @override
  String get profilePhoto => 'Foto profil';

  @override
  String get tapToChangePhoto => 'Ketuk untuk mengubah foto';

  @override
  String get previousField => 'Bidang sebelumnya';

  @override
  String get nextField => 'Bidang berikutnya';

  @override
  String get fullName => 'Nama lengkap';

  @override
  String get targetJobTitle => 'Jabatan target';

  @override
  String get githubLink => 'Tautan GitHub';

  @override
  String get linkedinLink => 'Tautan LinkedIn';

  @override
  String get email => 'Email';

  @override
  String get phoneNumber => 'Nomor telepon';

  @override
  String get location => 'Lokasi';

  @override
  String get websiteOrPortfolio => 'Situs web atau portofolio';

  @override
  String get professionalSummary => 'Ringkasan profesional';

  @override
  String get personalInformationSubtitle =>
      'Mulai dengan identitas, detail kontak, peran target, dan ringkasan posisi singkat.';

  @override
  String get suggestSummary => 'Sarankan ringkasan';

  @override
  String get resumeOrder => 'Urutan resume';

  @override
  String get resumeOrderBody =>
      'Entri tetap dalam urutan ini. Gunakan panah untuk memindahkan peran terkuat ke atas.';

  @override
  String experienceNumber(int number) {
    return 'Pengalaman $number';
  }

  @override
  String get moveUp => 'Pindah ke atas';

  @override
  String get moveDown => 'Pindah ke bawah';

  @override
  String get deleteExperience => 'Hapus pengalaman';

  @override
  String get deleteWorkExperienceTitle => 'Hapus pengalaman kerja?';

  @override
  String get deleteWorkExperienceMessage =>
      'Ini akan menghapus pekerjaan ini dan semua poinnya. Tidak dapat dibatalkan.';

  @override
  String get role => 'Peran';

  @override
  String get company => 'Perusahaan';

  @override
  String get startDate => 'Tanggal mulai';

  @override
  String get endDate => 'Tanggal akhir';

  @override
  String get monthYearHint => 'Bulan/tahun';

  @override
  String get monthYearOrPresentHint => 'Bulan/tahun atau Sekarang';

  @override
  String bulletNumber(int number) {
    return 'Poin $number';
  }

  @override
  String get removeBulletTitle => 'Hapus poin?';

  @override
  String get removeBulletFromJob => 'Poin ini akan dihapus dari pekerjaan ini.';

  @override
  String get addExperience => 'Tambah pengalaman';

  @override
  String get educationSubtitle =>
      'Sertakan gelar, institusi, dan jangka waktu studi Anda.';

  @override
  String educationNumber(int number) {
    return 'Pendidikan $number';
  }

  @override
  String get moveEducationUp => 'Pindahkan pendidikan ke atas';

  @override
  String get moveEducationDown => 'Pindahkan pendidikan ke bawah';

  @override
  String get deleteEducationEntry => 'Hapus entri pendidikan';

  @override
  String get deleteEducationEntryTitle => 'Hapus entri pendidikan?';

  @override
  String get deleteEducationEntryMessage =>
      'Ini akan menghapus sekolah dan gelar ini dari resume Anda. Tidak dapat dibatalkan.';

  @override
  String get institution => 'Institusi';

  @override
  String get degree => 'Gelar';

  @override
  String get startYear => 'Tahun mulai';

  @override
  String get endYear => 'Tahun akhir';

  @override
  String get selectYear => 'Pilih tahun';

  @override
  String get marksScore => 'Nilai / skor';

  @override
  String get marksScoreHint => '8.6 IPK, 92, atau 780/800';

  @override
  String get addEducation => 'Tambah pendidikan';

  @override
  String get showScoreAsPercent => 'Tampilkan sebagai persen';

  @override
  String get skillsSubtitle =>
      'Tambahkan alat dan kata kunci khusus pekerjaan. Pilih daftar sederhana, atau kategorikan keterampilan di bawah judul (misalnya Bahasa, Alat).';

  @override
  String skillsCount(int count) {
    return '$count keterampilan';
  }

  @override
  String get simpleList => 'Daftar sederhana';

  @override
  String get categorised => 'Dikategorikan';

  @override
  String get addASkill => 'Tambah keterampilan';

  @override
  String get addSkillHelper =>
      'Ketik untuk melihat saran atau tambahkan keterampilan Anda sendiri';

  @override
  String get categoryHint => 'Bahasa pemrograman, Alat, Framework, dll.';

  @override
  String get moveCategoryUp => 'Pindahkan kategori ke atas';

  @override
  String get moveCategoryDown => 'Pindahkan kategori ke bawah';

  @override
  String get removeCategory => 'Hapus kategori';

  @override
  String get deleteCategoryTitle => 'Hapus kategori?';

  @override
  String get deleteCategoryMessage =>
      'Ini akan menghapus kategori ini dan semua keterampilannya. Tidak dapat dibatalkan.';

  @override
  String get addCategory => 'Tambah kategori';

  @override
  String get projectsSubtitle =>
      'Tampilkan proyek sampingan, peluncuran produk, atau karya portofolio dengan hasil yang jelas.';

  @override
  String projectNumber(int number) {
    return 'Proyek $number';
  }

  @override
  String get moveProjectUp => 'Pindahkan proyek ke atas';

  @override
  String get moveProjectDown => 'Pindahkan proyek ke bawah';

  @override
  String get deleteProject => 'Hapus proyek';

  @override
  String get deleteProjectTitle => 'Hapus proyek?';

  @override
  String get deleteProjectMessage =>
      'Ini akan menghapus proyek ini dan semua poinnya. Tidak dapat dibatalkan.';

  @override
  String get projectTitle => 'Judul proyek';

  @override
  String get enterBulletPoint => 'Masukkan poin';

  @override
  String get removeBulletFromProject =>
      'Poin ini akan dihapus dari proyek ini.';

  @override
  String get addProject => 'Tambah proyek';

  @override
  String get customSectionProjectsSubtitle =>
      'Tambahkan entri dengan judul dan poin, seperti bagian Proyek.';

  @override
  String get removeSection => 'Hapus bagian';

  @override
  String get bulletPoints => 'Poin';

  @override
  String get customSectionSummaryHint =>
      'Tulis bagian ini sebagai paragraf singkat untuk resume Anda.';

  @override
  String entryNumber(int number) {
    return 'Entri $number';
  }

  @override
  String get moveEntryUp => 'Pindahkan entri ke atas';

  @override
  String get moveEntryDown => 'Pindahkan entri ke bawah';

  @override
  String get deleteEntry => 'Hapus entri';

  @override
  String get deleteEntryTitle => 'Hapus entri?';

  @override
  String get deleteEntryMessage =>
      'Ini akan menghapus entri ini dan semua poinnya. Tidak dapat dibatalkan.';

  @override
  String get removeBulletFromEntry => 'Poin ini akan dihapus dari entri ini.';

  @override
  String get addEntry => 'Tambah entri';

  @override
  String get livePreview => 'Pratinjau langsung';

  @override
  String get exportActions => 'Tindakan ekspor';

  @override
  String get downloadPdf => 'Unduh PDF';

  @override
  String get shareResume => 'Bagikan resume';

  @override
  String get resumeScore => 'Skor resume';

  @override
  String atsCompatibilitySummary(int percent, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Kompatibilitas ATS $percent% dengan $count kesenjangan keterampilan yang hilang.',
      one:
          'Kompatibilitas ATS $percent% dengan 1 kesenjangan keterampilan yang hilang.',
    );
    return '$_temp0';
  }

  @override
  String get unableToOpenShareSheet =>
      'Tidak dapat membuka lembar berbagi saat ini.';

  @override
  String get chooseTemplate => 'Pilih templat';

  @override
  String get fontSize => 'Ukuran font';

  @override
  String get colorAndFont => 'Warna & Font';

  @override
  String get sharedFromResumeAi => 'Dibagikan dari ResumeAI';

  @override
  String get unableToLoadPdfPreview =>
      'Tidak dapat memuat pratinjau PDF saat ini.';

  @override
  String get shareFormatPdf => 'PDF';

  @override
  String get shareFormatDocx => 'DOCX';

  @override
  String get coverLetterHeading => 'Surat lamaran';

  @override
  String get coverLetterEditorIntro =>
      'Halaman ini membuat draf surat lamaran dari detail di bawah. Tambahkan nama perusahaan, nama posisi, satu atau lebih keterampilan yang ingin ditonjolkan, dan bahasa, lalu ketuk Buat surat lamaran untuk membuka draf lengkap di layar berikutnya.';

  @override
  String get companyName => 'Nama perusahaan';

  @override
  String get jobPositionName => 'Nama posisi pekerjaan';

  @override
  String get skillToHighlight => 'Keterampilan yang ditonjolkan';

  @override
  String get creatingEllipsis => 'Membuat...';

  @override
  String get createCoverLetter => 'Buat surat lamaran';

  @override
  String get coverLetterContentHeading => 'Isi surat lamaran';

  @override
  String get coverLetterContentIntro =>
      'Draf surat lamaran Anda sudah siap. Tinjau isi lengkap di bawah, edit apa pun yang Anda inginkan, dan perubahan Anda akan disimpan secara otomatis.';

  @override
  String get regenerate => 'Buat ulang';

  @override
  String get coverLetterContentHint =>
      'Surat lamaran yang dibuat akan muncul di sini.';

  @override
  String get clLangEnglish => 'Inggris (English)';

  @override
  String get clLangArabic => 'Arab (العربية)';

  @override
  String get clLangBengali => 'Bengali (বাংলা)';

  @override
  String get clLangChinese => 'Cina, Mandarin (中文)';

  @override
  String get clLangDutch => 'Belanda (Nederlands)';

  @override
  String get clLangFrench => 'Prancis (Français)';

  @override
  String get clLangGerman => 'Jerman (Deutsch)';

  @override
  String get clLangHindi => 'Hindi (हिन्दी)';

  @override
  String get clLangItalian => 'Italia (Italiano)';

  @override
  String get clLangJapanese => 'Jepang (日本語)';

  @override
  String get clLangKorean => 'Korea (한국어)';

  @override
  String get clLangPortuguese => 'Portugis (Português)';

  @override
  String get clLangRussian => 'Rusia (Русский)';

  @override
  String get clLangSpanish => 'Spanyol (Español)';

  @override
  String get clLangTurkish => 'Turki (Türkçe)';

  @override
  String get clLangUrdu => 'Urdu (اردو)';

  @override
  String get clLangVietnamese => 'Vietnam (Tiếng Việt)';

  @override
  String get showPercentOnResume => 'Ketuk untuk menampilkan % di resume';

  @override
  String get hidePercentOnResume =>
      'Menampilkan % di resume — ketuk untuk menyembunyikan';

  @override
  String get removeBullet => 'Hapus poin';

  @override
  String get alreadySubscribedTitle => 'Sudah berlangganan';

  @override
  String youreOnPlan(String planLabel) {
    return 'Anda menggunakan $planLabel';
  }

  @override
  String get premiumPlanNotAvailableYet =>
      'Paket itu belum tersedia. Tarik untuk memuat ulang.';

  @override
  String get premiumCouldNotStartPurchase =>
      'Tidak dapat memulai pembelian. Coba lagi.';

  @override
  String get premiumSubscriptionRestored =>
      'Langganan Premium Anda telah dipulihkan.';

  @override
  String get premiumRestoredSuccessfully => 'Premium berhasil dipulihkan.';

  @override
  String get welcomeToResumeAppPro => 'Selamat datang di ResumeApp Pro!';

  @override
  String get jobsCreateResumeFirst =>
      'Buat resume terlebih dahulu untuk melihat lowongan.';

  @override
  String get jobsShowingLatestHint =>
      'Menampilkan lowongan terbaru dari 7 hari terakhir berdasarkan peran dan lokasi resume yang dipilih.';

  @override
  String get jobsNoneFound =>
      'Tidak ada lowongan untuk resume ini dalam 7 hari terakhir.';

  @override
  String get jobsLoadingMore => 'Memuat lowongan lainnya...';

  @override
  String get jobsScrollForMore => 'Gulir ke bawah untuk memuat lebih banyak';

  @override
  String get jobsLiveUnavailableBackup =>
      'Lowongan langsung tidak tersedia; menampilkan hasil cadangan.';

  @override
  String get couldNotOpenJobLink =>
      'Tidak dapat membuka tautan lowongan saat ini.';

  @override
  String get jobsPostedJustNow => 'baru saja';

  @override
  String jobsPostedHoursAgo(int hours) {
    return '${hours}j lalu';
  }

  @override
  String jobsPostedDaysAgo(int days) {
    return '${days}h lalu';
  }
}
