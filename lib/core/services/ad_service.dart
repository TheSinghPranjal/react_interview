import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_config.dart';

/// Centralized ad lifecycle. Widgets never instantiate ads themselves.
///
/// Every method is failure-tolerant: a failed load or show resolves to
/// `false`/`null` instead of throwing, so ads can never crash the app.
abstract interface class AdService {
  /// Whether this platform supports ads at all.
  bool get isSupported;

  /// Gathers consent (Google UMP) and initializes the SDK.
  /// Returns true if ads may be requested.
  Future<bool> initialize();

  /// Loads an adaptive banner for [width] logical pixels.
  Future<BannerAd?> loadBanner(int width);

  Future<bool> preloadInterstitial();
  Future<bool> showInterstitial();

  Future<bool> preloadRewarded();
  bool get isRewardedReady;

  /// Shows the rewarded ad. Resolves to true only if the user earned the
  /// reward.
  Future<bool> showRewarded();

  Future<bool> isPrivacyOptionsRequired();
  Future<void> showPrivacyOptions();

  void dispose();
}

/// Used on unsupported platforms, in tests, and when ads are disabled.
class NoopAdService implements AdService {
  const NoopAdService();

  @override
  bool get isSupported => false;
  @override
  Future<bool> initialize() async => false;
  @override
  Future<BannerAd?> loadBanner(int width) async => null;
  @override
  Future<bool> preloadInterstitial() async => false;
  @override
  Future<bool> showInterstitial() async => false;
  @override
  Future<bool> preloadRewarded() async => false;
  @override
  bool get isRewardedReady => false;
  @override
  Future<bool> showRewarded() async => false;
  @override
  Future<bool> isPrivacyOptionsRequired() async => false;
  @override
  Future<void> showPrivacyOptions() async {}
  @override
  void dispose() {}
}

class GoogleMobileAdsService implements AdService {
  GoogleMobileAdsService();

  static bool get platformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool _initialized = false;
  Future<bool>? _initFuture;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  String get _bannerId =>
      Platform.isIOS ? AdConfig.iosBannerId : AdConfig.androidBannerId;
  String get _interstitialId => Platform.isIOS
      ? AdConfig.iosInterstitialId
      : AdConfig.androidInterstitialId;
  String get _rewardedId =>
      Platform.isIOS ? AdConfig.iosRewardedId : AdConfig.androidRewardedId;

  @override
  bool get isSupported => platformSupported;

  @override
  Future<bool> initialize() => _initFuture ??= _initialize();

  Future<bool> _initialize() async {
    if (!isSupported) return false;
    try {
      await _gatherConsent();
    } catch (e) {
      debugPrint('Consent flow did not complete: $e');
    }
    try {
      if (!await ConsentInformation.instance.canRequestAds()) return false;
      await MobileAds.instance.initialize();
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('Mobile Ads initialization failed: $e');
      _initFuture = null;
      return false;
    }
  }

  /// Requests the latest consent info (time-limited, since it's a network
  /// call) and then shows Google's consent form only when required (e.g.
  /// EEA/UK users). The form itself is never timed out: it waits for the user.
  Future<void> _gatherConsent() async {
    final update = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!update.isCompleted) update.complete(true);
      },
      (error) {
        debugPrint('Consent info update failed: ${error.message}');
        if (!update.isCompleted) update.complete(false);
      },
    );
    final updated = await update.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => false,
    );
    if (!updated) return;

    final dismissed = Completer<void>();
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) debugPrint('Consent form: ${error.message}');
      if (!dismissed.isCompleted) dismissed.complete();
    });
    await dismissed.future;
  }

  @override
  Future<BannerAd?> loadBanner(int width) async {
    if (!_initialized) return null;
    try {
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      final completer = Completer<BannerAd?>();
      final ad = BannerAd(
        adUnitId: _bannerId,
        size: size ?? AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => completer.complete(ad as BannerAd),
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner failed: ${error.message}');
            unawaited(ad.dispose());
            completer.complete(null);
          },
        ),
      );
      await ad.load();
      return completer.future;
    } catch (e) {
      debugPrint('Banner error: $e');
      return null;
    }
  }

  @override
  Future<bool> preloadInterstitial() async {
    if (!_initialized || _interstitial != null || _loadingInterstitial) {
      return _interstitial != null;
    }
    _loadingInterstitial = true;
    final completer = Completer<bool>();
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial failed: ${error.message}');
            completer.complete(false);
          },
        ),
      );
      return await completer.future;
    } catch (e) {
      debugPrint('Interstitial error: $e');
      return false;
    } finally {
      _loadingInterstitial = false;
    }
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      unawaited(preloadInterstitial());
      return false;
    }
    _interstitial = null;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        unawaited(ad.dispose());
        if (!completer.isCompleted) completer.complete(true);
        unawaited(preloadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        unawaited(ad.dispose());
        if (!completer.isCompleted) completer.complete(false);
        unawaited(preloadInterstitial());
      },
    );
    try {
      await ad.show();
    } catch (e) {
      unawaited(ad.dispose());
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  @override
  bool get isRewardedReady => _rewarded != null;

  @override
  Future<bool> preloadRewarded() async {
    if (!_initialized || _rewarded != null || _loadingRewarded) {
      return _rewarded != null;
    }
    _loadingRewarded = true;
    final completer = Completer<bool>();
    try {
      await RewardedAd.load(
        adUnitId: _rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewarded = ad;
            completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded failed: ${error.message}');
            completer.complete(false);
          },
        ),
      );
      return await completer.future;
    } catch (e) {
      debugPrint('Rewarded error: $e');
      return false;
    } finally {
      _loadingRewarded = false;
    }
  }

  @override
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        unawaited(ad.dispose());
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        unawaited(ad.dispose());
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (e) {
      unawaited(ad.dispose());
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    if (!isSupported) return false;
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    if (!isSupported) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) debugPrint('Privacy options: ${error.message}');
      });
    } catch (e) {
      debugPrint('Privacy options error: $e');
    }
  }

  @override
  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
  }
}
