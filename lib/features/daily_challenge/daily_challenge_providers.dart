import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/daily_challenge.dart';
import '../../data/models/interview_question.dart';
import '../../data/models/lesson.dart';
import '../../data/models/mcq_question.dart';
import '../../data/repositories/repository_providers.dart';
import '../progress/providers/progress_provider.dart';

/// Deterministic daily challenge selection: the same date always yields the
/// same challenge, so reopening the app never changes it.
abstract final class DailyChallengeSelector {
  static DailyChallenge? select({
    required DateTime date,
    required List<McqQuestion> mcqs,
    required List<InterviewQuestion> interview,
    required List<Lesson> lessons,
  }) {
    final day = AppDates.dayNumber(date);
    final key = AppDates.dayKey(date);
    final lessonPool = lessons
        .where((l) => l.interviewQuestion != null)
        .toList();
    final kinds = DailyChallengeType.values;

    // Try the scheduled type first, then fall back to any non-empty pool.
    for (var offset = 0; offset < kinds.length; offset++) {
      final kind = kinds[(day + offset) % kinds.length];
      switch (kind) {
        case DailyChallengeType.mcq when mcqs.isNotEmpty:
          return DailyChallenge.mcq(key, mcqs[_index(day, mcqs.length)]);
        case DailyChallengeType.interview when interview.isNotEmpty:
          return DailyChallenge.interview(
            key,
            interview[_index(day, interview.length)],
          );
        case DailyChallengeType.lesson when lessonPool.isNotEmpty:
          return DailyChallenge.lesson(
            key,
            lessonPool[_index(day, lessonPool.length)],
          );
        default:
          continue;
      }
    }
    return null;
  }

  /// Spreads consecutive days across the pool using a large prime stride.
  static int _index(int day, int length) => (day * 7919 + 13).abs() % length;
}

final dailyChallengeProvider = FutureProvider<DailyChallenge?>((ref) async {
  final now = ref.watch(clockProvider)();
  final (mcqs, interview, lessons) = await (
    ref.watch(mcqQuestionsProvider.future),
    ref.watch(interviewQuestionsProvider.future),
    ref.watch(allLessonsProvider.future),
  ).wait;
  return DailyChallengeSelector.select(
    date: now,
    mcqs: mcqs,
    interview: interview,
    lessons: lessons,
  );
});

final dailyChallengeDoneProvider = Provider<bool>((ref) {
  final key = AppDates.dayKey(ref.watch(clockProvider)());
  return ref.watch(
    progressProvider.select((p) => p.dailyChallengeDays.contains(key)),
  );
});
