import '../../core/constants/app_constants.dart';
import '../datasources/local_content_datasource.dart';
import '../models/enums.dart';
import '../models/interview_question.dart';
import '../models/lesson.dart';
import '../models/mcq_question.dart';

/// Caches a future, but forgets it on failure so the next call retries.
class _Memo<T> {
  Future<T>? _future;

  Future<T> call(Future<T> Function() load) {
    final existing = _future;
    if (existing != null) return existing;
    final f = load();
    _future = f;
    f.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_future, f)) _future = null;
      },
    );
    return f;
  }
}

/// A group of lessons inside a track, in curriculum order.
class LessonCategory {
  const LessonCategory({
    required this.name,
    required this.track,
    required this.lessons,
  });

  final String name;
  final Track track;
  final List<Lesson> lessons;
}

class LessonRepository {
  LessonRepository(this._source);

  final LocalContentDataSource _source;
  final Map<Track, _Memo<List<Lesson>>> _memos = {
    for (final t in Track.values) t: _Memo<List<Lesson>>(),
  };

  static String assetFor(Track track) => switch (track) {
    Track.react => AppConstants.reactLessonsAsset,
    Track.next => AppConstants.nextLessonsAsset,
  };

  Future<List<Lesson>> lessons(Track track) => _memos[track]!(() async {
    final asset = assetFor(track);
    final raw = await _source.loadList(asset);
    final parsed = LocalContentDataSource.parseEach(
      asset,
      raw,
      (j) => Lesson.fromJson(j, fallbackTrack: track),
    );
    // Stable sort keeps JSON order for equal `order` values.
    final indexed = parsed.indexed.toList()
      ..sort((a, b) {
        final c = a.$2.order.compareTo(b.$2.order);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    return List.unmodifiable(indexed.map((e) => e.$2));
  });

  Future<List<Lesson>> allLessons() async {
    final results = await Future.wait(Track.values.map(lessons));
    return [for (final list in results) ...list];
  }

  Future<Lesson?> byId(String id) async {
    for (final lesson in await allLessons()) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  /// Groups lessons by category, preserving curriculum order.
  static List<LessonCategory> groupByCategory(Track track, List<Lesson> list) {
    final map = <String, List<Lesson>>{};
    for (final l in list) {
      map.putIfAbsent(l.category, () => []).add(l);
    }
    return [
      for (final e in map.entries)
        LessonCategory(name: e.key, track: track, lessons: e.value),
    ];
  }
}

class InterviewRepository {
  InterviewRepository(this._source);

  final LocalContentDataSource _source;
  final _memo = _Memo<List<InterviewQuestion>>();

  Future<List<InterviewQuestion>> all() => _memo(() async {
    const asset = AppConstants.interviewQuestionsAsset;
    final raw = await _source.loadList(asset);
    final parsed = LocalContentDataSource.parseEach(
      asset,
      raw,
      InterviewQuestion.fromJson,
    );
    final seen = <String>{};
    return List.unmodifiable(parsed.where((q) => seen.add(q.id)));
  });

  Future<InterviewQuestion?> byId(String id) async {
    for (final q in await all()) {
      if (q.id == id) return q;
    }
    return null;
  }
}

class QuizRepository {
  QuizRepository(this._source);

  final LocalContentDataSource _source;
  final _memo = _Memo<List<McqQuestion>>();

  /// All valid MCQs, de-duplicated by id.
  Future<List<McqQuestion>> all() => _memo(() async {
    const asset = AppConstants.mcqQuestionsAsset;
    final raw = await _source.loadList(asset);
    final parsed = LocalContentDataSource.parseEach(
      asset,
      raw,
      McqQuestion.fromJson,
    );
    final seen = <String>{};
    return List.unmodifiable(parsed.where((q) => seen.add(q.id)));
  });

  Future<McqQuestion?> byId(String id) async {
    for (final q in await all()) {
      if (q.id == id) return q;
    }
    return null;
  }
}
