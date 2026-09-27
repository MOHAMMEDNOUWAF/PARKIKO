import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../auth/services/user_id_resolver.dart';
import '../../sites/services/site_manager.dart';
import '../../sites/presentation/add_site_wizard_screen.dart';
import '../models/staff_model.dart';
import '../services/staff_manager.dart';
import 'add_staff_screen.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

enum _StaffRole { driver, manager, asstManager }

class _StaffMember {
  final String id;
  String name;
  final String phone;
  _StaffRole role;
  String assignedSite;
  final String metric;
  bool isOnDuty;
  String password;

  _StaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.assignedSite,
    required this.metric,
    this.isOnDuty = true,
    this.password = '1234',
  });
}

// ─── Colors ───────────────────────────────────────────────────────────────────

const _kBrand = Color(0xFF0F6B4F);
const _kBrandLight = Color(0xFFD6F2E4);
const _kBrandBg = Color(0xFFEDF6F0);
const _kAmberBg = Color(0xFFFEF2DC);
const _kAmberText = Color(0xFFA45D06);
const _kSurface = Colors.white;

// ─── Main Screen ──────────────────────────────────────────────────────────────

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  String _activeFilter = 'all';

  // Toast
  bool _showToast = false;
  String _toastMessage = '';
  Timer? _toastTimer;

  final List<_StaffMember> _staff = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _staffSubscription;

  @override
  void initState() {
    super.initState();
    SiteManager.instance.addListener(_onSitesUpdated);
    StaffManager.instance.addListener(_onStaffManagerUpdated);
    _syncFromStaffManager();
    _initStaffStream();
  }

  void _syncFromStaffManager() {
    final managerStaff = StaffManager.instance.staff;
    if (managerStaff.isNotEmpty) {
      if (mounted) {
        setState(() {
          _staff.clear();
          for (final s in managerStaff) {
            final role = s.isAssistantManager
                ? _StaffRole.asstManager
                : (s.isManager
                    ? _StaffRole.manager
                    : _StaffRole.driver);
            _staff.add(_StaffMember(
              id: s.id,
              name: s.name,
              phone: s.phone,
              role: role,
              assignedSite: s.assignedSite,
              metric: s.metric,
              isOnDuty: s.isOnDuty,
              password: s.password,
            ));
          }
        });
      }
    }
  }

  void _onStaffManagerUpdated() {
    if (mounted) {
      _syncFromStaffManager();
    }
  }

  void _initStaffStream() {
    _syncFromStaffManager();

    if (FirebaseService.isInitialized) {
      try {
        final collection = FirebaseFirestore.instance.collection(FirebaseService.staffCollection);
        _staffSubscription = collection.snapshots().listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              // Use StaffModel.fromMap + its isAssistantManager/isManager getters
              // as the single source of truth for role classification.
              final loaded = snapshot.docs.map((doc) {
                final model = StaffModel.fromMap(doc.data(), doc.id);
                final _StaffRole role;
                if (model.isAssistantManager) {
                  role = _StaffRole.asstManager;
                } else if (model.isManager) {
                  role = _StaffRole.manager;
                } else {
                  role = _StaffRole.driver;
                }
                final defaultMetric = role == _StaffRole.asstManager
                    ? '0 Shifts Supervised'
                    : (role == _StaffRole.manager ? '0 Operations Monitored' : '0 Cars Handled');
                final member = _StaffMember(
                  id: model.id,
                  name: model.name,
                  phone: model.phone,
                  role: role,
                  assignedSite: model.assignedSite,
                  metric: model.metric.isNotEmpty ? model.metric : defaultMetric,
                  isOnDuty: model.isOnDuty,
                  password: model.password,
                );
                return member;
              }).toList();

              if (mounted) {
                setState(() {
                  _staff.clear();
                  _staff.addAll(loaded);
                });
              }
            } else if (StaffManager.instance.staff.isEmpty) {
              if (mounted) {
                setState(() {
                  _staff.clear();
                });
              }
            }
          },
          onError: (e) {
            debugPrint('[StaffManagement] Firestore stream error: $e');
          },
        );
      } catch (e) {
        debugPrint('[StaffManagement] Error initializing stream: $e');
      }
    }
  }

  Future<void> _saveStaffToFirestore(
    _StaffMember member, {
    String? email,
    String? licenseNo,
    DateTime? licenseExpiry,
  }) async {
    // 1. Always update StaffManager in-memory singleton
    final roleStr = member.role == _StaffRole.asstManager
        ? 'assistant manager'
        : (member.role == _StaffRole.manager ? 'manager' : 'driver');

    final userRoleStr = member.role == _StaffRole.asstManager
        ? 'ASSISTANT MANAGER'
        : (member.role == _StaffRole.manager ? 'ADMIN' : 'VALET');

    await StaffManager.instance.addStaff(StaffModel(
      id: member.id,
      name: member.name,
      phone: member.phone,
      role: roleStr,
      assignedSite: member.assignedSite,
      password: member.password.isNotEmpty ? member.password : '1234',
      metric: member.metric,
      isOnDuty: member.isOnDuty,
      email: email,
      licenseNo: licenseNo,
      licenseExpiry: licenseExpiry,
    ));

    // 2. Persist to Firestore database
    try {
      if (!FirebaseService.isInitialized) return;
      final firestore = FirebaseFirestore.instance;

      // Primary staff document
      await firestore.collection(FirebaseService.staffCollection).doc(member.id).set({
        'id': member.id,
        'userId': member.id,
        'name': member.name,
        'phone': member.phone,
        'role': roleStr,
        'assignedSite': member.assignedSite,
        'metric': member.metric,
        'isOnDuty': member.isOnDuty,
        'password': member.password.isNotEmpty ? member.password : '1234',
        'email': email ?? '',
        'licenseNo': licenseNo ?? '',
        'licenseExpiry': licenseExpiry?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Synchronize to users collection (trusted UserProfile for Firebase Auth)
      await firestore.collection('users').doc(member.id).set({
        'uid': member.id,
        'userId': member.id,
        'name': member.name,
        'phone': member.phone,
        'role': userRoleStr,
        'status': member.isOnDuty ? 'ACTIVE' : 'SUSPENDED',
        'organizationId': member.assignedSite,
        'locationIds': [member.assignedSite],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // User ID mapping for tenant login
      await firestore.collection('user_mappings').doc(member.id.toLowerCase().trim()).set({
        'uid': member.id,
        'email': '${member.id.toLowerCase().trim()}@${UserIdResolver.defaultTenantDomain}',
        'role': userRoleStr,
      }, SetOptions(merge: true));

      debugPrint('[StaffManagement] Staff ${member.id} (${member.name}) profile synced to database.');
    } catch (e) {
      debugPrint('[StaffManagement] Offline mode: saved locally ($e)');
    }
  }

  Future<void> _deleteStaff(_StaffMember member) async {
    setState(() => _staff.remove(member));
    _showFeedback('Staff ${member.name} deleted from database', icon: 'warning');
    await StaffManager.instance.deleteStaff(member.id);
  }

  void _onSitesUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SiteManager.instance.removeListener(_onSitesUpdated);
    StaffManager.instance.removeListener(_onStaffManagerUpdated);
    _staffSubscription?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _openSiteSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isAllSelected = SiteManager.instance.selectedSite == 'All Sites' || SiteManager.instance.selectedSite.startsWith('All Sites');
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
                    tileColor: isAllSelected
                        ? AppColors.secondaryContainer.withAlpha(80)
                        : null,
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
                      SiteManager.instance.selectSite('All Sites');
                      Navigator.pop(ctx);
                      _showFeedback('Showing staff from all sites');
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
                        final s = SiteManager.instance.sites[index];
                        final isSelected = !isAllSelected && SiteManager.instance.selectedSite == s.name;
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: isSelected
                              ? AppColors.secondaryContainer.withAlpha(80)
                              : AppColors.surfaceContainerLow,
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
                            s.name,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            s.address,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                              : null,
                          onTap: () {
                            SiteManager.instance.selectSite(s.name);
                            Navigator.pop(ctx);
                            _showFeedback('Filtered by: ${s.name}');
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

  void _showFeedback(String message, {String icon = 'check_circle'}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _showToast = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  List<_StaffMember> get _siteFilteredStaff {
    final selectedSite = SiteManager.instance.selectedSite;
    if (selectedSite.isNotEmpty && !selectedSite.startsWith('All Sites')) {
      final cleanSite = selectedSite.toLowerCase().trim();
      return _staff.where((s) {
        final sSite = s.assignedSite.toLowerCase().trim();
        return sSite.isEmpty ||
            sSite == cleanSite ||
            sSite.contains(cleanSite) ||
            cleanSite.contains(sSite);
      }).toList();
    }
    return _staff;
  }

  List<_StaffMember> get _filtered {
    final list = _siteFilteredStaff;
    if (_activeFilter == 'manager') {
      return list.where((s) => s.role == _StaffRole.manager).toList();
    } else if (_activeFilter == 'asstManager') {
      return list.where((s) => s.role == _StaffRole.asstManager).toList();
    } else if (_activeFilter == 'driver') {
      return list.where((s) => s.role == _StaffRole.driver).toList();
    }
    return List.from(list);
  }

  int get _onDutyCount => _siteFilteredStaff.where((s) => s.isOnDuty).length;
  int get _totalCount => _siteFilteredStaff.length;
  int get _managerCount => _siteFilteredStaff.where((s) => s.role == _StaffRole.manager).length;
  int get _asstManagerCount => _siteFilteredStaff.where((s) => s.role == _StaffRole.asstManager).length;
  int get _driverCount => _siteFilteredStaff.where((s) => s.role == _StaffRole.driver).length;

  // ─── Dialogs ─────────────────────────────────────────────────────────────

  void _openAddModal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStaffScreen(
          onCreated: (name, role, site, {email, licenseExpiry, licenseNo, multiSiteAccess, password, phone, staffId}) {
            final newRole = role == VRole.asstManager
                ? _StaffRole.asstManager
                : (role == VRole.manager
                    ? _StaffRole.manager
                    : _StaffRole.driver);
            final formattedPhone = (phone != null && phone.isNotEmpty)
                ? (phone.startsWith('+91') ? phone : '+91 $phone')
                : '+91 98765 43210';
            final assignedPassword = (password != null && password.trim().isNotEmpty)
                ? password.trim()
                : '1234';
            final String assignedMetric = newRole == _StaffRole.asstManager
                ? '0 Shifts Supervised'
                : (newRole == _StaffRole.manager
                    ? '0 Operations Monitored'
                    : '0 Cars Handled');
            final newMember = _StaffMember(
              id: staffId ?? 'PK-${100 + DateTime.now().millisecondsSinceEpoch % 900}',
              name: name,
              phone: formattedPhone,
              role: newRole,
              assignedSite: site,
              metric: assignedMetric,
              isOnDuty: true,
              password: assignedPassword,
            );
            setState(() {
              _staff.add(newMember);
            });
            _saveStaffToFirestore(newMember, email: email, licenseNo: licenseNo, licenseExpiry: licenseExpiry);
            _showFeedback('$name enrolled! Credentials sent via WhatsApp. (ID: ${newMember.id}, PIN: $assignedPassword)');
          },
        ),
      ),
    );
  }

  void _openEditSheet(_StaffMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditStaffSheet(
        member: member,
        onSaved: (name, site, role, active) {
          setState(() {
            member.name = name;
            member.assignedSite = site;
            member.role = role;
            member.isOnDuty = active;
          });
          _showFeedback('Saved changes for $name');
          _saveStaffToFirestore(member);
        },
        onDeactivated: () {
          _deleteStaff(member);
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _kBrandBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── TopAppBar ──────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: _kBrandBg,
                scrolledUnderElevation: 0,
                elevation: 0,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                toolbarHeight: 56,
                title: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'P',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _kBrand,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Parkiko',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _kBrand,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Site Selector Card ─────────────────────
                    _SiteSelectorCard(
                      onTap: _openSiteSelector,
                      siteName: SiteManager.instance.hasSites
                          ? (SiteManager.instance.selectedSite.startsWith('All Sites')
                              ? 'All Sites (${SiteManager.instance.siteCount} Properties)'
                              : SiteManager.instance.selectedSite)
                          : 'All Sites (0 Properties)',
                      activeCount: '${SiteManager.instance.siteCount} Sites Active',
                    ),
                    const SizedBox(height: 14),

                    // ── Section Header ─────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Staff Management',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F1A14),
                            letterSpacing: -0.6,
                          ),
                        ),
                        _AddButton(onTap: _openAddModal),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── On Duty Metric ─────────────────────────
                    _MetricCard(onDuty: _onDutyCount),
                    const SizedBox(height: 12),

                    // ── Filter Chips ───────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All ($_totalCount)',
                            active: _activeFilter == 'all',
                            onTap: () => setState(() => _activeFilter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Managers ($_managerCount)',
                            active: _activeFilter == 'manager',
                            onTap: () => setState(() => _activeFilter = 'manager'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Assist Managers ($_asstManagerCount)',
                            active: _activeFilter == 'asstManager',
                            onTap: () => setState(() => _activeFilter = 'asstManager'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Drivers ($_driverCount)',
                            active: _activeFilter == 'driver',
                            onTap: () => setState(() => _activeFilter = 'driver'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Staff Cards ────────────────────────────
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEBF6EF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_outline, size: 28, color: Color(0xFF6F7A73)),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No staff members registered',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F1A14),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Staff roster is currently empty (0 staff).\nTap "+ Add Staff" to onboard your team manually.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Color(0xFF6F7A73)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00513A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _openAddModal,
                                icon: const Icon(Icons.person_add_alt_1, size: 18),
                                label: const Text('Add Staff Manually', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtered.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StaffCard(
                          member: m,
                          onCall: () => _showFeedback('Initiating call to ${m.name} (${m.phone})...', icon: 'call'),
                          onEdit: () => _openEditSheet(m),
                        ),
                      )),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),

          // ── Toast ──────────────────────────────────────────────
          if (_showToast)
            Positioned(
              top: 56 + 16,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showToast ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827).withAlpha(230),
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 16),
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
        ],
      ),
    );
  }
}

// ─── Site Selector Card ────────────────────────────────────────────────────────

class _SiteSelectorCard extends StatelessWidget {
  final VoidCallback onTap;
  final String siteName;
  final String activeCount;

  const _SiteSelectorCard({
    required this.onTap,
    this.siteName = 'All Sites (0 Properties)',
    this.activeCount = '0 Sites Active',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F6B4F).withAlpha(13)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.domain, color: _kBrand, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Valet Site & Deck',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          siteName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.expand_more, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD4F2E3),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: _kBrand, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  activeCount,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kBrand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metric Card ──────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final int onDuty;
  const _MetricCard({required this.onDuty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF0E5).withAlpha(179),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFC5E7D5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.badge, color: _kBrand, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: _kBrand, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$onDuty',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kBrand,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'On Duty',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F6B4F)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kBrand : _kSurface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: active ? _kBrand : const Color(0xFFE2E8F0),
          ),
          boxShadow: active
              ? [BoxShadow(color: _kBrand.withAlpha(40), blurRadius: 6, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// ─── Add Button ───────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBrand,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: _kBrand.withAlpha(80),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withAlpha(50),
        highlightColor: Colors.white.withAlpha(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Add Staff',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Staff Card ───────────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  final _StaffMember member;
  final VoidCallback onCall;
  final VoidCallback onEdit;

  const _StaffCard({required this.member, required this.onCall, required this.onEdit});

  String get _initials {
    final parts = member.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].substring(0, 2).toUpperCase();
  }

  Color get _badgeBg {
    const sites = {
      'Aerocity Grand': Color(0xFFD6F2E4),
      'Aerocity Grand Terminal - T2': Color(0xFFD6F2E4),
      'St. Regis Hotel': Color(0xFFD6F2E4),
      'Grand Hyatt': Color(0xFFD6F2E4),
      'Grand Hyatt & Convention': Color(0xFFD6F2E4),
      'JW Marriott Porch': Color(0xFFD6F2E4),
      'CyberHub Corporate Plaza': Color(0xFFD6F2E4),
      'South City Mall': _kAmberBg,
      'South City Luxury Mall Deck': _kAmberBg,
    };
    return sites[member.assignedSite] ?? _kBrandLight;
  }

  Color get _badgeText {
    return (member.assignedSite == 'South City Mall' || member.assignedSite == 'South City Luxury Mall Deck')
        ? _kAmberText
        : _kBrand;
  }

  String get _roleDisplayName {
    switch (member.role) {
      case _StaffRole.manager:
        return 'Manager';
      case _StaffRole.asstManager:
        return 'Assistant Manager';
      case _StaffRole.driver:
        return 'Driver';
    }
  }

  Color get _roleBadgeBg {
    switch (member.role) {
      case _StaffRole.manager:
        return const Color(0xFFDCFCE7);
      case _StaffRole.asstManager:
        return const Color(0xFFE0F2FE);
      case _StaffRole.driver:
        return const Color(0xFFFEF3C7);
    }
  }

  Color get _roleBadgeBorder {
    switch (member.role) {
      case _StaffRole.manager:
        return const Color(0xFF86EFAC);
      case _StaffRole.asstManager:
        return const Color(0xFFBAE6FD);
      case _StaffRole.driver:
        return const Color(0xFFFDE68A);
    }
  }

  Color get _roleBadgeText {
    switch (member.role) {
      case _StaffRole.manager:
        return const Color(0xFF0F6B4F);
      case _StaffRole.asstManager:
        return const Color(0xFF0369A1);
      case _StaffRole.driver:
        return const Color(0xFFB45309);
    }
  }

  IconData get _roleIcon {
    switch (member.role) {
      case _StaffRole.manager:
        return Icons.manage_accounts;
      case _StaffRole.asstManager:
        return Icons.supervisor_account;
      case _StaffRole.driver:
        return Icons.directions_car;
    }
  }

  Color get _avatarBg {
    switch (member.role) {
      case _StaffRole.manager:
        return const Color(0xFFDCFCE7);
      case _StaffRole.asstManager:
        return const Color(0xFFE0F2FE);
      case _StaffRole.driver:
        return const Color(0xFFFFFBEB);
    }
  }

  Color get _avatarBorder {
    switch (member.role) {
      case _StaffRole.manager:
        return const Color(0xFFBBF7D0);
      case _StaffRole.asstManager:
        return const Color(0xFFBAE6FD);
      case _StaffRole.driver:
        return const Color(0xFFFDE68A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Top Row ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _avatarBg,
                        border: Border.all(
                          color: _avatarBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _roleBadgeText,
                          ),
                        ),
                      ),
                    ),
                    if (member.isOnDuty)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Name + Position + ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _roleBadgeBg,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: _roleBadgeBorder, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_roleIcon, size: 10, color: _roleBadgeText),
                                const SizedBox(width: 3),
                                Text(
                                  _roleDisplayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: _roleBadgeText,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'ID: ${member.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            '•',
                            style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Position: $_roleDisplayName',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _roleBadgeText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Site Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: member.assignedSite == 'South City Mall'
                        ? Border.all(color: _kAmberBg.withAlpha(180))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.domain, size: 12, color: _badgeText),
                      const SizedBox(width: 4),
                      Text(
                        member.assignedSite,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _badgeText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Divider ──────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),

            // ── Bottom Row ───────────────────────────────────
            Row(
              children: [
                Icon(
                  _roleIcon,
                  size: 15,
                  color: _roleBadgeText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    member.metric,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                // Call button
                _ActionButton(
                  icon: Icons.call,
                  label: 'Call',
                  bgColor: const Color(0xFFE4F4EC),
                  textColor: _kBrand,
                  onTap: onCall,
                ),
                const SizedBox(width: 8),
                // Edit button
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  bgColor: _kSurface,
                  textColor: const Color(0xFF334155),
                  bordered: true,
                  onTap: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final bool bordered;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.bordered = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: bordered ? Border.all(color: const Color(0xFFE2E8F0)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Staff Bottom Sheet ────────────────────────────────────────────────────

class _AddStaffSheet extends StatefulWidget {
  final ValueChanged<String> onAdded;
  const _AddStaffSheet({required this.onAdded});

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedRole = 'Driver';
  String _selectedSite = 'CyberHub Corporate Plaza';

  final List<String> _sites = [
    'CyberHub Corporate Plaza',
    'Aerocity Grand Terminal - T2',
    'Grand Hyatt & Convention',
    'JW Marriott Porch',
    'South City Luxury Mall Deck',
    'St. Regis Hotel',
  ];
  final List<String> _roles = ['Driver', 'Manager', 'Assistant Manager'];

  @override
  void initState() {
    super.initState();
    if (SiteManager.instance.hasSites) {
      for (final s in SiteManager.instance.siteNames) {
        if (!_sites.contains(s)) _sites.insert(0, s);
      }
      if (SiteManager.instance.selectedSite.isNotEmpty &&
          !SiteManager.instance.selectedSite.startsWith('All Sites')) {
        _selectedSite = SiteManager.instance.selectedSite;
      } else {
        _selectedSite = _sites.first;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add, color: _kBrand, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Add New Staff',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Full Name
            _SheetField(label: 'Full Name', child: TextField(
              controller: _nameCtrl,
              decoration: _inputDec('e.g. Sameer Khan'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 12),

            // Phone
            _SheetField(label: 'Contact Number', child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDec('+91 98000 00000'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 12),

            // Role
            _SheetField(label: 'Role', child: _StyledDropdown(
              value: _selectedRole,
              items: _roles,
              onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
            )),
            const SizedBox(height: 12),

            // Site
            _SheetField(label: 'Assigned Property', child: _StyledDropdown(
              value: _selectedSite,
              items: _sites,
              onChanged: (v) => setState(() => _selectedSite = v ?? _selectedSite),
            )),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(context);
                      widget.onAdded(name);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrand,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Enroll Staff', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Staff Bottom Sheet ───────────────────────────────────────────────────

class _EditStaffSheet extends StatefulWidget {
  final _StaffMember member;
  final void Function(String name, String site, _StaffRole role, bool active) onSaved;
  final VoidCallback onDeactivated;

  const _EditStaffSheet({
    required this.member,
    required this.onSaved,
    required this.onDeactivated,
  });

  @override
  State<_EditStaffSheet> createState() => _EditStaffSheetState();
}

class _EditStaffSheetState extends State<_EditStaffSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedSite;
  late String _selectedRole;
  late bool _isOnDuty;

  final List<String> _sites = [
    'CyberHub Corporate Plaza',
    'Aerocity Grand Terminal - T2',
    'Grand Hyatt & Convention',
    'JW Marriott Porch',
    'South City Luxury Mall Deck',
    'St. Regis Hotel',
  ];
  final List<String> _roles = ['driver', 'manager', 'asstManager'];
  final Map<String, String> _roleLabels = {
    'driver': 'Driver',
    'manager': 'Manager',
    'asstManager': 'Assistant Manager',
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
    if (SiteManager.instance.hasSites) {
      for (final s in SiteManager.instance.siteNames) {
        if (!_sites.contains(s)) _sites.add(s);
      }
    }
    _selectedSite = widget.member.assignedSite;
    if (!_sites.contains(_selectedSite) && _selectedSite.isNotEmpty) {
      _sites.insert(0, _selectedSite);
    }
    _selectedRole = widget.member.role == _StaffRole.asstManager
        ? 'asstManager'
        : (widget.member.role == _StaffRole.manager ? 'manager' : 'driver');
    _isOnDuty = widget.member.isOnDuty;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Staff Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name
              _SheetField(label: 'Full Name', child: TextField(
                controller: _nameCtrl,
                decoration: _inputDec('Full Name'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              )),
              const SizedBox(height: 12),

              // ID (readonly)
              _SheetField(
                label: 'Staff ID & License',
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          widget.member.id,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kBrand),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Role
              _SheetField(label: 'Role', child: _StyledDropdown(
                value: _selectedRole,
                items: _roles,
                labelMap: _roleLabels,
                onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
              )),
              const SizedBox(height: 12),

              // Site
              _SheetField(label: 'Assigned Valet Site', child: _StyledDropdown(
                value: _selectedSite,
                items: _sites,
                onChanged: (v) => setState(() => _selectedSite = v ?? _selectedSite),
              )),
              const SizedBox(height: 16),

              // Duty Toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Duty Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        SizedBox(height: 2),
                        Text('Mark staff as active on the floor', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnDuty,
                    onChanged: (v) => setState(() => _isOnDuty = v),
                    activeThumbColor: _kBrand,
                    activeTrackColor: _kBrand.withAlpha(100),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDeactivated();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final role = _selectedRole == 'asstManager'
                            ? _StaffRole.asstManager
                            : (_selectedRole == 'manager'
                                ? _StaffRole.manager
                                : _StaffRole.driver);
                        widget.onSaved(_nameCtrl.text.trim(), _selectedSite, role, _isOnDuty);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBrand,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  final String label;
  final Widget child;
  const _SheetField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final Map<String, String>? labelMap;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    this.labelMap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveItems = items.contains(value) ? items : [value, ...items];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: _kBrand),
          items: effectiveItems.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                labelMap?[item] ?? item,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

InputDecoration _inputDec(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w400),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBrand, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}
