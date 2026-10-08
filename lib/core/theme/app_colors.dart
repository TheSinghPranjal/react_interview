import 'package:flutter/material.dart';

/// Brand palette. All contrast pairs used for text meet WCAG AA (4.5:1).
abstract final class AppColors {
  // Brand
  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoDark = Color(0xFF3730A3);
  static const Color indigoLight = Color(0xFF818CF8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA78BFA);

  // Tracks
  static const Color react = Color(0xFF0EA5E9);
  static const Color reactDeep = Color(0xFF0369A1);
  static const Color next = Color(0xFF1F2937);
  static const Color nextLight = Color(0xFFE5E7EB);

  // Semantic
  static const Color success = Color(0xFF15803D);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorLight = Color(0xFFF87171);
  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color streak = Color(0xFFEA580C);
  static const Color xp = Color(0xFFCA8A04);

  // Difficulty
  static const Color easy = Color(0xFF15803D);
  static const Color medium = Color(0xFFB45309);
  static const Color hard = Color(0xFFB91C1C);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF7F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF0FA);
  static const Color lightOutline = Color(0xFFDCDFEE);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);

  // Dark navy surfaces
  static const Color darkBackground = Color(0xFF0B1020);
  static const Color darkSurface = Color(0xFF131A2E);
  static const Color darkSurfaceAlt = Color(0xFF1B2440);
  static const Color darkOutline = Color(0xFF2A3558);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFFB4BCD0);

  // Code blocks use one dark theme in both modes for consistent highlighting.
  static const Color codeBackground = Color(0xFF0F172A);
  static const Color codeHeader = Color(0xFF1E293B);
  static const Color codeText = Color(0xFFE2E8F0);
  static const Color codeKeyword = Color(0xFFC792EA);
  static const Color codeString = Color(0xFFC3E88D);
  static const Color codeNumber = Color(0xFFF78C6C);
  static const Color codeComment = Color(0xFF8B95A7);
  static const Color codeFunction = Color(0xFF82AAFF);
  static const Color codeTag = Color(0xFFFF7A90);
  static const Color codeAttr = Color(0xFFFFCB6B);
  static const Color codePunctuation = Color(0xFF89DDFF);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [indigo, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient reactGradient = LinearGradient(
    colors: [Color(0xFF0369A1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nextGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF374151)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color difficulty(String level) => switch (level.toLowerCase()) {
    'easy' || 'beginner' => easy,
    'medium' || 'intermediate' => medium,
    _ => hard,
  };
}
