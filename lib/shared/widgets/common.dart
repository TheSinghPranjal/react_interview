import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/datasources/local_content_datasource.dart';
import '../../data/models/enums.dart';

/// Standard loading / error / data handling for [AsyncValue]s.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      data: data,
      loading: () =>
          loading ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator(),
            ),
          ),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  String get _message {
    if (error is ContentLoadException) {
      return 'Some learning content could not be loaded. '
          'Please reinstall or update the app if this keeps happening.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Content unavailable',
      message: _message,
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Difficulty indicator that uses an icon + text, never color alone.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge(this.difficulty, {this.lessonStyle = false, super.key});

  final Difficulty difficulty;
  final bool lessonStyle;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = AppColors.difficulty(difficulty.label);
    final color = dark ? Color.lerp(base, Colors.white, 0.45)! : base;
    final bars = difficulty.index + 1;
    final label = lessonStyle ? difficulty.lessonLabel : difficulty.label;
    return Semantics(
      label: 'Difficulty: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: base.withValues(alpha: dark ? 0.22 : 0.1),
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 3,
                height: 6.0 + i * 3,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: i < bars ? color : color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackBadge extends StatelessWidget {
  const TrackBadge(this.track, {super.key});
  final Track track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        track.label,
        style: TextStyle(
          color: scheme.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({required this.icon, required this.label, super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.action, this.onAction, super.key});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

/// Animated linear progress bar.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    required this.value,
    this.height = 8,
    this.color,
    this.backgroundColor,
    this.semanticsLabel,
    super.key,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      value: '${(v * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v),
        duration: AppDurations.slow,
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: animated,
            minHeight: height,
            color: color ?? scheme.primary,
            backgroundColor:
                backgroundColor ??
                (color ?? scheme.primary).withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }
}

/// Animated circular progress with a centered child.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    this.size = 64,
    this.strokeWidth = 7,
    this.color,
    this.trackColor,
    this.child,
    super.key,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: AppDurations.slow * 1.5,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: v,
            color: c,
            trackColor: trackColor ?? c.withValues(alpha: 0.15),
            strokeWidth: strokeWidth,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(strokeWidth + 2),
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deflated = rect.deflate(strokeWidth / 2);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(deflated, 0, math.pi * 2, false, track);
    if (value > 0) {
      canvas.drawArc(deflated, -math.pi / 2, math.pi * 2 * value, false, fg);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}

/// Fades and slides its child in once, optionally after a stagger delay.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.index = 0,
    this.offset = 16,
    super.key,
  });

  final Widget child;

  /// Position in a list; each step adds a small delay (capped).
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.medium + const Duration(milliseconds: 80),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 40 * math.min(widget.index, 8));
    Future<void>.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _a.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Rounded card with tap feedback and optional gradient background.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = AppSpacing.card,
    this.gradient,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decorated = Ink(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? scheme.surface) : null,
        gradient: gradient,
        borderRadius: AppRadius.lgAll,
        border: gradient == null
            ? Border.all(color: scheme.outlineVariant)
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: decorated,
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple responsive grid without nested scrolling.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.minItemWidth = 150,
    this.spacing = AppSpacing.md,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          2,
          ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor(),
        );
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in children) SizedBox(width: itemWidth, child: c),
          ],
        );
      },
    );
  }
}
