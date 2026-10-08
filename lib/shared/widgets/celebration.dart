import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/achievement.dart';
import '../../features/progress/providers/progress_provider.dart';

/// Maps achievement icon keys to const icons (keeps icon fonts tree-shakable).
IconData achievementIcon(String key) => switch (key) {
  'lesson' => Icons.menu_book_rounded,
  'quiz' => Icons.quiz_rounded,
  'check' => Icons.check_circle_rounded,
  'trophy' => Icons.emoji_events_rounded,
  'star' => Icons.star_rounded,
  'fire' => Icons.local_fire_department_rounded,
  'book' => Icons.auto_stories_rounded,
  'school' => Icons.school_rounded,
  'interview' => Icons.record_voice_over_rounded,
  'badge' => Icons.workspace_premium_rounded,
  'calendar' => Icons.event_available_rounded,
  'level' => Icons.trending_up_rounded,
  _ => Icons.military_tech_rounded,
};

/// Presents the result of a learning activity: an XP toast, streak message,
/// level-up dialog and achievement snackbars. Subtle by design.
Future<void> showActivityOutcome(
  BuildContext context,
  ActivityOutcome outcome,
) async {
  if (!outcome.hasNews || !context.mounted) return;

  final parts = <String>[
    if (outcome.xpGained > 0) '+${outcome.xpGained} XP',
    if ((outcome.streakExtendedTo ?? 0) >= 2)
      '${outcome.streakExtendedTo}-day streak!',
  ];
  if (parts.isNotEmpty) {
    XpToast.show(
      context,
      parts.join('  ·  '),
      streak: (outcome.streakExtendedTo ?? 0) >= 2,
    );
  }

  for (final a in outcome.newAchievements) {
    if (!context.mounted) return;
    _showAchievementSnack(context, a);
  }

  if (outcome.newLevel != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (_) => LevelUpDialog(level: outcome.newLevel!),
    );
  }
}

void _showAchievementSnack(BuildContext context, Achievement a) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(achievementIcon(a.iconKey), color: AppColors.warningLight),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Achievement unlocked: ${a.title}')),
        ],
      ),
    ),
  );
}

/// Small animated "+XP" pill shown near the top of the screen.
abstract final class XpToast {
  static OverlayEntry? _current;

  static void show(BuildContext context, String text, {bool streak = false}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _current?.remove();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _XpToastView(
        text: text,
        streak: streak,
        onDone: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    SemanticsService.sendAnnouncement(
      View.of(context),
      text,
      Directionality.of(context),
    );
  }
}

class _XpToastView extends StatefulWidget {
  const _XpToastView({
    required this.text,
    required this.streak,
    required this.onDone,
  });

  final String text;
  final bool streak;
  final VoidCallback onDone;

  @override
  State<_XpToastView> createState() => _XpToastViewState();
}

class _XpToastViewState extends State<_XpToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.celebration + const Duration(milliseconds: 400),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 12;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            // In: 0–0.2, hold, out: 0.8–1.
            final opacity = t < 0.2
                ? t / 0.2
                : t > 0.8
                ? (1 - t) / 0.2
                : 1.0;
            final scale = t < 0.2
                ? 0.7 + 0.3 * Curves.easeOutBack.transform(t / 0.2)
                : 1.0;
            return Opacity(
              opacity: opacity.clamp(0, 1),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: AppRadius.pillAll,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.streak
                          ? Icons.local_fire_department_rounded
                          : Icons.bolt_rounded,
                      color: AppColors.warningLight,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LevelUpDialog extends StatelessWidget {
  const LevelUpDialog({required this.level, super.key});
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      contentPadding: const EdgeInsets.all(AppSpacing.xl),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: AppDurations.slow,
            curve: Curves.elasticOut,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Level up!', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You reached level $level. Keep the momentum going!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Awesome'),
        ),
      ],
    );
  }
}

/// A short, lightweight confetti burst. Plays once; respects reduced motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({this.particleCount = 36, super.key});
  final int particleCount;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    const colors = [
      AppColors.indigoLight,
      AppColors.purpleLight,
      AppColors.react,
      AppColors.warningLight,
      AppColors.successLight,
    ];
    _particles = List.generate(widget.particleCount, (i) {
      final angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1;
      final speed = 0.55 + r.nextDouble() * 0.6;
      return _Particle(
        dx: math.cos(angle) * speed,
        dy: math.sin(angle) * speed,
        color: colors[i % colors.length],
        size: 4 + r.nextDouble() * 5,
        spin: (r.nextDouble() - 0.5) * 8,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && !_c.isAnimating) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConfettiPainter(_c, _particles),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.dx,
    required this.dy,
    required this.color,
    required this.size,
    required this.spin,
  });
  final double dx;
  final double dy;
  final Color color;
  final double size;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation, this.particles) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0 || t == 1) return;
    final origin = Offset(size.width / 2, size.height * 0.35);
    final scale = size.shortestSide * 0.9;
    final paint = Paint();
    for (final p in particles) {
      final x = origin.dx + p.dx * scale * t;
      final y = origin.dy + p.dy * scale * t + 0.9 * scale * t * t;
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
