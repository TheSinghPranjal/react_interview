import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/dashboard.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import '../../home/presentation/home_widgets.dart';
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
    final progress = ref.watch(progressProvider);
    final streak = ref.watch(streakProvider);
    final bookmarks = ref.watch(bookmarksProvider).length;
    final stats = progress.quizStats;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final children = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Profile',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track your progress and keep learning!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          _CircleAction(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(width: 10),
          _CircleAction(
            icon: Icons.bookmarks_outlined,
            tooltip: 'Bookmarks',
            onPressed: () => context.push(AppRoutes.bookmarks),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _Identity(onEdit: () => _editName(context, ref)),
      const SizedBox(height: AppSpacing.md),
      const HomeLevelCard(showNextLevel: true),
      const SizedBox(height: AppSpacing.md),
      const HomeStreakCard(plain: true),
      const SizedBox(height: AppSpacing.md),
      _StatGrid(
        tiles: [
          _ProfileStat(
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFF4511E),
            label: 'Streak',
            value: '${streak.current}',
            route: AppRoutes.stats,
          ),
          _ProfileStat(
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF2563EB),
            label: 'Topics completed',
            value: '${progress.lessonsCompleted}',
            route: AppRoutes.learn,
            goBranch: true,
          ),
          _ProfileStat(
            icon: Icons.groups_rounded,
            color: const Color(0xFF6D3AED),
            label: 'Interview done',
            value: '${progress.interviewCompleted}',
            route: AppRoutes.interview,
            goBranch: true,
          ),
          _ProfileStat(
            icon: Icons.quiz_rounded,
            color: const Color(0xFF16A34A),
            label: 'Quiz questions',
            value: '${stats.questionsAnswered}',
            route: AppRoutes.stats,
          ),
          _ProfileStat(
            icon: Icons.track_changes_rounded,
            color: const Color(0xFFE11D48),
            label: 'Accuracy',
            value: stats.questionsAnswered == 0
                ? '—'
                : '${(stats.accuracy * 100).round()}%',
            route: AppRoutes.stats,
          ),
          _ProfileStat(
            icon: Icons.bookmark_rounded,
            color: const Color(0xFFF59E0B),
            label: 'Bookmarks',
            value: '$bookmarks',
            route: AppRoutes.bookmarks,
          ),
        ],
      ),
      const _AchievementsStrip(),
      const DashSectionHeader('More'),
      TapCard(
        radius: AppRadius.xlAll,
        borderColor: scheme.outlineVariant.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: const Column(
          children: [
            _Link(
              icon: Icons.insights_rounded,
              color: Color(0xFF2563EB),
              title: 'Statistics',
              route: AppRoutes.stats,
            ),
            _Link(
              icon: Icons.military_tech_outlined,
              color: Color(0xFFF59E0B),
              title: 'Achievements',
              route: AppRoutes.achievements,
            ),
            _Link(
              icon: Icons.settings_outlined,
              color: Color(0xFF6D3AED),
              title: 'Settings',
              subtitle: 'Dark mode, notifications, privacy',
              route: AppRoutes.settings,
            ),
            _Link(
              icon: Icons.info_outline_rounded,
              color: Color(0xFF0EA5E9),
              title: 'About',
              route: AppRoutes.about,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          padding: AppSpacing.screen,
          itemCount: children.length,
          itemBuilder: (context, i) =>
              FadeSlideIn(index: i, child: children[i]),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: DashColors.softShadow(context),
        ),
        child: Material(
          color: scheme.surface,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: 48,
              child: Icon(icon, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar with edit badge, name, level and a nudge pill beside artwork.
class _Identity extends ConsumerWidget {
  const _Identity({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(settingsProvider.select((s) => s.userName));
    final level = ref.watch(levelProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          right: -AppSpacing.lg,
          top: -14,
          width: 138,
          child: ExcludeSemantics(
            child: Image(image: AssetImage('assets/images/profile_hero.png')),
          ),
        ),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Edit name',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onEdit,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: DashColors.button,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFA5B4FC),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF5B4BEA,
                            ).withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: DashColors.softShadow(context),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'Level ${level.level} · ${level.title}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? scheme.surfaceContainer
                            : const Color(0xFFFFF1D6),
                        borderRadius: AppRadius.pillAll,
                      ),
                      child: Text(
                        '👑  Keep learning to level up!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileStat {
  const _ProfileStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.route,
    this.goBranch = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String route;

  /// Switch tabs instead of pushing a page.
  final bool goBranch;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.tiles});
  final List<_ProfileStat> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final columns = c.maxWidth < 300 ? 2 : 3;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles)
              SizedBox(
                width: w,
                child: TapCard(
                  onTap: () =>
                      t.goBranch ? context.go(t.route) : context.push(t.route),
                  radius: AppRadius.lgAll,
                  shadows: const [],
                  color: dark
                      ? scheme.surface
                      : Color.lerp(Colors.white, t.color, 0.05),
                  borderColor: dark
                      ? scheme.outlineVariant
                      : t.color.withValues(alpha: 0.16),
                  padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                  semanticLabel: '${t.label}: ${t.value}',
                  child: ExcludeSemantics(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: 0,
                          bottom: -8,
                          child: Icon(
                            t.icon,
                            size: 56,
                            color: t.color.withValues(alpha: 0.09),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: t.color,
                                    borderRadius: AppRadius.smAll,
                                  ),
                                  child: Icon(
                                    t.icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: scheme.onSurfaceVariant,
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              t.value,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                t.label,
                                maxLines: 1,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Color _achievementColor(String key) => switch (key) {
  'quiz' || 'check' => const Color(0xFF2563EB),
  'lesson' || 'book' || 'school' => const Color(0xFF16A34A),
  'fire' || 'calendar' => const Color(0xFFF4511E),
  'trophy' || 'star' || 'badge' => const Color(0xFFF59E0B),
  'interview' => const Color(0xFF6D3AED),
  _ => const Color(0xFF4F46E5),
};

class _AchievementsStrip extends ConsumerWidget {
  const _AchievementsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementStatusesProvider);
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashSectionHeader(
          'Achievements · $unlocked/${achievements.length}',
          onViewAll: () => context.push(AppRoutes.achievements),
          viewAllLabel: 'See all',
        ),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(66) + 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: achievements.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = achievements[i];
              final color = _achievementColor(a.achievement.iconKey);
              return SizedBox(
                width: 122,
                child: TapCard(
                  onTap: () => context.push(AppRoutes.achievements),
                  radius: AppRadius.lgAll,
                  shadows: const [],
                  color: dark
                      ? scheme.surface
                      : Color.lerp(Colors.white, color, 0.05),
                  borderColor: dark
                      ? scheme.outlineVariant
                      : color.withValues(alpha: 0.14),
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                  semanticLabel:
                      '${a.achievement.title}, '
                      '${a.isUnlocked ? 'unlocked' : 'locked'}. '
                      '${a.achievement.description}',
                  child: ExcludeSemantics(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: -2,
                          top: -4,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: a.isUnlocked
                                  ? DashColors.easy
                                  : scheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: DashColors.softShadow(context),
                            ),
                            child: Icon(
                              a.isUnlocked
                                  ? Icons.check_rounded
                                  : Icons.lock_rounded,
                              size: 14,
                              color: a.isUnlocked
                                  ? Colors.white
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            IconDisc(
                              icon: achievementIcon(a.achievement.iconKey),
                              color: color,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              a.achievement.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.achievement.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({
    required this.icon,
    required this.color,
    required this.title,
    required this.route,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconDisc(icon: icon, color: color, size: 40),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(route),
    );
  }
}
