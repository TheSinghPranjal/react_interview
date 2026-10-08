import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/common.dart';
import '../providers/progress_provider.dart';

/// Gradient card with level, XP progress and XP earned today.
class LevelCard extends ConsumerWidget {
  const LevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(levelProvider);
    final today = ref.watch(xpTodayProvider);
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      gradient: AppColors.brandGradient,
      semanticLabel:
          'Level ${level.level}, ${level.totalXp} XP. '
          '${level.xpToNextLevel} XP to next level.',
      child: Row(
        children: [
          ProgressRing(
            value: level.progress,
            size: 68,
            color: Colors.white,
            trackColor: Colors.white.withValues(alpha: 0.22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LVL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${level.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.title,
                  style: textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: level.totalXp),
                  duration: AppDurations.slow,
                  builder: (context, v, _) => Text(
                    '$v XP',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AnimatedProgressBar(
                  value: level.progress,
                  height: 6,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${level.xpToNextLevel} XP to level ${level.level + 1}'
                  '  ·  +$today today',
                  style: textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven-day streak calendar (Mon–Sun) with flame header.
class StreakWeekCard extends ConsumerWidget {
  const StreakWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final flame = dark ? const Color(0xFFFB923C) : AppColors.streak;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: AppDurations.slow,
                curve: Curves.elasticOut,
                builder: (context, s, child) =>
                    Transform.scale(scale: s, child: child),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: streak.current > 0
                      ? flame
                      : theme.colorScheme.onSurfaceVariant,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${streak.current}-day streak',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      streak.activeToday
                          ? 'You learned today. Nice work!'
                          : streak.current > 0
                          ? 'Learn something today to keep it going.'
                          : 'Complete any activity to start a streak.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                'Best ${streak.longest}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in streak.week)
                Expanded(
                  child: Semantics(
                    label:
                        '${day.label}: ${day.isActive
                            ? 'active'
                            : day.isFuture
                            ? 'upcoming'
                            : 'no activity'}',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            day.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: day.isToday
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: AppDurations.medium,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: day.isActive ? flame : Colors.transparent,
                            border: Border.all(
                              color: day.isActive
                                  ? flame
                                  : day.isToday
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: day.isToday ? 2 : 1.5,
                            ),
                          ),
                          child: day.isActive
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
