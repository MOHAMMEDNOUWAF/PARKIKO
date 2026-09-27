import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeFilter = 'all';
  int _newCount = 3;
  final Set<String> _unreadIds = {'today-1', 'today-2', 'today-3'};

  // Toast state
  bool _showToast = false;
  String _toastMessage = '';
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _triggerToast(String message) {
    if (!mounted) return;
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _showToast = true;
    });

    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && _showToast && _toastMessage == message) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }

  void _markAllRead() {
    setState(() {
      _unreadIds.clear();
      _newCount = 0;
    });
    _triggerToast('All notifications marked as read');
  }

  void _openAssignBayModal(String valetName) {
    String selectedBay = 'Gate 3 • Bay A-12 (North Ramp)';
    final bays = [
      'Gate 3 • Bay A-12 (North Ramp)',
      'Gate 1 • Bay C-04 (Executive Deck)',
      'Deck South • Bay B-08 (Valet Hub)',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        color: AppColors.outlineVariant.withAlpha(120),
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
                            'Assign Parking Bay',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF142820),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Valet: $valetName',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF5A6E65),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF5A6E65)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE1EDE5)),
                  const SizedBox(height: 12),
                  Text(
                    'Select Priority Dock / Bay',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF142820),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE1EDE5)),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF1FCF5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBay,
                        isExpanded: true,
                        icon: const Icon(Icons.expand_more, color: Color(0xFF0F6B4F)),
                        items: bays.map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text(
                              b,
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF142820),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedBay = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE1EDE5)),
                            backgroundColor: const Color(0xFFF0F3F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: AppTypography.labelLarge.copyWith(
                              color: const Color(0xFF5A6E65),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFF0F6B4F),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final bayName = selectedBay.split('•')[0].trim();
                            _triggerToast('Assigned to $bayName');
                          },
                          child: Text(
                            'Confirm Assignment',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Filter items helper
  bool _matchesFilter(String category) {
    if (_activeFilter == 'all') return true;
    return _activeFilter == category;
  }

  @override
  Widget build(BuildContext context) {
    // Determine counts for Today and Earlier groups given current filter
    final todayMatches = [
      _matchesFilter('new-join'),
      _matchesFilter('shift-starts'),
      _matchesFilter('shift-ends'),
      _matchesFilter('shift-starts'),
    ].where((m) => m).length;

    final earlierMatches = [
      _matchesFilter('new-join'),
      _matchesFilter('shift-ends'),
    ].where((m) => m).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FCF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1FCF5),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF142820), size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Go back',
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Notifications',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF142820),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _newCount > 0 ? const Color(0xFF0F6B4F) : const Color(0xFF9CA3AF),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '$_newCount New',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F6B4F),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _markAllRead,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5F2EA)),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // 1. Metric Summary Cards (3-column grid)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricSummaryCard(
                          icon: Icons.person_add,
                          count: '1',
                          label: 'NEW JOIN',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricSummaryCard(
                          icon: Icons.login,
                          count: '4',
                          label: 'SHIFT STARTS',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricSummaryCard(
                          icon: Icons.check_circle,
                          count: '2',
                          label: 'SHIFT ENDS',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Filter Pills Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill(
                          id: 'all',
                          label: 'All 6',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          id: 'shift-starts',
                          label: 'Shift Starts 4',
                          hasDot: true,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          id: 'shift-ends',
                          label: 'Shift Ends 2',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          id: 'new-join',
                          label: 'New Joins 1',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. TODAY Section
                  if (todayMatches > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'TODAY',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5A6E65),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
                            const SizedBox(width: 6),
                            Text(
                              '$todayMatches updates',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF5A6E65),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _triggerToast('Filter by Dock selected'),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.tune, size: 16, color: Color(0xFF0F6B4F)),
                                const SizedBox(width: 4),
                                Text(
                                  'Filter by Dock',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: const Color(0xFF0F6B4F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Card 1: Rahul Sharma (new-join)
                    if (_matchesFilter('new-join')) ...[
                      _buildRahulSharmaCard(),
                      const SizedBox(height: 12),
                    ],

                    // Card 2: Suresh Kumar (shift-starts)
                    if (_matchesFilter('shift-starts')) ...[
                      _buildSureshKumarCard(),
                      const SizedBox(height: 12),
                    ],

                    // Card 3: Vikram Singh (shift-ends)
                    if (_matchesFilter('shift-ends')) ...[
                      _buildVikramSinghCard(),
                      const SizedBox(height: 12),
                    ],

                    // Card 4: Amit Verma (shift-starts)
                    if (_matchesFilter('shift-starts')) ...[
                      _buildAmitVermaCard(),
                      const SizedBox(height: 12),
                    ],
                  ],

                  // 4. EARLIER Section
                  if (earlierMatches > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'EARLIER',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5A6E65),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
                        const SizedBox(width: 6),
                        Text(
                          '$earlierMatches updates',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF5A6E65),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Card 5: Karan Patel (new-join)
                    if (_matchesFilter('new-join')) ...[
                      _buildKaranPatelCard(),
                      const SizedBox(height: 12),
                    ],

                    // Card 6: Pooja Nair (shift-ends)
                    if (_matchesFilter('shift-ends')) ...[
                      _buildPoojaNairCard(),
                      const SizedBox(height: 12),
                    ],
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),

          // Floating Toast Overlay
          if (_showToast)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: AnimatedOpacity(
                    opacity: _showToast ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _toastMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildBottomNavItem(
                        icon: Icons.home,
                        label: 'Home',
                        isActive: false,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
                      child: _buildBottomNavItem(
                        icon: Icons.local_shipping_outlined,
                        label: 'Operations',
                        isActive: false,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildBottomNavItem(
                        icon: Icons.group_outlined,
                        label: 'Staff',
                        isActive: false,
                        onTap: () => _triggerToast('Staff Directory (Shift Alpha)'),
                      ),
                    ),
                    Expanded(
                      child: _buildBottomNavItem(
                        icon: Icons.payments_outlined,
                        label: 'Payments',
                        isActive: false,
                        onTap: () => _triggerToast('Valet Payments Ledger'),
                      ),
                    ),
                    Expanded(
                      child: _buildBottomNavItem(
                        icon: Icons.more_horiz,
                        label: 'More',
                        isActive: true,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    if (isActive) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFB3ECD1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF0F6B4F)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F6B4F),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF6B7280)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary metric tile
  Widget _buildMetricSummaryCard({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1EDE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817211D),
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
              Icon(icon, size: 20, color: const Color(0xFF0F6B4F)),
              const SizedBox(width: 4),
              Text(
                count,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF142820),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filter Pill
  Widget _buildFilterPill({
    required String id,
    required String label,
    bool hasDot = false,
  }) {
    final isActive = _activeFilter == id;
    return TextButton(
      key: ValueKey('filter-$id'),
      style: TextButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF0F6B4F) : Colors.white,
        foregroundColor: isActive ? Colors.white : const Color(0xFF374151),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
          side: BorderSide(
            color: isActive ? const Color(0xFF0F6B4F) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      onPressed: () {
        setState(() {
          _activeFilter = id;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : const Color(0xFF059669),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Card 1: Rahul Sharma
  Widget _buildRahulSharmaCard() {
    final isUnread = _unreadIds.contains('today-1');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EDE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817211D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar RS with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFA3E5C7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'RS',
                    style: TextStyle(
                      color: Color(0xFF094834),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6B4F),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.white, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5F5E3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'New Join',
                        style: TextStyle(
                          color: Color(0xFF0F6B4F),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          '10m ago',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F6B4F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Valet Runner • Shift Alpha',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rahul Sharma',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF142820),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Assigned to Shift Alpha. Verification completed with verified commercial valet permit.',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 10),

                // Verification Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTag(Icons.verified, 'Account Verified'),
                    _buildTag(Icons.badge, 'DL Validated'),
                  ],
                ),
                const SizedBox(height: 14),

                // Quick Actions
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6B4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.local_parking, size: 16),
                      label: const Text('Assign Bay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _openAssignBayModal('Rahul Sharma'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F3F1),
                        foregroundColor: const Color(0xFF374151),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      label: const Text('Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      icon: const Icon(Icons.chevron_right, size: 16),
                      onPressed: () => _triggerToast('Rahul Sharma profile opened'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Suresh Kumar
  Widget _buildSureshKumarCard() {
    final isUnread = _unreadIds.contains('today-2');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EDE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817211D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF8DE4BC),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD5F5E3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                                const Text(
                                  'Work Started',
                                  style: TextStyle(color: Color(0xFF0F6B4F), fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Terminal North',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Text(
                          '45m ago',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F6B4F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Shift Commenced • Suresh Kumar',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF142820),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Clocked in on time. Assigned to Bay Gate 3 with Key Rack Locker #04.',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 10),

                // Callout Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EF),
                    border: Border.all(color: const Color(0xFFD6ECDF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Color(0xFF065F46)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Bay Gate 3 • Key Rack #04 assigned',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Color(0xFF374151), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Shift Active',
                        style: TextStyle(color: Color(0xFF0F6B4F), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Vikram Singh
  Widget _buildVikramSinghCard() {
    final isUnread = _unreadIds.contains('today-3');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EDE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817211D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD6EDE1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF065F46), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF2EF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Shift Completed',
                              style: TextStyle(color: Color(0xFF374151), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Shift Alpha',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Text(
                          '2h ago',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F6B4F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Shift Ended • Vikram Singh',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF142820),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Valet completed full duty with zero reported damages and prompt returns.',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 10),

                // Duty stats callout
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EF),
                    border: Border.all(color: const Color(0xFFD6ECDF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.directions_car, size: 16, color: Color(0xFF065F46)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '8 hrs • 24 cars • 100% on-time',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Color(0xFF374151), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _triggerToast('Vikram Singh duty report opened'),
                        child: const Row(
                          children: [
                            Text('Report', style: TextStyle(color: Color(0xFF0F6B4F), fontSize: 11, fontWeight: FontWeight.bold)),
                            Icon(Icons.arrow_forward, size: 12, color: Color(0xFF0F6B4F)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 4: Amit Verma
  Widget _buildAmitVermaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EDE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817211D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFB6EDD6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Color(0xFF065F46), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD5F5E3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Peak Overtime',
                              style: TextStyle(color: Color(0xFF0F6B4F), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Deck South',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('3h ago', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Overtime Started • Amit Verma',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF142820),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Supervisor checked in for evening peak hours surge at Deck South.',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 5: Karan Patel
  Widget _buildKaranPatelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EDE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817211D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3EAE6),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'KP',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6B4F),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD5F5E3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'New Join',
                              style: TextStyle(color: Color(0xFF0F6B4F), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Team Bravo',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Yesterday', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Driver Onboarding Approved • Karan Patel',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF142820),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Joined Valet Team Bravo. Verification badge & ramp access key issued.',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 6: Pooja Nair
  Widget _buildPoojaNairCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EDE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817211D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD6EDE1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dark_mode, color: Color(0xFF065F46), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF2EF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Shift Ended',
                              style: TextStyle(color: Color(0xFF374151), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Night Deck',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Yesterday', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Night Shift Wrap-up • Pooja Nair',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF142820),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Clocked out after completing Night Deck handover with keys safely secured in bay depot.',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF8F2),
        border: Border.all(color: const Color(0xFFDBEDE1)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF047857)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
