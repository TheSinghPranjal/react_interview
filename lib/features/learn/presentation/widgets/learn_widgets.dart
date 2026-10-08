import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/lesson.dart';
import '../../../../shared/widgets/common.dart';
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

/// Large gradient card for a learning track with progress.
class TrackCard extends ConsumerWidget {
  const TrackCard({required this.track, this.compact = false, super.key});

  final Track track;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(trackProgressProvider(track)).value;
    final isReact = track == Track.react;
    final title = isReact ? 'React' : 'Next.js';
    final subtitle = isReact
        ? 'Master modern React'
        : 'Build production-ready applications';
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      gradient: isReact ? AppColors.reactGradient : AppColors.nextGradient,
      onTap: () => context.go(AppRoutes.track(track)),
      semanticLabel:
          '$title track. $subtitle. '
          '${progress?.done ?? 0} of ${progress?.total ?? 0} lessons completed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  isReact ? Icons.blur_circular_rounded : Icons.layers_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (progress != null)
                Text(
                  '${(progress.fraction * 100).round()}%',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: Colors.white),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedProgressBar(
            value: progress?.fraction ?? 0,
            height: 6,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${progress?.done ?? 0} / ${progress?.total ?? 0} lessons',
            style: textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
