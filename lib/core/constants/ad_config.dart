import 'package:flutter/foundation.dart';

/// Ad unit configuration.
///
/// Debug and profile builds ALWAYS use Google's public test ad units.
/// Release builds read production IDs from `--dart-define` values, e.g.:
///
/// ```sh
/// flutter build appbundle --release --dart-define-from-file=config/admob.json
/// ```
///
/// If a production ID is missing in a release build, the test ID is used so a
/// misconfigured build never serves live ads by accident. Production IDs are
/// never hardcoded in the codebase.
abstract final class AdConfig {
  // Google's official sample ad units:
  // https://developers.google.com/admob/android/test-ads
  static const _testAndroidBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const _testAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIosBanner = 'ca-app-pub-3940256099942544/2435281174';
  static const _testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static const _prodAndroidBanner = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
  );
  static const _prodAndroidInterstitial = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
  );
  static const _prodAndroidRewarded = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
  );
  static const _prodIosBanner = String.fromEnvironment('ADMOB_IOS_BANNER_ID');
  static const _prodIosInterstitial = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
  );
  static const _prodIosRewarded = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
  );

  static String _pick(String prod, String test) =>
      kReleaseMode && prod.isNotEmpty ? prod : test;

  static String get androidBannerId =>
      _pick(_prodAndroidBanner, _testAndroidBanner);
  static String get androidInterstitialId =>
      _pick(_prodAndroidInterstitial, _testAndroidInterstitial);
  static String get androidRewardedId =>
      _pick(_prodAndroidRewarded, _testAndroidRewarded);
  static String get iosBannerId => _pick(_prodIosBanner, _testIosBanner);
  static String get iosInterstitialId =>
      _pick(_prodIosInterstitial, _testIosInterstitial);
  static String get iosRewardedId => _pick(_prodIosRewarded, _testIosRewarded);

  /// Whether test ad units are currently in use.
  static bool get usingTestAds =>
      !kReleaseMode || _prodAndroidBanner.isEmpty || _prodIosBanner.isEmpty;

  // Frequency caps — keep ads respectful.

  /// Minimum natural breaks (finished quiz, finished interview set) between
  /// two interstitials.
  static const int interstitialBreaksBetweenShows = 2;

  /// Minimum time between two interstitials.
  static const Duration interstitialMinInterval = Duration(minutes: 4);

  /// No interstitial is ever shown during the first part of a session.
  static const Duration interstitialStartupGrace = Duration(minutes: 2);
}
