import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:react_interview/core/constants/app_constants.dart';
import 'package:react_interview/core/providers/core_providers.dart';
import 'package:react_interview/core/services/ad_providers.dart';
import 'package:react_interview/core/services/ad_service.dart';
import 'package:react_interview/core/services/storage_service.dart';
import 'package:react_interview/data/models/enums.dart';
import 'package:react_interview/data/models/mcq_question.dart';

/// Asset bundle that serves in-memory strings (no isolates, no disk).
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Asset not found: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Asset not found: $key');
    return value;
  }
}

/// A mutable clock for date-dependent tests.
class TestClock {
  TestClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advanceDays(int days) => now = now.add(Duration(days: days));
}

Map<String, Object?> lessonJson(
  String id, {
  String track = 'react',
  String category = 'Hooks',
  int order = 1,
  String title = 'Lesson',
}) => {
  'id': id,
  'track': track,
  'category': category,
  'order': order,
  'title': title,
  'difficulty': 'Medium',
  'estimatedMinutes': 5,
  'description': 'Description of $title',
  'keyConcepts': ['Concept A', 'Concept B'],
  'sections': [
    {'title': 'What is it?', 'content': 'Explanation for $title with `code`.'},
    {'title': 'Why does it exist?', 'content': 'Because reasons.'},
  ],
  'codeExamples': [
    {
      'title': 'Example',
      'language': 'jsx',
      'code': 'const x = useMemo(() => 1, []);',
      'explanation': 'Explains it.',
    },
  ],
  'whenNotToUse': ['When it is cheap.'],
  'commonMistakes': ['A common mistake.'],
  'realWorldExample': 'Used in dashboards.',
  'interviewTip': 'Mention trade-offs.',
  'interviewQuestion': {'question': 'Explain $title', 'answer': 'Answer.'},
  'quiz': [
    {
      'type': 'mcq',
      'prompt': 'Pick one',
      'options': ['A', 'B', 'C', 'D'],
      'correctAnswer': 1,
      'explanation': 'B is right.',
    },
    {
      'type': 'trueFalse',
      'prompt': 'Is it true?',
      'correctAnswer': 0,
      'explanation': 'Yes.',
    },
  ],
  'flashcards': [
    {'front': 'Front', 'back': 'Back'},
  ],
};

Map<String, Object?> interviewJson(
  String id, {
  String category = 'React',
  String difficulty = 'Easy',
  String question = 'What is React?',
}) => {
  'id': id,
  'category': category,
  'difficulty': difficulty,
  'topic': 'Basics',
  'question': question,
  'shortAnswer': 'Short answer for $question',
  'detailedAnswer': 'Detailed answer.',
  'keyPoints': ['Point one', 'Point two'],
  'commonMistake': 'A mistake.',
  'interviewTip': 'A tip.',
};

Map<String, Object?> mcqJson(
  String id, {
  String category = 'React',
  String difficulty = 'Easy',
  String? question,
  int correct = 1,
}) => {
  'id': id,
  'category': category,
  'topic': 'Hooks',
  'difficulty': difficulty,
  'question': question ?? 'Question $id?',
  'options': ['Option A $id', 'Option B $id', 'Option C $id', 'Option D $id'],
  'correctAnswer': correct,
  'explanation': 'Because $id.',
};

McqQuestion mcq(
  String id, {
  Track category = Track.react,
  Difficulty difficulty = Difficulty.easy,
  int correct = 1,
}) => McqQuestion.fromJson(
  mcqJson(
    id,
    category: category.label,
    difficulty: difficulty.label,
    correct: correct,
  ),
);

/// Default fixture content: 2 React + 1 Next lesson, 6 interview questions,
/// 12 MCQs.
Map<String, String> fixtureAssets() {
  final mcqs = [
    for (var i = 0; i < 12; i++)
      mcqJson(
        'mcq_${i.toString().padLeft(3, '0')}',
        category: i.isEven ? 'React' : 'Next.js',
        difficulty: ['Easy', 'Medium', 'Hard'][i % 3],
        correct: i % 4,
      ),
  ];
  return {
    AppConstants.reactLessonsAsset: jsonEncode([
      lessonJson(
        'react_use_memo',
        title: 'useMemo',
        category: 'Advanced Hooks',
        order: 1,
      ),
      lessonJson(
        'react_use_callback',
        title: 'useCallback',
        category: 'Advanced Hooks',
        order: 2,
      ),
    ]),
    AppConstants.nextLessonsAsset: jsonEncode([
      lessonJson(
        'next_app_router',
        track: 'next',
        title: 'App Router',
        category: 'App Router',
      ),
    ]),
    AppConstants.interviewQuestionsAsset: jsonEncode([
      interviewJson('react_easy_001', question: 'What is JSX?'),
      interviewJson('react_easy_002', question: 'What are keys?'),
      interviewJson(
        'next_easy_001',
        category: 'Next.js',
        question: 'What is Next.js?',
      ),
      interviewJson(
        'react_medium_001',
        difficulty: 'Medium',
        question: 'What is reconciliation?',
      ),
      interviewJson(
        'next_hard_001',
        category: 'Next.js',
        difficulty: 'Hard',
        question: 'Design a caching strategy',
      ),
      interviewJson(
        'react_hard_001',
        difficulty: 'Hard',
        question: 'Explain concurrent rendering',
      ),
    ]),
    AppConstants.mcqQuestionsAsset: jsonEncode(mcqs),
  };
}

/// Standard overrides for tests: fake content, in-memory storage, fixed
/// clock, seeded randomness and no ads.
List<Override> testOverrides({
  Map<String, String>? assets,
  KeyValueStore? store,
  DateTime Function()? clock,
  Random? random,
}) => [
  assetBundleProvider.overrideWithValue(
    FakeAssetBundle(assets ?? fixtureAssets()),
  ),
  keyValueStoreProvider.overrideWithValue(store ?? InMemoryKeyValueStore()),
  clockProvider.overrideWithValue(clock ?? () => DateTime(2026, 10, 7, 9)),
  randomProvider.overrideWithValue(random ?? Random(42)),
  adServiceProvider.overrideWithValue(const NoopAdService()),
];

ProviderContainer createContainer({
  Map<String, String>? assets,
  KeyValueStore? store,
  DateTime Function()? clock,
  Random? random,
}) {
  final container = ProviderContainer(
    overrides: testOverrides(
      assets: assets,
      store: store,
      clock: clock,
      random: random,
    ),
    retry: (_, _) => null,
  );
  return container;
}
