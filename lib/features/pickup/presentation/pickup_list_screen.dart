import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/pickup_provider.dart';

class PickupListScreen extends ConsumerWidget {
  const PickupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(pickupProvider);

    return pickupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $e'),
            ElevatedButton(
              onPressed: () => ref.read(pickupProvider.notifier).fetchPickups(),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
      data: (pickups) {
        return pickups.isEmpty
            ? const Center(child: Text('No pickups found'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pickups.length,
                itemBuilder: (context, index) {
                  final item = pickups[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => context.push('/pickup/${item.storeId}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Store ID: ${item.storeId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                StatusBadge(status: item.status),
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              item.storeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: AppColors.greyDarker),
                                const SizedBox(width: 8),
                                Text(item.merchantName),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: AppColors.greyDarker),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.address, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Package count:', style: TextStyle(color: AppColors.greyDarker)),
                                Text(
                                  '${item.totalPackages} Parcels',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
      },
    );
  }
}
