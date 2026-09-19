import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_text_field.dart';

class AddSiteWizardScreen extends StatefulWidget {
  const AddSiteWizardScreen({super.key});

  @override
  State<AddSiteWizardScreen> createState() => _AddSiteWizardScreenState();
}

class _AddSiteWizardScreenState extends State<AddSiteWizardScreen> {
  int _currentStep = 1;

  // Step 1 Controllers
  final _siteNameController = TextEditingController(text: 'Grand Hyatt Regency');
  final _terminalCodeController = TextEditingController(text: 'GHR-T1');
  final _addressController = TextEditingController(text: 'Bandra Kurla Complex, Mumbai');
  final _operatingHoursController = TextEditingController(text: '24 Hours (3 Shifts)');

  // Step 2 Controllers
  int _deckACapacity = 80;
  int _deckBCapacity = 60;
  int _evSlots = 10;
  int _vipSlots = 15;

  // Step 3 Controllers
  final _hourlyRateController = TextEditingController(text: '150');
  final _flatRateController = TextEditingController(text: '300');
  final _overnightRateController = TextEditingController(text: '500');

  @override
  void dispose() {
    _siteNameController.dispose();
    _terminalCodeController.dispose();
    _addressController.dispose();
    _operatingHoursController.dispose();
    _hourlyRateController.dispose();
    _flatRateController.dispose();
    _overnightRateController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Site "${_siteNameController.text}" configured and deployed!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        title: Text(
          'Add New Site Setup',
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceContainerLow,
            child: Row(
              children: [
                _buildStepIndicator(1, 'Site Info'),
                const Expanded(child: Divider(color: Color(0x33BEC9C2))),
                _buildStepIndicator(2, 'Decks & Slots'),
                const Expanded(child: Divider(color: Color(0x33BEC9C2))),
                _buildStepIndicator(3, 'Staff & Rates'),
              ],
            ),
          ),

          // Step Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStepContent(),
            ),
          ),

          // Bottom Command Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(top: BorderSide(color: Color(0x33BEC9C2), width: 1)),
            ),
            child: Row(
              children: [
                if (_currentStep > 1) ...[
                  Expanded(
                    child: HudButton(
                      text: 'Previous',
                      variant: HudButtonVariant.secondary,
                      onPressed: _prevStep,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: HudButton(
                    text: _currentStep == 3 ? 'Finalize & Deploy Site' : 'Next Step',
                    trailingIcon: _currentStep == 3 ? Icons.rocket_launch : Icons.arrow_forward,
                    onPressed: _nextStep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.primary
                : isActive
                    ? AppColors.primary
                    : AppColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.outline,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: isActive ? AppColors.primary : AppColors.outline,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1SiteInfo();
      case 2:
        return _buildStep2DecksLayout();
      case 3:
        return _buildStep3RatesStaff();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1SiteInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Property Identity',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Register hospital, hotel, or commercial valet operations hub.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        HudCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              HudTextField(
                label: 'Property Name',
                controller: _siteNameController,
                prefixIcon: Icons.apartment,
              ),
              const SizedBox(height: 14),
              HudTextField(
                label: 'Terminal Code Identifier',
                controller: _terminalCodeController,
                prefixIcon: Icons.qr_code,
              ),
              const SizedBox(height: 14),
              HudTextField(
                label: 'Full Street Address',
                controller: _addressController,
                prefixIcon: Icons.location_on,
              ),
              const SizedBox(height: 14),
              HudTextField(
                label: 'Operating Hours & Shift Plan',
                controller: _operatingHoursController,
                prefixIcon: Icons.schedule,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2DecksLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Decks & Layout Dynamic',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Define slot allocations, ramps, VIP lanes, and EV charging points.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        HudCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSlotCounter(
                title: 'Deck A (Main Valet Apron)',
                count: _deckACapacity,
                onChanged: (val) => setState(() => _deckACapacity = val),
              ),
              const Divider(color: Color(0x33BEC9C2), height: 24),
              _buildSlotCounter(
                title: 'Deck B (Basement Storage)',
                count: _deckBCapacity,
                onChanged: (val) => setState(() => _deckBCapacity = val),
              ),
              const Divider(color: Color(0x33BEC9C2), height: 24),
              _buildSlotCounter(
                title: 'EV Fast-Charging Bays',
                count: _evSlots,
                onChanged: (val) => setState(() => _evSlots = val),
              ),
              const Divider(color: Color(0x33BEC9C2), height: 24),
              _buildSlotCounter(
                title: 'VIP Porch Reserved Bays',
                count: _vipSlots,
                onChanged: (val) => setState(() => _vipSlots = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCounter({
    required String title,
    required int count,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
            Text('$count total dedicated slots', style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: AppColors.primary, size: 20),
              onPressed: () {
                if (count > 0) onChanged(count - 5);
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
              onPressed: () => onChanged(count + 5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3RatesStaff() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Tariff & Roster Setup',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure pricing tariff matrix and default valet assignment roster.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        HudCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              HudTextField(
                label: 'Hourly Valet Rate (₹)',
                controller: _hourlyRateController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee,
              ),
              const SizedBox(height: 14),
              HudTextField(
                label: 'Flat Day Tariff (₹)',
                controller: _flatRateController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee,
              ),
              const SizedBox(height: 14),
              HudTextField(
                label: 'Overnight Surcharge (₹)',
                controller: _overnightRateController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
