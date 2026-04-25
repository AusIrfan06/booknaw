import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'signup_page.dart';
import 'staff_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      String identifier = _emailController.text.trim();
      
      // If it looks like a phone number (only digits), convert to fake email
      if (RegExp(r'^[0-9]+$').hasMatch(identifier)) {
        identifier = '$identifier@nachos.com';
      }

      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: identifier,
        password: _passwordController.text,
      );
      
      if (mounted) {
        final isStaff = res.session?.user.userMetadata?['is_staff'] == true;
        if (isStaff) {
          // Go to Staff Dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StaffDashboard()),
            (route) => false, // Clears the stack completely
          );
        } else {
          // Just pop back to Home
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat log masuk: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedFire, size: 80, color: Colors.deepOrange),
              const SizedBox(height: 16),
              const Text(
                'Selamat Kembali ke NACHOZYYY!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email atau No. Telefon',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.grey, size: 20),
                  ),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Katalaluan',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, color: Colors.grey, size: 20),
                  ),
                  suffixIcon: IconButton(
                    icon: HugeIcon(
                      icon: _obscurePassword ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView, 
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Log Masuk', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                },
                child: const Text('Belum ada akaun? Daftar sekarang!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
