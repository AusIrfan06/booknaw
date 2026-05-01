import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'all_reviews_page.dart';
import 'order_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String title;
  final String price;
  final String description;
  final Color themeColor;

  const ProductDetailPage({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.themeColor,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            // ── Left: Image Section ───────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.themeColor,
                          widget.themeColor.withValues(alpha: 0.5),
                          isDark ? const Color(0xFF121212) : Colors.white,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: widget.title,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPackage,
                          size: 250,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Right: Details Section ────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Container(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: _buildDetailsContent(context, isDark),
                      ),
                    ),
                    _buildBottomBar(context, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: Standard Sliver Layout ───────────────────────────────────────
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: widget.themeColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.themeColor,
                          widget.themeColor.withValues(alpha: 0.5),
                          isDark ? const Color(0xFF121212) : Colors.white,
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Hero(
                      tag: widget.title,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedPackage,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: GlassContainer(
                      useOwnLayer: true,
                      quality: GlassQuality.standard,
                      shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
                      settings: LiquidGlassSettings(thickness: 0.2, blur: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Row(
                          children: [
                             Icon(Icons.star, color: Colors.amber, size: 18),
                             SizedBox(width: 4),
                             Text('4.9 (120+)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildDetailsContent(context, isDark),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context, isDark),
    );
  }

  Widget _buildDetailsContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kategori: Nachos Premium',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              widget.price,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF5722),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Deskripsi Produk',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Maklumat Tambahan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _infoCard(HugeIcons.strokeRoundedFire, 'Tahap Pedas', 'Ekstrem', Colors.red),
              _infoCard(HugeIcons.strokeRoundedTimer01, 'Tempoh Sedia', '5-10 min', Colors.blue),
              _infoCard(HugeIcons.strokeRoundedVegetarianFood, 'Asli', 'Tanpa MSG', Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'Kuantiti',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _quantityBtn(Icons.remove, () {
                    if (_quantity > 1) setState(() => _quantity--);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _quantityBtn(Icons.add, () {
                    setState(() => _quantity++);
                  }),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 24),
        _buildReviewsSection(context, isDark),
        const SizedBox(height: 150),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, bool isDark) {
    final reviewsStream = Supabase.instance.client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Komen Pelanggan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllReviewsPage())),
              child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFFFF5722), fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: reviewsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) return const Text('Belum ada review lagi.', style: TextStyle(color: Colors.grey, fontSize: 12));
            
            return Column(
              children: reviews.take(3).map((r) => _buildMiniReview(r, isDark)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniReview(Map<String, dynamic> review, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review['customer_name'] ?? 'Pelanggan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < (review['rating'] ?? 5) ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber, size: 12,
                )),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(review['comment'] ?? '', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 4),
          Text(_formatDate(review['created_at']), style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tambah ke Troli (Ultra-transparent frosted)
          Expanded(
            child: InkWell(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambah ke troli!'))),
              child: GlassContainer(
                useOwnLayer: true,
                quality: GlassQuality.standard,
                shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
                settings: LiquidGlassSettings(
                  thickness: 0.05, blur: 5,
                  glassColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05),
                ),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
                  ),
                  child: const Center(
                    child: Text(
                      'TAMBAH KE TROLI',
                      style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Beli Sekarang (High-blur orange frosted)
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderPage(
                      initialHot: widget.title == 'HOT & SPICYYY' ? _quantity : 0,
                      initialBbq: widget.title == 'SMOKY BBQ' ? _quantity : 0,
                      initialCheese: widget.title == 'CHEESE DIP' ? _quantity : 0,
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
                  glassColor: const Color(0xFFFF5722).withValues(alpha: 0.7),
                ),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFF5722).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'BELI SEKARANG',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(dynamic icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
