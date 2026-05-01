import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'utils/cart_service.dart';
import 'order_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Troli Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: CartService(),
        builder: (context, _) {
          final service = CartService();
          final items = <Map<String, dynamic>>[];
          
          if (service.hotQuantity > 0) {
            items.add({'title': 'HOT & SPICYYY', 'qty': service.hotQuantity, 'color': Colors.redAccent, 'price': 5.0});
          }
          if (service.bbqQuantity > 0) {
            items.add({'title': 'SMOKY BBQ', 'qty': service.bbqQuantity, 'color': Colors.orangeAccent, 'price': 5.0});
          }
          if (service.cheeseQuantity > 0) {
            items.add({'title': 'CHEESE DIP', 'qty': service.cheeseQuantity, 'color': Colors.amber, 'price': 1.0});
          }

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedShoppingCart01, color: Colors.grey.withValues(alpha: 0.5), size: 100),
                  const SizedBox(height: 24),
                  const Text('Troli anda kosong.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Mula Membeli'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                                    Text('RM ${(item['price'] as double).toStringAsFixed(2)}', 
                                      style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _qtyBtn(Icons.remove, () {
                                    if (item['qty'] > 0) {
                                      service.updateQuantity(item['title'], item['qty'] - 1);
                                    }
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  _qtyBtn(Icons.add, () {
                                    service.updateQuantity(item['title'], item['qty'] + 1);
                                  }),
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
              _buildCheckoutBar(context, isDark, service),
            ],
          );
        },
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

  Widget _buildCheckoutBar(BuildContext context, bool isDark, CartService service) {
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
              const Text('Jumlah Keseluruhan', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('RM ${service.totalPrice.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFF5722))),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderPage(
                      initialHot: service.hotQuantity,
                      initialBbq: service.bbqQuantity,
                      initialCheese: service.cheeseQuantity,
                    ),
                  ),
                );
              },
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
