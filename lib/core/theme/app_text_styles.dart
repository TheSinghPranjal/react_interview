import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const String codeFontFamily = 'monospace';
  static const List<String> codeFontFallback = [
    'Roboto Mono',
    'Menlo',
    'Courier New',
    'Courier',
  ];

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: primary),
      bodyMedium: TextStyle(fontSize: 14.5, height: 1.5, color: primary),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: secondary),
      labelLarge: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: secondary,
      ),
    );
  }

  static const TextStyle code = TextStyle(
    fontFamily: codeFontFamily,
    fontFamilyFallback: codeFontFallback,
    fontSize: 13,
    height: 1.5,
  );

  static TextStyle inlineCode(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: codeFontFamily,
      fontFamilyFallback: codeFontFallback,
      fontSize: 13.5,
      color: scheme.primary,
      backgroundColor: scheme.primary.withValues(alpha: 0.08),
    );
  }
}
