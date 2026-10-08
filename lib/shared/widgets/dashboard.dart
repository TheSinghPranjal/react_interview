import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';

/// Dashboard palette shared by the redesigned tab screens.
abstract final class DashColors {
  static const Color ink = Color(0xFF0F1222);
  static const Color reactBlue = Color(0xFF2563EB);
  static const Color nextPurple = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF5EE1FF);
  static const Color reactCyan = Color(0xFF61DAFB);
  static const Color link = Color(0xFF4338CA);

  static const LinearGradient level = LinearGradient(
    colors: [Color(0xFF4A5CF2), Color(0xFF7B63F4), Color(0xFFA772F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient button = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient reactTrack = LinearGradient(
    colors: [Color(0xFF1677F0), Color(0xFF3A55EE), Color(0xFF7A3CF3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nextTrack = LinearGradient(
    colors: [Color(0xFF0B0F1C), Color(0xFF1B2133), Color(0xFF111522)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color easy = Color(0xFF16A34A);
  static const Color medium = Color(0xFFEA7A0B);
  static const Color hard = Color(0xFFDC2626);

  /// Difficulty accent; lightened in dark mode for contrast.
  static Color difficulty(Difficulty d, {bool dark = false}) {
    final c = switch (d) {
      Difficulty.easy => easy,
      Difficulty.medium => medium,
      Difficulty.hard => hard,
    };
    return dark ? Color.lerp(c, Colors.white, 0.35)! : c;
  }

  static List<BoxShadow> softShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF3C46A0).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
}

bool isDarkTheme(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// React "atom" logo drawn with three orbits and a nucleus.
class ReactLogo extends StatelessWidget {
  const ReactLogo({
    this.size = 24,
    this.color = DashColors.reactCyan,
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _AtomPainter(color)),
    );
  }
}

class _AtomPainter extends CustomPainter {
  _AtomPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;
    final orbit = Rect.fromCenter(
      center: Offset.zero,
      width: size.width * 0.92,
      height: size.height * 0.36,
    );
    for (var i = 0; i < 3; i++) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(i * math.pi / 3)
        ..drawOval(orbit, stroke)
        ..restore();
    }
    canvas.drawCircle(c, size.width * 0.09, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_AtomPainter old) => old.color != color;
}

/// Next.js mark: white "N" on a black disc.
class NextLogo extends StatelessWidget {
  const NextLogo({this.size = 24, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Text(
        'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.56,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

/// Bold section title with optional subtitle and a "View all →" link.
class DashSectionHeader extends StatelessWidget {
  const DashSectionHeader(
    this.title, {
    this.subtitle,
    this.onViewAll,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkColor = isDarkTheme(context)
        ? theme.colorScheme.primary
        : DashColors.link;
    final titleText = Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
      ),
    );
    final subtitleText = subtitle == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
    final viewAll = onViewAll == null
        ? null
        : TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: linkColor,
              minimumSize: const Size(48, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View all'),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          );
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: AppSpacing.md),
      child: trailing != null
          // Trailing badges sit beside both lines.
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleText, ?subtitleText],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                trailing!,
                ?viewAll,
              ],
            )
          // "View all" sits beside the title; the subtitle spans below.
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: titleText),
                    ?viewAll,
                  ],
                ),
                ?subtitleText,
              ],
            ),
    );
  }
}

/// Small rounded label with an optional leading widget.
class TagPill extends StatelessWidget {
  const TagPill({
    required this.label,
    required this.color,
    required this.background,
    this.leading,
    super.key,
  });

  final String label;
  final Color color;
  final Color background;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three ascending bars; the first [filled] use [color], the rest are faded.
class SignalBars extends StatelessWidget {
  const SignalBars({
    required this.color,
    this.filled = 3,
    this.size = 12,
    super.key,
  });
  final Color color;
  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: size * 0.22,
            height: size * (0.45 + i * 0.27),
            margin: EdgeInsets.only(right: i < 2 ? size * 0.14 : 0),
            decoration: BoxDecoration(
              color: i < filled ? color : color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
      ],
    );
  }
}

/// Gradient pill button used for primary calls to action.
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    this.height = 44,
    this.leading = const Icon(Icons.play_arrow_rounded, color: Colors.white),
    this.spreadArrow = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Widget leading;

  /// Pushes the trailing arrow to the far edge (full-width buttons).
  final bool spreadArrow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4BEA).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: AppRadius.lgAll,
              child: Ink(
                height: height,
                padding: EdgeInsets.symmetric(horizontal: spreadArrow ? 18 : 0),
                decoration: const BoxDecoration(
                  gradient: DashColors.button,
                  borderRadius: AppRadius.lgAll,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (spreadArrow) const SizedBox(width: 18),
                    if (spreadArrow) const Spacer(),
                    leading,
                    const SizedBox(width: 4),
                    Flexible(
                      flex: 6,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (spreadArrow) const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
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

/// Lavender pill naming the current tab, e.g. "🗣 Interview".
class ScreenBadge extends StatelessWidget {
  const ScreenBadge({required this.icon, required this.label, super.key});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkTheme(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = dark ? scheme.primary : DashColors.link;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainer : const Color(0xFFE9E7FC),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(color: fg, size: 20),
            child: icon,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded-square icon button used in screen heroes.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
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
          borderRadius: AppRadius.mdAll,
          boxShadow: DashColors.softShadow(context),
        ),
        child: Material(
          color: scheme.surface,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.mdAll,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(icon, color: scheme.onSurface, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen hero: tab badge + action, big title, subtitle and artwork.
class DashHero extends StatelessWidget {
  const DashHero({
    required this.badge,
    required this.title,
    required this.semanticTitle,
    required this.subtitle,
    required this.art,
    this.action,
    this.artWidth = 160,
    this.artTop = 40,
    this.titleWidthFactor = 0.68,
    this.subtitleWidthFactor = 0.64,
    this.titleFontSize = 27,
    super.key,
  });

  final Widget badge;
  final Widget? action;

  /// Rich title spans; colored words are separate spans.
  final List<InlineSpan> title;
  final String semanticTitle;
  final String subtitle;
  final String art;
  final double artWidth;
  final double artTop;
  final double titleWidthFactor;
  final double subtitleWidthFactor;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = isDarkTheme(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -AppSpacing.lg,
          top: artTop,
          width: artWidth,
          child: ExcludeSemantics(child: Image.asset(art, fit: BoxFit.contain)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: badge,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Spacer(),
                ?action,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FractionallySizedBox(
              widthFactor: titleWidthFactor,
              child: Semantics(
                header: true,
                label: semanticTitle,
                excludeSemantics: true,
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: titleFontSize,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.9,
                      color: dark
                          ? theme.colorScheme.onSurface
                          : DashColors.ink,
                    ),
                    children: title,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FractionallySizedBox(
              widthFactor: subtitleWidthFactor,
              child: Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rounded tappable surface whose shadow is drawn outside the ink layer.
class TapCard extends StatelessWidget {
  const TapCard({
    required this.child,
    this.onTap,
    this.gradient,
    this.color,
    this.borderColor,
    this.shadows,
    this.radius = AppRadius.xlAll,
    this.padding = const EdgeInsets.all(14),
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;

  /// Defaults to [DashColors.softShadow].
  final List<BoxShadow>? shadows;
  final BorderRadius radius;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadows ?? DashColors.softShadow(context),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Ink(
              padding: padding,
              decoration: BoxDecoration(
                color: gradient == null ? (color ?? scheme.surface) : null,
                gradient: gradient,
                borderRadius: radius,
                border: borderColor == null
                    ? null
                    : Border.all(color: borderColor!),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable pill. Selected pills are filled indigo with a check mark, or
/// outlined lavender when [outlinedSelection] is true.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.labelColor,
    this.outlinedSelection = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Color? labelColor;
  final bool outlinedSelection;

  /// Center content and fill the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = isDarkTheme(context);
    final indigo = dark ? scheme.primary : const Color(0xFF4F46E5);
    final filled = selected && !outlinedSelection;
    final fg = filled
        ? Colors.white
        : selected
        ? indigo
        : (labelColor ?? scheme.onSurface);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillAll,
          child: Ink(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: expand ? 6 : 14),
            decoration: BoxDecoration(
              gradient: filled ? DashColors.button : null,
              color: filled
                  ? null
                  : selected
                  ? indigo.withValues(alpha: 0.1)
                  : scheme.surface,
              borderRadius: AppRadius.pillAll,
              border: filled
                  ? null
                  : Border.all(
                      color: selected ? indigo : scheme.outlineVariant,
                      width: selected ? 1.6 : 1,
                    ),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (filled) ...[
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                ] else if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tinted circular icon disc.
class IconDisc extends StatelessWidget {
  const IconDisc({
    required this.icon,
    required this.color,
    this.size = 44,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkTheme(context) ? 0.2 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}
