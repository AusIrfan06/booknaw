import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'checkout_page.dart';
import 'login_page.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'utils/glass_toast.dart';
import 'utils/cart_service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _cartService = CartService();
  String? _deliveryOption;

  final Map<String, double> _deliveryFees = {
    'Pickup Alpha (A5-03-03)': 0.0,
    'Pickup Beta (B10-03-11)': 0.0,
    'Pickup Gamma (G-01-01)': 0.0,
    'Delivery Alpha': 1.0,
    'Delivery Beta': 1.0,
    'Delivery Gamma': 1.0,
    'Delivery NR': 2.0,
  };

  double get _totalPrice {
    double total = _cartService.totalPrice;
    if (_deliveryOption != null) {
      total += _deliveryFees[_deliveryOption] ?? 0.0;
    }
    return total;
  }

  void _proceedToCheckout() {
    if (_cartService.totalItems == 0) {
      showGlassToast(context, 'Sila tambah sekurang-kurangnya 1 item ke troli!', isError: true);
      return;
    }
    if (_deliveryOption == null) {
      showGlassToast(context, 'Sila pilih cara delivery/pickup!', isError: true);
      return;
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
          items: _cartService.items,
          deliveryOption: _deliveryOption!,
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Pesanan'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._cartService.items.map((item) => _buildOrderItem(item, isDark)),
            const SizedBox(height: 32),
            const Text(
              'Pilih Cara Penghantaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDeliveryOptions(isDark),
            const SizedBox(height: 150),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildOrderItem(CartItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('RM ${item.price.toStringAsFixed(2)} x ${item.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('RM ${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions(bool isDark) {
    return Column(
      children: _deliveryFees.keys.map((opt) {
        final fee = _deliveryFees[opt]!;
        final isSelected = _deliveryOption == opt;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _deliveryOption = opt),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFFF5722).withValues(alpha: 0.1) 
                    : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    opt.contains('Pickup') ? Icons.storefront_rounded : Icons.local_shipping_rounded,
                    color: isSelected ? const Color(0xFFFF5722) : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        Text(fee == 0 ? 'Percuma' : 'Caj: RM ${fee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFFFF5722)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(bool isDark) {
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
              child: const Text('TERUSKAN KE PEMBAYARAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
