import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/common.dart';
import '../providers/interview_providers.dart';
import 'interview_widgets.dart';

class InterviewHomeScreen extends ConsumerWidget {
  const InterviewHomeScreen({super.key});

  Future<void> _startRandom(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(interviewFilterProvider);
    final id = await ref
        .read(interviewSessionProvider.notifier)
        .startRandom(filter: filter);
    if (!context.mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions match your filters.')),
      );
      return;
    }
    await context.push(AppRoutes.interviewQuestion(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredInterviewQuestionsProvider);
    final filter = ref.watch(interviewFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview'),
        actions: [
          IconButton(
            tooltip: 'Bookmarks',
            onPressed: () => context.push(AppRoutes.bookmarks),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverList.list(
              children: [
                Text(
                  'Prepare for your next React interview',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '150 hand-picked questions across React and Next.js, '
                  'from fundamentals to architecture scenarios.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final (i, d) in Difficulty.values.indexed) ...[
                  FadeSlideIn(
                    index: i,
                    child: _DifficultyCard(difficulty: d),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                FadeSlideIn(
                  index: 3,
                  child: AppCard(
                    gradient: AppColors.brandGradient,
                    onTap: () => _startRandom(context, ref),
                    semanticLabel: 'Start a random interview of 10 questions',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shuffle_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Random Interview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '10 questions across all levels'
                                '${filter.isEmpty ? '' : ' (filtered)'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
                const SectionHeader('Browse questions'),
                _FilterBar(),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          ...filtered.when(
            skipLoadingOnReload: true,
            data: (list) => [
              if (list.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'No questions match',
                    message: 'Try removing a filter.',
                    action: TextButton(
                      onPressed: () =>
                          ref.read(interviewFilterProvider.notifier).clear(),
                      child: const Text('Clear filters'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    0,
                    AppSpacing.sm,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) => InterviewQuestionTile(
                      question: list[i],
                      number: i + 1,
                      onTap: () {
                        ref
                            .read(interviewSessionProvider.notifier)
                            .startWith('Filtered questions', list);
                        context.push(AppRoutes.interviewQuestion(list[i].id));
                      },
                    ),
                  ),
                ),
            ],
            loading: () => [
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              SliverToBoxAdapter(
                child: ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(interviewQuestionsProvider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends ConsumerWidget {
  const _DifficultyCard({required this.difficulty});
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(interviewProgressProvider(difficulty)).value;
    final theme = Theme.of(context);
    final color = AppColors.difficulty(difficulty.label);
    final dark = theme.brightness == Brightness.dark;
    final fg = dark ? Color.lerp(color, Colors.white, 0.45)! : color;
    final blurb = switch (difficulty) {
      Difficulty.easy => 'Core concepts every React developer must know',
      Difficulty.medium => 'Hooks, rendering, data fetching and trade-offs',
      Difficulty.hard => 'Architecture, performance and real scenarios',
    };
    return AppCard(
      onTap: () => context.go(AppRoutes.interviewLevel(difficulty)),
      semanticLabel:
          '${difficulty.label}: ${summary?.total ?? 50} questions, '
          '${summary?.done ?? 0} reviewed',
      child: Row(
        children: [
          ProgressRing(
            value: summary?.fraction ?? 0,
            size: 56,
            strokeWidth: 6,
            color: fg,
            child: Text(
              '${summary?.done ?? 0}',
              style: theme.textTheme.titleSmall?.copyWith(color: fg),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(difficulty.label, style: theme.textTheme.titleLarge),
                    DifficultyBadge(difficulty),
                  ],
                ),
                Text(
                  '${summary?.total ?? 50} Questions',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(blurb, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(interviewFilterProvider);
    final notifier = ref.read(interviewFilterProvider.notifier);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in Track.values)
          FilterChip(
            label: Text(t.label),
            selected: filter.categories.contains(t),
            onSelected: (_) => notifier.toggleCategory(t),
          ),
        for (final d in Difficulty.values)
          FilterChip(
            label: Text(d.label),
            selected: filter.difficulties.contains(d),
            onSelected: (_) => notifier.toggleDifficulty(d),
          ),
        if (!filter.isEmpty)
          ActionChip(
            avatar: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Clear'),
            onPressed: notifier.clear,
          ),
      ],
    );
  }
}
