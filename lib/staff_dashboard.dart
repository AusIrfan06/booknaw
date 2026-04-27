import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'home_page.dart';

// ─── Main Staff Dashboard with Bottom Nav ─────────────────────────────────────

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  }

  static const _titles = [
    'Dashboard',
    'Pesanan',
    'Penghantaran',
    'Stok Inventori',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardPage(),
      const _OrdersTab(),
      const _DeliveryTab(),
      const _InventoryTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => _logout(context),
            tooltip: 'Log Keluar',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDashboardSquare01,
              color: Colors.grey,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedDashboardSquare01,
              color: Color(0xFFFF5722),
              size: 24,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedTask01,
              color: Colors.grey,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedTask01,
              color: Color(0xFFFF5722),
              size: 24,
            ),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDeliveryTruck01,
              color: Colors.grey,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedDeliveryTruck01,
              color: Color(0xFFFF5722),
              size: 24,
            ),
            label: 'Hantar',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPackage,
              color: Colors.grey,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedPackage,
              color: Color(0xFFFF5722),
              size: 24,
            ),
            label: 'Stok',
          ),
        ],
      ),
    );
  }
}

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
    final email = user?.email ?? 'Staff';
    final name = email.split('@').first;

    final ordersStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    final inventoryStream = Supabase.instance.client
        .from('inventory')
        .stream(primaryKey: ['id']);

    return SingleChildScrollView(
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
                shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
                settings: _getStaffGlassSettings(Theme.of(context).brightness == Brightness.dark),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(
                      Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    ),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedUserCircle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat datang, $name',
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
                'Ringkasan Hari Ini',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

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
                    if (price is String)
                      return sum + (double.tryParse(price) ?? 0.0);
                    return sum;
                  });

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250,
                      mainAxisExtent: 110,
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

              const SizedBox(height: 24),

              // ── Stock summary ───────────────────────────────────────────────────
              const Text(
                'Status Stok',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

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
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _ModernStockCard(
                        label: 'HOT & SPICYYY',
                        stock: hotTotal,
                        icon: HugeIcons.strokeRoundedFire,
                        color: Colors.redAccent,
                        maxStock: 500,
                      ),
                      _ModernStockCard(
                        label: 'SMOKY BBQ',
                        stock: bbqTotal,
                        icon: HugeIcons.strokeRoundedPackage,
                        color: Colors.orangeAccent,
                        maxStock: 500,
                      ),
                      _ModernStockCard(
                        label: 'CHEESE DIP',
                        stock: cheeseTotal,
                        icon: HugeIcons.strokeRoundedPackage,
                        color: Colors.amber,
                        unit: 'unit',
                        maxStock: 1000,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Password Reset Helper ───────────────────────────────────────────
              const _PasswordResetHelper(),

              const SizedBox(height: 24),

              const Text(
                'Sedia Untuk Penghantaran',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordResetHelper extends StatefulWidget {
  const _PasswordResetHelper();

  @override
  State<_PasswordResetHelper> createState() => _PasswordResetHelperState();
}

class _PasswordResetHelperState extends State<_PasswordResetHelper> {
  final _phoneController = TextEditingController();
  String _foundEmail = '';

  void _lookupUser() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() {
      _foundEmail = '$phone@nachos.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedLockPassword,
                  color: Colors.blueGrey,
                  size: 24),
              SizedBox(width: 10),
              Text(
                'Bantuan Reset Kata Laluan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Untuk pengguna No. Telefon, staff perlu reset secara manual di Supabase Dashboard.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              hintText: 'Masukkan No. Tel Pelanggan...',
              prefixIcon: const Icon(Icons.phone_iphone, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _lookupUser,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.phone,
          ),
          if (_foundEmail.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Login ID Pelanggan:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(_foundEmail,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  const SizedBox(height: 12),
                  const Text(
                    'Langkah Seterusnya:\n1. Buka Supabase Dashboard\n2. Cari ID di atas dalam menu "Authentication"\n3. Klik "Edit User" -> "Change Password"',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
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
              ? color.withOpacity(0.15)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
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

  const _ModernStockCard({
    required this.label,
    required this.stock,
    this.unit = 'pek',
    required this.icon,
    required this.color,
    required this.maxStock,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double percent = (stock / maxStock).clamp(0.0, 1.0);
    
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

    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
      settings: _getStaffGlassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
                    color: color.withOpacity(0.15),
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
                          color: statusColor.withOpacity(0.15),
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
        // ── Tab bar ────────────────────────────────────────────────────────
        Container(
          color: Theme.of(context).colorScheme.primary,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: _tabs
                .map(
                  (t) => Tab(
                    child: Row(
                      children: [
                        Icon(t.icon, size: 16),
                        const SizedBox(width: 6),
                        Text(t.label),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Ralat: ${snapshot.error}'));
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
      if (opt.contains('Alpha')) locationId = 1;
      else if (opt.contains('Beta')) locationId = 2;
      else if (opt.contains('Gamma')) locationId = 3;
      else if (opt.contains('NR')) locationId = 4;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markDelivered(BuildContext context) async {
    try {
      await _tryUpdateStatus();
    } catch (e) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        await _tryUpdateStatus();
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tiada Internet! Sila semak sambungan anda.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _tryUpdateStatus() async {
    await Supabase.instance.client
        .from('orders')
        .update({'status': 'Delivered'})
        .eq('id', order['id']);
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
                  ? Colors.green.shade900.withOpacity(0.3)
                  : Colors.green.shade50.withOpacity(0.5))
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDelivered 
              ? Colors.green.withOpacity(0.3) 
              : Colors.white.withOpacity(isDark ? 0.1 : 0.5)
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
              Text(phone, style: const TextStyle(color: Colors.grey)),
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
                      isPaid ? 'Dibayar' : 'Belum Bayar',
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
              if (!isDelivered) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _markDelivered(context),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      color: Colors.green,
                      size: 20,
                    ),
                    label: const Text(
                      'Mark as Delivered',
                      style: TextStyle(color: Colors.green),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat: $e'), backgroundColor: Colors.red),
        );
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
            Text(phone, style: const TextStyle(color: Colors.grey)),
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
            if (!isOutForDelivery)
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

// ─── Page 3: Stok Inventori ───────────────────────────────────────────────────

const _inventoryLocations = [
  {'id': 1, 'name': 'Alpha'},
  {'id': 2, 'name': 'Beta'},
  {'id': 3, 'name': 'Gamma'},
  {'id': 4, 'name': 'Non Resident (NR)'},
];

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    final inventoryStream = Supabase.instance.client
        .from('inventory')
        .stream(primaryKey: ['id'])
        .order('id');

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: inventoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? [];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Calculate Totals
        int totalHot = data.fold<int>(0, (sum, r) => sum + (r['hot_stock'] as int? ?? 0));
        int totalBBQ = data.fold<int>(0, (sum, r) => sum + (r['bbq_stock'] as int? ?? 0));
        int totalCheese = data.fold<int>(0, (sum, r) => sum + (r['cheese_stock'] as int? ?? 0));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── TOTAL STOCK SECTION ─────────────────────────────────────
                  const Text(
                    'Ringkasan Keseluruhan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    useOwnLayer: true,
                    quality: GlassQuality.standard,
                    shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                    settings: _getStaffGlassSettings(isDark),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTotalStat(context, 'HOT', totalHot, Colors.redAccent),
                          _buildTotalStat(context, 'BBQ', totalBBQ, Colors.orangeAccent),
                          _buildTotalStat(context, 'CHEESE', totalCheese, Colors.amber),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── BY STORE SECTION ────────────────────────────────────────
                  const Text(
                    'Pecahan Mengikut Stor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._inventoryLocations.map((loc) {
                    final row = data.firstWhere(
                      (r) => r['id'] == loc['id'],
                      orElse: () => <String, dynamic>{},
                    );
                    final hotStock = row['hot_stock'] as int? ?? 0;
                    final bbqStock = row['bbq_stock'] as int? ?? 0;
                    final cheeseStock = row['cheese_stock'] as int? ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFFFF5722)),
                                const SizedBox(width: 8),
                                Text(
                                  'Cawangan: ${loc['name']}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                          _StockUpdater(
                            locationId: loc['id'] as int,
                            flavor: 'HOT & SPICYYY',
                            dbColumn: 'hot_stock',
                            currentStock: hotStock,
                            currentRow: row,
                          ),
                          const SizedBox(height: 12),
                          _StockUpdater(
                            locationId: loc['id'] as int,
                            flavor: 'BBQ',
                            dbColumn: 'bbq_stock',
                            currentStock: bbqStock,
                            currentRow: row,
                          ),
                          const SizedBox(height: 12),
                          _StockUpdater(
                            locationId: loc['id'] as int,
                            flavor: 'Cheese Dip',
                            dbColumn: 'cheese_stock',
                            currentStock: cheeseStock,
                            currentRow: row,
                            unit: 'unit',
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalStat(BuildContext context, String label, int value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}

class _StockUpdater extends StatefulWidget {
  final int locationId;
  final String flavor;
  final String dbColumn;
  final int currentStock;
  final Map<String, dynamic> currentRow;
  final String unit;

  const _StockUpdater({
    required this.locationId,
    required this.flavor,
    required this.dbColumn,
    required this.currentStock,
    required this.currentRow,
    this.unit = 'pek',
    super.key,
  });

  @override
  State<_StockUpdater> createState() => _StockUpdaterState();
}

class _StockUpdaterState extends State<_StockUpdater> {
  final _manualController = TextEditingController();
  Timer? _debounce;

  Future<void> _adjustStock(int amount) async {
    try {
      final newStock = widget.currentStock + amount;
      final payload = {
        'id': widget.locationId,
        'hot_stock': widget.currentRow['hot_stock'] ?? 0,
        'bbq_stock': widget.currentRow['bbq_stock'] ?? 0,
        'cheese_stock': widget.currentRow['cheese_stock'] ?? 0,
      };
      payload[widget.dbColumn] = newStock < 0 ? 0 : newStock;

      await Supabase.instance.client.from('inventory').upsert(payload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ralat: $e')));
      }
    }
  }

  Future<void> _setManualStock(String value) async {
    final newStock = int.tryParse(value);
    if (newStock == null) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final payload = {
          'id': widget.locationId,
          'hot_stock': widget.currentRow['hot_stock'] ?? 0,
          'bbq_stock': widget.currentRow['bbq_stock'] ?? 0,
          'cheese_stock': widget.currentRow['cheese_stock'] ?? 0,
        };
        payload[widget.dbColumn] = newStock < 0 ? 0 : newStock;

        await Supabase.instance.client.from('inventory').upsert(payload);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ralat: $e')));
        }
      }
    });
  }

  void _showManualInput() {
    _manualController.text = widget.currentStock.toString();
    _manualController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _manualController.text.length,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set Stok: ${widget.flavor}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Jumlah stok',
                border: OutlineInputBorder(),
                suffix: Text(widget.unit),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final val = _manualController.text;
                Navigator.pop(ctx);
                await _setManualStock(val);
              },
              child: const Text('Simpan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _manualController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSoldOut = widget.currentStock <= 0;
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isSoldOut ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.flavor,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSoldOut)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SOLD OUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _CounterButton(
                  icon: HugeIcons.strokeRoundedMinusSign,
                  buttonColor: Colors.orange,
                  onPressed: widget.currentStock > 0
                      ? () => _adjustStock(-1)
                      : null,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showManualInput,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: primary, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: primary.withValues(alpha: 0.05),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${widget.currentStock}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isSoldOut ? Colors.red : primary,
                            ),
                          ),
                          Text(
                            '${widget.unit}  •  ketuk untuk edit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _CounterButton(
                  icon: HugeIcons.strokeRoundedPlusSign,
                  buttonColor: Colors.green,
                  onPressed: () => _adjustStock(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final dynamic icon;
  final Color buttonColor;
  final VoidCallback? onPressed;

  const _CounterButton({
    required this.icon,
    required this.buttonColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed != null
          ? buttonColor.withOpacity(0.1)
          : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(
              color: onPressed != null ? buttonColor : Colors.grey.shade400,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(
              icon: icon,
              color: onPressed != null ? buttonColor : Colors.grey,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
