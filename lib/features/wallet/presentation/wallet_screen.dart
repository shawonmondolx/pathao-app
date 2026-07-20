import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Wallets', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              ElevatedButton(
                onPressed: () => ref.read(walletProvider.notifier).fetchWallets(),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
        data: (state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cash-in-hand / Balance Summary box
                Card(
                  color: AppColors.secondary,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cash Collected in Hand',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '৳ ${state.cashInHand.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.account_balance_wallet, size: 40, color: AppColors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Deposit Wallets Section
                const Text(
                  'Select Deposit Location / Wallet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select where you want to deposit your collected cash to complete your shift clearance.',
                  style: TextStyle(color: AppColors.greyDarker, fontSize: 13),
                ),
                const SizedBox(height: 16),

                if (state.locations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No deposit locations found.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: state.locations.length,
                    itemBuilder: (context, index) {
                      final item = state.locations[index];
                      final isMobile = item.type.toLowerCase().contains('mobile') || item.type.toLowerCase().contains('bkash');
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.greyLighter, shape: BoxShape.circle),
                            child: Icon(
                              isMobile ? Icons.phone_android : Icons.account_balance,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item.type} • ${item.address}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Selected deposit: ${item.name}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
