import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Features that a future premium tier could unlock.
enum PremiumFeature {
  removeAds,
  advancedInterviewQuestions,
  unlimitedQuizzes,
  advancedStatistics,
  offlineDownloads,
  mockInterviewMode,
}

/// Abstraction over in-app purchases. The app currently ships a free tier
/// only; a real implementation (e.g. `in_app_purchase` or RevenueCat) can be
/// dropped in by overriding [subscriptionServiceProvider]. No fake payments
/// are implemented.
abstract interface class SubscriptionService {
  bool get isPremium;
  bool hasFeature(PremiumFeature feature);

  /// Restores purchases from the store. No-op on the free tier.
  Future<void> restorePurchases();
}

class FreeTierSubscriptionService implements SubscriptionService {
  const FreeTierSubscriptionService();

  @override
  bool get isPremium => false;

  @override
  bool hasFeature(PremiumFeature feature) => false;

  @override
  Future<void> restorePurchases() async {}
}

final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => const FreeTierSubscriptionService(),
);

final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionServiceProvider).isPremium,
);
