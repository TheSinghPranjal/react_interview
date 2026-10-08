import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/repositories/repository_providers.dart';

/// Bookmarked lessons, interview questions and MCQs (most recent first).
class BookmarksNotifier extends Notifier<List<Bookmark>> {
  @override
  List<Bookmark> build() {
    final list = [...ref.read(bookmarkRepositoryProvider).load()]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  bool isBookmarked(BookmarkType type, String id) =>
      state.any((b) => b.type == type && b.itemId == id);

  /// Toggles a bookmark and returns whether the item is now bookmarked.
  bool toggle(BookmarkType type, String id) {
    final exists = isBookmarked(type, id);
    final next = exists
        ? state.where((b) => !(b.type == type && b.itemId == id)).toList()
        : [
            Bookmark(
              type: type,
              itemId: id,
              createdAt: ref.read(clockProvider)(),
            ),
            ...state,
          ];
    state = next;
    ref.read(bookmarkRepositoryProvider).save(next).ignore();
    return !exists;
  }

  Future<void> clearAll() async {
    state = const [];
    await ref.read(bookmarkRepositoryProvider).reset();
  }
}

final bookmarksProvider = NotifierProvider<BookmarksNotifier, List<Bookmark>>(
  BookmarksNotifier.new,
);

typedef BookmarkRef = ({BookmarkType type, String id});

/// Whether a single item is bookmarked; rebuilds only when that flips.
final isBookmarkedProvider = Provider.family<bool, BookmarkRef>(
  (ref, item) => ref.watch(
    bookmarksProvider.select(
      (list) => list.any((b) => b.type == item.type && b.itemId == item.id),
    ),
  ),
);

final bookmarksByTypeProvider = Provider.family<List<Bookmark>, BookmarkType>(
  (ref, type) => ref
      .watch(bookmarksProvider)
      .where((b) => b.type == type)
      .toList(growable: false),
);
