import '../../../../core/widgets/hud_chip.dart';

/// Full operational lifecycle status state machine for valet tickets.
enum TicketLifecycleStatus {
  created,
  waitingForPickup,
  assigned,
  accepted,
  vehicleReceived,
  parking,
  parked,
  retrievalRequested,
  retrieving,
  vehicleRetrieved,
  vehicleReady,
  handover,
  completed,
  cancelled,
  lostKey,
  vehicleIssue,
  handoverFailed;

  String get value {
    switch (this) {
      case TicketLifecycleStatus.created:
        return 'CREATED';
      case TicketLifecycleStatus.waitingForPickup:
        return 'WAITING_FOR_PICKUP';
      case TicketLifecycleStatus.assigned:
        return 'ASSIGNED';
      case TicketLifecycleStatus.accepted:
        return 'ACCEPTED';
      case TicketLifecycleStatus.vehicleReceived:
        return 'VEHICLE_RECEIVED';
      case TicketLifecycleStatus.parking:
        return 'PARKING';
      case TicketLifecycleStatus.parked:
        return 'PARKED';
      case TicketLifecycleStatus.retrievalRequested:
        return 'RETRIEVAL_REQUESTED';
      case TicketLifecycleStatus.retrieving:
        return 'RETRIEVING';
      case TicketLifecycleStatus.vehicleRetrieved:
        return 'VEHICLE_RETRIEVED';
      case TicketLifecycleStatus.vehicleReady:
        return 'VEHICLE_READY';
      case TicketLifecycleStatus.handover:
        return 'HANDOVER';
      case TicketLifecycleStatus.completed:
        return 'COMPLETED';
      case TicketLifecycleStatus.cancelled:
        return 'CANCELLED';
      case TicketLifecycleStatus.lostKey:
        return 'LOST_KEY';
      case TicketLifecycleStatus.vehicleIssue:
        return 'VEHICLE_ISSUE';
      case TicketLifecycleStatus.handoverFailed:
        return 'HANDOVER_FAILED';
    }
  }

  static TicketLifecycleStatus fromString(String? raw) {
    if (raw == null || raw.isEmpty) return TicketLifecycleStatus.created;
    final normalized = raw.trim().toUpperCase().replaceAll(' ', '_');
    for (final status in TicketLifecycleStatus.values) {
      if (status.value == normalized || status.name.toUpperCase() == normalized) {
        return status;
      }
    }
    // Backward compatibility for legacy status keys
    if (normalized == 'AVAILABLE' || normalized == 'RETRIEVED') {
      return TicketLifecycleStatus.completed;
    }
    if (normalized == 'OCCUPIED' || normalized == 'PARKED') {
      return TicketLifecycleStatus.parked;
    }
    if (normalized == 'INTRANSIT' || normalized == 'IN_TRANSIT') {
      return TicketLifecycleStatus.retrieving;
    }
    if (normalized == 'INTAKE_REGISTERED') {
      return TicketLifecycleStatus.vehicleReceived;
    }
    return TicketLifecycleStatus.created;
  }

  bool canTransitionTo(TicketLifecycleStatus target) {
    if (this == target) return true;
    switch (this) {
      case TicketLifecycleStatus.created:
        return target == TicketLifecycleStatus.waitingForPickup ||
            target == TicketLifecycleStatus.assigned ||
            target == TicketLifecycleStatus.accepted ||
            target == TicketLifecycleStatus.vehicleReceived ||
            target == TicketLifecycleStatus.parking ||
            target == TicketLifecycleStatus.parked ||
            target == TicketLifecycleStatus.cancelled;
      case TicketLifecycleStatus.waitingForPickup:
        return target == TicketLifecycleStatus.assigned ||
            target == TicketLifecycleStatus.accepted ||
            target == TicketLifecycleStatus.cancelled;
      case TicketLifecycleStatus.assigned:
        return target == TicketLifecycleStatus.accepted ||
            target == TicketLifecycleStatus.waitingForPickup ||
            target == TicketLifecycleStatus.cancelled;
      case TicketLifecycleStatus.accepted:
        return target == TicketLifecycleStatus.vehicleReceived ||
            target == TicketLifecycleStatus.cancelled ||
            target == TicketLifecycleStatus.vehicleIssue;
      case TicketLifecycleStatus.vehicleReceived:
        return target == TicketLifecycleStatus.parking ||
            target == TicketLifecycleStatus.parked ||
            target == TicketLifecycleStatus.lostKey ||
            target == TicketLifecycleStatus.vehicleIssue;
      case TicketLifecycleStatus.parking:
        return target == TicketLifecycleStatus.parked ||
            target == TicketLifecycleStatus.vehicleIssue ||
            target == TicketLifecycleStatus.lostKey;
      case TicketLifecycleStatus.parked:
        return target == TicketLifecycleStatus.retrievalRequested ||
            target == TicketLifecycleStatus.retrieving ||
            target == TicketLifecycleStatus.lostKey ||
            target == TicketLifecycleStatus.vehicleIssue;
      case TicketLifecycleStatus.retrievalRequested:
        return target == TicketLifecycleStatus.retrieving ||
            target == TicketLifecycleStatus.lostKey ||
            target == TicketLifecycleStatus.vehicleIssue;
      case TicketLifecycleStatus.retrieving:
        return target == TicketLifecycleStatus.vehicleRetrieved ||
            target == TicketLifecycleStatus.vehicleReady ||
            target == TicketLifecycleStatus.lostKey ||
            target == TicketLifecycleStatus.vehicleIssue;
      case TicketLifecycleStatus.vehicleRetrieved:
        return target == TicketLifecycleStatus.vehicleReady ||
            target == TicketLifecycleStatus.handover ||
            target == TicketLifecycleStatus.vehicleIssue;
      case TicketLifecycleStatus.vehicleReady:
        return target == TicketLifecycleStatus.handover ||
            target == TicketLifecycleStatus.completed ||
            target == TicketLifecycleStatus.handoverFailed ||
            target == TicketLifecycleStatus.vehicleIssue;
      case TicketLifecycleStatus.handover:
        return target == TicketLifecycleStatus.completed ||
            target == TicketLifecycleStatus.handoverFailed ||
            target == TicketLifecycleStatus.vehicleIssue;
      case TicketLifecycleStatus.handoverFailed:
        return target == TicketLifecycleStatus.vehicleReady ||
            target == TicketLifecycleStatus.handover ||
            target == TicketLifecycleStatus.completed;
      case TicketLifecycleStatus.completed:
      case TicketLifecycleStatus.cancelled:
        return false;
      case TicketLifecycleStatus.lostKey:
      case TicketLifecycleStatus.vehicleIssue:
        return target == TicketLifecycleStatus.parked ||
            target == TicketLifecycleStatus.vehicleReady ||
            target == TicketLifecycleStatus.completed ||
            target == TicketLifecycleStatus.cancelled;
    }
  }

  OperationalStatus toOperationalStatus() {
    switch (this) {
      case TicketLifecycleStatus.parked:
        return OperationalStatus.occupied;
      case TicketLifecycleStatus.parking:
      case TicketLifecycleStatus.retrieving:
      case TicketLifecycleStatus.vehicleRetrieved:
        return OperationalStatus.inTransit;
      case TicketLifecycleStatus.waitingForPickup:
      case TicketLifecycleStatus.retrievalRequested:
        return OperationalStatus.queue;
      case TicketLifecycleStatus.completed:
      case TicketLifecycleStatus.vehicleReady:
      case TicketLifecycleStatus.handover:
        return OperationalStatus.available;
      default:
        return OperationalStatus.available;
    }
  }
}

class ValetTicket {
  final String id;
  final String ticketNumber;
  final String licensePlate;
  final String carModel;
  final String color;
  final String customerName;
  final String customerPhone;
  final String siteName;
  final String siteShort;
  final String locationSlot;
  final String staffName;
  final String staffId;
  final String staffRole;
  final OperationalStatus status;
  final String statusText;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double amount;
  final bool isPaid;

  // Multi-location & Lifecycle Specific Attributes
  final String organizationId;
  final String locationId;
  final String customerId;
  final String? assignedValetId;
  final String? retrievalValetId;
  final String? handoverValetId;
  final TicketLifecycleStatus lifecycleStatus;

  // Lifecycle Timestamps
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? vehicleReceivedAt;
  final DateTime? parkingStartedAt;
  final DateTime? parkedAt;
  final DateTime? retrievalRequestedAt;
  final DateTime? retrievalStartedAt;
  final DateTime? retrievedAt;
  final DateTime? vehicleReadyAt;
  final DateTime? handoverAt;
  final DateTime? completedAt;

  // Convenient Aliases
  String get vehicleNumber => licensePlate;
  String get vehicleModel => carModel;

  const ValetTicket({
    required this.id,
    required this.ticketNumber,
    required this.licensePlate,
    required this.carModel,
    required this.color,
    required this.customerName,
    required this.customerPhone,
    required this.siteName,
    required this.siteShort,
    required this.locationSlot,
    required this.staffName,
    required this.staffId,
    required this.staffRole,
    required this.status,
    required this.statusText,
    required this.checkInTime,
    this.checkOutTime,
    this.amount = 150.0,
    this.isPaid = false,
    this.organizationId = 'default_org',
    this.locationId = 'default_loc',
    this.customerId = '',
    this.assignedValetId,
    this.retrievalValetId,
    this.handoverValetId,
    this.lifecycleStatus = TicketLifecycleStatus.created,
    this.createdAt,
    this.assignedAt,
    this.acceptedAt,
    this.vehicleReceivedAt,
    this.parkingStartedAt,
    this.parkedAt,
    this.retrievalRequestedAt,
    this.retrievalStartedAt,
    this.retrievedAt,
    this.vehicleReadyAt,
    this.handoverAt,
    this.completedAt,
  });

  ValetTicket copyWith({
    OperationalStatus? status,
    String? statusText,
    String? locationSlot,
    DateTime? checkOutTime,
    bool? isPaid,
    String? organizationId,
    String? locationId,
    String? customerId,
    String? assignedValetId,
    String? retrievalValetId,
    String? handoverValetId,
    TicketLifecycleStatus? lifecycleStatus,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? vehicleReceivedAt,
    DateTime? parkingStartedAt,
    DateTime? parkedAt,
    DateTime? retrievalRequestedAt,
    DateTime? retrievalStartedAt,
    DateTime? retrievedAt,
    DateTime? vehicleReadyAt,
    DateTime? handoverAt,
    DateTime? completedAt,
  }) {
    final nextLifecycle = lifecycleStatus ?? this.lifecycleStatus;
    return ValetTicket(
      id: id,
      ticketNumber: ticketNumber,
      licensePlate: licensePlate,
      carModel: carModel,
      color: color,
      customerName: customerName,
      customerPhone: customerPhone,
      siteName: siteName,
      siteShort: siteShort,
      locationSlot: locationSlot ?? this.locationSlot,
      staffName: staffName,
      staffId: staffId,
      staffRole: staffRole,
      status: status ?? nextLifecycle.toOperationalStatus(),
      statusText: statusText ?? nextLifecycle.value,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      amount: amount,
      isPaid: isPaid ?? this.isPaid,
      organizationId: organizationId ?? this.organizationId,
      locationId: locationId ?? this.locationId,
      customerId: customerId ?? this.customerId,
      assignedValetId: assignedValetId ?? this.assignedValetId,
      retrievalValetId: retrievalValetId ?? this.retrievalValetId,
      handoverValetId: handoverValetId ?? this.handoverValetId,
      lifecycleStatus: nextLifecycle,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      vehicleReceivedAt: vehicleReceivedAt ?? this.vehicleReceivedAt,
      parkingStartedAt: parkingStartedAt ?? this.parkingStartedAt,
      parkedAt: parkedAt ?? this.parkedAt,
      retrievalRequestedAt: retrievalRequestedAt ?? this.retrievalRequestedAt,
      retrievalStartedAt: retrievalStartedAt ?? this.retrievalStartedAt,
      retrievedAt: retrievedAt ?? this.retrievedAt,
      vehicleReadyAt: vehicleReadyAt ?? this.vehicleReadyAt,
      handoverAt: handoverAt ?? this.handoverAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'vehicleNumber': licensePlate,
      'licensePlate': licensePlate,
      'carModel': carModel,
      'vehicleModel': carModel,
      'color': color,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'siteName': siteName,
      'siteShort': siteShort,
      'locationSlot': locationSlot,
      'staffName': staffName,
      'staffId': staffId,
      'staffRole': staffRole,
      'status': status.name,
      'statusText': statusText,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'amount': amount,
      'isPaid': isPaid,
      'organizationId': organizationId,
      'locationId': locationId,
      'customerId': customerId,
      'assignedValetId': assignedValetId,
      'retrievalValetId': retrievalValetId,
      'handoverValetId': handoverValetId,
      'lifecycleStatus': lifecycleStatus.value,
      'createdAt': createdAt?.toIso8601String() ?? checkInTime.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'vehicleReceivedAt': vehicleReceivedAt?.toIso8601String(),
      'parkingStartedAt': parkingStartedAt?.toIso8601String(),
      'parkedAt': parkedAt?.toIso8601String(),
      'retrievalRequestedAt': retrievalRequestedAt?.toIso8601String(),
      'retrievalStartedAt': retrievalStartedAt?.toIso8601String(),
      'retrievedAt': retrievedAt?.toIso8601String(),
      'vehicleReadyAt': vehicleReadyAt?.toIso8601String(),
      'handoverAt': handoverAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ValetTicket.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      try {
        final dynamic ts = val;
        return ts.toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        final dynamic ts = val;
        return ts.toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    final rawLifecycle = map['lifecycleStatus'] as String? ?? map['statusText'] as String?;
    final lifecycleStatus = TicketLifecycleStatus.fromString(rawLifecycle);

    final statusStr = map['status'] as String? ?? 'available';
    final status = OperationalStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => lifecycleStatus.toOperationalStatus(),
    );

    final slot = (map['locationSlot'] as String?) ?? '';

    return ValetTicket(
      id: docId ?? map['id'] as String? ?? '',
      ticketNumber: map['ticketNumber'] as String? ?? '',
      licensePlate: (map['licensePlate'] as String?) ?? (map['vehicleNumber'] as String?) ?? '',
      carModel: (map['carModel'] as String?) ?? (map['vehicleModel'] as String?) ?? '',
      color: map['color'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      siteName: map['siteName'] as String? ?? '',
      siteShort: map['siteShort'] as String? ?? '',
      locationSlot: slot,
      staffName: map['staffName'] as String? ?? '',
      staffId: map['staffId'] as String? ?? '',
      staffRole: map['staffRole'] as String? ?? '',
      status: status,
      statusText: map['statusText'] as String? ?? lifecycleStatus.value,
      checkInTime: parseDate(map['checkInTime'] ?? map['createdAt']),
      checkOutTime: parseNullableDate(map['checkOutTime'] ?? map['completedAt']),
      amount: (map['amount'] as num?)?.toDouble() ?? 150.0,
      isPaid: map['isPaid'] as bool? ?? false,
      organizationId: map['organizationId'] as String? ?? 'default_org',
      locationId: map['locationId'] as String? ?? 'default_loc',
      customerId: map['customerId'] as String? ?? '',
      assignedValetId: map['assignedValetId'] as String?,
      retrievalValetId: map['retrievalValetId'] as String?,
      handoverValetId: map['handoverValetId'] as String?,
      lifecycleStatus: lifecycleStatus,
      createdAt: parseNullableDate(map['createdAt']),
      assignedAt: parseNullableDate(map['assignedAt']),
      acceptedAt: parseNullableDate(map['acceptedAt']),
      vehicleReceivedAt: parseNullableDate(map['vehicleReceivedAt']),
      parkingStartedAt: parseNullableDate(map['parkingStartedAt']),
      parkedAt: parseNullableDate(map['parkedAt']),
      retrievalRequestedAt: parseNullableDate(map['retrievalRequestedAt']),
      retrievalStartedAt: parseNullableDate(map['retrievalStartedAt']),
      retrievedAt: parseNullableDate(map['retrievedAt']),
      vehicleReadyAt: parseNullableDate(map['vehicleReadyAt']),
      handoverAt: parseNullableDate(map['handoverAt']),
      completedAt: parseNullableDate(map['completedAt']),
    );
  }
}

