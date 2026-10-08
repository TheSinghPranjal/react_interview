import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/interview_question.dart';
import '../../progress/providers/progress_provider.dart';

enum InterviewStatus { notStarted, known, practice }

final interviewStatusProvider = Provider.family<InterviewStatus, String>((
  ref,
  id,
) {
  return ref.watch(
    progressProvider.select(
      (p) => p.interviewKnown.contains(id)
          ? InterviewStatus.known
          : p.interviewPractice.contains(id)
          ? InterviewStatus.practice
          : InterviewStatus.notStarted,
    ),
  );
});

class InterviewQuestionTile extends ConsumerWidget {
  const InterviewQuestionTile({
    required this.question,
    required this.number,
    required this.onTap,
    super.key,
  });

  final InterviewQuestion question;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(interviewStatusProvider(question.id));
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final (IconData icon, Color color, String label) = switch (status) {
      InterviewStatus.known => (
        Icons.check_circle_rounded,
        dark ? AppColors.successLight : AppColors.success,
        'Known',
      ),
      InterviewStatus.practice => (
        Icons.replay_circle_filled_rounded,
        dark ? AppColors.warningLight : AppColors.warning,
        'Needs practice',
      ),
      InterviewStatus.notStarted => (
        Icons.circle_outlined,
        theme.colorScheme.outline,
        'Not reviewed',
      ),
    };
    return Semantics(
      button: true,
      label: 'Question $number: ${question.question}. $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.question,
                      style: theme.textTheme.titleSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#$number · ${question.category.label} · '
                      '${question.difficulty.label} · ${question.topic}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
