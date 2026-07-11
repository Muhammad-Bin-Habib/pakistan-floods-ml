import 'package:flutter_test/flutter_test.dart';
import 'package:pakistan_floods_app/main.dart';

void main() {
  testWidgets('Splash Screen compile check smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FloodGuardApp());

    // Verify that the splash screen title is rendered.
    expect(find.byType(FloodGuardApp), findsOneWidget);

    // Pump timer duration to flush the splash screen navigator transition.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
