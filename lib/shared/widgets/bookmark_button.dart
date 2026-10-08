import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/bookmark.dart';
import '../../features/bookmarks/providers/bookmarks_provider.dart';

/// Toggles a bookmark for any bookmarkable item.
class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({
    required this.type,
    required this.itemId,
    this.color,
    super.key,
  });

  final BookmarkType type;
  final String itemId;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isBookmarkedProvider((type: type, id: itemId)));
    return IconButton(
      tooltip: saved ? 'Remove bookmark' : 'Bookmark',
      isSelected: saved,
      onPressed: () {
        final now = ref.read(bookmarksProvider.notifier).toggle(type, itemId);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(now ? 'Bookmarked' : 'Bookmark removed'),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, a) =>
            ScaleTransition(scale: a, child: child),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey(saved),
          color: saved ? Theme.of(context).colorScheme.primary : color,
        ),
      ),
    );
  }
}
