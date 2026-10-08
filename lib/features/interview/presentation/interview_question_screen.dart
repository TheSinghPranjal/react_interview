import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/ad_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/models/interview_question.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../shared/widgets/code_block.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../learn/presentation/widgets/interactive_widgets.dart';
import '../providers/interview_providers.dart';
import 'interview_widgets.dart';

class InterviewQuestionScreen extends ConsumerStatefulWidget {
  const InterviewQuestionScreen({required this.questionId, super.key});
  final String questionId;

  @override
  ConsumerState<InterviewQuestionScreen> createState() =>
      _InterviewQuestionScreenState();
}

class _InterviewQuestionScreenState
    extends ConsumerState<InterviewQuestionScreen> {
  bool _revealed = false;

  @override
  void didUpdateWidget(InterviewQuestionScreen old) {
    super.didUpdateWidget(old);
    if (old.questionId != widget.questionId) _revealed = false;
  }

  void _ensureSession(InterviewQuestion q, List<InterviewQuestion> all) {
    final session = ref.read(interviewSessionProvider);
    if (session?.contains(q.id) ?? false) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(interviewSessionProvider.notifier).ensureContains(q, all);
      }
    });
  }

  Future<void> _mark(InterviewQuestion q, {required bool known}) async {
    final notifier = ref.read(interviewSessionProvider.notifier);
    final outcome = notifier.review(q.id, known: known);
    await showActivityOutcome(context, outcome);
    if (!mounted) return;

    final session = ref.read(interviewSessionProvider);
    final nextId = session?.nextAfter(q.id);
    if (nextId != null) {
      context.pushReplacement(AppRoutes.interviewQuestion(nextId));
      return;
    }
    await _finishSet(session);
  }

  Future<void> _finishSet(InterviewSession? session) async {
    final reviewed = session?.reviewedIds.length ?? 1;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events_rounded, size: 40),
        title: const Text('Set complete!'),
        content: Text(
          'You reviewed $reviewed question${reviewed == 1 ? '' : 's'} '
          'in "${session?.title ?? 'this set'}". Questions marked '
          '"Need Practice" stay highlighted so you can revisit them.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    ref.read(interviewSessionProvider.notifier).end();
    // Natural break: an interstitial may be shown (frequency-capped).
    await ref.read(interstitialAdManagerProvider).onNaturalBreak();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final questionAsync = ref.watch(
      interviewQuestionByIdProvider(widget.questionId),
    );
    final all = ref.watch(interviewQuestionsProvider).value ?? const [];
    final session = ref.watch(interviewSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.title ?? 'Interview question'),
        actions: [
          BookmarkButton(
            type: BookmarkType.interview,
            itemId: widget.questionId,
          ),
        ],
      ),
      body: AsyncValueView(
        value: questionAsync,
        onRetry: () => ref.invalidate(interviewQuestionsProvider),
        data: (q) {
          if (q == null) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Question not found',
              message: 'It may have been removed in an update.',
              action: FilledButton(
                onPressed: () => context.go(AppRoutes.interview),
                child: const Text('Back to interview'),
              ),
            );
          }
          _ensureSession(q, all);
          final inSession = session?.contains(q.id) ?? false;
          final number = inSession ? session!.indexOf(q.id) + 1 : null;
          final total = inSession ? session!.length : null;
          return Column(
            children: [
              if (total != null)
                AnimatedProgressBar(
                  value: number! / total,
                  height: 4,
                  semanticsLabel: 'Question $number of $total',
                ),
              Expanded(
                child: _QuestionBody(
                  question: q,
                  number: number,
                  total: total,
                  revealed: _revealed,
                ),
              ),
              _ActionBar(
                revealed: _revealed,
                onReveal: () => setState(() => _revealed = true),
                onKnown: () => _mark(q, known: true),
                onPractice: () => _mark(q, known: false),
                questionId: q.id,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({
    required this.question,
    required this.revealed,
    this.number,
    this.total,
  });

  final InterviewQuestion question;
  final bool revealed;
  final int? number;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = question;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (number != null)
              Text(
                'Question $number of $total',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            DifficultyBadge(q.difficulty),
            TrackBadge(q.category),
            InfoChip(icon: Icons.sell_outlined, label: q.topic),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: InlineRichText(
            q.question,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: AppDurations.medium,
          child: revealed
              ? _Answer(question: q)
              : Container(
                  key: const ValueKey('think'),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Think about your answer',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Say it out loud as if you were in the interview, '
                              'then reveal the model answer.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.question});
  final InterviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = question;
    return Column(
      key: const ValueKey('answer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Callout(
          icon: Icons.short_text_rounded,
          title: 'Short answer',
          color: AppColors.indigo,
          child: RichContent(q.shortAnswer, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Detailed explanation', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        RichContent(q.detailedAnswer),
        if (q.code != null) ...[
          const SizedBox(height: AppSpacing.md),
          CodeBlock(code: q.code!),
        ],
        if (q.keyPoints.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Key points', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final p in q.keyPoints)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: InlineRichText(p, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
        if (q.commonMistake.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Callout(
            icon: Icons.warning_amber_rounded,
            title: 'Common mistake',
            color: AppColors.warning,
            child: RichContent(
              q.commonMistake,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
        if (q.interviewTip.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Callout(
            icon: Icons.tips_and_updates_rounded,
            title: 'Interview tip',
            color: AppColors.purple,
            child: RichContent(
              q.interviewTip,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.revealed,
    required this.onReveal,
    required this.onKnown,
    required this.onPractice,
    required this.questionId,
  });

  final bool revealed;
  final VoidCallback onReveal;
  final VoidCallback onKnown;
  final VoidCallback onPractice;
  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(interviewStatusProvider(questionId));
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          child: !revealed
              ? SizedBox(
                  key: const ValueKey('reveal'),
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onReveal,
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Show Answer'),
                  ),
                )
              : Row(
                  key: const ValueKey('grade'),
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPractice,
                        icon: Icon(
                          status == InterviewStatus.practice
                              ? Icons.replay_circle_filled_rounded
                              : Icons.replay_rounded,
                        ),
                        label: const Text('Need Practice'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onKnown,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('I Know This'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
