import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../shared/widgets/common.dart';
import '../../progress/providers/progress_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(achievementStatusesProvider);
    final unlocked = list.where((a) => a.isUnlocked).length;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Achievements · $unlocked/${list.length}')),
      body: GridView.builder(
        padding: AppSpacing.screen,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: 50 + MediaQuery.textScalerOf(context).scale(170),
        ),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final a = list[i];
          final on = a.isUnlocked;
          return FadeSlideIn(
            index: i,
            child: Semantics(
              label:
                  '${a.achievement.title}. ${a.achievement.description} '
                  '${on ? 'Unlocked' : 'Locked, ${a.current} of ${a.achievement.target}'}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: on ? AppColors.brandGradient : null,
                  color: on ? null : theme.colorScheme.surface,
                  borderRadius: AppRadius.lgAll,
                  border: on
                      ? null
                      : Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          on
                              ? achievementIcon(a.achievement.iconKey)
                              : Icons.lock_outline_rounded,
                          size: 30,
                          color: on ? Colors.white : theme.colorScheme.outline,
                        ),
                        const Spacer(),
                        if (on)
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      a.achievement.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: on ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.achievement.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: on ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (!on) ...[
                      AnimatedProgressBar(value: a.progress, height: 5),
                      const SizedBox(height: 2),
                      Text(
                        '${a.current.clamp(0, a.achievement.target)} / ${a.achievement.target}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ] else
                      Text(
                        'Unlocked',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
