import 'package:flutter/material.dart';

/// Chip data for quick runner assignment buttons.
class QuickRunnerChipData {
  final String code;
  final String label;

  const QuickRunnerChipData(this.code, this.label);
}

/// Urgent retrieval queue item displayed with high priority alerting.
class UrgentRetrievalItem {
  final String id;
  final String orderNumber;
  final String vehicleName;
  final String plateNumber;
  final String guestName;
  final String sourceTag; // e.g. 'WhatsApp e-Pass', 'Manager Curbside', 'Bay Call'
  final IconData sourceIcon;
  final Color sourceBg;
  final Color sourceTextColor;
  final String paymentText;
  final bool isPaid;
  final String timerText;
  final String runnerStatusText;
  final String runnerPlaceholder;
  final List<QuickRunnerChipData> quickChips;
  final bool isAutoRunner;
  final TextEditingController runnerController;
  final FocusNode focusNode;

  UrgentRetrievalItem({
    required this.id,
    required this.orderNumber,
    required this.vehicleName,
    required this.plateNumber,
    required this.guestName,
    required this.sourceTag,
    required this.sourceIcon,
    required this.sourceBg,
    required this.sourceTextColor,
    required this.paymentText,
    required this.isPaid,
    required this.timerText,
    this.runnerStatusText = '5 available now',
    this.runnerPlaceholder = '108',
    this.quickChips = const [],
    this.isAutoRunner = false,
    String initialRunner = '',
  })  : runnerController = TextEditingController(text: initialRunner),
        focusNode = FocusNode();

  void dispose() {
    runnerController.dispose();
    focusNode.dispose();
  }
}

/// Parked vehicle ready for customer retrieval.
class ParkedVehicleItem {
  final String id;
  final String vehicleName;
  final String plateNumber;
  final String guestName;
  final String parkedBy;
  final String parkedAgo;
  final String slotPosition;
  final String vaultBox;
  final String paymentText;
  final bool isPaid;
  final bool isEv;
  final String status; // 'waiting_for_parking', 'parked', 'retrieval_requested', 'completed'
  final DateTime? retrievalRequestedAt;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String siteName;
  final String customerPhone;
  final DateTime? intakeTime;

  bool get isWaitingForParking => status == 'waiting_for_parking';
  bool get isParked => status == 'parked';
  bool get isParkedReady => status == 'parked';
  bool get isRetrievalRequested => status == 'retrieval_requested';
  bool get isCompleted => status == 'completed';

  const ParkedVehicleItem({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.guestName,
    required this.parkedBy,
    required this.parkedAgo,
    required this.slotPosition,
    required this.vaultBox,
    required this.paymentText,
    required this.isPaid,
    this.isEv = false,
    this.status = 'parked',
    this.retrievalRequestedAt,
    this.assignedDriverId,
    this.assignedDriverName,
    this.siteName = '',
    this.customerPhone = '',
    this.intakeTime,
  });

  ParkedVehicleItem copyWith({
    String? id,
    String? vehicleName,
    String? plateNumber,
    String? guestName,
    String? parkedBy,
    String? parkedAgo,
    String? slotPosition,
    String? vaultBox,
    String? paymentText,
    bool? isPaid,
    bool? isEv,
    String? status,
    DateTime? retrievalRequestedAt,
    String? assignedDriverId,
    String? assignedDriverName,
    String? siteName,
    String? customerPhone,
    DateTime? intakeTime,
  }) {
    return ParkedVehicleItem(
      id: id ?? this.id,
      vehicleName: vehicleName ?? this.vehicleName,
      plateNumber: plateNumber ?? this.plateNumber,
      guestName: guestName ?? this.guestName,
      parkedBy: parkedBy ?? this.parkedBy,
      parkedAgo: parkedAgo ?? this.parkedAgo,
      slotPosition: slotPosition ?? this.slotPosition,
      vaultBox: vaultBox ?? this.vaultBox,
      paymentText: paymentText ?? this.paymentText,
      isPaid: isPaid ?? this.isPaid,
      isEv: isEv ?? this.isEv,
      status: status ?? this.status,
      retrievalRequestedAt: retrievalRequestedAt ?? this.retrievalRequestedAt,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      siteName: siteName ?? this.siteName,
      customerPhone: customerPhone ?? this.customerPhone,
      intakeTime: intakeTime ?? this.intakeTime,
    );
  }
}

/// Completed or dispatched vehicle item for shift history log.
class HistoryDispatchItem {
  final String id;
  final String orderNumber;
  final String vehicleName;
  final String plateNumber;
  final String guestName;
  final String runnerLabel;
  final String timeLabel;
  final String paymentText;
  final String handoverTime;
  final bool isJustDispatched;

  const HistoryDispatchItem({
    required this.id,
    required this.orderNumber,
    required this.vehicleName,
    required this.plateNumber,
    required this.guestName,
    required this.runnerLabel,
    required this.timeLabel,
    required this.paymentText,
    required this.handoverTime,
    this.isJustDispatched = false,
  });
}
