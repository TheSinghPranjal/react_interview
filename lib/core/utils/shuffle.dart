import 'dart:math';

/// Returns a new list containing the elements of [source] in a uniformly
/// random order, using the Fisher–Yates (Durstenfeld) algorithm.
///
/// The [source] list is never modified.
List<T> fisherYatesShuffle<T>(List<T> source, Random random) {
  final result = List<T>.of(source);
  for (var i = result.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    if (i != j) {
      final tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
  }
  return result;
}
