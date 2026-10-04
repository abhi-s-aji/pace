import 'package:flutter/material.dart';

/// Pace Color Palette
/// Designed for a calm, professional, privacy-focused productivity tool.
abstract class PaceColors {
  // Dark Theme Base
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceElevated = Color(0xFF21262D);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkBorderSubtle = Color(0xFF21262D);

  // Light Theme Base
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);

  // Brand Accents
  static Color primary = const Color(0xFF0D9488);
  static Color primaryLight = const Color(0xFF14B8A6);
  static Color primaryDark = const Color(0xFF0F766E);

  static Color secondary = const Color(0xFF6366F1);
  static Color secondaryLight = const Color(0xFF818CF8);

  static const Color accentGold = Color(0xFFF59E0B);

  // Text Colors - Dark Mode
  static const Color darkTextPrimary = Color(0xFFC9D1D9);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextMuted = Color(0xFF6E7681);

  // Text Colors - Light Mode
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Contribution Calendar Levels
  static List<Color> contributionLevelsDark = [
    const Color(0xFF161B22),
    const Color(0xFF064E3B),
    const Color(0xFF047857),
    const Color(0xFF10B981),
    const Color(0xFF34D399),
  ];

  static List<Color> contributionLevelsLight = [
    const Color(0xFFE2E8F0),
    const Color(0xFFA7F3D0),
    const Color(0xFF34D399),
    const Color(0xFF10B981),
    const Color(0xFF047857),
  ];

  // Category Palette
  static const List<Color> categoryColors = [
    Color(0xFF0D9488),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF64748B),
  ];

  static void setAccentColor(String colorName) {
    switch (colorName) {
      case 'blue':
        primary = const Color(0xFF0284C7);
        primaryLight = const Color(0xFF0EA5E9);
        primaryDark = const Color(0xFF0369A1);
        contributionLevelsLight = [
          const Color(0xFFE2E8F0),
          const Color(0xFFBAE6FD),
          const Color(0xFF7DD3FC),
          const Color(0xFF0EA5E9),
          const Color(0xFF0284C7),
        ];
        break;
      case 'purple':
        primary = const Color(0xFF7C3AED);
        primaryLight = const Color(0xFF8B5CF6);
        primaryDark = const Color(0xFF6D28D9);
        contributionLevelsLight = [
          const Color(0xFFE2E8F0),
          const Color(0xFFDDD6FE),
          const Color(0xFFC4B5FD),
          const Color(0xFF8B5CF6),
          const Color(0xFF7C3AED),
        ];
        break;
      case 'orange':
        primary = const Color(0xFFEA580C);
        primaryLight = const Color(0xFFF97316);
        primaryDark = const Color(0xFFC2410C);
        contributionLevelsLight = [
          const Color(0xFFE2E8F0),
          const Color(0xFFFFEDD5),
          const Color(0xFFFDBA74),
          const Color(0xFFF97316),
          const Color(0xFFEA580C),
        ];
        break;
      case 'green':
      default:
        primary = const Color(0xFF0D9488);
        primaryLight = const Color(0xFF14B8A6);
        primaryDark = const Color(0xFF0F766E);
        contributionLevelsLight = [
          const Color(0xFFE2E8F0),
          const Color(0xFFA7F3D0),
          const Color(0xFF34D399),
          const Color(0xFF10B981),
          const Color(0xFF047857),
        ];
        break;
    }
  }
}
