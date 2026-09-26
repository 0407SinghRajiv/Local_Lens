import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 3: Google Login & Authentication Screen
class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  ConsumerState<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final success = await ref.read(authNotifierProvider).signInWithGoogle();

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (!success) {
        final authState = ref.read(authStateProvider);
        if (authState.hasError) {
          _showErrorSnackBar(authState.errorMessage);
        }
      }
      // Note: Router reacts automatically to auth state change and redirects to /traveler/home
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _showErrorSnackBar([String? customMessage]) {
    final authState = ref.read(authStateProvider);
    final message = customMessage ??
        authState.errorMessage ??
        'Failed to authenticate with Google. Please try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand Logo
              const LocalLensLogo(size: 38, showTagline: false),
              const SizedBox(height: 16),

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
                width: 250,
                height: 250,
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
                    onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                    borderRadius: BorderRadius.circular(LocalLensDimensions.buttonRadius),
                    child: Center(
                      child: _isGoogleLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(LocalLensColors.primaryTeal),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Icon
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
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

              const SizedBox(height: 12),

              // "Continue with Email"
              LocalLensPrimaryButton(
                text: 'Continue with Email',
                isOrange: false,
                onPressed: () {
                  context.push(AppRoutes.login);
                },
              ),

              const SizedBox(height: 12),

              // Don't have an account? Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push(AppRoutes.signup);
                    },
                    child: Text(
                      'Sign Up',
                      style: LocalLensTypography.caption.copyWith(
                        color: LocalLensColors.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Disclaimer
              Text(
                'By continuing, you agree to our Terms & Privacy Policy',
                textAlign: TextAlign.center,
                style: LocalLensTypography.caption.copyWith(
                  color: LocalLensColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
