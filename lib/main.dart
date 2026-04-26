import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'staff_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wazeallszgpiasinsjzi.supabase.co',
    anonKey: 'sb_publishable_0mYxWKXT0gnLwun9OmKzuQ_7qZSJmoh',
  );

  runApp(const NachozyyyApp());
}

class NachozyyyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  const NachozyyyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isStaff = user?.userMetadata?['is_staff'] == true;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'NACHOZYYY',
          themeMode: currentMode,
          theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange,
          secondary: Colors.amber,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange,
          secondary: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.deepOrange,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          color: Colors.grey.shade900,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
        home: isStaff ? const StaffDashboard() : const HomePage(),
      );
    },
  );
}
}
