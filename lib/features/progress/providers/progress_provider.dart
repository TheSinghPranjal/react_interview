import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/levels.dart';
import '../../../data/models/achievement.dart';
import '../../../data/models/mcq_question.dart';
import '../../../data/models/quiz_session.dart';
import '../../../data/models/user_progress.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../achievements/domain/achievement_catalog.dart';
import '../domain/streak_calculator.dart';

/// What happened as a result of a learning activity, so the UI can celebrate.
@immutable
class ActivityOutcome {
  const ActivityOutcome({
    this.xpGained = 0,
    this.newLevel,
    this.newAchievements = const [],
    this.streakExtendedTo,
  });

  static const none = ActivityOutcome();

  final int xpGained;

  /// Non-null if the user leveled up.
  final int? newLevel;
  final List<Achievement> newAchievements;

  /// Non-null when this activity extended the streak to a new day.
  final int? streakExtendedTo;

  bool get hasNews =>
      xpGained > 0 ||
      newLevel != null ||
      newAchievements.isNotEmpty ||
      streakExtendedTo != null;
}

/// Owns all learner progress: XP, streaks, completions, quiz stats and
/// achievements. Every mutation persists through [ProgressRepository].
class ProgressNotifier extends Notifier<UserProgress> {
  static const int _xpHistoryDays = 60;

  @override
  UserProgress build() => ref.read(progressRepositoryProvider).load();

  DateTime get _now => ref.read(clockProvider)();

  // ---------------------------------------------------------------------------
  // Lessons
  // ---------------------------------------------------------------------------

  void openLesson(String lessonId) {
    if (state.lastOpenedLessonId == lessonId) return;
    _commit(state.copyWith(lastOpenedLessonId: () => lessonId));
  }

  ActivityOutcome completeLesson(String lessonId) {
    if (state.isLessonCompleted(lessonId)) return ActivityOutcome.none;
    return _apply(
      state.copyWith(
        completedLessons: [...state.completedLessons, lessonId],
        lastOpenedLessonId: () => lessonId,
      ),
      xp: XpRewards.lessonCompleted,
    );
  }

  // ---------------------------------------------------------------------------
  // Interview
  // ---------------------------------------------------------------------------

  /// Marks an interview question as known or needing practice. XP is only
  /// awarded the first time a question is reviewed.
  ActivityOutcome markInterviewQuestion(String id, {required bool known}) {
    final firstTime = !state.isInterviewDone(id);
    final knownSet = {...state.interviewKnown};
    final practiceSet = {...state.interviewPractice};
    if (known) {
      knownSet.add(id);
      practiceSet.remove(id);
    } else {
      practiceSet.add(id);
      knownSet.remove(id);
    }
    return _apply(
      state.copyWith(interviewKnown: knownSet, interviewPractice: practiceSet),
      xp: firstTime ? XpRewards.interviewQuestionCompleted : 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Quiz
  // ---------------------------------------------------------------------------

  ActivityOutcome recordQuizAnswer(
    McqQuestion question, {
    required bool correct,
  }) {
    final s = state.quizStats;
    final cat = question.category.slug;
    final diff = question.difficulty.slug;
    final stats = s.copyWith(
      overall: s.overall.add(isCorrect: correct),
      byCategory: {
        ...s.byCategory,
        cat: s.category(cat).add(isCorrect: correct),
      },
      byDifficulty: {
        ...s.byDifficulty,
        diff: s.difficulty(diff).add(isCorrect: correct),
      },
    );
    return _apply(
      state.copyWith(quizStats: stats),
      xp: correct ? XpRewards.correctMcq : 0,
    );
  }

  /// Records a finished quiz. Per-answer XP was already granted by
  /// [recordQuizAnswer]; this adds the perfect-score bonus.
  ActivityOutcome recordQuizCompleted(QuizResult result) {
    final s = state.quizStats;
    final dayKey = AppDates.dayKey(result.completedAt);
    final entry = QuizHistoryEntry(
      completedAt: result.completedAt,
      total: result.total,
      correct: result.correct,
      label: result.session.config.label,
    );
    final history = [entry, ...s.history];
    final stats = s.copyWith(
      totalQuizzes: s.totalQuizzes + 1,
      perfectQuizzes: s.perfectQuizzes + (result.isPerfect ? 1 : 0),
      bestScorePercent: result.percent > s.bestScorePercent
          ? result.percent
          : s.bestScorePercent,
      sumScorePercent: s.sumScorePercent + result.percent,
      quizzesByDay: _trimDays({
        ...s.quizzesByDay,
        dayKey: (s.quizzesByDay[dayKey] ?? 0) + 1,
      }),
      history: history.length > QuizStats.maxHistory
          ? history.sublist(0, QuizStats.maxHistory)
          : history,
    );
    return _apply(
      state.copyWith(quizStats: stats),
      xp: result.isPerfect ? XpRewards.perfectQuizBonus : 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Daily challenge & rewards
  // ---------------------------------------------------------------------------

  bool isDailyChallengeDone([DateTime? on]) =>
      state.dailyChallengeDays.contains(AppDates.dayKey(on ?? _now));

  ActivityOutcome completeDailyChallenge() {
    final key = AppDates.dayKey(_now);
    if (state.dailyChallengeDays.contains(key)) return ActivityOutcome.none;
    return _apply(
      state.copyWith(dailyChallengeDays: {...state.dailyChallengeDays, key}),
      xp: XpRewards.dailyChallenge,
    );
  }

  int rewardedClaimsToday() =>
      state.rewardedClaimsByDay[AppDates.dayKey(_now)] ?? 0;

  bool canClaimRewardedXp() =>
      rewardedClaimsToday() < XpRewards.maxRewardedClaimsPerDay;

  /// Grants rewarded-ad XP. Does not count as a learning activity for streaks.
  ActivityOutcome claimRewardedXp() {
    if (!canClaimRewardedXp()) return ActivityOutcome.none;
    final key = AppDates.dayKey(_now);
    return _apply(
      state.copyWith(
        rewardedClaimsByDay: _trimDays({
          ...state.rewardedClaimsByDay,
          key: rewardedClaimsToday() + 1,
        }),
      ),
      xp: XpRewards.rewardedAd,
      countsAsActivity: false,
    );
  }

  Future<void> resetAll() async {
    await ref.read(progressRepositoryProvider).reset();
    state = const UserProgress();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  ActivityOutcome _apply(
    UserProgress next, {
    required int xp,
    bool countsAsActivity = true,
  }) {
    final now = _now;
    final before = state;
    var updated = next;

    if (xp > 0) {
      final key = AppDates.dayKey(now);
      updated = updated.copyWith(
        totalXp: updated.totalXp + xp,
        xpByDay: _trimDays({...updated.xpByDay, key: updated.xpOn(key) + xp}),
      );
    }

    int? streakExtendedTo;
    if (countsAsActivity) {
      final streak = StreakCalculator.registerActivity(updated.streak, now);
      if (!identical(streak, updated.streak)) {
        updated = updated.copyWith(streak: streak);
        streakExtendedTo = streak.currentStreak;
      }
    }

    final unlocked = AchievementCatalog.newlyUnlocked(updated);
    if (unlocked.isNotEmpty) {
      final iso = now.toIso8601String();
      updated = updated.copyWith(
        achievements: {
          ...updated.achievements,
          for (final a in unlocked) a.id: iso,
        },
      );
    }

    _commit(updated);

    final levelBefore = LevelSystem.fromXp(before.totalXp).level;
    final levelAfter = LevelSystem.fromXp(updated.totalXp).level;
    return ActivityOutcome(
      xpGained: xp,
      newLevel: levelAfter > levelBefore ? levelAfter : null,
      newAchievements: unlocked,
      streakExtendedTo: streakExtendedTo,
    );
  }

  void _commit(UserProgress updated) {
    state = updated;
    // Fire-and-forget: the repository logs and swallows disk failures, and the
    // in-memory state stays correct for the session.
    ref.read(progressRepositoryProvider).save(updated).ignore();
  }

  Map<String, int> _trimDays(Map<String, int> byDay) {
    if (byDay.length <= _xpHistoryDays) return byDay;
    final keys = byDay.keys.toList()..sort();
    final keep = keys.sublist(keys.length - _xpHistoryDays).toSet();
    return {
      for (final e in byDay.entries)
        if (keep.contains(e.key)) e.key: e.value,
    };
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, UserProgress>(
  ProgressNotifier.new,
);

// ---------------------------------------------------------------------------
// Derived, narrowly-scoped providers (rebuild only what changed).
// ---------------------------------------------------------------------------

final xpProvider = Provider<int>(
  (ref) => ref.watch(progressProvider.select((p) => p.totalXp)),
);

final levelProvider = Provider<LevelInfo>(
  (ref) => LevelSystem.fromXp(ref.watch(xpProvider)),
);

final xpTodayProvider = Provider<int>((ref) {
  final key = AppDates.dayKey(ref.watch(clockProvider)());
  return ref.watch(progressProvider.select((p) => p.xpOn(key)));
});

@immutable
class StreakView {
  const StreakView({
    required this.current,
    required this.longest,
    required this.activeToday,
    required this.week,
  });

  final int current;
  final int longest;
  final bool activeToday;
  final List<StreakDay> week;
}

final streakProvider = Provider<StreakView>((ref) {
  final streak = ref.watch(progressProvider.select((p) => p.streak));
  final now = ref.watch(clockProvider)();
  return StreakView(
    current: StreakCalculator.effectiveStreak(streak, now),
    longest: streak.longestStreak,
    activeToday: StreakCalculator.isActiveToday(streak, now),
    week: StreakCalculator.currentWeek(streak, now),
  );
});

final quizStatsProvider = Provider<QuizStats>(
  (ref) => ref.watch(progressProvider.select((p) => p.quizStats)),
);

final achievementStatusesProvider = Provider<List<AchievementStatus>>(
  (ref) => AchievementCatalog.statuses(ref.watch(progressProvider)),
);
