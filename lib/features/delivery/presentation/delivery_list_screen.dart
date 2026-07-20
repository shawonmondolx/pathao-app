import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/delivery_provider.dart';

class DeliveryListScreen extends ConsumerStatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  ConsumerState<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends ConsumerState<DeliveryListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesState = ref.watch(deliveryProvider);

    return Scaffold(
      backgroundColor: AppColors.white, // Makes status bar area white
      body: SafeArea(
        bottom: false,
        child: Container(
          color: AppColors.black, // Makes the rest of the screen black
          child: Column(
            children: [
              // Top White Curved Section for Today's Collection
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: deliveriesState.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                  ),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    "TODAY'S COLLECTION\n--",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.greyDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                data: (deliveryState) => Center(
                  child: Column(
                    children: [
                      const Text(
                        "TODAY'S COLLECTION",
                        style: TextStyle(
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${deliveryState.collection.totalCollected.toInt()} / ${deliveryState.collection.totalCollectable.toInt()}",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.greyDarkest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

  
            // Search Bar & Scan Button Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {}),
                        style: const TextStyle(color: AppColors.greyDarkest, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Search Number / Consignment',
                          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: AppColors.greyDark),
                          fillColor: AppColors.white,
                          filled: true,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Scan button box
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.black, size: 22),
                      onPressed: () => context.push('/scanner'),
                    ),
                  ),
                ],
              ),
            ),
    
            // List Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  deliveriesState.when(
                    loading: () => const Text(
                      'DELIVERY LIST',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3F51B5)),
                    ),
                    error: (_, __) => const Text(
                      'DELIVERY LIST',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3F51B5)),
                    ),
                    data: (deliveryState) => Text(
                      'DELIVERY LIST (${deliveryState.orders.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3F51B5), letterSpacing: 0.5),
                    ),
                  ),
                  // Sort button
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.greyDark),
                        foregroundColor: AppColors.greyDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sort orders requested')),
                        );
                      },
                      icon: const Icon(Icons.sort, size: 14),
                      label: const Text('Sort Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
  
          // Delivery List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(deliveryProvider.notifier).loadDeliveries(),
              child: deliveriesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: 300,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Server Error:\n$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(deliveryProvider.notifier).loadDeliveries(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (deliveryState) {
                  final list = deliveryState.orders;
                  final query = _searchController.text.toLowerCase();
                  final filteredList = list.where((item) {
                    return query.isEmpty ||
                        item.id.toLowerCase().contains(query) ||
                        item.recipientName.toLowerCase().contains(query) ||
                        item.recipientPhone.contains(query) ||
                        item.merchantName.toLowerCase().contains(query);
                  }).toList();
  
                  if (filteredList.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 300,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, color: AppColors.greyDark, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'No delivery consignments found',
                              style: TextStyle(color: AppColors.greyDarker, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          color: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push('/delivery/${item.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row: No, Name, Status, Amount
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${index + 1}. ${item.recipientName} (${item.merchantName})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.greyDarkest),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: item.status),
                                    const SizedBox(width: 8),
                                    Text(
                                      '৳ ${item.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.greyDarkest),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
  
                                // Failed reason (if any)
                                if (item.failedReason != null && item.failedReason!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '⚠ ${item.failedReason}',
                                      style: const TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Phone details (Customer)
                                GestureDetector(
                                  onTap: () async {
                                    final Uri url = Uri.parse('tel:${item.recipientPhone}');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone_android, size: 16, color: AppColors.greyDarker),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.recipientPhone,
                                        style: const TextStyle(
                                          color: Color(0xFFFF8000), // Orange color from screenshot
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('(Customer)', style: TextStyle(fontSize: 12, color: AppColors.greyDarker)),
                                      if (item.unseenMessageCount > 0) ...[
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDD3444),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${item.unseenMessageCount} msg',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Phone details (Merchant)
                                if (item.merchantPhone != null && item.merchantPhone!.isNotEmpty) ...[
                                  GestureDetector(
                                    onTap: () async {
                                      final Uri url = Uri.parse('tel:${item.merchantPhone}');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.store, size: 16, color: AppColors.greyDarker),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.merchantPhone!,
                                          style: const TextStyle(
                                            color: Color(0xFF3F51B5), // Indigo color
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text('(Merchant)', style: TextStyle(fontSize: 12, color: AppColors.greyDarker)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
  
                                // Consignment ID
                                Text(
                                  'Consignment Id: ${item.id}',
                                  style: const TextStyle(color: AppColors.greyDarker, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
  
                                // Address
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.greyDarker),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.address,
                                        style: const TextStyle(color: AppColors.greyDarker, fontSize: 13, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
  
                                // Action buttons: Call / Chat side-by-side
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFF8000), // Orange for customer
                                            foregroundColor: AppColors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () async {
                                            final Uri url = Uri.parse('tel:${item.recipientPhone}');
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            }
                                          },
                                          icon: const Icon(Icons.phone_android, size: 16),
                                          label: const Text('Call Cust', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                    if (item.merchantPhone != null && item.merchantPhone!.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFF3F51B5)), // Indigo for merchant
                                              foregroundColor: const Color(0xFF3F51B5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            onPressed: () async {
                                              final Uri url = Uri.parse('tel:${item.merchantPhone}');
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url);
                                              }
                                            },
                                            icon: const Icon(Icons.store, size: 16),
                                            label: const Text('Call Merch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  ); // closes ListView.builder
                }, // closes data: (deliveryState) {
              ), // closes deliveriesState.when(
            ), // closes RefreshIndicator(
          ), // closes Expanded(
        ], // closes Column children
      ), // closes Column(
    ), // closes Container(
  ), // closes SafeArea(
); // closes Scaffold(
} // closes build method
} // closes class


