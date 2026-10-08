import 'package:flutter/foundation.dart';

import 'user_progress.dart';

/// Static description of an achievement and how progress is measured.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.target,
    required this.metric,
  });

  final String id;
  final String title;
  final String description;

  /// Icon identifier, mapped to a const icon in the UI layer (keeps models
  /// UI-agnostic and icon fonts tree-shakeable).
  final String iconKey;
  final int target;
  final int Function(UserProgress progress) metric;

  bool isMet(UserProgress p) => metric(p) >= target;
}

@immutable
class AchievementStatus {
  const AchievementStatus({
    required this.achievement,
    required this.current,
    this.unlockedAt,
  });

  final Achievement achievement;
  final int current;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;
  double get progress => (current / achievement.target).clamp(0, 1).toDouble();
}
