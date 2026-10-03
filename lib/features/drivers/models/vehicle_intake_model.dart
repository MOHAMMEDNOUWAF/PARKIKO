import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a registered vehicle intake completed by a valet driver.
class VehicleIntakeModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String vehicleReg;
  final String vehicleModel;
  final String? photoName;
  final String driverId;
  final String driverName;
  final String siteName;
  final String status; // 'intake_registered', 'waiting_for_parking', 'parked', 'retrieval_requested', 'completed'
  final DateTime createdAt;
  final String? keyTag;
  final String paymentStatus; // 'unpaid', 'paid_cash', 'paid_online'
  final String paymentMode; // 'cash', 'online', or ''
  final double? paymentAmount;
  final DateTime? paidAt;
  final DateTime? retrievalRequestedAt;
  final String? assignedDriverId;
  final String? assignedDriverName;

  bool get isPaid =>
      paymentStatus == 'paid_cash' ||
      paymentStatus == 'paid_online' ||
      status == 'completed' ||
      status == 'retrieved';

  bool get isUnpaid => !isPaid;
  bool get isRetrievalRequested => status == 'retrieval_requested';

  const VehicleIntakeModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleReg,
    required this.vehicleModel,
    this.photoName = 'IMG_INTAKE_0284.JPG',
    required this.driverId,
    required this.driverName,
    required this.siteName,
    this.status = 'intake_registered',
    required this.createdAt,
    this.keyTag,
    this.paymentStatus = 'unpaid',
    this.paymentMode = '',
    this.paymentAmount,
    this.paidAt,
    this.retrievalRequestedAt,
    this.assignedDriverId,
    this.assignedDriverName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vehicleReg': vehicleReg,
      'vehicleModel': vehicleModel,
      'photoName': photoName,
      'driverId': driverId,
      'driverName': driverName,
      'siteName': siteName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (keyTag != null) 'keyTag': keyTag,
      'paymentStatus': paymentStatus,
      'paymentMode': paymentMode,
      if (paymentAmount != null) 'paymentAmount': paymentAmount,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      if (retrievalRequestedAt != null)
        'retrievalRequestedAt': Timestamp.fromDate(retrievalRequestedAt!),
      if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
      if (assignedDriverName != null) 'assignedDriverName': assignedDriverName,
    };
  }

  factory VehicleIntakeModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return VehicleIntakeModel(
      id: (id != null && id.isNotEmpty) ? id : (map['id'] as String? ?? ''),
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      vehicleReg: map['vehicleReg'] as String? ?? '',
      vehicleModel: map['vehicleModel'] as String? ?? '',
      photoName: map['photoName'] as String? ?? 'IMG_INTAKE_0284.JPG',
      driverId: map['driverId'] as String? ?? 'ST-108',
      driverName: map['driverName'] as String? ?? 'Rahul V.',
      siteName: map['siteName'] as String? ?? 'Terminal 2 • Valet Desk',
      status: map['status'] as String? ?? 'intake_registered',
      createdAt: parseDate(map['createdAt']),
      keyTag: map['keyTag'] as String?,
      paymentStatus: map['paymentStatus'] as String? ?? 'unpaid',
      paymentMode: map['paymentMode'] as String? ?? '',
      paymentAmount: (map['paymentAmount'] as num?)?.toDouble(),
      paidAt: map['paidAt'] != null ? parseDate(map['paidAt']) : null,
      retrievalRequestedAt: map['retrievalRequestedAt'] != null
          ? parseDate(map['retrievalRequestedAt'])
          : null,
      assignedDriverId: map['assignedDriverId'] as String?,
      assignedDriverName: map['assignedDriverName'] as String?,
    );
  }

  VehicleIntakeModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? vehicleReg,
    String? vehicleModel,
    String? photoName,
    String? driverId,
    String? driverName,
    String? siteName,
    String? status,
    DateTime? createdAt,
    String? keyTag,
    String? paymentStatus,
    String? paymentMode,
    double? paymentAmount,
    DateTime? paidAt,
    DateTime? retrievalRequestedAt,
    String? assignedDriverId,
    String? assignedDriverName,
  }) {
    return VehicleIntakeModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehicleReg: vehicleReg ?? this.vehicleReg,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      photoName: photoName ?? this.photoName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      siteName: siteName ?? this.siteName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      keyTag: keyTag ?? this.keyTag,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paidAt: paidAt ?? this.paidAt,
      retrievalRequestedAt: retrievalRequestedAt ?? this.retrievalRequestedAt,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
    );
  }
}
