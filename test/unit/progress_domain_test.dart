import 'package:flutter_test/flutter_test.dart';
import 'package:react_interview/core/constants/ad_config.dart';
import 'package:react_interview/core/services/ad_providers.dart';
import 'package:react_interview/core/utils/levels.dart';
import 'package:react_interview/data/models/user_progress.dart';
import 'package:react_interview/features/achievements/domain/achievement_catalog.dart';
import 'package:react_interview/features/progress/domain/streak_calculator.dart';

void main() {
  group('LevelSystem', () {
    test('matches the documented thresholds', () {
      expect(LevelSystem.xpForLevel(1), 0);
      expect(LevelSystem.xpForLevel(2), 100);
      expect(LevelSystem.xpForLevel(3), 250);
      expect(LevelSystem.xpForLevel(4), 500);
      expect(LevelSystem.xpForLevel(5), 850);
      expect(LevelSystem.xpForLevel(6), 1300);
    });

    test('thresholds strictly increase', () {
      for (var l = 1; l < 40; l++) {
        expect(
          LevelSystem.xpForLevel(l + 1),
          greaterThan(LevelSystem.xpForLevel(l)),
        );
      }
    });

    test('fromXp computes level and progress', () {
      expect(LevelSystem.fromXp(0).level, 1);
      expect(LevelSystem.fromXp(99).level, 1);
      expect(LevelSystem.fromXp(100).level, 2);
      final info = LevelSystem.fromXp(175);
      expect(info.level, 2);
      expect(info.xpIntoLevel, 75);
      expect(info.xpToNextLevel, 75);
      expect(info.progress, closeTo(0.5, 0.0001));
      expect(LevelSystem.fromXp(-5).level, 1);
    });
  });

  group('StreakCalculator', () {
    final day1 = DateTime(2026, 10, 5, 10); // Monday

    test('first activity starts a streak of 1', () {
      final s = StreakCalculator.registerActivity(const StreakState(), day1);
      expect(s.currentStreak, 1);
      expect(s.longestStreak, 1);
      expect(s.lastActiveDate, '2026-10-05');
    });

    test('same day activity does not change the streak', () {
      final s1 = StreakCalculator.registerActivity(const StreakState(), day1);
      final s2 = StreakCalculator.registerActivity(
        s1,
        day1.add(const Duration(hours: 5)),
      );
      expect(identical(s1, s2), isTrue);
    });

    test('consecutive days extend; a gap resets', () {
      var s = StreakCalculator.registerActivity(const StreakState(), day1);
      s = StreakCalculator.registerActivity(s, DateTime(2026, 10, 6, 23, 59));
      s = StreakCalculator.registerActivity(s, DateTime(2026, 10, 7, 0, 1));
      expect(s.currentStreak, 3);
      s = StreakCalculator.registerActivity(s, DateTime(2026, 10, 10));
      expect(s.currentStreak, 1);
      expect(s.longestStreak, 3);
    });

    test('effective streak drops to 0 after a missed day', () {
      var s = StreakCalculator.registerActivity(const StreakState(), day1);
      s = StreakCalculator.registerActivity(s, DateTime(2026, 10, 6));
      expect(StreakCalculator.effectiveStreak(s, DateTime(2026, 10, 7)), 2);
      expect(StreakCalculator.effectiveStreak(s, DateTime(2026, 10, 8)), 0);
    });

    test('clock moving backwards keeps the streak', () {
      final s = StreakCalculator.registerActivity(const StreakState(), day1);
      final back = StreakCalculator.registerActivity(s, DateTime(2026, 10, 1));
      expect(back.currentStreak, 1);
      expect(back.lastActiveDate, '2026-10-05');
    });

    test('current week runs Monday to Sunday with active flags', () {
      var s = StreakCalculator.registerActivity(const StreakState(), day1);
      s = StreakCalculator.registerActivity(s, DateTime(2026, 10, 6));
      final week = StreakCalculator.currentWeek(s, DateTime(2026, 10, 7));
      expect(week.map((d) => d.label), [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ]);
      expect(week.map((d) => d.isActive), [
        true,
        true,
        false,
        false,
        false,
        false,
        false,
      ]);
      expect(week[2].isToday, isTrue);
      expect(week[3].isFuture, isTrue);
    });
  });

  group('AchievementCatalog', () {
    test('unlocks first lesson and lessons_10 by metric', () {
      final p = UserProgress(
        completedLessons: [for (var i = 0; i < 10; i++) 'l$i'],
      );
      final ids = AchievementCatalog.newlyUnlocked(p).map((a) => a.id);
      expect(ids, containsAll(['first_lesson', 'lessons_10']));
      expect(ids, isNot(contains('lessons_50')));
    });

    test('does not re-unlock recorded achievements', () {
      final p = const UserProgress(
        completedLessons: ['a'],
        achievements: {'first_lesson': '2026-01-01'},
      );
      expect(
        AchievementCatalog.newlyUnlocked(p).map((a) => a.id),
        isNot(contains('first_lesson')),
      );
    });

    test('statuses expose progress', () {
      final s = AchievementCatalog.statuses(
        const UserProgress(
          quizStats: QuizStats(
            overall: AccuracyCounter(answered: 10, correct: 5),
          ),
        ),
      ).firstWhere((s) => s.achievement.id == 'correct_10');
      expect(s.progress, 0.5);
      expect(s.isUnlocked, isFalse);
    });
  });

  group('InterstitialPolicy', () {
    final start = DateTime(2026, 1, 1, 12);

    test('never shows during the startup grace period', () {
      final policy = InterstitialPolicy(appStartedAt: start);
      for (var i = 0; i < 5; i++) {
        expect(
          policy.registerBreak(start.add(const Duration(seconds: 30))),
          isFalse,
        );
      }
    });

    test('requires several breaks and a minimum interval', () {
      final policy = InterstitialPolicy(appStartedAt: start);
      var t = start.add(AdConfig.interstitialStartupGrace);
      expect(policy.registerBreak(t), isFalse, reason: 'first break');
      expect(policy.registerBreak(t), isTrue, reason: 'second break');
      policy.markShown(t);
      t = t.add(const Duration(minutes: 1));
      expect(policy.registerBreak(t), isFalse);
      expect(policy.registerBreak(t), isFalse, reason: 'interval not elapsed');
      t = t.add(AdConfig.interstitialMinInterval);
      expect(policy.registerBreak(t), isTrue);
    });
  });
}
