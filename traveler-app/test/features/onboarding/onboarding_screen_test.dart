import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:traveler_app/core/routes/app_routes.dart';
import 'package:traveler_app/features/onboarding/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen Carousel Tests', () {
    testWidgets('renders first carousel slide with Explore button and LocalLens badge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Verify brand header and skip button
      expect(find.text('LocalLens'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Verify first slide content (54506)
      expect(find.text('Explore Untamed\nDestinations'), findsOneWidget);
      expect(find.text('DISCOVER & WANDER'), findsOneWidget);

      // Verify Explore button
      expect(find.text('Explore'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('swiping carousel changes to second slide with 54511 content', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Swipe left on PageView to transition to 2nd slide
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Verify second slide content (54511)
      expect(find.text('Tailored Journeys\nat Your Fingertips'), findsOneWidget);
      expect(find.text('SMART ITINERARIES'), findsOneWidget);
    });

    testWidgets('tapping Explore button navigates to home route', (tester) async {
      String navigatedRoute = AppRoutes.onboarding;

      final testRouter = GoRouter(
        initialLocation: AppRoutes.onboarding,
        routes: [
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) {
              navigatedRoute = AppRoutes.onboarding;
              return const OnboardingScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) {
              navigatedRoute = AppRoutes.home;
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Explore button
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      expect(navigatedRoute, AppRoutes.home);
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });
}
