import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';

/// LocalLens Animated Splash Screen
///
/// Animation:
/// Local
///   ↓
/// LocalExperience
///   ↓
/// LocalLens
///   ↓
/// Welcome
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ============================================================
  // LOCAL LENS COLORS
  // ============================================================

  static const Color background = Color(0xFFFFFAF7);

  static const Color localColor = Color(0xFF4A3024);

  static const Color accentColor = Color(0xFFC9825E);

  static const Color softPeach = Color(0xFFF7E2D5);

  // ============================================================
  // ANIMATION CONTROLLERS
  // ============================================================

  late final AnimationController _logoController;
  late final AnimationController _exitController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  // ============================================================
  // LOGO STATE
  // ============================================================

  String _localText = '';

  String _suffix = '';

  bool _isExiting = false;

  bool _hasNavigated = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------------------
    // LOGO CONTROLLER
    // ------------------------------------------------------------

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    _logoScale = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // ------------------------------------------------------------
    // EXIT CONTROLLER
    // ------------------------------------------------------------

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _exitFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );

    _exitScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );

    // ------------------------------------------------------------
    // START
    // ------------------------------------------------------------

    _runSplashAnimation();
  }

  // ============================================================
  // SPLASH ANIMATION
  // ============================================================

  Future<void> _runSplashAnimation() async {
    // ==========================================================
    // STEP 1 — BUILD LOCAL LETTER BY LETTER
    // ==========================================================

    const word = 'Local';

    for (int i = 1; i <= word.length; i++) {
      if (!mounted || _hasNavigated) return;

      setState(() {
        _localText = word.substring(0, i);
      });

      await Future.delayed(
        const Duration(milliseconds: 120),
      );
    }

    // Small scale/fade animation.
    if (!mounted || _hasNavigated) return;

    await _logoController.forward();

    // ==========================================================
    // STEP 2 — LOCAL EXPERIENCE
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 200),
    );

    if (!mounted || _hasNavigated) return;

    setState(() {
      _suffix = 'Experience';
    });

    // Keep LocalExperience visible.
    await Future.delayed(
      const Duration(milliseconds: 1300),
    );

    // ==========================================================
    // STEP 3 — EXPERIENCE → LENS
    // ==========================================================

    if (!mounted || _hasNavigated) return;

    // Direct replacement.
    //
    // Because the ValueKey changes from
    //
    // ValueKey('Experience')
    //
    // to
    //
    // ValueKey('Lens')
    //
    // AnimatedSwitcher will animate the replacement.
    setState(() {
      _suffix = 'Lens';
    });

    // ==========================================================
    // STEP 4 — HOLD LOCAL LENS
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 1500),
    );

    // ==========================================================
    // STEP 5 — EXIT
    // ==========================================================

    if (!mounted || _hasNavigated) return;

    setState(() {
      _isExiting = true;
    });

    await _exitController.forward();

    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    // Navigate to splash root and let GoRouter's redirect decide
    // whether to go to /welcome (unauthenticated) or /traveler/home (authenticated).
    context.go(AppRoutes.splash);
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoFade.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // ==================================================
                // LOCAL
                // ==================================================

                Text(
                  _localText,
                  style: const TextStyle(
                    color: localColor,
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2.6,
                    height: 1,
                  ),
                ),

                // ==================================================
                // EXPERIENCE → LENS
                // ==================================================

                AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 500,
                  ),

                  reverseDuration: const Duration(
                    milliseconds: 400,
                  ),

                  switchInCurve: Curves.easeOutCubic,

                  switchOutCurve: Curves.easeInCubic,

                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    final slideAnimation = Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slideAnimation,
                        child: child,
                      ),
                    );
                  },

                  child: _suffix.isEmpty
                      ? const SizedBox(
                          key: ValueKey('empty'),
                        )
                      : Text(
                          _suffix,
                          key: ValueKey(_suffix),
                          style: const TextStyle(
                            color: accentColor,
                            fontSize: 46,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -2.2,
                            height: 1,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: AnimatedBuilder(
        animation: _exitController,

        builder: (context, child) {
          return Opacity(
            opacity: _exitFade.value,

            child: Transform.scale(
              scale: _exitScale.value,

              child: child,
            ),
          );
        },

        child: Stack(
          fit: StackFit.expand,

          children: [
            // ==================================================
            // BACKGROUND
            // ==================================================

            const ColoredBox(
              color: background,
            ),

            // ==================================================
            // SOFT PEACH BRAND GLOW
            // ==================================================

            Center(
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 220,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: softPeach.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // LOGO
            // ==================================================

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: FittedBox(
                  fit: BoxFit.scaleDown,

                  child: _buildLogo(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _logoController.dispose();
    _exitController.dispose();

    super.dispose();
  }
}