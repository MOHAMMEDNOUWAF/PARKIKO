import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_chip.dart';

class PaymentRecord {
  final String ticketNo;
  final String licensePlate;
  final double amount;
  final String paymentMethod;
  final String timestamp;
  final bool isSettled;

  const PaymentRecord({
    required this.ticketNo,
    required this.licensePlate,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
    required this.isSettled,
  });
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _activePaymentFilter = 'all';

  final List<PaymentRecord> _records = [
    const PaymentRecord(
      ticketNo: '#VP-1080',
      licensePlate: 'MH-01-DE-4411',
      amount: 250,
      paymentMethod: 'UPI (PhonePe)',
      timestamp: '16:25 PM',
      isSettled: true,
    ),
    const PaymentRecord(
      ticketNo: '#VP-1077',
      licensePlate: 'KA-04-MB-2020',
      amount: 200,
      paymentMethod: 'Cash Handover',
      timestamp: '16:15 PM',
      isSettled: true,
    ),
    const PaymentRecord(
      ticketNo: '#VP-1065',
      licensePlate: 'DL-08-CC-1212',
      amount: 450,
      paymentMethod: 'UPI (GPay)',
      timestamp: '15:40 PM',
      isSettled: true,
    ),
    const PaymentRecord(
      ticketNo: '#VP-1050',
      licensePlate: 'HR-26-DK-9009',
      amount: 500,
      paymentMethod: 'Corporate Fastag',
      timestamp: '14:35 PM',
      isSettled: true,
    ),
    const PaymentRecord(
      ticketNo: '#VP-1048',
      licensePlate: 'DL-01-AZ-7788',
      amount: 150,
      paymentMethod: 'Cash Handover',
      timestamp: '14:10 PM',
      isSettled: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _records.where((r) {
      if (_activePaymentFilter == 'upi' && !r.paymentMethod.contains('UPI')) return false;
      if (_activePaymentFilter == 'cash' && !r.paymentMethod.contains('Cash')) return false;
      return true;
    }).toList();

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
                    '₹28,450.00',
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
                      _buildSummaryItem('UPI & DIGITAL', '₹22,100', AppColors.secondaryContainer),
                      _buildSummaryItem('CASH AT HAND', '₹6,350', AppColors.primary),
                      _buildSummaryItem('TRANSACTIONS', '142', AppColors.textHighLuminance),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shift Alpha cash reconciliation locked & closed.'),
                    backgroundColor: AppColors.cardModule,
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
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transaction List
            for (final record in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HudCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: AppColors.groundZero,
                            child: Icon(
                              record.paymentMethod.contains('UPI') ? Icons.qr_code_2 : Icons.money,
                              size: 20,
                              color: record.paymentMethod.contains('UPI')
                                  ? AppColors.secondaryContainer
                                  : AppColors.primary,
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
                              color: AppColors.statusAvailable,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'SETTLED',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.statusAvailable,
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
