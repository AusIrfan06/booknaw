import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'auth_success_screen.dart';
import 'utils/glass_toast.dart';

class GuestSignupPage extends StatefulWidget {
  const GuestSignupPage({super.key});

  @override
  State<GuestSignupPage> createState() => _GuestSignupPageState();
}

class _GuestSignupPageState extends State<GuestSignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    String firstName = _firstNameController.text.trim();
    firstName = firstName.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');

    String lastName = _lastNameController.text.trim();
    lastName = lastName.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');
    String phoneInput = _phoneController.text.trim();
    String password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      showGlassToast(context, 'Sila masukkan nama pertama dan nama akhir!', isError: true);
      return;
    }

    String fullName = '$firstName $lastName';

    if (phoneInput.isEmpty) {
      showGlassToast(context, 'Sila masukkan no. telefon!', isError: true);
      return;
    }

    if (password.length < 6) {
      showGlassToast(context, 'Kata laluan mestilah sekurang-kurangnya 6 aksara!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Clean phone number (remove spaces)
      String cleanPhoneInput = phoneInput.replaceAll(RegExp(r'\s+'), '');
      if (cleanPhoneInput.startsWith('0')) {
        cleanPhoneInput = cleanPhoneInput.substring(1);
      }
      
      String phone = '+60$cleanPhoneInput';
      // Create a fake email using the phone number to satisfy Supabase
      String fakeEmail = '$cleanPhoneInput@nachos.com';

      final authRes = await Supabase.instance.client.auth.signUp(
        email: fakeEmail,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'is_staff': false,
        },
      );
      
      final userId = authRes.user?.id;
      if (userId != null) {
        // Save to public users table
        await Supabase.instance.client.from('users').upsert({
          'id': userId,
          'email': fakeEmail,
          'phone': phone,
          'full_name': fullName,
          'first_name': firstName,
          'last_name': lastName,
          'is_staff': false,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AuthSuccessScreen(
              name: firstName,
              isStaff: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassToast(context, 'Ralat: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daftar Tetamu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      ),
      body: Stack(
        children: [
          _buildBackground(isDark),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: GlassContainer(
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                  shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                  settings: _getGlassSettings(isDark),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Daftar Cepat',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hanya perlukan no. telefon & kata laluan',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        _buildField(
                          controller: _firstNameController,
                          label: 'Nama Pertama',
                          icon: HugeIcons.strokeRoundedUser,
                          isDark: isDark,
                          keyboardType: TextInputType.name,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _lastNameController,
                          label: 'Nama Akhir',
                          icon: HugeIcons.strokeRoundedUser,
                          isDark: isDark,
                          keyboardType: TextInputType.name,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _phoneController,
                          label: 'No. Telefon',
                          icon: HugeIcons.strokeRoundedSmartPhone01,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                          prefixText: '+60 ',
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _passwordController,
                          label: 'Kata Laluan',
                          icon: HugeIcons.strokeRoundedLock,
                          isDark: isDark,
                          isPassword: true,
                        ),
                        const SizedBox(height: 32),
                        _buildFrostedButton(
                          label: 'Daftar Sekarang',
                          onTap: _signUp,
                          isPrimary: true,
                          isLoading: _isLoading,
                          isDark: isDark,
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
    );
  }

  Widget _buildFrostedButton({
    required String label,
    required VoidCallback? onTap,
    dynamic icon,
    bool isPrimary = false,
    bool isLoading = false,
    required bool isDark,
  }) {
    const color = Color(0xFFFF5722);
    
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
      settings: LiquidGlassSettings(
        thickness: 0.1,
        blur: 15,
        refractiveIndex: 1.0,
        glassColor: Colors.transparent,
        lightAngle: 45.0,
        lightIntensity: isDark ? 0.1 : 0.2,
        ambientStrength: 1.0,
        saturation: 1.0,
        chromaticAberration: 0.0,
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary 
                ? color.withValues(alpha: isDark ? 0.8 : 0.9)
                : color.withValues(alpha: isDark ? 0.1 : 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isPrimary ? 0.5 : (isDark ? 0.3 : 0.5)),
              width: 1.0,
            ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        HugeIcon(
                          icon: icon,
                          color: isPrimary ? Colors.white : color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: isPrimary ? Colors.white : color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required dynamic icon,
    required bool isDark,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixText: prefixText,
              icon: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
              border: InputBorder.none,
              hintText: 'Masukkan $label',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  LiquidGlassSettings _getGlassSettings(bool isDark) {
    return LiquidGlassSettings(
      thickness: 0.1, blur: 15, refractiveIndex: 1.0,
      glassColor: Colors.transparent, lightAngle: 45.0,
      lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
      saturation: 1.0, chromaticAberration: 0.0,
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [const Color(0xFF121212), const Color(0xFF1E1E1E)] : [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)],
        ),
      ),
    );
  }
}
