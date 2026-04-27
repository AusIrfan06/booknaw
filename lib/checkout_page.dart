import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:image_picker/image_picker.dart';

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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  File? _receiptFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata;
      _nameController.text = meta?['full_name'] ?? '';
      _phoneController.text = meta?['phone'] ?? '';
    }
  }

  Future<void> _pickReceipt() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() => _receiptFile = File(file.path));
    }
  }

  bool get _isDelivery => widget.deliveryOption.startsWith('Delivery');

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? receiptUrl;
      if (_receiptFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_receipt.jpg';
        final path = 'receipts/$fileName';
        await Supabase.instance.client.storage.from('media').upload(path, _receiptFile!);
        receiptUrl = Supabase.instance.client.storage.from('media').getPublicUrl(path);
      }

      final response = await Supabase.instance.client.from('orders').insert({
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'customer_name': _nameController.text,
        'phone_number': _phoneController.text,
        'delivery_address': _isDelivery ? _addressController.text.trim() : null,
        'hot_quantity_100g': widget.hotQuantity,
        'bbq_quantity_100g': widget.bbqQuantity,
        'cheese_quantity': widget.cheeseQuantity,
        'delivery_option': widget.deliveryOption,
        'total_price': widget.totalPrice,
        'payment_status': 'Pending Payment',
        'receipt_url': receiptUrl,
      }).select().single();

      final orderId = response['id'];

      // Determine locId from delivery option
      int locId = 1;
      if (widget.deliveryOption.contains('Alpha')) locId = 1;
      else if (widget.deliveryOption.contains('Beta')) locId = 2;
      else if (widget.deliveryOption.contains('Gamma')) locId = 3;
      else if (widget.deliveryOption.contains('NR')) locId = 4;

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
      final name = _nameController.text;
      final phone = _phoneController.text;
      final hot = widget.hotQuantity > 0 ? 'HOT & SPICYYY x${widget.hotQuantity}' : '';
      final bbq = widget.bbqQuantity > 0 ? 'BBQ x${widget.bbqQuantity}' : '';
      final cheese = widget.cheeseQuantity > 0 ? 'Cheese Dip x${widget.cheeseQuantity}' : '';
      final items = [hot, bbq, cheese].where((s) => s.isNotEmpty).join(', ');
      final total = 'RM ${widget.totalPrice.toStringAsFixed(2)}';
      final location = widget.deliveryOption;

      final waMessage = Uri.encodeComponent(
        'Assalamualaikum Lysa Saya baru buat pesanan NACHOZYY!\n\n'
        '*ID Pesanan: #$orderId*\n'
        'Nama: $name\n'
        'No. Tel: $phone\n'
        'Pesanan: $items\n'
        'Lokasi: $location\n'
        '${_isDelivery ? "Alamat: ${_addressController.text.trim()}\n" : ""}'
        'Jumlah: $total\n\n'
        '${receiptUrl != null ? "Bukti Pembayaran: $receiptUrl\n\n" : ""}'
        'Sila semak resit pembayaran saya ya! Terima kasih',
      );
      const lysaNumber = '60132163194'; // Lysa - Beta & Gamma
      final waUrl = Uri.parse('https://wa.me/$lysaNumber?text=$waMessage');

      _showPaymentSheet(context, waUrl, orderId.toString());
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

  void _showPaymentSheet(BuildContext context, Uri waUrl, String orderId) {
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
            Text(
              'Pesanan #$orderId Berjaya!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  try {
                    await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint('Could not launch WhatsApp: $e');
                  }
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
              const SizedBox(height: 16),
              GlassContainer(
                useOwnLayer: true,
                quality: GlassQuality.standard,
                shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
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
                  margin: EdgeInsets.zero,
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
                        if (widget.cheeseQuantity > 0) _buildSummaryRow('Cheese Dip', '${widget.cheeseQuantity} unit'),
                        _buildSummaryRow('Lokasi', widget.deliveryOption),
                        const Divider(),
                        _buildSummaryRow('Jumlah Bayaran', 'RM ${widget.totalPrice.toStringAsFixed(2)}', isBold: true),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Maklumat Hubungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 12, color: Colors.deepOrange),
                        SizedBox(width: 4),
                        Text(
                          'Boleh diubah',
                          style: TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sila sahkan maklumat anda di bawah. Anda boleh menukar nama atau no. telefon jika perlu.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
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
              if (_isDelivery) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Penghantaran',
                    hintText: 'Cth: Blok B, Bilik 203, UiTM...',
                    prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedMapsLocation01, color: Colors.grey, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Sila masukkan alamat penghantaran' : null,
                ),
              ],
              const SizedBox(height: 32),

              // Step 1: Payment Selection & QR
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.withValues(alpha: 0.5), Colors.blue.withValues(alpha: 0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: GlassContainer(
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                  shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                  settings: LiquidGlassSettings(
                    thickness: 0.1,
                    blur: 15,
                    glassColor: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.qr_code_scanner, color: Colors.green, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Langkah 1', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                Text('Imbas QR & Bayar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/qr_payment.png',
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SITI FARHANA ALLYSA BINTI MD FADLI',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'DuitNow / QR Pay',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Sila pastikan jumlah bayaran tepat',
                            style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Step 2: Receipt Upload
              const Row(
                children: [
                  Icon(Icons.receipt_long, size: 24, color: Colors.orange),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Langkah 2', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text('Muat Naik Resit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Selepas bayaran dibuat, sila muat naik resit di bawah sebagai bukti.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickReceipt,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _receiptFile != null ? Colors.green.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: _receiptFile != null 
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14), 
                            child: Image.file(_receiptFile!, fit: BoxFit.cover),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12, 
                            top: 12, 
                            child: IconButton.filled(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20), 
                              onPressed: () => setState(() => _receiptFile = null),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.check_circle, color: Colors.white, size: 48),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 32),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Klik untuk muat naik resit pembayaran',
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          const Text(
                            'Format: JPG, PNG (Max 5MB)',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                ),
              ),

              const SizedBox(height: 40),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.green.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ) 
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded),
                          SizedBox(width: 12),
                          Text('Sahkan Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
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
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
