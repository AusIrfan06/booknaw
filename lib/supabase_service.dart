import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  /// Fetches the profile of the current user from the public.users table.
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching user: $e');
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
      await client.from('users').update(updates).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Fetches all orders (Staff Only).
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await client
          .from('orders')
          .select('*, users(full_name)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching orders: $e');
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
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  /// Registers a new business and promotes the user to owner role.
  static Future<void> registerBusiness({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String type,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      // 1. Insert into businesses table
      await client.from('businesses').insert({
        'owner_id': user.id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'type': type,
      });

      // 2. Update user role to owner
      // We update both the public.users table and the auth metadata
      await client.from('users').update({'role': 'owner'}).eq('id', user.id);
      
      await client.auth.updateUser(UserAttributes(
        data: {'role': 'owner'}
      ));
      
    } catch (e) {
      debugPrint('Error registering business: $e');
      rethrow;
    }
  }

  /// Fetches business information for the current user (if they are an owner).
  static Future<Map<String, dynamic>?> getBusinessInfo() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await client
          .from('businesses')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching business info: $e');
      return null;
    }
  }
}
