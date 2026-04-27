import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'signup_page.dart';
import 'staff_dashboard.dart';
import 'app_logo.dart';
import 'forgot_password_page.dart';
import 'auth_success_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final rawIdentifier = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // 1. Try as-entered (Email or Username)
      try {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: rawIdentifier,
          password: password,
        );
        if (mounted) _handleSignInSuccess(res);
        return;
      } catch (e) {
        final isDigits = RegExp(r'^[0-9]+$').hasMatch(rawIdentifier);
        if (!isDigits || !e.toString().contains('invalid_credentials')) {
          rethrow;
        }
      }

      // 2. Prepare phone variations
      String cleanPhone = rawIdentifier;
      if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }
      final variations = [
        '+60$cleanPhone', // Standard: +6011...
        '60$cleanPhone',  // 6011...
        rawIdentifier,    // 011...
      ];

      // 3. Try searching users for each variation
      for (var phone in variations) {
        try {
          final profileData = await Supabase.instance.client
              .from('users')
              .select('email')
              .eq('phone', phone)
              .maybeSingle();
          
          if (profileData != null && profileData['email'] != null) {
            final res = await Supabase.instance.client.auth.signInWithPassword(
              email: profileData['email'],
              password: password,
            );
            if (mounted) _handleSignInSuccess(res);
            return;
          }
        } catch (_) {}
      }

      // 4. Try fake email formats
      final fakeEmails = [
        '$cleanPhone@nachos.com',
        '$rawIdentifier@nachos.com',
      ];
      for (var email in fakeEmails) {
        try {
          final res = await Supabase.instance.client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          if (mounted) _handleSignInSuccess(res);
          return;
        } catch (_) {}
      }

      // 5. Try native phone login for each variation
      for (var phone in variations) {
        try {
          final res = await Supabase.instance.client.auth.signInWithPassword(
            phone: phone,
            password: password,
          );
          if (mounted) _handleSignInSuccess(res);
          return;
        } catch (_) {}
      }

      throw Exception('Maklumat log masuk tidak sah. Sila pastikan e-mel/no. telefon dan kata laluan adalah betul.');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: ${e.toString().replaceAll('Exception: ', '')}'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSignInSuccess(AuthResponse res) {
    final meta = res.session?.user.userMetadata;
    final isStaff = meta?['is_staff'] == true;
    final email = res.session?.user.email ?? '';
    final firstName = meta?['first_name'] ?? email.split('@').first;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AuthSuccessScreen(
          name: firstName,
          isStaff: isStaff,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
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
                        const Center(child: AppLogo(size: 80)),
                        const SizedBox(height: 24),
                        Text(
                          'Selamat Kembali!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sila log masuk ke akaun NACHOZYYY anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildGlassField(
                          controller: _emailController,
                          label: 'Email atau No. Telefon',
                          icon: HugeIcons.strokeRoundedUser,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _passwordController,
                          label: 'Kata Laluan',
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                              );
                            },
                            child: const Text(
                              'Lupa Kata Laluan?',
                              style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
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
                              : const Text('Log Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                              children: const [
                                TextSpan(text: 'Belum ada akaun? '),
                                TextSpan(
                                  text: 'Daftar sekarang!',
                                  style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required dynamic icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
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
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
