import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/core/services/customer_retention_service.dart';
import 'package:parkiko/core/services/firebase_service.dart';
import 'package:parkiko/features/drivers/models/vehicle_intake_model.dart';
import 'package:parkiko/features/drivers/services/driver_service.dart';
import 'package:parkiko/core/widgets/hud_chip.dart';
import 'package:parkiko/features/admin/operations/models/valet_ticket.dart';
import 'package:parkiko/features/admin/operations/services/ticket_repository.dart';

void main() {
  group('Customer Data Retention (Last 90 Days) Policy Tests', () {
    setUp(() {
      DriverService.instance.clearIntakes();
      TicketRepository.instance.clearInMemory();
    });

    test('Retention duration constant is exactly 90 days', () {
      expect(CustomerRetentionService.retentionDays, 90);
      expect(FirebaseService.customerDataRetentionDays, 90);
    });

    test('isWithinRetention accurately identifies records inside or outside 90-day window', () {
      final now = DateTime.now();

      // Within 90 days
      final today = now;
      final yesterday = now.subtract(const Duration(days: 1));
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));
      final eightyNineDaysAgo = now.subtract(const Duration(days: 89));

      expect(CustomerRetentionService.isWithinRetention(today), isTrue);
      expect(CustomerRetentionService.isWithinRetention(yesterday), isTrue);
      expect(CustomerRetentionService.isWithinRetention(sixtyDaysAgo), isTrue);
      expect(CustomerRetentionService.isWithinRetention(eightyNineDaysAgo), isTrue);

      // Outside 90 days (expired customer details)
      final ninetyOneDaysAgo = now.subtract(const Duration(days: 91));
      final oneHundredDaysAgo = now.subtract(const Duration(days: 100));
      final oneYearAgo = now.subtract(const Duration(days: 365));

      expect(CustomerRetentionService.isWithinRetention(ninetyOneDaysAgo), isFalse);
      expect(CustomerRetentionService.isWithinRetention(oneHundredDaysAgo), isFalse);
      expect(CustomerRetentionService.isWithinRetention(oneYearAgo), isFalse);
    });

    test('DriverService retains customer intakes within 90 days and prunes expired records', () async {
      final now = DateTime.now();

      // Recent customer intake (today)
      final recentIntake = VehicleIntakeModel(
        id: 'INT-RECENT-01',
        customerName: 'John Doe',
        customerPhone: '9876543210',
        vehicleReg: 'KL 07 CC 1234',
        vehicleModel: 'Honda City',
        driverId: 'DRV-1',
        driverName: 'Driver One',
        siteName: 'Terminal 2 • Valet Desk',
        createdAt: now,
      );

      // 45 days old customer intake (within 90-day retention)
      final midAgeIntake = VehicleIntakeModel(
        id: 'INT-MID-02',
        customerName: 'Jane Smith',
        customerPhone: '9876543211',
        vehicleReg: 'KL 07 DD 5678',
        vehicleModel: 'Hyundai Creta',
        driverId: 'DRV-1',
        driverName: 'Driver One',
        siteName: 'Terminal 2 • Valet Desk',
        createdAt: now.subtract(const Duration(days: 45)),
      );

      // 120 days old customer intake (expired beyond 90-day retention)
      final expiredIntake = VehicleIntakeModel(
        id: 'INT-EXPIRED-03',
        customerName: 'Old Customer',
        customerPhone: '9876543212',
        vehicleReg: 'KL 07 EE 9999',
        vehicleModel: 'Toyota Innova',
        driverId: 'DRV-1',
        driverName: 'Driver One',
        siteName: 'Terminal 2 • Valet Desk',
        createdAt: now.subtract(const Duration(days: 120)),
      );

      // Submit intakes
      await DriverService.instance.submitIntake(recentIntake);
      await DriverService.instance.submitIntake(midAgeIntake);
      await DriverService.instance.submitIntake(expiredIntake);

      // Enforce retention policy
      await DriverService.instance.enforceRetentionPolicy();

      // Only intakes within 90 days should remain
      final currentIntakes = DriverService.instance.intakes;
      expect(currentIntakes.any((i) => i.id == 'INT-RECENT-01'), isTrue);
      expect(currentIntakes.any((i) => i.id == 'INT-MID-02'), isTrue);
      expect(currentIntakes.any((i) => i.id == 'INT-EXPIRED-03'), isFalse);
      expect(currentIntakes.length, 2);
    });

    test('TicketRepository prunes tickets beyond the 90-day customer data retention limit', () async {
      final now = DateTime.now();

      final recentTicket = ValetTicket(
        id: 'TCK-RECENT-101',
        ticketNumber: '#101',
        licensePlate: 'KL 07 AA 1111',
        carModel: 'BMW 330i',
        color: 'Black',
        customerName: 'Aarav Patel',
        customerPhone: '9811122233',
        siteName: 'Terminal 2',
        siteShort: 'T2',
        locationSlot: 'Deck A1',
        staffName: 'Staff 1',
        staffId: 'ST-01',
        staffRole: 'VALET',
        status: OperationalStatus.inTransit,
        statusText: 'VEHICLE RECEIVED',
        checkInTime: now,
        createdAt: now,
      );

      final expiredTicket = ValetTicket(
        id: 'TCK-EXPIRED-102',
        ticketNumber: '#102',
        licensePlate: 'KL 07 BB 2222',
        carModel: 'Audi A4',
        color: 'White',
        customerName: 'Expired Customer',
        customerPhone: '9844455566',
        siteName: 'Terminal 2',
        siteShort: 'T2',
        locationSlot: 'Deck A2',
        staffName: 'Staff 1',
        staffId: 'ST-01',
        staffRole: 'VALET',
        status: OperationalStatus.available,
        statusText: 'COMPLETED',
        checkInTime: now.subtract(const Duration(days: 95)),
        createdAt: now.subtract(const Duration(days: 95)),
      );

      await TicketRepository.instance.createTicket(recentTicket);
      await TicketRepository.instance.createTicket(expiredTicket);

      // Even if an expired ticket was added, createTicket prunes expired records
      final activeTickets = TicketRepository.instance.inMemoryTickets;
      expect(activeTickets.any((t) => t.id == 'TCK-RECENT-101'), isTrue);
      expect(activeTickets.any((t) => t.id == 'TCK-EXPIRED-102'), isFalse);
    });
  });
}
