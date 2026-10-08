import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/common.dart';
import '../../progress/providers/progress_provider.dart';
import 'widgets/learn_widgets.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        actions: [
          IconButton(
            tooltip: 'Search lessons',
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Text(
            'Two tracks, from fundamentals to production. '
            'Every lesson explains what, why, when and how.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FadeSlideIn(child: TrackCard(track: Track.react)),
          const SizedBox(height: AppSpacing.md),
          const FadeSlideIn(index: 1, child: TrackCard(track: Track.next)),
          for (final track in Track.values) _CategoryOverview(track: track),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _CategoryOverview extends ConsumerWidget {
  const _CategoryOverview({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(lessonCategoriesProvider(track));
    final completed = ref.watch(
      progressProvider.select((p) => p.completedLessons),
    );
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          '${track.longLabel} categories',
          action: 'View all',
          onAction: () => context.go(AppRoutes.track(track)),
        ),
        AsyncValueView(
          value: categories,
          onRetry: () => ref.invalidate(lessonsByTrackProvider(track)),
          data: (cats) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final c in cats)
                ActionChip(
                  avatar: Icon(
                    c.lessons.every((l) => completed.contains(l.id))
                        ? Icons.check_circle_rounded
                        : Icons.folder_open_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    '${c.name} · '
                    '${c.lessons.where((l) => completed.contains(l.id)).length}'
                    '/${c.lessons.length}',
                  ),
                  onPressed: () => context.go(
                    '${AppRoutes.track(track)}?category=${Uri.encodeQueryComponent(c.name)}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
