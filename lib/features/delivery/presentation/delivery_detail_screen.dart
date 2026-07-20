import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  DateTime? _unlockExpiry;           // for countdown display
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
      _unlockExpiry = DateTime.now().add(_scanUnlockDuration);
    });
    // Auto-relock after 15 min (matching the real app timer)
    _unlockTimer = Timer(_scanUnlockDuration, () {
      if (mounted) {
        setState(() {
          _isUnlocked = false;
          _unlockExpiry = null;
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
                        _showResultSnackbar(error, successMsg: 'Status updated to On Hold!');
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
              children: reasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (val) => setDialogState(() => selectedReason = val),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(dialogCtx);
                      showDialog(
                        context: screenCtx,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      final errorMsg = await ref.read(deliveryProvider.notifier).initiateReturn(
                            consignmentId: item.id,
                            runOrderId: item.runOrderId,
                            reason: selectedReason!,
                            proceedMethod: _proceedMethod, // pass scan method
                          );
                      if (screenCtx.mounted) {
                        Navigator.pop(screenCtx);
                        _showResultSnackbar(errorMsg, successMsg: 'Return initiated successfully!');
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

  // After unlock: one-tap deliver (no OTP, no dialog — same as real app)
  Future<void> _doDeliver(Consignment item) async {
    final screenCtx = context;

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
      } else {
        _showResultSnackbar(error);
      }
    }
  }

  void _showManualDeliveryDialog(Consignment item) {
    final screenCtx = context;
    final amountController = TextEditingController(
      text: item.amount.toStringAsFixed(0),
    );
    showDialog(
      context: screenCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Delivery Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consignment: ${item.id}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'No QR scan — proceed_method: GENERAL',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Received Amount',
                prefixText: '\u09f3 ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Mark Delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? item.amount;
              Navigator.pop(dialogCtx);

              showDialog(
                context: screenCtx,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              final error = await ref
                  .read(deliveryProvider.notifier)
                  .verifyDeliveryOtp(
                    consignmentId: item.id,
                    runOrderId: item.runOrderId,
                    collectedAmount: amount,
                    otp: '',
                    status: DeliveryStatus.delivered,
                  );

              if (screenCtx.mounted) {
                Navigator.pop(screenCtx);
                _showResultSnackbar(error, successMsg: 'Delivered successfully!');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPartialDeliveryDialog(Consignment item) {
    final screenCtx = context;
    final amountController = TextEditingController(text: item.amount.toStringAsFixed(0));
    showDialog(
      context: screenCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Partial Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the amount collected for partial delivery:'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Received Amount',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              Navigator.pop(dialogCtx);
              showDialog(
                context: screenCtx,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              final error = await ref.read(deliveryProvider.notifier).sendPartialDelivery(
                consignmentId: item.id,
                runOrderId: item.runOrderId,
                collectedAmount: amount,
              );
              if (screenCtx.mounted) {
                Navigator.pop(screenCtx);
                _showResultSnackbar(error, successMsg: 'Partial delivery submitted!');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showPriceChangeDialog(Consignment item) {
    final screenCtx = context;
    final amountController = TextEditingController(text: item.amount.toStringAsFixed(0));
    showDialog(
      context: screenCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Price Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Original amount: ৳ ${item.amount.toStringAsFixed(2)}'),
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? item.amount;
              Navigator.pop(dialogCtx);
              showDialog(
                context: screenCtx,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              final error = await ref.read(deliveryProvider.notifier).sendPriceChange(
                consignmentId: item.id,
                runOrderId: item.runOrderId,
                newAmount: amount,
              );
              if (screenCtx.mounted) {
                Navigator.pop(screenCtx);
                _showResultSnackbar(error, successMsg: 'Price change submitted!');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showExchangeConfirmDialog(Consignment item) {
    final screenCtx = context;
    showDialog(
      context: screenCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Exchange'),
        content: Text('Confirm exchange for consignment ${item.id}?\n\nAmount: ৳ ${item.amount.toStringAsFixed(2)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              showDialog(
                context: screenCtx,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              final error = await ref.read(deliveryProvider.notifier).sendExchange(
                consignmentId: item.id,
                runOrderId: item.runOrderId,
                collectedAmount: item.amount,
              );
              if (screenCtx.mounted) {
                Navigator.pop(screenCtx);
                _showResultSnackbar(error, successMsg: 'Exchange submitted successfully!');
              }
            },
            child: const Text('Confirm Exchange'),
          ),
        ],
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

    final String _rawStatus = order.status.toString().toUpperCase().trim();
    // Replicate StatusBadge logic to ensure they match exactly
    String _statusStr = _rawStatus;
    if (_rawStatus == '1') _statusStr = 'PENDING';
    if (_rawStatus == '2') _statusStr = 'DELIVERED';
    if (_rawStatus == '3') _statusStr = 'ON HOLD';
    if (_rawStatus == '4') _statusStr = 'RETURNED';

    final bool isActive = _statusStr.contains('PENDING') || _statusStr.contains('HOLD') || _rawStatus == '1' || _rawStatus == '3';

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
                        ],
                      ),
                    ),
                  ),

                  // Hold Reason card
                  if (order.holdReason != null && order.status == 3) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: AppColors.orangeLight.withOpacity(0.1),
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
