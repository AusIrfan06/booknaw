import 'dart:ui' as ui;
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
// HELP CENTER SCREEN
// ==========================================
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});
  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, String>> faqs = [
    {"q": "Apa itu Nachozyyy?", "a": "Nachozyyy adalah aplikasi tempahan makanan yang memudahkan anda mendapatkan hidangan kegemaran dari restoran tempatan terus ke pintu rumah anda."},
    {"q": "Bagaimana cara membuat pesanan?", "a": "Pilih restoran kegemaran anda, tambah hidangan ke dalam troli, pilih kaedah pembayaran, dan sahkan pesanan anda."},
    {"q": "Berapakah caj penghantaran?", "a": "Caj penghantaran bergantung kepada jarak antara restoran dan lokasi anda. Anda boleh melihat caj tersebut sebelum membuat pembayaran."},
    {"q": "Bolehkah saya menjejaki pesanan saya?", "a": "Ya, anda boleh menjejaki status pesanan anda secara 'real-time' melalui tab 'Pesanan Saya'."},
  ];

  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const themeColor = Color(0xFFFF5722);

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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hai,\nApa yang boleh kami bantu?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, height: 1.2)),
                  const SizedBox(height: 24),

                  GlassContainer(
                    useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 16.0), settings: _getGlassSettings(isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6))),
                      child: TextField(
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Cari artikel...", hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.grey, size: 20), border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text("SOALAN LAZIM", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),

                  ...List.generate(faqs.length, (index) {
                    bool isExpanded = expandedIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => expandedIndex = isExpanded ? null : index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: isExpanded ? 0.08 : 0.03) : Colors.white.withValues(alpha: isExpanded ? 0.6 : 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isExpanded ? themeColor : Colors.white.withValues(alpha: isDark ? 0.05 : 0.4), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(faqs[index]["q"]!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87))),
                                Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Text(faqs[index]["a"]!, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, height: 1.5)),
                            ]
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  
                  // Contact Button
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen())),
                      child: const Text("Masih perlukan bantuan? Hubungi Kami", style: TextStyle(color: themeColor, fontWeight: FontWeight.w600)),
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
}

// ==========================================
// CONTACT US SCREEN
// ==========================================
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const themeColor = Color(0xFFFF5722);
    const whatsAppColor = Color(0xFF25D366);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text("Hubungi Kami", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          _buildBackgroundGlows(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hubungi Kami", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Text("Pasukan kami sedia membantu anda.", style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 32),

                  _buildContactCard(
                    isDark, 
                    HugeIcons.strokeRoundedWhatsapp, 
                    "Sembang dengan Ipan di Whatsapp", 
                    "Kami di sini untuk membantu.", 
                    "Mula sembang sekarang",
                    accentColor: whatsAppColor,
                    onTap: () => _launchWhatsApp('601115892468'),
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    isDark, 
                    HugeIcons.strokeRoundedMail01, 
                    "E-mel kami", 
                    "Hubungi kami melalui e-mel bila-bila masa.", 
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
                    "Hubungi kami", 
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
