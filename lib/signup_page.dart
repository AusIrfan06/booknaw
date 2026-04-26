import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'app_logo.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _staffCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureStaffCode = true;
  bool _usePhone = false;

  Future<void> _signUp() async {
    if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan nama pertama dan nama akhir!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool isStaff = false;
      if (_staffCodeController.text.trim() == 'STAFFENT300') {
        isStaff = true;
      }

      String identifier = _emailController.text.trim();
      if (_usePhone) {
        if (!RegExp(r'^[0-9]+$').hasMatch(identifier)) {
          throw Exception('Sila masukkan nombor telefon yang sah!');
        }
        identifier = '$identifier@nachos.com';
      }

      await Supabase.instance.client.auth.signUp(
        email: identifier,
        password: _passwordController.text,
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'is_staff': isStaff,
          'phone': _usePhone ? _emailController.text.trim() : null,
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berjaya! Sila log masuk.')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat daftar: $e'),
            backgroundColor: Colors.red,
          ),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _staffCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akaun')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo(size: 60)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pertama',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Akhir',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Daftar menggunakan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Email'),
                    selected: !_usePhone,
                    onSelected: (val) => setState(() => _usePhone = !val),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('No. Telefon'),
                    selected: _usePhone,
                    onSelected: (val) => setState(() => _usePhone = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: _usePhone ? 'No. Telefon' : 'Email',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: HugeIcon(
                      icon: _usePhone
                          ? HugeIcons.strokeRoundedSmartPhone01
                          : HugeIcons.strokeRoundedMail01,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: _usePhone
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Katalaluan (Minimum 6 aksara)',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedLockPassword,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: HugeIcon(
                      icon: _obscurePassword
                          ? HugeIcons.strokeRoundedViewOff
                          : HugeIcons.strokeRoundedView,
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
              const SizedBox(height: 16),
              TextField(
                controller: _staffCodeController,
                decoration: InputDecoration(
                  labelText: 'Kod Promosi / Rujukan (Pilihan)',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedGiftCard,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: HugeIcon(
                      icon: _obscureStaffCode
                          ? HugeIcons.strokeRoundedViewOff
                          : HugeIcons.strokeRoundedView,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureStaffCode = !_obscureStaffCode;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscureStaffCode,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Daftar Sekarang',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
