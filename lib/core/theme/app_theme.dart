import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.indigo,
          onPrimary: Colors.white,
          secondary: AppColors.purple,
          onSecondary: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          onSurfaceVariant: AppColors.lightTextSecondary,
          surfaceContainerLowest: AppColors.lightBackground,
          surfaceContainerLow: AppColors.lightSurface,
          surfaceContainer: AppColors.lightSurfaceAlt,
          surfaceContainerHigh: const Color(0xFFE6E8F5),
          outline: const Color(0xFF8C92AC),
          outlineVariant: AppColors.lightOutline,
          error: AppColors.error,
        ),
    background: AppColors.lightBackground,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.indigoLight,
          onPrimary: const Color(0xFF0B1020),
          secondary: AppColors.purpleLight,
          onSecondary: const Color(0xFF0B1020),
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          surfaceContainerLowest: AppColors.darkBackground,
          surfaceContainerLow: AppColors.darkSurface,
          surfaceContainer: AppColors.darkSurfaceAlt,
          surfaceContainerHigh: const Color(0xFF243052),
          outline: const Color(0xFF6B7699),
          outlineVariant: AppColors.darkOutline,
          error: AppColors.errorLight,
        ),
    background: AppColors.darkBackground,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final textTheme = AppTextStyles.textTheme(textPrimary, textSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : textSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSpacing.minTouchTarget),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelLarge,
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        checkmarkColor: scheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        minVerticalPadding: AppSpacing.md,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.14),
        circularTrackColor: scheme.primary.withValues(alpha: 0.14),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(48, 44),
          selectedBackgroundColor: scheme.primary.withValues(alpha: 0.16),
          selectedForegroundColor: scheme.primary,
        ),
      ),
    );
  }
}
