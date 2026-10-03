import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkiko/app.dart';
import 'package:parkiko/features/auth/models/user_profile.dart';
import 'package:parkiko/features/auth/providers/auth_provider.dart';
import 'package:parkiko/features/auth/services/firebase_auth_service.dart';
import 'package:parkiko/features/drivers/models/vehicle_intake_model.dart';
import 'package:parkiko/features/drivers/presentation/driver_intake_screen.dart';
import 'package:parkiko/features/drivers/presentation/driver_key_handover_screen.dart';
import 'package:parkiko/features/drivers/services/driver_service.dart';
import 'package:parkiko/features/managers/manager/manager_dashboard_screen.dart';
import 'package:parkiko/features/managers/manager/manager_payment_stats.dart';
import 'package:parkiko/features/managers/assistant%20manager/assistant_manager_screen.dart';
import 'package:parkiko/features/admin/sites/models/site_model.dart';
import 'package:parkiko/features/admin/sites/services/site_manager.dart';
import 'package:parkiko/features/admin/payments/presentation/payments_screen.dart';

class MockDriverAuthNotifier extends AuthNotifier {
  MockDriverAuthNotifier(super.authService, [UserProfile? initialProfile]) {
    if (initialProfile != null) {
      state = AsyncData(initialProfile);
    } else {
      state = const AsyncData(null);
    }
  }

  @override
  Future<void> checkInitialSession() async {}

  @override
  Future<AuthResult> signIn({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final lower = identifier.trim().toLowerCase();
    if (lower == 'st-108' || lower == 'driver1' || lower == 'rahul' || lower == '0108' || lower == 'pk-0108') {
      final profile = UserProfile(
        uid: 'test-driver-uid',
        userId: 'ST-108',
        name: 'Rahul V.',
        role: 'DRIVER',
        status: 'ACTIVE',
        organizationId: 'Terminal 2',
      );
      state = AsyncData(profile);
      return AuthResult.success(profile);
    } else if (lower == 'admin1' && password.trim() == '1234') {
      final adminProfile = UserProfile(
        uid: 'test-admin-uid',
        userId: 'admin1',
        name: 'Terminal Admin',
        role: 'ADMIN',
        status: 'ACTIVE',
      );
      state = AsyncData(adminProfile);
      return AuthResult.success(adminProfile);
    }
    return AuthResult.failure('Invalid credentials.');
  }

  @override
  Future<void> signOut() async {
    state = const AsyncData(null);
  }
}

void main() {
  setUp(() {
    DriverService.instance.clearIntakes();
    DriverService.instance.setDutyStatus(true);
  });

  group('VehicleIntakeModel Tests', () {
    test('Serializes to and from Map correctly', () {
      final now = DateTime.now();
      final intake = VehicleIntakeModel(
        id: 'INT-5001',
        customerName: 'Aarav Sharma',
        customerPhone: '9876543210',
        vehicleReg: 'KL 07 BZ 4501',
        vehicleModel: 'BMW 3 Series',
        photoName: 'IMG_INTAKE_0284.JPG',
        driverId: 'ST-108',
        driverName: 'Rahul V.',
        siteName: 'Terminal 2 • Valet Desk',
        status: 'intake_registered',
        createdAt: now,
      );

      final map = intake.toMap();
      expect(map['id'], 'INT-5001');
      expect(map['customerName'], 'Aarav Sharma');
      expect(map['customerPhone'], '9876543210');
      expect(map['vehicleReg'], 'KL 07 BZ 4501');

      final deserialized = VehicleIntakeModel.fromMap(map, 'INT-5001');
      expect(deserialized.id, 'INT-5001');
      expect(deserialized.customerName, 'Aarav Sharma');
      expect(deserialized.vehicleReg, 'KL 07 BZ 4501');
      expect(deserialized.driverId, 'ST-108');
    });

    test('DriverService manages duty status and submissions', () async {
      expect(DriverService.instance.isOnDuty, isTrue);
      DriverService.instance.toggleDutyStatus();
      expect(DriverService.instance.isOnDuty, isFalse);
      DriverService.instance.toggleDutyStatus();
      expect(DriverService.instance.isOnDuty, isTrue);

      final intake = VehicleIntakeModel(
        id: 'INT-999',
        customerName: 'Rohan Mehra',
        customerPhone: '9876500000',
        vehicleReg: 'MH 02 CD 8821',
        vehicleModel: 'Mercedes E-Class',
        driverId: 'ST-108',
        driverName: 'Rahul V.',
        siteName: 'Terminal 2 • Valet Desk',
        createdAt: DateTime.now(),
      );

      await DriverService.instance.submitIntake(intake);
      expect(DriverService.instance.intakes.length, 1);
      expect(DriverService.instance.intakes.first.id, 'INT-999');
    });
  });

  group('DriverIntakeScreen UI & Interaction Tests', () {
    testWidgets('Renders all driver header elements, duty status toggle, and initial state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool loggedOut = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DriverIntakeScreen(
            driverProfile: const UserProfile(
              uid: 'driver-1',
              userId: 'ST-108',
              name: 'Rahul V.',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
            onLogout: () => loggedOut = true,
            initialHasPhoto: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('RV'), findsOneWidget);
      expect(find.text('Driver: Rahul V. (ST-108)'), findsOneWidget);
      expect(find.text('ON DUTY'), findsOneWidget);

      // Verify Step Hero Header
      expect(find.text('New Intake'), findsOneWidget);
      expect(find.text('Vehicle Intake & Booking'), findsOneWidget);

      // Verify Sections
      expect(find.text('CUSTOMER DETAILS'), findsOneWidget);
      expect(find.text('VEHICLE DETAILS'), findsOneWidget);

      // Verify initial photo preview is loaded as per HTML default
      expect(find.byKey(const Key('photo_preview_box')), findsOneWidget);
      expect(find.text('Photo ready • Condition logged'), findsOneWidget);

      // Test duty status toggle
      await tester.tap(find.text('ON DUTY'));
      await tester.pumpAndSettle();
      expect(find.text('OFF DUTY'), findsOneWidget);
      expect(DriverService.instance.isOnDuty, isFalse);

      await tester.tap(find.text('OFF DUTY'));
      await tester.pumpAndSettle();
      expect(find.text('ON DUTY'), findsOneWidget);
      expect(DriverService.instance.isOnDuty, isTrue);

      // Test Profile & Logout Sheet
      await tester.tap(find.text('RV'));
      await tester.pumpAndSettle();
      expect(find.text('Sign Out of Terminal'), findsOneWidget);

      await tester.tap(find.text('Sign Out of Terminal'));
      await tester.pumpAndSettle();
      expect(loggedOut, isTrue);
    });

    testWidgets('Form validation and OCR scanner button interaction', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverIntakeScreen(
            driverProfile: const UserProfile(
              uid: 'driver-1',
              userId: 'ST-108',
              name: 'Rahul V.',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
            onLogout: () {},
            initialHasPhoto: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit with empty inputs
      await tester.tap(find.byKey(const Key('btn_submit_intake')));
      await tester.pumpAndSettle();

      // Verifies customer name error
      expect(find.text('Please enter a valid customer name.'), findsOneWidget);

      // Enter customer name
      await tester.enterText(find.byKey(const Key('driver_customer_name_input')), 'Pooja Hegde');
      await tester.tap(find.byKey(const Key('btn_submit_intake')));
      await tester.pumpAndSettle();

      // Verifies phone number error
      expect(find.text('Please enter a valid 10-digit mobile number.'), findsOneWidget);

      // Enter valid 10-digit phone
      await tester.enterText(find.byKey(const Key('driver_customer_phone_input')), '9876543210');
      await tester.tap(find.byKey(const Key('btn_submit_intake')));
      await tester.pumpAndSettle();

      // Verifies vehicle registration error
      expect(find.text('Please enter a valid vehicle license plate (e.g., KL 07 BZ 4501).'), findsOneWidget);

      // Enter vehicle registration plate
      await tester.enterText(find.byKey(const Key('driver_vehicle_reg_input')), 'KL 07 BZ 4501');
      await tester.pumpAndSettle();

      // Enter vehicle model
      await tester.enterText(find.byKey(const Key('driver_vehicle_model_input')), 'Hyundai Creta SX');
      await tester.pumpAndSettle();

      // Submit form / Tap Next
      await tester.tap(find.byKey(const Key('btn_submit_intake')));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Verifies Step 2 DriverKeyHandoverScreen is displayed
      expect(find.text('Vehicle Slot & Key Handover'), findsWidgets);
      expect(find.text('GENERATED BILL TOKEN'), findsOneWidget);
      expect(find.text('KEY CUSTODY & HANDOVER'), findsOneWidget);
      expect(find.text('Pooja Hegde'), findsWidgets);
      expect(find.text('Hyundai Creta SX'), findsWidgets);
      expect(find.byKey(const Key('key_status_toggle')), findsOneWidget);

      // Tap to accept keys
      await tester.tap(find.byKey(const Key('key_status_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Keys Accepted (In Custody)'), findsOneWidget);

      // Tap Parked & Complete Intake
      await tester.tap(find.byKey(const Key('btn_complete_intake')));
      await tester.pumpAndSettle();

      // Verifies success state
      expect(find.text('Intake Complete & Parked!'), findsOneWidget);
      expect(find.byKey(const Key('btn_back_to_driver_home')), findsOneWidget);

      // Tap Back to Driver Home
      await tester.tap(find.byKey(const Key('btn_back_to_driver_home')));
      await tester.pumpAndSettle();

      // Verifies returned to driver intake screen with form reset
      expect(find.text('Vehicle Intake & Booking'), findsOneWidget);
    });

    testWidgets('Photo toggle between preview and dropzone', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverIntakeScreen(
            driverProfile: const UserProfile(
              uid: 'driver-1',
              userId: 'ST-108',
              name: 'Rahul V.',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
            onLogout: () {},
            initialHasPhoto: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state has photo preview
      expect(find.byKey(const Key('photo_preview_box')), findsOneWidget);

      // Tap remove photo button
      await tester.tap(find.byKey(const Key('btn_remove_photo')));
      await tester.pumpAndSettle();

      // Preview box is gone, dropzone appears
      expect(find.byKey(const Key('photo_preview_box')), findsNothing);
      expect(find.byKey(const Key('photo_dropzone')), findsOneWidget);
      expect(find.text('Take Photo of Car'), findsOneWidget);
      expect(find.byKey(const Key('btn_open_camera')), findsOneWidget);

      // Tap Open Camera button to capture
      await tester.tap(find.byKey(const Key('btn_open_camera')));
      await tester.pumpAndSettle();

      // Preview box reappears with retake button
      expect(find.byKey(const Key('photo_preview_box')), findsOneWidget);
      expect(find.byKey(const Key('btn_retake_photo')), findsOneWidget);
      expect(find.text('Photo ready • Condition logged'), findsOneWidget);
    });
  });

  group('Driver Authentication & App Routing Tests', () {
    testWidgets('Logging in with Driver User ID routes directly to DriverIntakeScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => MockDriverAuthNotifier(ref.watch(firebaseAuthServiceProvider), null),
            ),
          ],
          child: const ParkikoApp(),
        ),
      );
      await tester.pumpAndSettle();

      // On LoginScreen
      expect(find.text('Welcome to Parkiko'), findsOneWidget);
      expect(find.text('User ID'), findsOneWidget);

      // Enter driver credentials
      await tester.enterText(find.byKey(const Key('login_user_id_field')), '0108');
      final pwFields = find.byType(TextField);
      await tester.enterText(pwFields.at(1), '1234');

      // Tap sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verifies that user is now on DriverIntakeScreen
      expect(find.text('RV'), findsOneWidget);
      expect(find.text('Driver: Rahul V. (ST-108)'), findsOneWidget);
      expect(find.text('Vehicle Intake & Booking'), findsOneWidget);
      expect(find.text('CUSTOMER DETAILS'), findsOneWidget);
    });

    testWidgets('Demo Driver Sign-In button logs directly into DriverIntakeScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => MockDriverAuthNotifier(ref.watch(firebaseAuthServiceProvider), null),
            ),
          ],
          child: const ParkikoApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Demo Driver Sign-In
      expect(find.byKey(const Key('dev_bypass_driver_login_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dev_bypass_driver_login_button')));
      await tester.pumpAndSettle();

      // Verifies that user is now on DriverIntakeScreen
      expect(find.text('RV'), findsOneWidget);
      expect(find.text('Driver: Rahul V. (ST-108)'), findsOneWidget);
      expect(find.text('Vehicle Intake & Booking'), findsOneWidget);
    });
  });

  group('DriverKeyHandoverScreen Tests', () {
    testWidgets('Renders all elements, key toggle, copy token, and completion', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleIntake = VehicleIntakeModel(
        id: 'INT-8842',
        customerName: 'Priya Sen',
        customerPhone: '9833411223',
        vehicleReg: 'MH 02 CD 8821',
        vehicleModel: 'Mercedes-Benz GLC 300',
        photoName: 'IMG_INTAKE_0284.JPG',
        driverId: 'ST-108',
        driverName: 'Rahul V.',
        siteName: 'Terminal 2 - Grand Hyatt Hub',
        status: 'intake_registered',
        createdAt: DateTime(2026, 9, 23, 14, 35),
      );

      bool completedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DriverKeyHandoverScreen(
            intake: sampleIntake,
            ticketNumber: 'BILL #PK-8842-T2',
            driverProfile: const UserProfile(
              uid: 'driver-1',
              userId: 'ST-108',
              name: 'Rahul V.',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
            onCompleted: () {
              completedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header checks
      expect(find.text('Vehicle Slot & Key Handover'), findsWidgets);
      expect(find.text('Verify assigned bay and accept physical key'), findsOneWidget);

      // Live Broadcast banner
      expect(find.text('Dispatched to Manager & Assistant Manager Deck'), findsOneWidget);
      expect(find.text('LIVE BROADCAST'), findsOneWidget);

      // Card 1 checks: Token & vehicle
      expect(find.text('GENERATED BILL TOKEN'), findsOneWidget);
      expect(find.text('BILL #PK-8842-T2'), findsOneWidget);
      expect(find.text('MH 02 CD 8821'), findsOneWidget);
      expect(find.text('Mercedes-Benz GLC 300'), findsOneWidget);
      expect(find.text('Priya Sen'), findsOneWidget);
      expect(find.text('+91 98334 11223'), findsOneWidget);
      expect(find.text('Prepaid FastPass'), findsOneWidget);

      // Copy token tap
      await tester.tap(find.byKey(const Key('btn_copy_token')));
      await tester.pumpAndSettle();

      // Card 2 checks: Key custody
      expect(find.text('KEY CUSTODY & HANDOVER'), findsOneWidget);
      expect(find.text('Parking Receipt & E-Pass'), findsOneWidget);
      expect(find.text('Manager & Asst. Mgr Deck'), findsOneWidget);
      expect(find.byKey(const Key('key_status_toggle')), findsOneWidget);

      // Tap key toggle
      await tester.tap(find.byKey(const Key('key_status_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Keys Accepted (In Custody)'), findsOneWidget);
      expect(find.text('Keys Secured'), findsOneWidget);

      // Complete intake button
      expect(find.byKey(const Key('btn_complete_intake')), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_complete_intake')));
      await tester.pumpAndSettle();

      // Success view
      expect(find.text('INTAKE SUCCESSFUL'), findsOneWidget);
      expect(find.text('Intake Complete & Parked!'), findsOneWidget);
      expect(find.text('Available for Next Car'), findsOneWidget);

      // Tap Back to Driver Home
      await tester.tap(find.byKey(const Key('btn_back_to_driver_home')));
      await tester.pumpAndSettle();

      expect(completedCalled, isTrue);
    });
  });

  group('Vehicle Registration Formatting & Keyboard Switching Tests', () {
    test('getPlateKeyboardType switches between text and number based on plate segment', () {
      // Empty or state letters
      expect(getPlateKeyboardType(''), TextInputType.text);
      expect(getPlateKeyboardType('K'), TextInputType.text);
      expect(getPlateKeyboardType('KL'), TextInputType.number);
      expect(getPlateKeyboardType('KL '), TextInputType.number);

      // District segment
      expect(getPlateKeyboardType('KL 0'), TextInputType.number);
      expect(getPlateKeyboardType('KL 07'), TextInputType.text);
      expect(getPlateKeyboardType('KL 7 '), TextInputType.text);
      expect(getPlateKeyboardType('KL 07 '), TextInputType.text);

      // Series segment (1-3 letters)
      expect(getPlateKeyboardType('KL 07 B'), TextInputType.text);
      expect(getPlateKeyboardType('KL 07 BZ'), TextInputType.text);
      expect(getPlateKeyboardType('KL 07 BZ '), TextInputType.number);
      expect(getPlateKeyboardType('KL 07 ABC'), TextInputType.number);
      expect(getPlateKeyboardType('KL 07 ABC '), TextInputType.number);

      // 4-digit number segment
      expect(getPlateKeyboardType('KL 07 BZ 4'), TextInputType.number);
      expect(getPlateKeyboardType('KL 07 BZ 4501'), TextInputType.number);
    });

    testWidgets('Entering 1-digit district shows Space button and allows advancing to letters', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverIntakeScreen(
            driverProfile: const UserProfile(
              uid: 'driver-1',
              userId: 'ST-108',
              name: 'Rahul V.',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 2-letter state code and 1-digit district
      final regFinder = find.byKey(const Key('driver_vehicle_reg_input'));
      await tester.enterText(regFinder, 'KL 7');
      await tester.pumpAndSettle();

      // Verify Space button appears
      expect(find.byKey(const Key('btn_advance_reg_segment')), findsOneWidget);

      // Tap Space button to advance
      await tester.tap(find.byKey(const Key('btn_advance_reg_segment')));
      await tester.pumpAndSettle();

      // Should now be 'KL 7 '
      final editable = tester.widget<TextField>(regFinder);
      expect(editable.controller?.text, 'KL 7 ');
      expect(editable.keyboardType, TextInputType.text);
    });

    testWidgets('Flexible registration format validates both 1-2 digits and 1-3 letters correctly', (WidgetTester tester) async {
      final regPattern = RegExp(r'^[A-Z]{2}\s[0-9]{1,2}\s[A-Z]{1,3}\s[0-9]{4}$');

      // 1 digit district + 1 letter series
      expect(regPattern.hasMatch('KL 7 A 1234'), isTrue);
      // 2 digits district + 1 letter series
      expect(regPattern.hasMatch('DL 01 C 4521'), isTrue);
      // 2 digits district + 2 letters series
      expect(regPattern.hasMatch('KL 07 BZ 4501'), isTrue);
      // 2 digits district + 3 letters series
      expect(regPattern.hasMatch('MH 12 ABC 9999'), isTrue);

      // Invalid formats
      expect(regPattern.hasMatch('K 07 BZ 4501'), isFalse); // only 1 letter state
      expect(regPattern.hasMatch('KL 123 BZ 4501'), isFalse); // 3 digits district
      expect(regPattern.hasMatch('KL 07 ABCD 4501'), isFalse); // 4 letters series
      expect(regPattern.hasMatch('KL 07 BZ 450'), isFalse); // 3 digits number
    });
  });

  group('Camera Vehicle Photo Tests', () {
    testWidgets('Screen starts with camera prompt when initialHasPhoto is false and captures via camera', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverIntakeScreen(
            driverProfile: const UserProfile(
              uid: 'driver-1',
              userId: 'ST-108',
              name: 'Rahul V.',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
            onLogout: () {},
            initialHasPhoto: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Camera dropzone is visible
      expect(find.byKey(const Key('photo_dropzone')), findsOneWidget);
      expect(find.text('Take Photo of Car'), findsOneWidget);
      expect(find.byKey(const Key('btn_open_camera')), findsOneWidget);
      expect(find.byKey(const Key('btn_open_gallery')), findsOneWidget);
      expect(find.byKey(const Key('photo_preview_box')), findsNothing);

      // Tap Open Camera
      await tester.tap(find.byKey(const Key('btn_open_camera')));
      await tester.pumpAndSettle();

      // Preview box is now visible
      expect(find.byKey(const Key('photo_preview_box')), findsOneWidget);
      expect(find.byKey(const Key('btn_retake_photo')), findsOneWidget);
      expect(find.byKey(const Key('btn_remove_photo')), findsOneWidget);
      expect(find.text('Photo ready • Condition logged'), findsOneWidget);

      // Tap Retake with Camera
      await tester.tap(find.byKey(const Key('btn_retake_photo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo_preview_box')), findsOneWidget);

      // Tap Remove photo
      await tester.tap(find.byKey(const Key('btn_remove_photo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo_dropzone')), findsOneWidget);
    });
  });

  group('Driver Status and Multi-Screen Sync Tests', () {
    testWidgets('Tapping Keys Accepted saves status as waiting_for_parking silently without saving toast', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleIntake = VehicleIntakeModel(
        id: 'INT-9901',
        customerName: 'Mohammed Nouwaf',
        customerPhone: '+91 9876543210',
        vehicleReg: 'KL 10 AB 1234',
        vehicleModel: 'BMW M340i',
        driverId: 'PK-1025',
        driverName: 'Shabeer',
        siteName: 'ABC Hospital',
        status: 'intake_registered',
        createdAt: DateTime(2026, 9, 29, 18, 45),
      );

      DriverService.instance.clearIntakes();
      await DriverService.instance.submitIntake(sampleIntake);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverKeyHandoverScreen(
            intake: sampleIntake,
            ticketNumber: '#PK-2026-00125',
            driverProfile: const UserProfile(
              uid: 'driver-pk-1025',
              userId: 'PK-1025',
              name: 'Shabeer',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure key toggle exists and is visible
      final keyToggle = find.byKey(const Key('key_status_toggle'));
      expect(keyToggle, findsOneWidget);
      await tester.ensureVisible(keyToggle);
      await tester.pumpAndSettle();

      // Tap Keys Accepted
      await tester.tap(keyToggle);
      await tester.pumpAndSettle();

      // Verify status in DriverService was updated to 'waiting_for_parking'
      final updated = DriverService.instance.intakes.firstWhere((i) => i.id == 'INT-9901');
      expect(updated.status, 'waiting_for_parking');

      // Verify NO toast exists containing "saved" or "database"
      expect(find.textContaining(RegExp(r'saving to database', caseSensitive: false)), findsNothing);
      expect(find.textContaining(RegExp(r'saved to database', caseSensitive: false)), findsNothing);
      expect(find.textContaining(RegExp(r'details saved', caseSensitive: false)), findsNothing);
    });

    testWidgets('ManagerDashboardScreen displays WAITING FOR PARKING badge for waiting intakes', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DriverService.instance.clearIntakes();
      final intake = VehicleIntakeModel(
        id: 'INT-9902',
        customerName: 'Mohammed Nouwaf',
        customerPhone: '+91 9876543210',
        vehicleReg: 'KL 10 AB 1234',
        vehicleModel: 'BMW M340i',
        driverId: 'PK-1025',
        driverName: 'Shabeer',
        siteName: 'Grand Hyatt & Convention',
        status: 'waiting_for_parking',
        createdAt: DateTime.now(),
      );
      await DriverService.instance.submitIntake(intake);

      await tester.pumpWidget(
        const MaterialApp(
          home: ManagerDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify badge on Manager Screen
      expect(find.text('WAITING FOR PARKING'), findsWidgets);
      expect(find.textContaining('1 Waiting'), findsOneWidget);
    });

    testWidgets('AssistantManagerScreen displays WAITING FOR PARKING section and allows bay assignment', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DriverService.instance.clearIntakes();
      final intake = VehicleIntakeModel(
        id: 'INT-9903',
        customerName: 'Mohammed Nouwaf',
        customerPhone: '+91 9876543210',
        vehicleReg: 'KL 10 AB 1234',
        vehicleModel: 'BMW M340i',
        driverId: 'PK-1025',
        driverName: 'Shabeer',
        siteName: 'Grand Hyatt • Deck B1',
        status: 'waiting_for_parking',
        createdAt: DateTime.now(),
      );
      await DriverService.instance.submitIntake(intake);

      await tester.pumpWidget(
        const MaterialApp(
          home: AssistantManagerScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Waiting for Parking Card in Parked Vehicles Listing
      expect(find.textContaining('PARKED VEHICLES'), findsOneWidget);
      expect(find.text('WAITING FOR BAY ALLOCATION'), findsOneWidget);
      expect(find.text('KL 10 AB 1234'), findsOneWidget);
      expect(find.byKey(const Key('btn_assign_bay_INT-9903')), findsOneWidget);

      // Tap Assign Bay & Park
      await tester.tap(find.byKey(const Key('btn_assign_bay_INT-9903')));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify status changed to parked
      final updated = DriverService.instance.intakes.firstWhere((i) => i.id == 'INT-9903');
      expect(updated.status, 'parked');
    });

    testWidgets('Driver screen updating from waiting for parking to parked updates on manager screen and assistant manager as parked', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DriverService.instance.clearIntakes();
      final sampleIntake = VehicleIntakeModel(
        id: 'INT-9905',
        customerName: 'Mohammed Nouwaf',
        customerPhone: '+91 9876543210',
        vehicleReg: 'KL 10 AB 1234',
        vehicleModel: 'BMW M340i',
        driverId: 'PK-1025',
        driverName: 'Shabeer',
        siteName: 'Grand Hyatt & Convention',
        status: 'intake_registered',
        createdAt: DateTime.now(),
      );
      await DriverService.instance.submitIntake(sampleIntake);

      // 1. Open DriverKeyHandoverScreen and tap Keys Accepted
      await tester.pumpWidget(
        MaterialApp(
          home: DriverKeyHandoverScreen(
            intake: sampleIntake,
            ticketNumber: '#PK-2026-00125',
            driverProfile: const UserProfile(
              uid: 'driver-pk-1025',
              userId: 'PK-1025',
              name: 'Shabeer',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final keyToggle = find.byKey(const Key('key_status_toggle'));
      await tester.ensureVisible(keyToggle);
      await tester.tap(keyToggle);
      await tester.pumpAndSettle();


      // At this stage, status must be 'waiting_for_parking'
      expect(DriverService.instance.intakes.firstWhere((i) => i.id == 'INT-9905').status, 'waiting_for_parking');

      // Verify Manager Screen shows WAITING FOR PARKING
      await tester.pumpWidget(const MaterialApp(home: ManagerDashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('WAITING FOR PARKING'), findsWidgets);
      expect(find.textContaining('1 Waiting'), findsOneWidget);

      // Verify Assistant Manager Screen shows in PARKED VEHICLES listing awaiting bay
      await tester.pumpWidget(const MaterialApp(home: AssistantManagerScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('PARKED VEHICLES'), findsOneWidget);
      expect(find.text('WAITING FOR BAY ALLOCATION'), findsOneWidget);

      // 2. Now driver taps "Parked & Complete Intake"
      await tester.pumpWidget(
        MaterialApp(
          home: DriverKeyHandoverScreen(
            intake: DriverService.instance.intakes.firstWhere((i) => i.id == 'INT-9905'),
            ticketNumber: '#PK-2026-00125',
            driverProfile: const UserProfile(
              uid: 'driver-pk-1025',
              userId: 'PK-1025',
              name: 'Shabeer',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final completeBtn = find.byKey(const Key('btn_complete_intake'));
      await tester.ensureVisible(completeBtn);
      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // Verify DriverService status updated to 'parked'
      expect(DriverService.instance.intakes.firstWhere((i) => i.id == 'INT-9905').status, 'parked');

      // 3. Verify Manager Screen has updated from "WAITING FOR PARKING" to "PARKED"
      await tester.pumpWidget(const MaterialApp(home: ManagerDashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('PARKED'), findsWidgets);
      expect(find.textContaining('1 Parked'), findsOneWidget);
      expect(find.text('WAITING FOR PARKING'), findsNothing);

      // 4. Verify Assistant Manager Screen has updated: reflects PARKED & SECURED in single PARKED VEHICLES listing
      await tester.pumpWidget(const MaterialApp(home: AssistantManagerScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('PARKED VEHICLES'), findsOneWidget);
      expect(find.text('PARKED & SECURED'), findsOneWidget);
      expect(find.text('KL 10 AB 1234'), findsWidgets);
      expect(find.text('1 Awaiting Bay'), findsNothing);
    });

    testWidgets('Clicking Next does not update database/DriverService; database only updates upon clicking Keys Accepted as one-click button; Delete button removes intake', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DriverService.instance.clearIntakes();

      await tester.pumpWidget(
        MaterialApp(
          home: DriverIntakeScreen(
            driverProfile: const UserProfile(
              uid: 'driver-test-1',
              userId: 'PK-1025',
              name: 'Shabeer',
              role: 'DRIVER',
              status: 'ACTIVE',
            ),
            onLogout: () {},
            initialHasPhoto: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in all mandatory fields
      await tester.enterText(find.byKey(const Key('driver_customer_name_input')), 'Aarav Patel');
      await tester.enterText(find.byKey(const Key('driver_customer_phone_input')), '9876543210');
      await tester.enterText(find.byKey(const Key('driver_vehicle_reg_input')), 'MH 02 AB 1234');
      await tester.enterText(find.byKey(const Key('driver_vehicle_model_input')), 'Tesla Model 3');
      await tester.pumpAndSettle();

      // Click Next
      await tester.tap(find.byKey(const Key('btn_submit_intake')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Handover screen is displayed
      expect(find.text('Vehicle Slot & Key Handover'), findsWidgets);

      // CRITICAL CHECK: DriverService database MUST BE EMPTY because Next was clicked, not Keys Accepted!
      expect(DriverService.instance.intakes.isEmpty, isTrue);

      // Now tap "Keys Accepted"
      final keyToggle = find.byKey(const Key('key_status_toggle'));
      await tester.tap(keyToggle);
      await tester.pumpAndSettle();


      // CRITICAL CHECK: NOW the intake is saved with status 'waiting_for_parking'
      expect(DriverService.instance.intakes.length, 1);
      final intake = DriverService.instance.intakes.first;
      expect(intake.customerName, 'Aarav Patel');
      expect(intake.vehicleReg, 'MH 02 AB 1234');
      expect(intake.status, 'waiting_for_parking');

      // CRITICAL CHECK: One-click button verification
      // Tapping "Keys Accepted" again must NOT toggle it back or change status
      await tester.tap(keyToggle);
      await tester.pumpAndSettle();
      expect(find.text('Keys Accepted (In Custody)'), findsOneWidget);
      expect(DriverService.instance.intakes.first.status, 'waiting_for_parking');

      // CRITICAL CHECK: Delete button removes the intake
      final deleteBtn = find.byKey(const Key('btn_delete_intake'));
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Dialog confirmation
      expect(find.text('Delete Intake?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Intake'));
      await tester.pumpAndSettle();

      // Verify intake is completely removed from DriverService
      expect(DriverService.instance.intakes.isEmpty, isTrue);
    });

    testWidgets('ManagerDashboardScreen Paid and Unpaid metrics, filtering, and payment collection work properly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Setup 2 intakes: 1 waiting for parking, 1 parked
      final intake1 = VehicleIntakeModel(
        id: 'INT-PAY-01',
        customerName: 'Rahul Sharma',
        customerPhone: '+91 98765 43210',
        vehicleReg: 'KA 01 MJ 1111',
        vehicleModel: 'Honda City',
        driverId: 'PK-101',
        driverName: 'Driver One',
        siteName: 'Grand Hyatt',
        status: 'waiting_for_parking',
        createdAt: DateTime.now(),
      );

      final intake2 = VehicleIntakeModel(
        id: 'INT-PAY-02',
        customerName: 'Anita Verma',
        customerPhone: '+91 98765 43211',
        vehicleReg: 'KA 01 MJ 2222',
        vehicleModel: 'Hyundai Creta',
        driverId: 'PK-102',
        driverName: 'Driver Two',
        siteName: 'Grand Hyatt',
        status: 'parked',
        createdAt: DateTime.now(),
      );

      await DriverService.instance.submitIntake(intake1);
      await DriverService.instance.submitIntake(intake2);

      await tester.pumpWidget(const MaterialApp(home: ManagerDashboardScreen()));
      await tester.pumpAndSettle();

      // Check: Both vehicles are unpaid (1 waiting, 1 parked).
      // Unpaid metric tile should show 2, and Paid metric tile should show 0.
      expect(find.byKey(const Key('tile_filter_unpaid')), findsOneWidget);
      expect(find.byKey(const Key('tile_filter_paid')), findsOneWidget);
      expect(find.text('2'), findsWidgets); // Unpaid tile counter
      expect(find.text('0'), findsWidgets); // Paid tile counter

      // Filter by Unpaid using the filter chip or tile
      await tester.tap(find.byKey(const Key('tile_filter_unpaid')));
      await tester.pumpAndSettle();

      // Both vehicles still visible because both are unpaid
      expect(find.text('KA 01 MJ 1111'), findsOneWidget);
      expect(find.text('KA 01 MJ 2222'), findsOneWidget);

      // Collect payment on intake2 (KA 01 MJ 2222)
      final collectBtn = find.widgetWithText(ElevatedButton, 'Collect Payment').first;
      await tester.tap(collectBtn);
      await tester.pumpAndSettle();

      // In payment modal, tap confirm
      expect(find.text('Collect Valet Payment'), findsOneWidget);
      final confirmBtn = find.textContaining('Confirm ₹250');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // After payment: Paid = 1, Unpaid = 1
      expect(find.text('1'), findsWidgets);

      // Tap Paid filter tile
      await tester.tap(find.byKey(const Key('tile_filter_paid')));
      await tester.pumpAndSettle();

      // Now only the paid vehicle should be visible
      expect(find.text('KA 01 MJ 2222'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Vehicle Retrieval'), findsOneWidget);
    });

    testWidgets('ManagerDashboardScreen derives vehicle tariff directly from Admin site assign', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DriverService.instance.clearIntakes();

      // Configure Admin site with custom base fee of ₹320
      final adminSite = SiteModel(
        id: 'site-aerocity',
        name: 'Aerocity Hub',
        address: 'Terminal 3 Gate 4',
        totalBays: 100,
        baseFee: 320.0,
        createdAt: DateTime.now(),
      );
      SiteManager.instance.addSite(adminSite);

      final intake = VehicleIntakeModel(
        id: 'INT-SITE-TFF-01',
        customerName: 'Karan Mehra',
        customerPhone: '+91 99988 77766',
        vehicleReg: 'DL 01 AA 9999',
        vehicleModel: 'BMW 5 Series',
        driverId: 'PK-105',
        driverName: 'Driver Five',
        siteName: 'Aerocity Hub',
        status: 'parked',
        createdAt: DateTime.now(),
      );
      await DriverService.instance.submitIntake(intake);

      await tester.pumpWidget(const MaterialApp(home: ManagerDashboardScreen()));
      await tester.pumpAndSettle();

      // Open payment modal
      final collectBtn = find.widgetWithText(ElevatedButton, 'Collect Payment').first;
      await tester.tap(collectBtn);
      await tester.pumpAndSettle();

      // Verify the fee due displays the dynamic admin-configured fee of ₹320
      expect(find.text('Collect Valet Payment'), findsOneWidget);
      expect(find.text('₹320'), findsOneWidget);
      expect(find.textContaining('Confirm ₹320'), findsOneWidget);

      // Confirm payment and verify record in ManagerPaymentStats has amount 320.0
      await tester.tap(find.textContaining('Confirm ₹320'));
      await tester.pumpAndSettle();

      final record = ManagerPaymentStats.instance.records.last;
      expect(record.amount, 320.0);
    });

    testWidgets('Cash collection updates to Admin payments screen in respective site', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DriverService.instance.clearIntakes();
      ManagerPaymentStats.instance.reset();

      // Configure two distinct admin sites: Aster and Aerocity
      final siteAster = SiteModel(
        id: 'site-aster',
        name: 'Aster Medcity',
        address: 'Cheranalloor, Kochi',
        totalBays: 100,
        baseFee: 200.0,
        createdAt: DateTime.now(),
      );
      final siteAerocity = SiteModel(
        id: 'site-aero',
        name: 'Aerocity Hub',
        address: 'Gate 4, New Delhi',
        totalBays: 80,
        baseFee: 300.0,
        createdAt: DateTime.now(),
      );

      SiteManager.instance.clearAllSites();
      SiteManager.instance.addSite(siteAster);
      SiteManager.instance.addSite(siteAerocity);

      // Submit intake for Aster Medcity
      final intake = VehicleIntakeModel(
        id: 'INT-CASH-AST-01',
        customerName: 'Suresh Kumar',
        customerPhone: '+91 94471 23456',
        vehicleReg: 'KL 07 CC 7777',
        vehicleModel: 'Honda Elevate',
        driverId: 'PK-201',
        driverName: 'Driver Two',
        siteName: 'Aster Medcity • Valet Desk',
        status: 'parked',
        createdAt: DateTime.now(),
      );
      await DriverService.instance.submitIntake(intake);

      // 1. Manager collects Cash payment on Manager screen
      await tester.pumpWidget(const MaterialApp(home: ManagerDashboardScreen()));
      await tester.pumpAndSettle();

      final collectBtn = find.widgetWithText(ElevatedButton, 'Collect Payment').first;
      await tester.tap(collectBtn);
      await tester.pumpAndSettle();

      // Select Cash payment mode
      await tester.tap(find.text('Cash Collection'));
      await tester.pumpAndSettle();

      // Confirm cash payment (₹200)
      final confirmCashBtn = find.textContaining('Confirm ₹200 Cash Payment');
      expect(confirmCashBtn, findsOneWidget);
      await tester.tap(confirmCashBtn);
      await tester.pumpAndSettle();

      // Verify the record was attributed to Aster Medcity
      final lastPayment = ManagerPaymentStats.instance.records.last;
      expect(lastPayment.mode, 'cash');
      expect(lastPayment.amount, 200.0);
      expect(lastPayment.siteName, contains('Aster Medcity'));

      // 2. Open Admin PaymentsScreen for Aster Medcity
      SiteManager.instance.selectSite('Aster Medcity');
      await tester.pumpWidget(const MaterialApp(home: PaymentsScreen()));
      await tester.pumpAndSettle();

      // Verify Cash Collections on Admin screen reflects ₹200 and 1 txn
      expect(find.text('Cash Collections'), findsOneWidget);
      expect(find.text('₹200'), findsWidgets);
      expect(find.text('1 txns'), findsOneWidget);

      // Tap Cash Channel to view the Cash Collections Ledger modal
      await tester.tap(find.text('Cash Collections'));
      await tester.pumpAndSettle();

      // Verify modal opened with the ticket details for Aster Medcity
      expect(find.text('Cash Collections Ledger'), findsOneWidget);
      expect(find.text('KL 07 CC 7777'), findsOneWidget);
      expect(find.text('CASH'), findsWidgets);
    });

    testWidgets('Payment status remains paid when logging out and logging back into Manager screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Clean state
      DriverService.instance.clearIntakes();
      ManagerPaymentStats.instance.reset();

      final intake = VehicleIntakeModel(
        id: 'INT-LOGOUT-TEST-01',
        customerName: 'Kavita Nair',
        customerPhone: '+91 98888 77777',
        vehicleReg: 'KL 07 CC 8888',
        vehicleModel: 'BMW 330i',
        driverId: 'PK-301',
        driverName: 'Driver Sam',
        siteName: 'Grand Hyatt',
        status: 'parked',
        createdAt: DateTime.now(),
      );
      await DriverService.instance.submitIntake(intake);

      // 1. Initial login to ManagerDashboardScreen
      await tester.pumpWidget(const MaterialApp(home: ManagerDashboardScreen()));
      await tester.pumpAndSettle();

      // Collect payment (online)
      expect(find.text('KL 07 CC 8888'), findsOneWidget);
      final collectBtn = find.widgetWithText(ElevatedButton, 'Collect Payment').first;
      await tester.tap(collectBtn);
      await tester.pumpAndSettle();

      final confirmBtn = find.textContaining('Confirm ₹');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify it's now showing PAID (ONLINE) and "Vehicle Retrieval" button
      expect(find.text('PAID (ONLINE)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Vehicle Retrieval'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Collect Payment'), findsNothing);

      // Verify DriverService intake model also has isPaid == true and paymentStatus == 'paid_online'
      final updatedIntake = DriverService.instance.intakes.firstWhere((i) => i.id == 'INT-LOGOUT-TEST-01');
      expect(updatedIntake.isPaid, isTrue);
      expect(updatedIntake.paymentStatus, 'paid_online');

      // 2. Simulate Logout (unmount ManagerDashboardScreen and mount a dummy login screen)
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Login Screen'))));
      await tester.pumpAndSettle();
      expect(find.text('Login Screen'), findsOneWidget);

      // 3. Log back into ManagerDashboardScreen (fresh widget tree)
      await tester.pumpWidget(const MaterialApp(home: ManagerDashboardScreen()));
      await tester.pumpAndSettle();

      // CRITICAL ASSERTION: The vehicle MUST still be marked as PAID and NOT show as unpaid
      expect(find.text('KL 07 CC 8888'), findsOneWidget);
      expect(find.text('PAID (ONLINE)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Vehicle Retrieval'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Collect Payment'), findsNothing);
      expect(find.byKey(const Key('tile_filter_paid')), findsOneWidget);
      expect(find.text('1'), findsWidgets); // Paid count is 1
    });
  });
}

