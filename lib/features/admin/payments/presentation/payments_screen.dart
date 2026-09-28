import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/hud_card.dart';
import '../../../../core/widgets/parkiko_logo.dart';
import '../../sites/services/site_manager.dart';
import '../../sites/presentation/add_site_wizard_screen.dart';
import '../../../managers/manager/manager_payment_stats.dart';

/// Data models for Reports & Financials
class DayInfluxData {
  final String label;
  final double ratio;
  final String day;
  final String rev;
  final String cars;
  final bool isPeak;

  const DayInfluxData({
    required this.label,
    required this.ratio,
    required this.day,
    required this.rev,
    required this.cars,
    this.isPeak = false,
  });
}

class SiteFinancialData {
  final String grossRev;
  final String prevRev;
  final String revGrowth;
  final String vehicles;
  final String rate;
  final String avgTicket;
  final String dwell;
  final String collRate;
  final String claims;
  final String upiRev;
  final String posRev;
  final String cashRev;
  final double upiRatio;
  final double posRatio;
  final double cashRatio;
  final List<DayInfluxData> bars;

  const SiteFinancialData({
    required this.grossRev,
    required this.prevRev,
    required this.revGrowth,
    required this.vehicles,
    required this.rate,
    required this.avgTicket,
    required this.dwell,
    required this.collRate,
    required this.claims,
    required this.upiRev,
    required this.posRev,
    required this.cashRev,
    required this.upiRatio,
    required this.posRatio,
    required this.cashRatio,
    required this.bars,
  });
}

class TariffItemData {
  final String name;
  final String badge;
  final String countText;
  final String revText;
  final String pctText;
  final double revValue;
  final int carCount;

  const TariffItemData({
    required this.name,
    required this.badge,
    required this.countText,
    required this.revText,
    required this.pctText,
    required this.revValue,
    required this.carCount,
  });
}

class SiteHubPerformance {
  final String name;
  final String revenue;
  final String carsText;
  final int capacityPct;
  final Color dotColor;

  const SiteHubPerformance({
    required this.name,
    required this.revenue,
    required this.carsText,
    required this.capacityPct,
    required this.dotColor,
  });
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _currentSite = 'No Site Selected';
  String _currentPeriod = 'Last 30 Days';
  DateTime? _selectedDate;
  int? _selectedBarIndex;
  String _sortCriteria = 'rev'; // 'rev' or 'volume'

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  String _formatFullDate(DateTime date) {
    final weekday = _weekdayNames[date.weekday - 1];
    final month = _shortMonthNames[date.month - 1];
    return '$weekday, ${date.day} $month ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    final month = _shortMonthNames[date.month - 1];
    return '$month ${date.day}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Pre-configured Site Datasets matching Design - all start with zero
  static const SiteFinancialData _zeroSiteData = SiteFinancialData(
    grossRev: '₹0',
    prevRev: 'vs ₹0 prev. 30d',
    revGrowth: '0.0%',
    vehicles: '0',
    rate: '0 / day',
    avgTicket: 'Avg. ₹0 / ticket',
    dwell: '0h 00m',
    collRate: '0.0%',
    claims: '₹0 pending claims',
    upiRev: '₹0',
    posRev: '₹0',
    cashRev: '₹0',
    upiRatio: 0.0,
    posRatio: 0.0,
    cashRatio: 0.0,
    bars: [
      DayInfluxData(label: '₹0', ratio: 0.0, day: 'Monday', rev: '₹0', cars: '0 cars'),
      DayInfluxData(label: '₹0', ratio: 0.0, day: 'Tuesday', rev: '₹0', cars: '0 cars'),
      DayInfluxData(label: '₹0', ratio: 0.0, day: 'Wednesday', rev: '₹0', cars: '0 cars'),
      DayInfluxData(label: '₹0', ratio: 0.0, day: 'Thursday', rev: '₹0', cars: '0 cars'),
      DayInfluxData(label: '₹0', ratio: 0.0, day: 'Friday', rev: '₹0', cars: '0 cars'),
      DayInfluxData(label: '₹0', ratio: 0.0, day: 'Saturday', rev: '₹0', cars: '0 cars', isPeak: false),
      DayInfluxData(label: '₹0', ratio: 0.0, day: 'Sunday', rev: '₹0', cars: '0 cars'),
    ],
  );

  final Map<String, SiteFinancialData> _siteDatasets = {};

  final List<TariffItemData> _tariffs = [
    const TariffItemData(
      name: 'Standard Valet Intake',
      badge: 'Base',
      countText: '0 cars @ ₹150 base',
      revText: '₹0',
      pctText: '0% rev',
      revValue: 0,
      carCount: 0,
    ),
    const TariffItemData(
      name: 'VIP Porch Express',
      badge: 'Priority',
      countText: '0 cars @ ₹300 express',
      revText: '₹0',
      pctText: '0% rev',
      revValue: 0,
      carCount: 0,
    ),
    const TariffItemData(
      name: 'Overnight & Rollover Fee',
      badge: '>12 hrs',
      countText: '0 cars @ ₹500 standard',
      revText: '₹0',
      pctText: '0% rev',
      revValue: 0,
      carCount: 0,
    ),
  ];

  final List<SiteHubPerformance> _siteHubs = [];

  @override
  void initState() {
    super.initState();
    SiteManager.instance.addListener(_onSitesUpdated);
    ManagerPaymentStats.instance.addListener(_onSitesUpdated);
    _syncSites();
  }

  @override
  void dispose() {
    SiteManager.instance.removeListener(_onSitesUpdated);
    ManagerPaymentStats.instance.removeListener(_onSitesUpdated);
    super.dispose();
  }

  void _onSitesUpdated() {
    if (mounted) {
      setState(() {
        _syncSites();
      });
    }
  }

  void _syncSites() {
    final manager = SiteManager.instance;
    if (manager.hasSites) {
      for (final site in manager.sites) {
        if (!_siteDatasets.containsKey(site.name)) {
          _siteDatasets[site.name] = _zeroSiteData;
        }
      }
      if (manager.selectedSite.isNotEmpty && !manager.selectedSite.startsWith('All Sites')) {
        _currentSite = manager.selectedSite;
      } else {
        _currentSite = 'All Sites (${manager.siteCount} Properties)';
      }
      _updateSiteHubs();
    } else {
      _currentSite = 'No Site Selected';
      _siteDatasets.clear();
      _siteHubs.clear();
    }
  }

  void _updateSiteHubs() {
    _siteHubs.clear();
    final colors = [AppColors.primary, AppColors.secondary, AppColors.tertiary];
    final stats = ManagerPaymentStats.instance;
    for (int i = 0; i < SiteManager.instance.sites.length; i++) {
      final s = SiteManager.instance.sites[i];
      final siteStats = stats.getFilteredStats(
        period: _currentPeriod,
        selectedDate: _selectedDate,
        siteName: s.name,
      );
      final siteRev = siteStats.totalRevenue.toInt();
      final siteCars = siteStats.totalCount;
      final capPct = s.totalBays > 0
          ? ((siteCars / s.totalBays) * 100).clamp(0, 100).round()
          : 0;

      _siteHubs.add(SiteHubPerformance(
        name: s.name,
        revenue: '₹${siteRev.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
        carsText: '$siteCars cars (${s.totalBays} Bays)',
        capacityPct: capPct,
        dotColor: colors[i % colors.length],
      ));
    }
  }

  void _showToast(String message, [IconData icon = Icons.check_circle]) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.secondaryContainer, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(milliseconds: 2400),
      ),
    );
  }

  void _applyPeriod(String period) {
    setState(() {
      _currentPeriod = period;
      _selectedDate = null;
      _selectedBarIndex = null;
      _updateSiteHubs();
    });
    _showToast('Timeframe updated: $period', Icons.calendar_today);
  }

  void _applySingleDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _currentPeriod = 'Daily: ${_formatShortDate(date)}';
      _selectedBarIndex = null;
      _updateSiteHubs();
    });
    _showToast('Loaded individual report for ${_formatFullDate(date)}', Icons.event_available);
  }

  void _clearSingleDate() {
    setState(() {
      _selectedDate = null;
      _currentPeriod = 'Last 30 Days';
      _selectedBarIndex = null;
      _updateSiteHubs();
    });
    _showToast('Returned to Last 30 Days overview', Icons.refresh);
  }

  void _selectSite(String site) {
    final isAllSites = site.startsWith('All Sites');
    final normalized = isAllSites ? 'All Sites' : site;
    SiteManager.instance.selectSite(normalized);
    setState(() {
      _currentSite = isAllSites
          ? 'All Sites (${SiteManager.instance.siteCount} Properties)'
          : site;
      _selectedBarIndex = null;
      _updateSiteHubs();
    });
    if (isAllSites) {
      _showToast('All Sites Selected - Displaying aggregated metrics', Icons.domain);
    } else {
      _showToast('Switched site to: $site', Icons.business);
    }
  }

  void _sortTariffs(String criteria) {
    setState(() {
      _sortCriteria = criteria;
      if (criteria == 'volume') {
        _tariffs.sort((a, b) => b.carCount.compareTo(a.carCount));
        _showToast('Tariffs sorted by volume (car count)', Icons.swap_vert);
      } else {
        _tariffs.sort((a, b) => b.revValue.compareTo(a.revValue));
        _showToast('Tariffs sorted by gross revenue', Icons.arrow_downward);
      }
    });
  }

  // --- MODALS ---
  void _openSiteSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isAllSelected = SiteManager.instance.selectedSite == 'All Sites' || _currentSite.startsWith('All Sites');
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
                    key: const Key('site_choice_all_sites'),
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
                      Navigator.pop(ctx);
                      _selectSite('All Sites');
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
                        final isSelected = !isAllSelected && (SiteManager.instance.selectedSite == site.name || _currentSite == site.name);
                        return ListTile(
                          key: Key('site_choice_${site.name}'),
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
                            Navigator.pop(ctx);
                            _selectSite(site.name);
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

  void _openMiniCalendarModal() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDate = today.subtract(const Duration(days: 90));
    final maxDate = today;

    int displayedYear = (_selectedDate ?? today).year;
    int displayedMonth = (_selectedDate ?? today).month;
    DateTime? tempSelected = _selectedDate ?? today;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysInMonth = DateTime(displayedYear, displayedMonth + 1, 0).day;
            final prevMonthDays = DateTime(displayedYear, displayedMonth, 0).day;
            final firstWeekday = DateTime(displayedYear, displayedMonth, 1).weekday;
            final leadingBlanks = firstWeekday - 1;

            final prevMonthLastDay = DateTime(displayedYear, displayedMonth - 1, DateTime(displayedYear, displayedMonth, 0).day);
            final canGoPrev = !prevMonthLastDay.isBefore(minDate);

            final nextMonthFirstDay = DateTime(displayedYear, displayedMonth + 1, 1);
            final canGoNext = !nextMonthFirstDay.isAfter(maxDate);

            final totalDisplayed = leadingBlanks + daysInMonth;
            final totalCells = totalDisplayed <= 35 ? 35 : 42;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.outlineVariant.withAlpha(120),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Daily Report Calendar',
                                          style: AppTypography.titleMedium.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: AppColors.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Select any date in last 90 days (${_formatShortDate(minDate)} - ${_formatShortDate(maxDate)})',
                                          style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: const Key('btn_close_calendar_modal'),
                              icon: const Icon(Icons.close, size: 20, color: AppColors.onSurfaceVariant),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQuickDateChip(
                                label: 'Today',
                                date: today,
                                isSelected: tempSelected != null && _isSameDay(tempSelected!, today),
                                onTap: () {
                                  setModalState(() {
                                    displayedYear = today.year;
                                    displayedMonth = today.month;
                                    tempSelected = today;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildQuickDateChip(
                                label: 'Yesterday',
                                date: today.subtract(const Duration(days: 1)),
                                isSelected: tempSelected != null && _isSameDay(tempSelected!, today.subtract(const Duration(days: 1))),
                                onTap: () {
                                  final d = today.subtract(const Duration(days: 1));
                                  setModalState(() {
                                    displayedYear = d.year;
                                    displayedMonth = d.month;
                                    tempSelected = d;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildQuickDateChip(
                                label: '7 Days Ago',
                                date: today.subtract(const Duration(days: 7)),
                                isSelected: tempSelected != null && _isSameDay(tempSelected!, today.subtract(const Duration(days: 7))),
                                onTap: () {
                                  final d = today.subtract(const Duration(days: 7));
                                  setModalState(() {
                                    displayedYear = d.year;
                                    displayedMonth = d.month;
                                    tempSelected = d;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildQuickDateChip(
                                label: '30 Days Ago',
                                date: today.subtract(const Duration(days: 30)),
                                isSelected: tempSelected != null && _isSameDay(tempSelected!, today.subtract(const Duration(days: 30))),
                                onTap: () {
                                  final d = today.subtract(const Duration(days: 30));
                                  setModalState(() {
                                    displayedYear = d.year;
                                    displayedMonth = d.month;
                                    tempSelected = d;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.outlineVariant.withAlpha(60)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                key: const Key('btn_cal_prev_month'),
                                icon: const Icon(Icons.chevron_left, size: 22),
                                color: canGoPrev ? AppColors.primary : AppColors.outlineVariant.withAlpha(90),
                                onPressed: canGoPrev
                                    ? () {
                                        setModalState(() {
                                          if (displayedMonth == 1) {
                                            displayedYear--;
                                            displayedMonth = 12;
                                          } else {
                                            displayedMonth--;
                                          }
                                        });
                                      }
                                    : null,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _monthNames[displayedMonth - 1],
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$displayedYear',
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                key: const Key('btn_cal_next_month'),
                                icon: const Icon(Icons.chevron_right, size: 22),
                                color: canGoNext ? AppColors.primary : AppColors.outlineVariant.withAlpha(90),
                                onPressed: canGoNext
                                    ? () {
                                        setModalState(() {
                                          if (displayedMonth == 12) {
                                            displayedYear++;
                                            displayedMonth = 1;
                                          } else {
                                            displayedMonth++;
                                          }
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              for (final dayLabel in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'])
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      dayLabel,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: (dayLabel == 'SAT' || dayLabel == 'SUN')
                                            ? AppColors.primary.withAlpha(180)
                                            : AppColors.outline,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1.05,
                          ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            if (index < leadingBlanks) {
                              final prevDayNum = prevMonthDays - leadingBlanks + index + 1;
                              return Container(
                                alignment: Alignment.center,
                                child: Text(
                                  '$prevDayNum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.outlineVariant.withAlpha(70),
                                  ),
                                ),
                              );
                            }

                            if (index >= leadingBlanks + daysInMonth) {
                              final nextDayNum = index - (leadingBlanks + daysInMonth) + 1;
                              return Container(
                                alignment: Alignment.center,
                                child: Text(
                                  '$nextDayNum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.outlineVariant.withAlpha(70),
                                  ),
                                ),
                              );
                            }

                            final dayNumber = index - leadingBlanks + 1;
                            final cellDate = DateTime(displayedYear, displayedMonth, dayNumber);
                            final isSelectable = !cellDate.isBefore(minDate) && !cellDate.isAfter(maxDate);
                            final isSelected = tempSelected != null && _isSameDay(tempSelected!, cellDate);
                            final isTodayCell = _isSameDay(today, cellDate);

                            return Material(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isTodayCell && !isSelected
                                      ? AppColors.primary.withAlpha(22)
                                      : Colors.transparent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: isTodayCell && !isSelected
                                    ? const BorderSide(color: AppColors.primary, width: 1.5)
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                key: Key('cal_day_$dayNumber'),
                                borderRadius: BorderRadius.circular(10),
                                onTap: isSelectable
                                    ? () {
                                        setModalState(() {
                                          tempSelected = cellDate;
                                        });
                                      }
                                    : null,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$dayNumber',
                                        style: TextStyle(
                                          fontWeight: (isSelected || isTodayCell)
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 13,
                                          color: isSelected
                                              ? Colors.white
                                              : (isSelectable
                                                  ? AppColors.onSurface
                                                  : AppColors.outlineVariant.withAlpha(70)),
                                        ),
                                      ),
                                      if (isTodayCell && !isSelected)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.outlineVariant.withAlpha(70)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.event, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tempSelected != null
                                          ? 'Selected: ${_formatFullDate(tempSelected!)}'
                                          : 'No date selected',
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tempSelected != null
                                          ? (_isSameDay(tempSelected!, today)
                                              ? 'Today’s live daily telemetry'
                                              : 'Historical single-day shift report')
                                          : 'Tap any active date above',
                                      style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                key: const Key('btn_apply_day_report'),
                                icon: const Icon(Icons.analytics, size: 16),
                                label: const Text('View Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: tempSelected != null
                                    ? () {
                                        Navigator.pop(sheetContext);
                                        _applySingleDate(tempSelected!);
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickDateChip({
    required String label,
    required DateTime date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withAlpha(60),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }



  void _openTariffSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Tariff Mix Options', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.arrow_downward, color: AppColors.primary),
                  title: const Text('Sort by Highest Revenue Contribution'),
                  trailing: _sortCriteria == 'rev' ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _sortTariffs('rev');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_vert, color: AppColors.secondary),
                  title: const Text('Sort by Vehicle Volume (Car Count)'),
                  trailing: _sortCriteria == 'volume' ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _sortTariffs('volume');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: AppColors.outline),
                  title: const Text('Configure Base & Surcharge Rates'),
                  onTap: () {
                    Navigator.pop(context);
                    _showToast('Tariff configurations locked to site contract', Icons.lock);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openExportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        double progress = 0.0;
        bool isExporting = false;
        String statusText = 'Compiling audit...';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void runExportFlow(String type, String filename) {
              setSheetState(() {
                isExporting = true;
                progress = 0.0;
                statusText = 'Compiling $type...';
              });

              Timer.periodic(const Duration(milliseconds: 150), (timer) {
                if (!mounted) {
                  timer.cancel();
                  return;
                }
                setSheetState(() {
                  progress += 0.25;
                });
                if (progress >= 1.0) {
                  timer.cancel();
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showToast('Exported: $filename', Icons.download_done);
                    }
                  });
                }
              });
            }

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export Audit & Ledger', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('Select format and distribution method', style: AppTypography.bodySmall.copyWith(color: AppColors.outline), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (isExporting) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(statusText, style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                Text('${(progress * 100).toInt()}%', style: AppTypography.labelMedium.copyWith(color: AppColors.outline)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: AppColors.surfaceContainerHigh,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      _buildExportOption(
                        icon: Icons.table_view,
                        color: AppColors.primary,
                        title: 'Download CSV Spreadsheet',
                        desc: 'Full raw ticket timestamp, POS txns, runner ID',
                        onTap: () => runExportFlow('CSV Spreadsheet', 'parkiko_audit_sept2024.csv'),
                      ),
                      const SizedBox(height: 8),
                      _buildExportOption(
                        icon: Icons.picture_as_pdf,
                        color: AppColors.secondary,
                        title: 'Export Formatted PDF Report',
                        desc: 'Branded charts, revenue breakdown & signatures',
                        onTap: () => runExportFlow('PDF Executive Summary', 'parkiko_executive_report.pdf'),
                      ),
                      const SizedBox(height: 8),
                      _buildExportOption(
                        icon: Icons.mail,
                        color: AppColors.onSurfaceVariant,
                        title: 'Email Audit to Admin',
                        desc: 'Send direct to finance and GM inbox',
                        onTap: () => runExportFlow('Email Dispatch', 'sent to admin@parkiko.com'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withAlpha(90)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                  Text(desc, style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeData = _siteDatasets[_currentSite] ?? _zeroSiteData;

    final isDailyMode = _selectedDate != null;

    // Dynamic multipliers for period scaling
    double multiplier = 1.0;
    if (_currentPeriod == 'Today') multiplier = 0.035;
    if (_currentPeriod == 'Last 7 Days') multiplier = 0.24;
    if (_currentPeriod == 'Last 3 Months') multiplier = 2.85;

    if (isDailyMode) {
      const dayWeights = [0.030, 0.032, 0.034, 0.037, 0.045, 0.055, 0.048];
      final dayIndex = _selectedDate!.weekday - 1;
      multiplier = dayWeights[dayIndex.clamp(0, 6)];
    }

    final activeSiteName = SiteManager.instance.selectedSite;
    final paymentStats = ManagerPaymentStats.instance;
    final filteredStats = paymentStats.getFilteredStats(
      period: _currentPeriod,
      selectedDate: _selectedDate,
      siteName: activeSiteName,
    );
    final hasManagerPayments = filteredStats.totalCount > 0;

    final baseRevNum = int.tryParse(activeData.grossRev.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final baseVehNum = int.tryParse(activeData.vehicles.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final scaledRev = (baseRevNum * multiplier).round();
    final scaledVeh = (baseVehNum * multiplier).round();

    final displayRev = hasManagerPayments
        ? '₹${filteredStats.totalRevenue.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
        : ((!isDailyMode && _currentPeriod == 'Last 30 Days')
            ? activeData.grossRev
            : '₹${scaledRev.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}');
    final displayVeh = hasManagerPayments
        ? '${filteredStats.totalCount}'
        : ((!isDailyMode && _currentPeriod == 'Last 30 Days')
            ? activeData.vehicles
            : scaledVeh.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const ParkikoLogo(size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reports & Financials',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Multi-Site Valet Revenue & Analytics',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('btn_header_calendar'),
            icon: const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
            onPressed: _openMiniCalendarModal,
          ),
          IconButton(
            key: const Key('btn_header_download'),
            icon: const Icon(Icons.file_download, size: 22, color: AppColors.primary),
            onPressed: _openExportModal,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Site Selector Pill
                InkWell(
                  key: const Key('site_selector_pill'),
                  onTap: _openSiteSelectorModal,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.outlineVariant.withAlpha(120)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0617211D), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACTIVE OPERATIONS SITE',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _currentSite,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Change', style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Daily Report Banner (shown when a specific date is selected)
                if (isDailyMode) ...[
                  Container(
                    key: const Key('daily_report_banner'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.event_available, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Individual Day Report',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _formatShortDate(_selectedDate!),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatFullDate(_selectedDate!),
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const Key('btn_clear_day_report'),
                          icon: const Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
                          tooltip: 'Clear day report and return to 30 days',
                          onPressed: _clearSingleDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 2. Time Range Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final period in ['Today', 'Last 7 Days', 'Last 30 Days', 'Last 3 Months']) ...[
                        _buildTimeFilterChip(period),
                        const SizedBox(width: 6),
                      ],
                      if (_selectedDate != null) ...[
                        _buildTimeFilterChip('Daily: ${_formatShortDate(_selectedDate!)}'),
                        const SizedBox(width: 6),
                      ],
                      InkWell(
                        key: const Key('btn_filter_calendar_chip'),
                        onTap: _openMiniCalendarModal,
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedDate != null
                                ? AppColors.primary.withAlpha(25)
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: _selectedDate != null
                                  ? AppColors.primary
                                  : AppColors.outlineVariant.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 14,
                                color: _selectedDate != null
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedDate != null ? 'Change Date' : 'Calendar',
                                style: TextStyle(
                                  color: _selectedDate != null
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: _selectedDate != null
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Primary Financial Summary KPI Cards (2x2 Grid)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  children: [
                    // Card 1: Gross Revenue
                    _buildKpiCard(
                      icon: Icons.payments,
                      badgeText: isDailyMode
                          ? (_selectedDate!.weekday >= 5 ? 'Weekend Surge' : '+1-Day Shift')
                          : (_currentPeriod == 'Today'
                              ? 'Today Live'
                              : (_currentPeriod == 'Last 7 Days'
                                  ? '7-Day Total'
                                  : (_currentPeriod == 'Last 3 Months'
                                      ? '90-Day Total'
                                      : (hasManagerPayments ? '30-Day Total' : activeData.revGrowth)))),
                      badgeBg: AppColors.secondaryContainer.withAlpha(100),
                      badgeTextColor: AppColors.primary,
                      title: 'Total Gross Revenue',
                      upperLabel: 'TOTAL COLLECTIONS',
                      value: displayRev,
                      subtitle: hasManagerPayments
                          ? '${filteredStats.totalCount} collection${filteredStats.totalCount == 1 ? '' : 's'} (${isDailyMode ? _formatShortDate(_selectedDate!) : _currentPeriod})'
                          : (isDailyMode ? 'Reconciled 24h intake' : activeData.prevRev),
                      onTap: () => _showToast('Gross Revenue calculated from valet manager payment intake', Icons.payments),
                    ),
                    // Card 2: Vehicles Handled
                    _buildKpiCard(
                      icon: Icons.directions_car,
                      badgeText: isDailyMode
                          ? '1-day total'
                          : (_currentPeriod == 'Today' ? 'Live rate' : (hasManagerPayments ? 'Desk Paid' : activeData.rate)),
                      badgeBg: AppColors.surfaceContainer,
                      badgeTextColor: AppColors.onSurfaceVariant,
                      title: 'Vehicles Handled',
                      value: displayVeh,
                      subtitle: hasManagerPayments
                          ? 'Manager desk intake & release'
                          : (isDailyMode ? 'Daily shift throughput' : activeData.avgTicket),
                      onTap: () => _showToast('Vehicles paid and released via Manager Operations', Icons.directions_car),
                    ),
                    // Card 3: Dwell Time
                    _buildKpiCard(
                      icon: Icons.schedule,
                      badgeText: 'Optimal',
                      badgeBg: AppColors.surfaceContainer,
                      badgeTextColor: AppColors.onSurfaceVariant,
                      title: 'Avg. Dwell Time',
                      value: isDailyMode ? '0h 00m' : (_currentPeriod == 'Today' ? '0h 00m' : activeData.dwell),
                      subtitle: isDailyMode ? 'Turnaround: 0.0m' : 'Peak turnaround: 0.0m',
                      onTap: () => _showToast('Peak vehicle turnaround benchmarked at 0.0 minutes', Icons.schedule),
                    ),
                    // Card 4: Collection Rate
                    _buildKpiCard(
                      icon: Icons.fact_check,
                      customDot: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      title: 'Collection Rate',
                      value: hasManagerPayments ? '100.0%' : (isDailyMode ? '0.0%' : activeData.collRate),
                      subtitle: hasManagerPayments
                          ? '${filteredStats.totalCount} verified shift collections'
                          : (isDailyMode ? 'Verified shift ledger' : activeData.claims),
                      subtitleColor: hasManagerPayments || isDailyMode ? AppColors.primary : AppColors.outline,
                      onTap: () => _showToast('Reconciliation status: verified against Manager desk collections', Icons.fact_check),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Payment Collection Method Breakdown
                HudCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Collections', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text(
                                  hasManagerPayments
                                      ? 'Live collections for ${isDailyMode ? _formatShortDate(_selectedDate!) : _currentPeriod}'
                                      : 'Reconciled split by intake channel',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              hasManagerPayments
                                  ? '${filteredStats.totalCount} in ${isDailyMode ? _formatShortDate(_selectedDate!) : _currentPeriod}'
                                  : '2 Channels',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Segmented Stack Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 10,
                          child: Row(
                            children: [
                              Expanded(
                                flex: (filteredStats.onlineRatio * 100).round() > 0
                                    ? (filteredStats.onlineRatio * 100).round()
                                    : (hasManagerPayments ? 0 : 1),
                                child: Container(
                                  color: AppColors.primary.withAlpha(
                                    filteredStats.onlineRatio > 0 ? 255 : (hasManagerPayments ? 0 : 40),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: (filteredStats.cashRatio * 100).round() > 0
                                    ? (filteredStats.cashRatio * 100).round()
                                    : (hasManagerPayments ? 0 : 1),
                                child: Container(
                                  color: AppColors.secondaryContainer.withAlpha(
                                    filteredStats.cashRatio > 0 ? 255 : (hasManagerPayments ? 0 : 40),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // UPI Channel
                      InkWell(
                        onTap: () => _showToast('UPI QR: Instant auto-settled via Manager Desk terminal', Icons.qr_code_scanner),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('UPI QR & Digital', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(
                                      'Instant settlement • ${hasManagerPayments ? (filteredStats.onlineRatio * 100).round() : 0}% volume',
                                      style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    hasManagerPayments
                                        ? '₹${filteredStats.onlineRevenue.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                                        : activeData.upiRev,
                                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${filteredStats.onlineCount} txns',
                                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 16),

                      // Cash Channel
                      InkWell(
                        onTap: () => _showToast('Cash: Desk physical count verified by Manager', Icons.attach_money),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.attach_money, color: AppColors.onSurfaceVariant, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cash Collections', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(
                                      'Vault verified • ${hasManagerPayments ? (filteredStats.cashRatio * 100).round() : 0}%',
                                      style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    hasManagerPayments
                                        ? '₹${filteredStats.cashRevenue.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                                        : activeData.cashRev,
                                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${filteredStats.cashCount} txns',
                                    style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
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
                const SizedBox(height: 16),

                // 5. Revenue & Vehicle Volume Trends (Weekly Influx Chart)
                HudCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weekly Influx Trends', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text('Daily volume spikes & evening rushes', style: AppTypography.bodySmall.copyWith(color: AppColors.outline), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Fri - Sun Peak',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Influx Bar Chart
                      SizedBox(
                        height: 140,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (int i = 0; i < activeData.bars.length; i++) ...[
                              Expanded(
                                child: _buildInfluxBar(
                                  data: activeData.bars[i],
                                  index: i,
                                  isSelected: _selectedBarIndex == i,
                                  onTap: () {
                                    setState(() {
                                      _selectedBarIndex = i;
                                    });
                                    _showToast('${activeData.bars[i].day}: ${activeData.bars[i].rev} • ${activeData.bars[i].cars}', Icons.insights);
                                  },
                                ),
                              ),
                              if (i < activeData.bars.length - 1) const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chart Highlight Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.insights, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _selectedBarIndex != null
                                          ? '${activeData.bars[_selectedBarIndex!].day}: ${activeData.bars[_selectedBarIndex!].rev} (${activeData.bars[_selectedBarIndex!].cars})'
                                          : 'Peak Surge Window: 19:00 - 22:30',
                                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '0 Valets active',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Operational Tariff Breakdown
                HudCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Operational Tariff Mix',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune, size: 20, color: AppColors.onSurfaceVariant),
                            onPressed: _openTariffSortModal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final item in _tariffs) ...[
                        InkWell(
                          onTap: () => _showToast('${item.name}: ${item.countText}', Icons.local_offer),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow.withAlpha(120),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.outlineVariant.withAlpha(60)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item.name,
                                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: item.badge == 'Priority' ? AppColors.secondaryContainer : AppColors.surfaceContainer,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.badge,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: item.badge == 'Priority' ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(item.countText, style: AppTypography.labelSmall.copyWith(color: AppColors.outline), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(item.revText, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                    Text(item.pctText, style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 7. Site-by-Site Comparison (Multi-Site Hubs Performance)
                HudCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Multi-Site Hubs Performance', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text('Capacity utilization & intake yield', style: AppTypography.bodySmall.copyWith(color: AppColors.outline), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Text(_siteHubs.isEmpty ? '0 Active Sites' : 'All ${_siteHubs.length} Live', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_siteHubs.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.domain_disabled, size: 36, color: AppColors.outline),
                              const SizedBox(height: 8),
                              Text(
                                'No Sites Configured',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All dummy sites removed. Add sites to track multi-property performance.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        for (final site in _siteHubs) ...[
                          InkWell(
                            onTap: () => _selectSite(site.name),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(width: 8, height: 8, decoration: BoxDecoration(color: site.dotColor, shape: BoxShape.circle)),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                site.name,
                                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(site.revenue, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: site.dotColor)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            site.carsText,
                                            style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${site.capacityPct}% Capacity', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: site.capacityPct / 100.0,
                                      backgroundColor: AppColors.surfaceContainer,
                                      valueColor: AlwaysStoppedAnimation<Color>(site.dotColor),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (site != _siteHubs.last) const Divider(height: 14),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 8. Action Footer (Export Button)
                ElevatedButton.icon(
                  key: const Key('btn_export_main'),
                  icon: const Icon(Icons.download, size: 20, color: Colors.white),
                  label: const Text('Export Full Audit CSV / PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _openExportModal,
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Includes runner cash reconciliation & ticket ledger',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip(String period) {
    final isSelected = _currentPeriod == period;
    return InkWell(
      key: Key('period_chip_$period'),
      onTap: () => _applyPeriod(period),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              period,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    String? badgeText,
    Color? badgeBg,
    Color? badgeTextColor,
    Widget? customDot,
    required String title,
    String? upperLabel,
    required String value,
    required String subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withAlpha(90)),
          boxShadow: const [
            BoxShadow(color: Color(0x0617211D), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg ?? AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTypography.labelSmall.copyWith(
                        color: badgeTextColor ?? AppColors.onSurfaceVariant,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  customDot ?? const SizedBox.shrink(),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (upperLabel != null)
                  Text(
                    upperLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.outline,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleColor ?? AppColors.outline,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfluxBar({
    required DayInfluxData data,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final barFillColor = isSelected
        ? AppColors.primary
        : data.ratio >= 0.8
            ? AppColors.primary.withAlpha(200)
            : AppColors.surfaceContainerHigh;

    return InkWell(
      key: Key('influx_bar_${data.day.toLowerCase()}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (data.isPeak)
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Text('Peak', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
            ),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 9,
              color: isSelected || data.ratio >= 0.8 ? AppColors.primary : AppColors.outline,
              fontWeight: isSelected || data.ratio >= 0.8 ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: data.ratio.clamp(0.1, 1.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: barFillColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.day.substring(0, 1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected || data.ratio >= 0.8 ? FontWeight.bold : FontWeight.normal,
              color: isSelected || data.ratio >= 0.8 ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
