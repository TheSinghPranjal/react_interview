import 'package:flutter/foundation.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/interview_question.dart';

/// Interview filters. Empty sets (and a null topic) mean "all".
@immutable
class InterviewFilter {
  const InterviewFilter({
    this.categories = const {},
    this.difficulties = const {},
    this.topic,
  });

  final Set<Track> categories;
  final Set<Difficulty> difficulties;
  final String? topic;

  bool get isEmpty =>
      categories.isEmpty && difficulties.isEmpty && topic == null;

  bool matches(InterviewQuestion q) =>
      (categories.isEmpty || categories.contains(q.category)) &&
      (difficulties.isEmpty || difficulties.contains(q.difficulty)) &&
      (topic == null || q.topic == topic);

  List<InterviewQuestion> apply(List<InterviewQuestion> questions) =>
      questions.where(matches).toList(growable: false);

  InterviewFilter toggleCategory(Track t) => InterviewFilter(
    categories: categories.contains(t)
        ? ({...categories}..remove(t))
        : {...categories, t},
    difficulties: difficulties,
    topic: topic,
  );

  InterviewFilter toggleDifficulty(Difficulty d) => InterviewFilter(
    categories: categories,
    difficulties: difficulties.contains(d)
        ? ({...difficulties}..remove(d))
        : {...difficulties, d},
    topic: topic,
  );

  InterviewFilter withTopic(String? value) => InterviewFilter(
    categories: categories,
    difficulties: difficulties,
    topic: value,
  );

  @override
  bool operator ==(Object other) =>
      other is InterviewFilter &&
      setEquals(other.categories, categories) &&
      setEquals(other.difficulties, difficulties) &&
      other.topic == topic;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(difficulties),
    topic,
  );
}
