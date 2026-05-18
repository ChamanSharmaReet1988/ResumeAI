import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'app_preferences.dart';
import 'premium_debug_log.dart';
import 'premium_entitlement_resolver.dart';
import 'premium_products.dart';
import 'premium_store_messages.dart';

/// Loads subscription products, handles purchases, and persists premium access.
class PremiumPurchaseService extends ChangeNotifier {
  PremiumPurchaseService({
    required AppPreferences appPreferences,
    InAppPurchase? inAppPurchase,
    bool enableStore = true,
  })  : _appPreferences = appPreferences,
        _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
        _enableStore = enableStore {
    if (_enableStore) {
      _ensurePurchaseStreamListener();
    }
  }

  factory PremiumPurchaseService.inMemory({
    required AppPreferences appPreferences,
    bool isPremium = false,
  }) {
    if (isPremium) {
      unawaited(appPreferences.setIsPremium(true));
    }
    return PremiumPurchaseService(
      appPreferences: appPreferences,
      enableStore: false,
    );
  }

  final AppPreferences _appPreferences;
  final InAppPurchase _inAppPurchase;
  final bool _enableStore;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _storeAvailable = false;
  bool _isLoadingProducts = true;
  List<String> _notFoundProductIds = const [];
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _statusMessage;
  String? _errorMessage;
  List<ProductDetails> _products = const [];
  String? _activeSubscriptionProductId;

  /// Debug-only: user turned Pro off in Developer Tools; ignore store until re-enabled.
  bool _developerProManuallyDisabled = false;

  /// Show welcome dialog on Settings after buy / restore (not on silent launch).
  bool _pendingPremiumWelcome = false;

  /// Prevents overlapping store sync / stream handlers from fighting each other.
  Future<void>? _ongoingStoreSync;

  static const Duration _storeEntitlementSettleDelay = Duration(
    milliseconds: 3500,
  );

  bool get storeAvailable => _storeAvailable;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoring => _isRestoring;
  bool get isPremium {
    if (kDebugMode && _developerProManuallyDisabled) {
      return false;
    }
    return _appPreferences.isPremium ||
        (kDebugMode && _appPreferences.debugPremiumOverrideEnabled);
  }
  bool get debugPremiumOverrideEnabled =>
      kDebugMode && _appPreferences.debugPremiumOverrideEnabled;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;
  List<String> get notFoundProductIds => _notFoundProductIds;
  bool get hasLoadedProducts => _products.isNotEmpty;
  String? get activeSubscriptionProductId => _activeSubscriptionProductId;

  String get activeSubscriptionPlanLabel =>
      PremiumProducts.planLabelFor(_activeSubscriptionProductId);

  String alreadySubscribedMessage() => PremiumProducts.alreadySubscribedMessage(
        productId: _activeSubscriptionProductId,
        debugOverride: debugPremiumOverrideEnabled,
      );

  /// Consumed by [SettingsScreen] to show the Pro welcome dialog once.
  bool consumePremiumWelcomePending() {
    if (!_pendingPremiumWelcome) {
      return false;
    }
    _pendingPremiumWelcome = false;
    return true;
  }

  ProductDetails? productFor(String productId) {
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  void _ensurePurchaseStreamListener() {
    if (!_enableStore || _purchaseSubscription != null) {
      return;
    }
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        _errorMessage = PremiumStoreMessages.friendly(
          error: error,
          fallback: PremiumStoreMessages.purchaseFailed,
        );
        _isPurchasing = false;
        notifyListeners();
      },
    );
  }

  Future<void> initialize() async {
    PremiumDebugLog.section('Premium initialize (app launch)');
    _logLocalPremiumState('before initialize');

    if (!_enableStore) {
      PremiumDebugLog.log('Store disabled (in-memory / test mode)');
      _isLoadingProducts = false;
      notifyListeners();
      return;
    }

    try {
      _storeAvailable = await _inAppPurchase.isAvailable();
      PremiumDebugLog.logPair('storeAvailable', _storeAvailable);
      if (!_storeAvailable) {
        _errorMessage =
            'In-app purchases are not available on this device right now.';
        _isLoadingProducts = false;
        notifyListeners();
        return;
      }

      _ensurePurchaseStreamListener();

      await _loadProducts();
      await verifyPremiumLocally(reason: 'app_launch');
      _logLocalPremiumState('after initialize');
    } catch (error, stackTrace) {
      PremiumDebugLog.log('initialize failed: $error');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
      _errorMessage = PremiumStoreMessages.friendly(
        error: error,
        fallback: PremiumStoreMessages.connectFailed,
      );
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Reloads subscription prices from the App Store or Play Store.
  Future<void> refreshProducts() => _loadProducts();

  /// Reads the current store entitlement and caches the active subscription
  /// product ID without changing local premium state.
  Future<String?> resolveCurrentStoreSubscription({
    String reason = 'store_preflight',
    bool requestAppStoreSync = false,
  }) async {
    if (!_enableStore) {
      return null;
    }

    _ensurePurchaseStreamListener();

    if (!_storeAvailable) {
      _storeAvailable = await _inAppPurchase.isAvailable();
    }
    if (!_storeAvailable) {
      PremiumDebugLog.log(
        'resolveCurrentStoreSubscription($reason): store unavailable',
      );
      return null;
    }

    await _refreshActiveSubscriptionFromStore(
      reason: reason,
      requestAppStoreSync: requestAppStoreSync,
    );
    return _activeSubscriptionProductId;
  }

  /// Reads subscription state already on the device — never calls [restorePurchases]
  /// or [AppStore.sync], so the user is not asked for an Apple ID password.
  Future<void> verifyPremiumLocally({required String reason}) async {
    PremiumDebugLog.section('Local Pro verify ($reason)');
    _logLocalPremiumState('before local verify');

    if (!_enableStore) {
      return;
    }

    _ensurePurchaseStreamListener();

    if (!_storeAvailable) {
      _storeAvailable = await _inAppPurchase.isAvailable();
    }
    if (!_storeAvailable) {
      PremiumDebugLog.log('local verify skipped: store unavailable');
      return;
    }

    try {
      await _refreshActiveSubscriptionFromStore(reason: reason);
      final entitled = _activeSubscriptionProductId != null;
      await _applyStoreEntitlement(entitled, reason: reason);
      _logLocalPremiumState('after local verify');
    } catch (error, stackTrace) {
      PremiumDebugLog.log('local verify failed ($reason): $error');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  /// Re-checks App Store / Play subscription state and updates local premium flag.
  ///
  /// Set [requestStoreRestore] to true only for the Restore purchases button.
  /// Set [requestAppStoreSync] for a user-initiated iOS sync without restore.
  /// Silent checks read cached StoreKit / Play data and do not ask for a password.
  Future<void> syncPremiumWithStore({
    bool silent = true,
    String reason = 'sync',
    bool requestStoreRestore = false,
    bool requestAppStoreSync = false,
  }) async {
    while (_ongoingStoreSync != null) {
      await _ongoingStoreSync;
    }

    final syncRun = _runStoreSync(
      silent: silent,
      reason: reason,
      requestStoreRestore: requestStoreRestore,
      requestAppStoreSync: requestAppStoreSync,
    );
    _ongoingStoreSync = syncRun;
    try {
      await syncRun;
    } finally {
      if (identical(_ongoingStoreSync, syncRun)) {
        _ongoingStoreSync = null;
      }
    }
  }

  Future<void> _runStoreSync({
    required bool silent,
    required String reason,
    required bool requestStoreRestore,
    required bool requestAppStoreSync,
  }) async {
    PremiumDebugLog.section('Premium sync ($reason)');
    _logLocalPremiumState('before sync');

    if (!_enableStore) {
      PremiumDebugLog.log('sync skipped: store disabled');
      return;
    }

    _ensurePurchaseStreamListener();

    if (!_storeAvailable) {
      _storeAvailable = await _inAppPurchase.isAvailable();
    }
    PremiumDebugLog.logPair('storeAvailable', _storeAvailable);
    if (!_storeAvailable) {
      PremiumDebugLog.log('sync skipped: store unavailable');
      return;
    }

    if (!silent) {
      _errorMessage = null;
      _statusMessage = null;
    }
    notifyListeners();

    try {
      if (requestStoreRestore) {
        PremiumDebugLog.log('Calling restorePurchases() (user initiated)…');
        await _inAppPurchase.restorePurchases();
        PremiumDebugLog.log(
          'Waiting ${_storeEntitlementSettleDelay.inMilliseconds}ms for purchase stream…',
        );
        await Future<void>.delayed(_storeEntitlementSettleDelay);
      } else if (requestAppStoreSync) {
        PremiumDebugLog.log(
          'User-initiated AppStore.sync entitlement refresh (no restorePurchases)',
        );
      } else {
        PremiumDebugLog.log(
          'Silent entitlement check (no restorePurchases / no AppStore.sync)',
        );
      }

      await _refreshActiveSubscriptionFromStore(
        reason: reason,
        requestAppStoreSync: requestAppStoreSync,
      );

      final entitled = _activeSubscriptionProductId != null;
      PremiumDebugLog.logPair('storeSaysEntitled', entitled);
      await _applyStoreEntitlement(entitled, reason: reason);

      _logLocalPremiumState('after sync');
    } catch (error, stackTrace) {
      PremiumDebugLog.log('sync failed ($reason): $error');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
      if (!silent) {
        _errorMessage = PremiumStoreMessages.friendly(
          error: error,
          fallback: PremiumStoreMessages.verifyFailed,
        );
        notifyListeners();
      }
    }
  }

  Future<void> _loadProducts() async {
    if (!_enableStore) {
      return;
    }

    _isLoadingProducts = true;
    _errorMessage = null;
    notifyListeners();

    if (!_storeAvailable) {
      _storeAvailable = await _inAppPurchase.isAvailable();
      if (!_storeAvailable) {
        _errorMessage =
            'In-app purchases are not available on this device right now.';
        _isLoadingProducts = false;
        notifyListeners();
        return;
      }
    }

    ProductDetailsResponse? response;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      response = await _queryStoreProducts();
      if (response.productDetails.isNotEmpty) {
        break;
      }
      if (response.error != null) {
        break;
      }
    }

    final resolved = response!;

    if (resolved.error != null) {
      _notFoundProductIds = const [];
      _errorMessage = _friendlyProductLoadError(resolved.error!.message);
      _products = const [];
    } else {
      _notFoundProductIds = resolved.notFoundIDs;
      _products = _sortProducts(resolved.productDetails);
      if (_products.isEmpty) {
        if (_notFoundProductIds.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              'Premium products not found in store: $_notFoundProductIds',
            );
          }
          _errorMessage = PremiumStoreMessages.productsUnavailable;
        } else {
          _errorMessage =
              'Could not load subscription prices. Try again.';
        }
      } else {
        _errorMessage = null;
      }
      for (final id in _notFoundProductIds) {
        if (kDebugMode) {
          debugPrint('Premium product not found in store: $id');
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        'Premium products loaded: ${_products.map((p) => '${p.id}=${p.price}').join(', ')}',
      );
      if (_errorMessage == null && _notFoundProductIds.isNotEmpty) {
        debugPrint('Premium products not found: $_notFoundProductIds');
      }
      if (_errorMessage != null) {
        debugPrint('Premium product load error: $_errorMessage');
      }
    }

    _isLoadingProducts = false;
    notifyListeners();
  }

  Future<ProductDetailsResponse> _queryStoreProducts() {
    return _inAppPurchase.queryProductDetails(
      PremiumProducts.subscriptionIds.toSet(),
    );
  }

  String _friendlyProductLoadError(String message) {
    return PremiumStoreMessages.friendly(
      rawMessage: message,
      fallback: PremiumStoreMessages.productsUnavailable,
    );
  }

  List<ProductDetails> _sortProducts(List<ProductDetails> products) {
    final order = PremiumProducts.subscriptionIds;
    final sorted = [...products];
    sorted.sort(
      (a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)),
    );
    return sorted;
  }

  Future<void> buy(String productId) async {
    if (!_storeAvailable || _isPurchasing) {
      return;
    }

    final product = productFor(productId);
    if (product == null) {
      _errorMessage = 'That plan is not available yet. Pull to refresh.';
      notifyListeners();
      return;
    }

    _isPurchasing = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    final PurchaseParam purchaseParam;
    if (product is GooglePlayProductDetails) {
      purchaseParam = GooglePlayPurchaseParam(productDetails: product);
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }
    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!started) {
      _isPurchasing = false;
      _errorMessage = 'Could not start the purchase. Please try again.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases({bool silent = false}) async {
    if (!_enableStore) {
      return;
    }

    if (kDebugMode && _developerProManuallyDisabled) {
      PremiumDebugLog.log(
        'manual restore: clearing developer forced-free mode',
      );
      _developerProManuallyDisabled = false;
    }

    _isRestoring = !silent;
    if (!silent) {
      _errorMessage = null;
      _statusMessage = null;
    }
    notifyListeners();

    try {
      await syncPremiumWithStore(
        silent: silent,
        reason: 'manual_restore',
        requestStoreRestore: true,
        requestAppStoreSync: true,
      );
      if (!silent) {
        final hasActiveStoreSubscription = _activeSubscriptionProductId != null;
        if (hasActiveStoreSubscription) {
          _statusMessage = 'Your Premium subscription has been restored.';
        } else {
          _statusMessage =
              'No active subscription was found for this Apple ID or Google account.';
        }
      }
    } catch (error) {
      if (!silent) {
        _errorMessage = PremiumStoreMessages.friendly(
          error: error,
          fallback: PremiumStoreMessages.restoreFailed,
        );
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    PremiumDebugLog.log(
      'purchaseStream update: ${purchaseDetailsList.length} item(s)',
    );
    for (final purchase in purchaseDetailsList) {
      if (!PremiumProducts.subscriptionIds.contains(purchase.productID)) {
        continue;
      }

      PremiumDebugLog.log(
        '  stream productId=${purchase.productID} '
        'status=${purchase.status.name} '
        'purchaseId=${purchase.purchaseID ?? "none"}',
      );

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isPurchasing = true;
          _errorMessage = null;
          _statusMessage = null;
          break;
        case PurchaseStatus.error:
          _isPurchasing = false;
          _errorMessage = PremiumStoreMessages.friendly(
            rawMessage: purchase.error?.message,
            fallback: PremiumStoreMessages.purchaseFailed,
          );
          break;
        case PurchaseStatus.canceled:
          _isPurchasing = false;
          _statusMessage = 'Purchase canceled.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final handleStreamUpdate =
              _isPurchasing || _isRestoring || _ongoingStoreSync != null;
          if (!handleStreamUpdate) {
            PremiumDebugLog.log(
              'Ignoring purchase stream ${purchase.status.name} '
              '(no active buy/restore)',
            );
            break;
          }
          unawaited(_finalizePurchaseFromStream(purchase));
          break;
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_inAppPurchase.completePurchase(purchase));
      }
    }

    notifyListeners();
  }

  Future<void> _refreshActiveSubscriptionFromStore({
    String reason = 'refresh',
    String? preferredProductId,
    bool requestAppStoreSync = false,
  }) async {
    if (!_enableStore) {
      _activeSubscriptionProductId = null;
      return;
    }
    _activeSubscriptionProductId =
        await PremiumEntitlementResolver.resolveActiveProductId(
      _inAppPurchase,
      reason: reason,
      preferredProductId: preferredProductId,
      requestAppStoreSync: requestAppStoreSync,
    );
    PremiumDebugLog.logPair(
      'cachedActiveProductId',
      _activeSubscriptionProductId ?? 'none',
    );
    notifyListeners();
  }

  Future<void> _finalizePurchaseFromStream(PurchaseDetails purchase) async {
    final wasBuying = _isPurchasing;
    try {
      if (_ongoingStoreSync != null) {
        PremiumDebugLog.log(
          'Waiting for store sync before purchase stream re-verify',
        );
        await _ongoingStoreSync;
      }
      if (purchase.status == PurchaseStatus.purchased) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
      await _refreshPremiumFromStoreAfterPurchase(purchase);
    } finally {
      if (wasBuying) {
        _isPurchasing = false;
      }
      notifyListeners();
    }
  }

  Future<void> _refreshPremiumFromStoreAfterPurchase(
    PurchaseDetails purchase,
  ) async {
    PremiumDebugLog.section(
      'Purchase stream → re-verify (${purchase.status.name})',
    );
    await _refreshActiveSubscriptionFromStore(
      reason: 'purchase_stream_${purchase.status.name}',
      preferredProductId: purchase.productID,
    );
    final entitled = _activeSubscriptionProductId != null;
    await _applyStoreEntitlement(
      entitled,
      reason: 'purchase_stream_${purchase.status.name}',
    );
    if (entitled) {
      _statusMessage = purchase.status == PurchaseStatus.restored
          ? 'Premium restored successfully.'
          : 'Welcome to ResumeApp Pro!';
    } else if (purchase.status == PurchaseStatus.restored) {
      _statusMessage =
          'No active subscription was found for this Apple ID or Google account.';
    }
    notifyListeners();
  }

  Future<void> _grantPremium() async {
    if (_appPreferences.isPremium) {
      PremiumDebugLog.log('grantPremium: already premium in local prefs');
      return;
    }
    PremiumDebugLog.log('grantPremium: setting is_premium=true');
    await _appPreferences.setIsPremium(true);
    notifyListeners();
  }

  Future<void> _revokePremium() async {
    _activeSubscriptionProductId = null;
    if (!_appPreferences.isPremium) {
      PremiumDebugLog.log('revokePremium: already not premium in local prefs');
      return;
    }
    PremiumDebugLog.log('revokePremium: setting is_premium=false');
    await _appPreferences.setIsPremium(false);
    if (_appPreferences.iCloudAutoSyncEnabled) {
      await _appPreferences.setICloudAutoSyncEnabled(false);
    }
    notifyListeners();
  }

  Future<void> _applyStoreEntitlement(
    bool entitled, {
    String reason = 'apply',
  }) async {
    if (kDebugMode && _developerProManuallyDisabled) {
      PremiumDebugLog.log(
        'applyStoreEntitlement($reason): developer Pro toggle OFF → '
        'keeping free access',
      );
      await _revokePremium();
      notifyListeners();
      return;
    }

    if (kDebugMode && _appPreferences.debugPremiumOverrideEnabled) {
      PremiumDebugLog.log(
        'applyStoreEntitlement($reason): debug override ON → '
        'skip revoke; isPremium getter=$isPremium',
      );
      if (entitled) {
        await _grantPremium();
      }
      notifyListeners();
      return;
    }

    PremiumDebugLog.log(
      'applyStoreEntitlement($reason): entitled=$entitled → '
      '${entitled ? "grant" : "revoke"} local premium',
    );

    final wasPremium = _appPreferences.isPremium;
    if (entitled) {
      await _grantPremium();
      if (!wasPremium && _shouldCelebratePremiumActivation(reason)) {
        _pendingPremiumWelcome = true;
        PremiumDebugLog.log('Premium welcome dialog queued ($reason)');
      }
    } else {
      await _revokePremium();
    }
    notifyListeners();
  }

  bool _shouldCelebratePremiumActivation(String reason) {
    return reason.startsWith('purchase_stream') || reason == 'manual_restore';
  }

  void _logLocalPremiumState(String moment) {
    PremiumDebugLog.log(
      'Local state ($moment): '
      'hiveIsPremium=${_appPreferences.isPremium} '
      'debugOverride=${_appPreferences.debugPremiumOverrideEnabled} '
      'activeProductId=${_activeSubscriptionProductId ?? "none"} '
      'isPremiumGetter=$isPremium',
    );
  }

  /// Developer Tools switch: mirrors [isPremium]; turning off forces free access.
  Future<void> setDeveloperProAccessEnabled(bool enabled) async {
    if (!kDebugMode) {
      return;
    }

    PremiumDebugLog.log(
      'setDeveloperProAccessEnabled: $enabled '
      '(was isPremium=$isPremium)',
    );

    if (enabled) {
      _developerProManuallyDisabled = false;
      await _appPreferences.setDebugPremiumOverrideEnabled(true);
      await _grantPremium();
      notifyListeners();
      return;
    }

    _developerProManuallyDisabled = true;
    await _appPreferences.setDebugPremiumOverrideEnabled(false);
    await _revokePremium();
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription?.cancel());
    super.dispose();
  }
}
