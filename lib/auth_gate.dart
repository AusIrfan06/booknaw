import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'staff_dashboard.dart';
import 'admin_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final session = snapshot.data?.session;
        if (session == null) {
          return const LoginPage();
        }

        final role = session.user.userMetadata?['role'] ?? 'customer';
        
        if (role == 'admin') {
          return const AdminDashboard();
        }
        if (role == 'staff') {
          return const StaffDashboard();
        }
        return const HomePage();
      },
    );
  }
}
