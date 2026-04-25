import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a StreamBuilder so the list updates automatically when a new order comes in
    final ordersStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Senarai Pesanan 📝'),
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

          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return const Center(child: Text('Belum ada pesanan lagi. 😢', style: TextStyle(fontSize: 18)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final hotQty = order['hot_quantity_100g'] as int? ?? 0;
    final bbqQty = order['bbq_quantity_100g'] as int? ?? 0;
    final addCheese = order['add_cheese_dip'] as bool? ?? false;
    final totalPrice = order['total_price'] ?? 0;
    final customerName = order['customer_name'] ?? 'Unknown';
    final phone = order['phone_number'] ?? 'Unknown';
    final delivery = order['delivery_option'] ?? 'Unknown';

    // Format date if needed, or just leave it out for simplicity
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100,
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
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(phone, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(height: 24),
            const Text('Pesanan:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (hotQty > 0) _buildItemRow(isDark, 'HOT & SPICYYY (100g)', 'x$hotQty'),
            if (bbqQty > 0) _buildItemRow(isDark, 'BBQ (100g)', 'x$bbqQty'),
            if (addCheese) _buildItemRow(isDark, 'Cheese Dip', 'Ya'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(delivery, style: const TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('- $label', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
