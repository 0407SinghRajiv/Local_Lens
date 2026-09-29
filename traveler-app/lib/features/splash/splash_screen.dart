import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

/// LocalLens Premium & Ultra-Smooth Animated Splash Screen (Powered by flutter_animate)
///
/// Flow:
/// 1. Runs EXACTLY ONCE per app launch (guaranteed single execution)
/// 2. "LocalExperience" enters with smooth spring curve (Local in deep brown, Experience in terracotta)
/// 3. "Experience" morphs smoothly into "Lens" over 450ms with scale-slide-fade transition
/// 4. Holds "LocalLens" before seamless redirect to /traveler/home or /welcome
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Color background = Color(0xFFFFFAF7);
  static const Color localColor = Color(0xFF4A3024);
  static const Color accentColor = Color(0xFFC9825E);
  static const Color softPeach = Color(0xFFF7E2D5);

  static bool _hasSplashRun = false;
  bool _showLens = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    if (_hasSplashRun) {
      // If splash animation already executed, skip re-play and navigate immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        _navigateNext();
      });
    } else {
      _hasSplashRun = true;
      _startSplashTimeline();
    }
  }

  void _navigateNext() {
    final authState = ref.read(authNotifierProvider).state;
    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.travelerHome);
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  Future<void> _startSplashTimeline() async {
    // 1. Show "LocalExperience" for 1100ms so initial brand mark is clearly readable
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted || _hasNavigated) return;

    // 2. Trigger ultra-smooth transition: "Experience" -> "Lens"
    setState(() {
      _showLens = true;
    });

    // 3. Hold "LocalLens" for 1200ms for readable brand presentation
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    _navigateNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Color Layer
          const ColoredBox(color: background),

          // Atithi Devo Bhava Watermark Background (Subtle Brand Anchor)
          Positioned.fill(
            child: Opacity(
              opacity: 0.14,
              child: Image.asset(
                'assets/images/atithi_devo_bhava_logo.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic),

          // Soft Peach Ambient Brand Glow Container
          Center(
            child: Container(
              width: 360,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: softPeach.withValues(alpha: 0.35),
              ),
            ),
          )
              .animate()
              .scale(
                duration: 700.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0.65, 0.65),
                end: const Offset(1.0, 1.0),
              )
              .fadeIn(duration: 450.ms),

          // Main Animated Logo Stack (LocalExperience -> LocalLens)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // "Local" Text Header
                    const Text(
                      'Local',
                      style: TextStyle(
                        color: localColor,
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2.6,
                        height: 1.0,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
                        .slideX(begin: -0.10, end: 0.0, duration: 450.ms, curve: Curves.easeOutCubic),

                    const SizedBox(width: 4),

                    // Dynamic Smooth Transition Container: "Experience" -> "Lens"
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      reverseDuration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.15, 0.0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: !_showLens
                          ? Text(
                              'Experience',
                              key: const ValueKey('suffix_experience'),
                              style: const TextStyle(
                                color: accentColor,
                                fontSize: 52,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -2.2,
                                height: 1.0,
                              ),
                            )
                          : Text(
                              'Lens',
                              key: const ValueKey('suffix_lens'),
                              style: const TextStyle(
                                color: accentColor,
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2.2,
                                height: 1.0,
                              ),
                            )
                              .animate()
                              .shimmer(duration: 650.ms, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                duration: 500.ms,
                curve: Curves.easeOutCubic,
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.0, 1.0),
              ),
        ],
      ),
    );
  }
}