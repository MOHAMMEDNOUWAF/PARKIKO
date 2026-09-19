import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_chip.dart';
import 'add_staff_screen.dart';

class StaffMember {
  final String id;
  final String name;
  final String staffCode;
  final String phone;
  final HudRole role;
  final String roleTitle;
  final String assignedSite;
  final bool isClockedIn;
  final int runsToday;
  final double rating;

  const StaffMember({
    required this.id,
    required this.name,
    required this.staffCode,
    required this.phone,
    required this.role,
    required this.roleTitle,
    required this.assignedSite,
    required this.isClockedIn,
    required this.runsToday,
    required this.rating,
  });
}

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  String _selectedRoleFilter = 'all';

  final List<StaffMember> _staff = [
    const StaffMember(
      id: '1',
      name: 'Arjun Sharma',
      staffCode: '#STF-104',
      phone: '+91 98201 11223',
      role: HudRole.valet,
      roleTitle: 'T2 Lead Valet',
      assignedSite: 'Aerocity Grand T2',
      isClockedIn: true,
      runsToday: 14,
      rating: 4.9,
    ),
    const StaffMember(
      id: '2',
      name: 'Vikram Singh',
      staffCode: '#STF-082',
      phone: '+91 98334 22334',
      role: HudRole.valet,
      roleTitle: 'CyberHub Valet',
      assignedSite: 'CyberHub Plaza',
      isClockedIn: true,
      runsToday: 11,
      rating: 4.8,
    ),
    const StaffMember(
      id: '3',
      name: 'Rakesh Nair',
      staffCode: '#STF-099',
      phone: '+91 97110 33445',
      role: HudRole.manager,
      roleTitle: 'Porch Operations Lead',
      assignedSite: 'South City Mall',
      isClockedIn: true,
      runsToday: 8,
      rating: 5.0,
    ),
    const StaffMember(
      id: '4',
      name: 'Deepak Mishra',
      staffCode: '#STF-110',
      phone: '+91 99100 44556',
      role: HudRole.valet,
      roleTitle: 'EV Deck Specialist',
      assignedSite: 'Aerocity Grand T2',
      isClockedIn: false,
      runsToday: 0,
      rating: 4.7,
    ),
    const StaffMember(
      id: '5',
      name: 'Mohit Rawat',
      staffCode: '#STF-125',
      phone: '+91 98111 55667',
      role: HudRole.admin,
      roleTitle: 'Site Supervisor',
      assignedSite: 'Executive Deck T2',
      isClockedIn: true,
      runsToday: 19,
      rating: 4.95,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredStaff = _staff.where((s) {
      if (_selectedRoleFilter == 'valet' && s.role != HudRole.valet) return false;
      if (_selectedRoleFilter == 'manager' && s.role != HudRole.manager) return false;
      if (_selectedRoleFilter == 'admin' && s.role != HudRole.admin) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Staff & Roster',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddStaffScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header & Add Staff CTA
          Padding(
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
                        Text(
                          'Staff Management',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.textHighLuminance,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_staff.where((s) => s.isClockedIn).length} Active On Shift • ${_staff.length} Total Enrolled',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    HudButton(
                      text: '+ ADD STAFF',
                      fullWidth: false,
                      height: 38,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddStaffScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Role filter pills
                Row(
                  children: [
                    _buildRolePill('all', 'ALL (${_staff.length})'),
                    const SizedBox(width: 6),
                    _buildRolePill('valet', 'VALETS'),
                    const SizedBox(width: 6),
                    _buildRolePill('manager', 'MANAGERS'),
                    const SizedBox(width: 6),
                    _buildRolePill('admin', 'LEADS'),
                  ],
                ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredStaff.length,
              itemBuilder: (context, index) {
                final member = filteredStaff[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HudCard(
                    padding: const EdgeInsets.all(14),
                    leftAccentColor: member.isClockedIn ? AppColors.statusAvailable : AppColors.statusOffline,
                    leftAccentWidth: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textHighLuminance,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    member.staffCode,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${member.roleTitle} • ${member.assignedSite}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.directions_car, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${member.runsToday} runs today',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.star, size: 13, color: AppColors.tertiary),
                                  const SizedBox(width: 3),
                                  Text(
                                    member.rating.toString(),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            HudRoleChip(role: member.role),
                            const SizedBox(height: 8),
                            HudStatusChip(
                              label: member.isClockedIn ? 'ON SHIFT' : 'OFF DUTY',
                              status: member.isClockedIn ? OperationalStatus.available : OperationalStatus.offline,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill(String roleKey, String label) {
    final isSelected = _selectedRoleFilter == roleKey;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = roleKey),
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.groundZero,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? AppColors.borderFocused : AppColors.borderSubtle,
            width: 1,
          ),
        ),
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
