import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'json_utils.dart';

@immutable
class McqQuestion {
  const McqQuestion({
    required this.id,
    required this.category,
    required this.topic,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  final String id;
  final Track category;
  final String topic;
  final Difficulty difficulty;
  final String question;

  /// Exactly four options.
  final List<String> options;

  /// Index into [options].
  final int correctAnswer;
  final String explanation;

  String get correctOption => options[correctAnswer];

  /// Parses and validates a question. Throws [ContentFormatException] if the
  /// question does not have exactly 4 options or a valid answer index.
  factory McqQuestion.fromJson(JsonMap json) {
    final options = json.stringList('options');
    if (options.length != 4) {
      throw ContentFormatException(
        'MCQ ${json['id']} must have exactly 4 options (has ${options.length})',
      );
    }
    final correct = json.reqInt('correctAnswer');
    if (correct < 0 || correct >= options.length) {
      throw ContentFormatException(
        'MCQ ${json['id']} has out-of-range correctAnswer $correct',
      );
    }
    return McqQuestion(
      id: json.reqString('id'),
      category: Track.parse(json.reqString('category')),
      topic: json.optString('topic', 'General'),
      difficulty: Difficulty.parse(json.reqString('difficulty')),
      question: json.reqString('question'),
      options: List.unmodifiable(options),
      correctAnswer: correct,
      explanation: json.optString('explanation'),
    );
  }
}
