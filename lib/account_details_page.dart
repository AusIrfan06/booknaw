import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['full_name'] ?? "";
      _phoneController.text = user.userMetadata?['phone'] ?? "";
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // Update auth metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': name,
            'phone': phone,
          },
        ),
      );

      // Update public.users table
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'full_name': name,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berjaya dikemaskini!'), backgroundColor: Colors.green),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Sila log masuk.")));
    }

    final email = user.email ?? "N/A";
    final isStaff = user.userMetadata?['is_staff'] == true;
    final createdAt = user.createdAt;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Butiran Akaun",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedEdit01, color: const Color(0xFFFF5722), size: 24),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundGlows(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Profile Avatar Placeholder
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildDetailSection(
                    isDark,
                    "Informasi Utama",
                    [
                      _isEditing 
                        ? _buildEditableTile(isDark, HugeIcons.strokeRoundedUser, "Nama Penuh", _nameController)
                        : _buildDetailTile(isDark, HugeIcons.strokeRoundedUser, "Nama Penuh", _nameController.text),
                      _isEditing
                        ? _buildEditableTile(isDark, HugeIcons.strokeRoundedSmartPhone01, "No. Telefon", _phoneController, keyboardType: TextInputType.phone)
                        : _buildDetailTile(isDark, HugeIcons.strokeRoundedSmartPhone01, "No. Telefon", _phoneController.text),
                      _buildDetailTile(isDark, HugeIcons.strokeRoundedMail01, "E-mel", email),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  _buildDetailSection(
                    isDark,
                    "Butiran Sistem",
                    [
                      _buildDetailTile(
                        isDark, 
                        HugeIcons.strokeRoundedUserCircle, 
                        "Peranan", 
                        isStaff ? "Staf Nachozyyy" : "Pelanggan",
                        accentColor: isStaff ? const Color(0xFFFF5722) : Colors.blueAccent,
                      ),
                      _buildDetailTile(
                        isDark, 
                        HugeIcons.strokeRoundedClock01, 
                        "Ahli Sejak", 
                        _formatDate(createdAt),
                      ),
                    ],
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "N/A";
    }
  }

  Widget _buildBackgroundGlows(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.08 : 0.15),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: isDark ? 0.06 : 0.12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(bool isDark, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
          settings: LiquidGlassSettings(
            thickness: 0.1, blur: 15, refractiveIndex: 1.0,
            glassColor: Colors.transparent, lightAngle: 45.0,
            lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
            saturation: 1.0, chromaticAberration: 0.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
                width: 1.0,
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(bool isDark, dynamic icon, String label, String value, {Color? accentColor}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (accentColor ?? (isDark ? Colors.white : Colors.black)).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(
              icon: icon,
              color: accentColor ?? (isDark ? Colors.white : Colors.black87),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value.isEmpty ? "Tiada" : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTile(bool isDark, dynamic icon, String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: const Color(0xFFFF5722), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
