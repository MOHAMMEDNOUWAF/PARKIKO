import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkiko/app.dart';

void main() {
  testWidgets('Parkiko Tactical Dispatch HUD launch test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ParkikoApp(),
      ),
    );

    // Verify that the title and key elements render
    expect(find.text('PARKIKO'), findsWidgets);
    expect(find.text('PERFORMANCE OVERVIEW'), findsOneWidget);
  });
}
