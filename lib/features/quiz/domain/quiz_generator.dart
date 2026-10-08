import 'dart:math';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/shuffle.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/mcq_question.dart';
import '../../../data/models/quiz_session.dart';

class QuizGenerationException implements Exception {
  QuizGenerationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Builds randomized quiz sessions.
///
/// 1. Filter questions by category / difficulty.
/// 2. De-duplicate by id.
/// 3. Fisher–Yates shuffle the questions.
/// 4. Take N.
/// 5. Shuffle each question's options, tracking where the correct one lands.
class QuizGenerator {
  QuizGenerator(this._random);

  final Random _random;

  static List<McqQuestion> filter(
    List<McqQuestion> pool, {
    Track? category,
    Difficulty? difficulty,
  }) {
    final seen = <String>{};
    return [
      for (final q in pool)
        if ((category == null || q.category == category) &&
            (difficulty == null || q.difficulty == difficulty) &&
            seen.add(q.id))
          q,
    ];
  }

  /// Shuffles the options of [q], preserving which option is correct.
  QuizQuestion shuffleOptions(McqQuestion q) {
    final order = fisherYatesShuffle(
      List<int>.generate(q.options.length, (i) => i),
      _random,
    );
    return QuizQuestion(
      source: q,
      options: List.unmodifiable([for (final i in order) q.options[i]]),
      correctIndex: order.indexOf(q.correctAnswer),
      optionOrder: List.unmodifiable(order),
    );
  }

  /// Creates a randomized list of quiz questions for [config].
  ///
  /// If fewer questions match than requested, all matching questions are
  /// used. Throws [QuizGenerationException] when nothing matches.
  List<QuizQuestion> generate(List<McqQuestion> pool, QuizConfig config) {
    final filtered = filter(
      pool,
      category: config.category,
      difficulty: config.difficulty,
    ).where((q) => q.options.length == QuizDefaults.optionsPerQuestion);
    final candidates = filtered.toList();
    if (candidates.isEmpty) {
      throw QuizGenerationException(
        'No questions match these filters. Try a different combination.',
      );
    }
    if (config.questionCount <= 0) {
      throw QuizGenerationException('Choose at least one question.');
    }
    final picked = fisherYatesShuffle(
      candidates,
      _random,
    ).take(config.questionCount);
    return [for (final q in picked) shuffleOptions(q)];
  }

  /// Re-shuffles an existing set of questions (used by "Retry Quiz").
  List<QuizQuestion> reshuffle(List<QuizQuestion> questions) => [
    for (final q in fisherYatesShuffle(questions, _random))
      shuffleOptions(q.source),
  ];
}

abstract final class QuizScorer {
  static int xpFor({required int correct, required int total}) {
    final perfect = total > 0 && correct == total;
    return correct * XpRewards.correctMcq +
        (perfect ? XpRewards.perfectQuizBonus : 0);
  }

  static QuizResult score(QuizSession session, DateTime completedAt) {
    final correct = session.correctCount;
    return QuizResult(
      session: session,
      total: session.total,
      correct: correct,
      xpEarned: xpFor(correct: correct, total: session.total),
      completedAt: completedAt,
    );
  }
}
