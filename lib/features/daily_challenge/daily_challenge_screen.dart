import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/daily_challenge.dart';
import '../../shared/widgets/celebration.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/rich_content.dart';
import '../learn/presentation/widgets/interactive_widgets.dart';
import '../progress/providers/progress_provider.dart';
import 'daily_challenge_providers.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  int? _selected;
  bool _revealed = false;
  bool _celebrate = false;

  Future<void> _complete() async {
    final outcome = ref
        .read(progressProvider.notifier)
        .completeDailyChallenge();
    if (outcome.hasNews) setState(() => _celebrate = true);
    await showActivityOutcome(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final challenge = ref.watch(dailyChallengeProvider);
    final done = ref.watch(dailyChallengeDoneProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily challenge')),
      body: AsyncValueView(
        value: challenge,
        onRetry: () => ref.invalidate(dailyChallengeProvider),
        data: (c) {
          if (c == null) {
            return const EmptyState(
              icon: Icons.event_busy_rounded,
              title: 'No challenge today',
              message: 'Content is unavailable right now.',
            );
          }
          return Stack(
            children: [
              ListView(
                padding: AppSpacing.screen,
                children: [
                  _Banner(challenge: c, done: done),
                  const SizedBox(height: AppSpacing.lg),
                  InlineRichText(
                    c.prompt,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ..._body(context, c, done),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
              if (_celebrate) const Positioned.fill(child: ConfettiBurst()),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, DailyChallenge c, bool done) {
    final theme = Theme.of(context);
    switch (c.type) {
      case DailyChallengeType.mcq:
        final q = c.mcq!;
        final answered = _selected != null;
        return [
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AnswerOptionButton(
                label: String.fromCharCode(65 + i),
                text: q.options[i],
                state: !answered
                    ? OptionState.idle
                    : i == _selected
                    ? (i == q.correctAnswer
                          ? OptionState.correct
                          : OptionState.incorrect)
                    : i == q.correctAnswer
                    ? OptionState.revealedCorrect
                    : OptionState.dimmed,
                onTap: answered
                    ? null
                    : () {
                        setState(() => _selected = i);
                        if (!done) _complete();
                      },
              ),
            ),
          if (answered)
            AnswerFeedback(
              correct: _selected == q.correctAnswer,
              correctAnswer: q.correctOption,
              explanation: q.explanation,
            ),
        ];
      case DailyChallengeType.interview:
      case DailyChallengeType.lesson:
        final answer = c.type == DailyChallengeType.interview
            ? '${c.interview!.shortAnswer}\n\n${c.interview!.detailedAnswer}'
            : c.lesson!.interviewQuestion?.answer ?? c.lesson!.description;
        return [
          Text(
            'Explain your answer out loud or write it down, then compare it '
            'with the model answer.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!_revealed)
            FilledButton.icon(
              onPressed: () => setState(() => _revealed = true),
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Show model answer'),
            )
          else ...[
            Callout(
              icon: Icons.lightbulb_rounded,
              title: 'Model answer',
              color: AppColors.indigo,
              child: RichContent(answer, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!done)
              FilledButton.icon(
                onPressed: _complete,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'I answered it  ·  +${XpRewards.dailyChallenge} XP',
                ),
              ),
            if (c.type == DailyChallengeType.lesson) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.push(
                  AppRoutes.lesson(c.lesson!.track, c.lesson!.id),
                ),
                child: Text('Open lesson: ${c.lesson!.title}'),
              ),
            ],
          ],
        ];
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.challenge, required this.done});
  final DailyChallenge challenge;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      gradient: AppColors.brandGradient,
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.typeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  done
                      ? 'Completed today ✓ · New challenge tomorrow'
                      : '${challenge.topic} · +${XpRewards.dailyChallenge} XP',
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
