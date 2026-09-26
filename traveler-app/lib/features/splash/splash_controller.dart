import 'package:flutter/material.dart';

class SplashAnimationConstants {
  SplashAnimationConstants._();

  static const Duration entranceDuration = Duration(milliseconds: 1200);
  static const Duration loopDuration = Duration(seconds: 4);

  // Logo animation intervals
  static const Interval logoScaleInterval = Interval(0.0, 0.65, curve: Curves.easeOutBack);
  static const Interval logoFadeInterval = Interval(0.0, 0.50, curve: Curves.easeIn);

  // App Name staggered entrance (~300ms after logo)
  static const Interval titleFadeInterval = Interval(0.35, 0.85, curve: Curves.easeOut);
  static const Interval titleSlideInterval = Interval(0.35, 0.85, curve: Curves.easeOutCubic);

  // Tagline animation interval
  static const Interval taglineFadeInterval = Interval(0.55, 1.0, curve: Curves.easeOut);
}
