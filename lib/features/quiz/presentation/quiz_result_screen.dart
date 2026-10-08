import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/ad_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../shared/widgets/common.dart';
import '../providers/quiz_providers.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() then,
  ) async {
    // Finishing a quiz is a natural break; the manager decides (with
    // frequency caps) whether an interstitial actually appears.
    await ref.read(interstitialAdManagerProvider).onNaturalBreak();
    if (context.mounted) await then();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(quizResultProvider);
    if (result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final success = dark ? AppColors.successLight : AppColors.success;
    final error = dark ? AppColors.errorLight : AppColors.error;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quiz complete'),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () =>
                _leave(context, ref, () async => context.go(AppRoutes.quiz)),
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Center(
                child: ProgressRing(
                  value: result.accuracy,
                  size: 160,
                  strokeWidth: 14,
                  color: result.percent >= 50 ? success : error,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: result.percent),
                        duration: AppDurations.slow * 2,
                        builder: (context, v, _) =>
                            Text('$v%', style: theme.textTheme.displaySmall),
                      ),
                      Text(
                        '${result.correct} / ${result.total}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                liveRegion: true,
                child: Text(
                  result.headline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Score: ${result.correct} / ${result.total}  ·  ${result.percent}%',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.check_circle_rounded,
                      label: 'Correct',
                      value: '${result.correct}',
                      color: success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      icon: Icons.cancel_rounded,
                      label: 'Incorrect',
                      value: '${result.incorrect}',
                      color: error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      icon: Icons.bolt_rounded,
                      label: 'XP earned',
                      value: '+${result.xpEarned}',
                      color: dark ? AppColors.warningLight : AppColors.xp,
                    ),
                  ),
                ],
              ),
              if (result.isPerfect) ...[
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Perfect quiz bonus: +50 XP included',
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.quizReview),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Review Answers'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _leave(context, ref, () async {
                  ref.read(quizSessionProvider.notifier).retry(result.session);
                  context.pushReplacement(AppRoutes.quizSession);
                }),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Retry Quiz'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => _leave(
                  context,
                  ref,
                  () async => context.go(AppRoutes.quiz),
                ),
                child: const Text('Back to Quiz'),
              ),
            ],
          ),
          if (result.percent >= 80)
            const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}
