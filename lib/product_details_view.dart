import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class ProductDetailsView extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsView({super.key, required this.product});

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  Map<String, dynamic>? _selectedVariation;
  late List<String> _allImages;

  @override
  void initState() {
    super.initState();
    _prepareImages();
  }

  void _prepareImages() {
    _allImages = [];
    // 1. Main Image
    if (widget.product['image_url'] != null) {
      _allImages.add(widget.product['image_url']);
    }
    
    // 2. Variation Images
    final variations = widget.product['variations'] as List? ?? [];
    for (var v in variations) {
      if (v['image_url'] != null) {
        _allImages.add(v['image_url']);
      }
    }
    
    // If no images at all, add a placeholder
    if (_allImages.isEmpty) {
      _allImages.add(""); // Placeholder
    }
  }

  void _onVariationSelected(Map<String, dynamic> variation) {
    setState(() {
      _selectedVariation = variation;
      
      // If variation has an image, find its index and scroll to it
      if (variation['image_url'] != null) {
        final index = _allImages.indexOf(variation['image_url']);
        if (index != -1) {
          _pageController.animateToPage(
            index, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeInOut
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final variations = widget.product['variations'] as List? ?? [];
    final currentPrice = _selectedVariation != null 
        ? (double.tryParse(_selectedVariation!['price'].toString()) ?? 0.0)
        : (double.tryParse(widget.product['price'].toString()) ?? 0.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- IMAGE CAROUSEL ---
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.width,
                pinned: true,
                backgroundColor: isDark ? Colors.black : Colors.white,
                leading: _buildCircularBackButton(context),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentImageIndex = index),
                        itemCount: _allImages.length,
                        itemBuilder: (context, index) {
                          final img = _allImages[index];
                          return img.isNotEmpty 
                            ? Image.network(img, fit: BoxFit.cover)
                            : Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 100, color: Colors.white));
                        },
                      ),
                      // Indicator
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: Text("${_currentImageIndex + 1} / ${_allImages.length}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- PRODUCT INFO ---
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: isDark ? Colors.black : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "RM ${currentPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFFF5722)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product['name'] ?? "Nama Produk",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatTag(isDark, Icons.star_rounded, "4.8", Colors.amber),
                          const SizedBox(width: 8),
                          _buildStatTag(isDark, Icons.shopping_bag_outlined, "1.2k Terjual", Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- VARIATIONS SECTION ---
              if (variations.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(20),
                    color: isDark ? Colors.black : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Pilihan Variasi", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: variations.map((v) {
                            final isSelected = _selectedVariation == v;
                            return GestureDetector(
                              onTap: () => _onVariationSelected(v),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFFFF5722).withValues(alpha: 0.1) 
                                      : (isDark ? Colors.white10 : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (v['image_url'] != null) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(v['image_url'], width: 20, height: 20, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      v['name'],
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? const Color(0xFFFF5722) : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- DESCRIPTION ---
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(20),
                  color: isDark ? Colors.black : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Deskripsi Produk", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.product['description'] ?? "Tiada deskripsi tersedia.",
                        style: TextStyle(color: Colors.grey[600], height: 1.5),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- BOTTOM ACTIONS ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 999),
        settings: const LiquidGlassSettings(thickness: 0.2, blur: 20),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildStatTag(bool isDark, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          _buildActionButton(HugeIcons.strokeRoundedChat01, "Chat", isDark),
          const SizedBox(width: 12),
          _buildActionButton(HugeIcons.strokeRoundedShoppingCart01, "Troli", isDark),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Beli Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(dynamic icon, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
