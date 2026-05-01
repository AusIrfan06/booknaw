import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/glass_nav_bar.dart';
import 'widgets/nav_item.dart';
import 'profile_page.dart';
import 'supabase_service.dart';

class BusinessOwnerDashboard extends StatefulWidget {
  const BusinessOwnerDashboard({super.key});

  @override
  State<BusinessOwnerDashboard> createState() => _BusinessOwnerDashboardState();
}

class _BusinessOwnerDashboardState extends State<BusinessOwnerDashboard> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Pusat Perniagaan',
    'Tempahan Saya',
    'Staf Saya',
    'Produk & Servis',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final pages = [
      const _OwnerOverviewTab(),
      const _OwnerOrdersTab(),
      const _OwnerStaffTab(),
      const _OwnerInventoryTab(),
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
                color: Colors.amber.withValues(alpha: isDark ? 0.05 : 0.08),
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
          NavItem(icon: HugeIcons.strokeRoundedStore01, title: 'Bisnes'),
          NavItem(icon: HugeIcons.strokeRoundedTask01, title: 'Order'),
          NavItem(icon: HugeIcons.strokeRoundedUserGroup, title: 'Staf'),
          NavItem(icon: HugeIcons.strokeRoundedPackage, title: 'Produk'),
          NavItem(icon: HugeIcons.strokeRoundedUser, title: 'Profil'),
        ],
      ),
    );
  }
}

// ─── Shared Utilities ────────────────────────────────────────────────────────

LiquidGlassSettings _getOwnerGlassSettings(bool isDark) {
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

class _OwnerOverviewTab extends StatelessWidget {
  const _OwnerOverviewTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.getBusinessInfo(),
      builder: (context, snapshot) {
        final business = snapshot.data;
        final businessName = business?['name'] ?? "Perniagaan Saya";

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBusinessWelcomeBanner(context, isDark, businessName),
              const SizedBox(height: 24),
              const Text(
                "Prestasi Perniagaan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOwnerStatsGrid(isDark),
              const SizedBox(height: 32),
              _buildRecentSalesSection(context, isDark),
            ],
          ),
        );
      }
    );
  }

  Widget _buildBusinessWelcomeBanner(BuildContext context, bool isDark, String businessName) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? "Owner";

    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: _getOwnerGlassSettings(isDark),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF5722).withValues(alpha: isDark ? 0.2 : 0.1),
              Colors.amber.withValues(alpha: isDark ? 0.1 : 0.05),
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
              child: const HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Color(0xFFFF5722), size: 32),
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
                    "$businessName beroperasi seperti biasa hari ini.",
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

  Widget _buildOwnerStatsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard("Jualan Hari Ini", "RM 450", HugeIcons.strokeRoundedWallet01, Colors.green, isDark),
        _buildStatCard("Tempahan Baru", "8", HugeIcons.strokeRoundedShoppingCart01, Colors.blue, isDark),
        _buildStatCard("Stok Rendah", "2", HugeIcons.strokeRoundedAlertCircle, Colors.red, isDark),
        _buildStatCard("Ulasan Baru", "15", HugeIcons.strokeRoundedStar, Colors.amber, isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, dynamic icon, Color color, bool isDark) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
      settings: _getOwnerGlassSettings(isDark),
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
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSalesSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Jualan Terkini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
          settings: _getOwnerGlassSettings(isDark),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFF5722), child: Icon(Icons.receipt_long, color: Colors.white, size: 18)),
                  title: const Text("Order #2930", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Nachos Extra Cheese x2", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Text("RM 24.00", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Orders ──────────────────────────────────────────────────────────

class _OwnerOrdersTab extends StatelessWidget {
  const _OwnerOrdersTab();

  @override
  Widget build(BuildContext context) {
    // Reusing the staff orders tab or something similar
    return const Center(child: Text("Sila urus tempahan di sini."));
  }
}

// ─── Tab 2: Staff Management ────────────────────────────────────────────────

class _OwnerStaffTab extends StatelessWidget {
  const _OwnerStaffTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: 3,
      itemBuilder: (context, index) {
        final staff = ["Ahmad", "Siti", "Chong"];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 16.0), settings: _getOwnerGlassSettings(isDark),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.blue.withValues(alpha: 0.2), child: Text(staff[index][0], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(staff[index], style: const TextStyle(fontWeight: FontWeight.bold)), const Text("Staf Kaunter", style: TextStyle(fontSize: 12, color: Colors.grey))])),
                  const HugeIcon(icon: HugeIcons.strokeRoundedUserEdit01, color: Colors.blue, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab 3: Products & Inventory ───────────────────────────────────────────

class _OwnerInventoryTab extends StatelessWidget {
  const _OwnerInventoryTab();

  @override
  Widget build(BuildContext context) {
    // Reusing existing inventory UI concepts
    return const Center(child: Text("Urus menu dan stok anda di sini."));
  }
}
