import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_chip.dart';

class PaymentRecord {
  final String ticketNo;
  final String licensePlate;
  final String customerName;
  final String customerPhone;
  final double amount;
  final double baseFee;
  final double gstFee;
  final String paymentMethod;
  final String timestamp;
  final String siteLocation;
  final String attendant;
  final String txnRef;
  final bool isSettled;

  const PaymentRecord({
    required this.ticketNo,
    required this.licensePlate,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.baseFee,
    required this.gstFee,
    required this.paymentMethod,
    required this.timestamp,
    required this.siteLocation,
    required this.attendant,
    required this.txnRef,
    required this.isSettled,
  });

  PaymentRecord copyWith({
    bool? isSettled,
    String? paymentMethod,
    String? txnRef,
  }) {
    return PaymentRecord(
      ticketNo: ticketNo,
      licensePlate: licensePlate,
      customerName: customerName,
      customerPhone: customerPhone,
      amount: amount,
      baseFee: baseFee,
      gstFee: gstFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      timestamp: timestamp,
      siteLocation: siteLocation,
      attendant: attendant,
      txnRef: txnRef ?? this.txnRef,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _activePaymentFilter = 'all';

  late List<PaymentRecord> _records;

  @override
  void initState() {
    super.initState();
    _records = [
      const PaymentRecord(
        ticketNo: '#VP-8821',
        licensePlate: 'DL-01-AB-1234',
        customerName: 'Vikram Malhotra',
        customerPhone: '+91 98112 44321',
        amount: 250,
        baseFee: 211.86,
        gstFee: 38.14,
        paymentMethod: 'UPI (Google Pay)',
        timestamp: '15:42 PM',
        siteLocation: 'Aerocity Grand (T2)',
        attendant: 'Suresh M. (Badge #302)',
        txnRef: 'UPI-4299104829',
        isSettled: true,
      ),
      const PaymentRecord(
        ticketNo: '#VP-8820',
        licensePlate: 'MH-01-DE-4411',
        customerName: 'Rohit Malhotra',
        customerPhone: '+91 98201 44552',
        amount: 250,
        baseFee: 211.86,
        gstFee: 38.14,
        paymentMethod: 'UPI (PhonePe)',
        timestamp: '16:25 PM',
        siteLocation: 'Aerocity Grand (T2)',
        attendant: 'Arjun S. (Badge #104)',
        txnRef: 'UPI-9928172641',
        isSettled: true,
      ),
      const PaymentRecord(
        ticketNo: '#VP-8819',
        licensePlate: 'KA-04-MB-2020',
        customerName: 'Amit S.',
        customerPhone: '+91 97110 55667',
        amount: 200,
        baseFee: 169.49,
        gstFee: 30.51,
        paymentMethod: 'Cash Handover',
        timestamp: '16:15 PM',
        siteLocation: 'South City Mall',
        attendant: 'Rakesh N. (Badge #099)',
        txnRef: 'CASH-8819',
        isSettled: true,
      ),
      const PaymentRecord(
        ticketNo: '#VP-8818',
        licensePlate: 'UP-16-BX-7720',
        customerName: 'Devendra Mehra',
        customerPhone: '+91 98200 45199',
        amount: 300,
        baseFee: 254.24,
        gstFee: 45.76,
        paymentMethod: 'Pending Collection',
        timestamp: '16:30 PM',
        siteLocation: 'South City Mall',
        attendant: 'Amit S. (Badge #110)',
        txnRef: 'UNPAID',
        isSettled: false,
      ),
      const PaymentRecord(
        ticketNo: '#VP-8815',
        licensePlate: 'DL-08-CC-1212',
        customerName: 'Rajesh Khanna',
        customerPhone: '+91 98711 22334',
        amount: 450,
        baseFee: 381.36,
        gstFee: 68.64,
        paymentMethod: 'UPI (Paytm)',
        timestamp: '15:10 PM',
        siteLocation: 'CyberHub Plaza',
        attendant: 'Vikram S. (Badge #082)',
        txnRef: 'UPI-1102938475',
        isSettled: true,
      ),
      const PaymentRecord(
        ticketNo: '#VP-8810',
        licensePlate: 'DL-01-AZ-7788',
        customerName: 'Sanjay Dutt',
        customerPhone: '+91 98100 99887',
        amount: 150,
        baseFee: 127.12,
        gstFee: 22.88,
        paymentMethod: 'Cash Handover',
        timestamp: '14:10 PM',
        siteLocation: 'St. Regis Hotel',
        attendant: 'Rahul V. (Badge #115)',
        txnRef: 'CASH-8810',
        isSettled: true,
      ),
    ];
  }

  void _showDigitalReceipt(PaymentRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.hudOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.secondaryContainer, width: 2),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Valet Receipt',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            record.ticketNo,
                            style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Vehicle & Amount Banner
              Container(
                padding: const EdgeInsets.all(12),
                color: AppColors.groundZero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.licensePlate,
                          style: AppTypography.licensePlate.copyWith(color: AppColors.textHighLuminance, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.customerName} • ${record.customerPhone}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        HudStatusChip(
                          label: record.isSettled ? 'PAID' : 'PENDING',
                          status: record.isSettled ? OperationalStatus.available : OperationalStatus.occupied,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${record.amount.toStringAsFixed(2)}',
                          style: AppTypography.headlineSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Receipt Breakdown Rows
              _buildReceiptRow('Valet Location', record.siteLocation),
              _buildReceiptRow('Attendant In-Charge', record.attendant),
              _buildReceiptRow('Payment Mode', record.paymentMethod),
              _buildReceiptRow('Transaction Ref ID', record.txnRef),
              _buildReceiptRow('Base Valet Fee', '₹${record.baseFee.toStringAsFixed(2)}'),
              _buildReceiptRow('GST (18% SGST + CGST)', '₹${record.gstFee.toStringAsFixed(2)}'),
              const Divider(color: AppColors.borderSubtle),
              _buildReceiptRow('Net Settled Amount', '₹${record.amount.toStringAsFixed(2)}', isBold: true),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: HudButton(
                      text: 'SHARE WHATSAPP',
                      icon: Icons.share,
                      variant: HudButtonVariant.secondary,
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('E-Receipt sent via WhatsApp to ${record.customerPhone}'),
                            backgroundColor: AppColors.statusWhatsApp.withAlpha(220),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HudButton(
                      text: 'PRINT SLIP',
                      icon: Icons.print,
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thermal receipt print triggered on Bluetooth terminal.'),
                            backgroundColor: AppColors.cardModule,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCollectPayment(PaymentRecord record) {
    String selectedMode = 'upi';
    final amountController = TextEditingController(text: record.amount.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.hudOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.statusOccupied, width: 2),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments, color: AppColors.statusOccupied, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Collect Valet Payment',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Vehicle details
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.groundZero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.licensePlate, style: AppTypography.licensePlate.copyWith(color: AppColors.textHighLuminance)),
                            Text('${record.customerName} • ${record.customerPhone}', style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                        Text(record.ticketNo, style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Tariff Amount (₹)', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.headlineSmall.copyWith(color: AppColors.textHighLuminance),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.groundZero,
                      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Select Payment Method', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedMode = 'upi'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedMode == 'upi' ? AppColors.primaryContainer.withAlpha(80) : AppColors.groundZero,
                              border: Border.all(
                                color: selectedMode == 'upi' ? AppColors.primary : AppColors.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.qr_code_2, color: AppColors.primary, size: 24),
                                const SizedBox(height: 4),
                                Text('UPI / QR CODE', style: AppTypography.labelSmall.copyWith(color: AppColors.textHighLuminance, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedMode = 'cash'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedMode == 'cash' ? AppColors.primaryContainer.withAlpha(80) : AppColors.groundZero,
                              border: Border.all(
                                color: selectedMode == 'cash' ? AppColors.primary : AppColors.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.money, color: AppColors.secondaryContainer, size: 24),
                                const SizedBox(height: 4),
                                Text('CASH HANDOVER', style: AppTypography.labelSmall.copyWith(color: AppColors.textHighLuminance, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HudButton(
                    text: 'CONFIRM PAYMENT & RELEASE',
                    icon: Icons.verified,
                    onPressed: () {
                      final updatedIdx = _records.indexWhere((r) => r.ticketNo == record.ticketNo);
                      if (updatedIdx != -1) {
                        setState(() {
                          _records[updatedIdx] = _records[updatedIdx].copyWith(
                            isSettled: true,
                            paymentMethod: selectedMode == 'upi' ? 'UPI (Dynamic QR)' : 'Cash Handover',
                            txnRef: selectedMode == 'upi' ? 'UPI-DYNAMIC-991' : 'CASH-SETTLED',
                          );
                        });
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment settled for ${record.licensePlate}. Vehicle released.'),
                          backgroundColor: AppColors.cardModule,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
          Text(
            value,
            style: isBold
                ? AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)
                : AppTypography.bodySmall.copyWith(color: AppColors.textHighLuminance, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _records.where((r) {
      if (_activePaymentFilter == 'upi' && !r.paymentMethod.contains('UPI')) return false;
      if (_activePaymentFilter == 'cash' && !r.paymentMethod.contains('Cash')) return false;
      if (_activePaymentFilter == 'pending' && r.isSettled) return false;
      return true;
    }).toList();

    final totalSettled = _records.where((r) => r.isSettled).fold<double>(0, (s, r) => s + r.amount);
    final upiSettled = _records.where((r) => r.isSettled && r.paymentMethod.contains('UPI')).fold<double>(0, (s, r) => s + r.amount);
    final cashSettled = _records.where((r) => r.isSettled && r.paymentMethod.contains('Cash')).fold<double>(0, (s, r) => s + r.amount);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Financials & Payments',
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting settlement statement as CSV...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settlement Summary Card
            HudCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.borderFocused,
              leftAccentColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TODAY’S REVENUE RECONCILIATION',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const HudStatusChip(label: 'BALANCED', status: OperationalStatus.available),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹${totalSettled.toStringAsFixed(2)}',
                    style: AppTypography.displayLargeMobile.copyWith(
                      color: AppColors.textHighLuminance,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderSubtle),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem('UPI & DIGITAL', '₹${upiSettled.toInt()}', AppColors.secondaryContainer),
                      _buildSummaryItem('CASH AT HAND', '₹${cashSettled.toInt()}', AppColors.primary),
                      _buildSummaryItem('TRANSACTIONS', '${_records.length}', AppColors.textHighLuminance),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settle Day Action
            HudButton(
              text: 'SETTLE CASH & CLOSE SHIFT',
              icon: Icons.account_balance_wallet,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.hudOverlay,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    title: Text('Lock Shift Alpha Reconciliation?', style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance)),
                    content: Text(
                      'Total Cash on Hand: ₹${cashSettled.toInt()} verified.\nThis will seal the shift register and dispatch digital audit receipts to accounting.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('CANCEL', style: TextStyle(color: AppColors.outline)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shift Alpha cash reconciliation locked & closed.'),
                              backgroundColor: AppColors.cardModule,
                            ),
                          );
                        },
                        child: const Text('CONFIRM SETTLEMENT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Transaction Filter Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRANSACTION LOG',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textHighLuminance,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    _buildFilterPill('all', 'ALL'),
                    const SizedBox(width: 4),
                    _buildFilterPill('upi', 'UPI'),
                    const SizedBox(width: 4),
                    _buildFilterPill('cash', 'CASH'),
                    const SizedBox(width: 4),
                    _buildFilterPill('pending', 'PENDING'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transaction List
            for (final record in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    if (record.isSettled) {
                      _showDigitalReceipt(record);
                    } else {
                      _showCollectPayment(record);
                    }
                  },
                  child: HudCard(
                    padding: const EdgeInsets.all(12),
                    leftAccentColor: record.isSettled ? AppColors.statusAvailable : AppColors.statusOccupied,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: AppColors.groundZero,
                              child: Icon(
                                record.paymentMethod.contains('UPI')
                                    ? Icons.qr_code_2
                                    : record.paymentMethod.contains('Cash')
                                        ? Icons.money
                                        : Icons.pending,
                                size: 20,
                                color: record.paymentMethod.contains('UPI')
                                    ? AppColors.secondaryContainer
                                    : record.paymentMethod.contains('Cash')
                                        ? AppColors.primary
                                        : AppColors.statusOccupied,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      record.licensePlate,
                                      style: AppTypography.licensePlate.copyWith(
                                        color: AppColors.textHighLuminance,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      record.ticketNo,
                                      style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${record.paymentMethod} • ${record.timestamp}',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+₹${record.amount.toInt()}',
                              style: AppTypography.titleMedium.copyWith(
                                color: record.isSettled ? AppColors.statusAvailable : AppColors.statusOccupied,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              record.isSettled ? 'SETTLED' : 'COLLECT',
                              style: AppTypography.labelSmall.copyWith(
                                color: record.isSettled ? AppColors.statusAvailable : AppColors.statusOccupied,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _activePaymentFilter == key;
    return InkWell(
      onTap: () => setState(() => _activePaymentFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: isSelected ? AppColors.primaryContainer : AppColors.groundZero,
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.textHighLuminance : AppColors.outline,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
