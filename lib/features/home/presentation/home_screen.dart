import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/dashboard.dart';
import '../../interview/providers/interview_providers.dart';
import '../../learn/presentation/widgets/learn_widgets.dart';
import '../../learn/providers/learn_providers.dart';
import '../../progress/providers/progress_provider.dart';
import 'home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const HomeHeader(),
      const HomeLevelCard(),
      const SizedBox(height: AppSpacing.md),
      const HomeStatsGrid(),
      const SizedBox(height: AppSpacing.md),
      const HomeStreakCard(),
      DashSectionHeader(
        'Continue learning',
        onViewAll: () => context.go(AppRoutes.learn),
      ),
      const HomeContinueCard(),
      DashSectionHeader(
        'Your tracks',
        subtitle: 'Choose a track and keep learning.',
        onViewAll: () => context.go(AppRoutes.learn),
      ),
      const HomeTrackRow(),
      const DashSectionHeader(
        'Daily challenge',
        subtitle: 'A new challenge every day to boost your skills.',
        trailing: HomeXpPill(),
      ),
      const HomeDailyChallengeCard(),
      const DashSectionHeader('Practice'),
      const _InterviewProgressCard(),
      const SizedBox(height: AppSpacing.md),
      const _QuizStatsCard(),
      const _RecommendedSection(),
      const _RecentlyCompletedSection(),
      const SizedBox(height: AppSpacing.xl),
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: dark
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFF1F2FE), Color(0xFFF7F8FD)],
                  begin: Alignment.topCenter,
                  end: Alignment(0, -0.2),
                ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView.builder(
            padding: AppSpacing.screen,
            itemCount: children.length,
            itemBuilder: (context, i) =>
                FadeSlideIn(index: i, child: children[i]),
          ),
        ),
      ),
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
        const DashSectionHeader('Recommended for you'),
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
        const DashSectionHeader('Recently completed'),
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
