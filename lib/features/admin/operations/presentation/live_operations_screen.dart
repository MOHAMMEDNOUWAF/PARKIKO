import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/hud_button.dart';
import '../../../../core/widgets/hud_card.dart';
import '../../../../core/widgets/hud_chip.dart';
import '../../../../core/widgets/parkiko_logo.dart';
import '../models/valet_ticket.dart';
import '../providers/operations_provider.dart';
import '../../sites/services/site_manager.dart';
import '../../sites/presentation/add_site_wizard_screen.dart';

class LiveOperationsScreen extends ConsumerStatefulWidget {
  const LiveOperationsScreen({super.key});

  @override
  ConsumerState<LiveOperationsScreen> createState() => _LiveOperationsScreenState();
}

class _LiveOperationsScreenState extends ConsumerState<LiveOperationsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SiteManager.instance.addListener(_onSitesUpdated);
    _syncSite();
  }

  void _onSitesUpdated() {
    if (mounted) {
      _syncSite();
      setState(() {});
    }
  }

  void _syncSite() {
    if (SiteManager.instance.hasSites) {
      final selected = SiteManager.instance.selectedSite;
      if (selected.isNotEmpty && !selected.startsWith('All Sites')) {
        ref.read(selectedSiteProvider.notifier).state = selected;
      } else {
        ref.read(selectedSiteProvider.notifier).state =
            'All Sites (${SiteManager.instance.siteCount} Properties)';
      }
    }
  }

  @override
  void dispose() {
    SiteManager.instance.removeListener(_onSitesUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _showTicketDetails(ValetTicket ticket) {
    showModalBottomSheet(
      context: context,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x66BEC9C2), width: 1),
                    ),
                    child: Text(
                      ticket.licensePlate,
                      style: AppTypography.licensePlate.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ticket.isPaid
                              ? const Color(0xFF10B981).withAlpha(30)
                              : const Color(0xFFF59E0B).withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ticket.isPaid
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          ticket.isPaid ? 'PAID ₹${ticket.amount.toInt()}' : 'UNPAID ₹${ticket.amount.toInt()}',
                          style: TextStyle(
                            color: ticket.isPaid
                                ? const Color(0xFF047857)
                                : const Color(0xFFB45309),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      HudStatusChip(label: ticket.statusText, status: ticket.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${ticket.carModel} (${ticket.color})',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Customer: ${ticket.customerName} • ${ticket.customerPhone}',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Location / Bay Slot:', style: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
                    Text(
                      ticket.locationSlot,
                      style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              if (ticket.status == OperationalStatus.occupied) ...[
                HudButton(
                  text: 'Retrieve to Porch Lane',
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
                        content: Text('${ticket.licensePlate} dispatched to Porch Lane & saved to DB'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ] else if (ticket.status == OperationalStatus.available) ...[
                HudButton(
                  text: 'Mark Handed Over (Completed)',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${ticket.licensePlate} completed & saved to DB'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (!ticket.isPaid) ...[
                HudButton(
                  text: 'Mark Valet Fee Paid (₹${ticket.amount.toInt()})',
                  icon: Icons.payments_outlined,
                  variant: HudButtonVariant.secondary,
                  onPressed: () {
                    ref.read(valetTicketsProvider.notifier).markPaid(ticket.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Valet payment recorded for ${ticket.licensePlate}'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              // WhatsApp dispatch button
              HudButton(
                text: 'Send WhatsApp Digital Slip',
                icon: Icons.send,
                variant: HudButtonVariant.secondary,
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('WhatsApp receipt sent to ${ticket.customerPhone}'),
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
  }

  void _showSiteSelector() {
    final currentSite = ref.read(selectedSiteProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isAllSelected = currentSite.startsWith('All Sites') || SiteManager.instance.selectedSite == 'All Sites';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valet Site',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select your active operational location',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
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
                if (!SiteManager.instance.hasSites) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.domain_disabled, size: 40, color: AppColors.outline),
                        const SizedBox(height: 10),
                        Text(
                          'No Sites Configured',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All dummy locations removed. Configure a site to begin operations.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.add_business, size: 18),
                          label: const Text('Add New Site', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddSiteWizardScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Option: All Sites
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isAllSelected ? AppColors.secondaryContainer.withAlpha(80) : null,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isAllSelected ? AppColors.primary : AppColors.primaryContainer.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.domain, color: isAllSelected ? Colors.white : AppColors.primary, size: 20),
                    ),
                    title: Text(
                      'All Sites (${SiteManager.instance.siteCount} Properties)',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    trailing: isAllSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                        : null,
                    onTap: () {
                      ref.read(selectedSiteProvider.notifier).state =
                          'All Sites (${SiteManager.instance.siteCount} Properties)';
                      SiteManager.instance.selectSite('All Sites');
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 6),
                  // Individual Configured Sites
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: SiteManager.instance.sites.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final site = SiteManager.instance.sites[index];
                        final isSelected = !isAllSelected && (currentSite == site.name || SiteManager.instance.selectedSite == site.name);
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: isSelected ? AppColors.secondaryContainer.withAlpha(80) : AppColors.surfaceContainerLow,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.apartment,
                              color: isSelected ? Colors.white : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            site.name,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            site.address,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                              : null,
                          onTap: () {
                            ref.read(selectedSiteProvider.notifier).state = site.name;
                            SiteManager.instance.selectSite(site.name);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(filteredTicketsProvider);
    final currentFilter = ref.watch(operationsFilterProvider);
    final currentSite = ref.watch(selectedSiteProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const ParkikoLogo(size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Parkiko',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  currentSite.isEmpty ? 'All Sites' : currentSite,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.onSurfaceVariant),
            tooltip: 'Sync Database',
            onPressed: () {
              ref.invalidate(valetTicketsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Operational tickets synchronized with database'),
                  backgroundColor: AppColors.primary,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Operations',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Site Selector Chip Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showSiteSelector,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x66BEC9C2), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.domain, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              currentSite.isEmpty ? 'All Sites (0 Properties)' : currentSite,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_more, size: 14, color: AppColors.outline),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Input with Barcode Trigger
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x66BEC9C2), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0817211D),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
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
                        icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppColors.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Camera barcode scanner active...'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Status Metric Strip — 3 cards: Parked, Retrieved, Completed
                // Sourced live from the database tickets matching active site
                Builder(
                  builder: (context) {
                    final allTickets = ref.watch(valetTicketsProvider);
                    final siteTickets = allTickets.where((ticket) {
                      if (currentSite.isEmpty || currentSite.startsWith('All Sites')) return true;
                      return ticket.siteName.toLowerCase().contains(currentSite.toLowerCase()) ||
                          ticket.siteShort.toLowerCase().contains(currentSite.toLowerCase());
                    }).toList();

                    final parkedCount = siteTickets.where((t) => t.status == OperationalStatus.occupied).length;
                    final retrievedCount = siteTickets.where((t) => t.status == OperationalStatus.available).length;
                    final completedCount = siteTickets.where((t) => t.status == OperationalStatus.custom).length;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildFilterCard(
                            title: 'Parked',
                            count: '$parkedCount',
                            subtext: 'In Slots',
                            icon: Icons.local_parking,
                            filterKey: 'parked',
                            currentFilter: currentFilter,
                            cardBg: const Color(0xFFFDE8E8),
                            cardBorder: currentFilter == 'parked' ? AppColors.error : Colors.transparent,
                            textColor: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterCard(
                            title: 'Retrieved',
                            count: '$retrievedCount',
                            subtext: 'At Porch',
                            icon: Icons.car_rental,
                            filterKey: 'retrieved',
                            currentFilter: currentFilter,
                            cardBg: const Color(0xFFECFDF5),
                            cardBorder: currentFilter == 'retrieved' ? const Color(0xFF059669) : Colors.transparent,
                            textColor: const Color(0xFF047857),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterCard(
                            title: 'Completed',
                            count: '$completedCount',
                            subtext: 'Handed Over',
                            icon: Icons.task_alt,
                            filterKey: 'completed',
                            currentFilter: currentFilter,
                            cardBg: AppColors.secondaryContainer.withAlpha(90),
                            cardBorder: currentFilter == 'completed' ? AppColors.primary : Colors.transparent,
                            textColor: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Live Operations Vehicle Cards Feed
          Expanded(
            child: tickets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_car, size: 30, color: AppColors.outlineVariant),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No vehicles in queue',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Operational queue is currently empty (0 active tickets).\nWaiting for driver intakes to arrive from active valet staff.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                          ),
                        ],
                      ),
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
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
  }) {
    final isSelected = currentFilter == filterKey;
    return InkWell(
      onTap: () {
        if (currentFilter == filterKey) {
          ref.read(operationsFilterProvider.notifier).state = 'all';
        } else {
          ref.read(operationsFilterProvider.notifier).state = filterKey;
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cardBorder : const Color(0x33BEC9C2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0617211D),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: textColor),
                const SizedBox(width: 3),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              subtext,
              style: TextStyle(
                color: textColor.withAlpha(180),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(ValetTicket ticket) {
    final timeFormatter = DateFormat('HH:mm');

    return HudCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showTicketDetails(ticket),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Plate tag, Ticket #, Paid badge, Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0x40BEC9C2), width: 1),
                    ),
                    child: Text(
                      ticket.licensePlate,
                      style: AppTypography.licensePlate.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
              Row(
                children: [
                  if (ticket.isPaid)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                      ),
                      child: const Text(
                        'PAID',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  HudStatusChip(label: ticket.statusText, status: ticket.status),
                ],
              ),
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
                  color: AppColors.onSurface,
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

          // Location Box (Stitch Porch / Assigned bay)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x40BEC9C2), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ticket.siteShort,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticket.status == OperationalStatus.available ? 'Porch Location:' : 'Assigned Slot:',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: ticket.status == OperationalStatus.available ? const Color(0xFF059669) : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.locationSlot,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Footer: Staff & Timestamps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge, size: 14, color: AppColors.secondary),
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
                  const Icon(Icons.schedule, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'In: ${timeFormatter.format(ticket.checkInTime)} PM',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
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
