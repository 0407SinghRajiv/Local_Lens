import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/locallens_components.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Redirect directly to home screen
      context.go(AppRoutes.home);
    } else {
      _showErrorSnackBar();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      context.go(AppRoutes.home);
    } else {
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        _showErrorSnackBar();
      }
    }
  }

  void _showErrorSnackBar() {
    final authState = ref.read(authControllerProvider);
    final error = authState.error;
    final message = error is AuthException
        ? error.message
        : (error?.toString() ?? 'Registration failed. Please try again.');

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  const LocalLensLogo(size: 38, showTagline: false),
                  const SizedBox(height: 18),

                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: LocalLensTypography.displayLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join LocalLens and unlock personalized travel curation',
                    textAlign: TextAlign.center,
                    style: LocalLensTypography.bodyMedium.copyWith(
                      color: LocalLensColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  Container(
                    decoration: BoxDecoration(
                      color: LocalLensColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                      border: Border.all(color: LocalLensColors.border),
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      style: LocalLensTypography.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: LocalLensColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.person_outline_rounded, color: LocalLensColors.primaryTeal),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  Container(
                    decoration: BoxDecoration(
                      color: LocalLensColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                      border: Border.all(color: LocalLensColors.border),
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: LocalLensTypography.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: LocalLensColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.email_outlined, color: LocalLensColors.primaryTeal),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  Container(
                    decoration: BoxDecoration(
                      color: LocalLensColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                      border: Border.all(color: LocalLensColors.border),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: LocalLensTypography.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: LocalLensColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: LocalLensColors.primaryTeal),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: LocalLensColors.textMuted,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password is required';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm Password
                  Container(
                    decoration: BoxDecoration(
                      color: LocalLensColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                      border: Border.all(color: LocalLensColors.border),
                    ),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      style: LocalLensTypography.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(color: LocalLensColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_reset_rounded, color: LocalLensColors.primaryTeal),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: LocalLensColors.textMuted,
                          ),
                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Up Button
                  LocalLensPrimaryButton(
                    text: 'Create Account',
                    isOrange: true,
                    isLoading: _isLoading,
                    onPressed: _handleSignup,
                  ),

                  const SizedBox(height: 20),

                  // "OR" Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: LocalLensColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: LocalLensTypography.caption.copyWith(
                            color: LocalLensColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: LocalLensColors.border)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google Sign-In Button
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

                  const SizedBox(height: 24),

                  // Already have an account? Sign In
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push(AppRoutes.login);
                        },
                        child: Text(
                          'Sign In',
                          style: LocalLensTypography.bodyMedium.copyWith(
                            color: LocalLensColors.primaryTeal,
                            fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }
}
