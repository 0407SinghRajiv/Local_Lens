import 'package:flutter/material.dart';

/// Centralized color palette derived directly from the LocalLens UI reference
class LocalLensColors {
  LocalLensColors._();

  // Stitch Warm Editorial Primary & Accent Brand Colors
  static const Color stitchPrimary = Color(0xFFE85028); // Terracotta/Persimmon
  static const Color stitchSecondary = Color(0xFF5A7363); // Coastal Sage
  static const Color stitchTertiary = Color(0xFFD4A373); // Sand

  static const Color terracottaPrimary = Color(0xFFE85028);
  static const Color coralPrimary = Color(0xFFFF5A5F); // Reference UI Coral Red
  static const Color coralSoft = Color(0xFFFFEBEB);
  static const Color coastalSage = Color(0xFF5A7363);
  static const Color sandTertiary = Color(0xFFD4A373);
  static const Color deepInk = Color(0xFF1A1A1A);

  static const Color surfaceContainer = Color(0xFFF0EDED);
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color surfaceContainerHigh = Color(0xFFEAE7E7);
  static const Color borderSubtle = Color(0xFFEAE8E3);

  static const Color primaryTeal = Color(0xFFFF5A5F); // Coral Red Primary Accent
  static const Color primaryTealDark = Color(0xFFCF3E18);
  static const Color primaryTealLight = Color(0xFFFA7252);
  static const Color primaryTealSoft = Color(0xFFFDF0ED);

  // Secondary & Accent Colors
  static const Color accentOrange = Color(0xFFE85028);
  static const Color accentOrangeLight = Color(0xFFFA7252);
  static const Color accentOrangeSoft = Color(0xFFFDF0ED);
  static const Color warmAmber = Color(0xFFD4A373);
  static const Color warmAmberSoft = Color(0xFFF7EFE6);
  static const Color successGreen = Color(0xFF5A7363);
  static const Color successGreenSoft = Color(0xFFEBF1ED);
  static const Color errorRed = Color(0xFFBA1A1A);
  static const Color errorRedSoft = Color(0xFFFFDAD6);

  // Typography & Dark Accents
  static const Color textPrimary = Color(0xFF1A1A1A); // Deep Ink Charcoal
  static const Color textSecondary = Color(0xFF6E6D7A); // Mid-tone Slate
  static const Color textMuted = Color(0xFF8A8998); // Muted Slate
  static const Color textWhite = Color(0xFFFFFFFF);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFFAF9F6); // Alabaster Cream
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceSecondary = Color(0xFFF5F4F0); // Pressed Stone
  static const Color border = Color(0xFFEAE8E3); // Soft Card Outline
  static const Color borderLight = Color(0xFFF0EEE9); // Subtle Hairline

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE85028), Color(0xFFFA7252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFE85028), Color(0xFFFA7252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C), Color(0xFFE85028)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFFFAF9F6), Color(0xFFF5F4F0)],
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

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: LocalLensColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
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

