import 'package:flutter/material.dart';
import 'pace_colors.dart';
import 'pace_design_tokens.dart';

abstract class PaceTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PaceColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: PaceColors.primary,
        onPrimary: Colors.white,
        secondary: PaceColors.secondary,
        onSecondary: Colors.white,
        surface: PaceColors.darkSurface,
        onSurface: PaceColors.darkTextPrimary,
        error: PaceColors.error,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: PaceColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaceRadius.lg),
          side: BorderSide(color: PaceColors.darkBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PaceColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaceRadius.xl),
          side: BorderSide(color: PaceColors.darkBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PaceColors.darkSurface,
        modalBackgroundColor: PaceColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(PaceRadius.sheet)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PaceColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: PaceColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: PaceColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PaceColors.darkSurface,
        indicatorColor: PaceColors.primary.withValues(alpha: 0.2),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PaceColors.primaryLight,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: PaceColors.darkTextMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: PaceColors.primaryLight, size: 22);
          }
          return IconThemeData(color: PaceColors.darkTextMuted, size: 22);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: PaceColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PaceColors.darkBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: PaceSpacing.lg, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.md),
          borderSide: BorderSide(color: PaceColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.md),
          borderSide: BorderSide(color: PaceColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.md),
          borderSide: BorderSide(color: PaceColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.md),
          borderSide: BorderSide(color: PaceColors.error),
        ),
        hintStyle: const TextStyle(color: PaceColors.darkTextMuted, fontSize: 14),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return PaceColors.primary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PaceColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: PaceColors.primary,
        onPrimary: Colors.white,
        secondary: PaceColors.secondary,
        onSecondary: Colors.white,
        surface: PaceColors.lightSurface,
        onSurface: PaceColors.lightTextPrimary,
        error: PaceColors.error,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: PaceColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaceRadius.lg),
          side: BorderSide(color: PaceColors.lightBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PaceColors.lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaceRadius.xl),
          side: BorderSide(color: PaceColors.lightBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PaceColors.lightSurface,
        modalBackgroundColor: PaceColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(PaceRadius.sheet)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PaceColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: PaceColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: PaceColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PaceColors.lightSurface,
        indicatorColor: PaceColors.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PaceColors.primaryDark,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: PaceColors.lightTextMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: PaceColors.primaryDark, size: 22);
          }
          return IconThemeData(color: PaceColors.lightTextMuted, size: 22);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: PaceColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PaceColors.lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: PaceSpacing.lg, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.md),
          borderSide: BorderSide(color: PaceColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.md),
          borderSide: BorderSide(color: PaceColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.md),
          borderSide: BorderSide(color: PaceColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.md),
          borderSide: BorderSide(color: PaceColors.error),
        ),
        hintStyle: const TextStyle(color: PaceColors.lightTextMuted, fontSize: 14),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return PaceColors.primary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
