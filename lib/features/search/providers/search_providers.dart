import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import '../domain/search_engine.dart';

final searchIndexProvider = FutureProvider<SearchIndex>((ref) async {
  final (lessons, interview, mcqs) = await (
    ref.watch(allLessonsProvider.future),
    ref.watch(interviewQuestionsProvider.future),
    ref.watch(mcqQuestionsProvider.future),
  ).wait;
  return SearchIndex.build(lessons: lessons, interview: interview, mcqs: mcqs);
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchTypeFilterNotifier extends Notifier<SearchResultType?> {
  @override
  SearchResultType? build() => null;

  void set(SearchResultType? type) => state = type;
}

final searchTypeFilterProvider =
    NotifierProvider<SearchTypeFilterNotifier, SearchResultType?>(
      SearchTypeFilterNotifier.new,
    );

final searchProvider = Provider<AsyncValue<List<SearchResult>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final type = ref.watch(searchTypeFilterProvider);
  return ref
      .watch(searchIndexProvider)
      .whenData((index) => index.search(query, type: type));
});
