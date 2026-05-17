import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'app_preferences.dart';
import 'premium_products.dart';

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

  bool get storeAvailable => _storeAvailable;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoring => _isRestoring;
  bool get isPremium =>
      _appPreferences.isPremium ||
      (kDebugMode && _appPreferences.debugPremiumOverrideEnabled);
  bool get debugPremiumOverrideEnabled =>
      kDebugMode && _appPreferences.debugPremiumOverrideEnabled;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;
  List<String> get notFoundProductIds => _notFoundProductIds;
  bool get hasLoadedProducts => _products.isNotEmpty;

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
        _errorMessage = 'Purchase error: $error';
        _isPurchasing = false;
        notifyListeners();
      },
    );
  }

  Future<void> initialize() async {
    if (!_enableStore) {
      _isLoadingProducts = false;
      notifyListeners();
      return;
    }

    try {
      _storeAvailable = await _inAppPurchase.isAvailable();
      if (!_storeAvailable) {
        _errorMessage =
            'In-app purchases are not available on this device right now.';
        _isLoadingProducts = false;
        notifyListeners();
        return;
      }

      _ensurePurchaseStreamListener();

      await _loadProducts();
      await restorePurchases(silent: true);
    } catch (error) {
      _errorMessage = 'Could not connect to the store: $error';
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Reloads subscription prices from the App Store or Play Store.
  Future<void> refreshProducts() => _loadProducts();

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
          _errorMessage =
              'Could not load plans. Product IDs must match App Store Connect '
              'exactly: ${_notFoundProductIds.join(', ')}.';
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
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        message.contains('StoreKit: Failed to get response from platform.')) {
      return 'The App Store did not return subscription products. '
          'Live prices require a real iPhone build using Sandbox, TestFlight, '
          'or the App Store.';
    }
    return message;
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

    _isRestoring = !silent;
    if (!silent) {
      _errorMessage = null;
      _statusMessage = null;
    }
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
      if (!silent) {
        if (isPremium) {
          _statusMessage = 'Your Premium subscription has been restored.';
        } else {
          _statusMessage =
              'No active subscription was found for this Apple ID or Google account.';
        }
      }
    } catch (error) {
      if (!silent) {
        _errorMessage = 'Restore failed: $error';
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (!PremiumProducts.subscriptionIds.contains(purchase.productID)) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _statusMessage = 'Purchase pending approval…';
          break;
        case PurchaseStatus.error:
          _isPurchasing = false;
          _errorMessage =
              purchase.error?.message ?? 'Purchase could not be completed.';
          break;
        case PurchaseStatus.canceled:
          _isPurchasing = false;
          _statusMessage = 'Purchase canceled.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _isPurchasing = false;
          unawaited(_grantPremium());
          _statusMessage = purchase.status == PurchaseStatus.restored
              ? 'Premium restored successfully.'
              : 'Welcome to ResumeApp Pro!';
          break;
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_inAppPurchase.completePurchase(purchase));
      }
    }

    notifyListeners();
  }

  Future<void> _grantPremium() async {
    if (_appPreferences.isPremium) {
      return;
    }
    await _appPreferences.setIsPremium(true);
    notifyListeners();
  }

  Future<void> setDebugPremiumOverrideEnabled(bool value) async {
    if (!kDebugMode ||
        _appPreferences.debugPremiumOverrideEnabled == value) {
      return;
    }
    await _appPreferences.setDebugPremiumOverrideEnabled(value);
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
