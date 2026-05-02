import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'supabase_service.dart';

LiquidGlassSettings _getGlassSettings(bool isDark) {
  return LiquidGlassSettings(
    thickness: 0.1, blur: 15, refractiveIndex: 1.0,
    glassColor: Colors.transparent, lightAngle: 45.0,
    lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
    saturation: 1.0, chromaticAberration: 0.0,
  );
}

class InventoryManagementPage extends StatefulWidget {
  const InventoryManagementPage({super.key});

  @override
  State<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _products = [];
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final business = await SupabaseService.getBusinessInfo();
      debugPrint("DEBUG: Fetching products for Business ID: ${business?['id']}");

      if (business != null) {
        final businessId = business['id'];
        final user = Supabase.instance.client.auth.currentUser;
        
        // Fetch Staff (join with users to get name)
        final staffRes = await Supabase.instance.client
            .from('staff')
            .select('*, users:user_id(full_name, email)')
            .eq('business_id', businessId);
        
        // Fetch Products
        final productRes = await Supabase.instance.client
            .from('products')
            .select()
            .eq('business_id', businessId)
            .order('created_at', ascending: false);

        debugPrint("DEBUG: Found ${productRes.length} products");

        if (mounted) {
          setState(() {
            _isOwner = business['owner_id'] == user?.id;
            _staff = List<Map<String, dynamic>>.from(staffRes);
            _products = List<Map<String, dynamic>>.from(productRes);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching inventory data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddProductPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductFormPopup(
        isOwner: _isOwner,
        onSaved: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchData();
        },
      ),
    );
  }

  void _showAddStaffPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StaffInvitePopup(
        onInvited: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFFFF5722),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: STAFF MANAGEMENT (TOP) ---
            _buildSectionHeader(
              "Pengurusan Staf", 
              HugeIcons.strokeRoundedUserGroup, 
              _isOwner ? _showAddStaffPopup : null // Only owner can add staff
            ),
            const SizedBox(height: 16),
            _buildStaffList(isDark),

            const SizedBox(height: 40),

            // --- SECTION 2: PRODUCT INVENTORY (BOTTOM) ---
            _buildSectionHeader("Inventori Produk", HugeIcons.strokeRoundedPackage, _showAddProductPopup),
            const SizedBox(height: 16),
            _buildProductGrid(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic icon, VoidCallback? onAdd) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5722).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Spacer(),
        if (onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF5722), size: 28),
          )
      ],
    );
  }

  Widget _buildStaffList(bool isDark) {
    if (_staff.isEmpty) {
      return _buildEmptyState(isDark, "Tiada staf lagi. Jemput staf anda!", HugeIcons.strokeRoundedUserGroup);
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _staff.length,
        itemBuilder: (context, index) {
          final person = _staff[index];
          return GestureDetector(
            onLongPress: _isOwner ? () => _confirmDeleteStaff(person) : null,
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  GlassContainer(
                    useOwnLayer: true,
                    quality: GlassQuality.standard,
                    shape: LiquidRoundedSuperellipse(borderRadius: 999),
                    settings: _getGlassSettings(isDark),
                    child: Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: person['image_url'] != null 
                          ? ClipOval(child: Image.network(person['image_url'], fit: BoxFit.cover, width: 64, height: 64))
                          : HugeIcon(icon: HugeIcons.strokeRoundedUser, color: const Color(0xFFFF5722), size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    person['users']?['full_name'] ?? person['email']?.split('@')[0] ?? "Staf",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    person['role'] ?? "Ahli",
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteStaff(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Padam Staf?"),
        content: Text("Adakah anda pasti mahu memadam ${staff['full_name']} daripada perniagaan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.from('staff').delete().eq('id', staff['id']);
              _fetchData();
            }, 
            child: const Text("Padam", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(bool isDark) {
    if (_products.isEmpty) {
      return _buildEmptyState(isDark, "Tiada produk lagi. Tambah sekarang!", HugeIcons.strokeRoundedPackage);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final bool isLowStock = (product['stock'] ?? 0) < 10;

        return GestureDetector(
          onTap: () => _showEditProductPopup(product),
          child: GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            shape: LiquidRoundedSuperellipse(borderRadius: 24),
            settings: _getGlassSettings(isDark),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(product['image_url'], fit: BoxFit.cover))
                        : const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedPackage, color: Color(0xFFFF5722), size: 40)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product['name'] ?? "Produk",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLowStock ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${product['stock'] ?? 0} unit",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "RM ${(product['price'] ?? 0).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF5722), fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditProductPopup(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductFormPopup(
        product: product,
        isOwner: _isOwner,
        onSaved: () => _fetchData(),
        onDeleted: () => _fetchData(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message, dynamic icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: Colors.grey.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

}

// ─── HELPER POPUPS ──────────────────────────────────────────────────────────

class _ProductFormPopup extends StatefulWidget {
  final Map<String, dynamic>? product;
  final bool isOwner;
  final VoidCallback onSaved;
  final VoidCallback? onDeleted;

  const _ProductFormPopup({this.product, required this.isOwner, required this.onSaved, this.onDeleted});

  @override
  State<_ProductFormPopup> createState() => _ProductFormPopupState();
}

class _ProductFormPopupState extends State<_ProductFormPopup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _skuController;
  late TextEditingController _categoryController;
  
  XFile? _selectedImage;
  final _picker = ImagePicker();
  
  // Variations
  List<Map<String, dynamic>> _variations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['name']);
    _descController = TextEditingController(text: widget.product?['description']);
    _priceController = TextEditingController(text: widget.product?['price']?.toString());
    _stockController = TextEditingController(text: widget.product?['stock']?.toString() ?? '0');
    _skuController = TextEditingController(text: widget.product?['sku']);
    _categoryController = TextEditingController(text: widget.product?['category']);
    
    // Initialize variations if editing
    if (widget.product != null && widget.product!['variations'] != null) {
      _variations = List<Map<String, dynamic>>.from(widget.product!['variations']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
      maxWidth: 1080,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  void _addVariation() {
    setState(() {
      _variations.add({
        'name': '',
        'price': _priceController.text,
        'image_url': null,
        'file': null, // Temporary for new uploads
      });
    });
  }

  Future<void> _pickVariationImage(int index) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
      maxWidth: 1080,
    );
    if (image != null) {
      setState(() {
        _variations[index]['file'] = image;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final business = await SupabaseService.getBusinessInfo();
      if (business == null) throw "Perniagaan tidak dijumpai.";

      String? mainImageUrl = widget.product?['image_url'];
      if (_selectedImage != null) {
        mainImageUrl = await SupabaseService.uploadProductImage(_selectedImage);
      }

      // Handle Variation Image Uploads
      for (int i = 0; i < _variations.length; i++) {
        if (_variations[i]['file'] != null) {
          final url = await SupabaseService.uploadProductImage(_variations[i]['file']);
          _variations[i]['image_url'] = url;
          _variations[i].remove('file'); // Remove the file object before saving to DB
        }
      }

      // Clean up variations (remove temporary 'file' objects)
      final cleanedVariations = _variations.map((v) {
        final newV = Map<String, dynamic>.from(v);
        newV.remove('file');
        return newV;
      }).toList();

      final data = {
        'business_id': business['id'],
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'sku': _skuController.text.trim(),
        'category': _categoryController.text.trim(),
        'image_url': mainImageUrl,
        'variations': cleanedVariations,
        // Removed the 'updated_at' key to match your SQL schema
      };

      if (widget.product == null) {
        await Supabase.instance.client.from('products').insert(data);
      } else {
        await Supabase.instance.client.from('products').update(data).eq('id', widget.product!['id']);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ralat Simpan: $e"),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.product == null) return;
    setState(() => _isLoading = true);
    try {
      // 1. Cleanup images from storage
      if (widget.product!['image_url'] != null) {
        await SupabaseService.deleteProductImage(widget.product!['image_url']);
      }
      final variations = widget.product!['variations'] as List? ?? [];
      for (var v in variations) {
        if (v['image_url'] != null) {
          await SupabaseService.deleteProductImage(v['image_url']);
        }
      }

      // 2. Delete database record
      await Supabase.instance.client.from('products').delete().eq('id', widget.product!['id']);
      widget.onDeleted?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ralat: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 32),
        settings: LiquidGlassSettings(thickness: 0.2, blur: 40), // HIGH BLUR
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.product == null ? "Tambah Produk" : "Edit Produk", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (widget.product != null && widget.isOwner)
                      IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline, color: Colors.red)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      // --- IMAGE PICKER ---
                      _buildImageSection(isDark),
                      const SizedBox(height: 32),

                      _buildField("Nama Produk", _nameController, HugeIcons.strokeRoundedPackage),
                      const SizedBox(height: 16),
                      _buildField("Deskripsi", _descController, HugeIcons.strokeRoundedTextSelection, maxLines: 3),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildField("Harga Dasar (RM)", _priceController, HugeIcons.strokeRoundedWallet01, keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildField("Stok", _stockController, HugeIcons.strokeRoundedArchive01, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildField("SKU / Kod", _skuController, HugeIcons.strokeRoundedShoppingBag01),
                      const SizedBox(height: 16),
                      _buildField("Kategori", _categoryController, HugeIcons.strokeRoundedLayers01),
                      
                      const SizedBox(height: 32),
                      // --- VARIATIONS SECTION ---
                      _buildVariationsHeader(),
                      const SizedBox(height: 16),
                      ..._buildVariationsList(isDark),
                      
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Simpan Produk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5722).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: _selectedImage != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(24), child: kIsWeb ? Image.network(_selectedImage!.path, fit: BoxFit.cover) : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
          : (widget.product?['image_url'] != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(widget.product!['image_url'], fit: BoxFit.cover))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: Color(0xFFFF5722), size: 32),
                    const SizedBox(height: 8),
                    Text("Tambah Gambar Utama", style: TextStyle(color: const Color(0xFFFF5722).withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                  ],
                )),
      ),
    );
  }

  Widget _buildVariationsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Variasi Produk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton.icon(
          onPressed: _addVariation, 
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF5722), size: 20),
          label: const Text("Tambah Variasi", style: TextStyle(color: Color(0xFFFF5722))),
        ),
      ],
    );
  }

  List<Widget> _buildVariationsList(bool isDark) {
    return List.generate(_variations.length, (index) {
      final variation = _variations[index];
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Variation Image
                GestureDetector(
                  onTap: () => _pickVariationImage(index),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: variation['file'] != null 
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.network(variation['file'].path, fit: BoxFit.cover) : Image.file(File(variation['file'].path), fit: BoxFit.cover))
                      : (variation['image_url'] != null 
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(variation['image_url'], fit: BoxFit.cover))
                          : const Icon(Icons.add_a_photo_outlined, color: Color(0xFFFF5722), size: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _buildSmallField("Nama (cth: Saiz M)", (v) => _variations[index]['name'] = v, initialValue: variation['name']),
                      const SizedBox(height: 8),
                      _buildSmallField("Harga (RM)", (v) => _variations[index]['price'] = v, initialValue: variation['price']?.toString(), keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _variations.removeAt(index)), 
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSmallField(String hint, Function(String) onChanged, {String? initialValue, TextInputType? keyboardType}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, dynamic icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
          decoration: InputDecoration(
            prefixIcon: Padding(padding: const EdgeInsets.all(12), child: HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20)),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _StaffInvitePopup extends StatefulWidget {
  final VoidCallback onInvited;
  const _StaffInvitePopup({required this.onInvited});

  @override
  State<_StaffInvitePopup> createState() => _StaffInvitePopupState();
}

class _StaffInvitePopupState extends State<_StaffInvitePopup> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final business = await SupabaseService.getBusinessInfo();
      if (business == null) throw "Perniagaan tidak dijumpai.";

      // 1. Check if user exists in auth.users (via a RPC or a search)
      // For this demo, we simulate finding the user or just adding them if they exist in public.users
      final userRes = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (userRes == null) {
        throw "Pengguna dengan emel ini tidak berdaftar di BookNaw.";
      }

      // 2. Add to staff table
      await Supabase.instance.client.from('staff').insert({
        'business_id': business['id'],
        'user_id': userRes['id'],
        'email': email,
        'role': 'Staff',
        'status': 'Active',
      });

      widget.onInvited();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Staf berjaya ditambah!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ralat: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 32),
        settings: LiquidGlassSettings(thickness: 0.2, blur: 50),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const HugeIcon(icon: HugeIcons.strokeRoundedMail01, color: Color(0xFFFF5722), size: 48),
              const SizedBox(height: 16),
              const Text("Tambah Staf", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Masukkan emel berdaftar untuk menjemput staf anda.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Emel Staf",
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF5722)),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _invite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Jemput Staf", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

