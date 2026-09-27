import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkiko/core/theme/app_theme.dart';
import 'package:parkiko/features/admin/staff/presentation/staff_management_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('StaffManagementScreen -> + Add Staff full flow works seamlessly without freeze or layout errors', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1536, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const StaffManagementScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify StaffManagementScreen loaded
    expect(find.text('Staff Management'), findsOneWidget);
    expect(find.text('Add Staff'), findsOneWidget);

    // 2. Click Add Staff
    await tester.tap(find.text('Add Staff'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 3. Verify AddStaffScreen is visible and all sections rendered
    expect(find.text('Add New Staff'), findsOneWidget);
    expect(find.text('Valet Team Onboarding'), findsOneWidget);
    expect(find.text('Upload Staff Photo'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Upload from Gallery'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Valet Role & Qualifications'), findsOneWidget);
    expect(find.text('Commercial Driving Credentials'), findsOneWidget);
    expect(find.text('Site & Location Assignment'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('+ Save & Assign Staff'), findsOneWidget);

    // 4. Switch role to Manager and fill form
    await tester.tap(find.byKey(const ValueKey('role_manager')));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Aditya Verma');
    await tester.enterText(textFields.at(1), '9876543210');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.byKey(const Key('save_staff_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 5. Verify back on Staff Management Screen with toast feedback
    expect(find.text('Staff Management'), findsOneWidget);
    expect(find.textContaining('Aditya Verma enrolled!'), findsOneWidget);
  });

  testWidgets('StaffManagementScreen -> Selecting Assistant Manager shows as Assistant Manager (not Manager)', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1536, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const StaffManagementScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Click Add Staff
    await tester.tap(find.text('Add Staff'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 2. Select Assistant Manager role card
    await tester.tap(find.byKey(const ValueKey('role_asstManager')));
    await tester.pumpAndSettle();

    // 3. Enter personal information
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Rohan Kapoor');
    await tester.enterText(textFields.at(1), '9811122233');
    await tester.pumpAndSettle();

    // 4. Save
    await tester.tap(find.byKey(const Key('save_staff_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 5. Verify on Staff Management Screen that Rohan Kapoor shows Assistant Manager position and badge
    expect(find.text('Rohan Kapoor'), findsOneWidget);
    expect(find.text('ASSISTANT MANAGER'), findsWidgets);
    expect(find.text('Position: Assistant Manager'), findsWidgets);

    // 6. Filter by Assistant Managers
    await tester.tap(find.textContaining('Assist Managers'));
    await tester.pumpAndSettle();

    expect(find.text('Rohan Kapoor'), findsOneWidget);
  });
}
