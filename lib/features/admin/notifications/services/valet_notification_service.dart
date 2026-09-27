import 'dart:async';
import 'package:flutter/foundation.dart';

enum ValetNotificationType {
  newPickupJob,
  retrievalRequest,
  jobAssigned,
  managerInstruction,
  statusUpdate,
}

class ValetNotification {
  final String id;
  final ValetNotificationType type;
  final String title;
  final String body;
  final String ticketId;
  final String locationId;
  final DateTime receivedAt;
  final Map<String, dynamic>? payload;

  const ValetNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.ticketId,
    required this.locationId,
    required this.receivedAt,
    this.payload,
  });
}

/// Service providing notification dispatching & FCM hooks for valet operations.
class ValetNotificationService {
  static final ValetNotificationService instance = ValetNotificationService._internal();
  ValetNotificationService._internal();

  final _notificationsController = StreamController<ValetNotification>.broadcast();
  Stream<ValetNotification> get onNotification => _notificationsController.stream;

  final List<ValetNotification> _recentNotifications = [];
  List<ValetNotification> get recentNotifications => List.unmodifiable(_recentNotifications);

  /// Dispatches an operational notification to the valet client.
  void dispatchNotification({
    required ValetNotificationType type,
    required String title,
    required String body,
    required String ticketId,
    required String locationId,
    Map<String, dynamic>? payload,
  }) {
    final notification = ValetNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      body: body,
      ticketId: ticketId,
      locationId: locationId,
      receivedAt: DateTime.now(),
      payload: payload,
    );

    _recentNotifications.insert(0, notification);
    if (_recentNotifications.length > 50) {
      _recentNotifications.removeLast();
    }

    _notificationsController.add(notification);
    debugPrint('[ValetNotificationService] Dispatched ${type.name}: $title');
  }

  void clearNotifications() {
    _recentNotifications.clear();
  }
}
