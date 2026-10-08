import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/shuffle.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/interview_question.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../progress/providers/progress_provider.dart';
import '../domain/interview_filter.dart';

class InterviewFilterNotifier extends Notifier<InterviewFilter> {
  @override
  InterviewFilter build() => const InterviewFilter();

  void toggleCategory(Track t) => state = state.toggleCategory(t);
  void toggleDifficulty(Difficulty d) => state = state.toggleDifficulty(d);
  void setTopic(String? topic) => state = state.withTopic(topic);
  void set(InterviewFilter filter) => state = filter;
  void clear() => state = const InterviewFilter();
}

final interviewFilterProvider =
    NotifierProvider<InterviewFilterNotifier, InterviewFilter>(
      InterviewFilterNotifier.new,
    );

final filteredInterviewQuestionsProvider =
    FutureProvider<List<InterviewQuestion>>((ref) async {
      final all = await ref.watch(interviewQuestionsProvider.future);
      return ref.watch(interviewFilterProvider).apply(all);
    });

final interviewByDifficultyProvider =
    FutureProvider.family<List<InterviewQuestion>, Difficulty>((
      ref,
      difficulty,
    ) async {
      final all = await ref.watch(interviewQuestionsProvider.future);
      return InterviewFilter(difficulties: {difficulty}).apply(all);
    });

@immutable
class InterviewProgressSummary {
  const InterviewProgressSummary({
    required this.total,
    required this.done,
    required this.known,
  });

  final int total;
  final int done;
  final int known;

  double get fraction => total == 0 ? 0 : done / total;
}

/// Question counts per topic, most common first.
final interviewTopicCountsProvider =
    FutureProvider.family<List<(String, int)>, Difficulty?>((
      ref,
      difficulty,
    ) async {
      final all = await ref.watch(interviewQuestionsProvider.future);
      final counts = <String, int>{};
      for (final q in all) {
        if (difficulty != null && q.difficulty != difficulty) continue;
        counts[q.topic] = (counts[q.topic] ?? 0) + 1;
      }
      return [for (final e in counts.entries) (e.key, e.value)]
        ..sort((a, b) => b.$2.compareTo(a.$2));
    });

/// Completion summary per difficulty (null = all questions).
final interviewProgressProvider =
    Provider.family<AsyncValue<InterviewProgressSummary>, Difficulty?>((
      ref,
      difficulty,
    ) {
      final progress = ref.watch(progressProvider);
      return ref.watch(interviewQuestionsProvider).whenData((all) {
        final list = difficulty == null
            ? all
            : all.where((q) => q.difficulty == difficulty);
        var done = 0;
        var known = 0;
        var total = 0;
        for (final q in list) {
          total++;
          if (progress.isInterviewDone(q.id)) done++;
          if (progress.interviewKnown.contains(q.id)) known++;
        }
        return InterviewProgressSummary(total: total, done: done, known: known);
      });
    });

/// An ordered practice queue of interview question ids.
@immutable
class InterviewSession {
  const InterviewSession({
    required this.title,
    required this.questionIds,
    this.reviewedIds = const {},
  });

  final String title;
  final List<String> questionIds;
  final Set<String> reviewedIds;

  int get length => questionIds.length;
  int indexOf(String id) => questionIds.indexOf(id);
  bool contains(String id) => questionIds.contains(id);
  bool get isFinished =>
      questionIds.isNotEmpty && reviewedIds.length >= questionIds.length;

  String? nextAfter(String id) {
    final i = indexOf(id);
    return i >= 0 && i + 1 < length ? questionIds[i + 1] : null;
  }

  String? previousBefore(String id) {
    final i = indexOf(id);
    return i > 0 ? questionIds[i - 1] : null;
  }
}

class InterviewSessionNotifier extends Notifier<InterviewSession?> {
  /// Size of a random interview set.
  static const int randomSetSize = 10;

  @override
  InterviewSession? build() => null;

  /// Starts a practice queue from an explicit list (e.g. a difficulty or a
  /// filtered list). Returns the first id, or null if [questions] is empty.
  String? startWith(String title, List<InterviewQuestion> questions) {
    if (questions.isEmpty) return null;
    state = InterviewSession(
      title: title,
      questionIds: [for (final q in questions) q.id],
    );
    return questions.first.id;
  }

  /// Random interview across all difficulties (respecting [filter]).
  Future<String?> startRandom({
    InterviewFilter filter = const InterviewFilter(),
    int count = randomSetSize,
  }) async {
    final all = await ref.read(interviewQuestionsProvider.future);
    final shuffled = fisherYatesShuffle(
      filter.apply(all),
      ref.read(randomProvider),
    );
    return startWith('Random Interview', shuffled.take(count).toList());
  }

  /// Makes sure a session exists that contains [id]; used when a question is
  /// opened directly (e.g. from search or bookmarks).
  void ensureContains(InterviewQuestion question, List<InterviewQuestion> all) {
    if (state?.contains(question.id) ?? false) return;
    final sameLevel = all
        .where((q) => q.difficulty == question.difficulty)
        .toList();
    state = InterviewSession(
      title: '${question.difficulty.label} questions',
      questionIds: [for (final q in sameLevel) q.id],
    );
  }

  /// Records a review in this session and in overall progress.
  ActivityOutcome review(String id, {required bool known}) {
    final s = state;
    if (s != null && s.contains(id)) {
      state = InterviewSession(
        title: s.title,
        questionIds: s.questionIds,
        reviewedIds: {...s.reviewedIds, id},
      );
    }
    return ref
        .read(progressProvider.notifier)
        .markInterviewQuestion(id, known: known);
  }

  void end() => state = null;
}

final interviewSessionProvider =
    NotifierProvider<InterviewSessionNotifier, InterviewSession?>(
      InterviewSessionNotifier.new,
    );
