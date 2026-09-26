import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 2: Welcome Screen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // Brand Logo & Home Action at top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 44),
                  const LocalLensLogo(size: 38, showTagline: false),
                  IconButton(
                    icon: const Icon(Icons.home_outlined, color: LocalLensColors.primaryTeal, size: 26),
                    tooltip: 'Go to Home',
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title & Subtitle
              Text(
                'Where will you\ndiscover next?',
                textAlign: TextAlign.center,
                style: LocalLensTypography.displayLarge.copyWith(
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Find local experiences, build the perfect itinerary, and enjoy the journey.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium.copyWith(
                  color: LocalLensColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Hero Illustration Card
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  boxShadow: LocalLensDimensions.softCardShadow,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/onboarding/welcome_traveler.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const Spacer(),

              // Action: Sign In Button
              LocalLensPrimaryButton(
                text: 'Sign In',
                isOrange: true,
                onPressed: () {
                  context.push(AppRoutes.login);
                },
              ),
              const SizedBox(height: 12),

              // Action: Continue to Home
              LocalLensSecondaryButton(
                text: 'Continue to Home',
                isOutlined: true,
                icon: Icons.home_rounded,
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: LocalLensTypography.bodyMedium.copyWith(
                      color: LocalLensColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push(AppRoutes.signup);
                    },
                    child: Text(
                      'Sign Up',
                      style: LocalLensTypography.bodyMedium.copyWith(
                        color: LocalLensColors.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
