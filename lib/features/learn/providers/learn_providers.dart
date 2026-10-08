import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../progress/providers/progress_provider.dart';

@immutable
class TrackProgress {
  const TrackProgress({required this.done, required this.total});
  final int done;
  final int total;
  double get fraction => total == 0 ? 0 : done / total;
}

final _completedSetProvider = Provider<Set<String>>(
  (ref) =>
      ref.watch(progressProvider.select((p) => p.completedLessons)).toSet(),
);

final trackProgressProvider = Provider.family<AsyncValue<TrackProgress>, Track>(
  (ref, track) {
    final completed = ref.watch(_completedSetProvider);
    return ref
        .watch(lessonsByTrackProvider(track))
        .whenData(
          (lessons) => TrackProgress(
            done: lessons.where((l) => completed.contains(l.id)).length,
            total: lessons.length,
          ),
        );
  },
);

final isLessonCompletedProvider = Provider.family<bool, String>(
  (ref, id) => ref.watch(_completedSetProvider).contains(id),
);

@immutable
class ContinueLearning {
  const ContinueLearning({
    required this.lesson,
    required this.categoryDone,
    required this.categoryTotal,
  });

  final Lesson lesson;
  final int categoryDone;
  final int categoryTotal;
}

/// Picks what the learner should do next:
/// the last opened lesson if unfinished, else the next unfinished lesson
/// after it, else the first unfinished lesson overall.
@visibleForTesting
Lesson? pickContinueLesson(
  List<Lesson> all,
  Set<String> completed,
  String? lastOpenedId,
) {
  if (all.isEmpty) return null;
  final lastIndex = lastOpenedId == null
      ? -1
      : all.indexWhere((l) => l.id == lastOpenedId);
  if (lastIndex >= 0) {
    final last = all[lastIndex];
    if (!completed.contains(last.id)) return last;
    for (var i = lastIndex + 1; i < all.length; i++) {
      if (all[i].track == last.track && !completed.contains(all[i].id)) {
        return all[i];
      }
    }
  }
  return all.where((l) => !completed.contains(l.id)).firstOrNull;
}

final continueLearningProvider = Provider<AsyncValue<ContinueLearning?>>((ref) {
  final completed = ref.watch(_completedSetProvider);
  final lastOpened = ref.watch(
    progressProvider.select((p) => p.lastOpenedLessonId),
  );
  return ref.watch(allLessonsProvider).whenData((all) {
    final lesson = pickContinueLesson(all, completed, lastOpened);
    if (lesson == null) return null;
    final inCategory = all.where(
      (l) => l.track == lesson.track && l.category == lesson.category,
    );
    return ContinueLearning(
      lesson: lesson,
      categoryDone: inCategory.where((l) => completed.contains(l.id)).length,
      categoryTotal: inCategory.length,
    );
  });
});

/// A suggestion from the track the learner has explored least.
final recommendedLessonProvider = Provider<AsyncValue<Lesson?>>((ref) {
  final completed = ref.watch(_completedSetProvider);
  final continueId = ref.watch(continueLearningProvider).value?.lesson.id;
  return ref.watch(allLessonsProvider).whenData((all) {
    double fraction(Track t) {
      final list = all.where((l) => l.track == t);
      if (list.isEmpty) return 1;
      return list.where((l) => completed.contains(l.id)).length / list.length;
    }

    final tracks = [...Track.values]
      ..sort((a, b) => fraction(a).compareTo(fraction(b)));
    for (final t in tracks) {
      final candidate = all
          .where(
            (l) =>
                l.track == t && !completed.contains(l.id) && l.id != continueId,
          )
          .firstOrNull;
      if (candidate != null) return candidate;
    }
    return null;
  });
});

final recentlyCompletedProvider = Provider<AsyncValue<List<Lesson>>>((ref) {
  final ids = ref.watch(progressProvider.select((p) => p.completedLessons));
  return ref.watch(allLessonsProvider).whenData((all) {
    final byId = {for (final l in all) l.id: l};
    return [for (final id in ids.reversed.take(5)) ?byId[id]];
  });
});

/// Previous / next lesson within the same track.
final adjacentLessonsProvider =
    Provider.family<AsyncValue<(Lesson?, Lesson?)>, String>((ref, id) {
      return ref.watch(allLessonsProvider).whenData((all) {
        final i = all.indexWhere((l) => l.id == id);
        if (i < 0) return (null, null);
        final track = all[i].track;
        final prev = i > 0 && all[i - 1].track == track ? all[i - 1] : null;
        final next = i + 1 < all.length && all[i + 1].track == track
            ? all[i + 1]
            : null;
        return (prev, next);
      });
    });
