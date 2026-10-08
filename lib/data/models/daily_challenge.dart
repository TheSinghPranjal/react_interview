import 'package:flutter/foundation.dart';

import 'interview_question.dart';
import 'lesson.dart';
import 'mcq_question.dart';

enum DailyChallengeType { mcq, interview, lesson }

/// The challenge for one calendar day. Exactly one payload is non-null,
/// matching [type].
@immutable
class DailyChallenge {
  const DailyChallenge._({
    required this.dayKey,
    required this.type,
    this.mcq,
    this.interview,
    this.lesson,
  });

  factory DailyChallenge.mcq(String dayKey, McqQuestion q) =>
      DailyChallenge._(dayKey: dayKey, type: DailyChallengeType.mcq, mcq: q);

  factory DailyChallenge.interview(String dayKey, InterviewQuestion q) =>
      DailyChallenge._(
        dayKey: dayKey,
        type: DailyChallengeType.interview,
        interview: q,
      );

  factory DailyChallenge.lesson(String dayKey, Lesson l) => DailyChallenge._(
    dayKey: dayKey,
    type: DailyChallengeType.lesson,
    lesson: l,
  );

  final String dayKey;
  final DailyChallengeType type;
  final McqQuestion? mcq;
  final InterviewQuestion? interview;
  final Lesson? lesson;

  String get prompt => switch (type) {
    DailyChallengeType.mcq => mcq!.question,
    DailyChallengeType.interview => interview!.question,
    DailyChallengeType.lesson =>
      lesson!.interviewQuestion?.question ??
          'Explain "${lesson!.title}" in your own words.',
  };

  String get typeLabel => switch (type) {
    DailyChallengeType.mcq => 'Quick quiz',
    DailyChallengeType.interview => 'Interview question',
    DailyChallengeType.lesson => 'Concept challenge',
  };

  String get topic => switch (type) {
    DailyChallengeType.mcq => mcq!.topic,
    DailyChallengeType.interview => interview!.topic,
    DailyChallengeType.lesson => lesson!.title,
  };
}
