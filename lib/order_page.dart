import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'checkout_page.dart';
import 'login_page.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int _hotQuantity = 0;
  int _bbqQuantity = 0;
  bool _addCheeseDip = false;
  String? _deliveryOption;
  String? _deliveryType; // 'pickup' or 'delivery'

  final double _pricePer100g = 5.0;
  final double _cheeseDipPrice = 1.0;

  final Map<String, double> _deliveryFees = {
    'Pickup Alpha (A5-03-03)': 0.0,
    'Pickup Beta (B10-03-11)': 0.0,
    'Delivery Alpha': 1.0,
    'Delivery Beta': 1.0,
    'Delivery Gamma': 1.0,
    'Delivery NR': 2.0,
  };

  double get _totalPrice {
    double total = ((_hotQuantity + _bbqQuantity) * _pricePer100g);
    if (_addCheeseDip) total += _cheeseDipPrice;
    if (_deliveryOption != null) {
      total += _deliveryFees[_deliveryOption] ?? 0.0;
    }
    return total;
  }

  void _proceedToCheckout() {
    if (_hotQuantity == 0 && _bbqQuantity == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila tambah sekurang-kurangnya 1 perisa! 🌶️🍖'),
        ),
      );
      return;
    }
    if (_deliveryOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih cara delivery/pickup! 🚗')),
      );
      return;
    }

    if (Supabase.instance.client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila log masuk untuk membuat pesanan!')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          hotQuantity: _hotQuantity,
          bbqQuantity: _bbqQuantity,
          addCheeseDip: _addCheeseDip,
          deliveryOption: _deliveryOption!,
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  late final Stream<List<Map<String, dynamic>>> _inventoryStream;

  @override
  void initState() {
    super.initState();
    _inventoryStream = Supabase.instance.client
        .from('inventory')
        .stream(primaryKey: ['id'])
        .order('id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _inventoryStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ralat: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sila pastikan table "inventory" wujud dan "Realtime" telah diaktifkan di Supabase Dashboard.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          int hotStock = 0;
          int bbqStock = 0;

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!;
            
            if (_deliveryOption == null) {
              // No zone selected: Use the maximum stock available in ANY single zone
              hotStock = data.fold<int>(0, (max, row) {
                final s = row['hot_stock'] as int? ?? 0;
                return s > max ? s : max;
              });
              bbqStock = data.fold<int>(0, (max, row) {
                final s = row['bbq_stock'] as int? ?? 0;
                return s > max ? s : max;
              });
            } else {
              // Zone is selected, use exact stock for that zone
              int locId = 1;
              if (_deliveryOption!.contains('Alpha')) locId = 1;
              else if (_deliveryOption!.contains('Beta')) locId = 2;
              else if (_deliveryOption!.contains('Gamma')) locId = 3;
              else if (_deliveryOption!.contains('NR')) locId = 4;
              
              final row = data.firstWhere((r) => r['id'] == locId, orElse: () => <String, dynamic>{});
              hotStock = row['hot_stock'] as int? ?? 0;
              bbqStock = row['bbq_stock'] as int? ?? 0;
            }
          }

          // Auto-correct quantities ONLY if stock drops below selected quantity
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              bool changed = false;
              if (_hotQuantity > hotStock) {
                setState(() => _hotQuantity = hotStock);
                changed = true;
              }
              if (_bbqQuantity > bbqStock) {
                setState(() => _bbqQuantity = bbqStock);
                changed = true;
              }
              
              if (changed && _deliveryOption != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maaf, stok di zon pilihan tidak mencukupi. Kuantiti diselaraskan secara automatik.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('1. Pilih Perisa & Kuantiti ✨'),
                _FlavorQuantityCard(
                  title: 'HOT & SPICYYY 🌶️',
                  subtitle: '(100g per pek)',
                  quantity: _hotQuantity,
                  maxStock: hotStock,
                  onIncrement: () {
                    if (_hotQuantity < hotStock) setState(() => _hotQuantity++);
                  },
                  onDecrement: () {
                    if (_hotQuantity > 0) setState(() => _hotQuantity--);
                  },
                ),
                const SizedBox(height: 12),
                _FlavorQuantityCard(
                  title: 'BBQ 🍖',
                  subtitle: '(100g per pek)',
                  quantity: _bbqQuantity,
                  maxStock: bbqStock,
                  onIncrement: () {
                    if (_bbqQuantity < bbqStock) setState(() => _bbqQuantity++);
                  },
                  onDecrement: () {
                    if (_bbqQuantity > 0) setState(() => _bbqQuantity--);
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('2. Add-on Padu 🤤'),
                CheckboxListTile(
                  title: const Text('Cheese Dip 🧀 (+ RM1.00)'),
                  value: _addCheeseDip,
                  onChanged: (val) =>
                      setState(() => _addCheeseDip = val ?? false),
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('3. Delivery / Pickup 🚗'),

                // ── Step 1: Pickup or Delivery ───────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: 'Pickup',
                        icon: Icons.store_outlined,
                        sublabel: 'FREE',
                        selected: _deliveryType == 'pickup',
                        color: Colors.green,
                        onTap: () => setState(() {
                          _deliveryType = 'pickup';
                          _deliveryOption = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeButton(
                        label: 'Delivery',
                        icon: Icons.delivery_dining_outlined,
                        sublabel: 'RM 1.00 – 2.00',
                        selected: _deliveryType == 'delivery',
                        color: Colors.deepOrange,
                        onTap: () => setState(() {
                          _deliveryType = 'delivery';
                          _deliveryOption = null;
                        }),
                      ),
                    ),
                  ],
                ),

                // ── Step 2: Zone ─────────────────────────────────────────
                if (_deliveryType != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_deliveryType == 'pickup') ...[
                        _ZoneChip(
                          label: 'Alpha (A5-03-03)',
                          value: 'Pickup Alpha (A5-03-03)',
                          fee: 0,
                          selected: _deliveryOption == 'Pickup Alpha (A5-03-03)',
                          onTap: () => setState(() => _deliveryOption = 'Pickup Alpha (A5-03-03)'),
                        ),
                        _ZoneChip(
                          label: 'Beta (B10-03-11)',
                          value: 'Pickup Beta (B10-03-11)',
                          fee: 0,
                          selected: _deliveryOption == 'Pickup Beta (B10-03-11)',
                          onTap: () => setState(() => _deliveryOption = 'Pickup Beta (B10-03-11)'),
                        ),
                      ] else ...[
                        _ZoneChip(
                          label: 'Alpha',
                          value: 'Delivery Alpha',
                          fee: 1,
                          selected: _deliveryOption == 'Delivery Alpha',
                          onTap: () => setState(() => _deliveryOption = 'Delivery Alpha'),
                        ),
                        _ZoneChip(
                          label: 'Beta',
                          value: 'Delivery Beta',
                          fee: 1,
                          selected: _deliveryOption == 'Delivery Beta',
                          onTap: () => setState(() => _deliveryOption = 'Delivery Beta'),
                        ),
                        _ZoneChip(
                          label: 'Gamma',
                          value: 'Delivery Gamma',
                          fee: 1,
                          selected: _deliveryOption == 'Delivery Gamma',
                          onTap: () => setState(() => _deliveryOption = 'Delivery Gamma'),
                        ),
                        _ZoneChip(
                          label: 'Non-Resident',
                          value: 'Delivery NR',
                          fee: 2,
                          selected: _deliveryOption == 'Delivery NR',
                          onTap: () => setState(() => _deliveryOption = 'Delivery NR'),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.amber.shade900.withValues(alpha: 0.3)
                        : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RM ${_totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Teruskan ke Pembayaran',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FlavorQuantityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int quantity;
  final int maxStock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _FlavorQuantityCard({
    required this.title,
    required this.subtitle,
    required this.quantity,
    required this.maxStock,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = quantity > 0;
    final isSoldOut = maxStock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSoldOut
            ? (isDark ? Colors.grey.shade900 : Colors.grey.shade300)
            : (isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected && !isSoldOut
              ? Theme.of(context).colorScheme.primary
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSoldOut
                              ? Colors.grey
                              : (isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87)),
                        ),
                      ),
                    ),
                    if (isSoldOut)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  isSoldOut ? 'Stok habis buat masa ini.' : subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSoldOut
                        ? Colors.grey
                        : (isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.8)
                              : (isDark ? Colors.white54 : Colors.black54)),
                  ),
                ),
              ],
            ),
          ),
          if (!isSoldOut)
            Row(
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMinusSignCircle,
                    color: quantity > 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    size: 28,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: quantity < maxStock ? onIncrement : null,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedPlusSignCircle,
                    color: quantity < maxStock
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    size: 28,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Delivery Type Button ──────────────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? color : Colors.grey.shade700,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                color: selected ? color.withValues(alpha: 0.8) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Zone Chip ─────────────────────────────────────────────────────────────────

class _ZoneChip extends StatelessWidget {
  final String label;
  final String value;
  final int fee;
  final bool selected;
  final VoidCallback onTap;

  const _ZoneChip({
    required this.label,
    required this.value,
    required this.fee,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          fee == 0 ? '$label  •  FREE' : '$label  •  +RM${fee.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
