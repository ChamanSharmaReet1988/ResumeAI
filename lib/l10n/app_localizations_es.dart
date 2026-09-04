// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ResumeAI';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabTemplates => 'Plantillas';

  @override
  String get tabAiResume => 'CV con IA';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get appLanguage => 'Idioma de la app';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortugueseBrazil => 'Português (Brasil)';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get iCloudBackup => 'Copia de iCloud';

  @override
  String get googleDriveBackup => 'Copia de Google Drive';

  @override
  String get goPremium => 'Hazte Premium';

  @override
  String get youAreProUser => 'Eres usuario Pro';

  @override
  String get feedback => 'Comentarios';

  @override
  String get rateApp => 'Valorar la app';

  @override
  String get ratePromptTitle => '¿Te gusta ResumeAI?';

  @override
  String get ratePromptBody =>
      'Si la app te está ayudando, una valoración rápida nos ayuda mucho.';

  @override
  String get maybeLater => 'Ahora no';

  @override
  String get shareApp => 'Compartir la app';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get versionLabel => 'Versión';

  @override
  String versionWithBuild(String version, String build) {
    return 'Versión $version ($build)';
  }

  @override
  String get ok => 'OK';

  @override
  String get languageAffectsAppOnly =>
      'Solo cambia menús y textos de la app. El contenido de tu currículum no se modifica.';

  @override
  String get homeSegmentResume => 'Currículum';

  @override
  String get homeSegmentCoverLetter => 'Carta de presentación';

  @override
  String get noResumesYet => 'Aún no hay currículums';

  @override
  String get noResumesYetBody =>
      'Toca el botón de añadir para crear tu primer currículum.';

  @override
  String get noCoverLettersYet => 'Aún no hay cartas de presentación';

  @override
  String get noCoverLettersYetBody =>
      'Toca el botón de añadir para crear tu primera carta de presentación.';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionRename => 'Renombrar';

  @override
  String get actionDuplicate => 'Duplicar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get create => 'Crear';

  @override
  String get deleteResumeTitle => '¿Eliminar currículum?';

  @override
  String deleteResumeMessage(String title) {
    return '¿Eliminar \"$title\"? Esta acción no se puede deshacer.';
  }

  @override
  String get deleteCoverLetterTitle => '¿Eliminar carta de presentación?';

  @override
  String deleteCoverLetterMessage(String title) {
    return '¿Eliminar \"$title\"? Esta acción no se puede deshacer.';
  }

  @override
  String get renameResumeTitle => 'Renombrar currículum';

  @override
  String get duplicateResumeTitle => 'Duplicar currículum';

  @override
  String get resumeRenamed => 'Currículum renombrado.';

  @override
  String get resumeDuplicated => 'Currículum duplicado.';

  @override
  String get resumeTitle => 'Título del currículum';

  @override
  String get enterResumeTitle => 'Introduce el título del currículum';

  @override
  String get coverLetterTitle => 'Título de la carta de presentación';

  @override
  String updatedDate(String date) {
    return 'Actualizado $date';
  }

  @override
  String titleWithCopySuffix(String title) {
    return '$title (Copia)';
  }

  @override
  String get untitledResume => 'Currículum sin título';

  @override
  String get untitledCoverLetter => 'Carta de presentación sin título';

  @override
  String get save => 'Guardar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get restore => 'Restaurar';

  @override
  String get resumeAppPro => 'ResumeApp Pro';

  @override
  String get chooseAPlan => 'Elige un plan';

  @override
  String get premiumLegalAgreement =>
      'Al continuar, aceptas nuestros Términos de uso y Política de privacidad.';

  @override
  String get subscriptionFound => 'Suscripción encontrada';

  @override
  String get processingEllipsis => 'Procesando…';

  @override
  String get checkingYourSubscription => 'Comprobando tu suscripción…';

  @override
  String get completingYourPurchase => 'Completando tu compra…';

  @override
  String get restoringYourSubscription => 'Restaurando tu suscripción…';

  @override
  String get pleaseWaitDoNotClose => 'Espera. No cierres la app.';

  @override
  String get premiumWelcomeCongratulations => '¡Enhorabuena!';

  @override
  String premiumWelcomeBody(String planLabel, String backup) {
    return 'ResumeApp Pro está activo en tu $planLabel. Las plantillas Premium y $backup ya están desbloqueados.';
  }

  @override
  String get premiumBenefitUnlockLayouts =>
      'Desbloquea AI Resume: crea y mejora currículums ATS con IA';

  @override
  String get premiumBenefitBackupIcloud =>
      'Haz copia de seguridad y sincroniza currículums con iCloud';

  @override
  String get premiumBenefitBackupGoogleDrive =>
      'Haz copia de seguridad y sincroniza currículums con Google Drive';

  @override
  String get premiumUpcomingUpdateBadge =>
      'Próximamente en la siguiente actualización';

  @override
  String get premiumUpcomingUpdateMessage =>
      'Nuevos diseños de currículum y plantillas modernas, incluidas con Pro.';

  @override
  String get planWeekly => 'Semanal';

  @override
  String get planMonthly => 'Mensual';

  @override
  String get planYearly => 'Anual';

  @override
  String get planPro => 'Pro';

  @override
  String get planSubtitleWeekly => 'Acceso a corto plazo';

  @override
  String get planSubtitleMonthly => 'Paga mes a mes';

  @override
  String get planSubtitleYearly => 'Mejor valor';

  @override
  String planLabelNamed(String title) {
    return 'Plan $title';
  }

  @override
  String savePercentWithYearlyBilling(int percent) {
    return 'Ahorra un $percent% con facturación anual';
  }

  @override
  String get priceUnavailable => '—';

  @override
  String get storeAccountGoogle => 'cuenta de Google';

  @override
  String get storeAccountApple => 'Apple ID';

  @override
  String get alreadySubscribedDebugOverride =>
      'La anulación Pro de desarrollador está activada. Todas las funciones Pro están desbloqueadas para pruebas en este dispositivo.';

  @override
  String alreadySubscribedWeekly(String backup) {
    return 'Tienes una suscripción semanal activa. Todas las plantillas Pro, $backup y las funciones premium están incluidas.';
  }

  @override
  String alreadySubscribedMonthly(String backup) {
    return 'Tienes una suscripción mensual activa. Todas las plantillas Pro, $backup y las funciones premium están incluidas.';
  }

  @override
  String alreadySubscribedYearly(String backup) {
    return 'Tienes una suscripción anual activa. Todas las plantillas Pro, $backup y las funciones premium están incluidas.';
  }

  @override
  String get alreadySubscribedGeneric =>
      'Tienes una suscripción activa de ResumeApp Pro. Todas las funciones premium están incluidas en tu plan.';

  @override
  String restoreInsteadWeekly(String account) {
    return 'Se encontró una suscripción semanal para esta $account. Usa Restaurar para activarla en este dispositivo en lugar de comprar de nuevo.';
  }

  @override
  String restoreInsteadMonthly(String account) {
    return 'Se encontró una suscripción mensual para esta $account. Usa Restaurar para activarla en este dispositivo en lugar de comprar de nuevo.';
  }

  @override
  String restoreInsteadYearly(String account) {
    return 'Se encontró una suscripción anual para esta $account. Usa Restaurar para activarla en este dispositivo en lugar de comprar de nuevo.';
  }

  @override
  String restoreInsteadGeneric(String account) {
    return 'Se encontró una suscripción activa de ResumeApp Pro para esta $account. Usa Restaurar para activarla en este dispositivo en lugar de comprar de nuevo.';
  }

  @override
  String get premiumPurchaseFailed =>
      'No pudimos completar tu compra. Inténtalo de nuevo.';

  @override
  String get premiumRestoreFailed =>
      'No pudimos restaurar tu suscripción. Inténtalo de nuevo.';

  @override
  String get noSubscriptionToRestoreGoogle =>
      'No se encontró ninguna suscripción activa para esta cuenta de Google.';

  @override
  String get noSubscriptionToRestoreApple =>
      'No se encontró ninguna suscripción activa para este Apple ID.';

  @override
  String get premiumStoreUnavailable =>
      'Las compras no están disponibles en este dispositivo ahora mismo.';

  @override
  String get premiumConnectFailedGoogle =>
      'No pudimos conectar con Google Play. Inténtalo más tarde.';

  @override
  String get premiumConnectFailedApple =>
      'No pudimos conectar con el App Store. Inténtalo más tarde.';

  @override
  String get premiumVerifyFailed =>
      'No pudimos verificar tu suscripción. Inténtalo de nuevo.';

  @override
  String get premiumProductsUnavailable =>
      'Los planes de suscripción no están disponibles ahora. Inténtalo más tarde.';

  @override
  String get premiumPurchaseCanceled => 'Compra cancelada.';

  @override
  String get hideKeyboard => 'Ocultar teclado';

  @override
  String get selectResumeWithContentFirst =>
      'Selecciona primero un currículum guardado con contenido.';

  @override
  String get aiAtsIntro =>
      'Selecciona un currículum y la IA creará una versión optimizada para ATS. Añade tu clave API en Ajustes para mejores resultados, o usa la IA integrada. La descripción del puesto es opcional. Pulsa Crear de nuevo para refinar.';

  @override
  String get aiEngineUsingCloudApi => 'Usando tu clave API (IA en la nube)';

  @override
  String get aiEngineUsingAppleIntelligence =>
      'Usando Apple Intelligence (en el dispositivo)';

  @override
  String get aiEngineUsingBuiltIn => 'Usando la IA integrada';

  @override
  String get aiApiKeySettingsTitle => 'Clave API de IA';

  @override
  String get aiApiKeySettingsIntro =>
      'Añade tu propia clave API de OpenAI o Gemini para generar currículums ATS más potentes. La clave permanece en este dispositivo. Si no hay clave, el iPhone usa Apple Intelligence cuando está disponible; si no, la IA integrada.';

  @override
  String aiApiKeyConfiguredSubtitle(String provider) {
    return 'Guardada: $provider';
  }

  @override
  String get aiApiKeyMissingSubtitle =>
      'Opcional: usa tu propia clave de OpenAI o Gemini';

  @override
  String get aiProviderLabel => 'Proveedor';

  @override
  String get aiApiKeyLabel => 'Clave API';

  @override
  String get aiApiKeyHint => 'Pega tu clave API secreta';

  @override
  String get aiModelOptionalLabel => 'Modelo (opcional)';

  @override
  String get aiApiKeyRequired => 'Introduce primero una clave API.';

  @override
  String get aiApiKeySaved => 'Clave API guardada en este dispositivo.';

  @override
  String get aiApiKeyRemoved => 'Clave API eliminada.';

  @override
  String get aiApiKeyTestSuccess => 'La clave API funciona.';

  @override
  String aiApiKeySavedMasked(String maskedKey) {
    return 'Clave guardada: $maskedKey';
  }

  @override
  String get saveAiApiKey => 'Guardar clave API';

  @override
  String get testAiApiKey => 'Probar clave API';

  @override
  String get removeAiApiKey => 'Eliminar clave API';

  @override
  String get noResumeAvailable => 'No hay ningún currículum disponible ahora.';

  @override
  String get createResumeThenGenerateAts =>
      'Crea primero un currículum y vuelve aquí para generar una versión ATS.';

  @override
  String get selectResume => 'Seleccionar currículum';

  @override
  String get jobDescriptionOptional => 'Descripción del puesto (opcional)';

  @override
  String get jobDescriptionHint =>
      'Pega una oferta de empleo para adaptar el currículum ATS, o déjalo en blanco.';

  @override
  String get createAtsResume => 'Crear currículum ATS';

  @override
  String furtherOptimizeAtsPass(int pass) {
    return 'Optimizar más el ATS (pase $pass)';
  }

  @override
  String get appliedChanges => 'Cambios aplicados';

  @override
  String get showAtsResume => 'Mostrar currículum ATS';

  @override
  String get saveOptimizedResume => 'Guardar currículum optimizado';

  @override
  String saveOptimizedResumePrompt(String sourceTitle) {
    return '¿Quieres guardarlo como una copia nueva o reemplazar \"$sourceTitle\"?';
  }

  @override
  String get newCopy => 'Copia nueva';

  @override
  String get existingResume => 'Currículum existente';

  @override
  String get resumePreview => 'Vista previa del currículum';

  @override
  String get highlightedSummaryChange => 'Cambio de resumen resaltado';

  @override
  String highlightedSkillsLabel(String skills) {
    return 'Habilidades resaltadas: $skills';
  }

  @override
  String get atsTitleSuffix => ' (ATS)';

  @override
  String get optimizedTitleSuffix => ' (Optimizado)';

  @override
  String get professionalResumes => 'Currículums profesionales';

  @override
  String get atsResumes => 'Currículums ATS';

  @override
  String get useTemplate => 'Usar plantilla';

  @override
  String get templateCorporate => 'Corporativo';

  @override
  String get templateCorporateCaption =>
      'Banda superior llamativa con secciones profesionales compactas.';

  @override
  String get templateProfileSidebar => 'Barra lateral de perfil';

  @override
  String get templateProfileSidebarCaption =>
      'Diseño centrado en el perfil con anclas visuales claras.';

  @override
  String get templateClassicSidebar => 'Barra lateral clásica';

  @override
  String get templateClassicSidebarCaption =>
      'Carril izquierdo suave con identidad con foto y secciones estructuradas.';

  @override
  String get templateAccentStrip => 'Franja de acento';

  @override
  String get templateAccentStripCaption =>
      'Franja izquierda llamativa con nombre grande y secciones limpias.';

  @override
  String get templateStructuredAts => 'ATS estructurado';

  @override
  String get templateStructuredAtsCaption =>
      'Bandas de sección grises y encabezado centrado para parsers.';

  @override
  String get templateLatexClassicAts => 'ATS clásico LaTeX';

  @override
  String get templateLatexClassicAtsCaption =>
      'Secciones con reglas al estilo de currículums LaTeX clásicos.';

  @override
  String get templateModernFlowAts => 'ATS flujo moderno';

  @override
  String get templateModernFlowAtsCaption =>
      'Fila de contacto centrada con secuencia lógica de secciones.';

  @override
  String get templateExecutiveAts => 'ATS ejecutivo';

  @override
  String get templateExecutiveAtsCaption =>
      'Encabezados en mayúsculas y habilidades en dos columnas.';

  @override
  String get templateCenterClassicAts => 'ATS clásico centrado';

  @override
  String get templateCenterClassicAtsCaption =>
      'Nombre centrado, eslogan con barras y secciones de una columna.';

  @override
  String get templateProfessionalBlueAts => 'ATS azul profesional';

  @override
  String get templateProfessionalBlueAtsCaption =>
      'Encabezados en azul con contacto alineado a la derecha y cuadrícula de habilidades.';

  @override
  String get templateClassicCvAts => 'ATS CV clásico';

  @override
  String get templateClassicCvAtsCaption =>
      'Nombre centrado, datos personales y secciones con etiquetas a la izquierda.';

  @override
  String get templateExecutiveNote => 'Nota ejecutiva';

  @override
  String get templateExecutiveNoteCaption =>
      'Carta de presentación profesional con un bloque de encabezado destacado.';

  @override
  String get templateMinimalLetter => 'Carta minimalista';

  @override
  String get templateMinimalLetterCaption =>
      'Encabezado centrado con espaciado amplio y cuerpo alineado a la izquierda.';

  @override
  String get templateMintLetter => 'Carta menta';

  @override
  String get templateMintLetterCaption =>
      'Nombre grande, fondo menta suave y cuerpo moderno y limpio.';

  @override
  String get templateClassicBusiness => 'Negocios clásico';

  @override
  String get templateClassicBusinessCaption =>
      'Carta comercial tradicional: fecha, destinatario y cuerpo alineado a la izquierda.';

  @override
  String get autoSync => 'Sincronización automática';

  @override
  String get sync => 'Sincronizar';

  @override
  String get download => 'Descargar';

  @override
  String get alreadyDownloaded => 'Ya descargado';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get syncToIcloud => 'Sincronizar con iCloud';

  @override
  String get syncToGoogleDrive => 'Sincronizar con Google Drive';

  @override
  String get iCloudUnavailable =>
      'iCloud no está disponible en este dispositivo ahora. Asegúrate de que iCloud Drive esté activado y de haber iniciado sesión con el Apple ID correcto.';

  @override
  String get noItemsInIcloud =>
      'Aún no hay currículums ni cartas de presentación en iCloud.';

  @override
  String get noItemsOnDrive =>
      'Aún no hay currículums ni cartas de presentación en Drive.';

  @override
  String get resumesInIcloud => 'Currículums en iCloud';

  @override
  String get coverLettersInIcloud => 'Cartas de presentación en iCloud';

  @override
  String get resumesInGoogleDrive => 'Currículums en Google Drive';

  @override
  String get coverLettersInGoogleDrive =>
      'Cartas de presentación en Google Drive';

  @override
  String get googleDriveBackupIntro =>
      'Haz una copia de seguridad de currículums y cartas de presentación en una carpeta ResumeApp de tu Google Drive. Solo se pueden acceder a los archivos creados por esta app.';

  @override
  String get googleDrivePermissionHint =>
      'En la página de Google que se abre a continuación, en \"Seleccionar a qué puede acceder ResumeApp\", marca la casilla junto a Google Drive (archivos usados con esta app) y pulsa Continuar. Sin esa casilla, la copia de seguridad en Drive no puede funcionar.';

  @override
  String get googleDriveLooksLikeThis => 'Se ve así:';

  @override
  String get googleDrivePermissionExampleSemantics =>
      'Pantalla de ejemplo de Google: Seleccionar a qué puede acceder ResumeApp, con la fila de Google Drive y la casilla.';

  @override
  String get noLocalItemsToSync =>
      'No hay currículums ni cartas de presentación locales para sincronizar.';

  @override
  String get everythingUpToDateIcloud => 'Todo ya está actualizado en iCloud.';

  @override
  String get everythingUpToDateGoogleDrive =>
      'Todo ya está actualizado en Google Drive.';

  @override
  String couldNotLoadIcloudItems(String error) {
    return 'No se pudieron cargar los elementos de iCloud: $error';
  }

  @override
  String couldNotSyncToIcloud(String error) {
    return 'No se pudo sincronizar con iCloud: $error';
  }

  @override
  String couldNotDeleteFromIcloud(String error) {
    return 'No se pudo eliminar de iCloud: $error';
  }

  @override
  String couldNotDownloadWithError(String error) {
    return 'No se pudo descargar: $error';
  }

  @override
  String syncedSummaryToIcloud(String summary) {
    return 'Se sincronizó $summary con iCloud.';
  }

  @override
  String syncedSummaryWithSkippedIcloud(String summary, String skipped) {
    return 'Se sincronizó $summary. $skipped sin modificar.';
  }

  @override
  String syncedSummaryToGoogleDrive(String summary) {
    return 'Se sincronizó $summary con Google Drive.';
  }

  @override
  String syncedSummaryWithSkippedDrive(String summary, String skipped) {
    return 'Se sincronizó $summary. $skipped sin modificar.';
  }

  @override
  String resumeCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count currículums',
      one: '1 currículum',
    );
    return '$_temp0';
  }

  @override
  String coverLetterCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas de presentación',
      one: '1 carta de presentación',
    );
    return '$_temp0';
  }

  @override
  String newerIcloudItemsUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos más recientes de iCloud',
      one: '1 elemento más reciente de iCloud',
    );
    return '$_temp0';
  }

  @override
  String newerDriveItemsUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos más recientes de Drive',
      one: '1 elemento más reciente de Drive',
    );
    return '$_temp0';
  }

  @override
  String listJoinAnd(String first, String second) {
    return '$first y $second';
  }

  @override
  String get deleteFromIcloudTitle => '¿Eliminar de iCloud?';

  @override
  String deleteFromIcloudMessage(String title) {
    return '¿Quitar \"$title\" de iCloud? Esto no eliminará la copia en este dispositivo.';
  }

  @override
  String get deleteFromIcloud => 'Eliminar de iCloud';

  @override
  String deleteDocumentType(String type) {
    return 'Eliminar $type';
  }

  @override
  String get documentTypeResume => 'currículum';

  @override
  String get documentTypeCoverLetter => 'carta de presentación';

  @override
  String removedFromIcloud(String title) {
    return 'Se eliminó $title de iCloud.';
  }

  @override
  String downloadedTitle(String title) {
    return 'Se descargó $title.';
  }

  @override
  String get googleSignInUnavailable =>
      'El inicio de sesión de Google no está disponible en este dispositivo.';

  @override
  String get couldNotSignInGoogleDrive =>
      'No se pudo iniciar sesión en Google Drive ahora. Inténtalo de nuevo.';

  @override
  String get couldNotLoadGoogleDriveItems =>
      'No se pudieron cargar tus elementos de Google Drive ahora. Inténtalo de nuevo.';

  @override
  String get couldNotSyncGoogleDrive =>
      'No se pudo sincronizar con Google Drive ahora. Inténtalo de nuevo.';

  @override
  String get couldNotDownloadFromGoogleDrive =>
      'No se pudo descargar este elemento de Google Drive. Inténtalo de nuevo.';

  @override
  String get couldNotRemoveFromGoogleDrive =>
      'No se pudo quitar este elemento de Google Drive. Inténtalo de nuevo.';

  @override
  String get removeFromGoogleDriveTitle => '¿Quitar de Google Drive?';

  @override
  String removeFromGoogleDriveMessage(String title) {
    return '¿Quitar \"$title\" de Google Drive? Esto no eliminará la copia en este dispositivo.';
  }

  @override
  String get removeFromGoogleDrive => 'Quitar de Google Drive';

  @override
  String removeDocumentType(String type) {
    return 'Quitar $type';
  }

  @override
  String removedFromGoogleDrive(String title) {
    return 'Se quitó $title de Google Drive.';
  }

  @override
  String get googleSignInNotConfigured =>
      'Google Sign-In no está configurado para esta compilación. Añade tus huellas SHA-1 de depuración y publicación en Firebase (consulta android/GOOGLE_SIGN_IN_SETUP.md), vuelve a descargar google-services.json y recompila.';

  @override
  String get couldNotOpenGoogleSignIn =>
      'No se pudo abrir la pantalla de inicio de sesión de Google. Inténtalo de nuevo.';

  @override
  String get googleSignInInterrupted =>
      'El inicio de sesión de Google se interrumpió. Inténtalo de nuevo.';

  @override
  String get unableToLoadPage => 'No se puede cargar la página';

  @override
  String get couldNotLoadThisPage => 'No se pudo cargar esta página.';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get shareAppSubject => 'ResumeApp';

  @override
  String shareAppMessage(String url) {
    return 'Prueba ResumeAI para crear, optimizar y compartir currículums profesionales. Descárgala aquí: $url';
  }

  @override
  String get feedbackEmailSubject => 'Comentarios sobre ResumeApp';

  @override
  String get noMailAppFound =>
      'No se encontró ninguna app de correo. Configura una app de correo.';

  @override
  String get couldNotOpenMailApp =>
      'No se pudo abrir la app de correo. Inténtalo de nuevo.';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace ahora.';

  @override
  String get add => 'Añadir';

  @override
  String get back => 'Atrás';

  @override
  String get done => 'Listo';

  @override
  String get hide => 'Ocultar';

  @override
  String get remove => 'Eliminar';

  @override
  String get preview => 'Vista previa';

  @override
  String get share => 'Compartir';

  @override
  String get print => 'Imprimir';

  @override
  String get dismiss => 'Descartar';

  @override
  String get template => 'Plantilla';

  @override
  String get color => 'Color';

  @override
  String get title => 'Título';

  @override
  String get type => 'Tipo';

  @override
  String get year => 'Año';

  @override
  String get summary => 'Resumen';

  @override
  String get category => 'Categoría';

  @override
  String get present => 'Actualidad';

  @override
  String get language => 'Idioma';

  @override
  String get sectionPersonalInformation => 'Información personal';

  @override
  String get sectionWorkExperience => 'Experiencia laboral';

  @override
  String get sectionEducation => 'Educación';

  @override
  String get sectionSkills => 'Habilidades';

  @override
  String get sectionProjects => 'Proyectos';

  @override
  String get personalInformationTitle => 'Información personal';

  @override
  String get workExperienceTitle => 'Experiencia laboral';

  @override
  String categoryNumber(int number) {
    return 'Categoría $number';
  }

  @override
  String pdfSavedTo(String path) {
    return 'PDF guardado en $path';
  }

  @override
  String get unableToGenerateSummary =>
      'No se pudo generar un resumen profesional ahora.';

  @override
  String get summaryUpdated => 'Resumen actualizado';

  @override
  String get summaryAdded => 'Resumen añadido';

  @override
  String get skillAlreadyInList => 'Esta habilidad ya está en tu lista.';

  @override
  String get addBulletPoint => 'Añadir viñeta';

  @override
  String get appearsFirstOnYourResume => 'Aparece primero en tu currículum';

  @override
  String appearsOnYourResumeAt(int position) {
    return 'Aparece en la posición $position de tu currículum';
  }

  @override
  String get hideFromResumeTitle => '¿Ocultar del currículum?';

  @override
  String hideFromResumeMessage(String sectionName) {
    return '$sectionName no se mostrará en tu currículum ni en los PDF exportados. Puedes volver a mostrarlo en cualquier momento con el botón junto al título de la sección.';
  }

  @override
  String get hideFromResume => 'Ocultar del currículum';

  @override
  String get showOnResume => 'Mostrar en el currículum';

  @override
  String get chooseMonthAndYear => 'Elegir mes y año';

  @override
  String get clearDate => 'Borrar fecha';

  @override
  String get selectEndMonthAndYear => 'Seleccionar mes y año de fin';

  @override
  String get selectStartMonthAndYear => 'Seleccionar mes y año de inicio';

  @override
  String get selectEndYear => 'Seleccionar año de fin';

  @override
  String get selectStartYear => 'Seleccionar año de inicio';

  @override
  String get newSection => 'Nueva sección';

  @override
  String get newSectionTitleHint => 'Certificaciones, Idiomas, Premios…';

  @override
  String get sectionTypeNormal => 'Normal';

  @override
  String get sectionTypeNormalSubtitle => 'Resumen o viñetas';

  @override
  String get sectionTypeAdvance => 'Avanzado';

  @override
  String get sectionTypeAdvanceSubtitle =>
      'Entradas estilo proyecto con título y viñetas';

  @override
  String get removeSectionTitle => '¿Eliminar sección?';

  @override
  String get removeSectionMessage =>
      'Esta sección se eliminará de tu currículum. Puedes añadir una nueva sección personalizada con Añadir en cualquier momento.';

  @override
  String get unableToPickImage => 'No se pudo elegir una imagen ahora.';

  @override
  String get camera => 'Cámara';

  @override
  String get library => 'Biblioteca';

  @override
  String get profilePhoto => 'Foto de perfil';

  @override
  String get tapToChangePhoto => 'Toca para cambiar la foto';

  @override
  String get previousField => 'Campo anterior';

  @override
  String get nextField => 'Campo siguiente';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get targetJobTitle => 'Puesto objetivo';

  @override
  String get githubLink => 'Enlace de GitHub';

  @override
  String get linkedinLink => 'Enlace de LinkedIn';

  @override
  String get email => 'Correo electrónico';

  @override
  String get phoneNumber => 'Número de teléfono';

  @override
  String get location => 'Ubicación';

  @override
  String get websiteOrPortfolio => 'Sitio web o portafolio';

  @override
  String get professionalSummary => 'Resumen profesional';

  @override
  String get personalInformationSubtitle =>
      'Empieza con tu identidad, datos de contacto, puesto objetivo y un breve resumen de posicionamiento.';

  @override
  String get suggestSummary => 'Sugerir resumen';

  @override
  String get resumeOrder => 'Orden del currículum';

  @override
  String get resumeOrderBody =>
      'Las entradas permanecen en este orden. Usa las flechas para mover tu puesto más fuerte arriba.';

  @override
  String experienceNumber(int number) {
    return 'Experiencia $number';
  }

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get deleteExperience => 'Eliminar experiencia';

  @override
  String get deleteWorkExperienceTitle => '¿Eliminar experiencia laboral?';

  @override
  String get deleteWorkExperienceMessage =>
      'Esto eliminará este trabajo y todas sus viñetas. No se puede deshacer.';

  @override
  String get role => 'Puesto';

  @override
  String get company => 'Empresa';

  @override
  String get startDate => 'Fecha de inicio';

  @override
  String get endDate => 'Fecha de fin';

  @override
  String get monthYearHint => 'Mes/año';

  @override
  String get monthYearOrPresentHint => 'Mes/año o Actualidad';

  @override
  String bulletNumber(int number) {
    return 'Viñeta $number';
  }

  @override
  String get removeBulletTitle => '¿Eliminar viñeta?';

  @override
  String get removeBulletFromJob => 'Esta viñeta se eliminará de este trabajo.';

  @override
  String get addExperience => 'Añadir experiencia';

  @override
  String get educationSubtitle =>
      'Incluye tu título, institución y período de estudios.';

  @override
  String educationNumber(int number) {
    return 'Educación $number';
  }

  @override
  String get moveEducationUp => 'Subir educación';

  @override
  String get moveEducationDown => 'Bajar educación';

  @override
  String get deleteEducationEntry => 'Eliminar entrada de educación';

  @override
  String get deleteEducationEntryTitle => '¿Eliminar entrada de educación?';

  @override
  String get deleteEducationEntryMessage =>
      'Esto eliminará esta escuela y título de tu currículum. No se puede deshacer.';

  @override
  String get institution => 'Institución';

  @override
  String get degree => 'Título';

  @override
  String get startYear => 'Año de inicio';

  @override
  String get endYear => 'Año de fin';

  @override
  String get selectYear => 'Seleccionar año';

  @override
  String get marksScore => 'Notas / puntuación';

  @override
  String get marksScoreHint => '8.6 CGPA, 92 o 780/800';

  @override
  String get addEducation => 'Añadir educación';

  @override
  String get showScoreAsPercent => 'Mostrar como porcentaje';

  @override
  String get skillsSubtitle =>
      'Añade herramientas y palabras clave del puesto. Elige una lista simple o categoriza las habilidades bajo encabezados (por ejemplo Idiomas, Herramientas).';

  @override
  String skillsCount(int count) {
    return '$count habilidades';
  }

  @override
  String get simpleList => 'Lista simple';

  @override
  String get categorised => 'Categorizadas';

  @override
  String get addASkill => 'Añadir una habilidad';

  @override
  String get addSkillHelper =>
      'Escribe para ver sugerencias o añade tu propia habilidad';

  @override
  String get categoryHint =>
      'Lenguajes de programación, Herramientas, Frameworks, etc.';

  @override
  String get moveCategoryUp => 'Subir categoría';

  @override
  String get moveCategoryDown => 'Bajar categoría';

  @override
  String get removeCategory => 'Eliminar categoría';

  @override
  String get deleteCategoryTitle => '¿Eliminar categoría?';

  @override
  String get deleteCategoryMessage =>
      'Esto eliminará esta categoría y todas sus habilidades. No se puede deshacer.';

  @override
  String get addCategory => 'Añadir categoría';

  @override
  String get projectsSubtitle =>
      'Destaca proyectos personales, lanzamientos o trabajos de portafolio con resultados claros.';

  @override
  String projectNumber(int number) {
    return 'Proyecto $number';
  }

  @override
  String get moveProjectUp => 'Subir proyecto';

  @override
  String get moveProjectDown => 'Bajar proyecto';

  @override
  String get deleteProject => 'Eliminar proyecto';

  @override
  String get deleteProjectTitle => '¿Eliminar proyecto?';

  @override
  String get deleteProjectMessage =>
      'Esto eliminará este proyecto y todas sus viñetas. No se puede deshacer.';

  @override
  String get projectTitle => 'Título del proyecto';

  @override
  String get enterBulletPoint => 'Escribe una viñeta';

  @override
  String get removeBulletFromProject =>
      'Esta viñeta se eliminará de este proyecto.';

  @override
  String get addProject => 'Añadir proyecto';

  @override
  String get customSectionProjectsSubtitle =>
      'Añade entradas con título y viñetas, como en la sección Proyectos.';

  @override
  String get removeSection => 'Eliminar sección';

  @override
  String get bulletPoints => 'Viñetas';

  @override
  String get customSectionSummaryHint =>
      'Escribe la sección como un párrafo corto para tu currículum.';

  @override
  String entryNumber(int number) {
    return 'Entrada $number';
  }

  @override
  String get moveEntryUp => 'Subir entrada';

  @override
  String get moveEntryDown => 'Bajar entrada';

  @override
  String get deleteEntry => 'Eliminar entrada';

  @override
  String get deleteEntryTitle => '¿Eliminar entrada?';

  @override
  String get deleteEntryMessage =>
      'Esto eliminará esta entrada y todas sus viñetas. No se puede deshacer.';

  @override
  String get removeBulletFromEntry =>
      'Esta viñeta se eliminará de esta entrada.';

  @override
  String get addEntry => 'Añadir entrada';

  @override
  String get livePreview => 'Vista previa en vivo';

  @override
  String get exportActions => 'Acciones de exportación';

  @override
  String get downloadPdf => 'Descargar PDF';

  @override
  String get shareResume => 'Compartir currículum';

  @override
  String get resumeScore => 'Puntuación del currículum';

  @override
  String atsCompatibilitySummary(int percent, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Compatibilidad ATS $percent% con $count brechas de habilidades faltantes.',
      one:
          'Compatibilidad ATS $percent% con 1 brecha de habilidades faltantes.',
    );
    return '$_temp0';
  }

  @override
  String get unableToOpenShareSheet =>
      'No se pudo abrir la hoja para compartir ahora.';

  @override
  String get chooseTemplate => 'Elegir plantilla';

  @override
  String get fontSize => 'Tamaño de fuente';

  @override
  String get colorAndFont => 'Color y fuente';

  @override
  String get sharedFromResumeAi => 'Compartido desde ResumeAI';

  @override
  String get unableToLoadPdfPreview =>
      'No se pudo cargar la vista previa del PDF ahora.';

  @override
  String get shareFormatPdf => 'PDF';

  @override
  String get shareFormatDocx => 'DOCX';

  @override
  String get coverLetterHeading => 'Carta de presentación';

  @override
  String get coverLetterEditorIntro =>
      'Esta página crea un borrador de carta de presentación con los datos siguientes. Añade el nombre de la empresa, el puesto, una o más habilidades a destacar y un idioma, y toca Crear carta de presentación para abrir el borrador completo en la siguiente pantalla.';

  @override
  String get companyName => 'Nombre de la empresa';

  @override
  String get jobPositionName => 'Nombre del puesto';

  @override
  String get skillToHighlight => 'Habilidad a destacar';

  @override
  String get creatingEllipsis => 'Creando...';

  @override
  String get createCoverLetter => 'Crear carta de presentación';

  @override
  String get coverLetterContentHeading => 'Contenido de la carta';

  @override
  String get coverLetterContentIntro =>
      'Tu borrador de carta está listo. Revisa el contenido completo abajo, edita lo que quieras y tus cambios se guardarán automáticamente.';

  @override
  String get regenerate => 'Regenerar';

  @override
  String get coverLetterContentHint => 'Tu carta generada aparecerá aquí.';

  @override
  String get clLangEnglish => 'Inglés (English)';

  @override
  String get clLangArabic => 'Árabe (العربية)';

  @override
  String get clLangBengali => 'Bengalí (বাংলা)';

  @override
  String get clLangChinese => 'Chino, mandarín (中文)';

  @override
  String get clLangDutch => 'Neerlandés (Nederlands)';

  @override
  String get clLangFrench => 'Francés (Français)';

  @override
  String get clLangGerman => 'Alemán (Deutsch)';

  @override
  String get clLangHindi => 'Hindi (हिन्दी)';

  @override
  String get clLangItalian => 'Italiano (Italiano)';

  @override
  String get clLangJapanese => 'Japonés (日本語)';

  @override
  String get clLangKorean => 'Coreano (한국어)';

  @override
  String get clLangPortuguese => 'Portugués (Português)';

  @override
  String get clLangRussian => 'Ruso (Русский)';

  @override
  String get clLangSpanish => 'Español (Español)';

  @override
  String get clLangTurkish => 'Turco (Türkçe)';

  @override
  String get clLangUrdu => 'Urdu (اردو)';

  @override
  String get clLangVietnamese => 'Vietnamita (Tiếng Việt)';

  @override
  String get showPercentOnResume => 'Toca para mostrar % en el currículum';

  @override
  String get hidePercentOnResume =>
      'Mostrando % en el currículum — toca para ocultar';

  @override
  String get removeBullet => 'Eliminar viñeta';

  @override
  String get alreadySubscribedTitle => 'Ya estás suscrito';

  @override
  String youreOnPlan(String planLabel) {
    return 'Estás en el $planLabel';
  }

  @override
  String get premiumPlanNotAvailableYet =>
      'Ese plan aún no está disponible. Desliza para actualizar.';

  @override
  String get premiumCouldNotStartPurchase =>
      'No se pudo iniciar la compra. Inténtalo de nuevo.';

  @override
  String get premiumSubscriptionRestored =>
      'Tu suscripción Premium se ha restaurado.';

  @override
  String get premiumRestoredSuccessfully => 'Premium restaurado correctamente.';

  @override
  String get welcomeToResumeAppPro => '¡Bienvenido a ResumeApp Pro!';

  @override
  String get jobsCreateResumeFirst =>
      'Crea un currículum primero para ver ofertas de empleo.';

  @override
  String get jobsShowingLatestHint =>
      'Mostrando las ofertas más recientes de los últimos 7 días según el puesto y la ubicación del currículum seleccionado.';

  @override
  String get jobsNoneFound =>
      'No se encontraron ofertas para este currículum en los últimos 7 días.';

  @override
  String get jobsLoadingMore => 'Cargando más ofertas...';

  @override
  String get jobsScrollForMore => 'Desplázate hacia abajo para cargar más';

  @override
  String get jobsLiveUnavailableBackup =>
      'Ofertas en vivo no disponibles; mostrando resultados de respaldo.';

  @override
  String get couldNotOpenJobLink =>
      'No se pudo abrir el enlace de la oferta ahora.';

  @override
  String get jobsPostedJustNow => 'ahora mismo';

  @override
  String jobsPostedHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String jobsPostedDaysAgo(int days) {
    return 'hace $days d';
  }
}
