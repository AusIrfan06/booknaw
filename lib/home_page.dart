import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'order_page.dart';
import 'contact_page.dart';
import 'login_page.dart';
import 'staff_dashboard.dart';
import 'status_page.dart';
import 'app_logo.dart';

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
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {
        // Clamp index in case Pesanan Saya disappears
        _currentIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  void _handleProfileTap() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      final isStaff = user.userMetadata?['is_staff'] == true;
      if (isStaff) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StaffDashboard()),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Keluar?'),
            content: const Text('Adakah anda pasti ingin log keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Log Keluar',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    }
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
      const ContactPage(),
    ];

    // Clamp index in case user just logged out and was on Pesanan Saya
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Utama',
      ),
      if (isLoggedIn)
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Pesanan Saya',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        activeIcon: Icon(Icons.chat_bubble_rounded),
        label: 'Hubungi',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NACHOZYYY 🌶️🧀'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: Colors.white,
                size: 24),
            tooltip: 'Profil',
            onPressed: _handleProfileTap,
          ),
        ],
      ),
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const AppLogo(size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Krup Krap, Krup Krap... 👀🔥',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Team HOT 🌶️ atau BBQ 🍖? Pilih ikut craving korang!',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child:
                      const Text('Order Now!', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilihan Perisa ✨',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildFlavorCard(
                  context,
                  title: 'HOT & SPICYYY 🌶️',
                  desc: 'Pedas berapi, memang ada kick!',
                  lightColor: Colors.red.shade100,
                  darkColor: Colors.red.shade900.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 10),
                _buildFlavorCard(
                  context,
                  title: 'BBQ 🍖',
                  desc: 'Smoky & sedap, sekali makan susah nak stop!',
                  lightColor: Colors.orange.shade100,
                  darkColor: Colors.orange.shade900.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlavorCard(
    BuildContext context, {
    required String title,
    required String desc,
    required Color lightColor,
    required Color darkColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      color: isDark ? darkColor : lightColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
