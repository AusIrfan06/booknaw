import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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

    // ── Not logged in ──────────────────────────────────────────────────────
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pesanan Saya 📦'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                const Text(
                  'Log masuk untuk lihat pesanan anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pesanan anda akan disimpan dan boleh dijejaki selepas log masuk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginPage()),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Log Masuk'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Logged in: filter by user_id ───────────────────────────────────────
    final ordersStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
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

          // On error (e.g. user_id column not yet added), just show empty
          final allOrders = snapshot.hasError
              ? <Map<String, dynamic>>[]
              : (snapshot.data ?? <Map<String, dynamic>>[]);

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
    final isOutForDelivery = status == 'Out for Delivery';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Payment pill colour
    Color payColor = isPaid ? Colors.green : Colors.orange;
    String payLabel = isPaid ? '💰 Dibayar' : '⏳ Belum Bayar';

    // Delivery pill colour
    Color delColor;
    String delLabel;
    
    if (isDelivered) {
      delColor = Colors.blue;
      delLabel = '✅ Telah Dihantar';
    } else if (isOutForDelivery) {
      delColor = Colors.orange;
      delLabel = '🛵 Sedang Dihantar';
    } else {
      delColor = Colors.grey;
      delLabel = isPaid ? '🚚 Sedang Diproses' : '⏳ Belum Bayar';
    }

    return InkWell(
      onTap: () => _showReceipt(context),
      borderRadius: BorderRadius.circular(14),
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 14.0),
        settings: LiquidGlassSettings(
          thickness: 0.05,
          blur: 10,
          refractiveIndex: 1.0,
          glassColor: Colors.transparent,
          lightAngle: 45.0,
          lightIntensity: 0.1,
          ambientStrength: 1.0,
          saturation: 1.0,
          chromaticAberration: 0.0,
        ),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
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
                          ? Colors.amber.shade900.withOpacity(0.3)
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
                _row('HOT & SPICYYY 🌶️', '$hotQty pek', isDark),
              if (bbqQty > 0)
                _row('BBQ 🍖', '$bbqQty pek', isDark),
              if (addCheese)
                _row('Cheese Dip 🧀', 'Ya', isDark),

              const SizedBox(height: 12),

              // Status pills
              Row(
                children: [
                  Flexible(child: _pill(payLabel, payColor)),
                  const SizedBox(width: 8),
                  Flexible(child: _pill(delLabel, delColor)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('Tekan untuk lihat resit',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showReceipt(BuildContext context) {
    final hotQty = order['hot_quantity_100g'] as int? ?? 0;
    final bbqQty = order['bbq_quantity_100g'] as int? ?? 0;
    final addCheese = order['add_cheese_dip'] as bool? ?? false;
    final totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final customerName = order['customer_name'] ?? '-';
    final phone = order['phone_number'] ?? '-';
    final delivery = order['delivery_option'] ?? '-';
    final address = order['delivery_address'] as String?;
    final status = order['status'] ?? 'Pending';
    final paymentStatus = order['payment_status'] ?? 'Pending Payment';
    final orderId = order['id']?.toString() ?? '-';
    final createdAt = order['created_at'] as String?;
    final isPaid = paymentStatus == 'Paid';
    final isDelivered = status == 'Delivered';
    final isOutForDelivery = status == 'Out for Delivery';

    Color delColor;
    String delLabel;
    
    if (isDelivered) {
      delColor = Colors.blue;
      delLabel = '✅ Telah Dihantar';
    } else if (isOutForDelivery) {
      delColor = Colors.orange;
      delLabel = '🛵 Sedang Dihantar';
    } else {
      delColor = Colors.grey;
      delLabel = isPaid ? '🚚 Sedang Diproses' : '⏳ Belum Bayar';
    }

    String dateStr = '-';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long_rounded,
                            color: primary, size: 32),
                      ),
                      const SizedBox(height: 10),
                      Text('NACHOZYYY 🌶️🧀',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primary)),
                      const SizedBox(height: 2),
                      Text('Resit Pesanan',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _dashedDivider(),

                // Order info
                _receiptRow('📌 No. Pesanan', '#$orderId'),
                _receiptRow('📅 Tarikh', dateStr),
                _receiptRow('👤 Nama', customerName),
                _receiptRow('📱 No. Tel', phone),
                if (address != null && address.isNotEmpty)
                  _receiptRow('🏠 Alamat', address),
                _receiptRow('📍 Lokasi', delivery),
                _dashedDivider(),

                // Items
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Pesanan',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          fontSize: 12)),
                ),
                if (hotQty > 0)
                  _receiptRow('HOT & SPICYYY 🌶️',
                      '${hotQty}x  @RM5.00  =  RM${(hotQty * 5.0).toStringAsFixed(2)}'),
                if (bbqQty > 0)
                  _receiptRow('BBQ 🍖',
                      '${bbqQty}x  @RM5.00  =  RM${(bbqQty * 5.0).toStringAsFixed(2)}'),
                if (addCheese)
                  _receiptRow('Cheese Dip 🧀', 'RM1.00'),
                _dashedDivider(),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('JUMLAH',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('RM ${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: primary)),
                  ],
                ),
                const SizedBox(height: 16),
                _dashedDivider(),

                // Status
                Row(
                  children: [
                    Expanded(
                      child: _statusBadge(
                        isPaid ? '💰 Dibayar' : '⏳ Belum Bayar',
                        isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statusBadge(
                        delLabel,
                        delColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Footer
                if (!isPaid) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final hot = hotQty > 0 ? 'HOT & SPICYYY x$hotQty' : '';
                      final bbq = bbqQty > 0 ? 'BBQ x$bbqQty' : '';
                      final cheese = addCheese ? '+ Cheese Dip' : '';
                      final items = [hot, bbq, cheese].where((s) => s.isNotEmpty).join(', ');
                      
                      final waMessage = Uri.encodeComponent(
                        'Assalamualaikum Lysa 🙋 Saya nak buat bayaran untuk pesanan (No. #$orderId)!\n\n'
                        '👤 Nama: $customerName\n'
                        '📱 No. Tel: $phone\n'
                        '🛒 Pesanan: $items\n'
                        '📍 Lokasi: $delivery\n'
                        '${address != null && address.isNotEmpty ? "🏠 Alamat: $address\n" : ""}'
                        '💰 Jumlah: RM ${totalPrice.toStringAsFixed(2)}\n\n'
                        'Sila semak resit pembayaran saya ya! Terima kasih 🙏',
                      );
                      const lysaNumber = '60132163194';
                      final waUrl = Uri.parse('https://wa.me/$lysaNumber?text=$waMessage');
                      try {
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Could not launch WhatsApp: $e');
                      }
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Hubungi & Buat Bayaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Center(
                  child: Text(
                    'Terima kasih kerana menyokong kami! 💛',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(
          30,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 13),
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
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
