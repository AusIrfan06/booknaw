import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _TabDef(label: 'Semua',        icon: Icons.list_alt_rounded),
    _TabDef(label: 'Belum Bayar',  icon: Icons.hourglass_empty_rounded),
    _TabDef(label: 'Diproses',     icon: Icons.local_shipping_outlined),
    _TabDef(label: 'Selesai',      icon: Icons.check_circle_outline_rounded),
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

  // Filter logic matching each tab
  List<Map<String, dynamic>> _filter(
      List<Map<String, dynamic>> orders, int tabIndex) {
    switch (tabIndex) {
      case 1: // Belum Bayar
        return orders
            .where((o) => (o['payment_status'] ?? 'Pending Payment') != 'Paid')
            .toList();
      case 2: // Diproses — paid but not delivered
        return orders
            .where((o) =>
                (o['payment_status'] ?? '') == 'Paid' &&
                (o['status'] ?? '') != 'Delivered')
            .toList();
      case 3: // Selesai
        return orders
            .where((o) => (o['status'] ?? '') == 'Delivered')
            .toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    // Stream all orders for this user (filter by user_id if column exists,
    // else show all — adjust .eq() to your actual column name)
    final ordersStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya 📦'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
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
                return _EmptyState(tab: _tabs[i].label);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, idx) =>
                    _CustomerOrderCard(order: filtered[idx]),
              );
            }),
          );
        },
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  const _TabDef({required this.label, required this.icon});
}

class _EmptyState extends StatelessWidget {
  final String tab;
  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Tiada pesanan "$tab"',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _CustomerOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final hotQty = order['hot_quantity_100g'] as int? ?? 0;
    final bbqQty = order['bbq_quantity_100g'] as int? ?? 0;
    final addCheese = order['add_cheese_dip'] as bool? ?? false;
    final totalPrice = order['total_price'] ?? 0;
    final customerName = order['customer_name'] ?? '-';
    final delivery = order['delivery_option'] ?? '-';
    final status = order['status'] ?? 'Pending';
    final paymentStatus = order['payment_status'] ?? 'Pending Payment';
    final isPaid = paymentStatus == 'Paid';
    final isDelivered = status == 'Delivered';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Payment pill colour
    Color payColor = isPaid ? Colors.green : Colors.orange;
    String payLabel = isPaid ? '💰 Dibayar' : '⏳ Belum Bayar';

    // Delivery pill colour
    Color delColor = isDelivered ? Colors.blue : Colors.grey;
    String delLabel = isDelivered ? '✅ Selesai' : '🚚 Diproses';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + total
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.amber.shade900.withValues(alpha: 0.3)
                        : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RM ${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(delivery,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const Divider(height: 20),

            // Items
            if (hotQty > 0)
              _row('HOT & SPICYYY 🌶️', '${hotQty} pek', isDark);
            if (bbqQty > 0)
              _row('BBQ 🍖', '${bbqQty} pek', isDark);
            if (addCheese)
              _row('Cheese Dip 🧀', 'Ya', isDark);

            const SizedBox(height: 12),

            // Status pills
            Row(
              children: [
                _pill(payLabel, payColor),
                const SizedBox(width: 8),
                _pill(delLabel, delColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $label',
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
