import 'package:flutter/foundation.dart';

import 'json_utils.dart';

/// answered / correct counter used for accuracy breakdowns.
@immutable
class AccuracyCounter {
  const AccuracyCounter({this.answered = 0, this.correct = 0});

  final int answered;
  final int correct;

  double get accuracy => answered == 0 ? 0 : correct / answered;
  int get incorrect => answered - correct;

  AccuracyCounter add({required bool isCorrect}) => AccuracyCounter(
    answered: answered + 1,
    correct: correct + (isCorrect ? 1 : 0),
  );

  factory AccuracyCounter.fromJson(JsonMap json) => AccuracyCounter(
    answered: json.optInt('answered'),
    correct: json.optInt('correct'),
  );

  JsonMap toJson() => {'answered': answered, 'correct': correct};
}

@immutable
class QuizHistoryEntry {
  const QuizHistoryEntry({
    required this.completedAt,
    required this.total,
    required this.correct,
    required this.label,
  });

  final DateTime completedAt;
  final int total;
  final int correct;
  final String label;

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();

  factory QuizHistoryEntry.fromJson(JsonMap json) => QuizHistoryEntry(
    completedAt:
        DateTime.tryParse(json.optString('completedAt')) ?? DateTime(2024),
    total: json.optInt('total'),
    correct: json.optInt('correct'),
    label: json.optString('label'),
  );

  JsonMap toJson() => {
    'completedAt': completedAt.toIso8601String(),
    'total': total,
    'correct': correct,
    'label': label,
  };
}

@immutable
class QuizStats {
  const QuizStats({
    this.totalQuizzes = 0,
    this.perfectQuizzes = 0,
    this.bestScorePercent = 0,
    this.sumScorePercent = 0,
    this.overall = const AccuracyCounter(),
    this.byCategory = const {},
    this.byDifficulty = const {},
    this.quizzesByDay = const {},
    this.history = const [],
  });

  static const int maxHistory = 30;

  final int totalQuizzes;
  final int perfectQuizzes;
  final int bestScorePercent;
  final int sumScorePercent;
  final AccuracyCounter overall;

  /// Keyed by [Track.slug].
  final Map<String, AccuracyCounter> byCategory;

  /// Keyed by [Difficulty.slug].
  final Map<String, AccuracyCounter> byDifficulty;

  /// Completed quizzes per day key.
  final Map<String, int> quizzesByDay;

  /// Most recent first.
  final List<QuizHistoryEntry> history;

  int get questionsAnswered => overall.answered;
  int get correctAnswers => overall.correct;
  int get incorrectAnswers => overall.incorrect;
  double get accuracy => overall.accuracy;
  double get averageScorePercent =>
      totalQuizzes == 0 ? 0 : sumScorePercent / totalQuizzes;

  AccuracyCounter category(String slug) =>
      byCategory[slug] ?? const AccuracyCounter();
  AccuracyCounter difficulty(String slug) =>
      byDifficulty[slug] ?? const AccuracyCounter();

  QuizStats copyWith({
    int? totalQuizzes,
    int? perfectQuizzes,
    int? bestScorePercent,
    int? sumScorePercent,
    AccuracyCounter? overall,
    Map<String, AccuracyCounter>? byCategory,
    Map<String, AccuracyCounter>? byDifficulty,
    Map<String, int>? quizzesByDay,
    List<QuizHistoryEntry>? history,
  }) => QuizStats(
    totalQuizzes: totalQuizzes ?? this.totalQuizzes,
    perfectQuizzes: perfectQuizzes ?? this.perfectQuizzes,
    bestScorePercent: bestScorePercent ?? this.bestScorePercent,
    sumScorePercent: sumScorePercent ?? this.sumScorePercent,
    overall: overall ?? this.overall,
    byCategory: byCategory ?? this.byCategory,
    byDifficulty: byDifficulty ?? this.byDifficulty,
    quizzesByDay: quizzesByDay ?? this.quizzesByDay,
    history: history ?? this.history,
  );

  factory QuizStats.fromJson(JsonMap json) {
    Map<String, AccuracyCounter> counters(String key) => {
      for (final e in (json.obj(key) ?? const <String, Object?>{}).entries)
        if (e.value is Map)
          e.key: AccuracyCounter.fromJson(
            (e.value! as Map).cast<String, Object?>(),
          ),
    };
    return QuizStats(
      totalQuizzes: json.optInt('totalQuizzes'),
      perfectQuizzes: json.optInt('perfectQuizzes'),
      bestScorePercent: json.optInt('bestScorePercent'),
      sumScorePercent: json.optInt('sumScorePercent'),
      overall: AccuracyCounter.fromJson(
        json.obj('overall') ?? const <String, Object?>{},
      ),
      byCategory: counters('byCategory'),
      byDifficulty: counters('byDifficulty'),
      quizzesByDay: json.intMap('quizzesByDay'),
      history: json.mapList('history').map(QuizHistoryEntry.fromJson).toList(),
    );
  }

  JsonMap toJson() => {
    'totalQuizzes': totalQuizzes,
    'perfectQuizzes': perfectQuizzes,
    'bestScorePercent': bestScorePercent,
    'sumScorePercent': sumScorePercent,
    'overall': overall.toJson(),
    'byCategory': {for (final e in byCategory.entries) e.key: e.value.toJson()},
    'byDifficulty': {
      for (final e in byDifficulty.entries) e.key: e.value.toJson(),
    },
    'quizzesByDay': quizzesByDay,
    'history': history.map((e) => e.toJson()).toList(),
  };
}

@immutable
class StreakState {
  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.activeDays = const [],
  });

  /// How many recent active days to retain for calendars.
  static const int maxActiveDays = 120;

  final int currentStreak;
  final int longestStreak;

  /// Day key (`yyyy-MM-dd`) of the most recent meaningful activity.
  final String? lastActiveDate;

  /// Day keys with activity, oldest first.
  final List<String> activeDays;

  factory StreakState.fromJson(JsonMap json) => StreakState(
    currentStreak: json.optInt('currentStreak'),
    longestStreak: json.optInt('longestStreak'),
    lastActiveDate: json.nullableString('lastActiveDate'),
    activeDays: json.stringList('activeDays'),
  );

  JsonMap toJson() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastActiveDate': lastActiveDate,
    'activeDays': activeDays,
  };
}

/// Everything about the learner's progress, persisted as one document.
@immutable
class UserProgress {
  const UserProgress({
    this.totalXp = 0,
    this.xpByDay = const {},
    this.completedLessons = const [],
    this.lastOpenedLessonId,
    this.streak = const StreakState(),
    this.interviewKnown = const {},
    this.interviewPractice = const {},
    this.dailyChallengeDays = const {},
    this.achievements = const {},
    this.rewardedClaimsByDay = const {},
    this.quizStats = const QuizStats(),
  });

  static const int schemaVersion = 1;

  final int totalXp;
  final Map<String, int> xpByDay;

  /// Completed lesson ids in completion order (most recent last).
  final List<String> completedLessons;
  final String? lastOpenedLessonId;
  final StreakState streak;
  final Set<String> interviewKnown;
  final Set<String> interviewPractice;
  final Set<String> dailyChallengeDays;

  /// Achievement id → ISO timestamp of unlock.
  final Map<String, String> achievements;
  final Map<String, int> rewardedClaimsByDay;
  final QuizStats quizStats;

  int get lessonsCompleted => completedLessons.length;
  int get interviewCompleted =>
      interviewKnown.length + interviewPractice.length;
  bool isLessonCompleted(String id) => completedLessons.contains(id);
  bool isInterviewDone(String id) =>
      interviewKnown.contains(id) || interviewPractice.contains(id);

  int xpOn(String dayKey) => xpByDay[dayKey] ?? 0;

  UserProgress copyWith({
    int? totalXp,
    Map<String, int>? xpByDay,
    List<String>? completedLessons,
    String? Function()? lastOpenedLessonId,
    StreakState? streak,
    Set<String>? interviewKnown,
    Set<String>? interviewPractice,
    Set<String>? dailyChallengeDays,
    Map<String, String>? achievements,
    Map<String, int>? rewardedClaimsByDay,
    QuizStats? quizStats,
  }) => UserProgress(
    totalXp: totalXp ?? this.totalXp,
    xpByDay: xpByDay ?? this.xpByDay,
    completedLessons: completedLessons ?? this.completedLessons,
    lastOpenedLessonId: lastOpenedLessonId != null
        ? lastOpenedLessonId()
        : this.lastOpenedLessonId,
    streak: streak ?? this.streak,
    interviewKnown: interviewKnown ?? this.interviewKnown,
    interviewPractice: interviewPractice ?? this.interviewPractice,
    dailyChallengeDays: dailyChallengeDays ?? this.dailyChallengeDays,
    achievements: achievements ?? this.achievements,
    rewardedClaimsByDay: rewardedClaimsByDay ?? this.rewardedClaimsByDay,
    quizStats: quizStats ?? this.quizStats,
  );

  factory UserProgress.fromJson(JsonMap json) => UserProgress(
    totalXp: json.optInt('totalXp'),
    xpByDay: json.intMap('xpByDay'),
    completedLessons: json.stringList('completedLessons'),
    lastOpenedLessonId: json.nullableString('lastOpenedLessonId'),
    streak: StreakState.fromJson(
      json.obj('streak') ?? const <String, Object?>{},
    ),
    interviewKnown: json.stringList('interviewKnown').toSet(),
    interviewPractice: json.stringList('interviewPractice').toSet(),
    dailyChallengeDays: json.stringList('dailyChallengeDays').toSet(),
    achievements: json.stringMap('achievements'),
    rewardedClaimsByDay: json.intMap('rewardedClaimsByDay'),
    quizStats: QuizStats.fromJson(
      json.obj('quizStats') ?? const <String, Object?>{},
    ),
  );

  JsonMap toJson() => {
    'schemaVersion': schemaVersion,
    'totalXp': totalXp,
    'xpByDay': xpByDay,
    'completedLessons': completedLessons,
    'lastOpenedLessonId': lastOpenedLessonId,
    'streak': streak.toJson(),
    'interviewKnown': interviewKnown.toList(),
    'interviewPractice': interviewPractice.toList(),
    'dailyChallengeDays': dailyChallengeDays.toList(),
    'achievements': achievements,
    'rewardedClaimsByDay': rewardedClaimsByDay,
    'quizStats': quizStats.toJson(),
  };
}
