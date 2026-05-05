import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/glass_toast.dart';
import 'utils/cart_service.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final String deliveryOption;
  final double totalPrice;

  const CheckoutPage({
    super.key,
    required this.items,
    required this.deliveryOption,
    required this.totalPrice,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata;
      String fullName = meta?['full_name'] ?? '';
      String firstName = meta?['first_name'] ?? '';
      String lastName = meta?['last_name'] ?? '';

      if (fullName.startsWith('Tetamu')) {
        _firstNameController.text = '';
        _lastNameController.text = '';
      } else {
        if (firstName.isNotEmpty) {
          _firstNameController.text = firstName;
          _lastNameController.text = lastName;
        } else if (fullName.isNotEmpty) {
          final parts = fullName.split(' ');
          _firstNameController.text = parts.first;
          if (parts.length > 1) {
            _lastNameController.text = parts.sublist(1).join(' ');
          }
        }
      }
      _phoneController.text = meta?['phone'] ?? '';
    }
  }

  bool get _isDelivery => widget.deliveryOption.startsWith('Delivery');

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String fName = _firstNameController.text.trim();
      fName = fName.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');
      
      String lName = _lastNameController.text.trim();
      lName = lName.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');

      final bizRes = await Supabase.instance.client.from('businesses').select('id').limit(1).maybeSingle();
      final bizId = bizRes?['id'];
      
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      // Extract legacy quantities for backward compatibility with Staff Dashboard
      int hotQty = 0;
      int bbqQty = 0;
      int cheeseQty = 0;
      for (var item in widget.items) {
        if (item.title == 'HOT & SPICYYY') hotQty += item.quantity;
        if (item.title == 'SMOKY BBQ' || item.title == 'BBQ') bbqQty += item.quantity;
        if (item.title == 'CHEESE DIP' || item.title == 'Cheese Dip') cheeseQty += item.quantity;
      }

      final response = await Supabase.instance.client.from('orders').insert({
        'business_id': bizId,
        'user_id': currentUserId,
        'customer_name': '$fName $lName'.trim(),
        'phone_number': _phoneController.text,
        'delivery_address': _isDelivery ? _addressController.text.trim() : null,
        'hot_quantity_100g': hotQty,
        'bbq_quantity_100g': bbqQty,
        'cheese_quantity': cheeseQty,
        'items': widget.items.map((i) => i.toJson()).toList(), // NEW: Save dynamic items
        'delivery_option': widget.deliveryOption,
        'total_price': widget.totalPrice,
        'payment_status': 'Pending Payment',
        'status': 'pending',
      }).select().single();

      final orderId = response['id'];

      // NOTE: Stock deduction is now handled in Staff Dashboard when marking as PAID 
      // to avoid double deduction and complex rollback logic.
      
      if (!mounted) return;

      final name = '${_firstNameController.text} ${_lastNameController.text}'.trim();
      final phone = _phoneController.text;
      final itemsStr = widget.items.map((i) => '${i.title} x${i.quantity}').join(', ');
      final total = 'RM ${widget.totalPrice.toStringAsFixed(2)}';
      
      final waMessage = Uri.encodeComponent(
        'Assalamualaikum Lysa Saya nak order Nachozy!\n\n'
        'No. Pesanan: #$orderId\n'
        'Nama: $name\n'
        'No. Tel: $phone\n'
        'Pesanan: $itemsStr\n'
        'Lokasi: ${widget.deliveryOption}\n'
        'Jumlah: $total\n\n'
        'Saya akan hantar bukti pembayaran sekejap lagi ya. Terima kasih!'
      );
      const lysaNumber = '60132163194';
      final waUrl = Uri.parse('https://wa.me/$lysaNumber?text=$waMessage');

      // Clear cart after success
      CartService().clear();

      _showSuccessDialog(orderId, waUrl);
    } catch (e) {
      if (mounted) {
        showGlassToast(context, 'Ralat: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(dynamic orderId, Uri waUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Pesanan Berjaya!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('No. Pesanan anda: #$orderId', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Text(
              'Sila hantar pesanan anda ke WhatsApp untuk pengesahan dan pembayaran.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                  if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedWhatsapp, color: Colors.white, size: 20),
                label: const Text('HANTAR KE WHATSAPP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maklumat Penghantaran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Maklumat Anda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Nama Depan', _firstNameController, Icons.person_outline)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Nama Belakang', _lastNameController, Icons.person_outline)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('No. Telefon', _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              if (_isDelivery) ...[
                const SizedBox(height: 24),
                const Text('Alamat Penghantaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildField('Alamat Lengkap (Blok/No. Rumah/Zon)', _addressController, Icons.location_on_outlined, maxLines: 3),
              ],
              const SizedBox(height: 40),
              _buildOrderSummary(isDark),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAHKAN PESANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Bayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _summaryRow('Subtotal', 'RM ${widget.totalPrice.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _summaryRow('JUMLAH KESELURUHAN', 'RM ${widget.totalPrice.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTotal ? 18 : 14, color: isTotal ? const Color(0xFFFF5722) : null)),
      ],
    );
  }
}
