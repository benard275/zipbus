import 'package:flutter_test/flutter_test.dart';
import 'package:zipbus2/main.dart';

void main() {
  testWidgets('ZipBus app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZipBusApp());

    // Verify that the splash screen is displayed initially.
    expect(find.text('ZipBus'), findsOneWidget);

    // Simulate navigation (you may need to adjust based on your splash screen logic).
    await tester.pumpAndSettle();

    // Add more test cases as needed for your app's UI.
  });
}