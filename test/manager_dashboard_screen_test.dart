import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/managers/manager/manager.dart';
import 'package:parkiko/features/admin/staff/models/staff_model.dart';

void main() {
  group('Manager Screen & Login Tests', () {
    testWidgets('ManagerLoginScreen: Validates credentials and logs in successfully', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      StaffModel? loggedInManager;

      await tester.pumpWidget(
        MaterialApp(
          home: ManagerLoginScreen(
            onLoginSuccess: (mgr) => loggedInManager = mgr,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header Elements
      expect(find.text('Parkiko Deck Manager'), findsOneWidget);
      expect(find.text('Floor Operations & Payment Terminal'), findsOneWidget);

      // Attempt submit without credentials
      await tester.tap(find.text('Login to Manager Deck'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your Manager User ID'), findsOneWidget);

      // Enter valid Manager ID and Password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'MGR-101');
      await tester.enterText(textFields.at(1), '1234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login to Manager Deck'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(loggedInManager, isNotNull);
      expect(loggedInManager!.id, 'MGR-101');
    });

    testWidgets('ManagerDashboardScreen: Displays driver intake details, processes payments, and triggers vehicle retrieval', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final manager = const StaffModel(
        id: 'MGR-101',
        name: 'Vikram Malhotra',
        phone: '+91 98200 12345',
        role: 'manager',
        assignedSite: 'Grand Hyatt & Convention',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ManagerDashboardScreen(
            currentManager: manager,
            seedDemoData: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar & location checks
      expect(find.text('DECK MGR'), findsOneWidget);
      expect(find.text('Grand Hyatt & Convention'), findsOneWidget);
      expect(find.text('Live Sync'), findsOneWidget);

      // Metric tiles check
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(find.text('Drivers'), findsOneWidget);

      // Vehicle card checks (ensuring driver intake details appear)
      expect(find.text('UNPAID VEHICLES (PENDING COLLECTION)'), findsOneWidget);
      expect(find.text('BMW X5 xDrive'), findsWidgets);
      expect(find.text('MH 01 DX 4022'), findsWidgets);
      expect(find.text('+91 98201 44521'), findsWidgets);
      expect(find.textContaining('Rahul Verma (ID: ST-108)'), findsWidgets);

      // 1. Test Collect Payment modal
      final collectPaymentButtons = find.text('Collect Payment');
      expect(collectPaymentButtons, findsWidgets);
      await tester.tap(collectPaymentButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Collect Valet Payment'), findsOneWidget);
      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('Cash Collection'), findsOneWidget);
      expect(find.text('Online / UPI'), findsOneWidget);

      // Tap Cash Collection
      await tester.tap(find.text('Cash Collection'));
      await tester.pumpAndSettle();

      // Confirm payment
      await tester.tap(find.textContaining('Confirm ₹250 Cash Payment'));
      await tester.pumpAndSettle();

      // Verify status morphed to PAID and shows Vehicle Retrieval
      expect(find.text('PAID (CASH)'), findsWidgets);
      expect(find.text('Vehicle Retrieval'), findsWidgets);

      // 2. Test Vehicle Retrieval
      await tester.tap(find.text('Vehicle Retrieval').first);
      await tester.pumpAndSettle();

      expect(find.text('RETRIEVAL DISPATCHED'), findsWidgets);
      expect(find.text('Runner Dispatched'), findsWidgets);

      // 3. Test Navigation tabs
      await tester.tap(find.text('History'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'), warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('ParkikoManagerApp boots successfully', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const ParkikoManagerApp());
      await tester.pumpAndSettle();

      expect(find.byType(ManagerLoginScreen), findsOneWidget);
    });
  });
}
