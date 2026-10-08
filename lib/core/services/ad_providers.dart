import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/ad_config.dart';
import '../providers/core_providers.dart';
import 'ad_service.dart';
import 'subscription_service.dart';

final adServiceProvider = Provider<AdService>((ref) {
  final AdService service = GoogleMobileAdsService.platformSupported
      ? GoogleMobileAdsService()
      : const NoopAdService();
  ref.onDispose(service.dispose);
  return service;
});

/// True once consent is resolved, the SDK is initialized and the user is not
/// premium. Everything ad-related checks this before doing work.
class AdsEnabledNotifier extends Notifier<bool> {
  bool _sdkReady = false;

  @override
  bool build() {
    final premium = ref.watch(isPremiumProvider);
    return _sdkReady && !premium;
  }

  /// Runs the consent flow + SDK init. Safe to call more than once.
  Future<void> initialize() async {
    final service = ref.read(adServiceProvider);
    if (!service.isSupported || ref.read(isPremiumProvider)) return;
    final ok = await service.initialize();
    if (!ref.mounted) return;
    _sdkReady = ok;
    state = ok && !ref.read(isPremiumProvider);
    if (state) {
      unawaited(service.preloadInterstitial());
      unawaited(ref.read(rewardedAdProvider.notifier).load());
    }
  }
}

final adsEnabledProvider = NotifierProvider<AdsEnabledNotifier, bool>(
  AdsEnabledNotifier.new,
);

/// Pure frequency-capping policy for interstitials (unit-testable).
class InterstitialPolicy {
  InterstitialPolicy({required this.appStartedAt});

  final DateTime appStartedAt;
  int _breaksSinceLastShow = 0;
  DateTime? _lastShownAt;

  /// Records a natural break and reports whether an ad may be shown now.
  bool registerBreak(DateTime now) {
    _breaksSinceLastShow++;
    if (now.difference(appStartedAt) < AdConfig.interstitialStartupGrace) {
      return false;
    }
    if (_breaksSinceLastShow < AdConfig.interstitialBreaksBetweenShows) {
      return false;
    }
    final last = _lastShownAt;
    if (last != null &&
        now.difference(last) < AdConfig.interstitialMinInterval) {
      return false;
    }
    return true;
  }

  void markShown(DateTime now) {
    _breaksSinceLastShow = 0;
    _lastShownAt = now;
  }
}

/// Shows interstitials only at natural breaks (finished quiz, finished
/// interview set) and never more often than [AdConfig] allows.
class InterstitialAdManager {
  InterstitialAdManager(this._ref)
    : _policy = InterstitialPolicy(appStartedAt: _ref.read(clockProvider)());

  final Ref _ref;
  final InterstitialPolicy _policy;

  Future<void> onNaturalBreak() async {
    if (!_ref.read(adsEnabledProvider)) return;
    final now = _ref.read(clockProvider)();
    if (!_policy.registerBreak(now)) return;
    final shown = await _ref.read(adServiceProvider).showInterstitial();
    if (shown) _policy.markShown(_ref.read(clockProvider)());
  }
}

final interstitialAdManagerProvider = Provider<InterstitialAdManager>(
  InterstitialAdManager.new,
);

enum RewardedAdStatus { unavailable, loading, ready }

/// Rewarded ad state. Users always opt in explicitly by tapping a button.
class RewardedAdNotifier extends Notifier<RewardedAdStatus> {
  @override
  RewardedAdStatus build() => RewardedAdStatus.unavailable;

  Future<void> load() async {
    if (!ref.read(adsEnabledProvider)) return;
    final service = ref.read(adServiceProvider);
    if (service.isRewardedReady) {
      state = RewardedAdStatus.ready;
      return;
    }
    state = RewardedAdStatus.loading;
    final ok = await service.preloadRewarded();
    if (!ref.mounted) return;
    state = ok ? RewardedAdStatus.ready : RewardedAdStatus.unavailable;
  }

  /// Shows the ad; returns true if the reward was earned.
  Future<bool> show() async {
    if (state != RewardedAdStatus.ready) return false;
    final earned = await ref.read(adServiceProvider).showRewarded();
    if (!ref.mounted) return earned;
    state = RewardedAdStatus.unavailable;
    unawaited(load());
    return earned;
  }
}

final rewardedAdProvider =
    NotifierProvider<RewardedAdNotifier, RewardedAdStatus>(
      RewardedAdNotifier.new,
    );

/// Whether the privacy options entry point must be shown (UMP requirement).
final privacyOptionsRequiredProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref.watch(adServiceProvider).isPrivacyOptionsRequired();
  } catch (e) {
    debugPrint('Privacy options check failed: $e');
    return false;
  }
});
