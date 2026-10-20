import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // LIGHT THEME TOKENS (#F4F7FB base, #2563EB primary)
  // ============================================================
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightHighlight = Color(0xFFEFF6FF);
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ============================================================
  // DARK THEME TOKENS (#0B1020 base, #60A5FA primary)
  // ============================================================
  static const Color darkBackground = Color(0xFF0B1020);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF111827);
  static const Color darkElevated = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkPrimary = Color(0xFF60A5FA);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ============================================================
  // ACCENT COLORS (Compatibility & Theme-Safe)
  // ============================================================
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color secondaryCyan = Color(0xFF06B6D4);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color primaryAccent = Color(0xFF2563EB);

  // ============================================================
  // STATUS COLORS (Semantic)
  // ============================================================
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF2563EB);

  // Semantic dark variants
  static const Color statusSuccessDark = Color(0xFF34D399);
  static const Color statusWarningDark = Color(0xFFFBBF24);
  static const Color statusErrorDark = Color(0xFFF87171);

  // Compatibility aliases
  static const Color success = statusSuccess;
  static const Color error = statusError;
  static const Color warning = statusWarning;
  static const Color successGreen = statusSuccess;
  static const Color warningOrange = statusWarning;
  static const Color errorRed = statusError;

  // ============================================================
  // CONFIDENCE LEVELS
  // ============================================================
  static const Color confidenceHigh = Color(0xFFEF4444);
  static const Color confidenceMedium = Color(0xFFF59E0B);
  static const Color confidenceLow = Color(0xFF10B981);

  static const Color highConfidence = Color(0xFFEF4444);
  static const Color mediumConfidence = Color(0xFFF59E0B);
  static const Color lowConfidence = Color(0xFF10B981);
  static const Color neutralConfidence = Color(0xFF64748B);

  // ============================================================
  // THEME CONTEXT HELPERS
  // ============================================================
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color card(BuildContext context) =>
      isDark(context) ? darkCard : lightCard;

  static Color elevated(BuildContext context) =>
      isDark(context) ? darkElevated : lightHighlight;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color primary(BuildContext context) =>
      isDark(context) ? darkPrimary : lightPrimary;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color highlight(BuildContext context) =>
      isDark(context) ? darkElevated : lightHighlight;
}
