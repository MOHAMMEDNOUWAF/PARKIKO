import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/site_manager.dart';
import '../../../../core/widgets/parkiko_logo.dart';
import 'add_site_wizard_screen.dart';

/// Entrypoint for the Parkiko Admin - Add New Site (Step 1: Multi-Site Onboarding).
/// Conforms to Flutter Material 3, strict Parkiko Admin design tokens, and production architecture.
void main() {
  runApp(const ParkikoAdminApp());
}

class ParkikoAdminApp extends StatelessWidget {
  const ParkikoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkiko Admin - Add New Site',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF00513A),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF0F6B4F),
          onPrimaryContainer: Color(0xFF97E8C5),
          secondary: Color(0xFF2D6955),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFAFEDD4),
          onSecondaryContainer: Color(0xFF326D59),
          surface: Color(0xFFF1FCF5),
          onSurface: Color(0xFF141E1A),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xFFEBF6EF),
          surfaceContainer: Color(0xFFE5F1EA),
          surfaceContainerHigh: Color(0xFFDFEBE4),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          outline: Color(0xFF6F7A73),
          outlineVariant: Color(0xFFBEC9C2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1FCF5),
      ),
      home: const AddNewSiteScreen(),
    );
  }
}

class AddNewSiteScreen extends StatefulWidget {
  final VoidCallback? onSiteCreated;
  final VoidCallback? onContinue;

  const AddNewSiteScreen({super.key, this.onSiteCreated, this.onContinue});

  @override
  State<AddNewSiteScreen> createState() => _AddNewSiteScreenState();
}

class _AddNewSiteScreenState extends State<AddNewSiteScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _baseFeeController = TextEditingController(text: '150');
  final TextEditingController _vipFeeController = TextEditingController(text: '300');
  final TextEditingController _retentionFeeController = TextEditingController();

  // Capacity state
  final int _totalValetBays = 150;
  bool _isDetectingGps = false;

  @override
  void dispose() {
    _siteNameController.dispose();
    _addressController.dispose();
    _baseFeeController.dispose();
    _vipFeeController.dispose();
    _retentionFeeController.dispose();
    super.dispose();
  }


  void _detectGpsLocation() async {
    setState(() {
      _isDetectingGps = true;
    });

    // Simulated GPS acquisition delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isDetectingGps = false;
      _addressController.text =
          'Gate 4, Asset 1, Hospitality District, Aerocity T2, New Delhi';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFFAFEDD4), size: 18),
            SizedBox(width: 8),
            Text('GPS Location detected and populated!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00513A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      final siteName = _siteNameController.text.trim();
      final address = _addressController.text.trim();
      final baseFee = double.tryParse(_baseFeeController.text.trim()) ?? 150.0;
      final vipFee = double.tryParse(_vipFeeController.text.trim()) ?? 300.0;
      final overnightFee = double.tryParse(_retentionFeeController.text.trim()) ?? 500.0;

      final siteId = 'site_${DateTime.now().millisecondsSinceEpoch}';
      final newSite = SiteModel(
        id: siteId,
        name: siteName,
        address: address,
        totalBays: _totalValetBays,
        baseFee: baseFee,
        vipFee: vipFee,
        overnightFee: overnightFee,
        status: 'active',
        createdAt: DateTime.now(),
      );

      SiteManager.instance.addSite(newSite);
      SiteManager.instance.selectedSite = siteName;
      widget.onSiteCreated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Site "$siteName" configured and deployed!'),
          backgroundColor: const Color(0xFF00513A),
        ),
      );

      if (widget.onContinue != null) {
        widget.onContinue!();
      } else {
        Navigator.maybePop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF141E1A)),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back',
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Site',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF141E1A),
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Multi-Site Valet Onboarding',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6F7A73),
              ),
            ),
          ],
        ),
        actions: [
          const Center(
            child: ParkikoLogo(size: 28),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF6F7A73)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Site Onboarding Help'),
                  content: const Text(
                    'Step 1 defines basic property parameters and default tariff rates across all operational decks.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Help',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Property & Site Details Section
                      _buildPropertyDetailsCard(theme),
                      const SizedBox(height: 16),


                      // 3. Valet Rates & Billing Defaults Section
                      _buildRatesCard(theme),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom Action Bar
            _buildStickyFooter(theme),
          ],
        ),
      ),
    );
  }

  /// Property & Site Details Card
  Widget _buildPropertyDetailsCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.apartment, size: 20, color: Color(0xFF00513A)),
              SizedBox(width: 8),
              Text(
                'Property & Site Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141E1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Site Name
          const Row(
            children: [
              Text(
                'Site Name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF141E1A),
                ),
              ),
              Text(' *', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('input_site_name'),
            controller: _siteNameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 14, color: Color(0xFF141E1A)),
            decoration: _inputDecoration(
              hintText: 'e.g., Grand Hyatt & Convention, Aerocity T2',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter site name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Address & GPS Auto-detect
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Complete Address / Location',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF141E1A),
                    ),
                  ),
                  Text(' *', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                key: const Key('btn_detect_gps'),
                onTap: _isDetectingGps ? null : _detectGpsLocation,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      _isDetectingGps
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00513A)),
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                              size: 15,
                              color: Color(0xFF00513A),
                            ),
                      const SizedBox(width: 4),
                      const Text(
                        'Detect Current GPS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00513A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('input_address'),
            controller: _addressController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: Color(0xFF141E1A), height: 1.3),
            decoration: _inputDecoration(
              hintText: 'e.g., Gate 4, Asset 1, Hospitality District, New Delhi',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter location address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }



  /// Valet Rates & Billing Defaults Card
  Widget _buildRatesCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined, size: 20, color: Color(0xFF00513A)),
              SizedBox(width: 8),
              Text(
                'Valet Rates & Billing Defaults',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141E1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Side-by-side Base & VIP Rates
          Row(
            children: [
              // Base Valet Fee
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Base Valet Fee (₹)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF141E1A),
                          ),
                        ),
                        Text(' *', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('input_base_fee'),
                      controller: _baseFeeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF141E1A)),
                      decoration: _currencyInputDecoration(prefix: '₹ '),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // VIP Porch Expedited
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VIP Porch Expedited (₹)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF141E1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('input_vip_fee'),
                      controller: _vipFeeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF141E1A)),
                      decoration: _currencyInputDecoration(prefix: '₹ '),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overnight / Rollover Retention Fee
          const Text(
            'Overnight / Rollover Retention Fee (₹)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF141E1A),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('input_retention_fee'),
            controller: _retentionFeeController,
            style: const TextStyle(fontSize: 14, color: Color(0xFF141E1A)),
            decoration: _inputDecoration(
              hintText: '₹ e.g., 500 per night',
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky Bottom Actions
  Widget _buildStickyFooter(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            flex: 2,
            child: OutlinedButton(
              key: const Key('btn_cancel'),
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFBEC9C2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF141E1A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Continue to next Button
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              key: const Key('btn_continue'),
              onPressed: _handleContinue,
              icon: const Icon(Icons.domain_add, size: 18),
              label: const Text(
                'Deploy & Activate Site',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00513A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6F7A73)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBEC9C2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBEC9C2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00513A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
      ),
    );
  }

  InputDecoration _currencyInputDecoration({required String prefix}) {
    return InputDecoration(
      prefixText: prefix,
      prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF141E1A)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBEC9C2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBEC9C2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00513A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
      ),
    );
  }
}
