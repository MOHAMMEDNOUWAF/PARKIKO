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
    if (lower == 'st-108' || lower == 'driver1' || lower == 'rahul') {
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
      expect(find.text('Please enter a valid vehicle license plate (e.g., KL 00 AA 0000).'), findsOneWidget);

      // Tap OCR Scanner button
      await tester.tap(find.byKey(const Key('btn_scan_ocr')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Verify that OCR filled a valid license plate
      final regController = tester.widget<TextField>(find.byKey(const Key('driver_vehicle_reg_input'))).controller!;
      expect(regController.text.length, 13); // format: LL NN LL NNNN

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
      expect(find.text('Tap to capture or upload vehicle photo'), findsOneWidget);

      // Tap dropzone to capture/upload
      await tester.tap(find.byKey(const Key('photo_dropzone')));
      await tester.pumpAndSettle();

      // Preview box reappears
      expect(find.byKey(const Key('photo_preview_box')), findsOneWidget);
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
      expect(find.text('Staff'), findsOneWidget);

      // Switch to Staff tab
      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();
      expect(find.text('Driver / Staff User ID'), findsOneWidget);

      // Enter driver credentials
      await tester.enterText(find.byKey(const Key('login_user_id_field')), 'ST-108');
      final pwFields = find.byType(TextField);
      await tester.enterText(pwFields.at(1), 'driver123');

      // Tap sign in
      await tester.tap(find.text('Sign In to Terminal'));
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
      expect(find.text('WhatsApp Receipt & E-Pass'), findsOneWidget);
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
}
