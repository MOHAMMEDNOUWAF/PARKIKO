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
  String _activeSiteFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

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
        paymentMethod: 'UPI • Google Pay',
        timestamp: 'Today, 15:42 PM',
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
        paymentMethod: 'UPI • PhonePe',
        timestamp: 'Today, 16:25 PM',
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
        timestamp: 'Today, 16:15 PM',
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
        timestamp: 'Today, 16:30 PM',
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
        paymentMethod: 'UPI • Paytm',
        timestamp: 'Today, 15:10 PM',
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
        timestamp: 'Today, 14:10 PM',
        siteLocation: 'St. Regis Hotel',
        attendant: 'Rahul V. (Badge #115)',
        txnRef: 'CASH-8810',
        isSettled: true,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDigitalReceipt(PaymentRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withAlpha(150),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppColors.onSecondaryContainer, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Valet Receipt',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x33BEC9C2), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0x40BEC9C2), width: 1),
                          ),
                          child: Text(
                            record.licensePlate,
                            style: AppTypography.licensePlate.copyWith(color: AppColors.onSurface, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          record.customerName,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          record.customerPhone,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
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
                        const SizedBox(height: 6),
                        Text(
                          '₹${record.amount.toStringAsFixed(2)}',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Receipt Breakdown Rows
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x33BEC9C2), width: 1),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Valet Location', record.siteLocation),
                    _buildReceiptRow('Attendant In-Charge', record.attendant),
                    _buildReceiptRow('Payment Mode', record.paymentMethod),
                    _buildReceiptRow('Transaction Ref ID', record.txnRef),
                    _buildReceiptRow('Base Valet Fee', '₹${record.baseFee.toStringAsFixed(2)}'),
                    _buildReceiptRow('GST (18% SGST + CGST)', '₹${record.gstFee.toStringAsFixed(2)}'),
                    const Divider(color: Color(0x33BEC9C2)),
                    _buildReceiptRow('Net Settled Amount', '₹${record.amount.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // QR Verified Stamp
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verified Parkiko Digital E-Receipt', style: AppTypography.labelMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                        Text('Digitally timestamped & tax compliant', style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: HudButton(
                      text: 'Share WhatsApp',
                      icon: Icons.share,
                      variant: HudButtonVariant.secondary,
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('E-Receipt sent via WhatsApp to ${record.customerPhone}'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HudButton(
                      text: 'Print Slip',
                      icon: Icons.print,
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thermal receipt print triggered on Bluetooth terminal.'),
                            backgroundColor: AppColors.primary,
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

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isBold ? AppColors.onSurface : AppColors.onSurfaceVariant,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isBold ? AppColors.primary : AppColors.onSurface,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectPayment(PaymentRecord record) {
    String selectedMode = 'upi';
    final amountController = TextEditingController(text: record.amount.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withAlpha(150),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.payments, color: Color(0xFFB45309), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Collect Valet Payment',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
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
                  // Vehicle details highlight
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.licensePlate, style: AppTypography.licensePlate.copyWith(color: AppColors.onSurface, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${record.customerName} • ${record.customerPhone}', style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                        Text(record.ticketNo, style: AppTypography.labelSmall.copyWith(color: const Color(0xFF92400E), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Tariff Amount (₹)', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x66BEC9C2))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Select Payment Method', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedMode = 'upi'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedMode == 'upi' ? AppColors.secondaryContainer.withAlpha(60) : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedMode == 'upi' ? AppColors.primary : const Color(0x66BEC9C2),
                                width: selectedMode == 'upi' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.qr_code_2, color: AppColors.primary, size: 24),
                                const SizedBox(height: 4),
                                Text('UPI / QR Code', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedMode = 'cash'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedMode == 'cash' ? AppColors.secondaryContainer.withAlpha(60) : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedMode == 'cash' ? AppColors.primary : const Color(0x66BEC9C2),
                                width: selectedMode == 'cash' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.payments, color: AppColors.secondary, size: 24),
                                const SizedBox(height: 4),
                                Text('Cash Handover', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  HudButton(
                    text: 'Confirm Payment & Release Vehicle',
                    icon: Icons.verified,
                    onPressed: () {
                      final updatedIdx = _records.indexWhere((r) => r.ticketNo == record.ticketNo);
                      if (updatedIdx != -1) {
                        setState(() {
                          _records[updatedIdx] = _records[updatedIdx].copyWith(
                            isSettled: true,
                            paymentMethod: selectedMode == 'upi' ? 'UPI • Dynamic QR' : 'Cash Handover',
                            txnRef: selectedMode == 'upi' ? 'UPI-DYNAMIC-991' : 'CASH-SETTLED',
                          );
                        });
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment of ₹${amountController.text} confirmed for ${record.licensePlate}!'),
                          backgroundColor: AppColors.primary,
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

  @override
  Widget build(BuildContext context) {
    var filteredList = _records.where((r) {
      if (_activePaymentFilter == 'paid') return r.isSettled;
      if (_activePaymentFilter == 'pending') return !r.isSettled;
      if (_activePaymentFilter == 'upi') return r.paymentMethod.toLowerCase().contains('upi');
      if (_activePaymentFilter == 'cash') return r.paymentMethod.toLowerCase().contains('cash');
      return true;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((r) {
        final query = _searchQuery.toLowerCase();
        return r.licensePlate.toLowerCase().contains(query) ||
            r.ticketNo.toLowerCase().contains(query) ||
            r.customerName.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.local_parking, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Payments',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'Live Valet',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download, size: 16, color: AppColors.primary),
            label: const Text('Export', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Valet ledger exported to CSV/PDF successfully.'),
                  backgroundColor: AppColors.primary,
                ),
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
            // Site Filter Chip Bar (Horizontal scroll)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSiteChip('all', 'All Sites (₹48.2k)'),
                  const SizedBox(width: 8),
                  _buildSiteChip('aerocity', 'Aerocity T2 (₹21.4k)'),
                  const SizedBox(width: 8),
                  _buildSiteChip('cyberhub', 'CyberHub (₹14.2k)'),
                  const SizedBox(width: 8),
                  _buildSiteChip('southcity', 'South City (₹8.1k)'),
                  const SizedBox(width: 8),
                  _buildSiteChip('stregis', 'St. Regis (₹4.5k)'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Clean Total Collections Hero Card
            HudCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TOTAL COLLECTIONS',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  '+14.2% today',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.onSecondaryContainer, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹48,250',
                                style: AppTypography.headlineLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 32,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(184 tickets)',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withAlpha(70),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.payments, color: AppColors.primary, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0x33BEC9C2)),
                  const SizedBox(height: 10),

                  // Side-by-side split badges (UPI 76% / Cash 24%)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                      const SizedBox(width: 5),
                                      Text('UPI / Online', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('₹36,800', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(6)),
                                child: Text('76%', style: AppTypography.labelSmall.copyWith(color: AppColors.onSecondaryContainer, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                                      const SizedBox(width: 5),
                                      Text('Cash', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('₹11,450', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
                                child: Text('24%', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sites Overview 2x2 Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sites Overview',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.sync, size: 14, color: AppColors.primary),
                  label: const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  onPressed: () => setState(() => _activeSiteFilter = 'all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _buildSiteSummaryCard('Aerocity T2', '₹21,400', '82 tickets • 44%'),
                _buildSiteSummaryCard('CyberHub', '₹14,250', '54 tickets • 30%'),
                _buildSiteSummaryCard('South City', '₹8,100', '32 tickets • 17%'),
                _buildSiteSummaryCard('St. Regis', '₹4,500', '16 tickets • 9%'),
              ],
            ),
            const SizedBox(height: 16),

            // Transactions Search & Category Filter Pills
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66BEC9C2), width: 1),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.search, size: 18, color: AppColors.outline),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search vehicle or ticket #...',
                        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: AppColors.outline),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Filter Tabs / Status Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryPill('all', 'All (184)'),
                  const SizedBox(width: 6),
                  _buildCategoryPill('paid', 'Paid (180)'),
                  const SizedBox(width: 6),
                  _buildCategoryPill('pending', 'Pending (4)'),
                  const SizedBox(width: 6),
                  _buildCategoryPill('upi', 'UPI (132)'),
                  const SizedBox(width: 6),
                  _buildCategoryPill('cash', 'Cash (44)'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Transactions Stream Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions Stream',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Showing ${filteredList.length} transactions',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Transactions List
            for (final record in filteredList)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildTransactionCard(record),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteChip(String key, String label) {
    final isSelected = _activeSiteFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeSiteFilter = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0x66BEC9C2),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0617211D),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String key, String label) {
    final isSelected = _activePaymentFilter == key;
    return InkWell(
      onTap: () => setState(() => _activePaymentFilter = key),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0x66BEC9C2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSiteSummaryCard(String name, String amount, String subtext) {
    return HudCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppTypography.labelMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            ],
          ),
          Text(amount, style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(subtext, style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(PaymentRecord record) {
    return InkWell(
      onTap: () {
        if (record.isSettled) {
          _showDigitalReceipt(record);
        } else {
          _showCollectPayment(record);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: HudCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0x40BEC9C2), width: 1),
                      ),
                      child: Text(
                        record.licensePlate,
                        style: AppTypography.licensePlate.copyWith(color: AppColors.onSurface, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(record.ticketNo, style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
                  ],
                ),
                Text(
                  '₹${record.amount.toStringAsFixed(2)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: record.isSettled ? AppColors.primary : AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.customerName, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${record.siteLocation} • ${record.timestamp}', style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
                  ],
                ),
                HudStatusChip(
                  label: record.isSettled ? 'PAID' : 'COLLECT',
                  status: record.isSettled ? OperationalStatus.available : OperationalStatus.occupied,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
