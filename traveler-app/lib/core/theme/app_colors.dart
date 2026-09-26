import 'package:flutter/material.dart';

/// Centralized color palette for the LocalLens Traveler application, matching Stitch Warm Editorial Journey.
class AppColors {
  AppColors._();

  // Stitch Warm Editorial Primary & Accent Brand Colors
  static const Color primaryTerracotta = Color(0xFFE85028);
  static const Color primaryBlue = Color(0xFFE85028); // Alias for Stitch Terracotta
  static const Color coastalSage = Color(0xFF5A7363);
  static const Color accentTeal = Color(0xFF5A7363); // Alias
  static const Color sandTertiary = Color(0xFFD4A373);
  static const Color accentGold = Color(0xFFD4A373); // Alias
  static const Color primaryDark = Color(0xFF1A1A1A); // Deep Ink
  static const Color accentOrange = Color(0xFFE85028);

  // Travel Gradients (Stitch Warm Editorial)
  static const List<Color> dayTravelGradient = [
    Color(0xFFE85028),
    Color(0xFFFA7252),
    Color(0xFFD4A373),
  ];

  static const List<Color> nightTravelGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF2C2C2C),
    Color(0xFFE85028),
  ];

  // Neutral Colors (Alabaster & Pure White)
  static const Color backgroundLight = Color(0xFFFAF9F6);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors (Deep Ink & Slate)
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6E6D7A);
  static const Color textPrimaryDark = Color(0xFFFAF9F6);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF5A7363);
  static const Color warning = Color(0xFFD4A373);
  static const Color error = Color(0xFFBA1A1A);

  /// Helper to get the appropriate splash gradient based on brightness
  static List<Color> splashGradient(Brightness brightness) {
    return brightness == Brightness.dark
        ? nightTravelGradient
        : dayTravelGradient;
  }
}
