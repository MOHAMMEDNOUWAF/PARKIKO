import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';

/// Represents an individual payment transaction collected by a Manager.
class ManagerPaymentRecord {
  final String id;
  final String vehicleName;
  final String plateNumber;
  final double amount;
  final String mode; // 'cash' or 'online'
  final String driverName;
  final String driverStaffId;
  final String siteName;
  final DateTime timestamp;

  const ManagerPaymentRecord({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.amount,
    required this.mode,
    required this.driverName,
    required this.driverStaffId,
    required this.siteName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicleName': vehicleName,
        'plateNumber': plateNumber,
        'amount': amount,
        'mode': mode,
        'driverName': driverName,
        'driverStaffId': driverStaffId,
        'siteName': siteName,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory ManagerPaymentRecord.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return ManagerPaymentRecord(
      id: (docId != null && docId.isNotEmpty) ? docId : (map['id'] as String? ?? ''),
      vehicleName: map['vehicleName'] as String? ?? '',
      plateNumber: map['plateNumber'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      mode: map['mode'] as String? ?? 'cash',
      driverName: map['driverName'] as String? ?? '',
      driverStaffId: map['driverStaffId'] as String? ?? '',
      siteName: map['siteName'] as String? ?? '',
      timestamp: parseDate(map['timestamp']),
    );
  }
}

/// Filtered slice of payment metrics for a specified time range or date.
class FilteredPaymentStats {
  final int totalCount;
  final int onlineCount;
  final int cashCount;
  final double totalRevenue;
  final double onlineRevenue;
  final double cashRevenue;
  final double onlineRatio;
  final double cashRatio;
  final List<ManagerPaymentRecord> records;

  const FilteredPaymentStats({
    required this.totalCount,
    required this.onlineCount,
    required this.cashCount,
    required this.totalRevenue,
    required this.onlineRevenue,
    required this.cashRevenue,
    required this.onlineRatio,
    required this.cashRatio,
    required this.records,
  });
}

/// Singleton service holding live valet payment collection data from the Manager page.
/// Both ManagerDashboardScreen (writer) and Admin PaymentsScreen (reader) use this.
class ManagerPaymentStats extends ChangeNotifier {
  ManagerPaymentStats._() {
    _initFirestoreSync();
  }
  static final instance = ManagerPaymentStats._();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSubscription;

  int _cashCount = 0;
  int _onlineCount = 0;
  double _cashRevenue = 0.0;
  double _onlineRevenue = 0.0;
  final List<ManagerPaymentRecord> _records = [];

  void _initFirestoreSync() {
    try {
      _firestoreSubscription = FirebaseFirestore.instance
          .collection(FirebaseService.paymentsCollection)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            for (final doc in snapshot.docs) {
              final remote = ManagerPaymentRecord.fromMap(doc.data(), doc.id);
              final idx = _records.indexWhere((r) => r.id == remote.id);
              if (idx != -1) {
                _records[idx] = remote;
              } else {
                _records.add(remote);
              }
            }
            _recalculateTotals();
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('[ManagerPaymentStats] Firestore sync notice: $e');
        },
      );
    } catch (e) {
      debugPrint('[ManagerPaymentStats] Firestore offline: $e');
    }
  }

  void _recalculateTotals() {
    int cCount = 0;
    int oCount = 0;
    double cRev = 0.0;
    double oRev = 0.0;

    for (final r in _records) {
      if (r.mode == 'cash') {
        cCount++;
        cRev += r.amount;
      } else {
        oCount++;
        oRev += r.amount;
      }
    }

    _cashCount = cCount;
    _onlineCount = oCount;
    _cashRevenue = cRev;
    _onlineRevenue = oRev;
  }

  /// Canonical site comparison accounting for suffixes like '• Valet Desk', '• Deck B1', etc.
  static bool isMatchingSite(String recordSite, String targetSite) {
    final rec = recordSite.trim().toLowerCase();
    final target = targetSite.trim().toLowerCase();

    if (target.isEmpty || target.startsWith('all sites') || target == 'no site selected') {
      return true;
    }
    if (rec.isEmpty) {
      return false;
    }
    if (rec == target) {
      return true;
    }

    String clean(String s) => s
        .toLowerCase()
        .replaceAll('• valet desk', '')
        .replaceAll('valet desk', '')
        .replaceAll('• deck b1', '')
        .replaceAll('deck b1', '')
        .replaceAll('& convention', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final cRec = clean(rec);
    final cTarget = clean(target);

    if (cRec.isEmpty || cTarget.isEmpty) {
      return false;
    }
    if (cRec == cTarget) {
      return true;
    }
    if (cRec.contains(cTarget) || cTarget.contains(cRec)) {
      return true;
    }

    // Check first word if long enough (e.g. 'Aster', 'Phoenix', 'Aerocity')
    final wordsRec = cRec.split(' ');
    final wordsTarget = cTarget.split(' ');
    if (wordsRec.isNotEmpty && wordsTarget.isNotEmpty) {
      if (wordsRec.first.length >= 4 && wordsRec.first == wordsTarget.first) {
        return true;
      }
    }

    return false;
  }

  void clear() {
    _cashCount = 0;
    _onlineCount = 0;
    _cashRevenue = 0.0;
    _onlineRevenue = 0.0;
    _records.clear();
    notifyListeners();
  }

  int get cashCount => _cashCount;
  int get onlineCount => _onlineCount;
  int get totalCount => _cashCount + _onlineCount;

  double get cashRevenue => _cashRevenue;
  double get onlineRevenue => _onlineRevenue;
  double get totalRevenue => _cashRevenue + _onlineRevenue;

  double get cashRatio => totalRevenue > 0
      ? (_cashRevenue / totalRevenue)
      : (totalCount > 0 ? (_cashCount / totalCount) : 0.0);

  double get onlineRatio => totalRevenue > 0
      ? (_onlineRevenue / totalRevenue)
      : (totalCount > 0 ? (_onlineCount / totalCount) : 0.0);

  List<ManagerPaymentRecord> get records => List.unmodifiable(_records);

  /// Seeds demo transaction records if explicitly requested.
  void seedForDemo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final seedItems = [
      // Today
      ManagerPaymentRecord(
        id: 'PAY-1001',
        vehicleName: 'BMW X5 xDrive',
        plateNumber: 'MH 01 DX 4022',
        amount: 250.0,
        mode: 'online',
        driverName: 'Rahul Verma',
        driverStaffId: 'ST-108',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.add(const Duration(hours: 10, minutes: 15)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1002',
        vehicleName: 'Audi Q7 Prestige',
        plateNumber: 'DL 03 CA 9918',
        amount: 300.0,
        mode: 'cash',
        driverName: 'Vikram Singh',
        driverStaffId: 'ST-082',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.add(const Duration(hours: 11, minutes: 40)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1003',
        vehicleName: 'Mercedes E-Class',
        plateNumber: 'MH 02 BG 3311',
        amount: 250.0,
        mode: 'online',
        driverName: 'Tanmay Sharma',
        driverStaffId: 'ST-044',
        siteName: 'Phoenix Palladium Mall',
        timestamp: today.add(const Duration(hours: 13, minutes: 20)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1004',
        vehicleName: 'Toyota Fortuner',
        plateNumber: 'KA 05 MN 1092',
        amount: 250.0,
        mode: 'online',
        driverName: 'Amit Kumar',
        driverStaffId: 'ST-044',
        siteName: 'Phoenix Palladium Mall',
        timestamp: today.add(const Duration(hours: 14, minutes: 5)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1005',
        vehicleName: 'Range Rover Velar',
        plateNumber: 'DL 01 AA 7700',
        amount: 500.0,
        mode: 'cash',
        driverName: 'Deepak Joshi',
        driverStaffId: 'ST-019',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.add(const Duration(hours: 15, minutes: 30)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1006',
        vehicleName: 'Porsche Macan GTS',
        plateNumber: 'MH 12 QP 5544',
        amount: 300.0,
        mode: 'online',
        driverName: 'Rahul Verma',
        driverStaffId: 'ST-108',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.add(const Duration(hours: 16, minutes: 45)),
      ),

      // Yesterday (1 day ago)
      ManagerPaymentRecord(
        id: 'PAY-1007',
        vehicleName: 'Volvo XC90',
        plateNumber: 'MH 04 ER 2291',
        amount: 350.0,
        mode: 'online',
        driverName: 'Karan Mehra',
        driverStaffId: 'ST-025',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.subtract(const Duration(days: 1, hours: -11)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1008',
        vehicleName: 'Hyundai Ioniq 5',
        plateNumber: 'DL 08 CC 4019',
        amount: 250.0,
        mode: 'cash',
        driverName: 'Vikram Singh',
        driverStaffId: 'ST-082',
        siteName: 'Phoenix Palladium Mall',
        timestamp: today.subtract(const Duration(days: 1, hours: -14)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1009',
        vehicleName: 'Mercedes C-Class',
        plateNumber: 'KA 03 MM 8812',
        amount: 250.0,
        mode: 'online',
        driverName: 'Tanmay Sharma',
        driverStaffId: 'ST-044',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.subtract(const Duration(days: 1, hours: -16)),
      ),

      // 3-5 days ago (Within Last 7 Days)
      ManagerPaymentRecord(
        id: 'PAY-1010',
        vehicleName: 'BMW 330i M Sport',
        plateNumber: 'MH 01 AB 1928',
        amount: 300.0,
        mode: 'online',
        driverName: 'Rahul Verma',
        driverStaffId: 'ST-108',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.subtract(const Duration(days: 3, hours: -12)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1011',
        vehicleName: 'Audi A6 Technology',
        plateNumber: 'DL 05 RT 7721',
        amount: 300.0,
        mode: 'cash',
        driverName: 'Amit Kumar',
        driverStaffId: 'ST-044',
        siteName: 'Phoenix Palladium Mall',
        timestamp: today.subtract(const Duration(days: 4, hours: -15)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1012',
        vehicleName: 'Jeep Grand Cherokee',
        plateNumber: 'KA 01 PP 4432',
        amount: 350.0,
        mode: 'online',
        driverName: 'Deepak Joshi',
        driverStaffId: 'ST-019',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.subtract(const Duration(days: 5, hours: -17)),
      ),

      // 10-20 days ago (Within Last 30 Days)
      ManagerPaymentRecord(
        id: 'PAY-1013',
        vehicleName: 'Jaguar F-Pace',
        plateNumber: 'MH 02 DD 9911',
        amount: 400.0,
        mode: 'online',
        driverName: 'Rahul Verma',
        driverStaffId: 'ST-108',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.subtract(const Duration(days: 12, hours: -11)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1014',
        vehicleName: 'Lexus RX 350h',
        plateNumber: 'DL 01 ZZ 1122',
        amount: 350.0,
        mode: 'cash',
        driverName: 'Vikram Singh',
        driverStaffId: 'ST-082',
        siteName: 'Phoenix Palladium Mall',
        timestamp: today.subtract(const Duration(days: 18, hours: -13)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1015',
        vehicleName: 'Land Rover Defender',
        plateNumber: 'KA 04 QQ 7788',
        amount: 500.0,
        mode: 'online',
        driverName: 'Tanmay Sharma',
        driverStaffId: 'ST-044',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.subtract(const Duration(days: 25, hours: -15)),
      ),

      // 40-70 days ago (Within Last 3 Months)
      ManagerPaymentRecord(
        id: 'PAY-1016',
        vehicleName: 'Porsche Cayenne Turbo',
        plateNumber: 'MH 01 TT 0001',
        amount: 600.0,
        mode: 'online',
        driverName: 'Rahul Verma',
        driverStaffId: 'ST-108',
        siteName: 'Grand Hyatt & Convention',
        timestamp: today.subtract(const Duration(days: 45, hours: -14)),
      ),
      ManagerPaymentRecord(
        id: 'PAY-1017',
        vehicleName: 'Mercedes S-Class',
        plateNumber: 'DL 03 SS 3333',
        amount: 500.0,
        mode: 'cash',
        driverName: 'Deepak Joshi',
        driverStaffId: 'ST-019',
        siteName: 'Phoenix Palladium Mall',
        timestamp: today.subtract(const Duration(days: 65, hours: -16)),
      ),
    ];

    for (final item in seedItems) {
      _records.add(item);
      if (item.mode == 'cash') {
        _cashCount += 1;
        _cashRevenue += item.amount;
      } else {
        _onlineCount += 1;
        _onlineRevenue += item.amount;
      }
    }
  }

  /// Filters transactions and recalculates totals based on the selected period, single calendar date, and optional site name.
  FilteredPaymentStats getFilteredStats({
    String? period,
    DateTime? selectedDate,
    String? siteName,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<ManagerPaymentRecord> filtered = _records;

    // Filter by site if a specific site is selected
    if (siteName != null &&
        siteName.isNotEmpty &&
        !siteName.startsWith('All Sites') &&
        siteName != 'No Site Selected') {
      filtered = filtered.where((r) => isMatchingSite(r.siteName, siteName)).toList();
    }

    if (selectedDate != null) {
      filtered = filtered.where((r) {
        return r.timestamp.year == selectedDate.year &&
            r.timestamp.month == selectedDate.month &&
            r.timestamp.day == selectedDate.day;
      }).toList();
    } else if (period == 'Today') {
      filtered = filtered.where((r) {
        return r.timestamp.year == today.year &&
            r.timestamp.month == today.month &&
            r.timestamp.day == today.day;
      }).toList();
    } else if (period == 'Last 7 Days') {
      final start = today.subtract(const Duration(days: 7));
      filtered = filtered.where((r) => !r.timestamp.isBefore(start)).toList();
    } else if (period == 'Last 3 Months') {
      final start = today.subtract(const Duration(days: 90));
      filtered = filtered.where((r) => !r.timestamp.isBefore(start)).toList();
    } else {
      // Default: 'Last 30 Days'
      final start = today.subtract(const Duration(days: 30));
      filtered = filtered.where((r) => !r.timestamp.isBefore(start)).toList();
    }

    int onlineCnt = 0;
    int cashCnt = 0;
    double onlineRev = 0.0;
    double cashRev = 0.0;

    for (final r in filtered) {
      if (r.mode == 'cash') {
        cashCnt++;
        cashRev += r.amount;
      } else {
        onlineCnt++;
        onlineRev += r.amount;
      }
    }

    final totalCnt = onlineCnt + cashCnt;
    final totalRev = onlineRev + cashRev;
    final onlineRatio = totalRev > 0
        ? (onlineRev / totalRev)
        : (totalCnt > 0 ? (onlineCnt / totalCnt) : 0.0);
    final cashRatio = totalRev > 0
        ? (cashRev / totalRev)
        : (totalCnt > 0 ? (cashCnt / totalCnt) : 0.0);

    return FilteredPaymentStats(
      totalCount: totalCnt,
      onlineCount: onlineCnt,
      cashCount: cashCnt,
      totalRevenue: totalRev,
      onlineRevenue: onlineRev,
      cashRevenue: cashRev,
      onlineRatio: onlineRatio,
      cashRatio: cashRatio,
      records: filtered,
    );
  }

  /// Records a new payment collection confirmed on the Manager page.
  void recordPayment({
    required String vehicleName,
    required String plateNumber,
    required double amount,
    required String mode,
    required String driverName,
    String driverStaffId = '',
    String siteName = '',
  }) {
    final cleanReg = plateNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final record = ManagerPaymentRecord(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}${cleanReg.isNotEmpty ? "-$cleanReg" : ""}',
      vehicleName: vehicleName,
      plateNumber: plateNumber,
      amount: amount,
      mode: mode,
      driverName: driverName,
      driverStaffId: driverStaffId,
      siteName: siteName,
      timestamp: DateTime.now(),
    );

    _records.add(record);

    if (mode == 'cash') {
      _cashCount += 1;
      _cashRevenue += amount;
    } else {
      _onlineCount += 1;
      _onlineRevenue += amount;
    }

    notifyListeners();
    _saveToFirestore(record);
  }

  Future<void> _saveToFirestore(ManagerPaymentRecord record) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseService.paymentsCollection)
          .doc(record.id)
          .set(record.toMap());
      debugPrint('[ManagerPaymentStats] Payment ${record.id} synced to Firestore.');
    } catch (e) {
      debugPrint('[ManagerPaymentStats] Firestore write notice (offline or test): $e');
    }
  }

  /// Finds an existing payment record for a given vehicle by intakeId or plate number (normalized).
  ManagerPaymentRecord? findPaymentForVehicle(String vehicleId, String plateNumber) {
    String clean(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final cleanTargetPlate = clean(plateNumber);
    final cleanTargetId = clean(vehicleId);

    for (final r in _records.reversed) {
      if (vehicleId.isNotEmpty && (r.id == vehicleId || clean(r.id).contains(cleanTargetId))) {
        return r;
      }
      final cleanRecPlate = clean(r.plateNumber);
      if (cleanTargetPlate.isNotEmpty && cleanRecPlate == cleanTargetPlate) {
        return r;
      }
    }
    return null;
  }

  /// Resets stats (useful for tests or clearing data).
  void reset() {
    _cashCount = 0;
    _onlineCount = 0;
    _cashRevenue = 0.0;
    _onlineRevenue = 0.0;
    _records.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
