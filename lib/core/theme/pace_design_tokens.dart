import 'package:flutter/material.dart';

/// Semantic Design Tokens for Pace
/// Provides consistent spacing, radii, touch targets, durations, and layout bounds.
abstract class PaceSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  static const double pageHorizontal = 16.0;
  static const double pageVertical = 16.0;
  static const double cardPadding = 16.0;
  static const double sectionGap = 20.0;
  static const double itemGap = 8.0;
}

abstract class PaceRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double sheet = 20.0;
  static const double pill = 999.0;
}

abstract class PaceTouchTarget {
  /// Minimum recommended accessible touch target height/width (48dp).
  static const double minTargetSize = 48.0;
  static const EdgeInsets minPadding = EdgeInsets.all(12.0);
}

abstract class PaceDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}
