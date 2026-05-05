import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'order_page.dart';
import 'status_page.dart';
import 'profile_page.dart';
import 'all_reviews_page.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'utils/glass_toast.dart';
import 'widgets/glass_nav_bar.dart';
import 'widgets/nav_item.dart';
import 'product_detail_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever login/logout happens
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _showUpdatePasswordDialog();
      }
      if (mounted) {
        setState(() {
          // Clamp index in case Pesanan Saya disappears
          _currentIndex = 0;
        });
      }
    });
  }

  void _showUpdatePasswordDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tukar Kata Laluan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sila masukkan kata laluan baru anda.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Laluan Baru',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newPass = controller.text.trim();
              if (newPass.length < 6) {
                showGlassToast(context, 'Minimum 6 aksara!', isError: true);
                return;
              }
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: newPass),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  showGlassToast(context, 'Kata laluan berjaya ditukar!');
                }
              } catch (e) {
                if (context.mounted) {
                  showGlassToast(context, 'Ralat: $e', isError: true);
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null;
    final List<Widget> pages = [
      _HomeTab(onOrder: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderPage()),
        );
      }),
      if (isLoggedIn) const StatusPage(),
      const ProfileSettingsScreen(),
    ];


    // Clamp index in case user just logged out and was on Pesanan Saya
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    final navItems = [
      const NavItem(
        icon: HugeIcons.strokeRoundedHome01,
        title: 'Utama',
      ),
      if (isLoggedIn)
        const NavItem(
          icon: HugeIcons.strokeRoundedTask01,
          title: 'Status',
        ),
      const NavItem(
        icon: HugeIcons.strokeRoundedUser,
        title: 'Profil',
      ),
    ];

    return Scaffold(
      appBar: safeIndex == 0 ? AppBar(
        title: const Text('NACHOZYYY'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ) : null,
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: GlassNavigationBar(
        selectedIndex: safeIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
        items: navItems,
      ),
    );
  }
}


// ─── Home Tab Content ────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {

  final VoidCallback onOrder;
  const _HomeTab({required this.onOrder});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _ads = [
    {
      'title': 'KRUP KRAP EXTREEM NACHOS!',
      'subtitle': 'Paling ranggup di alam semesta!',
      'color1': const Color(0xFFFF5722),
      'color2': const Color(0xFFFF9800),
      'icon': HugeIcons.strokeRoundedFire,
    },
    {
      'title': 'PENGHANTARAN PERCUMA!',
      'subtitle': 'Untuk pesanan atas RM30 sahaja.',
      'color1': const Color(0xFF4CAF50),
      'color2': const Color(0xFF8BC34A),
      'icon': HugeIcons.strokeRoundedDeliveryTruck01,
    },
    {
      'title': 'SALTED EGG SUPREME!',
      'subtitle': 'Nikmati kemewahan rasa telur masin.',
      'color1': const Color(0xFFFFC107),
      'color2': const Color(0xFFFFD54F),
      'icon': HugeIcons.strokeRoundedStars,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _ads.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // â”€â”€ Header Section (Auto-sliding Carousel) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SizedBox(
                  height: 280,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _ads.length,
                    itemBuilder: (context, index) {
                      final ad = _ads[index];
                      return _buildAdCard(ad, isDark);
                    },
                  ),
                ),
                
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _ads.asMap().entries.map((entry) {
                    return Container(
                      width: _currentPage == entry.key ? 20.0 : 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: (isDark ? Colors.white : const Color(0xFFFF5722))
                            .withValues(alpha: _currentPage == entry.key ? 0.9 : 0.2),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
                
                // â”€â”€ Selection Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilihan Hangat',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      MasonryGridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 2),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final products = [
                            (title: 'HOT & SPICYYY', desc: 'Pedas gila, gerenti berpeluh! (100g)', price: 'RM 5.00', color: Colors.redAccent, height: 220.0),
                            (title: 'SMOKY BBQ', desc: 'Rasa salai yang premium. (100g)', price: 'RM 5.00', color: Colors.orangeAccent, height: 260.0),
                            (title: 'CHEESE DIP', desc: 'Sos keju berkrim & padu.', price: 'RM 1.00', color: Colors.amber, height: 200.0),
                            (title: 'SALTED EGG SUPREME', desc: 'Rasa telur masin premium yang mewah.', price: 'RM 12.00', color: Colors.yellow.shade700, height: 280.0),
                          ];
                          final p = products[index];
                          return _buildPinterestCard(
                            context,
                            title: p.title,
                            desc: p.desc,
                            price: p.price,
                            imageColor: p.color,
                            height: p.height,
                            onTap: () {
                              if (p.title == 'SALTED EGG SUPREME') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  title: p.title,
                                  price: p.price,
                                  description: 'Alami kemewahan rasa telur masin yang diadun sempurna dengan kepingan nachos premium. Tekstur berkrim dan rasa umami yang tinggi gerenti membuatkan anda ketagih!',
                                  themeColor: p.color,
                                ),
                                  ),
                                );
                              } else {
                                widget.onOrder();
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      const _ReviewsSection(),
                      const SizedBox(height: 150), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 30.0),
        settings: LiquidGlassSettings(
          thickness: 0.1, blur: 15, refractiveIndex: 1.0,
          glassColor: Colors.transparent, lightAngle: 45.0,
          lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
          saturation: 1.0, chromaticAberration: 0.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ad['color1'], ad['color2']],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.2,
                  child: HugeIcon(icon: ad['icon'], color: Colors.white, size: 150),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad['title'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ad['subtitle'],
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinterestCard(
    BuildContext context, {
    required String title,
    required String desc,
    required String price,
    required Color imageColor,
    required double height,
    required VoidCallback onTap,
  }) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: LiquidGlassSettings(
        thickness: 0.1, blur: 15, refractiveIndex: 1.0,
        glassColor: Colors.transparent, lightAngle: 45.0,
        lightIntensity: isDark ? 0.05 : 0.1, ambientStrength: 1.0,
        saturation: 1.0, chromaticAberration: 0.0,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: height * 0.6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: imageColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: imageColor.withValues(alpha: 0.1))),
                ),
                child: Center(
                  child: HugeIcon(icon: HugeIcons.strokeRoundedPackage, color: imageColor, size: 48),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFF5722))),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFFF5722).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Color(0xFFFF5722), size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reviewsStream = Supabase.instance.client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Komen Pelanggan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllReviewsPage()),
                );
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: reviewsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada review lagi. Jadi yang pertama!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final rating = review['rating'] as int? ?? 5;
                  final imageUrl = review['image_url'] as String?;

                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    child: GlassContainer(
                      useOwnLayer: true,
                      quality: GlassQuality.standard,
                      shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
                      settings: LiquidGlassSettings(
                        thickness: 0.1,
                        blur: 10,
                        glassColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    review['customer_name'] ?? 'Pelanggan',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imageUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 60, height: 60, color: Colors.grey.shade300,
                                            child: const Icon(Icons.image_not_supported, size: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      review['comment'] ?? 'Tiada komen.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(review['created_at']),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
