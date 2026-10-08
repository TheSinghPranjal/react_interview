import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'json_utils.dart';

@immutable
class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.topic,
    required this.question,
    required this.shortAnswer,
    required this.detailedAnswer,
    required this.keyPoints,
    required this.commonMistake,
    required this.interviewTip,
    this.code,
  });

  final String id;
  final Track category;
  final Difficulty difficulty;
  final String topic;
  final String question;
  final String shortAnswer;
  final String detailedAnswer;
  final List<String> keyPoints;
  final String commonMistake;
  final String interviewTip;

  /// Optional code sample supporting the answer.
  final String? code;

  factory InterviewQuestion.fromJson(JsonMap json) => InterviewQuestion(
    id: json.reqString('id'),
    category: Track.parse(json.reqString('category')),
    difficulty: Difficulty.parse(json.reqString('difficulty')),
    topic: json.optString('topic', 'General'),
    question: json.reqString('question'),
    shortAnswer: json.reqString('shortAnswer'),
    detailedAnswer: json.reqString('detailedAnswer'),
    keyPoints: json.stringList('keyPoints'),
    commonMistake: json.optString('commonMistake'),
    interviewTip: json.optString('interviewTip'),
    code: json.nullableString('code'),
  );
}
