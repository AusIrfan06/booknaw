import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// 🟢 GLOBAL GLASSMORPHIC TOAST HELPER
void showGlassToast(BuildContext context, String message, {bool isError = false}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  // Clean message if it's an error
  final displayMessage = isError ? _cleanErrorMessage(message) : message;
  final color = isError ? Colors.redAccent : Colors.green;

  // Clear any existing snackbars so they don't stack up
  ScaffoldMessenger.of(context).removeCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent, // Hides the ugly default black box
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20), // Floats above the bottom
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass blur
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                    color: color,
                    size: 20
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayMessage,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// 🛠️ INTERNAL HELPER TO CLEAN ERROR MESSAGES
String _cleanErrorMessage(String rawMessage) {
  // 1. Remove common technical/localized prefixes
  String msg = rawMessage
      .replaceAll(RegExp(r'^(Ralat|Exception|AuthException|PostgrestException|Ralat daftar|Ralat masuk sebagai tetamu):', caseSensitive: false), '')
      .trim();
  
  // 2. Normalize for matching
  String lowMsg = msg.toLowerCase();

  // 3. Mapping technical errors to user-friendly Malay
  if (lowMsg.contains('invalid login credentials')) {
    return 'E-mel atau kata laluan salah. Sila cuba lagi.';
  }
  if (lowMsg.contains('email not confirmed')) {
    return 'E-mel anda belum disahkan. Sila semak peti masuk anda.';
  }
  if (lowMsg.contains('user already registered') || lowMsg.contains('already exists')) {
    return 'Akaun sudah wujud. Sila log masuk atau gunakan e-mel lain.';
  }
  if (lowMsg.contains('failed host lookup') || lowMsg.contains('network_error') || lowMsg.contains('socketexception') || lowMsg.contains('connection failed')) {
    return 'Tiada sambungan internet. Sila periksa rangkaian anda.';
  }
  if (lowMsg.contains('weak password')) {
    return 'Kata laluan terlalu lemah. Gunakan sekurang-kurangnya 6 aksara.';
  }
  if (lowMsg.contains('user not found')) {
    return 'Pengguna tidak ditemui. Sila daftar akaun baru.';
  }
  if (lowMsg.contains('invalid email')) {
    return 'Format e-mel tidak sah.';
  }
  if (lowMsg.contains('timeout')) {
    return 'Sambungan terputus (Timeout). Sila cuba sebentar lagi.';
  }
  if (lowMsg.contains('rate limit')) {
    return 'Terlalu banyak percubaan. Sila tunggu sebentar sebelum cuba lagi.';
  }
  if (lowMsg.contains('unexpected end of stream')) {
    return 'Masalah rangkaian. Sila cuba lagi.';
  }

  // 4. Fallback: Clean up the remaining technical string
  if (msg.isNotEmpty) {
    // If it starts with a lowercase letter, capitalize it
    if (msg.length > 1) {
      msg = msg[0].toUpperCase() + msg.substring(1);
    }
    // Remove any trailing technical jargon or IDs if possible (simplified)
    return msg;
  }

  return 'Berlaku ralat. Sila cuba lagi.';
}
