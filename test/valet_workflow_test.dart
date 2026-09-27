import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/auth/models/user_profile.dart';
import 'package:parkiko/features/drivers/models/attendance_model.dart';
import 'package:parkiko/features/drivers/services/attendance_repository.dart';
import 'package:parkiko/features/admin/operations/models/valet_ticket.dart';
import 'package:parkiko/features/admin/operations/services/audit_repository.dart';
import 'package:parkiko/features/admin/operations/services/key_record_repository.dart';
import 'package:parkiko/features/admin/operations/services/ticket_repository.dart';
import 'package:parkiko/features/admin/operations/services/vehicle_condition_repository.dart';
import 'package:parkiko/features/admin/staff/models/staff_model.dart';
import 'package:parkiko/features/admin/staff/services/staff_manager.dart';

void main() {
  group('Valet Profile & Role Model Tests', () {
    test('UserProfile correctly recognizes VALET role and legacy DRIVER alias', () {
      final valetProfile = UserProfile(
        uid: 'val_01',
        userId: 'VAL001',
        name: 'Rahul Kumar',
        role: 'VALET',
        status: 'ACTIVE',
        locationIds: ['LOC_01'],
      );
      expect(valetProfile.isValet, isTrue);
      expect(valetProfile.isDriver, isTrue);
      expect(valetProfile.isAdmin, isFalse);

      final legacyDriverProfile = UserProfile(
        uid: 'drv_01',
        userId: 'DRV001',
        name: 'Suresh P.',
        role: 'DRIVER',
        status: 'ACTIVE',
      );
      expect(legacyDriverProfile.isValet, isTrue);
      expect(legacyDriverProfile.isDriver, isTrue);

      final adminProfile = UserProfile(
        uid: 'adm_01',
        userId: 'ADM001',
        name: 'Admin User',
        role: 'ADMIN',
        status: 'ACTIVE',
      );
      expect(adminProfile.isValet, isFalse);
    });

    test('StaffModel calculates mobileLast4 and excludes passwords from Firestore serialization', () {
      final staff = StaffModel(
        id: 'VAL001',
        name: 'Rahul Kumar',
        role: 'VALET',
        phone: '9876543210',
        assignedSite: 'City Center Mall',
      );

      // Last 4 digits calculation
      expect(staff.mobileLast4, equals('3210'));
      expect(staff.isValet, isTrue);

      // Firestore map must NOT contain password
      final map = staff.toMap();
      expect(map.containsKey('password'), isFalse);
      expect(map['role'], equals('VALET'));
      expect(map['phone'], equals('9876543210'));

      // StaffManager verifies against mobile last 4
      expect(StaffManager.instance.verifyPassword('', '3210', staff: staff), isTrue);
      expect(StaffManager.instance.verifyPassword('', '0000', staff: staff), isFalse);
    });
  });

  group('Ticket State Machine & Concurrency Tests', () {
    setUp(() {
      TicketRepository.instance.clearInMemory();
      AuditRepository.instance.clearInMemory();
    });

    test('TicketLifecycleStatus validates normal and exceptional status transitions', () {
      // Normal flow checks
      expect(TicketLifecycleStatus.created.canTransitionTo(TicketLifecycleStatus.waitingForPickup), isTrue);
      expect(TicketLifecycleStatus.waitingForPickup.canTransitionTo(TicketLifecycleStatus.accepted), isTrue);
      expect(TicketLifecycleStatus.accepted.canTransitionTo(TicketLifecycleStatus.vehicleReceived), isTrue);
      expect(TicketLifecycleStatus.vehicleReceived.canTransitionTo(TicketLifecycleStatus.parking), isTrue);
      expect(TicketLifecycleStatus.parking.canTransitionTo(TicketLifecycleStatus.parked), isTrue);
      expect(TicketLifecycleStatus.parked.canTransitionTo(TicketLifecycleStatus.retrievalRequested), isTrue);
      expect(TicketLifecycleStatus.retrievalRequested.canTransitionTo(TicketLifecycleStatus.retrieving), isTrue);
      expect(TicketLifecycleStatus.retrieving.canTransitionTo(TicketLifecycleStatus.vehicleRetrieved), isTrue);
      expect(TicketLifecycleStatus.vehicleRetrieved.canTransitionTo(TicketLifecycleStatus.vehicleReady), isTrue);
      expect(TicketLifecycleStatus.vehicleReady.canTransitionTo(TicketLifecycleStatus.handover), isTrue);
      expect(TicketLifecycleStatus.handover.canTransitionTo(TicketLifecycleStatus.completed), isTrue);

      // Illegal transition check: Cannot jump from PARKED directly to COMPLETED
      expect(TicketLifecycleStatus.parked.canTransitionTo(TicketLifecycleStatus.completed), isFalse);

      // Exceptional states
      expect(TicketLifecycleStatus.waitingForPickup.canTransitionTo(TicketLifecycleStatus.cancelled), isTrue);
      expect(TicketLifecycleStatus.vehicleReceived.canTransitionTo(TicketLifecycleStatus.lostKey), isTrue);
      expect(TicketLifecycleStatus.parking.canTransitionTo(TicketLifecycleStatus.vehicleIssue), isTrue);
      expect(TicketLifecycleStatus.vehicleReady.canTransitionTo(TicketLifecycleStatus.handoverFailed), isTrue);
    });

    test('Two valets cannot claim the same pickup job simultaneously', () async {
      final ticket = ValetTicket(
        id: 'TICK_01',
        ticketNumber: 'PK-10254',
        licensePlate: 'KL 10 AB 1234',
        carModel: 'Toyota Fortuner',
        color: 'White',
        customerName: 'Anand V.',
        customerPhone: '9847000000',
        siteName: 'Grand Hyatt',
        siteShort: 'Grand',
        locationSlot: '',
        staffName: 'Desk',
        staffId: 'DESK_01',
        staffRole: 'FRONT_DESK',
        status: TicketLifecycleStatus.waitingForPickup.toOperationalStatus(),
        statusText: 'WAITING_FOR_PICKUP',
        checkInTime: DateTime.now(),
        lifecycleStatus: TicketLifecycleStatus.waitingForPickup,
      );

      await TicketRepository.instance.createTicket(ticket);

      // Valet 1 claims job
      final claimed = await TicketRepository.instance.acceptPickupJob(
        ticketId: 'TICK_01',
        valetId: 'VALET_01',
        locationId: 'Grand Hyatt',
      );
      expect(claimed.assignedValetId, equals('VALET_01'));
      expect(claimed.lifecycleStatus, equals(TicketLifecycleStatus.accepted));

      // Valet 2 attempts to claim the same job -> fails
      expect(
        () => TicketRepository.instance.acceptPickupJob(
          ticketId: 'TICK_01',
          valetId: 'VALET_02',
          locationId: 'Grand Hyatt',
        ),
        throwsA(isA<JobAlreadyClaimedException>()),
      );
    });

    test('Complete Valet Operational Workflow from Pickup to Handover with Audit Log', () async {
      final initialTicket = ValetTicket(
        id: 'TICK_100',
        ticketNumber: 'PK-20001',
        licensePlate: 'DL 01 AB 4920',
        carModel: 'BMW 5 Series',
        color: 'Black',
        customerName: 'Rohit Sharma',
        customerPhone: '9811000000',
        siteName: 'City Center Mall',
        siteShort: 'CCM',
        locationSlot: '',
        staffName: 'Intake Staff',
        staffId: 'STAFF_01',
        staffRole: 'VALET',
        status: TicketLifecycleStatus.waitingForPickup.toOperationalStatus(),
        statusText: 'WAITING_FOR_PICKUP',
        checkInTime: DateTime.now(),
        lifecycleStatus: TicketLifecycleStatus.waitingForPickup,
        organizationId: 'ORG_01',
        locationId: 'LOC_01',
      );

      await TicketRepository.instance.createTicket(initialTicket);

      // 1. Accept Pickup Job
      final accepted = await TicketRepository.instance.acceptPickupJob(
        ticketId: 'TICK_100',
        valetId: 'VALET_RAHUL',
        locationId: 'LOC_01',
      );
      expect(accepted.lifecycleStatus, equals(TicketLifecycleStatus.accepted));
      expect(accepted.acceptedAt, isNotNull);

      // 2. Receive Vehicle from Customer
      final received = await TicketRepository.instance.confirmVehicleReceived(
        ticketId: 'TICK_100',
        valetId: 'VALET_RAHUL',
      );
      expect(received.lifecycleStatus, equals(TicketLifecycleStatus.vehicleReceived));
      expect(received.vehicleReceivedAt, isNotNull);

      // 3. Start Parking
      final parking = await TicketRepository.instance.startParking(
        ticketId: 'TICK_100',
        valetId: 'VALET_RAHUL',
      );
      expect(parking.lifecycleStatus, equals(TicketLifecycleStatus.parking));
      expect(parking.parkingStartedAt, isNotNull);

      // 4. Confirm Vehicle Parked in Bay
      final parked = await TicketRepository.instance.confirmVehicleParked(
        ticketId: 'TICK_100',
        valetId: 'VALET_RAHUL',
        locationSlot: 'B-24',
      );
      expect(parked.lifecycleStatus, equals(TicketLifecycleStatus.parked));
      expect(parked.locationSlot, equals('B-24'));
      expect(parked.parkedAt, isNotNull);

      // 5. Manager Requests Retrieval
      final retrievalRequested = await TicketRepository.instance.requestRetrieval(
        ticketId: 'TICK_100',
        requestedBy: 'MANAGER_01',
      );
      expect(retrievalRequested.lifecycleStatus, equals(TicketLifecycleStatus.retrievalRequested));
      expect(retrievalRequested.retrievalRequestedAt, isNotNull);

      // 6. Valet Accepts Retrieval
      final retrieving = await TicketRepository.instance.acceptRetrieval(
        ticketId: 'TICK_100',
        valetId: 'VALET_RAHUL',
        locationId: 'LOC_01',
      );
      expect(retrieving.lifecycleStatus, equals(TicketLifecycleStatus.retrieving));
      expect(retrieving.retrievalValetId, equals('VALET_RAHUL'));
      expect(retrieving.retrievalStartedAt, isNotNull);

      // Second valet trying to accept same retrieval fails
      expect(
        () => TicketRepository.instance.acceptRetrieval(
          ticketId: 'TICK_100',
          valetId: 'VALET_OTHER',
          locationId: 'LOC_01',
        ),
        throwsA(isA<RetrievalAlreadyClaimedException>()),
      );

      // 7. Valet Confirms Vehicle Retrieved from Slot
      final retrieved = await TicketRepository.instance.confirmVehicleRetrieved(
        ticketId: 'TICK_100',
        valetId: 'VALET_RAHUL',
      );
      expect(retrieved.lifecycleStatus, equals(TicketLifecycleStatus.vehicleRetrieved));
      expect(retrieved.retrievedAt, isNotNull);

      // 8. Valet Confirms Vehicle Ready at Handover Area
      final ready = await TicketRepository.instance.confirmVehicleReady(
        ticketId: 'TICK_100',
        valetId: 'VALET_RAHUL',
      );
      expect(ready.lifecycleStatus, equals(TicketLifecycleStatus.vehicleReady));
      expect(ready.vehicleReadyAt, isNotNull);

      // 9. Customer Handover & Completion
      final completed = await TicketRepository.instance.completeHandover(
        ticketId: 'TICK_100',
        valetId: 'VALET_RAHUL',
      );
      expect(completed.lifecycleStatus, equals(TicketLifecycleStatus.completed));
      expect(completed.handoverAt, isNotNull);
      expect(completed.completedAt, isNotNull);
      expect(completed.handoverValetId, equals('VALET_RAHUL'));

      // Verify audit logs were tracked for each operational step
      final events = AuditRepository.instance.inMemoryEvents;
      expect(events.isNotEmpty, isTrue);
      final actions = events.map((e) => e.action).toList();
      expect(actions, contains('ACCEPT_PICKUP_JOB'));
      expect(actions, contains('CONFIRM_VEHICLE_RECEIVED'));
      expect(actions, contains('START_PARKING'));
      expect(actions, contains('CONFIRM_VEHICLE_PARKED'));
      expect(actions, contains('REQUEST_RETRIEVAL'));
      expect(actions, contains('ACCEPT_RETRIEVAL'));
      expect(actions, contains('CONFIRM_VEHICLE_RETRIEVED'));
      expect(actions, contains('CONFIRM_VEHICLE_READY'));
      expect(actions, contains('COMPLETE_HANDOVER'));
    });
  });

  group('Valet Attendance Management Tests', () {
    setUp(() {
      AttendanceRepository.instance.clearInMemory();
    });

    test('Valet can check in and prevents duplicate active check-ins', () async {
      final record = await AttendanceRepository.instance.checkIn(
        valetId: 'VALET_01',
        userId: 'USR_01',
        organizationId: 'ORG_01',
        locationId: 'LOC_01',
      );
      expect(record.status, equals(AttendanceStatus.working));
      expect(record.checkOutAt, isNull);

      // Second check-in while active throws DuplicateCheckInException
      expect(
        () => AttendanceRepository.instance.checkIn(
          valetId: 'VALET_01',
          userId: 'USR_01',
          organizationId: 'ORG_01',
          locationId: 'LOC_01',
        ),
        throwsA(isA<DuplicateCheckInException>()),
      );

      // Valet checks out
      final checkedOut = await AttendanceRepository.instance.checkOut(valetId: 'VALET_01');
      expect(checkedOut.status, equals(AttendanceStatus.completed));
      expect(checkedOut.checkOutAt, isNotNull);

      // Checking out again when no active shift throws NoActiveCheckInException
      expect(
        () => AttendanceRepository.instance.checkOut(valetId: 'VALET_01'),
        throwsA(isA<NoActiveCheckInException>()),
      );
    });
  });

  group('Vehicle Condition & Key Record Tests', () {
    setUp(() {
      VehicleConditionRepository.instance.clearInMemory();
      KeyRecordRepository.instance.clearInMemory();
    });

    test('Records and retrieves vehicle pre-inspection condition', () async {
      final condition = VehicleConditionRecord(
        id: 'cond_01',
        ticketId: 'PK-10254',
        vehicleNumber: 'KL 10 AB 1234',
        conditionNotes: 'Scratch on rear left bumper; alloy wheel clean.',
        photoUrls: ['https://cdn.parkiko.internal/photos/img_01.jpg'],
        recordedBy: 'VALET_01',
        recordedAt: DateTime.now(),
      );

      await VehicleConditionRepository.instance.recordCondition(condition);
      final retrieved = await VehicleConditionRepository.instance.getConditionForTicket('PK-10254');
      expect(retrieved, isNotNull);
      expect(retrieved!.vehicleNumber, equals('KL 10 AB 1234'));
      expect(retrieved.photoUrls.length, equals(1));
    });

    test('Records and tracks key management status', () async {
      await KeyRecordRepository.instance.updateKeyStatus(
        ticketId: 'PK-10254',
        keyTag: 'K-10254',
        status: KeyStatus.keyReceived,
        storageSlot: 'SLOT-A1',
        handledBy: 'VALET_01',
      );

      var key = await KeyRecordRepository.instance.getKeyRecordForTicket('PK-10254');
      expect(key, isNotNull);
      expect(key!.status, equals(KeyStatus.keyReceived));

      await KeyRecordRepository.instance.updateKeyStatus(
        ticketId: 'PK-10254',
        keyTag: 'K-10254',
        status: KeyStatus.keyStored,
        storageSlot: 'SLOT-A1',
        handledBy: 'VALET_01',
      );

      key = await KeyRecordRepository.instance.getKeyRecordForTicket('PK-10254');
      expect(key!.status, equals(KeyStatus.keyStored));
    });
  });
}
