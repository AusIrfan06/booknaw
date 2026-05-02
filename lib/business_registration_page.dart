import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/glass_toast.dart';
import 'business_owner_dashboard.dart';
import 'supabase_service.dart';


class BusinessRegistrationPage extends StatefulWidget {
  const BusinessRegistrationPage({super.key});

  @override
  State<BusinessRegistrationPage> createState() => _BusinessRegistrationPageState();
}

class _BusinessRegistrationPageState extends State<BusinessRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessTypeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) showGlassToast(context, "Sila log masuk terlebih dahulu", isError: true);
        return;
      }

      await SupabaseService.registerBusiness(
        name: _businessNameController.text.trim(),
        email: _businessEmailController.text.trim(),
        phone: _businessPhoneController.text.trim(),
        address: _businessAddressController.text.trim(),
        type: _businessTypeController.text.trim(),
      );

      if (mounted) {
        showGlassToast(context, "Pendaftaran perniagaan berjaya!");
        // Small delay to let the toast be seen
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
           Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BusinessOwnerDashboard()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) showGlassToast(context, "Ralat: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Daftar Perniagaan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            shape: LiquidRoundedSuperellipse(borderRadius: 999.0),
            settings: LiquidGlassSettings(thickness: 0.2, blur: 20),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.05 : 0.1)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withValues(alpha: isDark ? 0.05 : 0.1)))),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildHeroSection(isDark),
                        const SizedBox(height: 32),
                        
                        Text("Maklumat Perniagaan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 16),
                        
                        _buildGlassTextField(
                          controller: _businessNameController,
                          label: "Nama Perniagaan",
                          icon: HugeIcons.strokeRoundedStore01,
                          isDark: isDark,
                          validator: (v) => v!.isEmpty ? "Sila masukkan nama perniagaan" : null,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildGlassTextField(
                          controller: _businessTypeController,
                          label: "Jenis Perniagaan (cth: Restoran, Spa, Kedai)",
                          icon: HugeIcons.strokeRoundedShoppingBag01,
                          isDark: isDark,
                          validator: (v) => v!.isEmpty ? "Sila masukkan jenis perniagaan" : null,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildGlassTextField(
                          controller: _businessEmailController,
                          label: "Emel Perniagaan",
                          icon: HugeIcons.strokeRoundedMail01,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.isEmpty ? "Sila masukkan emel" : null,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildGlassTextField(
                          controller: _businessPhoneController,
                          label: "No. Telefon Perniagaan",
                          icon: HugeIcons.strokeRoundedSmartPhone01,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? "Sila masukkan no. telefon" : null,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildGlassTextField(
                          controller: _businessAddressController,
                          label: "Alamat Perniagaan",
                          icon: HugeIcons.strokeRoundedLocation01,
                          isDark: isDark,
                          maxLines: 3,
                          validator: (v) => v!.isEmpty ? "Sila masukkan alamat" : null,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        _buildSubmitButton(isDark),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: _getGlassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5722).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const HugeIcon(icon: HugeIcons.strokeRoundedGlobalEducation, color: Color(0xFFFF5722), size: 48),
            const SizedBox(height: 16),
            Text(
              "Kembangkan Perniagaan Anda",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Daftar sebagai rakan kongsi BookNaw dan mula terima tempahan dengan lebih mudah.",
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required dynamic icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
      settings: _getGlassSettings(isDark),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6)),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return GestureDetector(
      onTap: _isLoading ? null : _submitRegistration,
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
        settings: _getGlassSettings(isDark),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5722),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(
                    "Daftar Perniagaan",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  LiquidGlassSettings _getGlassSettings(bool isDark) {
    return LiquidGlassSettings(
      thickness: 0.1,
      blur: 15,
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: isDark ? 0.1 : 0.2,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    );
  }
}
