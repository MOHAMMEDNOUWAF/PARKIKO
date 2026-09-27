import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkiko/core/theme/app_theme.dart';
import 'package:parkiko/features/admin/staff/presentation/add_staff_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('AddStaffScreen under AppTheme.lightTheme reproduced infinite width crash', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1536, 730));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AddStaffScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add New Staff'), findsOneWidget);
  });
}
