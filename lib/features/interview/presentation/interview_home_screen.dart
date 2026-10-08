import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/dashboard.dart';
import '../domain/interview_filter.dart';
import '../providers/interview_providers.dart';
import 'interview_widgets.dart';

class InterviewHomeScreen extends ConsumerWidget {
  const InterviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[
      DashHero(
        badge: const ScreenBadge(
          icon: Icon(Icons.record_voice_over_rounded),
          label: 'Interview',
        ),
        action: SquareIconButton(
          icon: Icons.bookmarks_outlined,
          tooltip: 'Bookmarks',
          onPressed: () => context.push(AppRoutes.bookmarks),
        ),
        semanticTitle: 'Prepare for your next React interview',
        title: [
          const TextSpan(text: 'Prepare for your next '),
          TextSpan(
            text: 'React',
            style: TextStyle(
              color: isDarkTheme(context)
                  ? const Color(0xFF60A5FA)
                  : DashColors.reactBlue,
            ),
          ),
          const TextSpan(text: ' interview'),
        ],
        subtitle:
            '150 hand-picked questions across React and Next.js, '
            'from fundamentals to architecture scenarios.',
        art: 'assets/images/interview_hero.png',
        artWidth: 150,
        artTop: 52,
        titleFontSize: 23,
        titleWidthFactor: 0.72,
        subtitleWidthFactor: 0.6,
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final d in Difficulty.values) ...[
        _DifficultyCard(difficulty: d),
        const SizedBox(height: AppSpacing.md),
      ],
      RandomInterviewBanner(onTap: () => startRandomInterview(context, ref)),
      DashSectionHeader(
        'Browse questions',
        onViewAll: () {
          ref.read(interviewFilterProvider.notifier).clear();
          context.push(AppRoutes.interviewBrowse);
        },
      ),
      const _BrowseTiles(),
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

/// Starts a 10-question random interview using the current filter.
Future<void> startRandomInterview(
  BuildContext context,
  WidgetRef ref, {
  InterviewFilter filter = const InterviewFilter(),
}) async {
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

class _DifficultyCard extends ConsumerWidget {
  const _DifficultyCard({required this.difficulty});
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(interviewProgressProvider(difficulty)).value;
    final topics =
        ref.watch(interviewTopicCountsProvider(difficulty)).value ?? const [];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    final fg = DashColors.difficulty(difficulty, dark: dark);
    final (blurb, art, tint) = switch (difficulty) {
      Difficulty.easy => (
        'Core concepts every React developer must know.',
        'assets/images/interview_easy.png',
        const [Color(0xFFEFFBF3), Color(0xFFF6FDF8)],
      ),
      Difficulty.medium => (
        'Hooks, rendering, data fetching and trade-offs.',
        'assets/images/interview_medium.png',
        const [Color(0xFFFFF4E8), Color(0xFFFFFAF3)],
      ),
      Difficulty.hard => (
        'Architecture, performance and real scenarios.',
        'assets/images/interview_hard.png',
        const [Color(0xFFFEEFF0), Color(0xFFFFF6F6)],
      ),
    };
    final total = summary?.total ?? 50;
    final done = summary?.done ?? 0;
    return TapCard(
      onTap: () => context.go(AppRoutes.interviewLevel(difficulty)),
      gradient: dark
          ? null
          : LinearGradient(
              colors: tint,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      borderColor: dark
          ? scheme.outlineVariant
          : Color.lerp(tint.first, fg, 0.18),
      shadows: const [],
      padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
      semanticLabel:
          '${difficulty.label}: $total questions, $done reviewed. $blurb',
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Positioned(
              right: 30,
              top: 0,
              child: Image.asset(art, width: 92, height: 82),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressRing(
                  value: summary?.fraction ?? 0,
                  size: 64,
                  strokeWidth: 6,
                  color: fg,
                  trackColor: fg.withValues(alpha: 0.18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$done',
                        style: TextStyle(
                          color: fg,
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '/ $total',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            difficulty.label,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          TagPill(
                            label: difficulty.label,
                            color: fg,
                            background: fg.withValues(alpha: 0.12),
                            leading: difficultyBars(difficulty, fg, size: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$total Questions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(right: 70),
                        child: Text(
                          blurb,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final (t, _) in topics.take(4))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: fg.withValues(alpha: dark ? 0.2 : 0.1),
                                borderRadius: AppRadius.pillAll,
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  color: fg,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: dark ? scheme.surfaceContainer : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: DashColors.softShadow(context),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal strip: React, Next.js, then the most common topics.
class _BrowseTiles extends ConsumerWidget {
  const _BrowseTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics =
        ref.watch(interviewTopicCountsProvider(null)).value ?? const [];
    final questions = ref.watch(interviewQuestionsProvider).value ?? const [];
    int count(Track t) => questions.where((q) => q.category == t).length;
    final notifier = ref.read(interviewFilterProvider.notifier);
    void open(InterviewFilter f) {
      notifier.set(f);
      context.push(AppRoutes.interviewBrowse);
    }

    final tiles = <Widget>[
      _BrowseTile(
        icon: const ReactLogo(size: 30, color: Color(0xFF0EA5E9)),
        tint: const Color(0xFF0EA5E9),
        title: 'React',
        count: count(Track.react),
        onTap: () => open(const InterviewFilter(categories: {Track.react})),
      ),
      _BrowseTile(
        icon: const NextLogo(size: 34),
        tint: const Color(0xFF64748B),
        title: 'Next.js',
        count: count(Track.next),
        onTap: () => open(const InterviewFilter(categories: {Track.next})),
      ),
      for (final (t, n) in topics.take(6))
        Builder(
          builder: (context) {
            final (icon, color) = topicVisual(t);
            return _BrowseTile(
              icon: Icon(icon, color: color, size: 26),
              tint: color,
              title: t,
              count: n,
              onTap: () => open(InterviewFilter(topic: t)),
            );
          },
        ),
    ];
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => tiles[i],
      ),
    );
  }
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final Widget icon;
  final Color tint;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      width: 112,
      child: TapCard(
        onTap: onTap,
        radius: AppRadius.lgAll,
        borderColor: scheme.outlineVariant.withValues(alpha: 0.7),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        semanticLabel: '$title: $count questions',
        child: ExcludeSemantics(
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: icon,
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count Qs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
