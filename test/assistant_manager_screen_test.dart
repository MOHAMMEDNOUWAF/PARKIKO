import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/admin/staff/models/staff_model.dart';
import 'package:parkiko/features/admin/staff/services/staff_manager.dart';
import 'package:parkiko/features/managers/assistant manager/assistant_manager.dart';

void main() {
  group('Assistant Manager Screen Tests', () {
    testWidgets('AssistantManagerScreen defaults to clean empty state without hardcoded cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verifies clean Deck Clear state for unified single listing
      expect(find.text('Deck Clear • No Parked Vehicles'), findsOneWidget);
      expect(
        find.text('Parked vehicles and customer retrieval requests will appear here in real time.'),
        findsOneWidget,
      );
      expect(find.text('Audi A6 TFSI Matrix'), findsNothing);
      expect(find.text('Hyundai Ioniq 5 EV'), findsNothing);
    });

    testWidgets('Renders unified PARKED VEHICLES listing and site info when seeded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(seedDemoData: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Top App Bar
      expect(find.text('Parkiko'), findsOneWidget);
      expect(find.text('ASST. MGR'), findsOneWidget);
      expect(find.text('Grand Hyatt • Deck B1'), findsOneWidget);
      expect(find.text('Deck Live'), findsOneWidget);

      // Single listing header
      expect(find.textContaining('PARKED VEHICLES'), findsOneWidget);

      // Retrieval requested vehicles appear first
      expect(find.text('BMW X5 xDrive40i'), findsOneWidget);
      expect(find.text('Mercedes GLC 300'), findsOneWidget);

      // Parked vehicles in the single listing
      expect(find.text('Audi A6 TFSI Matrix'), findsOneWidget);
      expect(find.text('KA 03 MX 9012'), findsOneWidget);
      expect(find.text('Hyundai Ioniq 5 EV'), findsOneWidget);
      expect(find.text('MH 12 TC 5500'), findsOneWidget);

      // Bottom Navigation
      expect(find.text('Retrieval & Dispatch'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('Initiating retrieval makes card come FIRST and displays elapsed retrieval timer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(seedDemoData: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially 2 retrieval requested cards and 2 parked cards
      expect(find.textContaining('RETRIEVAL INITIATED'), findsNWidgets(2));
      expect(find.text('PARKED & SECURED'), findsNWidgets(2));

      // Tap 'Initiate Vehicle Retrieval' on Audi A6
      final retrieveBtn = find.text('Initiate Vehicle Retrieval').first;
      await tester.ensureVisible(retrieveBtn);
      await tester.tap(retrieveBtn);
      await tester.pump();

      // Now 3 cards have RETRIEVAL INITIATED alert and elapsed timer
      expect(find.textContaining('⏱️ RETRIEVAL INITIATED'), findsNWidgets(3));

      // Ticking timer updates elapsed seconds
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('RETRIEVAL INITIATED'), findsNWidgets(3));
    });

    testWidgets('Allows selecting driver by ID for respected site and dispatching',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      StaffManager.instance.clearStaff();
      StaffManager.instance.addStaff(
        const StaffModel(
          id: '108',
          name: 'Rohan Sharma',
          phone: '+91 98765 10800',
          role: 'driver',
          assignedSite: 'Grand Hyatt • Deck B1',
          password: '1234',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(
            assignedSite: 'Grand Hyatt • Deck B1',
            seedDemoData: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Quick ID chip for driver 108 on the first retrieval card
      final chip108 = find.textContaining('ID: 108').first;
      await tester.ensureVisible(chip108);
      await tester.tap(chip108);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dispatch button updates to show driver ID
      final dispatchBtn = find.text('Dispatch Runner [ID: 108] to Bay').first;
      await tester.ensureVisible(dispatchBtn);
      expect(dispatchBtn, findsOneWidget);

      // Tap dispatch
      await tester.tap(dispatchBtn);
      await tester.pump();

      // Toast confirms dispatch
      expect(find.textContaining('Runner PK-108 dispatched!'), findsOneWidget);

      // Wait for auto-transition to History tab
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 200));

      // History tab is now visible
      expect(find.text('DISPATCHED & COMPLETED LOG'), findsOneWidget);
    });

    testWidgets('Tapping logout button shows confirmation dialog and fires onLogout callback',
        (WidgetTester tester) async {
      bool loggedOut = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantManagerScreen(
            onLogout: () {
              loggedOut = true;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Logout button exists in top app bar
      final logoutBtn = find.byKey(const Key('assistant_manager_logout_button'));
      expect(logoutBtn, findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Tap Logout button
      await tester.tap(logoutBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmation dialog should be displayed
      expect(find.text('Sign Out'), findsOneWidget);
      expect(
        find.text('Are you sure you want to log out of the Assistant Manager terminal?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel button test
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(loggedOut, isFalse);
      expect(find.text('Sign Out'), findsNothing);

      // Tap Logout button again
      await tester.tap(logoutBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Tap confirm Logout in dialog
      final dialogLogoutBtn = find.widgetWithText(ElevatedButton, 'Logout');
      expect(dialogLogoutBtn, findsOneWidget);
      await tester.tap(dialogLogoutBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(loggedOut, isTrue);
    });

    testWidgets('Only shows same-site drivers in driver selector by ID',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      StaffManager.instance.clearStaff();
      StaffManager.instance.addStaff(
        const StaffModel(
          id: '108',
          name: 'Rahul V.',
          phone: '+91 98765 43210',
          role: 'driver',
          assignedSite: 'Grand Hyatt • Deck B1',
          password: '1234',
        ),
      );
      StaffManager.instance.addStaff(
        const StaffModel(
          id: '082',
          name: 'Farhan K.',
          phone: '+91 98765 08200',
          role: 'driver',
          assignedSite: 'Grand Hyatt • Deck B1',
          password: '1234',
        ),
      );
      StaffManager.instance.addStaff(
        const StaffModel(
          id: '044',
          name: 'Amit S.',
          phone: '+91 98765 04400',
          role: 'driver',
          assignedSite: 'Terminal 2 • Valet Desk',
          password: '1234',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(
            assignedSite: 'Grand Hyatt • Deck B1',
            seedDemoData: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Quick chips should include same site drivers (108 and 082)
      expect(find.textContaining('108'), findsWidgets);
      expect(find.textContaining('082'), findsWidgets);

      // Different site driver (044 / Amit) must NOT appear in quick chips
      expect(find.textContaining('Amit'), findsNothing);
      expect(find.textContaining('044'), findsNothing);
    });
  });
}
