import 'package:flutter_test/flutter_test.dart';
import 'package:react_interview/core/services/storage_service.dart';
import 'package:react_interview/data/models/bookmark.dart';
import 'package:react_interview/data/models/enums.dart';
import 'package:react_interview/data/models/quiz_session.dart';
import 'package:react_interview/data/repositories/repository_providers.dart';
import 'package:react_interview/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:react_interview/features/interview/providers/interview_providers.dart';
import 'package:react_interview/features/learn/providers/learn_providers.dart';
import 'package:react_interview/features/progress/providers/progress_provider.dart';
import 'package:react_interview/features/quiz/domain/quiz_generator.dart';
import 'package:react_interview/features/quiz/providers/quiz_providers.dart';
import 'package:react_interview/features/settings/providers/settings_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ProgressNotifier', () {
    test(
      'lesson completion awards XP once, starts a streak, unlocks achievement',
      () {
        final c = createContainer();
        addTearDown(c.dispose);
        final n = c.read(progressProvider.notifier);

        final first = n.completeLesson('react_use_memo');
        expect(first.xpGained, 20);
        expect(first.streakExtendedTo, 1);
        expect(
          first.newAchievements.map((a) => a.id),
          contains('first_lesson'),
        );

        final again = n.completeLesson('react_use_memo');
        expect(again.hasNews, isFalse);

        final p = c.read(progressProvider);
        expect(p.totalXp, 20);
        expect(p.lessonsCompleted, 1);
        expect(c.read(xpTodayProvider), 20);
        expect(c.read(streakProvider).current, 1);
      },
    );

    test('streak extends across days using the injected clock', () {
      final clock = TestClock(DateTime(2026, 10, 5, 9));
      final c = createContainer(clock: clock.call);
      addTearDown(c.dispose);
      final n = c.read(progressProvider.notifier);
      n.completeLesson('a');
      clock.advanceDays(1);
      expect(n.completeLesson('b').streakExtendedTo, 2);
      clock.advanceDays(1);
      n.markInterviewQuestion('q1', known: true);
      expect(c.read(progressProvider).streak.currentStreak, 3);
      clock.advanceDays(3);
      c.invalidate(streakProvider);
      expect(c.read(streakProvider).current, 0, reason: 'streak broken');
    });

    test('interview XP only on first review; known/practice are exclusive', () {
      final c = createContainer();
      addTearDown(c.dispose);
      final n = c.read(progressProvider.notifier);
      expect(n.markInterviewQuestion('q1', known: false).xpGained, 10);
      expect(n.markInterviewQuestion('q1', known: true).xpGained, 0);
      final p = c.read(progressProvider);
      expect(p.interviewKnown, {'q1'});
      expect(p.interviewPractice, isEmpty);
      expect(p.interviewCompleted, 1);
    });

    test('daily challenge rewards once per day', () {
      final clock = TestClock(DateTime(2026, 10, 5, 9));
      final c = createContainer(clock: clock.call);
      addTearDown(c.dispose);
      final n = c.read(progressProvider.notifier);
      expect(n.completeDailyChallenge().xpGained, 30);
      expect(n.completeDailyChallenge().xpGained, 0);
      clock.advanceDays(1);
      expect(n.completeDailyChallenge().xpGained, 30);
    });

    test('rewarded XP is capped per day and is not a streak activity', () {
      final c = createContainer();
      addTearDown(c.dispose);
      final n = c.read(progressProvider.notifier);
      for (var i = 0; i < 3; i++) {
        expect(n.claimRewardedXp().xpGained, 20);
      }
      expect(n.claimRewardedXp().xpGained, 0);
      expect(c.read(progressProvider).streak.currentStreak, 0);
    });

    test('progress persists and reloads from storage', () async {
      final store = InMemoryKeyValueStore();
      final c1 = createContainer(store: store);
      c1.read(progressProvider.notifier).completeLesson('react_use_memo');
      c1.read(progressProvider.notifier).openLesson('react_use_callback');
      await Future<void>.delayed(Duration.zero);
      c1.dispose();

      final c2 = createContainer(store: store);
      addTearDown(c2.dispose);
      final p = c2.read(progressProvider);
      expect(p.completedLessons, ['react_use_memo']);
      expect(p.lastOpenedLessonId, 'react_use_callback');
      expect(p.totalXp, 20);
      expect(p.achievements.keys, contains('first_lesson'));
    });

    test('corrupt stored progress falls back to defaults', () {
      final store = InMemoryKeyValueStore({'user_progress': '{broken'});
      final c = createContainer(store: store);
      addTearDown(c.dispose);
      expect(c.read(progressProvider).totalXp, 0);
    });

    test('level up is reported', () {
      final c = createContainer();
      addTearDown(c.dispose);
      final n = c.read(progressProvider.notifier);
      int? level;
      for (var i = 0; i < 5; i++) {
        level ??= n.completeLesson('l$i').newLevel;
      }
      expect(level, 2);
      expect(c.read(levelProvider).level, 2);
    });
  });

  group('Bookmarks', () {
    test('toggle and persist across containers', () async {
      final store = InMemoryKeyValueStore();
      final c1 = createContainer(store: store);
      final n = c1.read(bookmarksProvider.notifier);
      expect(n.toggle(BookmarkType.lesson, 'react_use_memo'), isTrue);
      expect(n.toggle(BookmarkType.mcq, 'mcq_001'), isTrue);
      expect(n.toggle(BookmarkType.mcq, 'mcq_001'), isFalse);
      expect(
        c1.read(
          isBookmarkedProvider((
            type: BookmarkType.lesson,
            id: 'react_use_memo',
          )),
        ),
        isTrue,
      );
      await Future<void>.delayed(Duration.zero);
      c1.dispose();

      final c2 = createContainer(store: store);
      addTearDown(c2.dispose);
      final list = c2.read(bookmarksProvider);
      expect(list, hasLength(1));
      expect(list.single.itemId, 'react_use_memo');
      expect(c2.read(bookmarksByTypeProvider(BookmarkType.mcq)), isEmpty);
    });
  });

  group('Quiz session', () {
    test('start, answer, lock answer, finish and record stats', () async {
      final c = createContainer();
      addTearDown(c.dispose);
      final notifier = c.read(quizSessionProvider.notifier);
      final session = await notifier.start(const QuizConfig(questionCount: 5));
      expect(session.total, 5);
      expect(session.questions.map((q) => q.id).toSet(), hasLength(5));

      for (var i = 0; i < 5; i++) {
        final s = c.read(quizSessionProvider)!;
        final pick = i < 4
            ? s.current.correctIndex
            : (s.current.correctIndex + 1) % 4;
        expect(notifier.submitAnswer(pick), isNotNull);
        // Second submission is ignored: answers can't be changed.
        expect(notifier.submitAnswer((pick + 1) % 4), isNull);
        expect(c.read(quizSessionProvider)!.currentAnswer, pick);
        if (i < 4) expect(notifier.next(), isTrue);
      }
      expect(notifier.next(), isFalse);

      final (result, _) = notifier.finish()!;
      expect(result.correct, 4);
      expect(result.percent, 80);
      expect(c.read(quizSessionProvider), isNull);
      expect(c.read(quizResultProvider), same(result));

      final stats = c.read(quizStatsProvider);
      expect(stats.totalQuizzes, 1);
      expect(stats.questionsAnswered, 5);
      expect(stats.correctAnswers, 4);
      expect(stats.bestScorePercent, 80);
      expect(stats.history.single.correct, 4);
      expect(
        stats.category('react').answered + stats.category('next').answered,
        5,
      );
      expect(c.read(progressProvider).totalXp, 40);
    });

    test('cannot advance before answering', () async {
      final c = createContainer();
      addTearDown(c.dispose);
      final notifier = c.read(quizSessionProvider.notifier);
      await notifier.start(const QuizConfig(questionCount: 3));
      expect(notifier.next(), isFalse);
      expect(notifier.finish(), isNull);
    });

    test('perfect quiz adds bonus XP', () async {
      final c = createContainer();
      addTearDown(c.dispose);
      final notifier = c.read(quizSessionProvider.notifier);
      await notifier.start(const QuizConfig(questionCount: 3));
      for (var i = 0; i < 3; i++) {
        notifier.submitAnswer(
          c.read(quizSessionProvider)!.current.correctIndex,
        );
        notifier.next();
      }
      final (result, _) = notifier.finish()!;
      expect(result.isPerfect, isTrue);
      expect(c.read(progressProvider).totalXp, 30 + 50);
      expect(c.read(quizStatsProvider).perfectQuizzes, 1);
    });

    test('difficulty filter is respected and empty filters throw', () async {
      final c = createContainer();
      addTearDown(c.dispose);
      final notifier = c.read(quizSessionProvider.notifier);
      final s = await notifier.start(
        const QuizConfig(
          questionCount: 50,
          difficulty: Difficulty.hard,
          category: Track.react,
        ),
      );
      expect(
        s.questions.every((q) => q.source.difficulty == Difficulty.hard),
        isTrue,
      );
      expect(
        s.questions.every((q) => q.source.category == Track.react),
        isTrue,
      );

      final none = createContainer(
        assets: {...fixtureAssets(), 'assets/data/mcq_questions.json': '[]'},
      );
      addTearDown(none.dispose);
      expect(
        none.read(quizSessionProvider.notifier).start(const QuizConfig()),
        throwsA(isA<QuizGenerationException>()),
      );
    });

    test('quiz config remembers the chosen count', () {
      final store = InMemoryKeyValueStore();
      final c = createContainer(store: store);
      addTearDown(c.dispose);
      c.read(quizConfigProvider.notifier).setCount(20);
      expect(c.read(quizConfigProvider).questionCount, 20);
      expect(c.read(settingsProvider).lastQuizConfigCount, 20);
    });
  });

  group('Learn & interview providers', () {
    test('track progress and continue learning', () async {
      final c = createContainer();
      addTearDown(c.dispose);
      await c.read(allLessonsProvider.future);
      c.read(progressProvider.notifier).completeLesson('react_use_memo');
      expect(c.read(trackProgressProvider(Track.react)).value!.done, 1);
      expect(c.read(trackProgressProvider(Track.react)).value!.total, 2);
      final cont = c.read(continueLearningProvider).value!;
      expect(cont.lesson.id, 'react_use_callback');
      expect(cont.categoryDone, 1);
      expect(cont.categoryTotal, 2);
    });

    test('interview filter and session navigation', () async {
      final c = createContainer();
      addTearDown(c.dispose);
      c.read(interviewFilterProvider.notifier).toggleCategory(Track.next);
      final filtered = await c.read(filteredInterviewQuestionsProvider.future);
      expect(filtered.every((q) => q.category == Track.next), isTrue);

      final easy = await c.read(
        interviewByDifficultyProvider(Difficulty.easy).future,
      );
      expect(easy, hasLength(3));
      final first = c
          .read(interviewSessionProvider.notifier)
          .startWith('Easy', easy);
      final session = c.read(interviewSessionProvider)!;
      expect(session.nextAfter(first!), easy[1].id);
      c.read(interviewSessionProvider.notifier).review(first, known: true);
      expect(c.read(interviewSessionProvider)!.reviewedIds, {first});
      expect(c.read(interviewProgressProvider(Difficulty.easy)).value!.done, 1);
    });
  });
}
