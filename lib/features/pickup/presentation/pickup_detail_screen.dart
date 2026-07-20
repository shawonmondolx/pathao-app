import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/otp_input.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/pickup_provider.dart';

class PickupDetailScreen extends ConsumerStatefulWidget {
  final int storeId;

  const PickupDetailScreen({super.key, required this.storeId});

  @override
  ConsumerState<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends ConsumerState<PickupDetailScreen> {
  final List<bool> _packageChecked = List.generate(12, (_) => false);
  bool _otpRequested = false;
  bool _isOtpLoading = false;

  void _requestOtp(MerchantPickup item) async {
    setState(() => _isOtpLoading = true);
    final success = await ref.read(pickupProvider.notifier).requestPickupOtp(storeId: item.storeId);
    setState(() {
      _isOtpLoading = false;
      if (success) _otpRequested = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'OTP code sent to merchant' : 'Failed to send OTP code'),
          backgroundColor: success ? AppColors.statusGood : AppColors.statusBad,
        ),
      );
    }
  }

  void _showOtpConfirmDialog(MerchantPickup item) {
    showDialog(
      context: context,
      builder: (context) {
        String inputOtp = '';
        return AlertDialog(
          title: const Text('Confirm Pickup OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter 4-digit code sent to: ${item.contactNumber}'),
              const SizedBox(height: 16),
              OtpInput(
                onCompleted: (code) {
                  inputOtp = code;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (inputOtp.length == 4) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  final error = await ref.read(pickupProvider.notifier).verifyPickupOtp(
                    storeId: item.storeId,
                    otp: inputOtp,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog
                    if (error == null) {
                      Navigator.pop(context); // Close OTP dialog
                      context.pop(); // Return to list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pickup completed successfully!'), backgroundColor: AppColors.statusGood),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: AppColors.statusBad),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid 4-digit OTP'), backgroundColor: AppColors.statusBad),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickupsAsync = ref.watch(pickupProvider);
    final pickups = pickupsAsync.valueOrNull ?? [];
    if (pickups.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final item = pickups.firstWhere(
      (p) => p.storeId == widget.storeId,
      orElse: () => pickups.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Details', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Store Header details
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    StatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Merchant: ${item.merchantName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('Contact: ${item.contactNumber}'),
                Text('Address: ${item.address}'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Package Checklist Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Package Checklist',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < item.totalPackages; i++) {
                        _packageChecked[i] = true;
                      }
                    });
                  },
                  child: const Text('Select All'),
                ),
              ],
            ),
          ),

          // Package checklist list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: item.totalPackages,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    title: Text('Consignment ID: PKG-${item.storeId}-${1000 + index}'),
                    value: _packageChecked[index],
                    activeColor: AppColors.primary,
                    onChanged: item.status == 'PICKED'
                        ? null
                        : (val) {
                            setState(() => _packageChecked[index] = val ?? false);
                          },
                  ),
                );
              },
            ),
          ),

          // Submit Bottom Panel
          if (item.status != 'PICKED')
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (!_otpRequested)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isOtpLoading ? null : () => _requestOtp(item),
                          child: _isOtpLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Send OTP Code'),
                        ),
                      ),
                    if (_otpRequested) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: _isOtpLoading ? null : () => _requestOtp(item),
                          child: _isOtpLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Resend OTP'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showOtpConfirmDialog(item),
                          child: const Text('Enter OTP'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
