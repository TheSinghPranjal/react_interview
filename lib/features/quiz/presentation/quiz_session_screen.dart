import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/models/quiz_session.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../learn/presentation/widgets/interactive_widgets.dart';
import '../providers/quiz_providers.dart';

/// The active quiz. No ads are shown on this screen.
class QuizSessionScreen extends ConsumerWidget {
  const QuizSessionScreen({super.key});

  Future<bool> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave quiz?'),
        content: const Text(
          'Answers so far still count toward your stats, '
          'but this quiz won\'t be scored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  void _submit(BuildContext context, WidgetRef ref, int index) {
    final outcome = ref.read(quizSessionProvider.notifier).submitAnswer(index);
    if (outcome == null) return;
    final session = ref.read(quizSessionProvider)!;
    final correct = session.isCorrectAt(session.currentIndex);
    SemanticsService.sendAnnouncement(
      View.of(context),
      correct
          ? 'Correct!'
          : 'Not quite. The correct answer is ${session.current.correctOption}',
      Directionality.of(context),
    );
    // Streak / achievement / level news (XP is shown inline on the card).
    if (outcome.newAchievements.isNotEmpty ||
        outcome.newLevel != null ||
        (outcome.streakExtendedTo ?? 0) >= 2) {
      showActivityOutcome(context, outcome);
    }
  }

  Future<void> _next(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(quizSessionProvider.notifier);
    if (notifier.next()) return;
    final finished = notifier.finish();
    if (finished == null || !context.mounted) return;
    context.pushReplacement(AppRoutes.quizResult);
    final outcome = finished.$2;
    if (outcome.newAchievements.isNotEmpty || outcome.newLevel != null) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) await showActivityOutcome(ctx, outcome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(quizSessionProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = session.current;
    final theme = Theme.of(context);
    final answered = session.isCurrentAnswered;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit(context)) {
          ref.read(quizSessionProvider.notifier).abandon();
          if (context.mounted) context.go(AppRoutes.quiz);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Leave quiz',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Semantics(
            label: 'Question ${session.currentIndex + 1} of ${session.total}',
            excludeSemantics: true,
            child: Text(
              'Question ${session.currentIndex + 1} / ${session.total}',
            ),
          ),
          actions: [BookmarkButton(type: BookmarkType.mcq, itemId: q.id)],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AnimatedProgressBar(
                value:
                    (session.currentIndex + (answered ? 1 : 0)) / session.total,
                height: 6,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDurations.medium,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  ),
                  child: _QuestionView(
                    key: ValueKey(session.currentIndex),
                    session: session,
                    onSelect: (i) => _submit(context, ref, i),
                  ),
                ),
              ),
              AnimatedSize(
                duration: AppDurations.fast,
                child: answered
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        child: FilledButton.icon(
                          onPressed: () => _next(context, ref),
                          icon: Icon(
                            session.isLastQuestion
                                ? Icons.flag_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(
                            session.isLastQuestion
                                ? 'See Results'
                                : 'Next Question',
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.session,
    required this.onSelect,
    super.key,
  });

  final QuizSession session;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = session.current;
    final selected = session.currentAnswer;
    final answered = selected != null;
    final correct = answered && selected == q.correctIndex;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TrackBadge(q.source.category),
            DifficultyBadge(q.source.difficulty),
            InfoChip(icon: Icons.sell_outlined, label: q.source.topic),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: InlineRichText(
            q.source.question,
            style: theme.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AnswerOptionButton(
              label: String.fromCharCode(65 + i),
              text: q.options[i],
              state: !answered
                  ? OptionState.idle
                  : i == selected
                  ? (i == q.correctIndex
                        ? OptionState.correct
                        : OptionState.incorrect)
                  : i == q.correctIndex
                  ? OptionState.revealedCorrect
                  : OptionState.dimmed,
              onTap: answered ? null : () => onSelect(i),
            ),
          ),
        AnimatedSize(
          duration: AppDurations.medium,
          child: answered
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: AnswerFeedback(
                    correct: correct,
                    correctAnswer: q.correctOption,
                    explanation: q.source.explanation,
                    xp: correct ? XpRewards.correctMcq : null,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
