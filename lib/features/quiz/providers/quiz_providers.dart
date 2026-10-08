import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/quiz_session.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../progress/providers/progress_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../domain/quiz_generator.dart';

final quizGeneratorProvider = Provider<QuizGenerator>(
  (ref) => QuizGenerator(ref.watch(randomProvider)),
);

/// Filters chosen on the quiz home screen.
class QuizConfigNotifier extends Notifier<QuizConfig> {
  @override
  QuizConfig build() =>
      QuizConfig(questionCount: ref.read(settingsProvider).lastQuizConfigCount);

  void setCount(int count) {
    state = state.copyWith(questionCount: count);
    ref.read(settingsProvider.notifier).setLastQuizCount(count);
  }

  void setCategory(Track? category) =>
      state = state.copyWith(category: () => category);

  void setDifficulty(Difficulty? difficulty) =>
      state = state.copyWith(difficulty: () => difficulty);
}

final quizConfigProvider = NotifierProvider<QuizConfigNotifier, QuizConfig>(
  QuizConfigNotifier.new,
);

/// Number of questions matching the current filters.
final availableQuizQuestionsProvider = FutureProvider<int>((ref) async {
  final config = ref.watch(quizConfigProvider);
  final pool = await ref.watch(mcqQuestionsProvider.future);
  return QuizGenerator.filter(
    pool,
    category: config.category,
    difficulty: config.difficulty,
  ).length;
});

/// The active quiz session, or null when no quiz is running.
class QuizSessionNotifier extends Notifier<QuizSession?> {
  @override
  QuizSession? build() => null;

  DateTime get _now => ref.read(clockProvider)();

  /// Starts a new randomized quiz. Throws [QuizGenerationException] if no
  /// questions match the configuration.
  Future<QuizSession> start(QuizConfig config) async {
    final pool = await ref.read(mcqQuestionsProvider.future);
    final questions = ref.read(quizGeneratorProvider).generate(pool, config);
    final session = QuizSession.start(
      id: 'quiz_${_now.microsecondsSinceEpoch}',
      config: config,
      questions: questions,
      startedAt: _now,
    );
    state = session;
    ref.read(quizResultProvider.notifier).clear();
    return session;
  }

  /// Restarts with the same questions in a new random order.
  QuizSession? retry(QuizSession previous) {
    final session = QuizSession.start(
      id: 'quiz_${_now.microsecondsSinceEpoch}',
      config: previous.config,
      questions: ref.read(quizGeneratorProvider).reshuffle(previous.questions),
      startedAt: _now,
    );
    state = session;
    ref.read(quizResultProvider.notifier).clear();
    return session;
  }

  /// Locks in an answer for the current question. Answers cannot be changed
  /// once submitted; repeated calls are ignored and return null.
  ActivityOutcome? submitAnswer(int displayIndex) {
    final s = state;
    if (s == null || s.isCurrentAnswered) return null;
    final q = s.current;
    if (displayIndex < 0 || displayIndex >= q.options.length) return null;
    final answers = [...s.answers]..[s.currentIndex] = displayIndex;
    state = s.copyWith(answers: List.unmodifiable(answers));
    return ref
        .read(progressProvider.notifier)
        .recordQuizAnswer(q.source, correct: displayIndex == q.correctIndex);
  }

  /// Advances to the next question. Returns false if already on the last one
  /// or the current question has not been answered yet.
  bool next() {
    final s = state;
    if (s == null || !s.isCurrentAnswered || s.isLastQuestion) return false;
    state = s.copyWith(currentIndex: s.currentIndex + 1);
    return true;
  }

  /// Scores the session, records stats and returns the result.
  (QuizResult, ActivityOutcome)? finish() {
    final s = state;
    if (s == null || !s.isComplete) return null;
    final result = QuizScorer.score(s, _now);
    final outcome = ref
        .read(progressProvider.notifier)
        .recordQuizCompleted(result);
    ref.read(quizResultProvider.notifier).set(result);
    state = null;
    return (result, outcome);
  }

  void abandon() => state = null;
}

final quizSessionProvider = NotifierProvider<QuizSessionNotifier, QuizSession?>(
  QuizSessionNotifier.new,
);

class QuizResultNotifier extends Notifier<QuizResult?> {
  @override
  QuizResult? build() => null;

  void set(QuizResult result) => state = result;
  void clear() => state = null;
}

/// The most recently finished quiz (shown on the result & review screens).
final quizResultProvider = NotifierProvider<QuizResultNotifier, QuizResult?>(
  QuizResultNotifier.new,
);
