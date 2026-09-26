import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/core/routes/app_routes.dart';
import 'package:traveler_app/main.dart';
import 'package:traveler_app/providers/initialization_provider.dart';

void main() {
  testWidgets('TravelerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initializationProvider.overrideWith(
            (ref) async => const AppInitState(
              isInitialized: false,
              targetRoute: AppRoutes.splash,
            ),
          ),
        ],
        child: const LocalLensTravelerApp(),
      ),
    );
    await tester.pump();
    expect(find.text('LocalLens'), findsOneWidget);
  });
}
