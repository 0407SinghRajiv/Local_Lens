import 'package:flutter/material.dart';
import '../splash_controller.dart';

class AnimatedLogo extends StatelessWidget {
  final AnimationController controller;
  final String appName;
  final String tagline;
  final double logoSize;

  const AnimatedLogo({
    super.key,
    required this.controller,
    this.appName = 'LocalLens',
    this.tagline = 'Your Intelligent Travel Companion',
    this.logoSize = 130.0,
  });

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: SplashAnimationConstants.logoScaleInterval,
      ),
    );

    final logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: SplashAnimationConstants.logoFadeInterval,
      ),
    );

    final titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: SplashAnimationConstants.titleFadeInterval,
      ),
    );

    final titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: SplashAnimationConstants.titleSlideInterval,
      ),
    );

    final taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: SplashAnimationConstants.taglineFadeInterval,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Centered Animated Logo with Scale + Fade
        ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: logoFadeAnimation,
            child: Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      size: 64,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // App Name Staggered Fade-in + Slide-up
        SlideTransition(
          position: titleSlideAnimation,
          child: FadeTransition(
            opacity: titleFadeAnimation,
            child: Text(
              appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle / Tagline
        FadeTransition(
          opacity: taglineFadeAnimation,
          child: Text(
            tagline,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}
