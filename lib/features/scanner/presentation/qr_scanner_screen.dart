import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../delivery/domain/delivery_provider.dart';

/// QR Scanner Screen — two modes:
///
/// 1. **unlockMode = true** (new, correct flow — matches real Pathao app)
///    Called from _openScannerForUnlock on the delivery detail screen.
///    • Validates scanned barcode == expectedConsignmentId
///    • On match → pops and returns the scannedId to the caller
///    • Caller (_onScanSuccess) sets _isUnlocked = true and starts 15-min timer
///    • NO API call is made here — the API is called AFTER user taps an action button
///
/// 2. **unlockMode = false** (legacy/standalone scan)
///    • Validates barcode, then calls completeDeliveryWithScan directly
///    • Used when scanner is opened standalone (not from delivery detail)

class QRScannerScreen extends ConsumerStatefulWidget {
  final String? expectedConsignmentId;
  final int? runOrderId;
  final double? collectedAmount;
  final bool unlockMode; // true = scan to unlock, false = scan to deliver

  const QRScannerScreen({
    super.key,
    this.expectedConsignmentId,
    this.runOrderId,
    this.collectedAmount,
    this.unlockMode = false,
  });

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanComplete = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isScanComplete) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _handleCode(barcodes.first.rawValue!);
    }
  }

  void _handleCode(String code) async {
    setState(() => _isScanComplete = true);
    final cleanCode = code.trim();
    // Pathao QR stickers sometimes encode "CONSIGNMENT_ID|extra"
    final scannedId = cleanCode.split('|').first.trim();

    final expectedId = widget.expectedConsignmentId;

    if (expectedId != null) {
      // Validate: scanned barcode must match the expected consignment
      final isMatch = scannedId == expectedId || cleanCode == expectedId;
      if (!isMatch) {
        setState(() => _isScanComplete = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Wrong Parcel Scanned!\nExpected: $expectedId\nGot: $scannedId'),
            backgroundColor: AppColors.statusBad,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }

      // Correct parcel scanned!
      if (widget.unlockMode) {
        // ── UNLOCK MODE ─────────────────────────────────────────────────────
        // Just pop and return the scanned ID to the delivery detail screen.
        // The detail screen will set _isUnlocked = true and start the 15-min timer.
        // The actual API call happens ONLY when the user taps Deliver/Hold/Return.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Parcel verified: $scannedId — all actions unlocked!'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Small delay so user sees the success message before pop
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.pop(scannedId); // return to detail screen
      } else {
        // ── LEGACY DIRECT-DELIVER MODE ───────────────────────────────────
        _completeScanDelivery(scannedId);
      }
    } else {
      // Generic scan (no expected ID): just return the code
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned: $code'), backgroundColor: AppColors.statusGood),
      );
      context.pop(code);
    }
  }

  /// Legacy mode: scan validates AND calls the delivery API directly.
  void _completeScanDelivery(String scannedId) async {
    final expectedId = widget.expectedConsignmentId!;
    final runOrderId = widget.runOrderId ?? 0;
    final amount = widget.collectedAmount ?? 0.0;

    if (runOrderId <= 0) {
      setState(() => _isScanComplete = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Invalid run order ID. Cannot complete delivery.'),
          backgroundColor: AppColors.statusBad,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final errorMsg = await ref.read(deliveryProvider.notifier).completeDeliveryWithScan(
      consignmentId: expectedId,
      runOrderId: runOrderId,
      collectedAmount: amount,
      proceedMethod: ProceedMethod.qrScan, // Always QR_SCAN from scanner screen
    );

    if (mounted) {
      Navigator.pop(context); // close loading
      if (errorMsg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Parcel scanned & delivered successfully!'),
            backgroundColor: AppColors.statusGood,
            duration: Duration(seconds: 3),
          ),
        );
        // Only go to proof screen for document parcels or when server requires it.
        // Look up the order from the provider to check.
        final deliveryState = ref.read(deliveryProvider).value;
        final order = deliveryState?.orders.where((o) => o.id == expectedId).firstOrNull;
        final needsProof = order?.isDocument == true || order?.isPhotoProofNeeded == true;
        if (needsProof) {
          context.pushReplacement('/delivery/$expectedId/proof');
        } else {
          // Normal parcel — just pop back to delivery list
          if (mounted) context.pop();
        }
      } else {
        setState(() => _isScanComplete = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery failed: $errorMsg'),
            backgroundColor: AppColors.statusBad,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showManualEntryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode Manually'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Barcode / Consignment ID',
            hintText: 'e.g. DTK20260717001',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = textController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _handleCode(code);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlockMode = widget.unlockMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUnlockMode ? 'Scan to Unlock' : 'Scan QR / Barcode',
          style: const TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: AppColors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Viewfinder overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isUnlockMode ? AppColors.primary : AppColors.green,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner highlights
                  ...[ Alignment.topLeft, Alignment.topRight,
                       Alignment.bottomLeft, Alignment.bottomRight].map((a) {
                    return Align(
                      alignment: a,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: isUnlockMode ? AppColors.primary : AppColors.green,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Mode label
          Positioned(
            top: 40,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isUnlockMode
                      ? '🔓  Scan parcel QR to unlock all actions'
                      : '📦  Scan parcel QR to complete delivery',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),

          // Expected consignment hint
          if (widget.expectedConsignmentId != null)
            Positioned(
              bottom: 110,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Expected: ${widget.expectedConsignmentId}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),

          // Manual Entry Button
          Positioned(
            bottom: 40,
            left: 24, right: 24,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _showManualEntryDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Enter Code Manually'),
            ),
          ),
        ],
      ),
    );
  }
}
