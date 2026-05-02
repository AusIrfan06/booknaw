import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'utils/glass_toast.dart';

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

      // Fetch first business ID as default
      final bizRes = await Supabase.instance.client.from('businesses').select('id').limit(1).maybeSingle();
      final bizId = bizRes?['id'];

      final response = await Supabase.instance.client.from('orders').insert({
        'business_id': bizId,
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'customer_name': '$fName $lName'.trim(),
        'phone_number': _phoneController.text,
        'delivery_address': _isDelivery ? _addressController.text.trim() : null,
        'hot_quantity_100g': widget.hotQuantity,
        'bbq_quantity_100g': widget.bbqQuantity,
        'cheese_quantity': widget.cheeseQuantity,
        'delivery_option': widget.deliveryOption,
        'total_price': widget.totalPrice,
        'payment_status': 'Pending Payment',
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
      final location = widget.deliveryOption;
      final address = _isDelivery ? _addressController.text.trim() : 'Pickup';

      final waMessage = Uri.encodeComponent(
        'Assalamualaikum Lysa Saya nak order Nachozy!\n\n'
        'No. Pesanan: #$orderId\n'
        'Nama: $name\n'
        'No. Tel: $phone\n'
        'Pesanan: $items\n'
        'Lokasi: $location\n'
        'Alamat: $address\n'
        'Jumlah: $total\n\n'
        'Saya akan hantar bukti pembayaran sekejap lagi ya! Terima kasih',
      );
      const lysaNumber = '60132163194';
      final waUrl = Uri.parse('https://wa.me/$lysaNumber?text=$waMessage');

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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bayaran & Maklumat'),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Contact Info Header ---
              _buildSectionHeader(
                icon: HugeIcons.strokeRoundedUser,
                title: 'Maklumat Peribadi',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _firstNameController,
                label: 'Nama Pertama',
                icon: HugeIcons.strokeRoundedUser,
                isDark: isDark,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                textCapitalization: TextCapitalization.words,
                validator: (val) => val == null || val.isEmpty ? 'Sila masukkan nama pertama' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Nama Akhir',
                icon: HugeIcons.strokeRoundedUser,
                isDark: isDark,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                textCapitalization: TextCapitalization.words,
                validator: (val) => val == null || val.isEmpty ? 'Sila masukkan nama akhir' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'No. Telefon (WhatsApp)',
                icon: HugeIcons.strokeRoundedSmartPhone01,
                isDark: isDark,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Sila masukkan no. telefon' : null,
              ),
              if (_isDelivery) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Alamat Penghantaran',
                  icon: HugeIcons.strokeRoundedMapsLocation01,
                  isDark: isDark,
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Sila masukkan alamat' : null,
                ),
              ],
              
              const SizedBox(height: 32),

              // --- Order Summary Card ---
              _buildModernSummary(isDark),
              
              const SizedBox(height: 32),

              const SizedBox(height: 40),

              // --- Step 1: Payment ---
              _buildStepHeader(
                step: 'Langkah 1',
                title: 'Tangkap Layar QR Code',
                icon: Icons.qr_code_scanner_rounded,
                color: primaryColor,
              ),
              const SizedBox(height: 16),
              _buildQRCodeSection(isDark, primaryColor),

              const SizedBox(height: 40),

              // --- Step 2 & 3: WhatsApp ---
              _buildStepHeader(
                step: 'Langkah 2 & 3',
                title: 'Hantar Pesanan & Bukti',
                icon: HugeIcons.strokeRoundedWhatsapp,
                color: const Color(0xFF25D366),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 48),
                child: Text(
                  '1. Tekan butang di bawah untuk hantar pesanan.\n2. Kemudian, lampirkan (attach) gambar resit di WhatsApp.',
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                ),
              ),

              const SizedBox(height: 48),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sahkan & Pesan Sekarang',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSummary(bool isDark) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: LiquidGlassSettings(
        thickness: 0.1, blur: 15, refractiveIndex: 1.0,
        glassColor: Colors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedShoppingCart01, color: Color(0xFFFF5722), size: 24),
                const SizedBox(width: 12),
                const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            if (widget.hotQuantity > 0) _buildSummaryRow('HOT & SPICYYY', '${widget.hotQuantity} pek'),
            if (widget.bbqQuantity > 0) _buildSummaryRow('BBQ', '${widget.bbqQuantity} pek'),
            if (widget.cheeseQuantity > 0) _buildSummaryRow('Cheese Dip', '${widget.cheeseQuantity} unit'),
            _buildSummaryRow('Lokasi', widget.deliveryOption),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Bayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'RM ${widget.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFF5722)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required dynamic icon, required String title, required bool isDark}) {
    return Row(
      children: [
        HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 24),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStepHeader({required String step, required String title, required dynamic icon, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: icon is IconData 
            ? Icon(icon, color: color, size: 24)
            : HugeIcon(icon: icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/qr_payment.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Column(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('QR Code tidak dapat dimuatkan', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'SITI FARHANA ALLYSA BINTI MD FADLI',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'DuitNow / QR Pay',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sila ambil tangkap layar (screenshot) QR ini',
              style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required dynamic icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
