import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutPage extends StatefulWidget {
  final int hotQuantity;
  final int bbqQuantity;
  final bool addCheeseDip;
  final String deliveryOption;
  final double totalPrice;

  const CheckoutPage({
    super.key,
    required this.hotQuantity,
    required this.bbqQuantity,
    required this.addCheeseDip,
    required this.deliveryOption,
    required this.totalPrice,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('orders').insert({
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'customer_name': _nameController.text,
        'phone_number': _phoneController.text,
        'hot_quantity_100g': widget.hotQuantity,
        'bbq_quantity_100g': widget.bbqQuantity,
        'add_cheese_dip': widget.addCheeseDip,
        'delivery_option': widget.deliveryOption,
        'total_price': widget.totalPrice,
        'payment_status': 'Pending Payment',
      });

      // Deduct stock
      final invData = await Supabase.instance.client.from('inventory').select().eq('id', 1).single();
      final newHot = (invData['hot_stock'] as int? ?? 0) - widget.hotQuantity;
      final newBbq = (invData['bbq_stock'] as int? ?? 0) - widget.bbqQuantity;
      
      await Supabase.instance.client.from('inventory').update({
        'hot_stock': newHot < 0 ? 0 : newHot,
        'bbq_stock': newBbq < 0 ? 0 : newBbq,
      }).eq('id', 1);

      if (!mounted) return;

      // Build WhatsApp message for Lysa
      final name = _nameController.text;
      final phone = _phoneController.text;
      final hot = widget.hotQuantity > 0 ? 'HOT & SPICYYY x${widget.hotQuantity}' : '';
      final bbq = widget.bbqQuantity > 0 ? 'BBQ x${widget.bbqQuantity}' : '';
      final cheese = widget.addCheeseDip ? '+ Cheese Dip' : '';
      final items = [hot, bbq, cheese].where((s) => s.isNotEmpty).join(', ');
      final total = 'RM ${widget.totalPrice.toStringAsFixed(2)}';
      final location = widget.deliveryOption;

      final waMessage = Uri.encodeComponent(
        'Assalamualaikum Lysa 🙋 Saya baru buat pesanan NACHOZYYY dan dah buat bayaran!\n\n'
        '👤 Nama: $name\n'
        '📱 No. Tel: $phone\n'
        '🛒 Pesanan: $items\n'
        '📍 Lokasi: $location\n'
        '💰 Jumlah: $total\n\n'
        'Sila semak resit pembayaran saya ya! Terima kasih 🙏',
      );
      const lysaNumber = '60132163194'; // Lysa - Beta & Gamma
      final waUrl = Uri.parse('https://wa.me/$lysaNumber?text=$waMessage');

      _showPaymentSheet(context, waUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentSheet(BuildContext context, Uri waUrl) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan Berjaya! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Langkah seterusnya: Hantar bukti pembayaran kepada Lysa melalui WhatsApp untuk pengesahan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text(
                  'Hubungi Lysa di WhatsApp',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Kembali ke Laman Utama'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bayaran & Maklumat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedShoppingCart01, size: 40),
                      const SizedBox(height: 8),
                      const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      if (widget.hotQuantity > 0) _buildSummaryRow('HOT & SPICYYY', '${widget.hotQuantity} pek'),
                      if (widget.bbqQuantity > 0) _buildSummaryRow('BBQ', '${widget.bbqQuantity} pek'),
                      if (widget.addCheeseDip) _buildSummaryRow('Cheese Dip', 'Ya'),
                      _buildSummaryRow('Lokasi', widget.deliveryOption),
                      const Divider(),
                      _buildSummaryRow('Jumlah Bayaran', 'RM ${widget.totalPrice.toStringAsFixed(2)}', isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Maklumat Hubungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Penuh',
                  prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.grey, size: 20),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Sila masukkan nama' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'No. Telefon (WhatsApp)',
                  prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedSmartPhone01, color: Colors.grey, size: 20),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Sila masukkan no. telefon' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Confirm & Submit Order', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
