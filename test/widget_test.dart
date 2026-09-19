import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkiko/app.dart';

void main() {
  testWidgets('Parkiko Tactical Dispatch HUD launch test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: ParkikoApp(),
      ),
    );

    // Verify that the Login screen renders initial elements
    expect(find.text('Welcome to Parkiko'), findsOneWidget);
    expect(find.text('SIGN IN TO TERMINAL'), findsOneWidget);

    // Tap the sign-in button
    await tester.tap(find.text('SIGN IN TO TERMINAL'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify navigation into the Main Dashboard
    expect(find.text('PARKIKO'), findsWidgets);
    expect(find.text('PERFORMANCE OVERVIEW'), findsOneWidget);
  });
}
