import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// SHARED UI HELPERS (Support)
// ==========================================
LiquidGlassSettings _getGlassSettings(bool isDark, {double blur = 15.0}) {
  return LiquidGlassSettings(
    thickness: 0.1, blur: blur, refractiveIndex: 1.0, glassColor: Colors.transparent,
    lightAngle: 45.0, lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
    saturation: 1.0, chromaticAberration: 0.0,
  );
}

Widget _buildBackgroundGlows(bool isDark) {
  return Stack(
    children: [
      Positioned(
        top: -50, right: -100,
        child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.08 : 0.15))),
      ),
      Positioned(
        bottom: 100, left: -100,
        child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withValues(alpha: isDark ? 0.06 : 0.12))),
      ),
    ],
  );
}

Future<void> _launchWhatsApp(String phone) async {
  final Uri url = Uri.parse('https://wa.me/$phone');
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch WhatsApp');
  }
}

// ==========================================
// HELP CENTER SCREEN (Combined Hubungi Kami)
// ==========================================
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const themeColor = Color(0xFFFF5722);
    const whatsAppColor = Color(0xFF25D366);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text("Pusat Bantuan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          _buildBackgroundGlows(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pusat Bantuan", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Text("Pasukan kami sedia membantu anda. Sila pilih saluran komunikasi di bawah.", style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 32),

                  _buildContactCard(
                    isDark, 
                    HugeIcons.strokeRoundedWhatsapp, 
                    "WhatsApp Ipan", 
                    "Sembang terus untuk bantuan teknikal & pesanan.", 
                    "Mula sembang sekarang",
                    accentColor: whatsAppColor,
                    onTap: () => _launchWhatsApp('601115892468'),
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    isDark, 
                    HugeIcons.strokeRoundedMail01, 
                    "E-mel Kami", 
                    "Hantarkan sebarang pertanyaan atau cadangan.", 
                    "ausirfan06@gmail.com",
                    accentColor: themeColor,
                    onTap: () async {
                       final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'ausirfan06@gmail.com',
                      );
                      await launchUrl(emailLaunchUri);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    isDark, 
                    HugeIcons.strokeRoundedCall02, 
                    "Talian Bantuan", 
                    "Isnin-Jumaat dari 9 pagi hingga 5 petang.", 
                    "+60 11-1589 2468",
                    accentColor: themeColor,
                    onTap: () async {
                      final Uri telLaunchUri = Uri(
                        scheme: 'tel',
                        path: '+601115892468',
                      );
                      await launchUrl(telLaunchUri);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(bool isDark, dynamic icon, String title, String subtitle, String action, {required Color accentColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 20.0), settings: _getGlassSettings(isDark),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6))),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: HugeIcon(icon: icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                    const SizedBox(height: 8),
                    Text(action, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: accentColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep ContactUsScreen as an alias for compatibility if needed
class ContactUsScreen extends HelpCenterScreen {
  const ContactUsScreen({super.key});
}
