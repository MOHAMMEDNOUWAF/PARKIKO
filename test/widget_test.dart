import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkiko/app.dart';

void main() {
  testWidgets('Parkiko Stitch Mint-Emerald app navigation and screens test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: ParkikoApp(),
      ),
    );

    // 1. Verify that the Login screen renders initial elements
    expect(find.text('Welcome to Parkiko'), findsOneWidget);
    expect(find.text('Sign In to Terminal'), findsOneWidget);

    // 2. Tap sign in button and navigate into Home Dashboard
    await tester.tap(find.text('Sign In to Terminal'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('PARKIKO'), findsWidgets);
    expect(find.text('PERFORMANCE OVERVIEW'), findsOneWidget);
    expect(find.text('Good Morning, Admin'), findsOneWidget);
    expect(find.text('Parking Occupancy'), findsOneWidget);

    // 3. Navigate to Operations tab
    await tester.tap(find.text('Operations'));
    await tester.pumpAndSettle();
    expect(find.text('Live Operations'), findsOneWidget);
    expect(find.text('Network Cap: 74%'), findsOneWidget);

    // 4. Navigate to Staff tab
    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
    expect(find.text('Staff Management'), findsOneWidget);
    expect(find.text('+ Add Staff'), findsOneWidget);

    // 5. Navigate to Payments tab
    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();
    expect(find.text('TOTAL COLLECTIONS'), findsOneWidget);
    expect(find.text('₹48,250'), findsOneWidget);

    // 6. Navigate to More tab
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('More Modules & System'), findsOneWidget);
    expect(find.text('Add New Site / Property'), findsOneWidget);
    expect(find.text('Sign Out of Terminal'), findsOneWidget);
  });
}
