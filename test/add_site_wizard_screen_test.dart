import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkiko/core/theme/app_theme.dart';
import 'package:parkiko/features/admin/sites/presentation/add_site_wizard_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AddSiteWizardScreen Tests', () {
    testWidgets('Renders all fields, handles GPS detection, validation, and directly deploys site', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool siteCreated = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AddSiteWizardScreen(
            onSiteCreated: () => siteCreated = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. App Bar Header
      expect(find.text('Add New Site'), findsOneWidget);
      expect(find.text('Multi-Site Valet Onboarding'), findsOneWidget);
      expect(find.byTooltip('Back to Multi-Site Settings'), findsOneWidget);
      expect(find.byTooltip('Support & Onboarding Help'), findsOneWidget);

      // 2. Card 1: Property & Site Details
      expect(find.text('Property & Site Details'), findsOneWidget);
      expect(find.text('Site Name'), findsOneWidget);
      expect(find.text('Complete Address / Location'), findsOneWidget);
      expect(find.text('Detect Current GPS'), findsOneWidget);

      // 3. Card 2: Capacity & Deck Allocation removed
      expect(find.text('Capacity & Deck Allocation'), findsNothing);

      // 4. Card 3: Valet Rates & Billing Defaults
      expect(find.text('Valet Rates & Billing Defaults'), findsOneWidget);
      expect(find.text('Base Valet Fee (₹)'), findsOneWidget);
      expect(find.text('VIP Porch Expedited (₹)'), findsOneWidget);
      expect(find.text('Overnight / Rollover Retention Fee (₹)'), findsOneWidget);

      // 5. Test GPS Detection button
      await tester.tap(find.byKey(const Key('btn_detect_gps')));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.textContaining('Terminal 3 Gate 4'), findsOneWidget);

      // Dismiss snackbar so it doesn't intercept taps
      ScaffoldMessenger.of(tester.element(find.byType(AddSiteWizardScreen))).clearSnackBars();
      await tester.pumpAndSettle();

      // 6. Validation test: Empty site name should prevent advancing
      await tester.tap(find.byKey(const Key('btn_continue_to_next')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a site name'), findsOneWidget);

      // Dismiss snackbar
      ScaffoldMessenger.of(tester.element(find.byType(AddSiteWizardScreen))).clearSnackBars();
      await tester.pumpAndSettle();

      // 7. Enter site name and deploy directly
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Grand Hyatt & Convention');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_continue_to_next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify site was created and deployed directly without navigating to Step 2
      expect(siteCreated, isTrue);
    });

    testWidgets('Help dialog renders properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AddSiteWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Support & Onboarding Help'));
      await tester.pumpAndSettle();

      expect(find.text('Site Onboarding Help'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Site Onboarding Help'), findsNothing);
    });
  });
}
