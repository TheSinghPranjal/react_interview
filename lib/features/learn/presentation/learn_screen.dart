import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/content_repositories.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/dashboard.dart';
import '../../progress/providers/progress_provider.dart';
import '../providers/learn_providers.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final children = <Widget>[
      const _LearnHeader(),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Two tracks, from fundamentals to production. '
        'Every lesson explains what, why, when and how.',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 15,
          height: 1.4,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const _LearnTrackCard(track: Track.react),
      const SizedBox(height: AppSpacing.md),
      const _LearnTrackCard(track: Track.next),
      for (final track in Track.values) _CategoryOverview(track: track),
      const SizedBox(height: AppSpacing.xl),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          padding: AppSpacing.screen,
          itemCount: children.length,
          itemBuilder: (context, i) =>
              FadeSlideIn(index: i, child: children[i]),
        ),
      ),
    );
  }
}

class _LearnHeader extends StatelessWidget {
  const _LearnHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = isDarkTheme(context);
    return Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Semantics(
              header: true,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) => LinearGradient(
                  colors: dark
                      ? const [Color(0xFF60A5FA), Color(0xFFA5B4FC)]
                      : const [Color(0xFF1D5FD8), Color(0xFF3B3FD8)],
                ).createShader(r),
                child: const Text(
                  'Learn',
                  style: TextStyle(
                    fontSize: 44,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Semantics(
                button: true,
                label: 'Search lessons',
                excludeSemantics: true,
                child: Material(
                  color: dark
                      ? scheme.surfaceContainer
                      : const Color(0xFFE9ECF8),
                  borderRadius: AppRadius.pillAll,
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.search),
                    borderRadius: AppRadius.pillAll,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.search_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search lessons...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LearnTrackCard extends ConsumerWidget {
  const _LearnTrackCard({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(trackProgressProvider(track)).value;
    final isReact = track == Track.react;
    final title = isReact ? 'React' : 'Next.js';
    final subtitle = isReact
        ? 'Master modern React'
        : 'Build production-ready applications';
    final fraction = progress?.fraction ?? 0;
    final white70 = Colors.white.withValues(alpha: 0.88);
    void open() => context.go(AppRoutes.track(track));
    final meta = TextStyle(
      color: white70,
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
    );
    return TapCard(
      onTap: open,
      gradient: isReact
          ? const LinearGradient(
              colors: [Color(0xFF1677F0), Color(0xFF4652EE), Color(0xFF8B5CF6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : DashColors.nextTrack,
      shadows: [
        BoxShadow(
          color: (isReact ? const Color(0xFF3A55EE) : const Color(0xFF0B0F1C))
              .withValues(alpha: 0.25),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      semanticLabel:
          '$title track. $subtitle. '
          '${progress?.done ?? 0} of ${progress?.total ?? 0} lessons completed',
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 50,
              top: 0,
              bottom: 20,
              child: Opacity(
                opacity: 0.16,
                child: isReact
                    ? const ReactLogo(size: 110, color: Colors.white)
                    : const Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 110,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isReact
                            ? const Color(0xFF0B3D7A).withValues(alpha: 0.85)
                            : Colors.black,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: isReact
                          ? const ReactLogo(size: 38)
                          : const NextLogo(size: 44),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(color: white70, fontSize: 14.5),
                          ),
                        ],
                      ),
                    ),
                    ProgressRing(
                      value: fraction,
                      size: 52,
                      strokeWidth: 4,
                      color: DashColors.cyan,
                      trackColor: Colors.white.withValues(alpha: 0.22),
                      child: Text(
                        '${(fraction * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 16,
                                  color: white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${progress?.total ?? 0} lessons',
                                  style: meta,
                                ),
                                Container(
                                  width: 1,
                                  height: 14,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                SignalBars(color: white70),
                                const SizedBox(width: 6),
                                Text('Beginner → Advanced', style: meta),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedProgressBar(
                            value: fraction,
                            height: 7,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Material(
                      color: isReact
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.lgAll,
                        side: isReact
                            ? BorderSide.none
                            : BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                      ),
                      child: InkWell(
                        onTap: open,
                        borderRadius: AppRadius.lgAll,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore',
                                style: TextStyle(
                                  color: isReact
                                      ? const Color(0xFF3B3FD8)
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: isReact
                                    ? const Color(0xFF3B3FD8)
                                    : Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon and accent for a lesson category, cycling a palette when unknown.
(IconData, Color) _categoryVisual(String name, int index) {
  const palette = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFE11D48),
    Color(0xFF059669),
    Color(0xFFF59E0B),
    Color(0xFF6D28D9),
  ];
  final color = palette[index % palette.length];
  final icon = switch (name) {
    _ when name.contains('Fundamentals') => Icons.menu_book_rounded,
    'Components' || 'Client Components' => Icons.view_in_ar_rounded,
    'JSX' => Icons.code_rounded,
    'Props & State' => Icons.storage_rounded,
    'Events & Forms' => Icons.bolt_rounded,
    'Hooks' || 'Advanced Hooks' => Icons.link_rounded,
    'Rendering' => Icons.layers_rounded,
    'Performance' => Icons.speed_rounded,
    'Modern React' => Icons.auto_awesome_rounded,
    'Server Components' => Icons.dns_rounded,
    'Testing' => Icons.science_rounded,
    'Best Practices' => Icons.verified_rounded,
    'App Router' || 'Routing' => Icons.alt_route_rounded,
    'Layouts' => Icons.dashboard_rounded,
    'Data Fetching' => Icons.cloud_download_rounded,
    'Caching' => Icons.cached_rounded,
    'Server Actions' => Icons.flash_on_rounded,
    'Route Handlers' => Icons.api_rounded,
    'Authentication' => Icons.shield_rounded,
    'SEO' => Icons.travel_explore_rounded,
    'Deployment' => Icons.rocket_launch_rounded,
    _ => Icons.folder_open_rounded,
  };
  return (icon, color);
}

class _CategoryOverview extends ConsumerWidget {
  const _CategoryOverview({required this.track});
  final Track track;

  static const _shown = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(lessonCategoriesProvider(track));
    final completed = ref.watch(
      progressProvider.select((p) => p.completedLessons),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashSectionHeader(
          '${track.longLabel} categories',
          subtitle: track == Track.react
              ? 'Start with the basics and build step by step.'
              : 'Learn to build real-world applications.',
          onViewAll: () => context.go(AppRoutes.track(track)),
        ),
        AsyncValueView(
          value: categories,
          onRetry: () => ref.invalidate(lessonsByTrackProvider(track)),
          data: (cats) {
            final shown = cats.take(_shown).toList();
            return LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth < 330 ? 1 : 2;
                return Column(
                  children: [
                    for (var i = 0; i < shown.length; i += columns)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var j = i; j < i + columns; j++) ...[
                                if (j > i) const SizedBox(width: 10),
                                Expanded(
                                  child: j < shown.length
                                      ? _CategoryTile(
                                          category: shown[j],
                                          index: j,
                                          completed: completed,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.index,
    required this.completed,
  });

  final LessonCategory category;
  final int index;
  final Iterable<String> completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    final (icon, color) = _categoryVisual(category.name, index);
    final done = category.lessons.where((l) => completed.contains(l.id)).length;
    final total = category.lessons.length;
    final allDone = total > 0 && done == total;
    return TapCard(
      onTap: () => context.go(
        '${AppRoutes.track(category.track)}'
        '?category=${Uri.encodeQueryComponent(category.name)}',
      ),
      radius: AppRadius.lgAll,
      color: dark ? scheme.surface : Color.lerp(Colors.white, color, 0.025),
      borderColor: dark
          ? scheme.outlineVariant
          : Color.lerp(Colors.white, color, 0.16),
      padding: const EdgeInsets.fromLTRB(10, 12, 2, 12),
      semanticLabel: '${category.name}: $done of $total lessons completed',
      child: ExcludeSemantics(
        child: Row(
          children: [
            IconDisc(
              icon: allDone ? Icons.check_rounded : icon,
              color: color,
              size: 40,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$done / $total lessons',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
