import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/highlighted_text.dart';
import '../../bookmarks/presentation/bookmarks_screen.dart';
import '../domain/search_engine.dart';
import '../providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(searchQueryProvider),
  );

  static const _suggestions = [
    'useEffect',
    'Server Components',
    'hydration',
    'useMemo',
    'caching',
    'Server Actions',
    'keys',
    'Suspense',
    'revalidate',
    'useOptimistic',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    ref.read(searchQueryProvider.notifier).set(q);
  }

  Future<void> _open(SearchResult r) async {
    switch (r.type) {
      case SearchResultType.lesson:
        await context.push(AppRoutes.lesson(r.track, r.id));
      case SearchResultType.interview:
        await context.push(AppRoutes.interviewQuestion(r.id));
      case SearchResultType.mcq:
        final all = await ref.read(mcqQuestionsProvider.future);
        final q = all.where((m) => m.id == r.id).firstOrNull;
        if (q != null && mounted) await showMcqSheet(context, q);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final type = ref.watch(searchTypeFilterProvider);
    final results = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search lessons, questions, concepts…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => _setQuery(''),
                  ),
          ),
          onChanged: ref.read(searchQueryProvider.notifier).set,
        ),
        actions: const [SizedBox(width: AppSpacing.md)],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: type == null,
                  onSelected: (_) =>
                      ref.read(searchTypeFilterProvider.notifier).set(null),
                ),
                for (final t in SearchResultType.values) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: Text(t.label),
                    selected: type == t,
                    onSelected: (_) =>
                        ref.read(searchTypeFilterProvider.notifier).set(t),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: query.trim().isEmpty
                ? ListView(
                    padding: AppSpacing.screen,
                    children: [
                      Text('Popular topics', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final s in _suggestions)
                            ActionChip(
                              label: Text(s),
                              onPressed: () => _setQuery(s),
                            ),
                        ],
                      ),
                    ],
                  )
                : AsyncValueView(
                    value: results,
                    onRetry: () => ref.invalidate(searchIndexProvider),
                    data: (list) {
                      if (list.isEmpty) {
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No results for "$query"',
                          message:
                              'Try a shorter term or a hook name like "useRef".',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          0,
                          AppSpacing.sm,
                          AppSpacing.xl,
                        ),
                        itemCount: list.length + 1,
                        separatorBuilder: (_, _) => const Divider(indent: 64),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  '${list.length} result${list.length == 1 ? '' : 's'}',
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                            );
                          }
                          final r = list[i - 1];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              child: Icon(
                                switch (r.type) {
                                  SearchResultType.lesson =>
                                    Icons.menu_book_rounded,
                                  SearchResultType.interview =>
                                    Icons.record_voice_over_rounded,
                                  SearchResultType.mcq => Icons.quiz_rounded,
                                },
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: HighlightedText(
                              r.title,
                              query: query,
                              maxLines: 2,
                              style: theme.textTheme.titleSmall,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.type.label} · ${r.meta}',
                                  style: theme.textTheme.labelSmall,
                                ),
                                const SizedBox(height: 2),
                                HighlightedText(
                                  r.snippet,
                                  query: query,
                                  maxLines: 2,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            onTap: () => _open(r),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
