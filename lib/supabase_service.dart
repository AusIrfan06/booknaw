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

  /// Updates the current user's profile information in the 'users' or 'profiles' table.
  static Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final updates = {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (fullName != null) 'full_name': fullName,
      if (firstName != null || lastName != null)
        'full_name': '${firstName ?? ''} ${lastName ?? ''}'.trim(),
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      // Update the main users table
      await client.from('users').update(updates).eq('id', user.id);
      
      // Also sync to profiles table for public access if needed
      await client.from('profiles').upsert({'id': user.id, ...updates});
    } catch (e) {
      debugPrint('Error updating user profile: $e');
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

  /// Creates a new order for a specific business.
  static Future<void> createOrder({
    required String businessId,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      await client.from('orders').insert({
        'business_id': businessId,
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

  /// Fetches business information for the current user (Owner or Staff).
  static Future<Map<String, dynamic>?> getBusinessInfo() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Check if user is an owner
      final ownerBusiness = await client
          .from('businesses')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
      
      if (ownerBusiness != null) return ownerBusiness;

      // 2. If not owner, check if user is staff
      final staffEntry = await client
          .from('staff')
          .select('business_id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (staffEntry != null) {
        return await client
            .from('businesses')
            .select()
            .eq('id', staffEntry['business_id'])
            .maybeSingle();
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching business info: $e');
      return null;
    }
  }

  /// Uploads a product image to Supabase Storage.
  static Future<String?> uploadProductImage(dynamic file) async {
    try {
      final fileExtension = file.name.split('.').last;
      final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = 'products/$fileName';

      final bytes = await file.readAsBytes();
      await client.storage
          .from('products')
          .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$fileExtension'));
      
      return client.storage.from('products').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      return null;
    }
  }

  // --- Advanced Inventory Features ---

  /// Adjusts stock for a product and logs the movement
  static Future<void> adjustStock({
    required String productId,
    required int amount,
    required String reason, // e.g., 'Restock' or 'Sales'
  }) async {
    try {
      // 1. Update the actual product stock using RPC
      // Note: requires a 'increment_stock' RPC function in Supabase
      await client.rpc('increment_stock', params: {
        'p_id': productId,
        'amount': amount,
      });

      // 2. Log the movement in the inventory table (treated as log here)
      // Note: We use 'inventory_logs' to avoid clashing with the legacy inventory table
      await client.from('inventory_logs').insert({
        'product_id': productId,
        'change_amount': amount,
        'reason': reason,
      });
    } catch (e) {
      debugPrint("Stock adjustment error: $e");
      rethrow;
    }
  }


  /// Deletes a product image from storage to prevent ghost files
  static Future<void> deleteProductImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      
      await client.storage
          .from('products') 
          .remove([fileName]);
    } catch (e) {
      debugPrint("Cleanup error: $e");
    }
  }
}
