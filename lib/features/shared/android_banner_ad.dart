import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../core/services/android_ads_service.dart';
import '../../core/services/platform_monetization.dart';
import '../../core/services/premium_purchase_service.dart';

/// Anchored adaptive banner (Android + iOS). Hidden when iOS Pro is active.
class AndroidBannerAdSlot extends StatefulWidget {
  const AndroidBannerAdSlot({
    super.key,
    required this.placement,
    this.height = 50,
  });

  final AndroidBannerPlacement placement;
  final double height;

  @override
  State<AndroidBannerAdSlot> createState() => _AndroidBannerAdSlotState();
}

class _AndroidBannerAdSlotState extends State<AndroidBannerAdSlot> {
  BannerAd? _banner;
  bool _loaded = false;
  int? _loadedWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureBanner();
  }

  @override
  void dispose() {
    _banner?.dispose();
    _banner = null;
    super.dispose();
  }

  Future<void> _ensureBanner() async {
    if (!PlatformMonetization.showsAds || !AndroidAdsService.isInitialized) {
      return;
    }
    if (_premiumHidesAds(context)) {
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || width == _loadedWidth) {
      return;
    }
    _loadedWidth = width;

    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) {
      return;
    }

    await _banner?.dispose();
    _banner = null;
    if (mounted) {
      setState(() => _loaded = false);
    }

    final ad = BannerAd(
      adUnitId: AndroidAdsConfig.bannerAdUnitIdFor(widget.placement),
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || ad != _banner) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted || ad != _banner) {
            return;
          }
          setState(() {
            _banner = null;
            _loaded = false;
          });
        },
      ),
    );
    _banner = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformMonetization.showsAds || _premiumHidesAds(context)) {
      return const SizedBox.shrink();
    }
    final banner = _banner;
    if (!_loaded || banner == null) {
      return SizedBox(height: widget.height, width: double.infinity);
    }
    return SizedBox(
      width: double.infinity,
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }
}

bool _premiumHidesAds(BuildContext context) {
  if (!PlatformMonetization.isIapEnabled) {
    return false;
  }
  try {
    return context.read<PremiumPurchaseService>().isPremium;
  } catch (_) {
    return AndroidAdsService.isPremiumActive?.call() ?? false;
  }
}

/// Compact top chrome: back + banner + optional trailing action (Preview).
class AndroidBannerHeaderBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AndroidBannerHeaderBar({
    super.key,
    this.onBack,
    this.trailing,
    this.backgroundColor,
    this.topPadding = 0,
  });

  final VoidCallback? onBack;
  final Widget? trailing;
  final Color? backgroundColor;

  /// Status-bar inset so back/edit sit below the system UI (Android).
  final double topPadding;

  static const double toolbarHeight = 56;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight + topPadding);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).cardColor;
    return Material(
      color: bg,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: SizedBox(
          height: toolbarHeight,
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                )
              else
                const SizedBox(width: 8),
              const Expanded(
                child: AndroidBannerAdSlot(
                  placement: AndroidBannerPlacement.preview,
                  height: 50,
                ),
              ),
              if (trailing != null) trailing! else const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
