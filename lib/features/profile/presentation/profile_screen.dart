import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../shared/widgets/common.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import '../../progress/presentation/progress_widgets.dart';
import '../../progress/providers/progress_provider.dart';
import '../../settings/providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).userName,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Shown only on this device',
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) ref.read(settingsProvider.notifier).setUserName(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(settingsProvider.select((s) => s.userName));
    final level = ref.watch(levelProvider);
    final progress = ref.watch(progressProvider);
    final streak = ref.watch(streakProvider);
    final bookmarks = ref.watch(bookmarksProvider).length;
    final achievements = ref.watch(achievementStatusesProvider);
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final stats = progress.quizStats;
    final theme = Theme.of(context);
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.headlineSmall),
                    Text(
                      'Level ${level.level} · ${level.title}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit name',
                onPressed: () => _editName(context, ref),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const LevelCard(),
          const SizedBox(height: AppSpacing.md),
          const StreakWeekCard(),
          const SizedBox(height: AppSpacing.md),
          ResponsiveGrid(
            minItemWidth: 100,
            children: [
              StatTile(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '${streak.current}',
              ),
              StatTile(
                icon: Icons.menu_book_rounded,
                label: 'Topics completed',
                value: '${progress.lessonsCompleted}',
              ),
              StatTile(
                icon: Icons.record_voice_over_rounded,
                label: 'Interview done',
                value: '${progress.interviewCompleted}',
              ),
              StatTile(
                icon: Icons.quiz_rounded,
                label: 'Quiz questions',
                value: '${stats.questionsAnswered}',
              ),
              StatTile(
                icon: Icons.track_changes_rounded,
                label: 'Accuracy',
                value: stats.questionsAnswered == 0
                    ? '—'
                    : '${(stats.accuracy * 100).round()}%',
              ),
              StatTile(
                icon: Icons.bookmark_rounded,
                label: 'Bookmarks',
                value: '$bookmarks',
              ),
            ],
          ),
          SectionHeader(
            'Achievements · $unlocked/${achievements.length}',
            action: 'See all',
            onAction: () => context.push(AppRoutes.achievements),
          ),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(40) + 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final a = achievements[i];
                return Semantics(
                  label:
                      '${a.achievement.title}, ${a.isUnlocked ? 'unlocked' : 'locked'}',
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: a.isUnlocked
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                )
                              : theme.colorScheme.surfaceContainer,
                          child: Icon(
                            a.isUnlocked
                                ? achievementIcon(a.achievement.iconKey)
                                : Icons.lock_outline_rounded,
                            color: a.isUnlocked
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.achievement.title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SectionHeader('More'),
          const AppCard(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                _Link(
                  icon: Icons.bookmarks_outlined,
                  title: 'Bookmarks',
                  route: AppRoutes.bookmarks,
                ),
                _Link(
                  icon: Icons.insights_rounded,
                  title: 'Statistics',
                  route: AppRoutes.stats,
                ),
                _Link(
                  icon: Icons.military_tech_outlined,
                  title: 'Achievements',
                  route: AppRoutes.achievements,
                ),
                _Link(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Dark mode, notifications, privacy',
                  route: AppRoutes.settings,
                ),
                _Link(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy',
                  route: AppRoutes.privacy,
                ),
                _Link(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  route: AppRoutes.about,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({
    required this.icon,
    required this.title,
    required this.route,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(route),
    );
  }
}
