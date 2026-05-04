import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'profile_page.dart';
import 'utils/glass_toast.dart';
import 'widgets/glass_nav_bar.dart';
import 'widgets/nav_item.dart';
import 'inventory_management_page.dart';
import 'supabase_service.dart';

// ─── Main Staff Dashboard with Bottom Nav ─────────────────────────────────────

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;


  static const _titles = [
    'Dashboard',
    'Pesanan',
    'Penghantaran',
    'Statistik',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardPage(),
      const _OrdersTab(),
      const _DeliveryTab(),
      const _StatisticsTab(),
      const ProfileSettingsScreen(showAppBar: false),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        automaticallyImplyLeading: false,
      ),
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: GlassNavigationBar(
        selectedIndex: _currentIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
        items: const [
          NavItem(
            icon: HugeIcons.strokeRoundedDashboardSquare01,
            title: 'Dash',
          ),
          NavItem(
            icon: HugeIcons.strokeRoundedTask01,
            title: 'Pesanan',
          ),
          NavItem(
            icon: HugeIcons.strokeRoundedDeliveryTruck01,
            title: 'Hantar',
          ),
          NavItem(
            icon: HugeIcons.strokeRoundedAnalytics01,
            title: 'Stat',
          ),
          NavItem(
            icon: HugeIcons.strokeRoundedUser,
            title: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ─── Data Constants ──────────────────────────────────────────────────────────

const _inventoryLocations = [
  {'id': 1, 'name': 'Alpha'},
  {'id': 2, 'name': 'Beta'},
  {'id': 3, 'name': 'Gamma'},
  {'id': 4, 'name': 'Non Resident (NR)'},
];

// ─── Page 0: Dashboard Overview ───────────────────────────────────────────────

LiquidGlassSettings _getStaffGlassSettings(bool isDark) {
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

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    final name = meta?['full_name'] ?? user?.email?.split('@').first ?? 'Staff';

    final ordersStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    final inventoryStream = Supabase.instance.client
        .from('inventory')
        .stream(primaryKey: ['id']);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.08)))),
          Positioned(bottom: 100, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.08)))),

          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Welcome banner ──────────────────────────────────────────────────
                    GlassContainer(
                      useOwnLayer: true,
                      quality: GlassQuality.standard,
                      shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                      settings: _getStaffGlassSettings(Theme.of(context).brightness == Brightness.dark),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
                              Colors.orange.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedUserCircle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat datang, $name',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black87,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Staff NACHOZYYY',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white70 
                                        : Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Tindakan Pantas',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Urus Inventori',
                            subtitle: 'Tambah & Edit Produk',
                            icon: HugeIcons.strokeRoundedPackage,
                            color: const Color(0xFFFF5722),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const InventoryManagementPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Pusat Bantuan',
                            subtitle: 'Hubungi Sokongan',
                            icon: HugeIcons.strokeRoundedCustomerService,
                            color: Colors.blue,
                            onTap: () {
                              // Link to help or contact
                            },
                          ),
                        ),
                      ],
                    ),
              const Text(
                'Ringkasan Hari Ini',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // ── Stats cards ─────────────────────────────────────────────────────
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: ordersStream,
                builder: (context, snap) {
                  final orders = snap.data ?? [];
                  final pending = orders
                      .where((o) => o['status'] != 'Delivered')
                      .length;
                  final delivered = orders
                      .where((o) => o['status'] == 'Delivered')
                      .length;
                  final paidOrders = orders.where(
                    (o) => o['payment_status'] == 'Paid',
                  );
                  final totalSales = paidOrders.fold<double>(0.0, (sum, o) {
                    final price = o['total_price'];
                    if (price is num) return sum + price.toDouble();
                    if (price is String) {
                      return sum + (double.tryParse(price) ?? 0.0);
                    }
                    return sum;
                  });

                  return GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250,
                      mainAxisExtent: 120, // Increased from 105 to fix overflow
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _StatCard(
                            label: 'Jumlah Pesanan',
                            value: '${orders.length}',
                            icon: HugeIcons.strokeRoundedShoppingCart01,
                            color: const Color(0xFF5C6BC0),
                          );
                        case 1:
                          return _StatCard(
                            label: 'Jualan (RM)',
                            value: totalSales.toStringAsFixed(2),
                            icon: HugeIcons.strokeRoundedWallet01,
                            color: Colors.green,
                          );
                        case 2:
                          return _StatCard(
                            label: 'Belum Hantar',
                            value: '$pending',
                            icon: HugeIcons.strokeRoundedClock01,
                            color: const Color(0xFFE65100),
                          );
                        default:
                          return _StatCard(
                            label: 'Selesai',
                            value: '$delivered',
                            icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                            color: const Color(0xFF2E7D32),
                          );
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 20),
              // ── Stock summary ───────────────────────────────────────────────────
              const Text(
                'Status Stok',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: inventoryStream,
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data!;
                  final hotTotal = data.fold<int>(0, (sum, row) => sum + (row['hot_stock'] as int? ?? 0));
                  final bbqTotal = data.fold<int>(0, (sum, row) => sum + (row['bbq_stock'] as int? ?? 0));
                  final cheeseTotal = data.fold<int>(0, (sum, row) => sum + (row['cheese_stock'] as int? ?? 0));

                  return GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1, // Increased from 2.2 for more height
                    children: [
                      _ModernStockCard(
                        label: 'HOT & SPICYYY',
                        stock: hotTotal,
                        icon: HugeIcons.strokeRoundedFire,
                        color: Colors.redAccent,
                        maxStock: 500,
                        onTap: () => _showStockUpdatePopup(context, 'HOT & SPICYYY', 'hot_stock'),
                      ),
                      _ModernStockCard(
                        label: 'SMOKY BBQ',
                        stock: bbqTotal,
                        icon: HugeIcons.strokeRoundedPackage,
                        color: Colors.orangeAccent,
                        maxStock: 500,
                        onTap: () => _showStockUpdatePopup(context, 'SMOKY BBQ', 'bbq_stock'),
                      ),
                      _ModernStockCard(
                        label: 'CHEESE DIP',
                        stock: cheeseTotal,
                        icon: HugeIcons.strokeRoundedPackage,
                        color: Colors.amber,
                        unit: 'unit',
                        maxStock: 1000,
                        onTap: () => _showStockUpdatePopup(context, 'CHEESE DIP', 'cheese_stock'),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text(
                'Sedia Untuk Penghantaran',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: ordersStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final orders = snap.data ?? [];
                  // Only paid, not yet delivered
                  final readyOrders = orders
                      .where(
                        (o) =>
                            (o['payment_status'] ?? '') == 'Paid' &&
                            (o['status'] ?? '') != 'Delivered',
                      )
                      .toList();

                  if (readyOrders.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tiada pesanan menunggu penghantaran.',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: readyOrders
                        .map((o) => _StaffOrderCard(order: o))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 160), // Further increased for tap clearance
            ],
          ),
        ),
      ),
    ),
  ],
),
);
  }



  void _showStockUpdatePopup(BuildContext context, String flavorLabel, String dbColumn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockPopup(flavorLabel: flavorLabel, dbColumn: dbColumn),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
        settings: _getStaffGlassSettings(isDark),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(icon: icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockPopup extends StatelessWidget {
  final String flavorLabel;
  final String dbColumn;

  const _StockPopup({required this.flavorLabel, required this.dbColumn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inventoryStream = Supabase.instance.client
        .from('inventory')
        .stream(primaryKey: ['id'])
        .order('id');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(
          borderRadius: 32.0,
        ),
        settings: _getStaffGlassSettings(isDark),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const HugeIcon(icon: HugeIcons.strokeRoundedPackage, color: Color(0xFFFF5722), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kemaskini Stok', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          Text(flavorLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: inventoryStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final data = snapshot.data!;
                    
                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(24),
                      itemCount: _inventoryLocations.length,
                      itemBuilder: (context, index) {
                        final loc = _inventoryLocations[index];
                        final row = data.firstWhere((r) => r['id'] == loc['id'], orElse: () => {});
                        final currentStock = row[dbColumn] as int? ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StockUpdateRow(
                            locName: loc['name'] as String,
                            locationId: loc['id'] as int,
                            dbColumn: dbColumn,
                            currentStock: currentStock,
                            currentRow: row,
                            unit: flavorLabel.contains('CHEESE') ? 'unit' : 'pek',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockUpdateRow extends StatelessWidget {
  final String locName;
  final int locationId;
  final String dbColumn;
  final int currentStock;
  final Map<String, dynamic> currentRow;
  final String unit;

  const _StockUpdateRow({
    required this.locName,
    required this.locationId,
    required this.dbColumn,
    required this.currentStock,
    required this.currentRow,
    required this.unit,
  });

  Future<void> _update(int amount) async {
    final newStock = (currentStock + amount).clamp(0, 9999);
    final payload = Map<String, dynamic>.from(currentRow);
    payload['id'] = locationId;
    payload[dbColumn] = newStock;
    await Supabase.instance.client.from('inventory').upsert(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$currentStock $unit', style: TextStyle(color: currentStock < 10 ? Colors.red : Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          _adjustBtn(Icons.remove, () => _update(-1), isDark),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$currentStock',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          _adjustBtn(Icons.add, () => _update(1), isDark),
        ],
      ),
    );
  }

  Widget _adjustBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}



class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 14.0),
      settings: _getStaffGlassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HugeIcon(icon: icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernStockCard extends StatelessWidget {
  final String label;
  final int stock;
  final String unit;
  final dynamic icon;
  final Color color;
  final int maxStock;

  final VoidCallback? onTap;

  const _ModernStockCard({
    required this.label,
    required this.stock,
    this.unit = 'pek',
    required this.icon,
    required this.color,
    required this.maxStock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double percent = (stock / 100).clamp(0.0, 1.0);
    
    Color statusColor;
    String statusText;
    if (stock <= 0) {
      statusColor = Colors.red;
      statusText = 'Habis';
    } else if (stock < 50) {
      statusColor = Colors.orange;
      statusText = 'Rendah';
    } else {
      statusColor = Colors.green;
      statusText = 'Tinggi';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
        settings: _getStaffGlassSettings(isDark),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HugeIcon(icon: icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$stock',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page 1: Pesanan ──────────────────────────────────────────────────────────

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (label: 'Semua', icon: Icons.list_alt_rounded),
    (label: 'Belum Bayar', icon: Icons.hourglass_empty_rounded),
    (label: 'Dibayar', icon: Icons.payments_outlined),
    (label: 'Selesai', icon: Icons.check_circle_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> orders, int i) {
    switch (i) {
      case 1:
        return orders
            .where((o) => (o['payment_status'] ?? 'Pending Payment') != 'Paid')
            .toList();
      case 2:
        return orders
            .where(
              (o) =>
                  (o['payment_status'] ?? '') == 'Paid' &&
                  (o['status'] ?? '') != 'Delivered',
            )
            .toList();
      case 3:
        return orders.where((o) => (o['status'] ?? '') == 'Delivered').toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Belum Bayar'),
              Tab(text: 'Diproses'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HugeIcon(
                              icon: HugeIcons.strokeRoundedAlertCircle,
                              color: Colors.red,
                              size: 48),
                          const SizedBox(height: 16),
                          Text('Ralat: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                }
                final allOrders = snapshot.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabs.length, (i) {
                    final filtered = _filter(allOrders, i);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tiada pesanan "${_tabs[i].label}"',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) =>
                          _StaffOrderCard(order: filtered[idx]),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _StaffOrderCard({required this.order});

  Future<void> _markPaid(BuildContext context) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'payment_status': 'Paid'})
          .eq('id', order['id']);

      // Deduct inventory
      final opt = order['delivery_option'] as String? ?? '';
      int locationId = 1; // Default to Alpha
      if (opt.contains('Alpha')) {
        locationId = 1;
      } else if (opt.contains('Beta')) {
        locationId = 2;
      } else if (opt.contains('Gamma')) {
        locationId = 3;
      } else if (opt.contains('NR')) {
        locationId = 4;
      }

      final hotQty = order['hot_quantity_100g'] as int? ?? 0;
      final bbqQty = order['bbq_quantity_100g'] as int? ?? 0;
      final cheeseQty = order['cheese_quantity'] as int? ?? 0;

      if (hotQty > 0 || bbqQty > 0 || cheeseQty > 0) {
        final invRes = await Supabase.instance.client
            .from('inventory')
            .select()
            .eq('id', locationId)
            .maybeSingle();

        if (invRes != null) {
          final currentHot = invRes['hot_stock'] as int? ?? 0;
          final currentBbq = invRes['bbq_stock'] as int? ?? 0;
          final currentCheese = invRes['cheese_stock'] as int? ?? 0;

          final newHot = currentHot - hotQty;
          final newBbq = currentBbq - bbqQty;
          final newCheese = currentCheese - cheeseQty;

          await Supabase.instance.client
              .from('inventory')
              .update({
                'hot_stock': newHot < 0 ? 0 : newHot,
                'bbq_stock': newBbq < 0 ? 0 : newBbq,
                'cheese_stock': newCheese < 0 ? 0 : newCheese,
              })
              .eq('id', locationId);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showGlassToast(context, e.toString(), isError: true);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final hotQty = order['hot_quantity_100g'] as int? ?? 0;
    final bbqQty = order['bbq_quantity_100g'] as int? ?? 0;
    final cheeseQty = order['cheese_quantity'] as int? ?? 0;
    final totalPrice = order['total_price'] ?? 0;
    final customerName = order['customer_name'] ?? 'Unknown';
    final phone = order['phone_number'] ?? 'Unknown';
    final delivery = order['delivery_option'] ?? 'Unknown';
    final status = order['status'] ?? 'Pending';
    final paymentStatus = order['payment_status'] ?? 'Pending Payment';
    final isPaid = paymentStatus == 'Paid';
    final isDelivered = status == 'Delivered';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 12.0),
      settings: _getStaffGlassSettings(isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDelivered
              ? (isDark
                  ? Colors.green.shade900.withValues(alpha: 0.3)
                  : Colors.green.shade50.withValues(alpha: 0.5))
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDelivered 
              ? Colors.green.withValues(alpha: 0.3) 
              : Colors.white.withValues(alpha: isDark ? 0.1 : 0.5)
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDelivered ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(phone, style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('tel:${phone.replaceAll(RegExp(r'\D'), '')}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.phone_rounded, color: Colors.blue, size: 20),
                    tooltip: 'Call',
                  ),
                  IconButton(
                    onPressed: () async {
                      String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                      if (cleanPhone.startsWith('0')) cleanPhone = '6$cleanPhone';
                      final Uri url = Uri.parse('https://wa.me/$cleanPhone');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedWhatsapp, color: Color(0xFF25D366), size: 20),
                    tooltip: 'WhatsApp',
                  ),
                ],
              ),
              const Divider(),
              if (hotQty > 0) Text('- HOT & SPICYYY x$hotQty'),
              if (bbqQty > 0) Text('- BBQ x$bbqQty'),
              if (cheeseQty > 0) Text('- Cheese Dip x$cheeseQty'),
              const SizedBox(height: 8),
              Text(
                'Lokasi: $delivery',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Total: RM ${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              // Payment status row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? (isDelivered ? 'Telah Bayar' : 'Dibayar') : 'Belum Bayar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isPaid) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markPaid(context),
                    icon: const Icon(
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Tandakan Dibayar',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
// ─── Page 2: Penghantaran ───────────────────────────────────────────────────

class _DeliveryTab extends StatelessWidget {
  const _DeliveryTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Alpha'),
                Tab(text: 'Beta'),
                Tab(text: 'Gamma'),
                Tab(text: 'Non Resident (NR)'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('orders')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snap.data ?? [];
                final activeOrders = orders.where((o) =>
                    (o['payment_status'] ?? '') == 'Paid' &&
                    (o['status'] ?? '') != 'Delivered').toList();

                return TabBarView(
                  children: [
                    _DeliveryList(orders: activeOrders, zone: 'Alpha'),
                    _DeliveryList(orders: activeOrders, zone: 'Beta'),
                    _DeliveryList(orders: activeOrders, zone: 'Gamma'),
                    _DeliveryList(orders: activeOrders, zone: 'NR'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String zone;

  const _DeliveryList({required this.orders, required this.zone});

  @override
  Widget build(BuildContext context) {
    final deliveries = orders.where((o) {
      final opt = (o['delivery_option'] as String? ?? '');
      return opt.contains(zone);
    }).toList();

    if (deliveries.isEmpty) {
      return Center(
        child: Text('Tiada pesanan untuk zon $zone.',
            style: const TextStyle(fontSize: 15, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deliveries.length,
      itemBuilder: (context, i) => _DeliveryOrderCard(order: deliveries[i]),
    );
  }
}

class _DeliveryOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _DeliveryOrderCard({required this.order});

  Future<void> _updateStatusAndWhatsApp(BuildContext context, String newStatus) async {
    final isDelivered = newStatus == 'Delivered';
    final title = isDelivered ? 'Sahkan Penghantaran Selesai' : 'Mula Penghantaran';
    final content = isDelivered
        ? 'Selesai pesanan ini dan hantar mesej WhatsApp bukti penghantaran?'
        : 'Tukar status ke "Sedang Dihantar" dan hantar WhatsApp kepada pelanggan?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDelivered ? const Color(0xFF25D366) : Colors.orange,
            ),
            child: const Text('Ya, Teruskan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', order['id']);

      String phone = order['phone_number'] ?? '';
      if (phone.startsWith('0')) phone = '6$phone';
      phone = phone.replaceAll(RegExp(r'\D'), '');

      final name = order['customer_name'] ?? 'Pelanggan';
      final orderId = order['id'];
      
      final msg = isDelivered
          ? 'Hi $name\n\nKami dari NACHOZYYY\nPesanan anda (No. #$orderId) telah selamat dihantar!\n\nTerima kasih kerana menyokong kami. (Gambar bukti penghantaran disertakan di bawah)'
          : 'Hi $name\n\nKami dari NACHOZYYY\nPesanan anda (No. #$orderId) sedang dihantar ke lokasi anda!\n\nSila bersedia untuk menerima pesanan anda sebentar lagi.';

      final waMessage = Uri.encodeComponent(msg);
      final waUrl = Uri.parse('https://wa.me/$phone?text=$waMessage');
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        showGlassToast(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _markAsDelivered(BuildContext context) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'Delivered'})
          .eq('id', order['id']);
      
      if (context.mounted) {
        showGlassToast(context, 'Pesanan telah ditanda sebagai Selesai.');
      }
    } catch (e) {
      if (context.mounted) {
        showGlassToast(context, e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotQty = order['hot_quantity_100g'] as int? ?? 0;
    final bbqQty = order['bbq_quantity_100g'] as int? ?? 0;
    final addCheese = order['add_cheese_dip'] as bool? ?? false;
    final customerName = order['customer_name'] ?? 'Unknown';
    final phone = order['phone_number'] ?? 'Unknown';
    final delivery = order['delivery_option'] ?? 'Unknown';
    final address = order['delivery_address'] as String?;
    final status = order['status'] ?? 'Pending';
    final isOutForDelivery = status == 'Out for Delivery';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.delivery_dining,
                  color: Colors.deepOrange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(phone, style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    final Uri url = Uri.parse('tel:${phone.replaceAll(RegExp(r'\D'), '')}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  icon: const Icon(Icons.phone_rounded, color: Colors.blue, size: 20),
                  tooltip: 'Call',
                ),
                IconButton(
                  onPressed: () async {
                    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                    if (cleanPhone.startsWith('0')) cleanPhone = '6$cleanPhone';
                    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedWhatsapp, color: Color(0xFF25D366), size: 20),
                  tooltip: 'WhatsApp',
                ),
              ],
            ),
            const Divider(),
            if (hotQty > 0) Text('- HOT & SPICYYY x$hotQty'),
            if (bbqQty > 0) Text('- BBQ x$bbqQty'),
            if (addCheese) const Text('- Cheese Dip'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (address != null && address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(address),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (delivery.toLowerCase().contains('pickup'))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsDelivered(context),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Telah Diambil (Mark as Delivered)',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else if (!isOutForDelivery)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatusAndWhatsApp(context, 'Out for Delivery'),
                  icon: const Icon(Icons.two_wheeler, color: Colors.white),
                  label: const Text(
                    'Mula Penghantaran (WhatsApp)',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatusAndWhatsApp(context, 'Delivered'),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Selesai & Hantar Gambar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsTab extends StatelessWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context) {
    final ordersStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Statistics Calculations
        final paidOrders = orders.where((o) => o['payment_status'] == 'Paid').toList();
        final totalSales = paidOrders.fold<double>(0.0, (sum, o) => sum + (double.tryParse(o['total_price'].toString()) ?? 0.0));
        
        final hotTotal = paidOrders.fold<int>(0, (sum, o) => sum + (int.tryParse(o['hot_quantity_100g']?.toString() ?? '0') ?? 0));
        final bbqTotal = paidOrders.fold<int>(0, (sum, o) => sum + (int.tryParse(o['bbq_quantity_100g']?.toString() ?? '0') ?? 0));
        final cheeseTotal = paidOrders.fold<int>(0, (sum, o) => sum + (int.tryParse(o['cheese_quantity']?.toString() ?? '0') ?? 0));

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryGrid(context, totalSales, paidOrders.length, orders.length, isDark),
                  const SizedBox(height: 20),
                  
                  const Text('Analisis Jualan Harian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDailySalesChart(context, paidOrders, isDark),
                  
                  const SizedBox(height: 24),
                  const Text('Analisis Jualan Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildProductChart(context, hotTotal, bbqTotal, cheeseTotal, isDark),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transaksi Terkini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                           // Future: Show dialog to add expense
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Fungsi tambah belanja akan datang.'))
                           );
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.red),
                        label: const Text('Tambah Belanja', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionList(context, orders, isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryGrid(BuildContext context, double sales, int paidCount, int totalCount, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisExtent: 120,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildStatCard('Jumlah Jualan', 'RM ${sales.toStringAsFixed(2)}', HugeIcons.strokeRoundedWallet01, Colors.green, isDark);
          case 1:
            return _buildStatCard('Pesanan Dibayar', '$paidCount', HugeIcons.strokeRoundedCheckmarkCircle01, Colors.blue, isDark);
          default:
            return _buildStatCard('Semua Pesanan', '$totalCount', HugeIcons.strokeRoundedShoppingCart01, Colors.orange, isDark);
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, dynamic icon, Color color, bool isDark) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 14.0),
      settings: _getStaffGlassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HugeIcon(icon: icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySalesChart(BuildContext context, List<Map<String, dynamic>> paidOrders, bool isDark) {
    // Calculate daily data and store orders for popups
    final Map<String, double> dailyData = {};
    final Map<String, List<Map<String, dynamic>>> dailyOrders = {};
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = "${date.day}/${date.month}";
      dailyData[key] = 0.0;
      dailyOrders[key] = [];
    }

    for (var o in paidOrders) {
      final date = DateTime.tryParse(o['created_at'].toString()) ?? DateTime.now();
      final key = "${date.day}/${date.month}";
      if (dailyData.containsKey(key)) {
        dailyData[key] = dailyData[key]! + (double.tryParse(o['total_price'].toString()) ?? 0.0);
        dailyOrders[key]!.add(o);
      }
    }

    final sortedKeys = dailyData.keys.toList().reversed.toList();
    final maxVal = dailyData.values.isEmpty ? 1.0 : dailyData.values.reduce((a, b) => a > b ? a : b);
    final scale = maxVal == 0 ? 1.0 : maxVal;

    return GlassContainer(
      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: _getStaffGlassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prestasi Jualan 7 Hari', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Max: RM ${maxVal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sortedKeys.map((key) {
                  final val = dailyData[key]!;
                  final orders = dailyOrders[key]!;
                  final percent = val / scale;
                  
                  return InkWell(
                    onTap: () => _showDaySummary(context, key, orders, isDark),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 25,
                            height: (100 * percent).clamp(5.0, 100.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.green.shade700, Colors.green.shade300],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                if (percent > 0.1)
                                  BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(key, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDaySummary(BuildContext context, String day, List<Map<String, dynamic>> orders, bool isDark) {
    int hot = 0;
    int bbq = 0;
    int cheese = 0;
    double total = 0;
    for (var o in orders) {
      hot += (o['hot_quantity_100g'] as num? ?? 0).toInt();
      bbq += (o['bbq_quantity_100g'] as num? ?? 0).toInt();
      cheese += (o['cheese_quantity'] as num? ?? 0).toInt();
      total += double.tryParse(o['total_price'].toString()) ?? 0.0;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 32.0),
        settings: _getStaffGlassSettings(isDark),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Ringkasan Jualan ($day)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _summaryRow('HOT & SPICYYY', '$hot unit', Colors.redAccent),
              _summaryRow('SMOKY BBQ', '$bbq unit', Colors.orangeAccent),
              _summaryRow('CHEESE DIP', '$cheese unit', Colors.amber),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah Pendapatan', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('RM ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProductChart(BuildContext context, int hot, int bbq, int cheese, bool isDark) {
    final maxVal = [hot, bbq, cheese].reduce((a, b) => a > b ? a : b);
    final scale = maxVal == 0 ? 1.0 : maxVal.toDouble();

    return GlassContainer(
      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: _getStaffGlassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            _buildBar('HOT & SPICYYY', hot, scale, Colors.redAccent, isDark),
            const SizedBox(height: 20),
            _buildBar('SMOKY BBQ', bbq, scale, Colors.orangeAccent, isDark),
            const SizedBox(height: 20),
            _buildBar('CHEESE DIP', cheese, scale, Colors.amber, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, int value, double max, Color color, bool isDark) {
    final percent = value / max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('$value unit', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.01, 1.0),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionList(BuildContext context, List<Map<String, dynamic>> orders, bool isDark) {
    return Column(
      children: [
        GlassContainer(
          useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
          settings: _getStaffGlassSettings(isDark),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length > 7 ? 7 : orders.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 64),
              itemBuilder: (context, index) {
                final o = orders[index];
                final price = double.tryParse(o['total_price'].toString()) ?? 0.0;
                final date = DateTime.tryParse(o['created_at'].toString()) ?? DateTime.now();
                final isPaid = o['payment_status'] == 'Paid';
                
                final isOut = o['type'] == 'Expense'; 
                final itemColor = isOut ? Colors.red : (isPaid ? Colors.green : Colors.orange);
                final itemIcon = isOut ? HugeIcons.strokeRoundedArrowUpRight01 : (isPaid ? HugeIcons.strokeRoundedArrowDownLeft01 : HugeIcons.strokeRoundedClock01);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: HugeIcon(icon: itemIcon, color: itemColor, size: 20),
                  ),
                  title: Text(o['customer_name'] ?? 'Transaksi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text('${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${isOut ? "-" : "+"} RM ${price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: itemColor)),
                      Text(isOut ? "Belanja" : (o['payment_status'] ?? 'Pending'), style: TextStyle(fontSize: 10, color: itemColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (orders.length > 7)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => _AllTransactionsPage(orders: orders)),
                );
              },
              icon: const Text('Lihat Semua Transaksi', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
              label: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

class _AllTransactionsPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const _AllTransactionsPage({required this.orders});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Transaksi'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassContainer(
          useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
          settings: _getStaffGlassSettings(isDark),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 64),
              itemBuilder: (context, index) {
                final o = orders[index];
                final price = double.tryParse(o['total_price'].toString()) ?? 0.0;
                final date = DateTime.tryParse(o['created_at'].toString()) ?? DateTime.now();
                final isPaid = o['payment_status'] == 'Paid';
                final isOut = o['type'] == 'Expense';
                final itemColor = isOut ? Colors.red : (isPaid ? Colors.green : Colors.orange);
                final itemIcon = isOut ? HugeIcons.strokeRoundedArrowUpRight01 : (isPaid ? HugeIcons.strokeRoundedArrowDownLeft01 : HugeIcons.strokeRoundedClock01);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: HugeIcon(icon: itemIcon, color: itemColor, size: 20),
                  ),
                  title: Text(o['customer_name'] ?? 'Transaksi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text('${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${isOut ? "-" : "+"} RM ${price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: itemColor)),
                      Text(isOut ? "Belanja" : (o['payment_status'] ?? 'Pending'), style: TextStyle(fontSize: 10, color: itemColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
