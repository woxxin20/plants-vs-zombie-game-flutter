/// Ads and IAP — spec §20. No backend, no receipt server.
///
/// AD UNIT IDS ARE GOOGLE'S PUBLIC TEST IDS. Shipping with these serves test
/// ads and earns nothing; real ids are a blocked open question (ARCH-Q-002 /
/// PRD-Q-001) and must be swapped in before any store build.
library;

import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'save_store.dart';

/// The single non-consumable. Must match the id created in both stores.
const String kRemoveAdsProductId = 'remove_ads';

abstract final class AdIds {
  // ponytail: test ids inline until the real ones exist; swapping them is a
  // two-line change here, so a config layer would be machinery for nothing.
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get rewarded => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
}

/// Loads and shows the three ad formats. Every entry point is a no-op when the
/// player bought Remove Ads, so no call site needs to check.
class AdService {
  AdService._();
  static final AdService I = AdService._();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  bool get _suppressed => SaveStore.I.state.removeAds;

  /// Wins since the last interstitial — spec §20 caps it at 1 in 3.
  int _winsSinceInterstitial = 0;

  Future<void> init() async {
    if (_suppressed) return;
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  // --- banner ------------------------------------------------------------

  /// Builds a banner for Home/Map. Returns null when ads are off, so the shell
  /// can simply omit the widget. Never shown during a battle (spec §20).
  BannerAd? createBanner({required void Function() onLoaded}) {
    if (_suppressed) return null;
    return BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  // --- interstitial ------------------------------------------------------

  void _loadInterstitial() {
    if (_suppressed) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Called after a win. Shows at most one interstitial per three wins.
  void maybeShowInterstitial() {
    if (_suppressed) return;
    _winsSinceInterstitial++;
    final ad = _interstitial;
    if (ad == null || _winsSinceInterstitial < 3) return;
    _winsSinceInterstitial = 0;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  // --- rewarded ----------------------------------------------------------

  void _loadRewarded() {
    if (_suppressed) return;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  bool get rewardedReady => !_suppressed && _rewarded != null;

  /// Shows the +50 Glow rewarded ad. [onRewarded] fires only on an actual
  /// reward callback — never optimistically.
  void showRewarded({required void Function() onRewarded}) {
    final ad = _rewarded;
    if (ad == null) return;
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (_, _) => onRewarded());
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}

/// The single Remove Ads purchase. Local entitlement only — with no backend
/// there is nothing to validate against, which spec §20 accepts explicitly.
class IapService {
  IapService._();
  static final IapService I = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  ProductDetails? _product;
  Stream<List<PurchaseDetails>>? _stream;

  ProductDetails? get product => _product;
  String get priceLabel => _product?.price ?? '\$2.99';

  Future<void> init({void Function()? onEntitlementChanged}) async {
    if (!await _iap.isAvailable()) return;

    final response = await _iap.queryProductDetails({kRemoveAdsProductId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }

    _stream = _iap.purchaseStream;
    _stream!.listen((purchases) async {
      for (final p in purchases) {
        switch (p.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            if (p.productID == kRemoveAdsProductId) {
              SaveStore.I.state.removeAds = true;
              await SaveStore.I.flush();
              onEntitlementChanged?.call();
            }
          case PurchaseStatus.error:
          case PurchaseStatus.canceled:
          case PurchaseStatus.pending:
            break;
        }
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      }
    });
  }

  Future<void> buyRemoveAds() async {
    final p = _product;
    if (p == null) return;
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
  }

  Future<void> restore() => _iap.restorePurchases();
}
