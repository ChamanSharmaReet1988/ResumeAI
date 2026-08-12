// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ResumeAI';

  @override
  String get tabHome => 'Início';

  @override
  String get tabTemplates => 'Modelos';

  @override
  String get tabAiResume => 'Currículo IA';

  @override
  String get tabSettings => 'Configurações';

  @override
  String get appearance => 'Aparência';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get appLanguage => 'Idioma do app';

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortugueseBrazil => 'Português (Brasil)';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get iCloudBackup => 'Backup do iCloud';

  @override
  String get googleDriveBackup => 'Backup do Google Drive';

  @override
  String get goPremium => 'Assinar Premium';

  @override
  String get youAreProUser => 'Você é usuário Pro';

  @override
  String get feedback => 'Feedback';

  @override
  String get rateApp => 'Avaliar o app';

  @override
  String get shareApp => 'Compartilhar o app';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get termsOfUse => 'Termos de uso';

  @override
  String get versionLabel => 'Versão';

  @override
  String versionWithBuild(String version, String build) {
    return 'Versão $version ($build)';
  }

  @override
  String get ok => 'OK';

  @override
  String get languageAffectsAppOnly =>
      'Altera apenas menus e textos do app. O conteúdo do seu currículo permanece como escrito.';

  @override
  String get homeSegmentResume => 'Currículo';

  @override
  String get homeSegmentCoverLetter => 'Carta de apresentação';

  @override
  String get noResumesYet => 'Nenhum currículo ainda';

  @override
  String get noResumesYetBody =>
      'Toque no botão de adicionar para criar seu primeiro currículo.';

  @override
  String get noCoverLettersYet => 'Nenhuma carta de apresentação ainda';

  @override
  String get noCoverLettersYetBody =>
      'Toque no botão de adicionar para criar sua primeira carta de apresentação.';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionRename => 'Renomear';

  @override
  String get actionDuplicate => 'Duplicar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get create => 'Criar';

  @override
  String get deleteResumeTitle => 'Excluir currículo?';

  @override
  String deleteResumeMessage(String title) {
    return 'Excluir \"$title\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get deleteCoverLetterTitle => 'Excluir carta de apresentação?';

  @override
  String deleteCoverLetterMessage(String title) {
    return 'Excluir \"$title\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get renameResumeTitle => 'Renomear currículo';

  @override
  String get duplicateResumeTitle => 'Duplicar currículo';

  @override
  String get resumeRenamed => 'Currículo renomeado.';

  @override
  String get resumeDuplicated => 'Currículo duplicado.';

  @override
  String get resumeTitle => 'Título do currículo';

  @override
  String get enterResumeTitle => 'Digite o título do currículo';

  @override
  String get coverLetterTitle => 'Título da carta de apresentação';

  @override
  String updatedDate(String date) {
    return 'Atualizado em $date';
  }

  @override
  String titleWithCopySuffix(String title) {
    return '$title (Cópia)';
  }

  @override
  String get untitledResume => 'Currículo sem título';

  @override
  String get untitledCoverLetter => 'Carta de apresentação sem título';

  @override
  String get save => 'Salvar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get restore => 'Restaurar';

  @override
  String get resumeAppPro => 'ResumeApp Pro';

  @override
  String get chooseAPlan => 'Escolha um plano';

  @override
  String get premiumLegalAgreement =>
      'Ao continuar, você concorda com nossos Termos de uso e Política de privacidade.';

  @override
  String get subscriptionFound => 'Assinatura encontrada';

  @override
  String get processingEllipsis => 'Processando…';

  @override
  String get checkingYourSubscription => 'Verificando sua assinatura…';

  @override
  String get completingYourPurchase => 'Concluindo sua compra…';

  @override
  String get restoringYourSubscription => 'Restaurando sua assinatura…';

  @override
  String get pleaseWaitDoNotClose => 'Aguarde. Não feche o app.';

  @override
  String get premiumWelcomeCongratulations => 'Parabéns!';

  @override
  String premiumWelcomeBody(String planLabel, String backup) {
    return 'O ResumeApp Pro está ativo no seu $planLabel. Modelos Premium e $backup agora estão desbloqueados.';
  }

  @override
  String get premiumBenefitUnlockLayouts =>
      'Desbloqueie todos os layouts ATS e a criação ATS com IA';

  @override
  String get premiumBenefitBackupIcloud =>
      'Faça backup e sincronize currículos com o iCloud';

  @override
  String get premiumBenefitBackupGoogleDrive =>
      'Faça backup e sincronize currículos com o Google Drive';

  @override
  String get premiumUpcomingUpdateBadge => 'Em breve na próxima atualização';

  @override
  String get premiumUpcomingUpdateMessage =>
      'Novos layouts de currículo e modelos modernos, incluídos no Pro.';

  @override
  String get planWeekly => 'Semanal';

  @override
  String get planMonthly => 'Mensal';

  @override
  String get planYearly => 'Anual';

  @override
  String get planPro => 'Pro';

  @override
  String get planSubtitleWeekly => 'Acesso de curto prazo';

  @override
  String get planSubtitleMonthly => 'Pague mês a mês';

  @override
  String get planSubtitleYearly => 'Melhor custo-benefício';

  @override
  String planLabelNamed(String title) {
    return 'Plano $title';
  }

  @override
  String savePercentWithYearlyBilling(int percent) {
    return 'Economize $percent% com cobrança anual';
  }

  @override
  String get priceUnavailable => '—';

  @override
  String get storeAccountGoogle => 'conta do Google';

  @override
  String get storeAccountApple => 'Apple ID';

  @override
  String get alreadySubscribedDebugOverride =>
      'A substituição Pro de desenvolvedor está ativada. Todos os recursos Pro estão desbloqueados para testes neste dispositivo.';

  @override
  String alreadySubscribedWeekly(String backup) {
    return 'Você tem uma assinatura semanal ativa. Todos os modelos Pro, $backup e recursos premium estão incluídos.';
  }

  @override
  String alreadySubscribedMonthly(String backup) {
    return 'Você tem uma assinatura mensal ativa. Todos os modelos Pro, $backup e recursos premium estão incluídos.';
  }

  @override
  String alreadySubscribedYearly(String backup) {
    return 'Você tem uma assinatura anual ativa. Todos os modelos Pro, $backup e recursos premium estão incluídos.';
  }

  @override
  String get alreadySubscribedGeneric =>
      'Você tem uma assinatura ativa do ResumeApp Pro. Todos os recursos premium estão incluídos no seu plano.';

  @override
  String restoreInsteadWeekly(String account) {
    return 'Foi encontrada uma assinatura semanal para esta $account. Use Restaurar para ativá-la neste dispositivo em vez de comprar novamente.';
  }

  @override
  String restoreInsteadMonthly(String account) {
    return 'Foi encontrada uma assinatura mensal para esta $account. Use Restaurar para ativá-la neste dispositivo em vez de comprar novamente.';
  }

  @override
  String restoreInsteadYearly(String account) {
    return 'Foi encontrada uma assinatura anual para esta $account. Use Restaurar para ativá-la neste dispositivo em vez de comprar novamente.';
  }

  @override
  String restoreInsteadGeneric(String account) {
    return 'Foi encontrada uma assinatura ativa do ResumeApp Pro para esta $account. Use Restaurar para ativá-la neste dispositivo em vez de comprar novamente.';
  }

  @override
  String get premiumPurchaseFailed =>
      'Não foi possível concluir sua compra. Tente novamente.';

  @override
  String get premiumRestoreFailed =>
      'Não foi possível restaurar sua assinatura. Tente novamente.';

  @override
  String get noSubscriptionToRestoreGoogle =>
      'Nenhuma assinatura ativa foi encontrada para esta conta do Google.';

  @override
  String get noSubscriptionToRestoreApple =>
      'Nenhuma assinatura ativa foi encontrada para este Apple ID.';

  @override
  String get premiumStoreUnavailable =>
      'As compras não estão disponíveis neste dispositivo no momento.';

  @override
  String get premiumConnectFailedGoogle =>
      'Não foi possível conectar ao Google Play. Tente novamente mais tarde.';

  @override
  String get premiumConnectFailedApple =>
      'Não foi possível conectar à App Store. Tente novamente mais tarde.';

  @override
  String get premiumVerifyFailed =>
      'Não foi possível verificar sua assinatura. Tente novamente.';

  @override
  String get premiumProductsUnavailable =>
      'Os planos de assinatura não estão disponíveis agora. Tente novamente mais tarde.';

  @override
  String get premiumPurchaseCanceled => 'Compra cancelada.';

  @override
  String get hideKeyboard => 'Ocultar teclado';

  @override
  String get selectResumeWithContentFirst =>
      'Selecione primeiro um currículo salvo com conteúdo.';

  @override
  String get aiAtsIntro =>
      'Selecione um currículo e a IA criará um currículo ATS no estilo ChatGPT/Claude. Cada vez que você tocar em Criar novamente, a IA otimiza mais o mesmo rascunho ATS. A descrição da vaga é opcional.';

  @override
  String get aiEngineUsingCloudApi => 'Usando sua chave de API (IA na nuvem)';

  @override
  String get aiEngineUsingAppleIntelligence =>
      'Usando Apple Intelligence (no dispositivo)';

  @override
  String get aiEngineUsingBuiltIn => 'Usando a IA integrada';

  @override
  String get aiApiKeySettingsTitle => 'Chave de API de IA';

  @override
  String get aiApiKeySettingsIntro =>
      'Adicione sua própria chave de API OpenAI ou Gemini para gerar currículos ATS mais fortes. A chave fica neste dispositivo. Sem chave, o iPhone usa Apple Intelligence quando disponível; caso contrário, a IA integrada.';

  @override
  String aiApiKeyConfiguredSubtitle(String provider) {
    return 'Salva: $provider';
  }

  @override
  String get aiApiKeyMissingSubtitle =>
      'Opcional — use sua própria chave OpenAI ou Gemini';

  @override
  String get aiProviderLabel => 'Provedor';

  @override
  String get aiApiKeyLabel => 'Chave de API';

  @override
  String get aiApiKeyHint => 'Cole sua chave de API secreta';

  @override
  String get aiModelOptionalLabel => 'Modelo (opcional)';

  @override
  String get aiApiKeyRequired => 'Digite uma chave de API primeiro.';

  @override
  String get aiApiKeySaved => 'Chave de API salva neste dispositivo.';

  @override
  String get aiApiKeyRemoved => 'Chave de API removida.';

  @override
  String get aiApiKeyTestSuccess => 'A chave de API funciona.';

  @override
  String aiApiKeySavedMasked(String maskedKey) {
    return 'Chave salva: $maskedKey';
  }

  @override
  String get saveAiApiKey => 'Salvar chave de API';

  @override
  String get testAiApiKey => 'Testar chave de API';

  @override
  String get removeAiApiKey => 'Remover chave de API';

  @override
  String get noResumeAvailable => 'Nenhum currículo disponível no momento.';

  @override
  String get createResumeThenGenerateAts =>
      'Crie um currículo primeiro e volte aqui para gerar uma versão ATS.';

  @override
  String get selectResume => 'Selecionar currículo';

  @override
  String get jobDescriptionOptional => 'Descrição da vaga (opcional)';

  @override
  String get jobDescriptionHint =>
      'Cole um anúncio de vaga para adaptar o currículo ATS, ou deixe em branco.';

  @override
  String get createAtsResume => 'Criar currículo ATS';

  @override
  String furtherOptimizeAtsPass(int pass) {
    return 'Otimizar mais o ATS (passagem $pass)';
  }

  @override
  String get appliedChanges => 'Alterações aplicadas';

  @override
  String get showAtsResume => 'Mostrar currículo ATS';

  @override
  String get saveOptimizedResume => 'Salvar currículo otimizado';

  @override
  String saveOptimizedResumePrompt(String sourceTitle) {
    return 'Deseja salvar isto como uma nova cópia ou substituir \"$sourceTitle\"?';
  }

  @override
  String get newCopy => 'Nova cópia';

  @override
  String get existingResume => 'Currículo existente';

  @override
  String get resumePreview => 'Prévia do currículo';

  @override
  String get highlightedSummaryChange => 'Alteração de resumo destacada';

  @override
  String highlightedSkillsLabel(String skills) {
    return 'Habilidades destacadas: $skills';
  }

  @override
  String get atsTitleSuffix => ' (ATS)';

  @override
  String get optimizedTitleSuffix => ' (Otimizado)';

  @override
  String get professionalResumes => 'Currículos profissionais';

  @override
  String get atsResumes => 'Currículos ATS';

  @override
  String get useTemplate => 'Usar modelo';

  @override
  String get templateCorporate => 'Corporativo';

  @override
  String get templateCorporateCaption =>
      'Faixa superior marcante com seções profissionais compactas.';

  @override
  String get templateProfileSidebar => 'Barra lateral de perfil';

  @override
  String get templateProfileSidebarCaption =>
      'Layout centrado no perfil com âncoras visuais fortes.';

  @override
  String get templateClassicSidebar => 'Barra lateral clássica';

  @override
  String get templateClassicSidebarCaption =>
      'Trilho esquerdo suave com identidade com foto e seções estruturadas.';

  @override
  String get templateAccentStrip => 'Faixa de destaque';

  @override
  String get templateAccentStripCaption =>
      'Faixa esquerda marcante com nome grande e seções limpas.';

  @override
  String get templateStructuredAts => 'ATS estruturado';

  @override
  String get templateStructuredAtsCaption =>
      'Faixas de seção cinzas e cabeçalho centralizado para parsers.';

  @override
  String get templateLatexClassicAts => 'ATS clássico LaTeX';

  @override
  String get templateLatexClassicAtsCaption =>
      'Seções com linhas inspiradas em currículos LaTeX clássicos.';

  @override
  String get templateModernFlowAts => 'ATS fluxo moderno';

  @override
  String get templateModernFlowAtsCaption =>
      'Linha de contato centralizada com sequência lógica de seções.';

  @override
  String get templateExecutiveAts => 'ATS executivo';

  @override
  String get templateExecutiveAtsCaption =>
      'Títulos em maiúsculas e habilidades em duas colunas.';

  @override
  String get templateCenterClassicAts => 'ATS clássico centralizado';

  @override
  String get templateCenterClassicAtsCaption =>
      'Nome centralizado, slogan com barras e seções em coluna única.';

  @override
  String get templateProfessionalBlueAts => 'ATS azul profissional';

  @override
  String get templateProfessionalBlueAtsCaption =>
      'Títulos em azul com contato alinhado à direita e grade de habilidades.';

  @override
  String get templateExecutiveNote => 'Nota executiva';

  @override
  String get templateExecutiveNoteCaption =>
      'Carta de apresentação profissional com um bloco de cabeçalho forte.';

  @override
  String get templateMinimalLetter => 'Carta minimalista';

  @override
  String get templateMinimalLetterCaption =>
      'Cabeçalho centralizado com espaçamento amplo e corpo alinhado à esquerda.';

  @override
  String get templateMintLetter => 'Carta menta';

  @override
  String get templateMintLetterCaption =>
      'Nome grande, fundo menta suave e corpo moderno e limpo.';

  @override
  String get templateClassicBusiness => 'Negócios clássico';

  @override
  String get templateClassicBusinessCaption =>
      'Carta comercial tradicional: data, destinatário e corpo alinhado à esquerda.';

  @override
  String get autoSync => 'Sincronização automática';

  @override
  String get sync => 'Sincronizar';

  @override
  String get download => 'Baixar';

  @override
  String get alreadyDownloaded => 'Já baixado';

  @override
  String get signOut => 'Sair';

  @override
  String get signInWithGoogle => 'Entrar com o Google';

  @override
  String get syncToIcloud => 'Sincronizar com o iCloud';

  @override
  String get syncToGoogleDrive => 'Sincronizar com o Google Drive';

  @override
  String get iCloudUnavailable =>
      'O iCloud não está disponível neste dispositivo agora. Verifique se o iCloud Drive está ativado e se você entrou com o Apple ID correto.';

  @override
  String get noItemsInIcloud =>
      'Ainda não há currículos nem cartas de apresentação no iCloud.';

  @override
  String get noItemsOnDrive =>
      'Ainda não há currículos nem cartas de apresentação no Drive.';

  @override
  String get resumesInIcloud => 'Currículos no iCloud';

  @override
  String get coverLettersInIcloud => 'Cartas de apresentação no iCloud';

  @override
  String get resumesInGoogleDrive => 'Currículos no Google Drive';

  @override
  String get coverLettersInGoogleDrive =>
      'Cartas de apresentação no Google Drive';

  @override
  String get googleDriveBackupIntro =>
      'Faça backup de currículos e cartas de apresentação em uma pasta ResumeApp no seu Google Drive. Somente arquivos criados por este app são acessíveis.';

  @override
  String get googleDrivePermissionHint =>
      'Na página do Google que abrir em seguida, em \"Selecionar o que o ResumeApp pode acessar\", marque a caixa ao lado de Google Drive (arquivos usados com este app) e toque em Continuar. Sem essa caixa, o backup no Drive não funciona.';

  @override
  String get googleDriveLooksLikeThis => 'É assim:';

  @override
  String get googleDrivePermissionExampleSemantics =>
      'Tela de exemplo do Google: Selecionar o que o ResumeApp pode acessar, com a linha do Google Drive e a caixa de seleção.';

  @override
  String get noLocalItemsToSync =>
      'Não há currículos nem cartas de apresentação locais para sincronizar.';

  @override
  String get everythingUpToDateIcloud => 'Tudo já está atualizado no iCloud.';

  @override
  String get everythingUpToDateGoogleDrive =>
      'Tudo já está atualizado no Google Drive.';

  @override
  String couldNotLoadIcloudItems(String error) {
    return 'Não foi possível carregar os itens do iCloud: $error';
  }

  @override
  String couldNotSyncToIcloud(String error) {
    return 'Não foi possível sincronizar com o iCloud: $error';
  }

  @override
  String couldNotDeleteFromIcloud(String error) {
    return 'Não foi possível excluir do iCloud: $error';
  }

  @override
  String couldNotDownloadWithError(String error) {
    return 'Não foi possível baixar: $error';
  }

  @override
  String syncedSummaryToIcloud(String summary) {
    return '$summary sincronizado(s) com o iCloud.';
  }

  @override
  String syncedSummaryWithSkippedIcloud(String summary, String skipped) {
    return '$summary sincronizado(s). $skipped mantido(s) intacto(s).';
  }

  @override
  String syncedSummaryToGoogleDrive(String summary) {
    return '$summary sincronizado(s) com o Google Drive.';
  }

  @override
  String syncedSummaryWithSkippedDrive(String summary, String skipped) {
    return '$summary sincronizado(s). $skipped mantido(s) intacto(s).';
  }

  @override
  String resumeCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count currículos',
      one: '1 currículo',
    );
    return '$_temp0';
  }

  @override
  String coverLetterCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas de apresentação',
      one: '1 carta de apresentação',
    );
    return '$_temp0';
  }

  @override
  String newerIcloudItemsUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens mais recentes do iCloud',
      one: '1 item mais recente do iCloud',
    );
    return '$_temp0';
  }

  @override
  String newerDriveItemsUntouched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens mais recentes do Drive',
      one: '1 item mais recente do Drive',
    );
    return '$_temp0';
  }

  @override
  String listJoinAnd(String first, String second) {
    return '$first e $second';
  }

  @override
  String get deleteFromIcloudTitle => 'Excluir do iCloud?';

  @override
  String deleteFromIcloudMessage(String title) {
    return 'Remover \"$title\" do iCloud? Isso não excluirá a cópia neste dispositivo.';
  }

  @override
  String get deleteFromIcloud => 'Excluir do iCloud';

  @override
  String deleteDocumentType(String type) {
    return 'Excluir $type';
  }

  @override
  String get documentTypeResume => 'currículo';

  @override
  String get documentTypeCoverLetter => 'carta de apresentação';

  @override
  String removedFromIcloud(String title) {
    return '$title removido do iCloud.';
  }

  @override
  String downloadedTitle(String title) {
    return '$title baixado.';
  }

  @override
  String get googleSignInUnavailable =>
      'O login do Google não está disponível neste dispositivo.';

  @override
  String get couldNotSignInGoogleDrive =>
      'Não foi possível entrar no Google Drive agora. Tente novamente.';

  @override
  String get couldNotLoadGoogleDriveItems =>
      'Não foi possível carregar seus itens do Google Drive agora. Tente novamente.';

  @override
  String get couldNotSyncGoogleDrive =>
      'Não foi possível sincronizar com o Google Drive agora. Tente novamente.';

  @override
  String get couldNotDownloadFromGoogleDrive =>
      'Não foi possível baixar este item do Google Drive. Tente novamente.';

  @override
  String get couldNotRemoveFromGoogleDrive =>
      'Não foi possível remover este item do Google Drive. Tente novamente.';

  @override
  String get removeFromGoogleDriveTitle => 'Remover do Google Drive?';

  @override
  String removeFromGoogleDriveMessage(String title) {
    return 'Remover \"$title\" do Google Drive? Isso não excluirá a cópia neste dispositivo.';
  }

  @override
  String get removeFromGoogleDrive => 'Remover do Google Drive';

  @override
  String removeDocumentType(String type) {
    return 'Remover $type';
  }

  @override
  String removedFromGoogleDrive(String title) {
    return '$title removido do Google Drive.';
  }

  @override
  String get googleSignInNotConfigured =>
      'O Google Sign-In não está configurado para esta build. Adicione as impressões digitais SHA-1 de depuração e lançamento no Firebase (veja android/GOOGLE_SIGN_IN_SETUP.md), baixe novamente o google-services.json e recompile.';

  @override
  String get couldNotOpenGoogleSignIn =>
      'Não foi possível abrir a tela de login do Google. Tente novamente.';

  @override
  String get googleSignInInterrupted =>
      'O login do Google foi interrompido. Tente novamente.';

  @override
  String get unableToLoadPage => 'Não foi possível carregar a página';

  @override
  String get couldNotLoadThisPage => 'Não foi possível carregar esta página.';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get shareAppSubject => 'ResumeApp';

  @override
  String shareAppMessage(String url) {
    return 'Conheça o ResumeApp para criar, otimizar e compartilhar currículos profissionais no iPhone. Baixe na App Store: $url';
  }

  @override
  String get feedbackEmailSubject => 'Feedback do ResumeApp';

  @override
  String get noMailAppFound =>
      'Nenhum app de e-mail encontrado. Configure um app de e-mail.';

  @override
  String get couldNotOpenMailApp =>
      'Não foi possível abrir o app de e-mail. Tente novamente.';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link agora.';

  @override
  String get add => 'Adicionar';

  @override
  String get back => 'Voltar';

  @override
  String get done => 'Concluído';

  @override
  String get hide => 'Ocultar';

  @override
  String get remove => 'Remover';

  @override
  String get preview => 'Prévia';

  @override
  String get share => 'Compartilhar';

  @override
  String get print => 'Imprimir';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get template => 'Modelo';

  @override
  String get color => 'Cor';

  @override
  String get title => 'Título';

  @override
  String get type => 'Tipo';

  @override
  String get year => 'Ano';

  @override
  String get summary => 'Resumo';

  @override
  String get category => 'Categoria';

  @override
  String get present => 'Atual';

  @override
  String get language => 'Idioma';

  @override
  String get sectionPersonalInformation => 'Informações pessoais';

  @override
  String get sectionWorkExperience => 'Experiência profissional';

  @override
  String get sectionEducation => 'Educação';

  @override
  String get sectionSkills => 'Habilidades';

  @override
  String get sectionProjects => 'Projetos';

  @override
  String get personalInformationTitle => 'Informações pessoais';

  @override
  String get workExperienceTitle => 'Experiência profissional';

  @override
  String categoryNumber(int number) {
    return 'Categoria $number';
  }

  @override
  String pdfSavedTo(String path) {
    return 'PDF salvo em $path';
  }

  @override
  String get unableToGenerateSummary =>
      'Não foi possível gerar um resumo profissional agora.';

  @override
  String get summaryUpdated => 'Resumo atualizado';

  @override
  String get summaryAdded => 'Resumo adicionado';

  @override
  String get skillAlreadyInList => 'Esta habilidade já está na sua lista.';

  @override
  String get addBulletPoint => 'Adicionar marcador';

  @override
  String get appearsFirstOnYourResume => 'Aparece primeiro no seu currículo';

  @override
  String appearsOnYourResumeAt(int position) {
    return 'Aparece na posição $position do seu currículo';
  }

  @override
  String get hideFromResumeTitle => 'Ocultar do currículo?';

  @override
  String hideFromResumeMessage(String sectionName) {
    return '$sectionName não será mostrado no seu currículo nem nos PDFs exportados. Você pode mostrá-lo novamente a qualquer momento usando o botão ao lado do título da seção.';
  }

  @override
  String get hideFromResume => 'Ocultar do currículo';

  @override
  String get showOnResume => 'Mostrar no currículo';

  @override
  String get chooseMonthAndYear => 'Escolher mês e ano';

  @override
  String get clearDate => 'Limpar data';

  @override
  String get selectEndMonthAndYear => 'Selecionar mês e ano de término';

  @override
  String get selectStartMonthAndYear => 'Selecionar mês e ano de início';

  @override
  String get selectEndYear => 'Selecionar ano de término';

  @override
  String get selectStartYear => 'Selecionar ano de início';

  @override
  String get newSection => 'Nova seção';

  @override
  String get newSectionTitleHint => 'Certificações, Idiomas, Prêmios…';

  @override
  String get sectionTypeNormal => 'Normal';

  @override
  String get sectionTypeNormalSubtitle => 'Resumo ou marcadores';

  @override
  String get sectionTypeAdvance => 'Avançado';

  @override
  String get sectionTypeAdvanceSubtitle =>
      'Entradas no estilo de projeto com título e marcadores';

  @override
  String get removeSectionTitle => 'Remover seção?';

  @override
  String get removeSectionMessage =>
      'Esta seção será removida do seu currículo. Você pode adicionar uma nova seção personalizada com Adicionar a qualquer momento.';

  @override
  String get unableToPickImage => 'Não foi possível escolher uma imagem agora.';

  @override
  String get camera => 'Câmera';

  @override
  String get library => 'Biblioteca';

  @override
  String get profilePhoto => 'Foto de perfil';

  @override
  String get tapToChangePhoto => 'Toque para alterar a foto';

  @override
  String get previousField => 'Campo anterior';

  @override
  String get nextField => 'Próximo campo';

  @override
  String get fullName => 'Nome completo';

  @override
  String get targetJobTitle => 'Cargo desejado';

  @override
  String get githubLink => 'Link do GitHub';

  @override
  String get linkedinLink => 'Link do LinkedIn';

  @override
  String get email => 'E-mail';

  @override
  String get phoneNumber => 'Número de telefone';

  @override
  String get location => 'Localização';

  @override
  String get websiteOrPortfolio => 'Site ou portfólio';

  @override
  String get professionalSummary => 'Resumo profissional';

  @override
  String get personalInformationSubtitle =>
      'Comece com identidade, dados de contato, cargo desejado e um breve resumo de posicionamento.';

  @override
  String get suggestSummary => 'Sugerir resumo';

  @override
  String get resumeOrder => 'Ordem do currículo';

  @override
  String get resumeOrderBody =>
      'As entradas ficam nesta ordem. Use as setas para mover sua função mais forte para o topo.';

  @override
  String experienceNumber(int number) {
    return 'Experiência $number';
  }

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String get deleteExperience => 'Excluir experiência';

  @override
  String get deleteWorkExperienceTitle => 'Excluir experiência profissional?';

  @override
  String get deleteWorkExperienceMessage =>
      'Isso removerá este emprego e todos os seus marcadores. Não é possível desfazer.';

  @override
  String get role => 'Cargo';

  @override
  String get company => 'Empresa';

  @override
  String get startDate => 'Data de início';

  @override
  String get endDate => 'Data de término';

  @override
  String get monthYearHint => 'Mês/ano';

  @override
  String get monthYearOrPresentHint => 'Mês/ano ou Atual';

  @override
  String bulletNumber(int number) {
    return 'Marcador $number';
  }

  @override
  String get removeBulletTitle => 'Remover marcador?';

  @override
  String get removeBulletFromJob =>
      'Este marcador será removido deste emprego.';

  @override
  String get addExperience => 'Adicionar experiência';

  @override
  String get educationSubtitle =>
      'Inclua sua formação, instituição e período de estudo.';

  @override
  String educationNumber(int number) {
    return 'Educação $number';
  }

  @override
  String get moveEducationUp => 'Mover educação para cima';

  @override
  String get moveEducationDown => 'Mover educação para baixo';

  @override
  String get deleteEducationEntry => 'Excluir entrada de educação';

  @override
  String get deleteEducationEntryTitle => 'Excluir entrada de educação?';

  @override
  String get deleteEducationEntryMessage =>
      'Isso removerá esta escola e formação do seu currículo. Não é possível desfazer.';

  @override
  String get institution => 'Instituição';

  @override
  String get degree => 'Formação';

  @override
  String get startYear => 'Ano de início';

  @override
  String get endYear => 'Ano de término';

  @override
  String get selectYear => 'Selecionar ano';

  @override
  String get marksScore => 'Notas / pontuação';

  @override
  String get marksScoreHint => '8,6 CGPA, 92 ou 780/800';

  @override
  String get addEducation => 'Adicionar educação';

  @override
  String get showScoreAsPercent => 'Mostrar como porcentagem';

  @override
  String get skillsSubtitle =>
      'Adicione ferramentas e palavras-chave específicas da vaga. Escolha uma lista simples ou categorize habilidades sob títulos (por exemplo Idiomas, Ferramentas).';

  @override
  String skillsCount(int count) {
    return '$count habilidades';
  }

  @override
  String get simpleList => 'Lista simples';

  @override
  String get categorised => 'Categorizadas';

  @override
  String get addASkill => 'Adicionar uma habilidade';

  @override
  String get addSkillHelper =>
      'Digite para ver sugestões ou adicione sua própria habilidade';

  @override
  String get categoryHint =>
      'Linguagens de programação, Ferramentas, Frameworks, etc.';

  @override
  String get moveCategoryUp => 'Mover categoria para cima';

  @override
  String get moveCategoryDown => 'Mover categoria para baixo';

  @override
  String get removeCategory => 'Remover categoria';

  @override
  String get deleteCategoryTitle => 'Excluir categoria?';

  @override
  String get deleteCategoryMessage =>
      'Isso removerá esta categoria e todas as suas habilidades. Não é possível desfazer.';

  @override
  String get addCategory => 'Adicionar categoria';

  @override
  String get projectsSubtitle =>
      'Mostre projetos paralelos, lançamentos ou trabalhos de portfólio com resultados claros.';

  @override
  String projectNumber(int number) {
    return 'Projeto $number';
  }

  @override
  String get moveProjectUp => 'Mover projeto para cima';

  @override
  String get moveProjectDown => 'Mover projeto para baixo';

  @override
  String get deleteProject => 'Excluir projeto';

  @override
  String get deleteProjectTitle => 'Excluir projeto?';

  @override
  String get deleteProjectMessage =>
      'Isso removerá este projeto e todos os seus marcadores. Não é possível desfazer.';

  @override
  String get projectTitle => 'Título do projeto';

  @override
  String get enterBulletPoint => 'Digite um marcador';

  @override
  String get removeBulletFromProject =>
      'Este marcador será removido deste projeto.';

  @override
  String get addProject => 'Adicionar projeto';

  @override
  String get customSectionProjectsSubtitle =>
      'Adicione entradas com título e marcadores, como na seção Projetos.';

  @override
  String get removeSection => 'Remover seção';

  @override
  String get bulletPoints => 'Marcadores';

  @override
  String get customSectionSummaryHint =>
      'Escreva a seção como um parágrafo curto para o seu currículo.';

  @override
  String entryNumber(int number) {
    return 'Entrada $number';
  }

  @override
  String get moveEntryUp => 'Mover entrada para cima';

  @override
  String get moveEntryDown => 'Mover entrada para baixo';

  @override
  String get deleteEntry => 'Excluir entrada';

  @override
  String get deleteEntryTitle => 'Excluir entrada?';

  @override
  String get deleteEntryMessage =>
      'Isso removerá esta entrada e todos os seus marcadores. Não é possível desfazer.';

  @override
  String get removeBulletFromEntry =>
      'Este marcador será removido desta entrada.';

  @override
  String get addEntry => 'Adicionar entrada';

  @override
  String get livePreview => 'Prévia ao vivo';

  @override
  String get exportActions => 'Ações de exportação';

  @override
  String get downloadPdf => 'Baixar PDF';

  @override
  String get shareResume => 'Compartilhar currículo';

  @override
  String get resumeScore => 'Pontuação do currículo';

  @override
  String atsCompatibilitySummary(int percent, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Compatibilidade ATS $percent% com $count lacunas de habilidades faltantes.',
      one:
          'Compatibilidade ATS $percent% com 1 lacuna de habilidades faltantes.',
    );
    return '$_temp0';
  }

  @override
  String get unableToOpenShareSheet =>
      'Não foi possível abrir a folha de compartilhamento agora.';

  @override
  String get chooseTemplate => 'Escolher modelo';

  @override
  String get fontSize => 'Tamanho da fonte';

  @override
  String get colorAndFont => 'Cor e fonte';

  @override
  String get sharedFromResumeAi => 'Compartilhado do ResumeAI';

  @override
  String get unableToLoadPdfPreview =>
      'Não foi possível carregar a prévia do PDF agora.';

  @override
  String get shareFormatPdf => 'PDF';

  @override
  String get shareFormatDocx => 'DOCX';

  @override
  String get coverLetterHeading => 'Carta de apresentação';

  @override
  String get coverLetterEditorIntro =>
      'Esta página cria um rascunho de carta de apresentação com os detalhes abaixo. Adicione o nome da empresa, o cargo, uma ou mais habilidades a destacar e um idioma, e toque em Criar carta de apresentação para abrir o rascunho completo na próxima tela.';

  @override
  String get companyName => 'Nome da empresa';

  @override
  String get jobPositionName => 'Nome do cargo';

  @override
  String get skillToHighlight => 'Habilidade a destacar';

  @override
  String get creatingEllipsis => 'Criando...';

  @override
  String get createCoverLetter => 'Criar carta de apresentação';

  @override
  String get coverLetterContentHeading => 'Conteúdo da carta';

  @override
  String get coverLetterContentIntro =>
      'Seu rascunho da carta está pronto. Revise o conteúdo completo abaixo, edite o que quiser e suas alterações serão salvas automaticamente.';

  @override
  String get regenerate => 'Gerar novamente';

  @override
  String get coverLetterContentHint => 'Sua carta gerada aparecerá aqui.';

  @override
  String get clLangEnglish => 'Inglês (English)';

  @override
  String get clLangArabic => 'Árabe (العربية)';

  @override
  String get clLangBengali => 'Bengali (বাংলা)';

  @override
  String get clLangChinese => 'Chinês, mandarim (中文)';

  @override
  String get clLangDutch => 'Holandês (Nederlands)';

  @override
  String get clLangFrench => 'Francês (Français)';

  @override
  String get clLangGerman => 'Alemão (Deutsch)';

  @override
  String get clLangHindi => 'Hindi (हिन्दी)';

  @override
  String get clLangItalian => 'Italiano (Italiano)';

  @override
  String get clLangJapanese => 'Japonês (日本語)';

  @override
  String get clLangKorean => 'Coreano (한국어)';

  @override
  String get clLangPortuguese => 'Português (Português)';

  @override
  String get clLangRussian => 'Russo (Русский)';

  @override
  String get clLangSpanish => 'Espanhol (Español)';

  @override
  String get clLangTurkish => 'Turco (Türkçe)';

  @override
  String get clLangUrdu => 'Urdu (اردو)';

  @override
  String get clLangVietnamese => 'Vietnamita (Tiếng Việt)';

  @override
  String get showPercentOnResume => 'Toque para mostrar % no currículo';

  @override
  String get hidePercentOnResume =>
      'Mostrando % no currículo — toque para ocultar';

  @override
  String get removeBullet => 'Remover marcador';

  @override
  String get alreadySubscribedTitle => 'Já assinante';

  @override
  String youreOnPlan(String planLabel) {
    return 'Você está no $planLabel';
  }

  @override
  String get premiumPlanNotAvailableYet =>
      'Esse plano ainda não está disponível. Puxe para atualizar.';

  @override
  String get premiumCouldNotStartPurchase =>
      'Não foi possível iniciar a compra. Tente novamente.';

  @override
  String get premiumSubscriptionRestored =>
      'Sua assinatura Premium foi restaurada.';

  @override
  String get premiumRestoredSuccessfully => 'Premium restaurado com sucesso.';

  @override
  String get welcomeToResumeAppPro => 'Bem-vindo ao ResumeApp Pro!';

  @override
  String get jobsCreateResumeFirst =>
      'Crie um currículo primeiro para ver vagas.';

  @override
  String get jobsShowingLatestHint =>
      'Mostrando as vagas mais recentes dos últimos 7 dias com base no cargo e na localização do currículo selecionado.';

  @override
  String get jobsNoneFound =>
      'Nenhuma vaga encontrada para este currículo nos últimos 7 dias.';

  @override
  String get jobsLoadingMore => 'Carregando mais vagas...';

  @override
  String get jobsScrollForMore => 'Role para baixo para carregar mais';

  @override
  String get jobsLiveUnavailableBackup =>
      'Vagas ao vivo indisponíveis; mostrando resultados de backup.';

  @override
  String get couldNotOpenJobLink =>
      'Não foi possível abrir o link da vaga agora.';

  @override
  String get jobsPostedJustNow => 'agora mesmo';

  @override
  String jobsPostedHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String jobsPostedDaysAgo(int days) {
    return 'há $days d';
  }
}
