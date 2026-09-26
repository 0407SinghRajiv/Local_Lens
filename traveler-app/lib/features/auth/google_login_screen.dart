import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 3: Google Login & Authentication Screen
class GoogleLoginScreen extends StatelessWidget {
  const GoogleLoginScreen({super.key});

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
              const SizedBox(height: 12),
              // Brand Logo
              const LocalLensLogo(size: 38, showTagline: false),
              const SizedBox(height: 20),

              // Title
              Text(
                'Let\'s make your trip\npersonal.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.displayMedium.copyWith(
                  height: 1.2,
                ),
              ),

              const Spacer(),

              // Traveler Character Illustration
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  boxShadow: LocalLensDimensions.softCardShadow,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/onboarding/login_traveler.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const Spacer(),

              // "Continue with Google" button
              Container(
                width: double.infinity,
                height: LocalLensDimensions.buttonHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.buttonRadius),
                  border: Border.all(color: LocalLensColors.border, width: 1.5),
                  boxShadow: LocalLensDimensions.softCardShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push(AppRoutes.tripSetup);
                    },
                    borderRadius: BorderRadius.circular(LocalLensDimensions.buttonRadius),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google Color Icon
                          Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 22,
                            height: 22,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.g_mobiledata_rounded,
                              color: Colors.redAccent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: LocalLensTypography.button.copyWith(
                              color: LocalLensColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // "Continue with Email"
              LocalLensPrimaryButton(
                text: 'Continue with Email',
                isOrange: false,
                onPressed: () {
                  context.push(AppRoutes.login);
                },
              ),

              const SizedBox(height: 20),

              // Disclaimer
              Text(
                'By continuing, you agree to our Terms & Privacy Policy',
                textAlign: TextAlign.center,
                style: LocalLensTypography.caption.copyWith(
                  color: LocalLensColors.textMuted,
                  fontSize: 11,
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
