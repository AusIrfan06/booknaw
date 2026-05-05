
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient('YOUR_URL', 'YOUR_KEY');
  
  final bizRes = await supabase.from('businesses').select().count(CountOption.exact);
  print('Business count: ${bizRes.count}');
  
  final orderRes = await supabase.from('orders').select().count(CountOption.exact);
  print('Order count: ${orderRes.count}');
  
  final lastOrder = await supabase.from('orders').select().order('created_at', ascending: false).limit(1).maybeSingle();
  print('Last order: $lastOrder');
}
