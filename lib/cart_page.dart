import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mock cart data
    final cartItems = [
      {'title': 'HOT & SPICYYY', 'price': 'RM 5.00', 'qty': 2, 'color': Colors.redAccent},
      {'title': 'SMOKY BBQ', 'price': 'RM 5.00', 'qty': 1, 'color': Colors.orangeAccent},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Troli Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassContainer(
                    useOwnLayer: true,
                    quality: GlassQuality.standard,
                    shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
                    settings: LiquidGlassSettings(
                      thickness: 0.1, blur: 10,
                      glassColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: HugeIcon(icon: HugeIcons.strokeRoundedPackage, color: item['color'] as Color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(item['price'] as String, style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _qtyBtn(Icons.remove, () {}),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              _qtyBtn(Icons.add, () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildCheckoutBar(context, isDark),
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

  Widget _buildCheckoutBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Jumlah Keseluruhan', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('RM 15.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFF5722))),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: InkWell(
              onTap: () {},
              child: GlassContainer(
                useOwnLayer: true,
                quality: GlassQuality.standard,
                shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
                settings: LiquidGlassSettings(
                  thickness: 0.15, blur: 25,
                  glassColor: const Color(0xFFFF5722).withValues(alpha: 0.8),
                ),
                child: const SizedBox(
                  height: 54,
                  child: Center(
                    child: Text('BAYAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
