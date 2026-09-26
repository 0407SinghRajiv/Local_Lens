import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/core/theme/app_theme.dart';
import 'package:traveler_app/features/splash/splash_screen.dart';
import 'package:traveler_app/widgets/common/locallens_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget Tests', () {
    testWidgets('renders splash brand header and footer elements', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          ),
        ),
      );

      // Verify splash screen rendering
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LocalLensLogo), findsOneWidget);
      expect(find.text('LocalLens • Discover Your World'), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
