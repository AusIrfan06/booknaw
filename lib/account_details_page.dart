import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class AccountDetailsPage extends StatelessWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Sila log masuk.")));
    }

    final name = user.userMetadata?['full_name'] ?? "N/A";
    final email = user.email ?? "N/A";
    final isStaff = user.userMetadata?['is_staff'] == true;
    final createdAt = user.createdAt;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Butiran Akaun",
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
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Profile Avatar Placeholder
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildDetailSection(
                    isDark,
                    "Informasi Peribadi",
                    [
                      _buildDetailTile(isDark, HugeIcons.strokeRoundedUser, "Nama Penuh", name),
                      _buildDetailTile(isDark, HugeIcons.strokeRoundedMail01, "E-mel", email),
                      _buildDetailTile(
                        isDark, 
                        HugeIcons.strokeRoundedUserCircle, 
                        "Peranan", 
                        isStaff ? "Staf Nachozyyy" : "Pelanggan",
                        accentColor: isStaff ? const Color(0xFFFF5722) : Colors.blueAccent,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  _buildDetailSection(
                    isDark,
                    "Keselamatan & Sistem",
                    [
                      _buildDetailTile(
                        isDark, 
                        HugeIcons.strokeRoundedClock01, 
                        "Ahli Sejak", 
                        _formatDate(createdAt),
                      ),
                      _buildDetailTile(
                        isDark, 
                        HugeIcons.strokeRoundedCheckmarkCircle01, 
                        "ID Akaun", 
                        user.id.substring(0, 8).toUpperCase(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  
                  Text(
                    "Butiran ini digunakan untuk pengurusan pesanan dan profil anda. Sila hubungi sokongan jika anda ingin menukar e-mel.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
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

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "N/A";
    }
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

  Widget _buildDetailSection(bool isDark, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
          settings: LiquidGlassSettings(
            thickness: 0.1, blur: 15, refractiveIndex: 1.0,
            glassColor: Colors.transparent, lightAngle: 45.0,
            lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
            saturation: 1.0, chromaticAberration: 0.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
                width: 1.0,
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(bool isDark, dynamic icon, String label, String value, {Color? accentColor}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (accentColor ?? (isDark ? Colors.white : Colors.black)).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(
              icon: icon,
              color: accentColor ?? (isDark ? Colors.white : Colors.black87),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
