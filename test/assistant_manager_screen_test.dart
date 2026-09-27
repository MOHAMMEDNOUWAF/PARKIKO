import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/managers/assistant manager/assistant_manager.dart';

void main() {
  group('Assistant Manager Screen Tests', () {
    testWidgets('Renders all header elements, metrics, urgent & parked vehicles faithfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Top App Bar
      expect(find.text('Parkiko'), findsOneWidget);
      expect(find.text('ASST. MGR'), findsOneWidget);
      expect(find.text('Grand Hyatt • Deck B1'), findsOneWidget);
      expect(find.text('Deck Live'), findsOneWidget);

      // 3 Metrics
      expect(find.text('Retrievals'), findsOneWidget);
      expect(find.text('2 Urgent'), findsOneWidget);
      expect(find.text('Parked'), findsOneWidget);
      expect(find.text('14 Ready'), findsOneWidget);
      expect(find.text('Runners'), findsOneWidget);
      expect(find.text('5 Idle'), findsOneWidget);

      // Section 1: Urgent
      expect(find.text('URGENT RETRIEVALS (2)'), findsOneWidget);
      expect(find.text('Avg wait: 02:10s'), findsOneWidget);
      expect(find.text('BMW X5 xDrive40i'), findsOneWidget);
      expect(find.text('MH 01 DX 4022'), findsOneWidget);
      expect(find.text('Mercedes GLC 300'), findsOneWidget);
      expect(find.text('DL 01 AA 7700'), findsOneWidget);

      // Section 2: Parked
      expect(find.text('PARKED BY DRIVER (READY)'), findsOneWidget);
      expect(find.text('14 Total Bayed'), findsOneWidget);
      expect(find.text('Audi A6 TFSI Matrix'), findsOneWidget);
      expect(find.text('KA 03 MX 9012'), findsOneWidget);
      expect(find.text('Hyundai Ioniq 5 EV'), findsOneWidget);
      expect(find.text('EV Charging'), findsOneWidget);

      // Bottom Navigation
      expect(find.text('Retrieval & Dispatch'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('Quick chip selection updates runner input and enables dispatch button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially dispatch button is disabled with prompt
      expect(find.text('Enter Runner to Dispatch'), findsWidgets);

      // Tap Quick runner chip 'PK-108 (Rohan)'
      final rohanChip = find.text('PK-108 (Rohan)').first;
      await tester.tap(rohanChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Button updates to active emerald state with runner ID
      expect(find.text('Dispatch Runner PK-108'), findsOneWidget);

      // Tap dispatch
      await tester.tap(find.text('Dispatch Runner PK-108'));
      await tester.pump();

      // Toast appears
      expect(find.textContaining('Runner PK-108 dispatched!'), findsOneWidget);

      // BMW X5 should now be removed from urgent queue
      expect(find.text('BMW X5 xDrive40i'), findsNothing);
      expect(find.text('URGENT RETRIEVALS (1)'), findsOneWidget);

      // Wait for auto-transition to History tab
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 200));

      // Should be on History view
      expect(find.text('DISPATCHED & COMPLETED LOG'), findsOneWidget);
      expect(find.text('BMW X5 xDrive40i'), findsOneWidget);
      expect(find.text('Runner: '), findsWidgets);
    });

    testWidgets('Triggering retrieval from parked list adds item to urgent queue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('URGENT RETRIEVALS (2)'), findsOneWidget);

      // Find Trigger Retrieval on Audi A6 and ensure visible
      final triggerBtns = find.text('Trigger Retrieval');
      expect(triggerBtns, findsWidgets);
      await tester.ensureVisible(triggerBtns.first);
      await tester.pump();

      await tester.tap(triggerBtns.first);
      await tester.pump();

      // Toast appears
      expect(
        find.textContaining('Retrieval requested! Adding Audi A6'),
        findsOneWidget,
      );

      // Wait for delay
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));

      // Urgent queue count incremented to 3
      expect(find.text('URGENT RETRIEVALS (3)'), findsOneWidget);
      expect(find.text('Bay Call'), findsOneWidget);
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
  });
}
