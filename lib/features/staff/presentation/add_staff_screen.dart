import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_text_field.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  String _selectedRole = 'Valet Driver';
  String _selectedSite = 'Aerocity Grand T2';
  bool _isEnrolling = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  void _enrollStaff() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter staff full name')),
      );
      return;
    }
    setState(() => _isEnrolling = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isEnrolling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff member ${_nameController.text} enrolled successfully!'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Add New Staff Member',
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPERATIONAL ONBOARDING',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textHighLuminance,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enroll valet drivers, shift supervisors, and porters into terminal dispatch.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            HudCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HudTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    placeholder: 'e.g. Rahul Verma',
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 14),
                  HudTextField(
                    label: 'Mobile Phone Number',
                    controller: _phoneController,
                    placeholder: '+91 98XXX XXXXX',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone,
                  ),
                  const SizedBox(height: 14),
                  HudTextField(
                    label: 'Driver License Number',
                    controller: _licenseController,
                    placeholder: 'DL-0420110023456',
                    prefixIcon: Icons.badge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'OPERATIONAL ROLE',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.groundZero,
                      border: Border.all(color: AppColors.borderSubtle, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        dropdownColor: AppColors.cardModule,
                        isExpanded: true,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textHighLuminance),
                        items: ['Valet Driver', 'Porch Supervisor', 'Site Manager', 'Terminal Lead']
                            .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ASSIGNED VALET PROPERTY',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.groundZero,
                      border: Border.all(color: AppColors.borderSubtle, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSite,
                        dropdownColor: AppColors.cardModule,
                        isExpanded: true,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textHighLuminance),
                        items: ['Aerocity Grand T2', 'CyberHub Plaza', 'South City Mall', 'Terminal 2 Executive Deck']
                            .map((site) => DropdownMenuItem(value: site, child: Text(site)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSite = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  HudButton(
                    text: 'CONFIRM & ENROLL STAFF',
                    icon: Icons.check,
                    isLoading: _isEnrolling,
                    onPressed: _enrollStaff,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
