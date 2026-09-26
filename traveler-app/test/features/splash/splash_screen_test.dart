import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:traveler_app/core/routes/app_routes.dart';
import 'package:traveler_app/core/theme/app_theme.dart';
import 'package:traveler_app/features/splash/splash_screen.dart';
import 'package:traveler_app/features/splash/widgets/animated_logo.dart';
import 'package:traveler_app/features/splash/widgets/loading_dots.dart';
import 'package:traveler_app/providers/initialization_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget Tests', () {
    testWidgets('renders animated logo, app name, and loading dots', (tester) async {
      final completer = Completer<AppInitState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializationProvider.overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          ),
        ),
      );

      // Verify initial rendering of widgets
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(AnimatedLogo), findsOneWidget);
      expect(find.text('LocalLens'), findsOneWidget);
      expect(find.text('Your Intelligent Travel Companion'), findsOneWidget);
      expect(find.byType(MinimalLoadingDots), findsOneWidget);

      // Advance animation frames to allow entrance curves to animate
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('LocalLens'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('triggers navigation to home route on successful initialization', (tester) async {
      String currentRoute = AppRoutes.splash;

      final testRouter = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) {
              currentRoute = AppRoutes.splash;
              return const SplashScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) {
              currentRoute = AppRoutes.home;
              return const Scaffold(body: Text('Home Screen Loaded'));
            },
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) {
              currentRoute = AppRoutes.onboarding;
              return const Scaffold(body: Text('Onboarding Screen Loaded'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializationProvider.overrideWith(
              (ref) async => const AppInitState(
                isInitialized: true,
                targetRoute: AppRoutes.home,
                isAuthenticated: true,
              ),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      // Advance frames to trigger state listener and router transition
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify navigation transitioned to /home
      expect(currentRoute, AppRoutes.home);
      expect(find.text('Home Screen Loaded'), findsOneWidget);
    });

    testWidgets('navigates to onboarding route when isFirstLaunch is true', (tester) async {
      String currentRoute = AppRoutes.splash;

      final testRouter = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) {
              currentRoute = AppRoutes.splash;
              return const SplashScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) {
              currentRoute = AppRoutes.onboarding;
              return const Scaffold(body: Text('Onboarding Screen Loaded'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializationProvider.overrideWith(
              (ref) async => const AppInitState(
                isInitialized: true,
                targetRoute: AppRoutes.onboarding,
                isFirstLaunch: true,
              ),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentRoute, AppRoutes.onboarding);
      expect(find.text('Onboarding Screen Loaded'), findsOneWidget);
    });

    testWidgets('displays error and retry button when initialization fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializationProvider.overrideWith(
              (ref) async => AppInitState.error('Network connection timeout'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Network connection timeout'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
