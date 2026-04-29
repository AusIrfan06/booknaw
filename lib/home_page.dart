import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'order_page.dart';
import 'contact_page.dart';
import 'login_page.dart';
import 'staff_dashboard.dart';
import 'status_page.dart';
import 'profile_page.dart';
import 'app_logo.dart';
import 'all_reviews_page.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'utils/glass_toast.dart';
import 'widgets/glass_nav_bar.dart';
import 'widgets/nav_item.dart';

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
                if (mounted) {
                  Navigator.pop(context);
                  showGlassToast(context, 'Kata laluan berjaya ditukar!');
                }
              } catch (e) {
                if (mounted) {
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

  void _handleProfileTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null;
    final pages = [
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


// ─── Home Tab Content ─────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final VoidCallback onOrder;
  const _HomeTab({required this.onOrder});

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
                // ── Header Section ──────────────────────────────────────────────
                GlassContainer(
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
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                          ? [const Color(0xFFFF5722).withValues(alpha: 0.3), const Color(0xFF1E1E1E)] 
                          : [const Color(0xFFFF5722).withValues(alpha: 0.8), const Color(0xFFFF9800).withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 80),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'KRUP KRAP EXTREEM NACHOS!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Paling ranggup di alam semesta!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // ── Order Now Button Section ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: onOrder,
                    borderRadius: BorderRadius.circular(20),
                    child: GlassContainer(
                      useOwnLayer: true,
                      quality: GlassQuality.standard,
                      shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
                      settings: LiquidGlassSettings(thickness: 0.15, blur: 20, glassColor: Colors.white.withValues(alpha: 0.1)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedShoppingCart01, color: Colors.black87, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'ORDER SEKARANG!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // ── Selection Section ───────────────────────────────────────────
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
                      const SizedBox(height: 16),
                      _buildSleekCard(
                        context,
                        title: 'HOT & SPICYYY',
                        desc: 'Pedas gila, gerenti berpeluh! (100g)',
                        price: 'RM 5.00',
                        imageColor: Colors.redAccent,
                        onTap: onOrder,
                      ),
                      const SizedBox(height: 16),
                      _buildSleekCard(
                        context,
                        title: 'SMOKY BBQ',
                        desc: 'Rasa salai yang premium. (100g)',
                        price: 'RM 5.00',
                        imageColor: Colors.orangeAccent,
                        onTap: onOrder,
                      ),
                      const SizedBox(height: 16),
                      _buildSleekCard(
                        context,
                        title: 'CHEESE DIP',
                        desc: 'Sos keju berkrim & padu.',
                        price: 'RM 1.00',
                        imageColor: Colors.amber,
                        onTap: onOrder,
                      ),
                      const SizedBox(height: 32),
                      const _ReviewsSection(),
                      const SizedBox(height: 150), // Further increased for tap clearance
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

  Widget _buildSleekCard(
    BuildContext context, {
    required String title,
    required String desc,
    required String price,
    required Color imageColor,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: imageColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: imageColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: HugeIcon(icon: HugeIcons.strokeRoundedPackage, color: imageColor, size: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                    const SizedBox(height: 12),
                    Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFFF5722))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFF5722), borderRadius: BorderRadius.circular(12)),
                child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white, size: 20),
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
