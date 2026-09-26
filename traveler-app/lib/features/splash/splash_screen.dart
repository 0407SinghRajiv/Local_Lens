import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/initialization_provider.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 1: Splash Screen matching exact reference design
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Fallback timer in case provider takes slightly longer (1.8s)
    _fallbackTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted && !_hasNavigated) {
        _navigateToRoute(AppRoutes.welcome);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _navigateToRoute(String targetRoute) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();
    context.go(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final initStateAsync = ref.watch(initializationProvider);

    // If state is already initialized, navigate
    initStateAsync.whenData((state) {
      if (state.isInitialized && !_hasNavigated) {
        Timer(const Duration(milliseconds: 1400), () {
          if (mounted && !_hasNavigated) {
            _navigateToRoute(state.targetRoute == AppRoutes.onboarding ? AppRoutes.welcome : state.targetRoute);
          }
        });
      }
    });

    ref.listen<AsyncValue<AppInitState>>(initializationProvider, (previous, next) {
      next.whenData((state) {
        if (state.isInitialized && !_hasNavigated) {
          Timer(const Duration(milliseconds: 1400), () {
            if (mounted && !_hasNavigated) {
              _navigateToRoute(state.targetRoute == AppRoutes.onboarding ? AppRoutes.welcome : state.targetRoute);
            }
          });
        }
      });
    });

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Allow instant skip on tap
          _navigateToRoute(AppRoutes.welcome);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed Mountain Landscape & Traveler Hero Image
            Image.asset(
              'assets/images/onboarding/splash_traveler.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LocalLensColors.splashGradient,
                ),
              ),
            ),

            // Subtle gradient overlay for pristine brand logo contrast
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  stops: const [0.0, 0.22, 0.55, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Top Animated Brand Header (LocalLens + "See More. Experience Local.")
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const LocalLensLogo(
                          size: 42,
                          showTagline: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom subtle pulsing loading indicator
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 1
                                ? LocalLensColors.accentOrange
                                : LocalLensColors.primaryTeal,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
