import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_logo.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifierController = TextEditingController();
  bool _isLoading = false;
  bool _isPhone = false;

  Future<void> _resetPassword() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sila masukkan ${_isPhone ? "nombor telefon" : "email"} anda!')),
      );
      return;
    }

    if (_isPhone) {
      // Logic for Phone users: Contact Admin via WhatsApp
      final message = Uri.encodeComponent(
          "Hi Ipan, saya terlupa katalaluan untuk akaun Nachozyyy saya (No. Tel: $identifier). Boleh bantu saya set semula?");
      final url = "https://wa.me/601115892468?text=$message"; // Using Ipan's number
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')),
          );
        }
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(identifier);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email Dihantar!'),
            content: const Text(
                'Sila semak peti masuk email anda untuk pautan tetapan semula katalaluan.\n\n'
                'Tip: Jika anda tidak menemui email, sila semak folder SPAM anda.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
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
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Katalaluan')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const AppLogo(size: 80),
              const SizedBox(height: 24),
              const Text(
                'Tetapkan Semula Katalaluan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Email'),
                    selected: !_isPhone,
                    onSelected: (val) => setState(() => _isPhone = !val),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('No. Telefon'),
                    selected: _isPhone,
                    onSelected: (val) => setState(() => _isPhone = val),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _isPhone
                    ? 'Pengguna No. Telefon perlu hubungi Admin via WhatsApp untuk set semula akaun.'
                    : 'Masukkan email anda dan kami akan hantar pautan untuk menukar katalaluan baru.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _identifierController,
                decoration: InputDecoration(
                  labelText: _isPhone ? 'No. Telefon' : 'Email',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: HugeIcon(
                        icon: _isPhone ? HugeIcons.strokeRoundedSmartPhone01 : HugeIcons.strokeRoundedMail01,
                        color: Colors.grey,
                        size: 20),
                  ),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: _isPhone ? TextInputType.phone : TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPhone ? Colors.green : Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isPhone ? 'Hubungi Ipan di WhatsApp' : 'Hantar Pautan Reset',
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
