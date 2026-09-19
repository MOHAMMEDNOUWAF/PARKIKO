import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_chip.dart';
import '../../../core/widgets/parkiko_logo.dart';
import '../models/valet_ticket.dart';
import '../providers/operations_provider.dart';

class LiveOperationsScreen extends ConsumerStatefulWidget {
  const LiveOperationsScreen({super.key});

  @override
  ConsumerState<LiveOperationsScreen> createState() => _LiveOperationsScreenState();
}

class _LiveOperationsScreenState extends ConsumerState<LiveOperationsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTicketDetails(ValetTicket ticket) {
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    color: AppColors.groundZero,
                    child: Text(
                      ticket.licensePlate,
                      style: AppTypography.licensePlate.copyWith(
                        color: AppColors.textHighLuminance,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  HudStatusChip(label: ticket.statusText, status: ticket.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${ticket.carModel} (${ticket.color})',
                style: AppTypography.headlineSmall.copyWith(color: AppColors.textHighLuminance),
              ),
              const SizedBox(height: 4),
              Text(
                'Customer: ${ticket.customerName} • ${ticket.customerPhone}',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                color: AppColors.groundZero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Location / Bay Slot:', style: AppTypography.labelMedium),
                    Text(
                      ticket.locationSlot,
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              if (ticket.status == OperationalStatus.occupied) ...[
                HudButton(
                  text: 'RETRIEVE TO PORCH LANE',
                  icon: Icons.directions_car,
                  variant: HudButtonVariant.primary,
                  onPressed: () {
                    ref.read(valetTicketsProvider.notifier).updateTicketStatus(
                          ticket.id,
                          OperationalStatus.available,
                          'RETRIEVED',
                          newSlot: 'Porch Lane (Ready)',
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${ticket.licensePlate} dispatched to Porch Lane'),
                        backgroundColor: AppColors.cardModule,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ] else if (ticket.status == OperationalStatus.available) ...[
                HudButton(
                  text: 'MARK HANDED OVER (COMPLETED)',
                  icon: Icons.check_circle_outline,
                  variant: HudButtonVariant.primary,
                  onPressed: () {
                    ref.read(valetTicketsProvider.notifier).updateTicketStatus(
                          ticket.id,
                          OperationalStatus.custom,
                          'COMPLETED',
                          newSlot: 'Released to Customer',
                        );
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
              ],
              // WhatsApp dispatch button
              HudButton(
                text: 'SEND WHATSAPP TICKET',
                icon: Icons.send,
                variant: HudButtonVariant.secondary,
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('WhatsApp receipt sent to ${ticket.customerPhone}'),
                      backgroundColor: AppColors.statusWhatsApp.withAlpha(200),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(filteredTicketsProvider);
    final allTickets = ref.watch(valetTicketsProvider);
    final currentFilter = ref.watch(operationsFilterProvider);
    final currentSite = ref.watch(selectedSiteProvider);

    final totalCount = allTickets.length;
    final parkedCount = allTickets.where((t) => t.status == OperationalStatus.occupied).length;
    final retrievedCount = allTickets.where((t) => t.status == OperationalStatus.available).length;
    final completedCount = allTickets.where((t) => t.status == OperationalStatus.custom).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ParkikoLogo(size: 22),
                const SizedBox(width: 8),
                Text(
                  'PARKIKO',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 6, height: 6, color: AppColors.statusAvailable),
              ],
            ),
            Text(
              '$currentSite • $totalCount Active in Network',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.onSurfaceVariant),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Telemetry synchronized with all terminal decks'),
                  backgroundColor: AppColors.cardModule,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Operational Live Context Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Operations',
                      style: AppTypography.headlineLargeMobile.copyWith(
                        color: AppColors.textHighLuminance,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.primary.withAlpha(100), width: 1),
                      ),
                      child: Text(
                        'CAPACITY: 74%',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search Input with Barcode Trigger
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.groundZero,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
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
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textHighLuminance),
                          onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                          decoration: InputDecoration(
                            hintText: 'Search ticket #, plate, or customer...',
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
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppColors.statusAvailable),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Camera barcode scanner active...'),
                              backgroundColor: AppColors.cardModule,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Status Metric Strip (4 cards)
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterCard(
                        title: 'ALL',
                        count: '$totalCount',
                        subtext: 'Arrived',
                        icon: Icons.directions_car,
                        filterKey: 'all',
                        currentFilter: currentFilter,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildFilterCard(
                        title: 'PARKED',
                        count: '$parkedCount',
                        subtext: 'In Slots',
                        icon: Icons.local_parking,
                        filterKey: 'parked',
                        currentFilter: currentFilter,
                        color: AppColors.statusOccupied,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildFilterCard(
                        title: 'READY',
                        count: '$retrievedCount',
                        subtext: 'At Porch',
                        icon: Icons.car_rental,
                        filterKey: 'retrieved',
                        currentFilter: currentFilter,
                        color: AppColors.statusAvailable,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildFilterCard(
                        title: 'DONE',
                        count: '$completedCount',
                        subtext: 'Released',
                        icon: Icons.task_alt,
                        filterKey: 'completed',
                        currentFilter: currentFilter,
                        color: AppColors.secondaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vehicle Operations Card Feed
          Expanded(
            child: tickets.isEmpty
                ? Center(
                    child: Text(
                      'No vehicles match the selected filter.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildVehicleCard(ticket),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard({
    required String title,
    required String count,
    required String subtext,
    required IconData icon,
    required String filterKey,
    required String currentFilter,
    required Color color,
  }) {
    final isSelected = currentFilter == filterKey;
    return InkWell(
      onTap: () => ref.read(operationsFilterProvider.notifier).state = filterKey,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : AppColors.groundZero,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? color : AppColors.outline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: AppTypography.titleMedium.copyWith(
                color: isSelected ? AppColors.textHighLuminance : AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtext,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.outline,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(ValetTicket ticket) {
    Color statusColor;
    if (ticket.status == OperationalStatus.available) {
      statusColor = AppColors.statusAvailable;
    } else if (ticket.status == OperationalStatus.occupied) {
      statusColor = AppColors.statusOccupied;
    } else {
      statusColor = AppColors.secondaryContainer;
    }

    final timeFormatter = DateFormat('HH:mm');

    return HudCard(
      padding: const EdgeInsets.all(14),
      leftAccentColor: statusColor,
      leftAccentWidth: 4,
      onTap: () => _showTicketDetails(ticket),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Plate, Ticket #, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: AppColors.surfaceContainerHigh,
                    child: Text(
                      ticket.licensePlate,
                      style: AppTypography.licensePlate.copyWith(
                        color: AppColors.textHighLuminance,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ticket.ticketNumber,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              HudStatusChip(label: ticket.statusText, status: ticket.status),
            ],
          ),
          const SizedBox(height: 10),

          // Car Model & Customer
          Row(
            children: [
              const Icon(Icons.directions_car, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                ticket.carModel,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHighLuminance,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${ticket.color})',
                style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Row(
              children: [
                const Icon(Icons.person, size: 13, color: AppColors.outline),
                const SizedBox(width: 4),
                Text(
                  ticket.customerName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text('•', style: TextStyle(color: AppColors.outline.withAlpha(150))),
                const SizedBox(width: 6),
                Text(
                  ticket.customerPhone,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Location Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.groundZero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: AppColors.secondaryContainer.withAlpha(40),
                      child: Text(
                        ticket.siteShort,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location:',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      ticket.status == OperationalStatus.available ? Icons.car_rental : Icons.local_parking,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.locationSlot,
                      style: AppTypography.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Footer: Staff & Timestamps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.staffName} (${ticket.staffId})',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 13, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    'In: ${timeFormatter.format(ticket.checkInTime)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
