import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/admin/staff/presentation/add_staff_screen.dart';

void main() {
  testWidgets('AddStaffScreen layout at 1536x730', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1536, 730));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: AddStaffScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add New Staff'), findsOneWidget);
    expect(find.text('Upload Staff Photo'), findsOneWidget);
  });
}
