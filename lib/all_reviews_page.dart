import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'add_review_page.dart';

class AllReviewsPage extends StatelessWidget {
  const AllReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reviewsStream = Supabase.instance.client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 5 : (width > 900 ? 4 : (width > 600 ? 3 : 2));

    return Scaffold(
      appBar: AppBar(title: const Text('Semua Review Pelanggan')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: reviewsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return const Center(child: Text('Tiada review lagi.'));
            }
            return MasonryGridView.count(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final rating = review['rating'] as int? ?? 5;
                final imageUrl = review['image_url'] as String?;
                final hasImage = imageUrl != null && imageUrl.isNotEmpty;

                return GlassContainer(
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                  shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                  settings: LiquidGlassSettings(
                    thickness: 0.1,
                    blur: 15,
                    glassColor: isDark
                        ? const Color(0xFFFF5722).withValues(alpha: 0.08)
                        : const Color(0xFFFF5722).withValues(alpha: 0.04),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasImage)
                        AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.format_quote_rounded, color: Color(0xFFFF5722), size: 24),
                              const Spacer(),
                              ...List.generate(5, (i) => Icon(
                                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 16,
                              )),
                            ],
                          ),
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['comment'] ?? 'Tiada komen.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: const Color(0xFFFF5722).withValues(alpha: 0.2),
                                  child: const Icon(Icons.person, size: 12, color: Color(0xFFFF5722)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    review['customer_name'] ?? 'Pelanggan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // You could navigate to add review here if you want a general button
        },
        backgroundColor: const Color(0xFFFF5722),
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }
}
