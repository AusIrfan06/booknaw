import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'checkout_page.dart';
import 'login_page.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'utils/glass_toast.dart';
import 'utils/cart_service.dart';

class OrderPage extends StatefulWidget {
  final int initialHot;
  final int initialBbq;
  final int initialCheese;

  const OrderPage({
    super.key,
    this.initialHot = 0,
    this.initialBbq = 0,
    this.initialCheese = 0,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // Use CartService for quantities
  final _cartService = CartService();
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
    double total = ((_cartService.hotQuantity + _cartService.bbqQuantity) * _pricePer100g);
    if (_cartService.cheeseQuantity > 0) total += (_cartService.cheeseQuantity * _cheeseDipPrice);
    if (_deliveryOption != null) {
      total += _deliveryFees[_deliveryOption] ?? 0.0;
    }
    return total;
  }

  List<Map<String, dynamic>> _currentInventory = [];

  void _proceedToCheckout() {
    if (_cartService.totalItems == 0) {
      showGlassToast(context, 'Sila tambah sekurang-kurangnya 1 item (Nachos atau Cheese Dip)!', isError: true);
      return;
    }
    if (_deliveryOption == null) {
      showGlassToast(context, 'Sila pilih cara delivery/pickup!', isError: true);
      return;
    }

    // NEW: Strict Location Stock Check
    int locId = 1;
    if (_deliveryOption!.contains('Alpha')) {
      locId = 1;
    } else if (_deliveryOption!.contains('Beta')) {
      locId = 2;
    } else if (_deliveryOption!.contains('Gamma')) {
      locId = 3;
    } else if (_deliveryOption!.contains('NR')) {
      locId = 4;
    }

    final locData = _currentInventory.firstWhere((element) => element['id'] == locId, orElse: () => {});
    if (locData.isNotEmpty) {
      final hotStock = locData['hot_stock'] as int? ?? 0;
      final bbqStock = locData['bbq_stock'] as int? ?? 0;
      final cheeseStock = locData['cheese_stock'] as int? ?? 0;

      String? errorMsg;
      if (_cartService.hotQuantity > hotStock) {
        errorMsg = 'Maaf, $_deliveryOption hanya mempunyai $hotStock stok HOT & SPICYYY.';
      } else if (_cartService.bbqQuantity > bbqStock) {
        errorMsg = 'Maaf, $_deliveryOption hanya mempunyai $bbqStock stok SMOKY BBQ.';
      } else if (_cartService.cheeseQuantity > cheeseStock) {
        errorMsg = 'Maaf, $_deliveryOption hanya mempunyai $cheeseStock stok Cheese Dip.';
      }

      if (errorMsg != null) {
        showGlassToast(context, errorMsg, isError: true);
        return;
      }
    }

    if (Supabase.instance.client.auth.currentUser == null) {
      showGlassToast(context, 'Sila log masuk untuk membuat pesanan!', isError: true);
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
          hotQuantity: _cartService.hotQuantity,
          bbqQuantity: _cartService.bbqQuantity,
          cheeseQuantity: _cartService.cheeseQuantity,
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
    // Initialize CartService with values from constructor if provided
    if (widget.initialHot > 0) _cartService.updateQuantity('HOT & SPICYYY', widget.initialHot);
    if (widget.initialBbq > 0) _cartService.updateQuantity('SMOKY BBQ', widget.initialBbq);
    if (widget.initialCheese > 0) _cartService.updateQuantity('CHEESE DIP', widget.initialCheese);

    _inventoryStream = Supabase.instance.client
        .from('inventory')
        .stream(primaryKey: ['id'])
        .order('id');
    
    _cartService.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            shape: LiquidRoundedSuperellipse(borderRadius: 999.0),
            settings: LiquidGlassSettings(thickness: 0.2, blur: 20),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _inventoryStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ralat: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final inventory = snapshot.data ?? [];
          _currentInventory = inventory;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('1. Pilih Perisa Nachos (100g)'),
                const SizedBox(height: 16),
                _buildNachosOption(
                  'HOT & SPICYYY',
                  'Pedas gila, gerenti berpeluh!',
                  _cartService.hotQuantity,
                  (val) => _cartService.updateQuantity('HOT & SPICYYY', val),
                  inventory,
                  'hot_stock',
                  Colors.redAccent,
                ),
                const SizedBox(height: 12),
                _buildNachosOption(
                  'SMOKY BBQ',
                  'Rasa salai yang premium.',
                  _cartService.bbqQuantity,
                  (val) => _cartService.updateQuantity('SMOKY BBQ', val),
                  inventory,
                  'bbq_stock',
                  Colors.orangeAccent,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('2. Tambah Sos Keju'),
                const SizedBox(height: 16),
                _buildCheeseOption(inventory),
                const SizedBox(height: 32),
                _buildSectionHeader('3. Cara Penghantaran'),
                const SizedBox(height: 16),
                _buildDeliveryTypeSelection(),
                if (_deliveryType != null) ...[
                  const SizedBox(height: 16),
                  _buildLocationSelection(),
                ],
                const SizedBox(height: 150),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildNachosOption(
    String title,
    String sub,
    int qty,
    ValueChanged<int> onChanged,
    List<Map<String, dynamic>> inventory,
    String stockKey,
    Color color,
  ) {
    int displayStock = 0;
    if (_deliveryOption != null) {
      // Show stock for selected location
      int locId = 1;
      if (_deliveryOption!.contains('Alpha')) {
        locId = 1;
      } else if (_deliveryOption!.contains('Beta')) {
        locId = 2;
      } else if (_deliveryOption!.contains('Gamma')) {
        locId = 3;
      } else if (_deliveryOption!.contains('NR')) {
        locId = 4;
      }
      
      final locData = inventory.firstWhere((e) => e['id'] == locId, orElse: () => {});
      displayStock = locData[stockKey] as int? ?? 0;
    } else {
      // Show aggregate stock
      for (var loc in inventory) {
        displayStock += (loc[stockKey] as int? ?? 0);
      }
    }

    final isOutOfStock = displayStock <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.fastfood, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (isOutOfStock)
                  const Text('Stok Habis', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))
                else
                  Text('Stok: $displayStock', style: const TextStyle(fontSize: 10, color: Colors.green)),
              ],
            ),
          ),
          if (!isOutOfStock)
            Row(
              children: [
                _qtyBtn(Icons.remove, () {
                  if (qty > 0) onChanged(qty - 1);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _qtyBtn(Icons.add, () {
                  if (qty < displayStock) {
                    onChanged(qty + 1);
                  } else {
                    showGlassToast(context, 'Maaf, tiada stok tambahan di $_deliveryOption!', isError: true);
                  }
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCheeseOption(List<Map<String, dynamic>> inventory) {
    int displayStock = 0;
    if (_deliveryOption != null) {
      int locId = 1;
      if (_deliveryOption!.contains('Alpha')) {
        locId = 1;
      } else if (_deliveryOption!.contains('Beta')) {
        locId = 2;
      } else if (_deliveryOption!.contains('Gamma')) {
        locId = 3;
      } else if (_deliveryOption!.contains('NR')) {
        locId = 4;
      }
      
      final locData = inventory.firstWhere((e) => e['id'] == locId, orElse: () => {});
      displayStock = locData['cheese_stock'] as int? ?? 0;
    } else {
      for (var loc in inventory) {
        displayStock += (loc['cheese_stock'] as int? ?? 0);
      }
    }
    final isOutOfStock = displayStock <= 0;
    final qty = _cartService.cheeseQuantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bakery_dining, color: Colors.amber),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHEESE DIP', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('Sos keju berkrim & padu.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                if (isOutOfStock)
                  const Text('Stok Habis', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))
                else
                  Text('Stok: $displayStock', style: const TextStyle(fontSize: 10, color: Colors.green)),
              ],
            ),
          ),
          if (!isOutOfStock)
            Row(
              children: [
                _qtyBtn(Icons.remove, () {
                  if (qty > 0) _cartService.updateQuantity('CHEESE DIP', qty - 1);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _qtyBtn(Icons.add, () {
                  if (qty < displayStock) {
                    _cartService.updateQuantity('CHEESE DIP', qty + 1);
                  } else {
                    showGlassToast(context, 'Maaf, tiada stok tambahan di $_deliveryOption!', isError: true);
                  }
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTypeSelection() {
    return Row(
      children: [
        _typeCard('Pickup', Icons.storefront, _deliveryType == 'pickup', () {
          setState(() {
            _deliveryType = 'pickup';
            _deliveryOption = null;
          });
        }),
        const SizedBox(width: 16),
        _typeCard('Delivery', Icons.local_shipping, _deliveryType == 'delivery', () {
          setState(() {
            _deliveryType = 'delivery';
            _deliveryOption = null;
          });
        }),
      ],
    );
  }

  Widget _typeCard(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5722) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFFFF5722) : Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelection() {
    final options = _deliveryFees.keys.where((k) => k.toLowerCase().contains(_deliveryType!)).toList();

    return Column(
      children: options.map((opt) {
        final fee = _deliveryFees[opt]!;
        final isSelected = _deliveryOption == opt;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _deliveryOption = opt),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF5722).withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFFFF5722) : Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        Text(fee == 0 ? 'Percuma' : 'Caj: RM ${fee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFFF5722)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Jumlah Bayaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('RM ${_totalPrice.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFF5722))),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              onPressed: _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('TERUSKAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.05)),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
