import 'package:flutter/foundation.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/interview_question.dart';

/// Interview filters. Empty sets mean "all".
@immutable
class InterviewFilter {
  const InterviewFilter({
    this.categories = const {},
    this.difficulties = const {},
  });

  final Set<Track> categories;
  final Set<Difficulty> difficulties;

  bool get isEmpty => categories.isEmpty && difficulties.isEmpty;

  bool matches(InterviewQuestion q) =>
      (categories.isEmpty || categories.contains(q.category)) &&
      (difficulties.isEmpty || difficulties.contains(q.difficulty));

  List<InterviewQuestion> apply(List<InterviewQuestion> questions) =>
      questions.where(matches).toList(growable: false);

  InterviewFilter toggleCategory(Track t) => InterviewFilter(
    categories: categories.contains(t)
        ? ({...categories}..remove(t))
        : {...categories, t},
    difficulties: difficulties,
  );

  InterviewFilter toggleDifficulty(Difficulty d) => InterviewFilter(
    categories: categories,
    difficulties: difficulties.contains(d)
        ? ({...difficulties}..remove(d))
        : {...difficulties, d},
  );

  @override
  bool operator ==(Object other) =>
      other is InterviewFilter &&
      setEquals(other.categories, categories) &&
      setEquals(other.difficulties, difficulties);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(difficulties),
  );
}
