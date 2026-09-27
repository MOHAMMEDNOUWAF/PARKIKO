import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkiko/features/admin/staff/presentation/add_staff_screen.dart';
import 'package:parkiko/features/admin/staff/presentation/staff_management_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('AddStaffScreen renders all sections, handles role changes, and form validation', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? createdName;
    VRole? createdRole;
    String? createdSite;
    String? createdPhone;
    String? createdStaffId;

    await tester.pumpWidget(
      MaterialApp(
        home: AddStaffScreen(
          onCreated: (name, role, site, {email, licenseExpiry, licenseNo, multiSiteAccess, password, phone, staffId}) {
            createdName = name;
            createdRole = role;
            createdSite = site;
            createdPhone = phone;
            createdStaffId = staffId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Top App Bar Header
    expect(find.text('Add New Staff'), findsOneWidget);
    expect(find.text('Valet Team Onboarding'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);

    // 2. Verify Photo Card
    expect(find.text('Upload Staff Photo'), findsOneWidget);
    expect(find.text('JPEG, PNG or HEIC · Max 5MB'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Upload from Gallery'), findsOneWidget);

    // 3. Verify Personal Information Section
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.textContaining('Full Name'), findsOneWidget);
    expect(find.textContaining('Mobile Number'), findsOneWidget);
    expect(find.textContaining('Staff ID (Username)'), findsOneWidget);
    expect(find.textContaining('Work Email'), findsOneWidget);

    // 4. Test Staff ID Regeneration
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('PK-'), findsWidgets);

    // 5. Verify Roles & Qualifications
    expect(find.text('Valet Role & Qualifications'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
    expect(find.text('Assistant Manager'), findsOneWidget);
    expect(find.text('Commercial Driving Credentials'), findsOneWidget);
    expect(find.text('RTA Verified'), findsOneWidget);

    // 6. Switch role to Manager
    await tester.tap(find.byKey(const ValueKey('role_manager')));
    await tester.pumpAndSettle();

    // 7. Verify Site Assignment Section & WhatsApp note
    expect(find.text('Site & Location Assignment'), findsOneWidget);
    expect(find.text('Aerocity Grand Terminal - T2'), findsOneWidget);
    expect(find.text('Allow Multi-Site Floating Access'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    expect(find.textContaining('Once created, the staff member receives their valet terminal credentials'), findsOneWidget);

    // 8. Verify Sticky Action Bar
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('+ Save & Assign Staff'), findsOneWidget);

    // 9. Fill personal info (0: Full Name, 1: Mobile, 2: Staff ID, 3: Email)
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Rohit Deshmukh');
    await tester.enterText(textFields.at(1), '9876543210');
    await tester.enterText(textFields.at(3), 'rohit@parkiko.com');
    await tester.pumpAndSettle();

    // 10. Save manager
    await tester.tap(find.byKey(const Key('save_staff_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(createdName, 'Rohit Deshmukh');
    expect(createdRole, VRole.manager);
    expect(createdSite, 'Aerocity Grand Terminal - T2');
    expect(createdPhone, '9876543210');
    expect(createdStaffId, isNotNull);
  });

  testWidgets('AddStaffScreen validates Driver license and shows visible error feedback', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: AddStaffScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Default role is Driver. Tapping save with empty fields should trigger validation
    await tester.tap(find.byKey(const Key('save_staff_button')));
    await tester.pumpAndSettle();

    // Verify errors
    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Mobile number is required'), findsOneWidget);
    expect(find.text('Driving license number is required'), findsOneWidget);
    expect(find.text('License expiry date is required'), findsOneWidget);
    expect(find.text('Please complete all required fields correctly.'), findsOneWidget);
  });

  testWidgets('AddStaffScreen creates Driver successfully when driving license and date are provided', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? createdName;
    VRole? createdRole;
    String? createdLicenseNo;
    DateTime? createdExpiry;

    await tester.pumpWidget(
      MaterialApp(
        home: AddStaffScreen(
          onCreated: (name, role, site, {email, licenseExpiry, licenseNo, multiSiteAccess, password, phone, staffId}) {
            createdName = name;
            createdRole = role;
            createdLicenseNo = licenseNo;
            createdExpiry = licenseExpiry;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    // 0: Full Name, 1: Mobile Number, 2: Staff ID, 3: Password, 4: Work Email, 5: Driving License Number
    await tester.enterText(textFields.at(0), 'Kavita Iyer');
    await tester.enterText(textFields.at(1), '9123456780');
    await tester.enterText(textFields.at(5), 'DL-0420230099881');
    await tester.pumpAndSettle();

    // Pick license expiry date via preset chip
    await tester.tap(find.byKey(const ValueKey('preset_+3 Years')));
    await tester.pumpAndSettle();

    // Save Driver
    await tester.tap(find.byKey(const Key('save_staff_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(createdName, 'Kavita Iyer');
    expect(createdRole, VRole.driver);
    expect(createdLicenseNo, 'DL-0420230099881');
    expect(createdExpiry, isNotNull);
  });

  testWidgets('StaffManagementScreen opens AddStaffScreen, adds new staff, and updates roster', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: StaffManagementScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Staff Management'), findsOneWidget);
    expect(find.text('Add Staff'), findsOneWidget);

    // Tap Add Staff
    await tester.tap(find.text('Add Staff'));
    await tester.pumpAndSettle();

    // Verify AddStaffScreen is open
    expect(find.text('Add New Staff'), findsOneWidget);

    // Select Manager role on AddStaffScreen
    await tester.tap(find.byKey(const ValueKey('role_manager')).last);
    await tester.pumpAndSettle();

    // Enter name & phone (0: Full Name, 1: Mobile, 2: Staff ID, 3: Email)
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Deepak Chawla');
    await tester.enterText(textFields.at(1), '9988776655');
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.byKey(const Key('save_staff_button')).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify returned to StaffManagementScreen
    expect(find.text('Add New Staff'), findsNothing);
    expect(find.text('Staff Management'), findsOneWidget);

    // Verify new staff member Deepak Chawla is in list
    expect(find.text('Deepak Chawla'), findsOneWidget);
    expect(find.textContaining('enrolled! Credentials sent via WhatsApp.'), findsOneWidget);
  });

  testWidgets('AddStaffScreen supports custom staff ID, quick date chips, and cancel dismiss', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? savedStaffId;
    String? savedName;
    DateTime? savedExpiry;

    await tester.pumpWidget(
      MaterialApp(
        home: AddStaffScreen(
          onCreated: (name, role, site, {email, licenseExpiry, licenseNo, multiSiteAccess, password, phone, staffId}) {
            savedName = name;
            savedStaffId = staffId;
            savedExpiry = licenseExpiry;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    // 0: Full Name, 1: Mobile, 2: Staff ID, 3: Email, 4: Driving License
    // 1. Enter custom staff ID into textFields.at(2)
    await tester.enterText(textFields.at(2), 'VALET-VIP-07');
    await tester.pump();

    // 2. Fill Name & Phone
    await tester.enterText(textFields.at(0), 'Anand Kumar');
    await tester.enterText(textFields.at(1), '9812345678');

    // 3. Test Quick Date Chip (+3 Years)
    expect(find.text('+3 Years'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('preset_+3 Years')));
    await tester.pumpAndSettle();

    // 4. Test "Verification in progress" checkbox
    expect(find.textContaining('Verification in progress'), findsOneWidget);
    await tester.tap(find.byKey(const Key('verification_later_row')));
    await tester.pumpAndSettle();

    // 5. Save Driver without filling driving license number (since verification pending is checked)
    await tester.tap(find.byKey(const Key('save_staff_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(savedName, 'Anand Kumar');
    expect(savedStaffId, 'VALET-VIP-07');
    expect(savedExpiry, isNotNull);
  });

  testWidgets('AddStaffScreen Cancel button dismisses screen without getting stuck', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddStaffScreen()),
            ),
            child: const Text('Open Screen'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open
    await tester.tap(find.text('Open Screen'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Staff'), findsOneWidget);

    // Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Should return to previous screen
    expect(find.text('Add New Staff'), findsNothing);
    expect(find.text('Open Screen'), findsOneWidget);
  });
}
