import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/lesson.dart';
import '../../providers/learn_providers.dart';

class LessonTile extends ConsumerWidget {
  const LessonTile({required this.lesson, this.index, super.key});

  final Lesson lesson;
  final int? index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(isLessonCompletedProvider(lesson.id));
    final theme = Theme.of(context);
    return Semantics(
      label:
          '${lesson.title}. ${lesson.difficulty.lessonLabel}. '
          '${lesson.estimatedMinutes} minutes. ${done ? 'Completed' : 'Not completed'}',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () => context.push(AppRoutes.lesson(lesson.track, lesson.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppDurations.medium,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.success
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : Text(
                        '${(index ?? 0) + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${lesson.difficulty.lessonLabel} · '
                      '${lesson.estimatedMinutes} min',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
