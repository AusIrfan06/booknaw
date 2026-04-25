import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
import 'home_page.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Staff Dashboard 🧑‍💼'),
          actions: [
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: Colors.white, size: 24),
              onPressed: () => _logout(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: HugeIcon(icon: HugeIcons.strokeRoundedTask01, color: Colors.white, size: 24), text: 'Pesanan'),
              Tab(icon: HugeIcon(icon: HugeIcons.strokeRoundedPackage, color: Colors.white, size: 24), text: 'Stok Inventori'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersTab(),
            _InventoryTab(),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

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
        if (snapshot.hasError) {
          return Center(child: Text('Ralat: ${snapshot.error}'));
        }

        final orders = snapshot.data;
        if (orders == null || orders.isEmpty) {
          return const Center(child: Text('Belum ada pesanan.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _StaffOrderCard(order: order);
          },
        );
      },
    );
  }
}

class _StaffOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _StaffOrderCard({required this.order});

  Future<void> _markDelivered(BuildContext context) async {
    try {
      await _tryUpdateStatus();
    } catch (e) {
      // First error, wait 1 second and try again
      await Future.delayed(const Duration(seconds: 1));
      try {
        await _tryUpdateStatus();
      } catch (e2) {
        // Second fail, show snackbar
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
    final addCheese = order['add_cheese_dip'] as bool? ?? false;
    final totalPrice = order['total_price'] ?? 0;
    final customerName = order['customer_name'] ?? 'Unknown';
    final phone = order['phone_number'] ?? 'Unknown';
    final delivery = order['delivery_option'] ?? 'Unknown';
    final status = order['status'] ?? 'Pending';
    final isDelivered = status == 'Delivered';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDelivered ? (isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: isDelivered ? Colors.green : Colors.orange)),
              ],
            ),
            const SizedBox(height: 4),
            Text(phone, style: const TextStyle(color: Colors.grey)),
            const Divider(),
            if (hotQty > 0) Text('- HOT & SPICYYY x$hotQty'),
            if (bbqQty > 0) Text('- BBQ x$bbqQty'),
            if (addCheese) const Text('- Cheese Dip'),
            const SizedBox(height: 8),
            Text('Lokasi: $delivery', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Total: RM ${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
            if (!isDelivered) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _markDelivered(context),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, color: Colors.green, size: 20),
                  label: const Text('Mark as Delivered', style: TextStyle(color: Colors.green)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    final inventoryStream = Supabase.instance.client
        .from('inventory')
        .stream(primaryKey: ['id'])
        .eq('id', 1);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: inventoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(child: Text('Sila cipta table inventory di Supabase. Error: ${snapshot.error}'));
        }

        final inv = snapshot.data!.first;
        final hotStock = inv['hot_stock'] as int? ?? 0;
        final bbqStock = inv['bbq_stock'] as int? ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _StockUpdater(flavor: 'HOT & SPICYYY 🌶️', dbColumn: 'hot_stock', currentStock: hotStock),
              const SizedBox(height: 20),
              _StockUpdater(flavor: 'BBQ 🍖', dbColumn: 'bbq_stock', currentStock: bbqStock),
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

  const _StockUpdater({required this.flavor, required this.dbColumn, required this.currentStock, super.key});

  @override
  State<_StockUpdater> createState() => _StockUpdaterState();
}

class _StockUpdaterState extends State<_StockUpdater> {
  final _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _setManualStock();
    });
  }

  Future<void> _adjustStock(int amount) async {
    try {
      final newStock = widget.currentStock + amount;
      await Supabase.instance.client
          .from('inventory')
          .update({widget.dbColumn: newStock < 0 ? 0 : newStock})
          .eq('id', 1);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ralat: $e')));
      }
    }
  }

  Future<void> _setManualStock() async {
    final newStock = int.tryParse(_controller.text);
    if (newStock == null) return;
    try {
      await Supabase.instance.client
          .from('inventory')
          .update({widget.dbColumn: newStock < 0 ? 0 : newStock})
          .eq('id', 1);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ralat: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSoldOut = widget.currentStock <= 0;

    return Card(
      elevation: 2,
      color: isSoldOut ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.flavor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (isSoldOut)
                  const Text('SOLD OUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Stok Semasa: ${widget.currentStock} pek', style: TextStyle(fontSize: 16, color: isSoldOut ? Colors.red : null)),
            const SizedBox(height: 16),
            Row(
              children: [
                _adjustButton(icon: HugeIcons.strokeRoundedMinusSign, label: '-1', color: Colors.orange, onPressed: () => _adjustStock(-1)),
                const SizedBox(width: 8),
                _adjustButton(icon: HugeIcons.strokeRoundedPlusSign, label: '+1', color: Colors.green, onPressed: () => _adjustStock(1)),
                const SizedBox(width: 8),
                _adjustButton(icon: HugeIcons.strokeRoundedPlusSignCircle, label: '+10', color: Colors.green.shade700, onPressed: () => _adjustStock(10)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    onChanged: _onChanged,
                    decoration: const InputDecoration(
                      labelText: 'Taip untuk set stok baru...',
                      isDense: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, color: Colors.grey, size: 20),
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _adjustButton({required List<List<dynamic>> icon, required String label, required Color color, required VoidCallback onPressed}) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: HugeIcon(icon: icon, size: 16, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
