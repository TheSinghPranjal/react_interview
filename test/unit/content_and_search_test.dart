import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:react_interview/core/constants/app_constants.dart';
import 'package:react_interview/data/datasources/local_content_datasource.dart';
import 'package:react_interview/data/models/enums.dart';
import 'package:react_interview/data/models/interview_question.dart';
import 'package:react_interview/data/models/lesson.dart';
import 'package:react_interview/data/models/mcq_question.dart';
import 'package:react_interview/data/repositories/content_repositories.dart';
import 'package:react_interview/features/daily_challenge/daily_challenge_providers.dart';
import 'package:react_interview/features/interview/domain/interview_filter.dart';
import 'package:react_interview/features/search/domain/search_engine.dart';
import 'package:react_interview/shared/widgets/highlighted_text.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Repository parsing', () {
    test('parses lessons sorted by order with quiz items', () async {
      final repo = LessonRepository(
        LocalContentDataSource(FakeAssetBundle(fixtureAssets())),
      );
      final lessons = await repo.lessons(Track.react);
      expect(lessons.map((l) => l.id), [
        'react_use_memo',
        'react_use_callback',
      ]);
      final l = lessons.first;
      expect(l.track, Track.react);
      expect(l.difficulty, Difficulty.medium);
      expect(l.quiz, hasLength(2));
      expect(l.quiz[1].type, LessonQuizType.trueFalse);
      expect(l.quiz[1].options, ['True', 'False']);
      expect(l.interviewQuestion, isNotNull);
      final cats = LessonRepository.groupByCategory(Track.react, lessons);
      expect(cats.single.name, 'Advanced Hooks');
      expect(await repo.byId('next_app_router'), isNotNull);
    });

    test('skips invalid MCQs instead of failing', () async {
      final bad = Map.of(mcqJson('bad'))
        ..['options'] = ['only', 'three', 'options'];
      final outOfRange = Map.of(mcqJson('oor'))..['correctAnswer'] = 9;
      final assets = {
        AppConstants.mcqQuestionsAsset: jsonEncode([
          mcqJson('good'),
          bad,
          outOfRange,
        ]),
      };
      final repo = QuizRepository(
        LocalContentDataSource(FakeAssetBundle(assets)),
      );
      final all = await repo.all();
      expect(all.map((q) => q.id), ['good']);
    });

    test('invalid JSON raises ContentLoadException', () async {
      final repo = InterviewRepository(
        LocalContentDataSource(
          FakeAssetBundle({AppConstants.interviewQuestionsAsset: '{not json'}),
        ),
      );
      expect(repo.all(), throwsA(isA<ContentLoadException>()));
    });

    test('missing asset raises ContentLoadException and can retry', () async {
      final assets = <String, String>{};
      final repo = QuizRepository(
        LocalContentDataSource(FakeAssetBundle(assets)),
      );
      await expectLater(repo.all(), throwsA(isA<ContentLoadException>()));
      assets[AppConstants.mcqQuestionsAsset] = jsonEncode([mcqJson('x')]);
      expect((await repo.all()).single.id, 'x');
    });

    test('McqQuestion requires exactly four options', () {
      expect(
        () => McqQuestion.fromJson(
          Map.of(mcqJson('a'))..['options'] = ['a', 'b'],
        ),
        throwsA(anything),
      );
    });
  });

  group('Interview filtering', () {
    final questions = [
      InterviewQuestion.fromJson(interviewJson('r1')),
      InterviewQuestion.fromJson(interviewJson('n1', category: 'Next.js')),
      InterviewQuestion.fromJson(interviewJson('r2', difficulty: 'Hard')),
      InterviewQuestion.fromJson(
        interviewJson('n2', category: 'Next.js', difficulty: 'Medium'),
      ),
    ];

    test('empty filter returns everything', () {
      expect(const InterviewFilter().apply(questions), hasLength(4));
    });

    test('filters by category', () {
      final f = const InterviewFilter().toggleCategory(Track.next);
      expect(f.apply(questions).map((q) => q.id), ['n1', 'n2']);
    });

    test('filters by difficulty and combines with category', () {
      final f = const InterviewFilter()
          .toggleDifficulty(Difficulty.easy)
          .toggleCategory(Track.react);
      expect(f.apply(questions).map((q) => q.id), ['r1']);
    });

    test('toggling twice removes the filter', () {
      final f = const InterviewFilter()
          .toggleDifficulty(Difficulty.hard)
          .toggleDifficulty(Difficulty.hard);
      expect(f.isEmpty, isTrue);
      expect(f, const InterviewFilter());
    });
  });

  group('Search', () {
    final lessons = [
      Lesson.fromJson(lessonJson('l1', title: 'useMemo')),
      Lesson.fromJson(
        lessonJson('l2', title: 'Server Components', track: 'next'),
      ),
    ];
    final interview = [
      InterviewQuestion.fromJson(
        interviewJson('i1', question: 'When should you avoid useMemo?'),
      ),
    ];
    final mcqs = [
      McqQuestion.fromJson(mcqJson('m1', question: 'What does useMemo cache?')),
    ];
    final index = SearchIndex.build(
      lessons: lessons,
      interview: interview,
      mcqs: mcqs,
    );

    test('finds matches across content types, lesson title first', () {
      final results = index.search('usememo');
      expect(results.map((r) => r.type).toSet(), {
        SearchResultType.lesson,
        SearchResultType.interview,
        SearchResultType.mcq,
      });
      expect(results.first.id, 'l1');
    });

    test('requires all terms to match', () {
      expect(index.search('server components').map((r) => r.id), ['l2']);
      expect(index.search('server usememo'), isEmpty);
    });

    test('empty query returns nothing and type filter works', () {
      expect(index.search('   '), isEmpty);
      expect(
        index.search('usememo', type: SearchResultType.mcq).single.id,
        'm1',
      );
    });

    test('highlight ranges merge overlaps and ignore case', () {
      expect(HighlightedText.matchRanges('useMemo and USEmemo', 'usememo'), [
        (0, 7),
        (12, 19),
      ]);
      expect(HighlightedText.matchRanges('abc', ''), isEmpty);
    });
  });

  group('Daily challenge', () {
    final mcqs = [for (var i = 0; i < 20; i++) mcq('m$i')];
    final interview = [
      for (var i = 0; i < 20; i++)
        InterviewQuestion.fromJson(interviewJson('i$i', question: 'Q$i')),
    ];
    final lessons = [Lesson.fromJson(lessonJson('l1'))];

    test('is deterministic for the same date', () {
      final a = DailyChallengeSelector.select(
        date: DateTime(2026, 10, 8, 8),
        mcqs: mcqs,
        interview: interview,
        lessons: lessons,
      );
      final b = DailyChallengeSelector.select(
        date: DateTime(2026, 10, 8, 23),
        mcqs: mcqs,
        interview: interview,
        lessons: lessons,
      );
      expect(a!.type, b!.type);
      expect(a.prompt, b.prompt);
    });

    test('changes between days and rotates types', () {
      final types = {
        for (var d = 0; d < 3; d++)
          DailyChallengeSelector.select(
            date: DateTime(2026, 10, 8 + d),
            mcqs: mcqs,
            interview: interview,
            lessons: lessons,
          )!.type,
      };
      expect(types, hasLength(3));
    });

    test('falls back when a pool is empty', () {
      final c = DailyChallengeSelector.select(
        date: DateTime(2026, 10, 8),
        mcqs: const [],
        interview: const [],
        lessons: lessons,
      );
      expect(c, isNotNull);
    });
  });
}
