import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/content_repositories.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/common.dart';
import '../../progress/providers/progress_provider.dart';
import '../providers/learn_providers.dart';
import 'widgets/learn_widgets.dart';

/// All categories and lessons of one track.
class TrackScreen extends ConsumerWidget {
  const TrackScreen({required this.track, super.key});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(lessonCategoriesProvider(track));
    final progress = ref.watch(trackProgressProvider(track)).value;
    final focus = GoRouterState.of(context).uri.queryParameters['category'];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(track.longLabel)),
      bottomNavigationBar: const BannerAdWidget(),
      body: AsyncValueView(
        value: categories,
        onRetry: () => ref.invalidate(lessonsByTrackProvider(track)),
        data: (cats) {
          if (cats.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No lessons yet',
              message: 'Lessons for this track will appear here.',
            );
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppCard(
                    child: Row(
                      children: [
                        ProgressRing(
                          value: progress?.fraction ?? 0,
                          child: Text(
                            '${((progress?.fraction ?? 0) * 100).round()}%',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track == Track.react
                                    ? 'Master modern React'
                                    : 'Build production-ready applications',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${progress?.done ?? 0} of ${progress?.total ?? 0} lessons · '
                                '${cats.length} categories',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverList.builder(
                  itemCount: cats.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _CategoryCard(
                      category: cats[i],
                      number: i + 1,
                      initiallyExpanded: focus == null
                          ? i == 0
                          : cats[i].name == focus,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.category,
    required this.number,
    required this.initiallyExpanded,
  });

  final LessonCategory category;
  final int number;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(
      progressProvider.select((p) => p.completedLessons),
    );
    final done = category.lessons.where((l) => completed.contains(l.id)).length;
    final total = category.lessons.length;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              '$number',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(category.name, style: theme.textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done of $total lessons completed',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedProgressBar(
                  value: total == 0 ? 0 : done / total,
                  height: 4,
                ),
              ],
            ),
          ),
          children: [
            for (var i = 0; i < category.lessons.length; i++)
              LessonTile(lesson: category.lessons[i], index: i),
          ],
        ),
      ),
    );
  }
}
