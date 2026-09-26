import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/initialization_provider.dart';
import 'splash_controller.dart';
import 'widgets/animated_logo.dart';
import 'widgets/loading_dots.dart';
import 'widgets/travel_motif_painter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _motifController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: SplashAnimationConstants.entranceDuration,
    )..forward();

    _motifController = AnimationController(
      vsync: this,
      duration: SplashAnimationConstants.loopDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  void _navigateToRoute(String targetRoute) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final gradient = AppColors.splashGradient(brightness);
    final initStateAsync = ref.watch(initializationProvider);

    // If state is already initialized (e.g. cached or completed), navigate immediately
    initStateAsync.whenData((state) {
      if (state.isInitialized && !_hasNavigated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToRoute(state.targetRoute);
        });
      }
    });

    // Listen to future transitions
    ref.listen<AsyncValue<AppInitState>>(initializationProvider, (previous, next) {
      next.whenData((state) {
        if (state.isInitialized && !_hasNavigated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToRoute(state.targetRoute);
          });
        }
      });
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Travel Gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
          ),

          // Animated Flight Path Travel Motif
          AnimatedBuilder(
            animation: _motifController,
            builder: (context, _) => CustomPaint(
              painter: TravelMotifPainter(
                animationProgress: _motifController.value,
                brightness: brightness,
              ),
            ),
          ),

          // Centered Animated Logo + App Title
          Center(
            child: AnimatedLogo(
              controller: _entranceController,
            ),
          ),

          // Bottom Loading Dots or Error Message
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: SafeArea(
              child: Center(
                child: initStateAsync.when(
                  data: (state) => state.errorMessage != null
                      ? _buildErrorView(state.errorMessage!)
                      : const MinimalLoadingDots(),
                  loading: () => const MinimalLoadingDots(),
                  error: (error, _) => _buildErrorView(error.toString()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            ref.invalidate(initializationProvider);
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry Connection'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryDark,
            elevation: 2,
          ),
        ),
      ],
    );
  }
}
