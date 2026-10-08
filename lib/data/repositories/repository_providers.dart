import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../datasources/local_content_datasource.dart';
import '../models/enums.dart';
import '../models/interview_question.dart';
import '../models/lesson.dart';
import '../models/mcq_question.dart';
import 'content_repositories.dart';
import 'user_repositories.dart';

final contentDataSourceProvider = Provider<LocalContentDataSource>(
  (ref) => LocalContentDataSource(ref.watch(assetBundleProvider)),
);

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(ref.watch(contentDataSourceProvider)),
);

final interviewRepositoryProvider = Provider<InterviewRepository>(
  (ref) => InterviewRepository(ref.watch(contentDataSourceProvider)),
);

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.watch(contentDataSourceProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(keyValueStoreProvider)),
);

final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => BookmarkRepository(ref.watch(keyValueStoreProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(keyValueStoreProvider)),
);

// ---------------------------------------------------------------------------
// Content providers (cached for the app lifetime).
// ---------------------------------------------------------------------------

final lessonsByTrackProvider = FutureProvider.family<List<Lesson>, Track>(
  (ref, track) => ref.watch(lessonRepositoryProvider).lessons(track),
);

final allLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final react = await ref.watch(lessonsByTrackProvider(Track.react).future);
  final next = await ref.watch(lessonsByTrackProvider(Track.next).future);
  return [...react, ...next];
});

final lessonCategoriesProvider =
    FutureProvider.family<List<LessonCategory>, Track>((ref, track) async {
      final lessons = await ref.watch(lessonsByTrackProvider(track).future);
      return LessonRepository.groupByCategory(track, lessons);
    });

final lessonByIdProvider = FutureProvider.family<Lesson?, String>((
  ref,
  id,
) async {
  final all = await ref.watch(allLessonsProvider.future);
  return all.where((l) => l.id == id).firstOrNull;
});

final interviewQuestionsProvider = FutureProvider<List<InterviewQuestion>>(
  (ref) => ref.watch(interviewRepositoryProvider).all(),
);

final interviewQuestionByIdProvider =
    FutureProvider.family<InterviewQuestion?, String>((ref, id) async {
      final all = await ref.watch(interviewQuestionsProvider.future);
      return all.where((q) => q.id == id).firstOrNull;
    });

final mcqQuestionsProvider = FutureProvider<List<McqQuestion>>(
  (ref) => ref.watch(quizRepositoryProvider).all(),
);
