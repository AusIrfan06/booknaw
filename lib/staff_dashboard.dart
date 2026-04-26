import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
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

  static const _titles = ['Dashboard', 'Pesanan', 'Stok Inventori'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardPage(),
      const _OrdersTab(),
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
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
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
              icon: HugeIcons.strokeRoundedPackage,
              color: Colors.grey,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedPackage,
              color: Color(0xFFFF5722),
              size: 24,
            ),
            label: 'Stok Inventori',
          ),
        ],
      ),
    );
  }
}

// ─── Page 0: Dashboard Overview ───────────────────────────────────────────────

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
        .stream(primaryKey: ['id'])
        .eq('id', 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome banner ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFBF360C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang, $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Staff NACHOZYYY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
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
              final pending = orders.where((o) => o['status'] != 'Delivered').length;
              final delivered = orders.where((o) => o['status'] == 'Delivered').length;

              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Jumlah Pesanan',
                      value: '${orders.length}',
                      icon: HugeIcons.strokeRoundedShoppingCart01,
                      color: const Color(0xFF5C6BC0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Belum Hantar',
                      value: '$pending',
                      icon: HugeIcons.strokeRoundedClock01,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Selesai',
                      value: '$delivered',
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
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
              final inv = snap.data!.first;
              final hotStock = inv['hot_stock'] as int? ?? 0;
              final bbqStock = inv['bbq_stock'] as int? ?? 0;

              return Column(
                children: [
                  _StockSummaryTile(
                    label: 'HOT & SPICYYY 🌶️',
                    stock: hotStock,
                  ),
                  const SizedBox(height: 10),
                  _StockSummaryTile(
                    label: 'BBQ 🍖',
                    stock: bbqStock,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Paid orders ready for delivery ──────────────────────────────────
          const Text(
            'Sedia Untuk Penghantaran 🚚',
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
                  .where((o) =>
                      (o['payment_status'] ?? '') == 'Paid' &&
                      (o['status'] ?? '') != 'Delivered')
                  .toList();

              if (readyOrders.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Tiada pesanan menunggu penghantaran.',
                          style: TextStyle(color: Colors.green)),
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
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final List<List<dynamic>> icon;
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
    return Container(
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _StockSummaryTile extends StatelessWidget {
  final String label;
  final int stock;

  const _StockSummaryTile({required this.label, required this.stock});

  @override
  Widget build(BuildContext context) {
    final isSoldOut = stock <= 0;
    final color = isSoldOut ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSoldOut ? 'SOLD OUT' : '$stock pek',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
    (label: 'Semua',       icon: Icons.list_alt_rounded),
    (label: 'Belum Bayar', icon: Icons.hourglass_empty_rounded),
    (label: 'Dibayar',     icon: Icons.payments_outlined),
    (label: 'Selesai',     icon: Icons.check_circle_outline_rounded),
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

  List<Map<String, dynamic>> _filter(
      List<Map<String, dynamic>> orders, int i) {
    switch (i) {
      case 1:
        return orders
            .where((o) => (o['payment_status'] ?? 'Pending Payment') != 'Paid')
            .toList();
      case 2:
        return orders
            .where((o) =>
                (o['payment_status'] ?? '') == 'Paid' &&
                (o['status'] ?? '') != 'Delivered')
            .toList();
      case 3:
        return orders
            .where((o) => (o['status'] ?? '') == 'Delivered')
            .toList();
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
                .map((t) => Tab(
                      child: Row(
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(t.label),
                        ],
                      ),
                    ))
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
                          Icon(Icons.inbox_outlined,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Tiada pesanan "${_tabs[i].label}"',
                              style: TextStyle(color: Colors.grey.shade600)),
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
          .update({'payment_status': 'Paid'}).eq('id', order['id']);
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
        .update({'status': 'Delivered'}).eq('id', order['id']);
  }

  @override
  Widget build(BuildContext context) {
    final hotQty = order['hot_quantity_100g'] as int? ?? 0;
    final bbqQty = order['bbq_quantity_100g'] as int? ?? 0;
    final addCheese = order['add_cheese_dip'] as bool? ?? false;
    final totalPrice = order['total_price'] ?? 0;
    final customerName = order['customer_name'] ?? 'Unknown';
    final phone = order['phone_number'] ?? 'Unknown';
    final delivery = order['delivery_option'] ?? 'Unknown';
    final status = order['status'] ?? 'Pending';
    final paymentStatus = order['payment_status'] ?? 'Pending Payment';
    final isPaid = paymentStatus == 'Paid';
    final isDelivered = status == 'Delivered';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDelivered
          ? (isDark
              ? Colors.green.shade900.withValues(alpha: 0.3)
              : Colors.green.shade50)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
            if (addCheese) const Text('- Cheese Dip'),
            const SizedBox(height: 8),
            Text('Lokasi: $delivery',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Total: RM ${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            // Payment status row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid ? '💰 Dibayar' : '⏳ Belum Bayar',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                  icon: const Icon(Icons.payments_outlined, color: Colors.white, size: 18),
                  label: const Text('Tandakan Dibayar', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  label: const Text('Mark as Delivered',
                      style: TextStyle(color: Colors.green)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ─── Page 2: Stok Inventori ───────────────────────────────────────────────────

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    final inventoryStream = Supabase.instance.client
        .from('inventory')
        .stream(primaryKey: ['id']).eq('id', 1);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: inventoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return Center(
              child: Text(
                  'Sila cipta table inventory di Supabase. Error: ${snapshot.error}'));
        }

        final inv = snapshot.data!.first;
        final hotStock = inv['hot_stock'] as int? ?? 0;
        final bbqStock = inv['bbq_stock'] as int? ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _StockUpdater(
                  flavor: 'HOT & SPICYYY 🌶️',
                  dbColumn: 'hot_stock',
                  currentStock: hotStock),
              const SizedBox(height: 20),
              _StockUpdater(
                  flavor: 'BBQ 🍖',
                  dbColumn: 'bbq_stock',
                  currentStock: bbqStock),
            ],
          ),
        );
      },
    );
  }
}

class _StockUpdater extends StatefulWidget {
  final String flavor;
  final String dbColumn;
  final int currentStock;

  const _StockUpdater(
      {required this.flavor,
      required this.dbColumn,
      required this.currentStock,
      super.key});

  @override
  State<_StockUpdater> createState() => _StockUpdaterState();
}

class _StockUpdaterState extends State<_StockUpdater> {
  final _manualController = TextEditingController();
  Timer? _debounce;

  Future<void> _adjustStock(int amount) async {
    try {
      final newStock = widget.currentStock + amount;
      await Supabase.instance.client
          .from('inventory')
          .update({widget.dbColumn: newStock < 0 ? 0 : newStock}).eq('id', 1);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ralat: $e')));
      }
    }
  }

  Future<void> _setManualStock(String value) async {
    final newStock = int.tryParse(value);
    if (newStock == null) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        await Supabase.instance.client
            .from('inventory')
            .update(
                {widget.dbColumn: newStock < 0 ? 0 : newStock}).eq('id', 1);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Ralat: $e')));
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
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Jumlah stok',
                border: OutlineInputBorder(),
                suffix: Text('pek'),
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
                Text(widget.flavor,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (isSoldOut)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('SOLD OUT',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _CounterButton(
                  icon: HugeIcons.strokeRoundedMinusSign,
                  color: Colors.orange,
                  onPressed:
                      widget.currentStock > 0 ? () => _adjustStock(-1) : null,
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
                            'pek  •  ketuk untuk edit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _CounterButton(
                  icon: HugeIcons.strokeRoundedPlusSign,
                  color: Colors.green,
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
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback? onPressed;

  const _CounterButton(
      {required this.icon, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed != null ? color.withValues(alpha: 0.1) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(
                color: onPressed != null ? color : Colors.grey.shade400,
                width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(
              icon: icon,
              color: onPressed != null ? color : Colors.grey,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
