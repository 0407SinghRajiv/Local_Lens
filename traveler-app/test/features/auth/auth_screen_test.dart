import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/core/theme/app_theme.dart';
import 'package:traveler_app/features/auth/login_screen.dart';
import 'package:traveler_app/features/auth/signup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Screens Widget Tests', () {
    testWidgets('renders LoginScreen elements correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      // Verify header, inputs, and buttons
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to explore tailored travel experiences'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Continue as Guest Explorer'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty login submission', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      // Tap Sign In without filling form
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('renders SignupScreen with all fields and validation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SignupScreen(),
          ),
        ),
      );

      // Verify title & fields
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsNWidgets(2)); // Title + Button

      // Scroll to button and tap
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
