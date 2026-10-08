import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/bookmark.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../learn/presentation/widgets/interactive_widgets.dart';
import '../providers/quiz_providers.dart';

class QuizReviewScreen extends ConsumerWidget {
  const QuizReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(quizResultProvider);
    if (result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = result.session;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Review · ${result.correct}/${result.total}')),
      body: ListView.builder(
        padding: AppSpacing.screen,
        itemCount: session.total,
        itemBuilder: (context, i) {
          final q = session.questions[i];
          final selected = session.answers[i];
          final correct = selected == q.correctIndex;
          final color = correct
              ? (dark ? AppColors.successLight : AppColors.success)
              : (dark ? AppColors.errorLight : AppColors.error);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: color,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Question ${i + 1} · ${correct ? 'Correct' : 'Incorrect'}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                      DifficultyBadge(q.source.difficulty),
                      BookmarkButton(type: BookmarkType.mcq, itemId: q.id),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InlineRichText(
                    q.source.question,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (var o = 0; o < q.options.length; o++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AnswerOptionButton(
                        label: String.fromCharCode(65 + o),
                        text: q.options[o],
                        state: o == selected
                            ? (o == q.correctIndex
                                  ? OptionState.correct
                                  : OptionState.incorrect)
                            : o == q.correctIndex
                            ? OptionState.revealedCorrect
                            : OptionState.dimmed,
                      ),
                    ),
                  if (q.source.explanation.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    RichContent(
                      q.source.explanation,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
