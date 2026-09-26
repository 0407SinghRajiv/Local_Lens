import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/itinerary_provider.dart';

/// Screen: AI-style Loading & Itinerary Generation Screen
class ItineraryGeneratingScreen extends ConsumerStatefulWidget {
  const ItineraryGeneratingScreen({super.key});

  @override
  ConsumerState<ItineraryGeneratingScreen> createState() => _ItineraryGeneratingScreenState();
}

class _ItineraryGeneratingScreenState extends ConsumerState<ItineraryGeneratingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  int _messageIndex = 0;
  Timer? _messageTimer;
  Timer? _fallbackTimer;
  bool _hasNavigated = false;

  final List<String> _loadingMessages = [
    'Understanding your trip...',
    'Finding experiences & hidden gems...',
    'Checking your time window...',
    'Balancing your budget...',
    'Building your local itinerary...',
    'Almost ready...',
  ];

  final List<Map<String, dynamic>> _orbitIcons = [
    {'icon': Icons.place_rounded, 'color': LocalLensColors.accentOrange, 'label': 'Pins'},
    {'icon': Icons.restaurant_rounded, 'color': LocalLensColors.warmAmber, 'label': 'Food'},
    {'icon': Icons.camera_alt_rounded, 'color': LocalLensColors.primaryTeal, 'label': 'Photos'},
    {'icon': Icons.route_rounded, 'color': Color(0xFF6366F1), 'label': 'Route'},
    {'icon': Icons.account_balance_rounded, 'color': Color(0xFF8B5CF6), 'label': 'Heritage'},
    {'icon': Icons.backpack_rounded, 'color': LocalLensColors.successGreen, 'label': 'Backpack'},
    {'icon': Icons.coffee_rounded, 'color': Color(0xFFB45309), 'label': 'Coffee'},
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    // Rotate messages every 400ms
    _messageTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      }
    });

    // Post-frame callback for generation initiation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneration();
    });

    // Hard fallback safety timer (2.2s max) to guarantee the screen never gets stuck
    _fallbackTimer = Timer(const Duration(milliseconds: 2200), () {
      _navigateToResult();
    });
  }

  Future<void> _startGeneration() async {
    try {
      final itinerary = await ref.read(itineraryProvider.notifier).generateItinerary();
      if (!mounted) return;

      if (itinerary != null) {
        _navigateToResult();
      } else {
        _navigateToResult();
      }
    } catch (_) {
      if (mounted) {
        _navigateToResult();
      }
    }
  }

  void _navigateToResult() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    // Use context.go to ensure clean, deterministic route navigation
    context.go(AppRoutes.aiItineraryResult);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _messageTimer?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryProvider);
    final destination = state.locationMode == LocationMode.exact
        ? state.displayAddress
        : (state.destination.isNotEmpty ? state.destination : 'Panvel');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Traveler & Orbiting Elements
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Glow Rings
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 220 + (_pulseController.value * 30),
                          height: 220 + (_pulseController.value * 30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LocalLensColors.primaryTeal.withValues(alpha: 0.08 * (1 - _pulseController.value * 0.5)),
                          ),
                        );
                      },
                    ),

                    // Orbiting Icons Ring
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        final angle = _rotationController.value * 2 * pi;
                        return Stack(
                          children: List.generate(_orbitIcons.length, (index) {
                            final itemAngle = angle + (index * 2 * pi / _orbitIcons.length);
                            const radius = 110.0;
                            final x = radius * cos(itemAngle);
                            final y = radius * sin(itemAngle);
                            final item = _orbitIcons[index];

                            return Transform.translate(
                              offset: Offset(x, y),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: (item['color'] as Color).withValues(alpha: 0.5), width: 1.5),
                                  boxShadow: LocalLensDimensions.floatingShadow,
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: item['color'] as Color,
                                  size: 20,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    // Center Traveler Character Illustration
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LocalLensColors.primaryTealSoft,
                        boxShadow: LocalLensDimensions.softCardShadow,
                        border: Border.all(color: LocalLensColors.primaryTeal, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/illustrations/ai_robot_traveler.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.explore_rounded,
                            size: 64,
                            color: LocalLensColors.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Destination Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: LocalLensColors.primaryTealSoft,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_rounded, color: LocalLensColors.primaryTeal, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      destination,
                      style: LocalLensTypography.caption.copyWith(
                        color: LocalLensColors.primaryTealDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Title & Dynamic Rotating Message
              Text(
                'Crafting Your Perfect Day',
                style: LocalLensTypography.displayMedium.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _loadingMessages[_messageIndex],
                  key: ValueKey<int>(_messageIndex),
                  textAlign: TextAlign.center,
                  style: LocalLensTypography.bodyMedium.copyWith(
                    color: LocalLensColors.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Animated Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: LocalLensColors.surfaceSecondary,
                        valueColor: const AlwaysStoppedAnimation<Color>(LocalLensColors.primaryTeal),
                        minHeight: 8,
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              // Quick skip / View button
              TextButton(
                onPressed: _navigateToResult,
                child: Text(
                  'Tap to view itinerary →',
                  style: LocalLensTypography.caption.copyWith(
                    color: LocalLensColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
