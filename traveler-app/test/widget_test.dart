import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/main.dart';

void main() {
  testWidgets('TravelerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LocalLensTravelerApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(LocalLensTravelerApp), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
