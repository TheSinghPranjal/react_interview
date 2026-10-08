import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'mcq_question.dart';

/// User-chosen quiz settings. `null` category/difficulty means "All".
@immutable
class QuizConfig {
  const QuizConfig({this.questionCount = 10, this.category, this.difficulty});

  final int questionCount;
  final Track? category;
  final Difficulty? difficulty;

  QuizConfig copyWith({
    int? questionCount,
    Track? Function()? category,
    Difficulty? Function()? difficulty,
  }) => QuizConfig(
    questionCount: questionCount ?? this.questionCount,
    category: category != null ? category() : this.category,
    difficulty: difficulty != null ? difficulty() : this.difficulty,
  );

  String get label {
    final c = category?.label ?? 'All topics';
    final d = difficulty?.label ?? 'All levels';
    return '$c · $d';
  }

  @override
  bool operator ==(Object other) =>
      other is QuizConfig &&
      other.questionCount == questionCount &&
      other.category == category &&
      other.difficulty == difficulty;

  @override
  int get hashCode => Object.hash(questionCount, category, difficulty);
}

/// A question as presented in a session: options are shuffled and
/// [correctIndex] points at the correct option *after* shuffling.
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.source,
    required this.options,
    required this.correctIndex,
    required this.optionOrder,
  });

  final McqQuestion source;

  /// Options in display order.
  final List<String> options;

  /// Index of the correct option within [options].
  final int correctIndex;

  /// `optionOrder[displayIndex] == originalIndex`.
  final List<int> optionOrder;

  String get id => source.id;
  String get correctOption => options[correctIndex];
}

@immutable
class QuizSession {
  const QuizSession({
    required this.id,
    required this.config,
    required this.questions,
    required this.answers,
    required this.currentIndex,
    required this.startedAt,
  });

  factory QuizSession.start({
    required String id,
    required QuizConfig config,
    required List<QuizQuestion> questions,
    required DateTime startedAt,
  }) => QuizSession(
    id: id,
    config: config,
    questions: List.unmodifiable(questions),
    answers: List<int?>.filled(questions.length, null),
    currentIndex: 0,
    startedAt: startedAt,
  );

  final String id;
  final QuizConfig config;
  final List<QuizQuestion> questions;

  /// Selected display index per question, or null if unanswered.
  final List<int?> answers;
  final int currentIndex;
  final DateTime startedAt;

  int get total => questions.length;
  QuizQuestion get current => questions[currentIndex];
  int? get currentAnswer => answers[currentIndex];
  bool get isCurrentAnswered => currentAnswer != null;
  bool get isLastQuestion => currentIndex == total - 1;
  bool get isComplete => answers.every((a) => a != null);
  int get answeredCount => answers.where((a) => a != null).length;

  int get correctCount {
    var c = 0;
    for (var i = 0; i < total; i++) {
      if (answers[i] == questions[i].correctIndex) c++;
    }
    return c;
  }

  bool isCorrectAt(int index) =>
      answers[index] == questions[index].correctIndex;

  QuizSession copyWith({List<int?>? answers, int? currentIndex}) => QuizSession(
    id: id,
    config: config,
    questions: questions,
    answers: answers ?? this.answers,
    currentIndex: currentIndex ?? this.currentIndex,
    startedAt: startedAt,
  );
}

/// Final outcome of a finished quiz session.
@immutable
class QuizResult {
  const QuizResult({
    required this.session,
    required this.total,
    required this.correct,
    required this.xpEarned,
    required this.completedAt,
  });

  final QuizSession session;
  final int total;
  final int correct;
  final int xpEarned;
  final DateTime completedAt;

  int get incorrect => total - correct;
  double get accuracy => total == 0 ? 0 : correct / total;
  int get percent => (accuracy * 100).round();
  bool get isPerfect => total > 0 && correct == total;

  String get headline {
    if (isPerfect) return 'Perfect score!';
    if (percent >= 80) return 'Great job!';
    if (percent >= 50) return 'Good effort!';
    return 'Keep practicing!';
  }
}
