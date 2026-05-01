import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class InventoryManagementPage extends StatefulWidget {
  const InventoryManagementPage({super.key});

  @override
  State<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final business = await SupabaseService.getBusinessInfo();
      if (business != null) {
        final businessId = business['id'];
        
        // Fetch Staff
        final staffRes = await Supabase.instance.client
            .from('staff')
            .select()
            .eq('business_id', businessId);
        
        // Fetch Products
        final productRes = await Supabase.instance.client
            .from('products')
            .select()
            .eq('business_id', businessId);

        setState(() {
          _staff = List<Map<String, dynamic>>.from(staffRes);
          _products = List<Map<String, dynamic>>.from(productRes);
        });
      }
    } catch (e) {
      debugPrint('Error fetching inventory data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECTION 1: STAFF MANAGEMENT (TOP) ---
          _buildSectionHeader("Pengurusan Staf", HugeIcons.strokeRoundedUserGroup, () {
            // Logic to add staff
          }),
          const SizedBox(height: 16),
          _buildStaffList(isDark),

          const SizedBox(height: 40),

          // --- SECTION 2: PRODUCT INVENTORY (BOTTOM) ---
          _buildSectionHeader("Inventori Produk", HugeIcons.strokeRoundedPackage, () {
            // Logic to add product
          }),
          const SizedBox(height: 16),
          _buildProductGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic icon, VoidCallback onAdd) {
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
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF5722), size: 28),
        )
      ],
    );
  }

  Widget _buildStaffList(bool isDark) {
    if (_staff.isEmpty) {
      return _buildEmptyState(isDark, "Tiada staf lagi", HugeIcons.strokeRoundedUserGroup);
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _staff.length,
        itemBuilder: (context, index) {
          final person = _staff[index];
          return Container(
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
                  person['full_name'] ?? "Staf",
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
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(bool isDark) {
    if (_products.isEmpty) {
      return _buildEmptyState(isDark, "Tiada produk lagi", HugeIcons.strokeRoundedPackage);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final bool isLowStock = (product['stock_quantity'] ?? 0) < 10;

        return GlassContainer(
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
                    child: product['image_url'] != null
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
                        "${product['stock_quantity'] ?? 0} unit",
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
        );
      },
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
          Text(message, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  LiquidGlassSettings _getGlassSettings(bool isDark) {
    return LiquidGlassSettings(
      thickness: 0.1, blur: 15, refractiveIndex: 1.0,
      glassColor: Colors.transparent, lightAngle: 45.0,
      lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
      saturation: 1.0, chromaticAberration: 0.0,
    );
  }
}
