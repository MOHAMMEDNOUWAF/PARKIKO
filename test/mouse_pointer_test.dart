import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/admin/staff/presentation/add_staff_screen.dart';

void main() {
  testWidgets('AddStaffScreen push transition with pointer hover', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1536, 730));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: Scaffold(
          body: ElevatedButton(
            onPressed: () {
              navKey.currentState!.push(
                MaterialPageRoute(builder: (_) => const AddStaffScreen()),
              );
            },
            child: const Text('Open Add Staff'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Add Staff'));
    await tester.pump(); // Start transition

    // Simulate mouse move during transition (like MouseTracker on web)
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(const Offset(450, 350));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(const Offset(500, 400));
    await tester.pumpAndSettle();

    expect(find.text('Add New Staff'), findsOneWidget);
    expect(find.text('Upload Staff Photo'), findsOneWidget);
    await gesture.removePointer();
  });
}
