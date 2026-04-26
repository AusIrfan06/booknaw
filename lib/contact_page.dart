import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launchWhatsApp(String phoneUrl) async {
    final Uri url = Uri.parse('https://$phoneUrl');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hubungi Kami')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ada soalan atau nak order manual? WhatsApp kami terus! 👇',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            _ContactCard(
              name: 'Yan',
              location: 'Alpha',
              phoneUrl: 'wa.me/601112769605',
              onTap: () => _launchWhatsApp('wa.me/601112769605'),
            ),
            const SizedBox(height: 12),
            
            _ContactCard(
              name: 'Izzah',
              location: 'Beta',
              phoneUrl: 'wa.me/60102531607',
              onTap: () => _launchWhatsApp('wa.me/60102531607'),
            ),
            const SizedBox(height: 12),

            _ContactCard(
              name: 'Lysa',
              location: 'Beta & Gamma',
              phoneUrl: 'wa.me/60132163194',
              onTap: () => _launchWhatsApp('wa.me/60132163194'),
            ),
            const SizedBox(height: 12),

            _ContactCard(
              name: 'Alya',
              location: 'NR',
              phoneUrl: 'wa.me/60199973803',
              onTap: () => _launchWhatsApp('wa.me/60199973803'),
            ),
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Thank you so much for supporting our ENT300 project! We truly appreciate it! 💛',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String location;
  final String phoneUrl;
  final VoidCallback onTap;

  const _ContactCard({
    required this.name,
    required this.location,
    required this.phoneUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? Colors.green.shade900.withValues(alpha: 0.5) : Colors.green.shade100,
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedWhatsapp,
            color: isDark ? Colors.greenAccent : Colors.green,
            size: 24.0,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Kawasan: $location'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
