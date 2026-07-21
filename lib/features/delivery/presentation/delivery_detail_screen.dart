import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/delivery_provider.dart';
import '../../dashboard/domain/dashboard_provider.dart';
import 'package:file_picker/file_picker.dart';

class DeliveryDetailScreen extends ConsumerStatefulWidget {
  final String consignmentId;

  const DeliveryDetailScreen({super.key, required this.consignmentId});

  @override
  ConsumerState<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends ConsumerState<DeliveryDetailScreen> {
  final _amountController = TextEditingController();

  // ── Scan-to-Unlock state ─────────────────────────────────────────────────
  // Matches DELIVERY_AGENT_MARK_SCAN_TIMER = 900000 ms (15 min) from bundle
  static const _scanUnlockDuration = Duration(milliseconds: 900000);

  bool _isUnlocked = false;          // true once QR scan succeeds
  int _proceedMethod = 2;            // 2 = QR_SCAN (set by setDaMarkScanProceedMethod)
  Timer? _unlockTimer;               // auto-re-locks after 15 min
  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _amountController.dispose();
    _unlockTimer?.cancel();
    super.dispose();
  }

  // Called by the QR scanner route result OR after in-screen scan
  void _onScanSuccess(String scannedId) {
    _unlockTimer?.cancel();
    setState(() {
      _isUnlocked = true;
      _proceedMethod = ProceedMethod.qrScan; // 2 = QR_SCAN
    });
    // Auto-relock after 15 min (matching the real app timer)
    _unlockTimer = Timer(_scanUnlockDuration, () {
      if (mounted) {
        setState(() {
          _isUnlocked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan session expired. Please scan again to take action.'),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    });
  }

  Future<void> _showHoldDialog(Consignment item) async {
    final reasonsAsync = ref.read(holdReasonsProvider);
    final List<Map<String, dynamic>> reasons = reasonsAsync.value ?? [
      {'id': 0, 'en': 'Customer not available', 'bn': 'কাস্টমার অনুপস্থিত'},
      {'id': 0, 'en': 'Wrong phone number', 'bn': 'ভুল ফোন নাম্বার'},
      {'id': 0, 'en': 'Customer refused to receive', 'bn': 'কাস্টমার রিসিভ করতে অস্বীকৃতি জানিয়েছে'},
      {'id': 0, 'en': 'Address incorrect', 'bn': 'ভুল ঠিকানা'},
      {'id': 0, 'en': 'Will collect later', 'bn': 'পরে সংগ্রহ করবে'},
    ];

    Map<String, dynamic>? selectedReasonMap;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mark On Hold'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: reasons.map((reasonMap) {
                return RadioListTile<Map<String, dynamic>>(
                  title: Text(reasonMap['bn'] as String),
                  value: reasonMap,
                  groupValue: selectedReasonMap,
                  onChanged: isSubmitting ? null : (val) {
                    setDialogState(() => selectedReasonMap = val);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedReasonMap == null || isSubmitting)
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final error = await ref.read(deliveryProvider.notifier).sendHoldStatus(
                            consignmentId: item.id,
                            runOrderId: item.runOrderId,
                            reason: selectedReasonMap!['en'] as String,
                            holdReasonType: selectedReasonMap!['id'] as int?,
                            proceedMethod: _proceedMethod, // pass scan method
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (error == 'REQUIRE_OTP') {
                          context.push(
                            '/delivery/${item.id}/otp',
                            extra: {
                              'runOrderId': item.runOrderId,
                              'recipientPhone': item.recipientPhone,
                              'collectedAmount': 0.0,
                              'status': 3, // Hold status
                            },
                          );
                        } else {
                          _showResultSnackbar(error, successMsg: 'Status updated to On Hold!');
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReturnDialog(Consignment item) async {
    final screenCtx = context;
    final reasonsAsync = ref.read(returnReasonsProvider);
    final reasons = reasonsAsync.value ?? [
      'Merchant requested return',
      'Customer rejected packaging',
      'Item damaged in transit',
      'Wrong item delivered',
      'Customer address not found',
    ];

    String? selectedReason;

    await showDialog(
      context: screenCtx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Initiate Return'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select return reason:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...reasons.map((reason) {
                  return RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason, style: const TextStyle(fontSize: 14)),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (val) =>
                        setDialogState(() => selectedReason = val),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(dialogCtx);
                      // ── Step 1: fire the return API immediately (one-click for most parcels) ──
                      showDialog(
                        context: screenCtx,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      final errorMsg = await ref
                          .read(deliveryProvider.notifier)
                          .initiateReturn(
                            consignmentId: item.id,
                            runOrderId: item.runOrderId,
                            reason: selectedReason!,
                            proceedMethod: _proceedMethod,
                          );
                      if (!screenCtx.mounted) return;
                      Navigator.pop(screenCtx); // dismiss loading

                      if (errorMsg == null) {
                        // ✅ One-click return — no OTP needed
                        _showResultSnackbar(null,
                            successMsg: 'Return initiated successfully!');
                      } else if (errorMsg == 'REQUIRE_OTP') {
                        // ── Step 2 (only if server demands OTP): ask merchant or customer ──
                        final otpTarget = await showDialog<String>(
                          context: screenCtx,
                          builder: (ctx) => AlertDialog(
                            title: const Text('OTP Confirmation Required'),
                            content: const Text(
                                'This parcel requires OTP confirmation.\nWho should receive the OTP?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'merchant'),
                                child: const Text('Merchant'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'customer'),
                                child: const Text('Customer'),
                              ),
                            ],
                          ),
                        );
                        if (otpTarget != null && screenCtx.mounted) {
                          screenCtx.push(
                            '/delivery/${item.id}/otp',
                            extra: {
                              'runOrderId': item.runOrderId,
                              'recipientPhone': item.recipientPhone,
                              'collectedAmount': 0.0,
                              'status': DeliveryStatus.returned,
                              'otpTarget': otpTarget,
                            },
                          );
                        }
                      } else {
                        // Other API error
                        _showResultSnackbar(errorMsg);
                      }
                    },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQcSubmissionBottomSheet(Consignment item) {
    String? reason;
    String? imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: bottomPadding + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Submit QC Request',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Please provide a reason and photo proof for Quality Control.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'QC Reject Reason',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => reason = val,
                  ),
                  const SizedBox(height: 16),
                  if (imagePath != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(imagePath!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setSheetState(() => imagePath = null),
                        ),
                      ],
                    )
                  else
                      OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Upload Media/Photo Proof'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(type: FileType.any);
                        if (result != null && result.files.single.path != null) {
                          setSheetState(() => imagePath = result.files.single.path!);
                        }
                      },
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: (reason == null || reason!.trim().length < 3 || imagePath == null)
                        ? null
                        : () async {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );

                            final errorMsg = await ref.read(deliveryProvider.notifier).submitQcRequest(
                                  consignmentId: item.id,
                                  imagePath: imagePath!,
                                  reason: reason!,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              _showResultSnackbar(errorMsg, successMsg: 'QC Request submitted successfully!');
                            }
                          },
                    child: const Text('Submit QC Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── AUTO-UNLOCK ─────────────────────────────────────────────────────────
  //
  // Simulates a successful QR scan by using the consignment ID directly.
  // Sets _isUnlocked = true and proceed_method = 2 (QR_SCAN).
  // The server receives proceed_method=2 when delivery is marked, exactly
  // as if the agent had physically scanned the parcel QR code.
  // 15-min auto-relock timer starts (DELIVERY_AGENT_MARK_SCAN_TIMER = 900000ms).
  // ─────────────────────────────────────────────────────────────────────────
  void _autoUnlock(Consignment item) {
    _onScanSuccess(item.id);
  }

  // After unlock: one-tap deliver.
  //
  // Rule A (v2.md): collectable > 0  → one-click, NO OTP, NO dialog.
  // Rule B (v2.md): collectable <= 0 → intercept LOCALLY, navigate directly to
  //                  customer OTP screen (otp_type="customer"). Skip amount dialog
  //                  (nothing to collect) and skip the API call entirely.
  Future<void> _doDeliver(Consignment item) async {
    final screenCtx = context;

    // ── Rule B: Paid / Pre-paid Delivery (collectable <= 0) ──────────────────
    // Per v2.md: "The app intercepts the one-click process and prompts for the
    // Customer's OTP." This must be decided LOCALLY — do NOT call the API first.
    if (item.amount <= 0) {
      screenCtx.push(
        '/delivery/${item.id}/otp',
        extra: {
          'runOrderId': item.runOrderId,
          'recipientPhone': item.recipientPhone,
          'collectedAmount': 0.0,
          'status': DeliveryStatus.delivered,
          'otpTarget': 'customer', // ← sends otp_type="customer" to the API
        },
      );
      return;
    }

    // ── Rule A: Normal COD Delivery (collectable > 0) ─────────────────────────
    // Show amount confirmation dialog, then fire the API — no OTP needed.
    final amountController = TextEditingController(text: item.amount.toStringAsFixed(0));
    final confirmed = await showDialog<double>(
      context: screenCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Received Amount'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Received Amount (৳)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? item.amount;
              Navigator.pop(dialogCtx, amount);
            },
            child: const Text('Deliver ✓'),
          ),
        ],
      ),
    );

    if (confirmed == null || !screenCtx.mounted) return;

    showDialog(
      context: screenCtx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final error = await ref.read(deliveryProvider.notifier).completeDeliveryWithScan(
      consignmentId: item.id,
      runOrderId: item.runOrderId,
      collectedAmount: confirmed,
      proceedMethod: _proceedMethod, // 2=QR_SCAN after scan, 1=GENERAL for no-scan hubs
    );

    if (screenCtx.mounted) {
      Navigator.pop(screenCtx);
      if (error == null) {
        _showResultSnackbar(null, successMsg: '✅ Delivered successfully!');
        // Only require photo proof for document parcels or when server explicitly
        // requires it (is_photo_proof_needed = true). Normal COD parcels skip this.
        if (item.isDocument || item.isPhotoProofNeeded) {
          screenCtx.push('/delivery/${item.id}/proof');
        } else {
          // Normal parcel: go back to delivery list
          if (screenCtx.mounted) screenCtx.pop();
        }
      } else if (error == 'REQUIRE_OTP') {
        // Server unexpectedly required OTP for a non-zero amount parcel.
        // Always treat as customer OTP (consistent with delivery otp_type rules).
        screenCtx.push(
          '/delivery/${item.id}/otp',
          extra: {
            'runOrderId': item.runOrderId,
            'recipientPhone': item.recipientPhone,
            'collectedAmount': confirmed,
            'status': DeliveryStatus.delivered,
            'otpTarget': 'customer', // ← always customer for delivery OTP fallback
          },
        );
      } else {
        _showResultSnackbar(error);
      }
    }
  }


  void _showPartialDeliveryDialog(Consignment item) {
    final screenCtx = context;
    final amountController =
        TextEditingController(text: item.amount.toStringAsFixed(0));
    final countController = TextEditingController(text: '1');
    final otpController = TextEditingController();
    bool isLoading = false;
    bool otpSent = false;

    showDialog(
      context: screenCtx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Partial Delivery'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Amount collected ───────────────────────────────────────
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Collected Amount',
                    prefixText: '৳ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Delivered parcel count ─────────────────────────────────
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Parcels Delivered',
                    hintText: 'Out of ${item.totalItems ?? '?'} total',
                    border: const OutlineInputBorder(),
                    suffixText: 'pcs',
                  ),
                ),
                const SizedBox(height: 16),
                // ── Merchant OTP ───────────────────────────────────────────
                const Text('Merchant OTP',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: '4-digit OTP',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 14),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setDialogState(() => isLoading = true);
                              final messenger = ScaffoldMessenger.of(screenCtx);
                              final ok = await ref
                                  .read(deliveryProvider.notifier)
                                  .resendOtpSms(runOrderId: item.runOrderId);
                              setDialogState(() {
                                isLoading = false;
                                otpSent = ok;
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? '✅ OTP sent to merchant'
                                      : '❌ Failed to send OTP'),
                                  backgroundColor: ok
                                      ? AppColors.statusGood
                                      : AppColors.statusBad,
                                ),
                              );
                            },
                      child: const Text('Send OTP',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (otpSent)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('OTP sent to merchant',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      final count =
                          int.tryParse(countController.text) ?? 1;
                      final otp = otpController.text.trim();
                      if (otp.length != 4) {
                        ScaffoldMessenger.of(screenCtx).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please enter the 4-digit merchant OTP')),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      Navigator.pop(dialogCtx);
                      showDialog(
                        context: screenCtx,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      final error = await ref
                          .read(deliveryProvider.notifier)
                          .sendPartialDelivery(
                            consignmentId: item.id,
                            runOrderId: item.runOrderId,
                            collectedAmount: amount,
                            deliveredCount: count,
                            otp: otp,
                          );
                      if (screenCtx.mounted) {
                        Navigator.pop(screenCtx);
                        _showResultSnackbar(error,
                            successMsg: 'Partial delivery submitted!');
                      }
                    },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceChangeDialog(Consignment item) {
    final screenCtx = context;
    final amountController =
        TextEditingController(text: item.amount.toStringAsFixed(0));
    final reasonController = TextEditingController();
    final otpController = TextEditingController();
    bool isLoading = false;
    bool otpSent = false;

    showDialog(
      context: screenCtx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Price Change'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original amount: ৳ ${item.amount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New Amount',
                    prefixText: '৳ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (required)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Merchant OTP section ────────────────────────────────────
                const Text('Merchant OTP',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: '4-digit OTP',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 14),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setDialogState(() => isLoading = true);
                              final messenger = ScaffoldMessenger.of(screenCtx);
                              final ok = await ref
                                  .read(deliveryProvider.notifier)
                                  .resendOtpSms(runOrderId: item.runOrderId);
                              setDialogState(() {
                                isLoading = false;
                                otpSent = ok;
                              });
                              if (dialogCtx.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? '✅ OTP sent to merchant'
                                        : '❌ Failed to send OTP'),
                                    backgroundColor: ok
                                        ? AppColors.statusGood
                                        : AppColors.statusBad,
                                  ),
                                );
                              }
                            },
                      child: const Text('Send OTP',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (otpSent)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('OTP sent to merchant',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final amount =
                          double.tryParse(amountController.text) ??
                              item.amount;
                      final reason = reasonController.text.trim();
                      final otp = otpController.text.trim();
                      if (reason.length < 3) {
                        ScaffoldMessenger.of(screenCtx).showSnackBar(
                          const SnackBar(
                              content: Text('Reason must be at least 3 characters')),
                        );
                        return;
                      }
                      if (otp.length != 4) {
                        ScaffoldMessenger.of(screenCtx).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter the 4-digit merchant OTP')),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      Navigator.pop(dialogCtx);
                      showDialog(
                        context: screenCtx,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      final error = await ref
                          .read(deliveryProvider.notifier)
                          .sendPriceChange(
                            consignmentId: item.id,
                            runOrderId: item.runOrderId,
                            newAmount: amount,
                            otp: otp,
                            reason: reason,
                          );
                      if (screenCtx.mounted) {
                        Navigator.pop(screenCtx);
                        _showResultSnackbar(error,
                            successMsg: 'Price change submitted!');
                      }
                    },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExchangeConfirmDialog(Consignment item) {
    final screenCtx = context;
    final otpController = TextEditingController();
    bool isLoading = false;
    bool otpSent = false;

    showDialog(
      context: screenCtx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Exchange'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consignment: ${item.id}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Recipient: ${item.recipientName}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                const Text('Merchant OTP Required',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.teal)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: '4-digit OTP',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 14),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setDialogState(() => isLoading = true);
                              final messenger = ScaffoldMessenger.of(screenCtx);
                              final ok = await ref
                                  .read(deliveryProvider.notifier)
                                  .resendOtpSms(runOrderId: item.runOrderId);
                              setDialogState(() {
                                isLoading = false;
                                otpSent = ok;
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? '✅ OTP sent to merchant'
                                      : '❌ Failed to send OTP'),
                                  backgroundColor: ok
                                      ? AppColors.statusGood
                                      : AppColors.statusBad,
                                ),
                              );
                            },
                      child: const Text('Send OTP',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (otpSent)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('OTP sent to merchant',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: isLoading
                  ? null
                  : () async {
                      final otp = otpController.text.trim();
                      if (otp.length != 4) {
                        ScaffoldMessenger.of(screenCtx).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please enter the 4-digit merchant OTP')),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      Navigator.pop(dialogCtx);
                      showDialog(
                        context: screenCtx,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      final error = await ref
                          .read(deliveryProvider.notifier)
                          .sendExchange(
                            consignmentId: item.id,
                            runOrderId: item.runOrderId,
                            otp: otp,
                          );
                      if (screenCtx.mounted) {
                        Navigator.pop(screenCtx);
                        _showResultSnackbar(error,
                            successMsg: 'Exchange submitted successfully!');
                      }
                    },
              child: const Text('Confirm Exchange'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrtoConfirmDialog(Consignment item) {
    context.push('/delivery/${item.id}/drto', extra: {
      'runOrderId': item.runOrderId,
      'recipientPhone': item.recipientPhone,
    });
  }

  void _showResultSnackbar(String? error, {String successMsg = 'Done!'}) {
    if (!mounted) return;
    if (error == null) {
      // Refresh list and dashboard automatically on any successful action
      ref.invalidate(dashboardProvider);
      ref.read(deliveryProvider.notifier).loadDeliveries(); 
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? successMsg),
      backgroundColor: error != null ? AppColors.statusBad : AppColors.statusGood,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fetch reasons in background
    ref.watch(holdReasonsProvider);
    ref.watch(returnReasonsProvider);

    final deliveriesState = ref.watch(deliveryProvider);
    final list = deliveriesState.value?.orders ?? [];

    if (list.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Delivery Details', style: TextStyle(color: AppColors.white)),
          iconTheme: const IconThemeData(color: AppColors.white),
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Consignment? item;
    try {
      item = list.firstWhere((c) => c.id == widget.consignmentId);
    } catch (_) {
      item = null;
    }

    if (item == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Delivery Details', style: TextStyle(color: AppColors.white)),
          iconTheme: const IconThemeData(color: AppColors.white),
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                'Consignment ${widget.consignmentId} not found in list.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(deliveryProvider.notifier).loadDeliveries(),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // item is guaranteed non-null here
    final order = item;

    _amountController.text = order.amount.toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Details', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Consignment ID & Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Consignment ID', style: TextStyle(color: AppColors.greyDarker, fontSize: 13)),
                        Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Merchant Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MERCHANT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Text(order.merchantName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recipient Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RECIPIENT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Text(order.recipientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: AppColors.greyDarker),
                        const SizedBox(width: 8),
                        Text(order.recipientPhone, style: const TextStyle(fontSize: 15)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.phone_in_talk, color: AppColors.green),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Dialing ${order.recipientPhone}')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 18, color: AppColors.greyDarker),
                        const SizedBox(width: 8),
                        Expanded(child: Text(order.address, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CASH TO COLLECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.greyDarker)),
                              Text('৳ ${order.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.link, size: 18),
                              label: const Text('Send Payment Link'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(child: CircularProgressIndicator()),
                                );
                                final error = await ref.read(deliveryProvider.notifier).sendPaymentLink(
                                  runOrderId: order.runOrderId,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _showResultSnackbar(error, successMsg: 'Payment link sent via SMS!');
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.purple),
                                    foregroundColor: Colors.purple,
                                    minimumSize: const Size(0, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _showExchangeConfirmDialog(order),
                                  child: const Text('Exchange'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.fact_check, size: 18),
                                  label: const Text('QC Request'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.blue),
                                    foregroundColor: Colors.blue,
                                    minimumSize: const Size(0, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _showQcSubmissionBottomSheet(order),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Price Change — new amount + reason + merchant OTP required
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.price_change, size: 18),
                              label: const Text('Price Change'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange),
                                foregroundColor: Colors.orange,
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showPriceChangeDialog(order),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hold Reason card
                  if (order.holdReason != null && order.status == 3) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: AppColors.orangeLight.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: AppColors.orangeDarker),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hold Reason: ${order.holdReason}',
                                style: const TextStyle(color: AppColors.orangeDarker, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: !_isUnlocked 
            ? // ── LOCKED STATE ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open_rounded, size: 24),
                  label: const Text(
                    'UNLOCK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  onPressed: () => _autoUnlock(order),
                ),
              )
            : // ── UNLOCKED STATE (ACTION BUTTONS) ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_open, color: AppColors.green, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Actions active', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 12))),
                        TextButton(
                          onPressed: () => _autoUnlock(order),
                          style: TextButton.styleFrom(foregroundColor: AppColors.green, padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                          child: const Text('Re-unlock', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  if (!order.canMark)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.statusBad.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.block, color: AppColors.statusBad, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text('Locked by Server', style: TextStyle(color: AppColors.statusBad, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                  IgnorePointer(
                    ignoring: !order.canMark,
                    child: Opacity(
                      opacity: order.canMark ? 1.0 : 0.4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text('DELIVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _doDeliver(order),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.pause_circle, size: 16),
                                  label: const Text('On Hold'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.statusWarning),
                                    foregroundColor: AppColors.orangeDarker,
                                    minimumSize: const Size(0, 40),
                                  ),
                                  onPressed: () => _showHoldDialog(order),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.undo, size: 16),
                                  label: const Text('Return'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.statusBad),
                                    foregroundColor: AppColors.statusBad,
                                    minimumSize: const Size(0, 40),
                                  ),
                                  onPressed: () => _showReturnDialog(order),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.pie_chart, size: 16),
                                  label: const Text('Partial Delivery'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primary),
                                    foregroundColor: AppColors.primary,
                                    minimumSize: const Size(0, 40),
                                  ),
                                  onPressed: () => _showPartialDeliveryDialog(order),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.airport_shuttle, size: 16),
                                  label: const Text('DRTO'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.teal),
                                    foregroundColor: Colors.teal,
                                    minimumSize: const Size(0, 40),
                                  ),
                                  onPressed: () => _showDrtoConfirmDialog(order),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
