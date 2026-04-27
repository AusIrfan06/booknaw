import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:hugeicons/hugeicons.dart';

class AddReviewPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const AddReviewPage({super.key, required this.order});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  int _rating = 5;
  final _commentController = TextEditingController();
  File? _mediaFile;
  bool _isVideo = false;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickMedia(bool video) async {
    final XFile? file = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 70,
          );

    if (file != null) {
      setState(() {
        _mediaFile = File(file.path);
        _isVideo = video;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila tulis komen anda!')),
      );
      return;
    }

    // Double check status before submitting
    if (widget.order['status'] != 'Delivered') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hanya pesanan yang telah selesai boleh direview!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      String? mediaUrl;

      if (_mediaFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_mediaFile!.path.split('/').last}';
        final path = 'reviews/$fileName';

        await Supabase.instance.client.storage
            .from('reviews')
            .upload(path, _mediaFile!);
        mediaUrl = Supabase.instance.client.storage
            .from('reviews')
            .getPublicUrl(path);
      }

      await Supabase.instance.client.from('reviews').insert({
        'user_id': user?.id,
        'order_id': widget.order['id'],
        'customer_name': user?.userMetadata?['full_name'] ?? 'Pelanggan',
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'image_url': mediaUrl,
        'is_video': _isVideo,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review berjaya dihantar! Terima kasih!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Info Summary
            _buildOrderInfo(isDark),
            const SizedBox(height: 32),

            const Text(
              'Bagaimana pengalaman anda?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis komen anda di sini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 24),

            // Media Preview
            if (_mediaFile != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _isVideo
                        ? Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          )
                        : Image.file(
                            _mediaFile!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      onPressed: () => setState(() => _mediaFile = null),
                      icon: const CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 14,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickMedia(false),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedImage01,
                      color: Color(0xFFFF5722),
                      size: 20,
                    ),
                    label: const Text('Tambah Gambar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickMedia(true),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedVideo01,
                      color: Color(0xFFFF5722),
                      size: 20,
                    ),
                    label: const Text('Tambah Video'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isUploading ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Hantar Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pesanan Selesai:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            'Order #${widget.order['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            widget.order['delivery_option'] ?? '',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
