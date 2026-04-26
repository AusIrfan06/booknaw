import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  /// Fetches the profile of the current user from the public.profiles table.
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Updates the current user's profile information.
  static Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final updates = {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (firstName != null || lastName != null)
        'full_name': '${firstName ?? ''} ${lastName ?? ''}'.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await client.from('profiles').update(updates).eq('id', user.id);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  /// Fetches all orders (Staff Only).
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await client
          .from('orders')
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  /// Creates a new order.
  static Future<void> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalPrice,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      await client.from('orders').insert({
        'user_id': user.id,
        'items': items,
        'total_price': totalPrice,
        'status': 'pending',
      });
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }
}
