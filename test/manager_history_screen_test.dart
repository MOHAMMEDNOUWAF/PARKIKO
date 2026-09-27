import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/managers/manager/manager.dart';

void main() {
  group('Manager History & Audit Screen Tests', () {
    testWidgets('Renders ManagerHistoryScreen with KPIs, search, and audit cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManagerHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Location
      expect(find.text('TODAY HISTORY'), findsOneWidget);
      expect(find.text('Grand Hyatt & Convention'), findsOneWidget);

      // Verify KPI Summary Titles
      expect(find.text('Retrieved'), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('Channel Split'), findsOneWidget);

      // Verify Search & Filter Tabs
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Online UPI ('), findsOneWidget);
      expect(find.textContaining('Cash Handover ('), findsOneWidget);

      // Verify Completed Card Content
      expect(find.text('BMW X5 xDrive'), findsOneWidget);
      expect(find.text('MH 01 DX 4022'), findsOneWidget);

      // Verify tapping "Slip" opens bottom sheet modal
      final slipButtons = find.text('Slip');
      expect(slipButtons, findsWidgets);
      await tester.tap(slipButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Valet Digital Audit Slip'), findsOneWidget);
      expect(find.text('SETTLED & RELEASED'), findsOneWidget);
      expect(find.text('Share e-Slip'), findsOneWidget);
      expect(find.text('Print Receipt'), findsOneWidget);
    });

    testWidgets('Filters completed runs by Online and Cash tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManagerHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Cash filter
      final cashFilter = find.textContaining('Cash Handover');
      await tester.tap(cashFilter);
      await tester.pumpAndSettle();

      // Should show cash vehicle Audi Q7 Prestige and hide BMW X5 xDrive
      expect(find.text('Audi Q7 Prestige'), findsOneWidget);
      expect(find.text('BMW X5 xDrive'), findsNothing);

      // Tap Online filter
      final onlineFilter = find.textContaining('Online UPI');
      await tester.tap(onlineFilter);
      await tester.pumpAndSettle();

      expect(find.text('BMW X5 xDrive'), findsOneWidget);
      expect(find.text('Audi Q7 Prestige'), findsNothing);
    });
  });
}
