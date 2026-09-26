import 'package:flutter/material.dart';

/// Centralized color palette for the LocalLens Traveler application.
class AppColors {
  AppColors._();

  // Primary & Accent Brand Colors
  static const Color primaryBlue = Color(0xFF0284C7);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentGold = Color(0xFFF59E0B);

  // Travel Gradients
  // Day Travel Gradient: Sky Blue -> Horizon Blue -> Sunset Glow
  static const List<Color> dayTravelGradient = [
    Color(0xFF0284C7),
    Color(0xFF38BDF8),
    Color(0xFFFB923C),
  ];

  // Night Travel Gradient: Deep Navy -> Night Sky -> Oceanic Teal
  static const List<Color> nightTravelGradient = [
    Color(0xFF0B132B),
    Color(0xFF1C2541),
    Color(0xFF0D9488),
  ];

  // Neutral Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF090D16);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  /// Helper to get the appropriate splash gradient based on brightness
  static List<Color> splashGradient(Brightness brightness) {
    return brightness == Brightness.dark
        ? nightTravelGradient
        : dayTravelGradient;
  }
}
