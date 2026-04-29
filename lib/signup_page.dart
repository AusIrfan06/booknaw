import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'auth_success_screen.dart';
import 'utils/glass_toast.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _staffCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureStaffCode = true;

  Future<void> _signUp() async {
    String firstName = _firstNameController.text.trim();
    firstName = firstName.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');
    
    String lastName = _lastNameController.text.trim();
    lastName = lastName.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');
    String email = _emailController.text.trim();
    String phoneInput = _phoneController.text.trim();
    String password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      showGlassToast(context, 'Sila masukkan nama pertama dan nama akhir!', isError: true);
      return;
    }

    if (email.isEmpty) {
      showGlassToast(context, 'Sila masukkan alamat email!', isError: true);
      return;
    }

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
      bool isStaff = false;
      if (_staffCodeController.text.trim().toUpperCase() == 'STAFFENT300') {
        isStaff = true;
      }



      // Format phone correctly: strip leading zero and remove all spaces
      String cleanPhoneInput = phoneInput.replaceAll(RegExp(r'\s+'), '');
      if (cleanPhoneInput.startsWith('0')) {
        cleanPhoneInput = cleanPhoneInput.substring(1);
      }
      String phone = '+60$cleanPhoneInput';

      final authRes = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName',
          'is_staff': isStaff,
          'phone': phone,
        },
      );
      
      final userId = authRes.user?.id;
      if (userId != null) {
        // Create user record for future lookups (like phone login)
        await Supabase.instance.client.from('users').upsert({
          'id': userId,
          'email': email,
          'phone': phone,
          'full_name': '$firstName $lastName',
          'first_name': firstName,
          'last_name': lastName,
          'is_staff': isStaff,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AuthSuccessScreen(
              name: _firstNameController.text.trim(),
              isStaff: isStaff,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassToast(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _staffCodeController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daftar Akaun'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
              : [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Cipta Akaun Baru',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sertai komuniti Nachozy hari ini!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildGlassField(
                          controller: _firstNameController,
                          label: 'Nama Pertama',
                          icon: HugeIcons.strokeRoundedUser,
                          isDark: isDark,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _lastNameController,
                          label: 'Nama Akhir',
                          icon: HugeIcons.strokeRoundedUser,
                          isDark: isDark,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _emailController,
                          label: 'Email',
                          icon: HugeIcons.strokeRoundedMail01,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _phoneController,
                          label: 'No. Telefon',
                          icon: HugeIcons.strokeRoundedSmartPhone01,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                          prefixText: '+60 ',
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _passwordController,
                          label: 'Kata Laluan (Min 6)',
                          icon: HugeIcons.strokeRoundedLockPassword,
                          isDark: isDark,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: HugeIcon(
                              icon: _obscurePassword ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _staffCodeController,
                          label: 'Kod Rujukan (Abaikan jika tiada)',
                          icon: HugeIcons.strokeRoundedShare01,
                          isDark: isDark,
                          obscureText: _obscureStaffCode,
                          suffixIcon: IconButton(
                            icon: HugeIcon(
                              icon: _obscureStaffCode ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureStaffCode = !_obscureStaffCode),
                          ),
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
        ),
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

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    dynamic icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
          prefixText: prefixText,
          prefixStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
          prefixIcon: icon != null ? Padding(
            padding: const EdgeInsets.all(12.0),
            child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
          ) : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}


