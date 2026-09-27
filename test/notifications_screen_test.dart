import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/admin/notifications/presentation/notifications_screen.dart';

void main() {
  testWidgets('NotificationsScreen renders metrics, filters, cards, and modal interactions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify TopBar header
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('3 New'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);

    // 2. Verify Metric Summary cards
    expect(find.text('NEW JOIN'), findsOneWidget);
    expect(find.text('SHIFT STARTS'), findsOneWidget);
    expect(find.text('SHIFT ENDS'), findsOneWidget);

    // 3. Verify Filter Pills
    expect(find.text('All 6'), findsOneWidget);
    expect(find.text('Shift Starts 4'), findsOneWidget);
    expect(find.text('Shift Ends 2'), findsOneWidget);
    expect(find.text('New Joins 1'), findsOneWidget);

    // 4. Test "Mark all read" action
    await tester.tap(find.text('Mark all read'));
    await tester.pump();
    expect(find.text('0 New'), findsOneWidget);
    expect(find.text('All notifications marked as read'), findsOneWidget);

    // 5. Test Filter Pills
    await tester.ensureVisible(find.text('Shift Starts 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shift Starts 4'));
    await tester.pumpAndSettle();
    expect(find.text('Shift Commenced • Suresh Kumar'), findsOneWidget);
    expect(find.text('Overtime Started • Amit Verma'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsNothing);

    await tester.ensureVisible(find.text('New Joins 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Joins 1'));
    await tester.pumpAndSettle();
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Driver Onboarding Approved • Karan Patel'), findsOneWidget);
    expect(find.text('Shift Commenced • Suresh Kumar'), findsNothing);

    // Reset to All
    await tester.ensureVisible(find.text('All 6'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All 6'));
    await tester.pumpAndSettle();
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Shift Commenced • Suresh Kumar'), findsOneWidget);

    // 6. Test "Assign Bay" Modal
    final assignBayBtn = find.widgetWithText(ElevatedButton, 'Assign Bay');
    await tester.tap(assignBayBtn);
    await tester.pumpAndSettle();

    expect(find.text('Assign Parking Bay'), findsOneWidget);
    expect(find.text('Valet: Rahul Sharma'), findsOneWidget);

    // Confirm assignment
    await tester.tap(find.text('Confirm Assignment'));
    await tester.pump();
    expect(find.text('Assigned to Gate 3'), findsOneWidget);

    // 7. Verify bottom navigation bar
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Let any remaining toast timer elapse cleanly
    await tester.pump(const Duration(seconds: 3));
  });
}
