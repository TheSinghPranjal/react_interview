import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';

/// Holds the in-app splash over the first screen, then lets it through.
///
/// The native launch screen (flutter_native_splash) stays as it is: the same
/// logo on the light or dark background. Android 12 only gives a branding
/// image about 200×80 dp, which cannot show this icon plus a two-line byline
/// at a readable size, and a bitmap would ignore text scale, safe area, and
/// the app fonts. This screen continues that launch look and adds the name
/// and studio mark, then hands off to the normal first route.
class StudioSplashGate extends StatefulWidget {
  const StudioSplashGate({required this.child, super.key});

  final Widget child;

  /// How long the splash stays up after the first Flutter frame.
  static const Duration duration = Duration(milliseconds: 2000);

  @override
  State<StudioSplashGate> createState() => _StudioSplashGateState();
}

class _StudioSplashGateState extends State<StudioSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _reveal;
  late final CurvedAnimation _exit;
  late final Animation<double> _opacity;
  var _showSplash = true;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: StudioSplashGate.duration,
    );
    _reveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.28, curve: Curves.easeOutCubic),
    );
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.86, 1, curve: Curves.easeIn),
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(_exit);
    unawaited(_controller.forward().then((_) => _dismiss(), onError: (_) {}));
  }

  void _dismiss() {
    if (_disposed || !mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  void dispose() {
    _disposed = true;
    _reveal.dispose();
    _exit.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: _showSplash,
          child: IgnorePointer(ignoring: _showSplash, child: widget.child),
        ),
        if (_showSplash)
          Positioned.fill(
            child: FadeTransition(
              opacity: _opacity,
              child: StudioSplashScreen(reveal: _reveal),
            ),
          ),
      ],
    );
  }
}

/// Launch continuation: the existing splash logo and app name, with the
/// Lazy Bear Club byline pinned to the bottom.
class StudioSplashScreen extends StatelessWidget {
  const StudioSplashScreen({this.reveal, super.key});

  /// 0–1 entrance for the name and byline. The logo stays fully visible so
  /// it lines up with the native splash. Null means fully revealed.
  final Animation<double>? reveal;

  static const logoAsset = 'assets/images/splash_logo.png';
  static const brandIconAsset = 'assets/branding/lazy_bear_club.png';
  static const byWord = 'by';
  static const studioName = 'The Lazy Bear Club';

  static const logoKey = Key('splash_logo');
  static const brandIconKey = Key('lazy_bear_club_icon');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final overlay = dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shortest = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final logoSize = (shortest * 0.36).clamp(84.0, 176.0);
                final iconSize = (shortest * 0.16).clamp(64.0, 88.0);
                final bylineMaxHeight = math.min(
                  200.0,
                  constraints.maxHeight * 0.34,
                );
                final contentWidth = math.min(constraints.maxWidth, 440.0);

                return Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: bylineMaxHeight),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: contentWidth,
                            child: _Identity(
                              logoSize: logoSize,
                              reveal: reveal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: contentWidth,
                          maxHeight: bylineMaxHeight,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: contentWidth,
                            child: _LazyBearByline(
                              iconSize: iconSize,
                              reveal: reveal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.logoSize, required this.reveal});

  final double logoSize;
  final Animation<double>? reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          StudioSplashScreen.logoAsset,
          key: StudioSplashScreen.logoKey,
          width: logoSize,
          height: logoSize,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
        SizedBox(height: logoSize < 100 ? AppSpacing.sm : AppSpacing.lg),
        _Reveal(
          animation: reveal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppConstants.appName,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppConstants.tagline,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LazyBearByline extends StatelessWidget {
  const _LazyBearByline({required this.iconSize, required this.reveal});

  final double iconSize;
  final Animation<double>? reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final radius = iconSize * 0.22;

    return _Reveal(
      animation: reveal,
      child: Semantics(
        label: '${StudioSplashScreen.byWord} ${StudioSplashScreen.studioName}',
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Image.asset(
                    StudioSplashScreen.brandIconAsset,
                    key: StudioSplashScreen.brandIconKey,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                StudioSplashScreen.byWord,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  StudioSplashScreen.studioName,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.animation});

  final Animation<double>? animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = this.animation;
    if (animation == null) return child;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
