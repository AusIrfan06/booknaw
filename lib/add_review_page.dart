import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:hugeicons/hugeicons.dart';
import 'utils/glass_toast.dart';

class AddReviewPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const AddReviewPage({super.key, required this.order});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  int _rating = 5;
  final _commentController = TextEditingController();
  XFile? _selectedFile;
  bool _isUploading = false;
  bool _alreadyReviewed = false;
  bool _isLoadingCheck = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  Future<void> _checkExistingReview() async {
    try {
      final orderId = int.tryParse(widget.order['id'].toString());
      if (orderId == null) return;

      final existing = await Supabase.instance.client
          .from('reviews')
          .select('id')
          .eq('order_id', orderId)
          .maybeSingle();
      
      if (existing != null) {
        setState(() {
          _alreadyReviewed = true;
          _isLoadingCheck = false;
        });
      } else {
        setState(() => _isLoadingCheck = false);
      }
    } catch (e) {
      setState(() => _isLoadingCheck = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (file != null) {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      showGlassToast(context, 'Sila tulis komen anda!', isError: true);
      return;
    }

    if (_alreadyReviewed) {
      showGlassToast(context, 'Anda telah pun memberi review untuk pesanan ini.', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      // Double check existence before insert
      final orderId = int.tryParse(widget.order['id'].toString());
      if (orderId == null) throw 'ID Pesanan tidak sah.';

      final existing = await Supabase.instance.client
          .from('reviews')
          .select('id')
          .eq('order_id', orderId)
          .maybeSingle();
      
      if (existing != null) {
        throw 'Anda telah pun memberi review untuk pesanan ini.';
      }

      String? mediaUrl;

      // 1. Upload Media if selected
      if (_selectedFile != null) {
        final fileExtension = _selectedFile!.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final path = 'review_images/$fileName';

        try {
          final bytes = await _selectedFile!.readAsBytes();
          await Supabase.instance.client.storage
              .from('reviews')
              .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$fileExtension'));
          
          mediaUrl = Supabase.instance.client.storage
              .from('reviews')
              .getPublicUrl(path);
        } catch (e) {
          throw 'Gagal memuat naik imej. Sila pastikan bucket "reviews" adalah Public di Supabase.';
        }
      }

      // 2. Save to Database
      await Supabase.instance.client.from('reviews').insert({
        'order_id': orderId,
        'user_id': user?.id,
        'customer_name': user?.userMetadata?['full_name'] ?? 'Pelanggan',
        'rating': _rating,
        'comment': comment,
        'image_url': mediaUrl,
      });

      if (mounted) {
        showGlassToast(context, 'Review berjaya dihantar! Terima kasih!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showGlassToast(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingCheck) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tambah Review')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_alreadyReviewed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tambah Review')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Review Dihantar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda telah pun memberikan review untuk pesanan ini. Terima kasih!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Order Summary Card
            _buildOrderCard(isDark),
            const SizedBox(height: 32),

            // Star Rating
            const Text('Berikan Penarafan:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => IconButton(
                icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 40),
                onPressed: () => setState(() => _rating = i + 1),
              )),
            ),
            const SizedBox(height: 32),

            // Comment Box
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Kongsikan pengalaman anda...',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Image Preview
            if (_selectedFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb 
                  ? Image.network(_selectedFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(_selectedFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedFile = null),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Buang Gambar', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
            ] else 
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Tambah Gambar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

            const SizedBox(height: 48),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Hantar Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pesanan #${widget.order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(widget.order['delivery_option'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
