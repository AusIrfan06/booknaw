import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/glass_toast.dart';
import 'utils/cart_service.dart';

class CheckoutPage extends StatefulWidget {
  final int hotQuantity;
  final int bbqQuantity;
  final int cheeseQuantity;
  final String deliveryOption;
  final double totalPrice;

  const CheckoutPage({
    super.key,
    required this.hotQuantity,
    required this.bbqQuantity,
    required this.cheeseQuantity,
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
          // Fallback for old accounts without split names
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

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      debugPrint('Submitting order: user_id=$currentUserId');

      final response = await Supabase.instance.client.from('orders').insert({
        'user_id': currentUserId,
        'customer_name': '$fName $lName'.trim(),
        'phone_number': _phoneController.text,
        'delivery_address': _isDelivery ? _addressController.text.trim() : null,
        'hot_quantity_100g': widget.hotQuantity,
        'bbq_quantity_100g': widget.bbqQuantity,
        'cheese_quantity': widget.cheeseQuantity,
        'delivery_option': widget.deliveryOption,
        'total_price': widget.totalPrice,
        'payment_status': 'Pending Payment',
        'status': 'pending', 
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final orderId = response['id'];

      // Determine locId from delivery option
      int locId = 1;
      if (widget.deliveryOption.contains('Alpha')) {
        locId = 1;
      } else if (widget.deliveryOption.contains('Beta')) {
        locId = 2;
      } else if (widget.deliveryOption.contains('Gamma')) {
        locId = 3;
      } else if (widget.deliveryOption.contains('NR')) {
        locId = 4;
      }

      // Deduct stock from the CORRECT location
      final invData = await Supabase.instance.client.from('inventory').select().eq('id', locId).single();
      final newHot = (invData['hot_stock'] as int? ?? 0) - widget.hotQuantity;
      final newBbq = (invData['bbq_stock'] as int? ?? 0) - widget.bbqQuantity;
      final newCheese = (invData['cheese_stock'] as int? ?? 0) - widget.cheeseQuantity;
      
      await Supabase.instance.client.from('inventory').update({
        'hot_stock': newHot < 0 ? 0 : newHot,
        'bbq_stock': newBbq < 0 ? 0 : newBbq,
        'cheese_stock': newCheese < 0 ? 0 : newCheese,
      }).eq('id', locId);

      if (!mounted) return;

      // Build WhatsApp message for Lysa
      final name = '${_firstNameController.text} ${_lastNameController.text}'.trim();
      final phone = _phoneController.text;
      final hot = widget.hotQuantity > 0 ? 'HOT & SPICYYY x${widget.hotQuantity}' : '';
      final bbq = widget.bbqQuantity > 0 ? 'BBQ x${widget.bbqQuantity}' : '';
      final cheese = widget.cheeseQuantity > 0 ? 'Cheese Dip x${widget.cheeseQuantity}' : '';
      final items = [hot, bbq, cheese].where((s) => s.isNotEmpty).join(', ');
      final total = 'RM ${widget.totalPrice.toStringAsFixed(2)}';
      
      final waMessage = Uri.encodeComponent(
        'Assalamualaikum Lysa Saya nak order Nachozy!\n\n'
        'No. Pesanan: #$orderId\n'
        'Nama: $name\n'
        'No. Tel: $phone\n'
        'Pesanan: $items\n'
        'Lokasi: ${widget.deliveryOption}\n'
        'Jumlah: $total\n\n'
        'Saya akan hantar bukti pembayaran sekejap lagi ya. Terima kasih!'
      );
      const lysaNumber = '60132163194';
      final waUrl = Uri.parse('https://wa.me/$lysaNumber?text=$waMessage');

      // Clear cart
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text('Pesanan Berjaya!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('No. Pesanan anda: #$orderId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              
              _buildStepRow(
                step: 'Langkah 1',
                title: 'Tangkap Layar QR Code',
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFFFF5722),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/qr_payment.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SITI FARHANA ALLYSA BINTI MD FADLI',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 20),
              
              _buildStepRow(
                step: 'Langkah 2 & 3',
                title: 'Hantar Pesanan & Bukti',
                icon: HugeIcons.strokeRoundedWhatsapp,
                color: const Color(0xFF25D366),
              ),
              const SizedBox(height: 16),
              
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
      ),
    );
  }

  Widget _buildStepRow({required String step, required String title, required dynamic icon, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: icon is IconData 
            ? Icon(icon, color: color, size: 18)
            : HugeIcon(icon: icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ],
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
