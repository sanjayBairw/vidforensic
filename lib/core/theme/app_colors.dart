import 'package:flutter/material.dart';

class AppColors {
  // Dark Forensic Theme Colors
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);      // Slate 700

  // Light Forensic Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);    // Slate 200

  // Accent Colors
  static const Color primaryBlue = Color(0xFF3B82F6);    // Blue 500
  static const Color primaryBlueDark = Color(0xFF2563EB);
  static const Color secondaryCyan = Color(0xFF06B6D4);   // Cyan 500
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color primaryAccent = Color(0xFF3B82F6);

  // Status Colors
  static const Color successGreen = Color(0xFF10B981);   // Emerald 500
  static const Color warningOrange = Color(0xFFF59E0B);  // Amber 500
  static const Color errorRed = Color(0xFFEF4444);       // Red 500
  static const Color infoBlue = Color(0xFF3B82F6);

  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);

  // Confidence Levels
  static const Color confidenceHigh = Color(0xFFEF4444);  // High Severity/Confidence Red
  static const Color confidenceMedium = Color(0xFFF59E0B); // Amber
  static const Color confidenceLow = Color(0xFF10B981);   // Emerald Green

  static const Color highConfidence = Color(0xFFEF4444);
  static const Color mediumConfidence = Color(0xFFF59E0B);
  static const Color lowConfidence = Color(0xFF10B981);
  static const Color neutralConfidence = Color(0xFF64748B);
}
