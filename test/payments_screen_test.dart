import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkiko/core/theme/app_theme.dart';
import 'package:parkiko/features/admin/payments/presentation/payments_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('PaymentsScreen - Reports & Financials Tests', () {
    testWidgets('Renders all Reports & Financials sections and initial KPI state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. App Bar
      expect(find.text('Reports & Financials'), findsOneWidget);
      expect(find.text('Multi-Site Valet Revenue & Analytics'), findsOneWidget);
      expect(find.byKey(const Key('btn_header_calendar')), findsOneWidget);
      expect(find.byKey(const Key('btn_header_download')), findsOneWidget);

      // 2. Active Site Selector Pill
      expect(find.text('ACTIVE OPERATIONS SITE'), findsOneWidget);
      expect(find.textContaining('All Sites'), findsWidgets);
      expect(find.text('Change'), findsOneWidget);

      // 3. Time Filter Chips
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Last 3 Months'), findsOneWidget);

      // 4. Primary KPI Cards
      expect(find.text('TOTAL COLLECTIONS'), findsOneWidget);
      expect(find.text('Total Gross Revenue'), findsOneWidget);
      expect(find.text('₹0'), findsWidgets);
      expect(find.text('Vehicles Handled'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Avg. Dwell Time'), findsOneWidget);
      expect(find.text('0h 00m'), findsOneWidget);
      expect(find.text('Live rate'), findsOneWidget);
      expect(find.text('Collection Rate'), findsOneWidget);
      expect(find.text('0.0%'), findsWidgets);

      // 5. Payment Collections Channel Breakdown
      expect(find.text('Payment Collections'), findsOneWidget);
      expect(find.text('Reconciled split by intake channel'), findsOneWidget);
      expect(find.text('UPI QR & Digital'), findsOneWidget);
      expect(find.text('Cash Collections'), findsOneWidget);

      // 6. Weekly Influx Trends
      expect(find.text('Weekly Influx Trends'), findsOneWidget);
      expect(find.text('Fri - Sun Peak'), findsOneWidget);
      expect(find.text('Peak Surge Window: 19:00 - 22:30'), findsOneWidget);

      // 7. Operational Tariff Breakdown
      expect(find.text('Operational Tariff Mix'), findsOneWidget);
      expect(find.text('Standard Valet Intake'), findsOneWidget);
      expect(find.text('VIP Porch Express'), findsOneWidget);
      expect(find.text('Overnight & Rollover Fee'), findsOneWidget);

      // 8. Multi-Site Hubs Performance
      expect(find.text('Multi-Site Hubs Performance'), findsOneWidget);
      expect(find.text('0 Active Sites'), findsOneWidget);
      expect(find.text('No Sites Configured'), findsOneWidget);

      // 9. Action Footer Export
      expect(find.text('Export Full Audit CSV / PDF'), findsOneWidget);
    });

    testWidgets('Tapping time filter chip updates timeframe and scales KPIs', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Default is Today
      expect(find.text('0h 00m'), findsOneWidget);
      expect(find.text('Live rate'), findsOneWidget);

      // Tap 'Last 7 Days' chip
      await tester.tap(find.byKey(const Key('period_chip_Last 7 Days')));
      await tester.pumpAndSettle();

      // Verify timeframe updated
      expect(find.text('7-Day Total'), findsOneWidget);
    });

    testWidgets('Tapping Site Selector opens modal and shows empty state when no sites configured', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap site selector pill to open bottom sheet
      await tester.tap(find.byKey(const Key('site_selector_pill')));
      await tester.pumpAndSettle();

      expect(find.text('Valet Site'), findsOneWidget);
      expect(find.text('No Sites Configured'), findsWidgets);
      expect(find.text('All dummy locations removed. Configure a site to begin operations.'), findsOneWidget);
    });

    testWidgets('Tapping influx bar updates highlight surge window pill', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Saturday bar
      await tester.tap(find.byKey(const Key('influx_bar_saturday')));
      await tester.pumpAndSettle();

      expect(find.text('Saturday: ₹0 (0 cars)'), findsOneWidget);
    });

    testWidgets('Opening Export Modal shows format options', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_header_download')));
      await tester.pumpAndSettle();

      expect(find.text('Export Audit & Ledger'), findsOneWidget);
      expect(find.text('Download CSV Spreadsheet'), findsOneWidget);
      expect(find.text('Export Formatted PDF Report'), findsOneWidget);
      expect(find.text('Email Audit to Admin'), findsOneWidget);
    });

    testWidgets('Tapping calendar icon opens mini calendar modal with 90-day range and shortcuts', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap calendar icon button in AppBar
      await tester.tap(find.byKey(const Key('btn_header_calendar')));
      await tester.pumpAndSettle();

      // Verify mini calendar modal opened
      expect(find.text('Daily Report Calendar'), findsOneWidget);
      expect(find.byKey(const Key('btn_cal_prev_month')), findsOneWidget);
      expect(find.byKey(const Key('btn_cal_next_month')), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('7 Days Ago'), findsOneWidget);
      expect(find.text('30 Days Ago'), findsOneWidget);
      expect(find.byKey(const Key('btn_apply_day_report')), findsOneWidget);

      // Close modal
      await tester.tap(find.byKey(const Key('btn_close_calendar_modal')));
      await tester.pumpAndSettle();
      expect(find.text('Daily Report Calendar'), findsNothing);
    });

    testWidgets('Selecting an individual date applies single-day report banner, scales KPIs, and allows clearing', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open calendar modal
      await tester.tap(find.byKey(const Key('btn_header_calendar')));
      await tester.pumpAndSettle();

      // Tap 'Yesterday' shortcut
      await tester.tap(find.text('Yesterday'));
      await tester.pumpAndSettle();

      // Apply day report
      await tester.tap(find.byKey(const Key('btn_apply_day_report')));
      await tester.pumpAndSettle();

      // Verify Daily Report Banner appears
      expect(find.byKey(const Key('daily_report_banner')), findsOneWidget);
      expect(find.text('Individual Day Report'), findsOneWidget);
      expect(find.text('Reconciled 24h intake'), findsOneWidget);
      expect(find.text('1-day total'), findsOneWidget);

      // Clear the daily report
      await tester.tap(find.byKey(const Key('btn_clear_day_report')));
      await tester.pumpAndSettle();

      // Verify returned to standard 30 days view
      expect(find.byKey(const Key('daily_report_banner')), findsNothing);
      expect(find.text('vs ₹0 prev. 30d'), findsOneWidget);
    });

    testWidgets('Renders properly on mobile viewport without layout overflow', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reports & Financials'), findsOneWidget);
      expect(find.text('TOTAL COLLECTIONS'), findsOneWidget);
      expect(find.text('Payment Collections'), findsOneWidget);
    });
  });
}
