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
import '../../../shared/widgets/dashboard.dart';
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
    final count = available.value;
    final dark = isDarkTheme(context);
    final quizSize = count == null || count >= config.questionCount
        ? config.questionCount
        : count;

    final children = <Widget>[
      DashHero(
        badge: ScreenBadge(
          icon: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: dark ? AppColors.indigoLight : const Color(0xFF3730D8),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          label: 'Quiz',
        ),
        action: SquareIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Statistics',
          onPressed: () => context.push(AppRoutes.stats),
        ),
        semanticTitle: 'Test your knowledge',
        title: [
          const TextSpan(text: 'Test your '),
          TextSpan(
            text: 'knowledge',
            style: TextStyle(
              color: dark ? AppColors.indigoLight : const Color(0xFF3B3FE0),
            ),
          ),
        ],
        subtitle:
            'Practice MCQs, strengthen your concepts and track your progress.',
        art: 'assets/images/quiz_hero.png',
        artWidth: 145,
        artTop: 22,
        titleWidthFactor: 0.62,
        subtitleWidthFactor: 0.58,
      ),
      const SizedBox(height: AppSpacing.lg),
      const _QuizSummaryCard(),
      const DashSectionHeader(
        'Build your quiz',
        subtitle: 'Customize your quiz and start practicing.',
      ),
      _OptionCard(
        icon: Icons.article_outlined,
        color: const Color(0xFF2563EB),
        title: 'Number of questions',
        subtitle: 'Choose how many questions you want to attempt.',
        child: LayoutBuilder(
          builder: (context, c) {
            const gap = 8.0;
            final options = QuizDefaults.questionCountOptions;
            final narrow =
                c.maxWidth < 260 * MediaQuery.textScalerOf(context).scale(1);
            final w = narrow
                ? null
                : (c.maxWidth - gap * (options.length - 1) - 30) /
                      options.length;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final n in options)
                  SizedBox(
                    width: w == null
                        ? null
                        : (config.questionCount == n ? w + 30 : w),
                    child: ChoicePill(
                      label: '$n',
                      expand: w != null,
                      selected: config.questionCount == n,
                      onTap: () => notifier.setCount(n),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _OptionCard(
        icon: Icons.layers_rounded,
        color: const Color(0xFF6D3AED),
        title: 'Topic',
        subtitle: 'Select the technology or focus area.',
        child: _PillRow(
          flex: const [4, 5, 5],
          children: [
            ChoicePill(
              label: 'All',
              expand: true,
              selected: config.category == null,
              onTap: () => notifier.setCategory(null),
            ),
            ChoicePill(
              label: 'React',
              expand: true,
              leading: const ReactLogo(size: 22, color: Color(0xFF0EA5E9)),
              selected: config.category == Track.react,
              onTap: () => notifier.setCategory(Track.react),
            ),
            ChoicePill(
              label: 'Next.js',
              expand: true,
              leading: const NextLogo(size: 24),
              selected: config.category == Track.next,
              onTap: () => notifier.setCategory(Track.next),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _OptionCard(
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFFEA7A0B),
        title: 'Difficulty',
        subtitle: 'Choose the difficulty level.',
        child: _PillRow(
          flex: const [5, 6, 8, 6],
          minPill: 70,
          children: [
            ChoicePill(
              label: 'All',
              expand: true,
              selected: config.difficulty == null,
              onTap: () => notifier.setDifficulty(null),
            ),
            for (final d in Difficulty.values)
              ChoicePill(
                label: d.label,
                expand: true,
                labelColor: DashColors.difficulty(d, dark: dark),
                leading: SignalBars(
                  color: DashColors.difficulty(d, dark: dark),
                  filled: d.index + 1,
                  size: 16,
                ),
                selected: config.difficulty == d,
                onTap: () => notifier.setDifficulty(d),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _MatchInfo(count: count, requested: config.questionCount),
      const SizedBox(height: AppSpacing.md),
      GradientButton(
        label: 'Start $quizSize-question quiz',
        height: 52,
        spreadArrow: true,
        leading: _starting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow_rounded, color: Colors.white),
        onPressed: _starting || count == 0 ? null : _start,
      ),
      const SizedBox(height: AppSpacing.lg),
      const _FeatureRow(),
      const SizedBox(height: AppSpacing.lg),
      const _RewardedXpCard(),
      const _RecentHistory(),
      const SizedBox(height: AppSpacing.xl),
    ];

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
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

class _QuizSummaryCard extends ConsumerWidget {
  const _QuizSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quizStatsProvider);
    return TapCard(
      onTap: () => context.push(AppRoutes.stats),
      gradient: const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF6D4BF0), Color(0xFF9A6CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadows: [
        BoxShadow(
          color: const Color(0xFF5B4BEA).withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      semanticLabel:
          'Your quiz progress: ${s.totalQuizzes} quizzes, '
          '${s.correctAnswers} of ${s.questionsAnswered} correct, '
          'best score ${s.bestScorePercent}%',
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.emoji_events_rounded,
                size: 76,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Row(
              children: [
                ProgressRing(
                  value: s.accuracy,
                  size: 76,
                  strokeWidth: 7,
                  color: const Color(0xFF7DD3FC),
                  trackColor: const Color(0xFF7DD3FC).withValues(alpha: 0.35),
                  child: Text(
                    s.questionsAnswered == 0
                        ? '–'
                        : '${(s.accuracy * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Quiz Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${s.totalQuizzes} quizzes  •  '
                        '${s.correctAnswers}/${s.questionsAnswered} correct',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14.5,
                        ),
                      ),
                      Text(
                        'Best score ${s.bestScorePercent}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14.5,
                        ),
                      ),
                    ],
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

/// White card with an icon disc, title, hint and a row of options.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TapCard(
      radius: AppRadius.xlAll,
      borderColor: scheme.outlineVariant.withValues(
        alpha: isDarkTheme(context) ? 1 : 0.6,
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconDisc(icon: icon, color: color, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Lays pills out in one row with the given flex weights when there is
/// room (about [minPill] per pill), otherwise wraps them.
class _PillRow extends StatelessWidget {
  const _PillRow({
    required this.children,
    required this.flex,
    this.minPill = 76,
  });

  final List<Widget> children;
  final List<int> flex;
  final double minPill;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, c) {
        final fits = c.maxWidth / children.length >= minPill * scale;
        if (!fits) {
          return Wrap(spacing: gap, runSpacing: gap, children: children);
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(flex: flex[i], child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class _MatchInfo extends StatelessWidget {
  const _MatchInfo({required this.count, required this.requested});
  final int? count;
  final int requested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    final c = count;
    final headline = c == null
        ? 'Counting questions…'
        : '$c questions match your selection.';
    final detail = c != null && c < requested
        ? 'Your quiz will use all of them.'
        : 'Questions and answers are shuffled every time.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainer : const Color(0xFFF0F4FE),
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: dark ? scheme.outlineVariant : const Color(0xFFDDE6FA),
        ),
      ),
      child: Row(
        children: [
          const IconDisc(
            icon: Icons.shuffle_rounded,
            color: Color(0xFF2563EB),
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

/// Four small "why practice here" tiles.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.emoji_events_rounded,
        Color(0xFF16A34A),
        'Track\nProgress',
        'See detailed results',
      ),
      (
        Icons.track_changes_rounded,
        Color(0xFFE11D48),
        'Detailed\nExplanations',
        'Learn from mistakes',
      ),
      (
        Icons.psychology_rounded,
        Color(0xFF2563EB),
        'Multiple\nTopics',
        'React, Next.js and more',
      ),
      (
        Icons.bolt_rounded,
        Color(0xFFF59E0B),
        'Build\nConfidence',
        'Get interview ready',
      ),
    ];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final columns = c.maxWidth < 340 ? 2 : 4;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (icon, color, title, sub) in items)
              Container(
                width: w,
                constraints: const BoxConstraints(minHeight: 132),
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                decoration: BoxDecoration(
                  color: isDarkTheme(context)
                      ? scheme.surface
                      : Color.lerp(Colors.white, color, 0.04),
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: [
                    IconDisc(icon: icon, color: color, size: 40),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
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
