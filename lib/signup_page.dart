import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _staffCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isStaffRegistration = false;
  bool _obscurePassword = true;
  bool _obscureStaffCode = true;
  bool _usePhone = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      bool isStaff = false;
      if (_isStaffRegistration) {
        if (_staffCodeController.text != 'ENT300') {
          throw Exception('Kod Staff tidak sah!');
        }
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
              SwitchListTile(
                title: const Text('Saya adalah Staff ENT300'),
                value: _isStaffRegistration,
                onChanged: (val) => setState(() => _isStaffRegistration = val),
                secondary: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              if (_isStaffRegistration) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _staffCodeController,
                  decoration: InputDecoration(
                    labelText: 'Kod Rahsia Staff',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedShield01,
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
              ],
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
