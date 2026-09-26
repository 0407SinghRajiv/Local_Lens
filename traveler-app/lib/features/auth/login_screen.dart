import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/locallens_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
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
        : (error?.toString() ?? 'Failed to authenticate. Please check your credentials.');

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

  void _showForgotPasswordDialog() {
    _forgotEmailController.text = _emailController.text;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Reset Password',
                  style: LocalLensTypography.displayMedium.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your registered email address and we will send you a password reset link.',
                  style: LocalLensTypography.bodyMedium.copyWith(
                    color: LocalLensColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: LocalLensColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                    border: Border.all(color: LocalLensColors.border),
                  ),
                  child: TextField(
                    controller: _forgotEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'traveler@example.com',
                      prefixIcon: Icon(Icons.email_outlined, color: LocalLensColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                LocalLensPrimaryButton(
                  text: 'Send Reset Link',
                  isOrange: false,
                  onPressed: () async {
                    final email = _forgotEmailController.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid email.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final sent = await ref
                        .read(authControllerProvider.notifier)
                        .resetPassword(email);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            sent
                                ? 'Password reset email sent! Check your inbox.'
                                : 'Could not send reset email. Verify your email address.',
                          ),
                          backgroundColor: sent ? LocalLensColors.successGreen : Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
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
                  const SizedBox(height: 20),

                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: LocalLensTypography.displayLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to explore tailored travel experiences',
                    textAlign: TextAlign.center,
                    style: LocalLensTypography.bodyMedium.copyWith(
                      color: LocalLensColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email Field
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
                  const SizedBox(height: 14),

                  // Password Field
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
                        return null;
                      },
                    ),
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'Forgot Password?',
                        style: LocalLensTypography.caption.copyWith(
                          color: LocalLensColors.primaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sign In Button
                  LocalLensPrimaryButton(
                    text: 'Sign In',
                    isOrange: true,
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
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

                  const SizedBox(height: 28),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push(AppRoutes.signup);
                        },
                        child: Text(
                          'Sign Up',
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
