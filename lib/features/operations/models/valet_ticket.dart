import '../../../core/widgets/hud_chip.dart';

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
  });

  ValetTicket copyWith({
    OperationalStatus? status,
    String? statusText,
    String? locationSlot,
    DateTime? checkOutTime,
    bool? isPaid,
  }) {
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
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      amount: amount,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticketNumber': ticketNumber,
      'licensePlate': licensePlate,
      'carModel': carModel,
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
    };
  }

  factory ValetTicket.fromMap(Map<String, dynamic> map, [String? docId]) {
    final statusStr = map['status'] as String? ?? 'available';
    final status = OperationalStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => OperationalStatus.available,
    );

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

    return ValetTicket(
      id: docId ?? map['id'] as String? ?? '',
      ticketNumber: map['ticketNumber'] as String? ?? '',
      licensePlate: map['licensePlate'] as String? ?? '',
      carModel: map['carModel'] as String? ?? '',
      color: map['color'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      siteName: map['siteName'] as String? ?? '',
      siteShort: map['siteShort'] as String? ?? '',
      locationSlot: map['locationSlot'] as String? ?? '',
      staffName: map['staffName'] as String? ?? '',
      staffId: map['staffId'] as String? ?? '',
      staffRole: map['staffRole'] as String? ?? '',
      status: status,
      statusText: map['statusText'] as String? ?? 'RETRIEVED',
      checkInTime: parseDate(map['checkInTime']),
      checkOutTime: parseNullableDate(map['checkOutTime']),
      amount: (map['amount'] as num?)?.toDouble() ?? 150.0,
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }
}
