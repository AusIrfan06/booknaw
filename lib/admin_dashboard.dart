import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/glass_nav_bar.dart';
import 'widgets/nav_item.dart';
import 'profile_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Admin Central',
    'Perniagaan',
    'Pengguna',
    'Laporan',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final pages = [
      const _AdminOverviewTab(),
      const _AdminBusinessTab(),
      const _AdminUsersTab(),
      const _AdminReportsTab(),
      const ProfileSettingsScreen(showAppBar: false),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background blobs for aesthetic
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.05 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: isDark ? 0.05 : 0.08),
              ),
            ),
          ),
          
          IndexedStack(index: _currentIndex, children: pages),
        ],
      ),
      bottomNavigationBar: GlassNavigationBar(
        selectedIndex: _currentIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
        items: const [
          NavItem(icon: HugeIcons.strokeRoundedDashboardSquare01, title: 'Dash'),
          NavItem(icon: HugeIcons.strokeRoundedStore01, title: 'Bisnes'),
          NavItem(icon: HugeIcons.strokeRoundedUserGroup, title: 'User'),
          NavItem(icon: HugeIcons.strokeRoundedAnalytics01, title: 'Report'),
          NavItem(icon: HugeIcons.strokeRoundedUser, title: 'Profil'),
        ],
      ),
    );
  }
}

// ─── Shared Utilities ────────────────────────────────────────────────────────

LiquidGlassSettings _getAdminGlassSettings(bool isDark) {
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

// ─── Tab 0: Overview ─────────────────────────────────────────────────────────

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(context, isDark),
          const SizedBox(height: 24),
          const Text(
            "Statistik Keseluruhan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(isDark),
          const SizedBox(height: 32),
          _buildRecentActivitySection(context, isDark),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, bool isDark) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? "Administrator";

    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: _getAdminGlassSettings(isDark),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF5722).withValues(alpha: isDark ? 0.2 : 0.1),
              Colors.blue.withValues(alpha: isDark ? 0.1 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(icon: HugeIcons.strokeRoundedShield01, color: Color(0xFFFF5722), size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selamat Kembali, $name",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Anda mempunyai 3 permohonan baru yang memerlukan semakan.",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          "Jumlah Bisnes",
          "124",
          HugeIcons.strokeRoundedStore01,
          Colors.orange,
          isDark,
        ),
        _buildStatCard(
          "Pengguna Aktif",
          "1,850",
          HugeIcons.strokeRoundedUserGroup,
          Colors.blue,
          isDark,
        ),
        _buildStatCard(
          "Pendapatan",
          "RM 12.5k",
          HugeIcons.strokeRoundedWallet01,
          Colors.green,
          isDark,
        ),
        _buildStatCard(
          "Tiket Sokongan",
          "12",
          HugeIcons.strokeRoundedCustomerService,
          Colors.purple,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, dynamic icon, Color color, bool isDark) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
      settings: _getAdminGlassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HugeIcon(icon: icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Aktiviti Terkini",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
          settings: _getAdminGlassSettings(isDark),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.6)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                final activities = [
                  {"title": "Permohonan Baru", "desc": "Nasi Lemak Wanjo ingin menyertai platform.", "time": "2 min lepas", "icon": HugeIcons.strokeRoundedAdd01, "color": Colors.green},
                  {"title": "Akaun Dipadam", "desc": "Pengguna ID #8812 telah memadam akaun.", "time": "45 min lepas", "icon": HugeIcons.strokeRoundedDelete02, "color": Colors.red},
                  {"title": "Laporan Teknikal", "desc": "Ralat dikesan pada modul pembayaran.", "time": "2 jam lepas", "icon": HugeIcons.strokeRoundedAlert01, "color": Colors.amber},
                  {"title": "Kemasukan Staf", "desc": "Ahmad telah dilantik sebagai Moderator.", "time": "5 jam lepas", "icon": HugeIcons.strokeRoundedUserAdd01, "color": Colors.blue},
                ];
                final act = activities[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (act['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(icon: act['icon'] as List<List<dynamic>>, color: act['color'] as Color, size: 20),
                  ),
                  title: Text(act['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(act['desc'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Text(act['time'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Business Management ─────────────────────────────────────────────

class _AdminBusinessTab extends StatelessWidget {
  const _AdminBusinessTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: 5,
      itemBuilder: (context, index) {
        final businesses = [
          {"name": "Nachozyyy HQ", "type": "Makanan", "status": "Aktif", "revenue": "RM 5,200"},
          {"name": "Warung Kopi", "type": "Minuman", "status": "Aktif", "revenue": "RM 1,800"},
          {"name": "Spa Sejahtera", "type": "Kesihatan", "status": "Pending", "revenue": "RM 0"},
          {"name": "Kedai Buku Aman", "type": "Runcit", "status": "Aktif", "revenue": "RM 950"},
          {"name": "Maju Motor", "type": "Servis", "status": "Digantung", "revenue": "RM 2,100"},
        ];
        final b = businesses[index];
        Color statusColor = Colors.green;
        if (b['status'] == 'Pending') statusColor = Colors.orange;
        if (b['status'] == 'Digantung') statusColor = Colors.red;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
            settings: _getAdminGlassSettings(isDark),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Color(0xFFFF5722), size: 24)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(b['type']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(b['revenue']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(b['status']!, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab 2: User Management ────────────────────────────────────────────────

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
            settings: _getAdminGlassSettings(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFF5722).withValues(alpha: 0.1),
                    child: const HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Color(0xFFFF5722), size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pengguna #12093", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("user@example.com", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab 3: Reports ────────────────────────────────────────────────────────

class _AdminReportsTab extends StatelessWidget {
  const _AdminReportsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedAnalytics01, color: const Color(0xFFFF5722).withValues(alpha: 0.3), size: 80),
          const SizedBox(height: 24),
          const Text("Laporan Grafik", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Modul laporan sedang dikemaskini.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
