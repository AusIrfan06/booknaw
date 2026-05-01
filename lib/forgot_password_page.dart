import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'app_logo.dart';
import 'utils/glass_toast.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _inputController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      showGlassToast(context, 'Sila masukkan e-mel atau no. telefon!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEmail = input.contains('@');
      
      if (isEmail) {
        // For web, we use the current origin. For mobile, we keep the custom scheme
        // but we can also use a site URL if available.
        final String redirectUrl = kIsWeb 
            ? Uri.base.origin 
            : 'io.supabase.booknaw://reset-password/';

        await Supabase.instance.client.auth.resetPasswordForEmail(
          input,
          redirectTo: redirectUrl,
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('E-mel Dihantar', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('Sila semak peti masuk e-mel anda untuk pautan tetapan semula kata laluan.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to login
                  },
                  child: const Text('OK', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } else {
        // Phone logic -> Redirect to Customer's OWN WhatsApp
        final phoneDigits = input.replaceAll(RegExp(r'[^0-9]'), '');
        String cleanPhone = phoneDigits;
        if (cleanPhone.startsWith('60')) {
          cleanPhone = cleanPhone.substring(2);
        } else if (cleanPhone.startsWith('0')) {
          cleanPhone = cleanPhone.substring(1);
        }

        // Variations to search for the user's name
        final variations = ['+60$cleanPhone', '60$cleanPhone', '0$cleanPhone', cleanPhone];
        String customerName = 'Pelanggan';
        
        try {
          final tables = ['users', 'profiles'];
          for (var table in tables) {
            for (var v in variations) {
              final res = await Supabase.instance.client
                  .from(table)
                  .select('full_name')
                  .eq('phone', v)
                  .maybeSingle();
              if (res != null && res['full_name'] != null) {
                customerName = res['full_name'];
                break;
              }
            }
            if (customerName != 'Pelanggan') break;
          }
        } catch (_) {
          // Fallback to generic name if query fails
        }

        final targetPhone = '60$cleanPhone';
        final msg = 'Hai $customerName, sila tetapkan semula kata laluan anda di sini:\n\n'
                    'https://wazeallszgpiasinsjzi.supabase.co/auth/v1/verify?type=recovery&phone=+$targetPhone\n\n'
                    '(Nota: Anda boleh membuka pautan ini dalam pelayar web atau aplikasi BookNaw)';
        
        final waUrl = Uri.parse('https://wa.me/$targetPhone?text=${Uri.encodeComponent(msg)}');
        
        if (await canLaunchUrl(waUrl)) {
          await launchUrl(waUrl, mode: LaunchMode.externalApplication);
        } else {
          throw 'Tidak dapat membuka WhatsApp. Sila hubungi kami secara manual.';
        }
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
            shape: LiquidRoundedSuperellipse(borderRadius: 12.0),
            settings: LiquidGlassSettings(thickness: 0.2, blur: 20),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundGlows(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const AppLogo(size: 80),
                  const SizedBox(height: 32),
                  const Text(
                    'Lupa Kata Laluan?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jangan risau! Masukkan e-mel atau no. telefon anda untuk menetapkan semula kata laluan anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 48),

                  GlassContainer(
                    useOwnLayer: true,
                    quality: GlassQuality.standard,
                    shape: LiquidRoundedSuperellipse(borderRadius: 32.0),
                    settings: LiquidGlassSettings(
                      thickness: 0.1, blur: 15, refractiveIndex: 1.0,
                      glassColor: Colors.transparent, lightAngle: 45.0,
                      lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
                      saturation: 1.0, chromaticAberration: 0.0,
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
                            controller: _inputController,
                            label: 'E-mel atau No. Telefon',
                            icon: HugeIcons.strokeRoundedUser,
                            isDark: isDark,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Hantar Pautan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Kembali ke Log Masuk',
                      style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required dynamic icon,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
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
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: 'Masukkan e-mel atau no. tel',
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
