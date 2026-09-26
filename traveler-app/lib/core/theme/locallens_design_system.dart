import 'package:flutter/material.dart';

/// Centralized color palette derived directly from the LocalLens UI reference
class LocalLensColors {
  LocalLensColors._();

  // Primary Brand Colors
  static const Color primaryTeal = Color(0xFF0E8388);
  static const Color primaryTealDark = Color(0xFF006D77);
  static const Color primaryTealLight = Color(0xFF2EC4B6);
  static const Color primaryTealSoft = Color(0xFFE6F7F7);

  // Secondary & Accent Colors
  static const Color accentOrange = Color(0xFFFF6B4A);
  static const Color accentOrangeLight = Color(0xFFFA7268);
  static const Color accentOrangeSoft = Color(0xFFFFF0EC);
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color warmAmberSoft = Color(0xFFFEF3C7);
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenSoft = Color(0xFFD1FAE5);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRedSoft = Color(0xFFFEE2E2);

  // Typography & Dark Accents
  static const Color textPrimary = Color(0xFF0B2545);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0E8388), Color(0xFF2EC4B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B4A), Color(0xFFFA7268)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF006D77), Color(0xFF0E8388), Color(0xFF2EC4B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF83C5BE), Color(0xFFE29578)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Centralized Typography hierarchy matching the reference design
class LocalLensTypography {
  LocalLensTypography._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: LocalLensColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: LocalLensColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: LocalLensColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: LocalLensColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: LocalLensColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: LocalLensColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: LocalLensColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: LocalLensColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
  );
}

/// Design system dimension constants
class LocalLensDimensions {
  LocalLensDimensions._();

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 999.0;

  static const double paddingScreen = 20.0;
  static const double paddingCard = 16.0;

  static const double buttonHeight = 54.0;
  static const double buttonRadius = 27.0;

  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x0A0B2545),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x140B2545),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 2,
    ),
  ];
}

/// Token aliases per design.md specification
class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double sheet = 28.0;
  static const double full = 999.0;
}

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0C0B2545),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1A0B2545),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 1,
    ),
  ];
}

