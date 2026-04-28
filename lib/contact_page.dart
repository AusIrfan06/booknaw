import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launchWhatsApp(String phoneUrl) async {
    final Uri url = Uri.parse('https://$phoneUrl');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
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

  Widget _buildBackgroundGlows(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.08 : 0.15),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: isDark ? 0.06 : 0.12),
            ),
          ),
        ),
      ],
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
        centerTitle: true,
        title: Text(
          "Hubungi Kami",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
                  Text(
                    "Hubungi Kami",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Ada soalan atau nak order manual? WhatsApp kami terus!",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildModernContactCard(
                    isDark: isDark,
                    name: 'Yan',
                    location: 'Alpha',
                    onTap: () => _launchWhatsApp('wa.me/601112769605'),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildModernContactCard(
                    isDark: isDark,
                    name: 'Izzah',
                    location: 'Beta',
                    onTap: () => _launchWhatsApp('wa.me/60102531607'),
                  ),
                  const SizedBox(height: 16),

                  _buildModernContactCard(
                    isDark: isDark,
                    name: 'Lysa',
                    location: 'Beta & Gamma',
                    onTap: () => _launchWhatsApp('wa.me/60132163194'),
                  ),
                  const SizedBox(height: 16),

                  _buildModernContactCard(
                    isDark: isDark,
                    name: 'Alya',
                    location: 'NR',
                    onTap: () => _launchWhatsApp('wa.me/60199973803'),
                  ),
                  const SizedBox(height: 40),

                  GlassContainer(
                    useOwnLayer: true,
                    quality: GlassQuality.standard,
                    shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                    settings: _getGlassSettings(isDark),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Color(0xFFFF5722), size: 40),
                          const SizedBox(height: 16),
                          Text(
                            'Terima kasih kerana menyokong projek ENT300 kami! Kami sangat menghargainya!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildModernContactCard({
    required bool isDark,
    required String name,
    required String location,
    required VoidCallback onTap,
  }) {
    const whatsAppColor = Color(0xFF25D366);
    
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
        settings: _getGlassSettings(isDark),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: whatsAppColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedWhatsapp,
                  color: whatsAppColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Kawasan: $location',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Mula sembang sekarang",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: whatsAppColor,
                      ),
                    ),
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
