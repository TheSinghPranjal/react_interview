import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/common.dart';
import '../../daily_challenge/daily_challenge_providers.dart';
import '../../interview/providers/interview_providers.dart';
import '../../learn/presentation/widgets/learn_widgets.dart';
import '../../learn/providers/learn_providers.dart';
import '../../progress/presentation/progress_widgets.dart';
import '../../progress/providers/progress_provider.dart';
import '../../settings/providers/settings_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[
      const _Header(),
      const SizedBox(height: AppSpacing.lg),
      const LevelCard(),
      const SizedBox(height: AppSpacing.md),
      const _StatsGrid(),
      const SizedBox(height: AppSpacing.md),
      const StreakWeekCard(),
      const SectionHeader('Continue learning'),
      const _ContinueLearningCard(),
      const SectionHeader('Your tracks'),
      const _TrackRow(),
      const SectionHeader('Daily challenge'),
      const _DailyChallengeCard(),
      const SectionHeader('Practice'),
      const _InterviewProgressCard(),
      const SizedBox(height: AppSpacing.md),
      const _QuizStatsCard(),
      const _RecommendedSection(),
      const _RecentlyCompletedSection(),
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

class _Header extends ConsumerWidget {
  const _Header();

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(settingsProvider.select((s) => s.userName));
    final now = ref.watch(clockProvider)();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_greeting(now)}, $name 👋',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Search',
              onPressed: () => context.push(AppRoutes.search),
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: 'Bookmarks',
              onPressed: () => context.push(AppRoutes.bookmarks),
              icon: const Icon(Icons.bookmarks_outlined),
            ),
          ],
        ),
        Semantics(
          header: true,
          child: Text(
            AppConstants.tagline,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppConstants.subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider.select((s) => s.current));
    final level = ref.watch(levelProvider);
    final lessons = ref.watch(
      progressProvider.select((p) => p.lessonsCompleted),
    );
    final interview = ref.watch(
      progressProvider.select((p) => p.interviewCompleted),
    );
    final stats = ref.watch(quizStatsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ResponsiveGrid(
      minItemWidth: 100,
      children: [
        StatTile(
          icon: Icons.local_fire_department_rounded,
          label: 'Day streak',
          value: '$streak',
          color: dark ? const Color(0xFFFB923C) : AppColors.streak,
        ),
        StatTile(
          icon: Icons.bolt_rounded,
          label: 'Total XP',
          value: '${level.totalXp}',
          color: dark ? AppColors.warningLight : AppColors.xp,
        ),
        StatTile(
          icon: Icons.trending_up_rounded,
          label: 'Level',
          value: '${level.level}',
        ),
        StatTile(
          icon: Icons.menu_book_rounded,
          label: 'Topics done',
          value: '$lessons',
        ),
        StatTile(
          icon: Icons.track_changes_rounded,
          label: 'Quiz accuracy',
          value: stats.questionsAnswered == 0
              ? '—'
              : '${(stats.accuracy * 100).round()}%',
        ),
        StatTile(
          icon: Icons.record_voice_over_rounded,
          label: 'Interview Qs',
          value: '$interview',
        ),
      ],
    );
  }
}

class _ContinueLearningCard extends ConsumerWidget {
  const _ContinueLearningCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(continueLearningProvider);
    final theme = Theme.of(context);
    return AsyncValueView(
      value: value,
      onRetry: () => ref.invalidate(continueLearningProvider),
      data: (cl) {
        if (cl == null) {
          return const AppCard(
            child: Row(
              children: [
                Icon(Icons.celebration_rounded, size: 32),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'You completed every lesson. Time to ace interviews!',
                  ),
                ),
              ],
            ),
          );
        }
        final l = cl.lesson;
        return AppCard(
          onTap: () => context.push(AppRoutes.lesson(l.track, l.id)),
          semanticLabel: 'Continue ${l.category}: ${l.title}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  TrackBadge(l.track),
                  DifficultyBadge(l.difficulty, lessonStyle: true),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l.category, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Next up: ${l.title}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedProgressBar(
                value: cl.categoryTotal == 0
                    ? 0
                    : cl.categoryDone / cl.categoryTotal,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  Text(
                    '${cl.categoryDone} of ${cl.categoryTotal} lessons completed',
                    style: theme.textTheme.labelMedium,
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.lesson(l.track, l.id)),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Continue'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 340) {
          return const Column(
            children: [
              TrackCard(track: Track.react),
              SizedBox(height: AppSpacing.md),
              TrackCard(track: Track.next),
            ],
          );
        }
        return const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: TrackCard(track: Track.react, compact: true)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: TrackCard(track: Track.next, compact: true)),
            ],
          ),
        );
      },
    );
  }
}

class _DailyChallengeCard extends ConsumerWidget {
  const _DailyChallengeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(dailyChallengeProvider);
    final done = ref.watch(dailyChallengeDoneProvider);
    final theme = Theme.of(context);
    return AsyncValueView(
      value: challenge,
      onRetry: () => ref.invalidate(dailyChallengeProvider),
      data: (c) {
        if (c == null) return const SizedBox.shrink();
        return AppCard(
          onTap: () => context.push(AppRoutes.challenge),
          semanticLabel: 'Daily challenge: ${c.prompt}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: theme.brightness == Brightness.dark
                        ? AppColors.warningLight
                        : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      c.typeLabel,
                      style: theme.textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    done ? 'Completed ✓' : '+30 XP',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: done
                          ? AppColors.success
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                c.prompt,
                style: theme.textTheme.titleMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: done
                    ? OutlinedButton(
                        onPressed: () => context.push(AppRoutes.challenge),
                        child: const Text('Review'),
                      )
                    : FilledButton(
                        onPressed: () => context.push(AppRoutes.challenge),
                        child: const Text('Answer'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InterviewProgressCard extends ConsumerWidget {
  const _InterviewProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(interviewProgressProvider(null)).value;
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => context.go(AppRoutes.interview),
      semanticLabel:
          'Interview preparation: ${summary?.done ?? 0} of ${summary?.total ?? 0} reviewed',
      child: Row(
        children: [
          ProgressRing(
            value: summary?.fraction ?? 0,
            size: 56,
            strokeWidth: 6,
            child: Icon(
              Icons.record_voice_over_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interview prep', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${summary?.done ?? 0} / ${summary?.total ?? 150} questions reviewed'
                  ' · ${summary?.known ?? 0} known',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _QuizStatsCard extends ConsumerWidget {
  const _QuizStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quizStatsProvider);
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => context.go(AppRoutes.quiz),
      semanticLabel: 'Quiz statistics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Quiz stats', style: theme.textTheme.titleMedium),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.stats),
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _MiniStat(label: 'Quizzes', value: '${s.totalQuizzes}'),
              _MiniStat(label: 'Answered', value: '${s.questionsAnswered}'),
              _MiniStat(label: 'Best', value: '${s.bestScorePercent}%'),
              _MiniStat(
                label: 'Average',
                value: '${s.averageScorePercent.round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _RecommendedSection extends ConsumerWidget {
  const _RecommendedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(recommendedLessonProvider).value;
    if (lesson == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Recommended for you'),
        AppCard(
          onTap: () => context.push(AppRoutes.lesson(lesson.track, lesson.id)),
          semanticLabel: 'Recommended: ${lesson.title}',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: theme.textTheme.titleMedium),
                    Text(
                      lesson.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentlyCompletedSection extends ConsumerWidget {
  const _RecentlyCompletedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentlyCompletedProvider).value ?? const [];
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Recently completed'),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++)
                LessonTile(lesson: recent[i], index: i),
            ],
          ),
        ),
      ],
    );
  }
}
