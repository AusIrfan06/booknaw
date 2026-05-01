import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'staff_dashboard.dart';
import 'admin_dashboard.dart';
import 'guest_signup_page.dart';
import 'forgot_password_page.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'utils/glass_toast.dart';

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
        // If it's an email format, or it's not an 'invalid credentials' error, rethrow
        if (rawIdentifier.contains('@') || !e.toString().contains('invalid_credentials')) {
          rethrow;
        }
      }

      // 2. Prepare phone variations
      // Clean identifier to digits only for phone matching
      String digitsOnly = rawIdentifier.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isEmpty) {
        throw Exception('Maklumat log masuk tidak sah.');
      }

      String cleanPhone = digitsOnly;
      if (cleanPhone.startsWith('60')) {
        cleanPhone = cleanPhone.substring(2);
      } else if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }

      final variations = [
        '+60$cleanPhone', // Standard: +6011...
        '60$cleanPhone',  // 6011...
        '0$cleanPhone',   // 011...
        cleanPhone,       // 11...
      ];

      // 3. Try searching in public.users and public.profiles for each variation
      final tables = ['users', 'profiles'];
      for (var table in tables) {
        for (var phone in variations) {
          try {
            final profileData = await Supabase.instance.client
                .from(table)
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
      }

      // 4. Try fake email formats (used by some implementations)
      final fakeEmails = [
        '$cleanPhone@nachos.com',
        '0$cleanPhone@nachos.com',
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
        showGlassToast(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _handleSignInSuccess(AuthResponse res) {
    final user = res.session?.user;
    final meta = user?.userMetadata;
    final role = meta?['role'] ?? 'customer';

    if (role == 'admin') {
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminDashboard()), (route) => false);
      }
      return;
    }

    if (role == 'staff') {
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const StaffDashboard()), (route) => false);
      }
      return;
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
          // Background glows
          _buildBackgroundGlows(isDark),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    children: [
                  const SizedBox(height: 40),
                  const SizedBox(height: 24),
                  const Text(
                    'Log Masuk',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sila log masuk untuk teruskan pesanan anda.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Form with Glassmorphism
                  GlassContainer(
                    useOwnLayer: true,
                    quality: GlassQuality.standard,
                    shape: LiquidRoundedSuperellipse(borderRadius: 32.0),
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
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: 'E-mel atau No. Telefon',
                            icon: HugeIcons.strokeRoundedMail01,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Kata Laluan',
                            icon: HugeIcons.strokeRoundedLock,
                            isDark: isDark,
                            isPassword: true,
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
                                style: TextStyle(color: Color(0xFFFF5722), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Login Button
                          _buildFrostedButton(
                            label: 'Log Masuk',
                            onTap: _signIn,
                            isPrimary: true,
                            isLoading: _isLoading,
                            isDark: isDark,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Register Button
                          _buildFrostedButton(
                            label: 'Daftar Sekarang',
                            icon: HugeIcons.strokeRoundedUserAdd01,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignupPage()),
                              );
                            },
                            isDark: isDark,
                          ),

                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("ATAU", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Guest Login Button
                          _buildFrostedButton(
                            label: 'Log Masuk sebagai Tetamu',
                            icon: HugeIcons.strokeRoundedUserCircle,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GuestSignupPage()),
                              );
                            },
                            isDark: isDark,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required dynamic icon,
    required bool isDark,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: 'Masukkan ${label.toLowerCase()}',
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundGlows(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.05 : 0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: isDark ? 0.03 : 0.08),
            ),
          ),
        ),
      ],
    );
  }
}
