import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'json_utils.dart';

@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.track,
    required this.category,
    required this.order,
    required this.title,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.description,
    required this.keyConcepts,
    required this.sections,
    required this.codeExamples,
    required this.whenNotToUse,
    required this.commonMistakes,
    required this.realWorldExample,
    required this.interviewTip,
    required this.quiz,
    required this.flashcards,
    this.beforeAfter,
    this.interviewQuestion,
  });

  final String id;
  final Track track;
  final String category;
  final int order;
  final String title;
  final Difficulty difficulty;
  final int estimatedMinutes;
  final String description;
  final List<String> keyConcepts;
  final List<LessonSection> sections;
  final List<CodeExample> codeExamples;
  final BeforeAfter? beforeAfter;
  final List<String> whenNotToUse;
  final List<String> commonMistakes;
  final String realWorldExample;
  final String interviewTip;
  final RevealQuestion? interviewQuestion;
  final List<LessonQuizItem> quiz;
  final List<Flashcard> flashcards;

  factory Lesson.fromJson(JsonMap json, {Track? fallbackTrack}) {
    final trackRaw = json.nullableString('track');
    return Lesson(
      id: json.reqString('id'),
      track: trackRaw != null
          ? Track.parse(trackRaw)
          : fallbackTrack ?? Track.react,
      category: json.reqString('category'),
      order: json.optInt('order'),
      title: json.reqString('title'),
      difficulty: Difficulty.parse(json.optString('difficulty', 'Easy')),
      estimatedMinutes: json.optInt('estimatedMinutes', 5),
      description: json.optString('description'),
      keyConcepts: json.stringList('keyConcepts'),
      sections: json.mapList('sections').map(LessonSection.fromJson).toList(),
      codeExamples: json
          .mapList('codeExamples')
          .map(CodeExample.fromJson)
          .toList(),
      beforeAfter: switch (json.obj('beforeAfter')) {
        final m? => BeforeAfter.fromJson(m),
        null => null,
      },
      whenNotToUse: json.stringList('whenNotToUse'),
      commonMistakes: json.stringList('commonMistakes'),
      realWorldExample: json.optString('realWorldExample'),
      interviewTip: json.optString('interviewTip'),
      interviewQuestion: switch (json.obj('interviewQuestion')) {
        final m? => RevealQuestion.fromJson(m),
        null => null,
      },
      quiz: [for (final q in json.mapList('quiz')) ?LessonQuizItem.tryParse(q)],
      flashcards: json.mapList('flashcards').map(Flashcard.fromJson).toList(),
    );
  }

  /// All searchable text for this lesson, lower-cased.
  String get searchBody => [
    description,
    ...keyConcepts,
    for (final s in sections) s.content,
  ].join(' ');
}

@immutable
class LessonSection {
  const LessonSection({required this.title, required this.content});
  final String title;
  final String content;

  factory LessonSection.fromJson(JsonMap json) => LessonSection(
    title: json.optString('title'),
    content: json.optString('content'),
  );
}

@immutable
class CodeExample {
  const CodeExample({
    required this.language,
    required this.code,
    required this.explanation,
    this.title,
  });

  final String? title;
  final String language;
  final String code;
  final String explanation;

  factory CodeExample.fromJson(JsonMap json) => CodeExample(
    title: json.nullableString('title'),
    language: json.optString('language', 'jsx'),
    code: json.reqString('code'),
    explanation: json.optString('explanation'),
  );
}

@immutable
class BeforeAfter {
  const BeforeAfter({
    required this.title,
    required this.before,
    required this.after,
    required this.language,
    required this.explanation,
  });

  final String title;
  final String before;
  final String after;
  final String language;
  final String explanation;

  factory BeforeAfter.fromJson(JsonMap json) => BeforeAfter(
    title: json.optString('title', 'Before & after'),
    before: json.reqString('before'),
    after: json.reqString('after'),
    language: json.optString('language', 'jsx'),
    explanation: json.optString('explanation'),
  );
}

@immutable
class RevealQuestion {
  const RevealQuestion({required this.question, required this.answer});
  final String question;
  final String answer;

  factory RevealQuestion.fromJson(JsonMap json) => RevealQuestion(
    question: json.reqString('question'),
    answer: json.reqString('answer'),
  );
}

@immutable
class Flashcard {
  const Flashcard({required this.front, required this.back});
  final String front;
  final String back;

  factory Flashcard.fromJson(JsonMap json) =>
      Flashcard(front: json.reqString('front'), back: json.reqString('back'));
}

enum LessonQuizType { mcq, trueFalse, predictOutput, ordering }

/// An interactive check inside a lesson.
///
/// * [LessonQuizType.mcq], [LessonQuizType.trueFalse] and
///   [LessonQuizType.predictOutput] use [options] + [correctAnswer].
/// * [LessonQuizType.ordering] uses [items] listed in the correct order.
@immutable
class LessonQuizItem {
  const LessonQuizItem({
    required this.type,
    required this.prompt,
    required this.explanation,
    this.code,
    this.options = const [],
    this.correctAnswer = 0,
    this.items = const [],
  });

  final LessonQuizType type;
  final String prompt;
  final String? code;
  final List<String> options;
  final int correctAnswer;
  final List<String> items;
  final String explanation;

  static LessonQuizItem? tryParse(JsonMap json) {
    final type = switch (json.optString('type')) {
      'mcq' => LessonQuizType.mcq,
      'trueFalse' => LessonQuizType.trueFalse,
      'predictOutput' => LessonQuizType.predictOutput,
      'ordering' => LessonQuizType.ordering,
      _ => null,
    };
    if (type == null) return null;
    final prompt = json.optString('prompt');
    if (prompt.isEmpty) return null;
    final options = type == LessonQuizType.trueFalse
        ? const ['True', 'False']
        : json.stringList('options');
    final correct = json.optInt('correctAnswer', -1);
    final items = json.stringList('items');
    if (type == LessonQuizType.ordering) {
      if (items.length < 2) return null;
    } else if (correct < 0 || correct >= options.length) {
      return null;
    }
    return LessonQuizItem(
      type: type,
      prompt: prompt,
      code: json.nullableString('code'),
      options: options,
      correctAnswer: correct,
      items: items,
      explanation: json.optString('explanation'),
    );
  }
}
