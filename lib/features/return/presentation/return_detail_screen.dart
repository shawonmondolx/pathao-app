import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/otp_input.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../dashboard/domain/dashboard_provider.dart';
import '../domain/return_provider.dart';

class ReturnDetailScreen extends ConsumerStatefulWidget {
  final int storeId;

  const ReturnDetailScreen({super.key, required this.storeId});

  @override
  ConsumerState<ReturnDetailScreen> createState() => _ReturnDetailScreenState();
}

class _ReturnDetailScreenState extends ConsumerState<ReturnDetailScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnProvider.notifier).fetchReturnDetail(widget.storeId);
    });
  }

  MerchantReturn? _findMerchant(List<MerchantReturn> returns) {
    try {
      return returns.firstWhere((element) => element.storeId == widget.storeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSubmitReturn(MerchantReturn merchant) async {
    setState(() => _isSubmitting = true);

    final result = await ref
        .read(returnProvider.notifier)
        .submitReturnChecklist(merchant: merchant);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result.isComplete) {
      ref.invalidate(dashboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return completed successfully!'),
          backgroundColor: AppColors.statusGood,
        ),
      );
      context.pop();
    } else if (result.requiresOtp) {
      _showReturnOtpDialog(merchant);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to submit return'),
          backgroundColor: AppColors.statusBad,
        ),
      );
    }
  }

  void _showReturnOtpDialog(MerchantReturn merchant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ReturnOtpModal(merchant: merchant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(returnProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Return to Merchant'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: returnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref
                    .read(returnProvider.notifier)
                    .fetchReturnDetail(widget.storeId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (returns) {
          final merchant = _findMerchant(returns);
          if (merchant == null) {
            return const Center(child: Text('Store return details not found.'));
          }

          final orders = merchant.returnOrderStatuses.values.toList();
          final checkedCount = orders.where((e) => e.status == 'RETURNED').length;

          return Column(
            children: [
              // Store Header Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          merchant.storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        StatusBadge(status: merchant.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.greyDarker),
                        const SizedBox(width: 6),
                        Text(merchant.merchantName),
                        const SizedBox(width: 16),
                        const Icon(Icons.phone, size: 16, color: AppColors.greyDarker),
                        const SizedBox(width: 6),
                        Text(merchant.contactNumber),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.greyDarker),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            merchant.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Store ID: ${merchant.storeId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Checked: $checkedCount / ${orders.length} Parcels',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Batch Toggle Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(returnProvider.notifier)
                            .updateAllPackageStatuses(merchant.storeId, 'RETURNED');
                      },
                      icon: const Icon(Icons.select_all),
                      label: const Text('Check All'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(returnProvider.notifier)
                            .updateAllPackageStatuses(merchant.storeId, 'PENDING');
                      },
                      icon: const Icon(Icons.deselect),
                      label: const Text('Uncheck All'),
                    ),
                  ],
                ),
              ),

              // Parcels Checklist
              Expanded(
                child: orders.isEmpty
                    ? const Center(child: Text('No return packages found for this store'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = orders[index];
                          final isChecked = item.status == 'RETURNED';

                          return Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isChecked
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isChecked,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                final newStatus = (val == true) ? 'RETURNED' : 'PENDING';
                                ref
                                    .read(returnProvider.notifier)
                                    .updatePackageStatus(
                                      merchant.storeId,
                                      item.consignmentId,
                                      newStatus,
                                    );
                              },
                              title: Text(
                                'Consignment ID: ${item.consignmentId}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Status: ${item.status}',
                                style: TextStyle(
                                  color: isChecked ? AppColors.statusGood : Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Action Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: ElevatedButton(
                  onPressed: _isSubmitting || orders.isEmpty
                      ? null
                      : () => _handleSubmitReturn(merchant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Return Checklist',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Return OTP Verification Modal
// ---------------------------------------------------------------------------

class _ReturnOtpModal extends ConsumerStatefulWidget {
  final MerchantReturn merchant;

  const _ReturnOtpModal({required this.merchant});

  @override
  ConsumerState<_ReturnOtpModal> createState() => _ReturnOtpModalState();
}

class _ReturnOtpModalState extends ConsumerState<_ReturnOtpModal> {
  String _otpCode = '';
  File? _pickupSlipFile;
  bool _isVerifying = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 1) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      }
    });
  }

  Future<void> _pickSlipImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickupSlipFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);
    final success = await ref
        .read(returnProvider.notifier)
        .resendReturnOtp(storeId: widget.merchant.storeId);
    setState(() => _isResending = false);

    if (mounted) {
      if (success) {
        _startCooldownTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent to merchant successfully!'),
            backgroundColor: AppColors.statusGood,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend OTP. Try again.'),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 4-digit OTP'),
          backgroundColor: AppColors.statusBad,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    final errorMsg = await ref.read(returnProvider.notifier).verifyReturnOtp(
          merchant: widget.merchant,
          otp: _otpCode,
          pickupSlipFile: _pickupSlipFile,
        );

    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (errorMsg == null) {
      ref.invalidate(dashboardProvider);
      Navigator.of(context).pop(); // close modal
      context.pop(); // return to returns list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return OTP verified successfully!'),
          backgroundColor: AppColors.statusGood,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP Verification Failed: $errorMsg'),
          backgroundColor: AppColors.statusBad,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Merchant Return OTP'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 4-digit OTP sent to merchant contact:\n${widget.merchant.contactNumber}',
              style: const TextStyle(fontSize: 14, color: AppColors.greyDarker),
            ),
            const SizedBox(height: 16),
            OtpInput(
              onCompleted: (code) => setState(() => _otpCode = code),
            ),
            const SizedBox(height: 16),

            // Pickup Slip Image Upload (Optional)
            OutlinedButton.icon(
              onPressed: _pickSlipImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(_pickupSlipFile != null
                  ? 'Pickup Slip Attached ✓'
                  : 'Attach Pickup Slip Photo (Optional)'),
            ),
            const SizedBox(height: 8),

            // Resend OTP button with cooldown timer
            TextButton(
              onPressed: (_cooldownSeconds > 0 || _isResending)
                  ? null
                  : _handleResendOtp,
              child: _isResending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _cooldownSeconds > 0
                          ? 'Resend OTP in ${_cooldownSeconds}s'
                          : 'Resend OTP',
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _handleVerifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Verify & Return'),
        ),
      ],
    );
  }
}