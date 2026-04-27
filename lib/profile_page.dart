import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'main.dart';
import 'contact_page.dart';
import 'help_center_page.dart';
import 'all_reviews_page.dart';
import 'staff_dashboard.dart';
import 'account_details_page.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final bool showAppBar;
  const ProfileSettingsScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null;
    
    // Mock data for UI only
    final name = isLoggedIn ? (user!.userMetadata?['full_name'] ?? "User Name") : "Guest";
    final email = isLoggedIn ? (user!.email ?? "email@example.com") : "Log in to access more features";
    final isStaff = isLoggedIn && (user!.userMetadata?['is_staff'] == true);
    const locationStr = "Shah Alam, Selangor";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Profil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: Navigator.of(context).canPop() ? IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.grey, size: 24),
            onPressed: () => Navigator.pop(context)
        ) : null,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ) : null,
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.05 : 0.1)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withValues(alpha: isDark ? 0.05 : 0.1)))),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Profile Header
                      Center(
                          child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isLoggedIn ? const Color(0xFFFF5722).withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3), width: 2)),
                                  child: CircleAvatar(
                                     radius: 50,
                                     backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                     child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: isDark ? Colors.white70 : Colors.black54, size: 40),
                                   ),
                                 ),
                                 const SizedBox(height: 16),
                                 Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                                 const SizedBox(height: 4),
                                 if (isStaff) ...[
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                     decoration: BoxDecoration(
                                       color: const Color(0xFFFF5722),
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: const Text(
                                       "STAF NACHOZYYY",
                                       style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                     ),
                                   ),
                                   const SizedBox(height: 8),
                                 ],
                                 Text(email, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 14)),
                                const SizedBox(height: 12),

                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          HugeIcon(icon: HugeIcons.strokeRoundedLocation01, color: const Color(0xFFFF5722), size: 14),
                                          SizedBox(width: 4),
                                          Text(locationStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          SizedBox(width: 6),
                                          Icon(Icons.refresh_rounded, color: Colors.grey, size: 12),
                                        ]
                                    )
                                ),
                              ]
                          )
                      ),
                      const SizedBox(height: 32),

                      // Main Content
                      if (!isLoggedIn) ...[
                        _buildGlassButton(isDark, "Log Masuk / Daftar", const Color(0xFFFF5722), () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                        }),
                        const SizedBox(height: 32),
                      ],

                      if (isLoggedIn) ...[
                        _buildSectionHeader("Akaun"),
                        _buildGlassSection(isDark, Column(children: [
                          _buildSettingsTile(isDark, HugeIcons.strokeRoundedUserEdit01, "Butiran Akaun", onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountDetailsPage()));
                          }),
                          _buildDivider(isDark),
                          _buildSettingsTile(isDark, HugeIcons.strokeRoundedUser, "Maklumat Peribadi"),
                          _buildDivider(isDark),
                          _buildSettingsTile(isDark, HugeIcons.strokeRoundedLock, "Privasi & Keselamatan"),
                        ])),
                        const SizedBox(height: 24),

                        const SizedBox(height: 24),
                      ],

                      _buildSectionHeader("Pilihan"),
                      _buildGlassSection(isDark, Column(children: [
                        _buildThemeToggleTile(isDark),
                      ])),
                      const SizedBox(height: 24),

                      _buildSectionHeader("Sokongan"),
                      _buildGlassSection(isDark, Column(children: [
                        _buildSettingsTile(isDark, HugeIcons.strokeRoundedCustomerService, "Pusat Bantuan", onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
                        }),
                        _buildDivider(isDark),
                        _buildSettingsTile(isDark, HugeIcons.strokeRoundedMessageQuestion, "Hubungi Kami", onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactPage()));
                        }),
                      ])),
                      const SizedBox(height: 40),

                      if (isLoggedIn) ...[
                        _buildGlassButton(isDark, "Log Keluar", Colors.redAccent, () async {
                          await Supabase.instance.client.auth.signOut();
                          if (mounted) Navigator.pop(context);
                        }),
                        const SizedBox(height: 40),
                      ],
                      
                      Center(child: Column(children: [const Text("Nachozyyy v0.1.0", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 4), const Text("Dibuat dengan Kasih Sayang", style: TextStyle(color: Colors.grey, fontSize: 10))])),
                      const SizedBox(height: 40),
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

  // UI Helper Widgets
  Widget _buildGlassButton(bool isDark, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.1 : 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.5), width: 1.0)),
          child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildGlassSection(bool isDark, Widget child) {
    return GlassContainer(
      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
      child: Container(
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6), width: 1.0), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 16, offset: const Offset(0, 6))]),
        child: child,
      ),
    );
  }

  LiquidGlassSettings _getGlassSettings(bool isDark) {
    return LiquidGlassSettings(thickness: 0.1, blur: 15, refractiveIndex: 1.0, glassColor: Colors.transparent, lightAngle: 45.0, lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0, saturation: 1.0, chromaticAberration: 0.0);
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2))));

  Widget _buildSettingsTile(bool isDark, dynamic icon, String title, {Widget? trailing, VoidCallback? onTap}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)), child: HugeIcon(icon: icon, color: isDark ? Colors.white : Colors.black87, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            if (trailing != null) trailing,
            const SizedBox(width: 8),
            const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.grey, size: 20)
          ]),
        ),
      ),
  );

  Widget _buildThemeToggleTile(bool isDark) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: NachozyyyApp.themeNotifier,
      builder: (context, currentMode, _) {
        final isDarkNow = currentMode == ThemeMode.dark || 
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
            
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: isDarkNow ? HugeIcons.strokeRoundedMoon02 : HugeIcons.strokeRoundedSun01,
                  color: const Color(0xFFFF5722),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Mod Gelap",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Switch.adaptive(
                value: isDarkNow,
                activeColor: const Color(0xFFFF5722),
                onChanged: (v) {
                  NachozyyyApp.themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleTile(bool isDark, dynamic icon, String title, bool value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)), child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        Switch.adaptive(value: value, activeColor: const Color(0xFFFF5722), onChanged: (v) {})
      ])
  );

  Widget _buildDivider(bool isDark) => Padding(padding: const EdgeInsets.only(left: 60, right: 16), child: Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)));
}
