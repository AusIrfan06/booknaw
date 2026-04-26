import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'app_logo.dart';
import 'auth_success_screen.dart';

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
  final _staffCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureStaffCode = true;
  bool _usePhone = false;

  Future<void> _signUp() async {
    if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan nama pertama dan nama akhir!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool isStaff = false;
      if (_staffCodeController.text.trim() == 'STAFFENT300') {
        isStaff = true;
      }

      String identifier = _emailController.text.trim();
      if (_usePhone) {
        if (!RegExp(r'^[0-9]+$').hasMatch(identifier)) {
          throw Exception('Sila masukkan nombor telefon yang sah!');
        }
        identifier = '$identifier@nachos.com';
      }

      await Supabase.instance.client.auth.signUp(
        email: identifier,
        password: _passwordController.text,
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'is_staff': isStaff,
          'phone': _usePhone ? _emailController.text.trim() : null,
        },
      );
      
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat daftar: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            child: GlassContainer(
              useOwnLayer: true,
              quality: GlassQuality.standard,
              shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
              settings: _getGlassSettings(isDark),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 60)),
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlassField(
                            controller: _firstNameController,
                            label: 'Nama Pertama',
                            icon: HugeIcons.strokeRoundedUser,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGlassField(
                            controller: _lastNameController,
                            label: 'Nama Akhir',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ChoicePill(
                          label: 'Email',
                          selected: !_usePhone,
                          onTap: () => setState(() => _usePhone = false),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _ChoicePill(
                          label: 'Telefon',
                          selected: _usePhone,
                          onTap: () => setState(() => _usePhone = true),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGlassField(
                      controller: _emailController,
                      label: _usePhone ? 'No. Telefon' : 'Email',
                      icon: _usePhone ? HugeIcons.strokeRoundedSmartPhone01 : HugeIcons.strokeRoundedMail01,
                      isDark: isDark,
                      keyboardType: _usePhone ? TextInputType.phone : TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildGlassField(
                      controller: _passwordController,
                      label: 'Katalaluan (Min 6)',
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
                      label: 'Kod Promosi (Pilihan)',
                      icon: HugeIcons.strokeRoundedGiftCard,
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
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Daftar Sekarang',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    dynamic icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
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

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected 
            ? const Color(0xFFFF5722) 
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? [
            BoxShadow(
              color: const Color(0xFFFF5722).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
