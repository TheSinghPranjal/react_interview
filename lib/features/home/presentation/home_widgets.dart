import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/dashboard.dart';
import '../../daily_challenge/daily_challenge_providers.dart';
import '../../learn/providers/learn_providers.dart';
import '../../progress/providers/progress_provider.dart';
import '../../settings/providers/settings_provider.dart';

/// Greeting, search/bookmark/avatar actions and the hero title with artwork.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(settingsProvider.select((s) => s.userName));
    final now = ref.watch(clockProvider)();
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final dark = isDarkTheme(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -AppSpacing.lg,
          top: 78,
          bottom: -4,
          width: 196,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: dark ? 0.9 : 1,
              child: Image.asset(
                'assets/images/home_hero.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting(now)},',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '$name 👋',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => context.push(AppRoutes.search),
                  icon: Icon(Icons.search_rounded, size: 28, color: ink),
                ),
                IconButton(
                  tooltip: 'Bookmarks',
                  onPressed: () => context.push(AppRoutes.bookmarks),
                  icon: Icon(Icons.bookmarks_outlined, size: 26, color: ink),
                ),
                const SizedBox(width: AppSpacing.xs),
                Semantics(
                  button: true,
                  label: 'Profile',
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFDDE3FB),
                        boxShadow: DashColors.softShadow(context),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/home_avatar.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              label: 'Learn React & Next.js',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: dark ? ink : DashColors.ink,
                    ),
                    children: [
                      const TextSpan(text: 'Learn '),
                      TextSpan(
                        text: 'React',
                        style: TextStyle(
                          color: dark
                              ? const Color(0xFF60A5FA)
                              : DashColors.reactBlue,
                        ),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Next.js',
                        style: TextStyle(
                          color: dark
                              ? AppColors.purpleLight
                              : DashColors.nextPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: Text(
                'Master modern web development one concept at a time.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ],
    );
  }
}

/// Indigo→violet level card with a cyan ring, XP bar and medal.
class HomeLevelCard extends ConsumerWidget {
  const HomeLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(levelProvider);
    final today = ref.watch(xpTodayProvider);
    return Semantics(
      button: true,
      label:
          'Level ${level.level}, ${level.title}, ${level.totalXp} XP. '
          '${level.xpToNextLevel} XP to next level.',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xlAll,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B5BF0).withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => context.push(AppRoutes.achievements),
            borderRadius: AppRadius.xlAll,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: DashColors.level,
                borderRadius: AppRadius.xlAll,
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  ProgressRing(
                    value: level.progress,
                    size: 76,
                    strokeWidth: 6,
                    color: DashColors.cyan,
                    trackColor: DashColors.cyan.withValues(alpha: 0.35),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'LVL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${level.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    level.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TweenAnimationBuilder<int>(
                                    tween: IntTween(
                                      begin: 0,
                                      end: level.totalXp,
                                    ),
                                    duration: AppDurations.slow,
                                    builder: (context, v, _) => Text(
                                      '$v XP',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        height: 1.25,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text('🏅', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AnimatedProgressBar(
                          value: level.progress,
                          height: 5,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${level.xpToNextLevel} XP to level ${level.level + 1}'
                            '   •   +$today today',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One stat tile: tinted icon disc, chevron, big value and label.
class HomeStatTile extends StatelessWidget {
  const HomeStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.tint,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = isDarkTheme(context);
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          boxShadow: DashColors.softShadow(context),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: Ink(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: dark ? 1 : 0.55,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: dark ? color.withValues(alpha: 0.18) : tint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3-column grid of stat tiles (two columns on very narrow screens).
class HomeStatsGrid extends ConsumerWidget {
  const HomeStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider.select((s) => s.current));
    final level = ref.watch(levelProvider);
    final lessons = ref.watch(
      progressProvider.select((p) => p.lessonsCompleted),
    );
    final interview = ref.watch(
      progressProvider.select((p) => p.interviewCompleted),
    );
    final stats = ref.watch(quizStatsProvider);
    void push(String r) => context.push(r);
    void go(String r) => context.go(r);
    final tiles = [
      HomeStatTile(
        icon: Icons.local_fire_department_rounded,
        label: 'Day streak',
        value: '$streak',
        color: const Color(0xFFF4511E),
        tint: const Color(0xFFFFE6DE),
        onTap: () => push(AppRoutes.stats),
      ),
      HomeStatTile(
        icon: Icons.bolt_rounded,
        label: 'Total XP',
        value: '${level.totalXp}',
        color: const Color(0xFFF5B000),
        tint: const Color(0xFFFFF3D1),
        onTap: () => push(AppRoutes.achievements),
      ),
      HomeStatTile(
        icon: Icons.bar_chart_rounded,
        label: 'Level',
        value: '${level.level}',
        color: const Color(0xFF6D3AED),
        tint: const Color(0xFFECE5FD),
        onTap: () => push(AppRoutes.achievements),
      ),
      HomeStatTile(
        icon: Icons.menu_book_rounded,
        label: 'Topics done',
        value: '$lessons',
        color: const Color(0xFF2563EB),
        tint: const Color(0xFFE2ECFE),
        onTap: () => go(AppRoutes.learn),
      ),
      HomeStatTile(
        icon: Icons.track_changes_rounded,
        label: 'Quiz accuracy',
        value: stats.questionsAnswered == 0
            ? '—'
            : '${(stats.accuracy * 100).round()}%',
        color: const Color(0xFF16A34A),
        tint: const Color(0xFFDDF6E6),
        onTap: () => push(AppRoutes.stats),
      ),
      HomeStatTile(
        icon: Icons.group_rounded,
        label: 'Interview Qs',
        value: '$interview',
        color: const Color(0xFFE11D74),
        tint: const Color(0xFFFDE2EE),
        onTap: () => go(AppRoutes.interview),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final columns = c.maxWidth < 300 ? 2 : 3;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

/// Streak summary with a Mon–Sun row inside a soft blue card.
class HomeStreakCard extends ConsumerWidget {
  const HomeStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    const flame = Color(0xFFF4511E);
    final indigo = dark ? scheme.primary : const Color(0xFF3B3FD8);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: dark
            ? null
            : const LinearGradient(
                colors: [Color(0xFFEAF1FF), Color(0xFFF1EFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: dark ? scheme.surface : null,
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: dark ? scheme.outlineVariant : const Color(0xFFD9E3FA),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: dark ? scheme.surfaceContainer : Colors.white,
                  borderRadius: AppRadius.mdAll,
                  boxShadow: DashColors.softShadow(context),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: AppDurations.slow,
                  curve: Curves.elasticOut,
                  builder: (context, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: flame,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${streak.current}-day streak',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      streak.activeToday
                          ? 'You learned today. Nice work!'
                          : streak.current > 0
                          ? 'Learn something today to keep it going.'
                          : 'Complete any learning activity to start a streak.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: dark
                      ? scheme.surfaceContainer
                      : const Color(0xFFE2E9FA),
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  'Best ${streak.longest}',
                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: dark
                  ? scheme.surfaceContainer
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: AppRadius.lgAll,
            ),
            child: Row(
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
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: day.isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: day.isToday
                                    ? indigo
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 30,
                            child: Center(
                              child: AnimatedContainer(
                                duration: AppDurations.medium,
                                width: day.isToday ? 30 : 25,
                                height: day.isToday ? 30 : 25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: day.isActive
                                      ? flame
                                      : day.isToday
                                      ? indigo.withValues(alpha: 0.14)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: day.isActive
                                        ? flame
                                        : day.isToday
                                        ? indigo
                                        : (dark
                                              ? scheme.outline
                                              : const Color(0xFFC7D2EE)),
                                    width: day.isToday ? 2.5 : 1.5,
                                  ),
                                ),
                                child: day.isActive
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Continue learning" card with badges, meta row, progress and artwork.
class HomeContinueCard extends ConsumerWidget {
  const HomeContinueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(continueLearningProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    return AsyncValueView(
      value: value,
      onRetry: () => ref.invalidate(continueLearningProvider),
      data: (cl) {
        if (cl == null) {
          return const AppCard(
            child: Row(
              children: [
                Icon(Icons.celebration_rounded, size: 32),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'You completed every lesson. Time to ace interviews!',
                  ),
                ),
              ],
            ),
          );
        }
        final l = cl.lesson;
        final isReact = l.track == Track.react;
        final purple = dark ? AppColors.purpleLight : const Color(0xFF6D3AED);
        final green = dark ? AppColors.successLight : const Color(0xFF15803D);
        final muted = scheme.onSurfaceVariant;
        void open() => context.push(AppRoutes.lesson(l.track, l.id));
        final meta = TextStyle(
          color: muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        );
        Widget divider() => Container(
          width: 1,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: scheme.outlineVariant,
        );
        return Semantics(
          button: true,
          label: 'Continue ${l.category}: ${l.title}',
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.xlAll,
              boxShadow: DashColors.softShadow(context),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: open,
                borderRadius: AppRadius.xlAll,
                child: Ink(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    gradient: dark
                        ? null
                        : const LinearGradient(
                            colors: [Colors.white, Color(0xFFF4F0FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.topRight,
                          ),
                    borderRadius: AppRadius.xlAll,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(
                        alpha: dark ? 1 : 0.6,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                TagPill(
                                  label: l.track.label,
                                  color: purple,
                                  background: purple.withValues(alpha: 0.12),
                                  leading: isReact
                                      ? ReactLogo(size: 16, color: purple)
                                      : const NextLogo(size: 16),
                                ),
                                TagPill(
                                  label: l.difficulty.lessonLabel,
                                  color: green,
                                  background: green.withValues(alpha: 0.12),
                                  leading: SignalBars(color: green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l.category,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Next up: ${l.title}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${l.estimatedMinutes} min',
                                    style: meta,
                                  ),
                                  divider(),
                                  Icon(
                                    Icons.article_outlined,
                                    size: 16,
                                    color: muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cl.categoryTotal} lessons',
                                    style: meta,
                                  ),
                                  divider(),
                                  SignalBars(color: muted),
                                  const SizedBox(width: 4),
                                  Text(l.difficulty.lessonLabel, style: meta),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            AnimatedProgressBar(
                              value: cl.categoryTotal == 0
                                  ? 0
                                  : cl.categoryDone / cl.categoryTotal,
                              height: 9,
                              color: dark
                                  ? scheme.primary
                                  : const Color(0xFF4F46E5),
                              backgroundColor: dark
                                  ? scheme.surfaceContainer
                                  : const Color(0xFFE6E3FA),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${cl.categoryDone} of ${cl.categoryTotal} lessons completed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 138,
                        child: Column(
                          children: [
                            ExcludeSemantics(
                              child: Image.asset(
                                'assets/images/home_continue_art.png',
                                height: 112,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GradientButton(label: 'Continue', onPressed: open),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Side-by-side React / Next.js track cards.
class HomeTrackRow extends StatelessWidget {
  const HomeTrackRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 320) {
          return const Column(
            children: [
              HomeTrackCard(track: Track.react),
              SizedBox(height: AppSpacing.md),
              HomeTrackCard(track: Track.next),
            ],
          );
        }
        return const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: HomeTrackCard(track: Track.react)),
              SizedBox(width: 10),
              Expanded(child: HomeTrackCard(track: Track.next)),
            ],
          ),
        );
      },
    );
  }
}

class HomeTrackCard extends ConsumerWidget {
  const HomeTrackCard({required this.track, super.key});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(trackProgressProvider(track)).value;
    final isReact = track == Track.react;
    final title = isReact ? 'React' : 'Next.js';
    final subtitle = isReact
        ? 'Master modern React with hands-on examples'
        : 'Build production-ready applications with Next.js';
    final fraction = progress?.fraction ?? 0;
    void open() => context.go(AppRoutes.track(track));
    return Semantics(
      button: true,
      label:
          '$title track. $subtitle. '
          '${progress?.done ?? 0} of ${progress?.total ?? 0} lessons completed',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xlAll,
          boxShadow: [
            BoxShadow(
              color:
                  (isReact ? const Color(0xFF3A55EE) : const Color(0xFF0B0F1C))
                      .withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: open,
            borderRadius: AppRadius.xlAll,
            child: Ink(
              decoration: BoxDecoration(
                gradient: isReact
                    ? DashColors.reactTrack
                    : DashColors.nextTrack,
                borderRadius: AppRadius.xlAll,
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isReact
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: AppRadius.lgAll,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: isReact
                            ? const ReactLogo(size: 34)
                            : const NextLogo(size: 36),
                      ),
                      const Spacer(),
                      ProgressRing(
                        value: fraction,
                        size: 50,
                        strokeWidth: 4,
                        color: DashColors.cyan,
                        trackColor: Colors.white.withValues(alpha: 0.18),
                        child: Text(
                          '${(fraction * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                    maxLines: 3,
                  ),
                  const Spacer(),
                  const SizedBox(height: 12),
                  AnimatedProgressBar(
                    value: fraction,
                    height: 6,
                    color: DashColors.cyan,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress?.done ?? 0} / ${progress?.total ?? 0} lessons',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: isReact
                        ? Colors.white.withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgAll,
                      side: isReact
                          ? BorderSide.none
                          : BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                    ),
                    child: InkWell(
                      onTap: open,
                      borderRadius: AppRadius.lgAll,
                      child: SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Start learning',
                                    style: TextStyle(
                                      color: isReact
                                          ? const Color(0xFF3B3FD8)
                                          : Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: isReact
                                    ? const Color(0xFF3B3FD8)
                                    : Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "+30 XP" pill shown next to the daily challenge header.
class HomeXpPill extends ConsumerWidget {
  const HomeXpPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(dailyChallengeDoneProvider);
    final dark = isDarkTheme(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainer : const Color(0xFFEDE9FE),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        done ? 'Completed ✓' : '🔥 +30 XP',
        style: TextStyle(
          color: done
              ? (dark ? AppColors.successLight : AppColors.success)
              : (dark ? scheme.primary : DashColors.link),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Warm gradient daily challenge card with artwork on the right.
class HomeDailyChallengeCard extends ConsumerWidget {
  const HomeDailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(dailyChallengeProvider);
    final done = ref.watch(dailyChallengeDoneProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    return AsyncValueView(
      value: challenge,
      onRetry: () => ref.invalidate(dailyChallengeProvider),
      data: (c) {
        if (c == null) return const SizedBox.shrink();
        void open() => context.push(AppRoutes.challenge);
        final orange = dark ? AppColors.warningLight : const Color(0xFFD97706);
        final link = dark ? scheme.primary : DashColors.link;
        return Semantics(
          button: true,
          label: 'Daily challenge: ${c.prompt}',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: open,
              borderRadius: AppRadius.xlAll,
              child: Ink(
                decoration: BoxDecoration(
                  color: dark ? scheme.surface : null,
                  gradient: dark
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFFF5EA), Color(0xFFFBF0FB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: AppRadius.xlAll,
                  border: Border.all(
                    color: dark
                        ? scheme.outlineVariant
                        : const Color(0xFFF6E3D3),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8730C),
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: TagPill(
                                  label: c.typeLabel,
                                  color: orange,
                                  background: orange.withValues(
                                    alpha: dark ? 0.18 : 0.14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            c.prompt,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          Material(
                            color: dark
                                ? scheme.surfaceContainer
                                : const Color(0xFFE9E5FD),
                            shape: const StadiumBorder(),
                            child: InkWell(
                              onTap: open,
                              customBorder: const StadiumBorder(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  16,
                                  10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      done
                                          ? Icons.replay_rounded
                                          : Icons.play_arrow_rounded,
                                      color: link,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        done ? 'Review' : 'Take challenge',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: link,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: link,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ExcludeSemantics(
                      child: Image.asset(
                        'assets/images/home_challenge_art.png',
                        width: 104,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
