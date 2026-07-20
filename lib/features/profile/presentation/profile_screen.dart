import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/user_provider.dart';
import '../domain/reviews_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final reviewsAsync = ref.watch(reviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              color: AppColors.primary,
              width: double.infinity,
              child: userAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.white)),
                error: (e, _) => Text('Error loading profile: $e', style: const TextStyle(color: Colors.white)),
                data: (user) {
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.white,
                        backgroundImage: user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
                        child: user.imageUrl == null ? const Icon(Icons.person, size: 64, color: AppColors.primary) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agent ID: AG-${user.agentId}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          user.roleType,
                          style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Performance Cards (Ratings overview)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Average Rating', style: TextStyle(color: AppColors.greyDarker, fontSize: 13)),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: AppColors.yellow, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  userAsync.valueOrNull?.rating ?? '0.0',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('out of 5.0 (${userAsync.valueOrNull?.reviewCount ?? 0} reviews)', style: const TextStyle(color: AppColors.greyDark, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(height: 60, width: 1, color: AppColors.grey),
                      const Expanded(
                        child: Column(
                          children: [
                            Text('Completion Rate', style: TextStyle(color: AppColors.greyDarker, fontSize: 13)),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.green, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  '97.2%',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text('24 consignments failed', style: TextStyle(color: AppColors.greyDark, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Reviews history list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Feedback & Reviews',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  reviewsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading reviews: $e'),
                    data: (reviews) {
                      if (reviews.isEmpty) return const Text('No reviews found.');
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final item = reviews[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: List.generate(
                                          5,
                                          (starIdx) => Icon(
                                            Icons.star,
                                            size: 16,
                                            color: starIdx < item.rating ? AppColors.yellow : AppColors.grey,
                                          ),
                                        ),
                                      ),
                                      Text(item.date, style: const TextStyle(color: AppColors.greyDark, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.comment,
                                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
