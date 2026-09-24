import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/main.dart';

void main() {
  testWidgets('TravelerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalLensTravelerApp());
    expect(find.text('LocalLens'), findsOneWidget);
  });
}
