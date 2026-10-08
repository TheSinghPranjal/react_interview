import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:react_interview/core/utils/shuffle.dart';
import 'package:react_interview/data/models/enums.dart';
import 'package:react_interview/data/models/quiz_session.dart';
import 'package:react_interview/features/quiz/domain/quiz_generator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('fisherYatesShuffle', () {
    test('returns a permutation and never mutates the input', () {
      final input = List.generate(50, (i) => i);
      final copy = [...input];
      final out = fisherYatesShuffle(input, Random(1));
      expect(input, copy, reason: 'input must be untouched');
      expect(out.length, input.length);
      expect(out.toSet(), input.toSet());
      expect(
        out,
        isNot(equals(input)),
        reason: 'seeded shuffle should move items',
      );
    });

    test('handles empty and single-element lists', () {
      expect(fisherYatesShuffle(<int>[], Random(1)), isEmpty);
      expect(fisherYatesShuffle([7], Random(1)), [7]);
    });

    test('is roughly uniform over many runs', () {
      // Count how often each value lands in position 0 for a 4-element list.
      final counts = List.filled(4, 0);
      final random = Random(123);
      const runs = 40000;
      for (var i = 0; i < runs; i++) {
        counts[fisherYatesShuffle([0, 1, 2, 3], random).first]++;
      }
      for (final c in counts) {
        expect(c / runs, closeTo(0.25, 0.02));
      }
    });
  });

  group('QuizGenerator', () {
    final pool = [
      for (var i = 0; i < 30; i++)
        mcq(
          'q$i',
          category: i.isEven ? Track.react : Track.next,
          difficulty: Difficulty.values[i % 3],
          correct: i % 4,
        ),
    ];

    test('takes N questions with no duplicate ids', () {
      final gen = QuizGenerator(Random(7));
      final qs = gen.generate(pool, const QuizConfig(questionCount: 10));
      expect(qs, hasLength(10));
      expect(qs.map((q) => q.id).toSet(), hasLength(10));
    });

    test('preserves the correct answer after shuffling options', () {
      for (var seed = 0; seed < 200; seed++) {
        final gen = QuizGenerator(Random(seed));
        for (final q in gen.generate(
          pool,
          const QuizConfig(questionCount: 30),
        )) {
          expect(q.options, hasLength(4));
          expect(q.options.toSet(), q.source.options.toSet());
          expect(q.correctOption, q.source.correctOption);
          expect(
            q.options[q.correctIndex],
            q.source.options[q.source.correctAnswer],
          );
          expect(q.optionOrder[q.correctIndex], q.source.correctAnswer);
        }
      }
    });

    test('randomizes question order between quizzes', () {
      final gen = QuizGenerator(Random(99));
      final a = gen.generate(pool, const QuizConfig(questionCount: 30));
      final b = gen.generate(pool, const QuizConfig(questionCount: 30));
      expect(a.map((q) => q.id).toList(), isNot(b.map((q) => q.id).toList()));
    });

    test('randomizes option order', () {
      final gen = QuizGenerator(Random(5));
      final shuffledAtLeastOnce = gen
          .generate(pool, const QuizConfig(questionCount: 30))
          .any((q) => q.options.join() != q.source.options.join());
      expect(shuffledAtLeastOnce, isTrue);
    });

    test('filters by category and difficulty', () {
      final gen = QuizGenerator(Random(3));
      final qs = gen.generate(
        pool,
        const QuizConfig(
          questionCount: 50,
          category: Track.next,
          difficulty: Difficulty.hard,
        ),
      );
      expect(qs, isNotEmpty);
      expect(qs.every((q) => q.source.category == Track.next), isTrue);
      expect(qs.every((q) => q.source.difficulty == Difficulty.hard), isTrue);
    });

    test('uses all matching questions when fewer than requested', () {
      final gen = QuizGenerator(Random(3));
      final qs = gen.generate(
        pool,
        const QuizConfig(questionCount: 50, difficulty: Difficulty.easy),
      );
      expect(qs, hasLength(10));
    });

    test('ignores duplicate ids in the pool', () {
      final gen = QuizGenerator(Random(3));
      final dupPool = [...pool, ...pool];
      final qs = gen.generate(dupPool, const QuizConfig(questionCount: 50));
      expect(qs.map((q) => q.id).toSet().length, qs.length);
      expect(qs, hasLength(30));
    });

    test('throws QuizGenerationException when nothing matches', () {
      final gen = QuizGenerator(Random(3));
      expect(
        () => gen.generate(const [], const QuizConfig()),
        throwsA(isA<QuizGenerationException>()),
      );
    });

    test('reshuffle keeps the same questions with valid answers', () {
      final gen = QuizGenerator(Random(11));
      final first = gen.generate(pool, const QuizConfig(questionCount: 8));
      final again = gen.reshuffle(first);
      expect(again.map((q) => q.id).toSet(), first.map((q) => q.id).toSet());
      for (final q in again) {
        expect(q.correctOption, q.source.correctOption);
      }
    });
  });

  group('QuizScorer', () {
    QuizSession sessionWith(List<int?> picks) {
      final gen = QuizGenerator(Random(1));
      final qs = gen.generate([
        for (var i = 0; i < picks.length; i++) mcq('s$i'),
      ], QuizConfig(questionCount: picks.length));
      final session = QuizSession.start(
        id: 's',
        config: QuizConfig(questionCount: picks.length),
        questions: qs,
        startedAt: DateTime(2026),
      );
      // picks: 1 = answer correctly, 0 = answer incorrectly.
      return session.copyWith(
        answers: [
          for (var i = 0; i < qs.length; i++)
            picks[i] == 1 ? qs[i].correctIndex : (qs[i].correctIndex + 1) % 4,
        ],
      );
    }

    test('scores correct and incorrect answers', () {
      final result = QuizScorer.score(
        sessionWith([1, 1, 0, 1, 0]),
        DateTime(2026),
      );
      expect(result.correct, 3);
      expect(result.incorrect, 2);
      expect(result.percent, 60);
      expect(result.isPerfect, isFalse);
      expect(result.xpEarned, 30);
    });

    test('adds the perfect bonus', () {
      final result = QuizScorer.score(
        sessionWith([1, 1, 1, 1]),
        DateTime(2026),
      );
      expect(result.isPerfect, isTrue);
      expect(result.xpEarned, 4 * 10 + 50);
      expect(result.headline, 'Perfect score!');
    });

    test('xpFor handles zero questions', () {
      expect(QuizScorer.xpFor(correct: 0, total: 0), 0);
    });
  });
}
