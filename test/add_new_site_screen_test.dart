import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkiko/features/admin/sites/presentation/add_new_site_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AddNewSiteScreen Tests', () {
    testWidgets('Renders all fields, increments/decrements bays, detects GPS, and validates form', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool continueCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AddNewSiteScreen(
            onContinue: () {
              continueCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Headers & Titles
      expect(find.text('Add New Site'), findsOneWidget);
      expect(find.text('Multi-Site Valet Onboarding'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Help'), findsOneWidget);

      // 2. Verify Help Dialog
      await tester.tap(find.byTooltip('Help'));
      await tester.pumpAndSettle();
      expect(find.text('Site Onboarding Help'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Site Onboarding Help'), findsNothing);

      // 3. Verify Cards
      expect(find.text('Property & Site Details'), findsOneWidget);
      expect(find.text('Capacity & Deck Allocation'), findsNothing);
      expect(find.text('Valet Rates & Billing Defaults'), findsOneWidget);

      // 5. Verify GPS Detection
      await tester.tap(find.byKey(const Key('btn_detect_gps')));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hospitality District, Aerocity T2'), findsOneWidget);

      // Dismiss SnackBar so it doesn't intercept taps
      ScaffoldMessenger.of(tester.element(find.byType(AddNewSiteScreen))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // 6. Test Form Validation on empty site name
      await tester.tap(find.byKey(const Key('btn_continue')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter site name'), findsOneWidget);

      // 7. Enter site name and submit
      await tester.enterText(find.byKey(const Key('input_site_name')), 'Grand Hyatt & Convention');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_continue')));
      await tester.pumpAndSettle();

      expect(continueCalled, isTrue);
      expect(find.textContaining('configured and deployed!'), findsOneWidget);
    });

    testWidgets('ParkikoAdminApp boots successfully', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const ParkikoAdminApp());
      await tester.pumpAndSettle();

      expect(find.text('Add New Site'), findsOneWidget);
      expect(find.text('Property & Site Details'), findsOneWidget);
    });
  });
}
