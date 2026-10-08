import 'package:flutter/foundation.dart';

/// XP → level calculation.
///
/// Level 1: 0 XP, Level 2: 100, Level 3: 250, Level 4: 500, then each level
/// needs 100 XP more than the previous gap (850, 1300, 1850, 2500, ...).
abstract final class LevelSystem {
  static const List<int> _base = [0, 100, 250, 500];

  /// Total XP required to reach [level] (1-based).
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    if (level <= _base.length) return _base[level - 1];
    var xp = _base.last;
    var gap = _base.last - _base[_base.length - 2]; // 250
    for (var l = _base.length + 1; l <= level; l++) {
      gap += 100;
      xp += gap;
    }
    return xp;
  }

  static LevelInfo fromXp(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;
    var level = 1;
    while (xpForLevel(level + 1) <= xp) {
      level++;
    }
    return LevelInfo(
      level: level,
      totalXp: xp,
      currentLevelXp: xpForLevel(level),
      nextLevelXp: xpForLevel(level + 1),
    );
  }

  static String title(int level) {
    if (level < 3) return 'Beginner';
    if (level < 5) return 'Explorer';
    if (level < 8) return 'Builder';
    if (level < 12) return 'Engineer';
    if (level < 16) return 'Senior Engineer';
    return 'React Master';
  }
}

@immutable
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.totalXp,
    required this.currentLevelXp,
    required this.nextLevelXp,
  });

  final int level;
  final int totalXp;
  final int currentLevelXp;
  final int nextLevelXp;

  int get xpIntoLevel => totalXp - currentLevelXp;
  int get xpNeededForLevel => nextLevelXp - currentLevelXp;
  int get xpToNextLevel => nextLevelXp - totalXp;
  double get progress =>
      xpNeededForLevel == 0 ? 0 : xpIntoLevel / xpNeededForLevel;
  String get title => LevelSystem.title(level);
}
