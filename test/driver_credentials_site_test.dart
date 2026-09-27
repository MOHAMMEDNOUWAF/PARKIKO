import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/auth/models/user_profile.dart';
import 'package:parkiko/features/auth/services/firebase_auth_service.dart';
import 'package:parkiko/features/drivers/presentation/driver_intake_screen.dart';
import 'package:parkiko/features/drivers/services/driver_service.dart';
import 'package:parkiko/features/admin/sites/services/site_manager.dart';
import 'package:parkiko/features/admin/staff/models/staff_model.dart';
import 'package:parkiko/features/admin/staff/services/staff_manager.dart';

void main() {
  setUp(() {
    StaffManager.instance.clearStaff();
    DriverService.instance.clearIntakes();
  });

  group('Driver Credentials & Assigned Site Database Sync', () {
    test('Admin adds driver to database with ID, password, and assigned site', () async {
      final newDriver = const StaffModel(
        id: 'DRV-901',
        name: 'Arjun Nair',
        phone: '+91 98765 12345',
        role: 'driver',
        assignedSite: 'CyberHub Corporate Plaza',
        password: 'securePass99',
        metric: '0 Cars Handled',
        isOnDuty: true,
      );

      await StaffManager.instance.addStaff(newDriver);

      // Verify stored in database
      final fetched = await StaffManager.instance.findStaffById('DRV-901');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'DRV-901');
      expect(fetched.name, 'Arjun Nair');
      expect(fetched.password, 'securePass99');
      expect(fetched.assignedSite, 'CyberHub Corporate Plaza');
    });

    test('StaffManager validates credentials correctly', () async {
      await StaffManager.instance.addStaff(
        const StaffModel(
          id: 'DRV-902',
          name: 'Sunil Kumar',
          phone: '+91 98111 22233',
          role: 'driver',
          assignedSite: 'Grand Hyatt & Convention',
          password: 'pass8888',
        ),
      );

      // Correct password
      final success = await StaffManager.instance.findDriverByCredentials('DRV-902', 'pass8888');
      expect(success, isNotNull);
      expect(success!.name, 'Sunil Kumar');
      expect(success.assignedSite, 'Grand Hyatt & Convention');

      // Wrong password
      final fail = await StaffManager.instance.findDriverByCredentials('DRV-902', 'wrong1234');
      expect(fail, isNull);
    });

    test('FirebaseAuthService signs in driver from database and retrieves assigned site', () async {
      await StaffManager.instance.addStaff(
        const StaffModel(
          id: 'PK-DRV-77',
          name: 'Vikram Seth',
          phone: '+91 97777 88888',
          role: 'driver',
          assignedSite: 'JW Marriott Porch',
          password: 'pin4321',
        ),
      );

      final authService = FirebaseAuthService();

      // Attempt sign in with wrong password
      final failedResult = await authService.signInWithIdentifier(
        identifier: 'PK-DRV-77',
        password: 'wrongpassword',
      );
      expect(failedResult.isSuccess, isFalse);
      expect(failedResult.errorMessage, contains('Incorrect password'));

      // Attempt sign in with correct password
      final successResult = await authService.signInWithIdentifier(
        identifier: 'PK-DRV-77',
        password: 'pin4321',
      );
      expect(successResult.isSuccess, isTrue);
      expect(successResult.profile, isNotNull);

      final profile = successResult.profile!;
      expect(profile.userId, 'PK-DRV-77');
      expect(profile.name, 'Vikram Seth');
      expect(profile.isDriver, isTrue);
      expect(profile.organizationId, 'JW Marriott Porch');

      // Verify site was synchronized in SiteManager
      expect(SiteManager.instance.selectedSite, 'JW Marriott Porch');
    });

    testWidgets('DriverIntakeScreen displays authenticated driver name and assigned site', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const driverProfile = UserProfile(
        uid: 'staff_DRV-901',
        userId: 'DRV-901',
        name: 'Arjun Nair',
        role: 'DRIVER',
        status: 'ACTIVE',
        organizationId: 'CyberHub Corporate Plaza',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DriverIntakeScreen(
            driverProfile: driverProfile,
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify driver info in header
      expect(find.textContaining('Arjun Nair'), findsOneWidget);
      expect(find.textContaining('DRV-901'), findsOneWidget);

      // Verify assigned site displayed in header
      expect(find.textContaining('CyberHub Corporate Plaza'), findsWidgets);
    });
  });
}
