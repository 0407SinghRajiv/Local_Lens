import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 9: AI Personalization & Itinerary Building Screen
class AIPersonalizationScreen extends StatefulWidget {
  const AIPersonalizationScreen({super.key});

  @override
  State<AIPersonalizationScreen> createState() => _AIPersonalizationScreenState();
}

class _AIPersonalizationScreenState extends State<AIPersonalizationScreen> {
  int _completedSteps = 0;
  Timer? _timer;

  final List<String> _steps = [
    'Understanding your preferences',
    'Finding local experiences',
    'Checking time & budget',
    'Building your itinerary',
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_completedSteps < _steps.length) {
        setState(() {
          _completedSteps++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Building your\nperfect trip...',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 24),

              // Animated Checklist
              ...List.generate(_steps.length, (index) {
                final isDone = index < _completedSteps;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? LocalLensColors.successGreen
                              : LocalLensColors.surfaceSecondary,
                        ),
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        _steps[index],
                        style: LocalLensTypography.bodyLarge.copyWith(
                          fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                          color: isDone
                              ? LocalLensColors.textPrimary
                              : LocalLensColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Spacer(),

              // AI Planning Hero Illustration
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                    boxShadow: LocalLensDimensions.softCardShadow,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/illustrations/ai_robot_traveler.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Explore Now CTA
              LocalLensPrimaryButton(
                text: 'Explore Your Trip',
                isOrange: true,
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
