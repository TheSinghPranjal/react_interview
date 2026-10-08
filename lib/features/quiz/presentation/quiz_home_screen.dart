import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/ad_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/providers/core_providers.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../shared/widgets/common.dart';
import '../../progress/providers/progress_provider.dart';
import '../domain/quiz_generator.dart';
import '../providers/quiz_providers.dart';

class QuizHomeScreen extends ConsumerStatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  ConsumerState<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends ConsumerState<QuizHomeScreen> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await ref
          .read(quizSessionProvider.notifier)
          .start(ref.read(quizConfigProvider));
      if (mounted) await context.push(AppRoutes.quizSession);
    } on QuizGenerationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load quiz questions. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(quizConfigProvider);
    final available = ref.watch(availableQuizQuestionsProvider);
    final notifier = ref.read(quizConfigProvider.notifier);
    final theme = Theme.of(context);
    final count = available.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          IconButton(
            tooltip: 'Statistics',
            onPressed: () => context.push(AppRoutes.stats),
            icon: const Icon(Icons.insights_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const FadeSlideIn(child: _QuizSummaryCard()),
          const SectionHeader('Build your quiz'),
          Text('Number of questions', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final n in QuizDefaults.questionCountOptions)
                ChoiceChip(
                  label: Text('$n'),
                  selected: config.questionCount == n,
                  onSelected: (_) => notifier.setCount(n),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Topic', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<Track?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(value: Track.react, label: Text('React')),
              ButtonSegment(value: Track.next, label: Text('Next.js')),
            ],
            selected: {config.category},
            onSelectionChanged: (s) => notifier.setCategory(s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Difficulty', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<Difficulty?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
              ButtonSegment(value: Difficulty.medium, label: Text('Medium')),
              ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
            ],
            selected: {config.difficulty},
            onSelectionChanged: (s) => notifier.setDifficulty(s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            count == null
                ? 'Counting questions…'
                : count < config.questionCount
                ? '$count questions match — your quiz will use all of them.'
                : '$count questions match. Questions and answers are shuffled every time.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _starting || count == 0 ? null : _start,
            icon: _starting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(
              'Start ${count == null ? config.questionCount : (count < config.questionCount ? count : config.questionCount)}-question quiz',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _RewardedXpCard(),
          const _RecentHistory(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _QuizSummaryCard extends ConsumerWidget {
  const _QuizSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quizStatsProvider);
    final theme = Theme.of(context);
    return AppCard(
      gradient: AppColors.brandGradient,
      child: Row(
        children: [
          ProgressRing(
            value: s.accuracy,
            size: 72,
            color: Colors.white,
            trackColor: Colors.white.withValues(alpha: 0.22),
            child: Text(
              s.questionsAnswered == 0 ? '—' : '${(s.accuracy * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test your knowledge',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.totalQuizzes} quizzes · ${s.correctAnswers}/${s.questionsAnswered} correct'
                  '\nBest score ${s.bestScorePercent}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional rewarded ad: only shown when an ad is ready, the user is not
/// premium, and the daily cap has not been reached. Always user-initiated.
class _RewardedXpCard extends ConsumerWidget {
  const _RewardedXpCard();

  Future<void> _watch(BuildContext context, WidgetRef ref) async {
    final earned = await ref.read(rewardedAdProvider.notifier).show();
    if (!context.mounted) return;
    if (earned) {
      final outcome = ref.read(progressProvider.notifier).claimRewardedXp();
      await showActivityOutcome(context, outcome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reward this time. Try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(rewardedAdProvider);
    final todayKey = AppDates.dayKey(ref.watch(clockProvider)());
    final claims = ref.watch(
      progressProvider.select((p) => p.rewardedClaimsByDay[todayKey] ?? 0),
    );
    if (status != RewardedAdStatus.ready ||
        claims >= XpRewards.maxRewardedClaimsPerDay) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.card_giftcard_rounded, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Watch a short ad to earn +${XpRewards.rewardedAd} XP',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => _watch(context, ref),
            child: const Text('Watch'),
          ),
        ],
      ),
    );
  }
}

class _RecentHistory extends ConsumerWidget {
  const _RecentHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(quizStatsProvider.select((s) => s.history));
    if (history.isEmpty) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Recent quizzes',
          action: 'All stats',
          onAction: () => context.push(AppRoutes.stats),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (final h in history.take(5))
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: Text(
                      '${h.percent}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text('${h.correct} / ${h.total} correct'),
                  subtitle: Text(
                    '${h.label} · ${AppDates.relative(h.completedAt, now)}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
