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
}
