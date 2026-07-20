import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/delivery_provider.dart';
import '../../dashboard/domain/dashboard_provider.dart';
import '../../../shared/widgets/otp_input.dart';

class DrtoScreen extends ConsumerStatefulWidget {
  final String consignmentId;
  final int runOrderId;
  final String recipientPhone;

  const DrtoScreen({
    super.key,
    required this.consignmentId,
    required this.runOrderId,
    required this.recipientPhone,
  });

  @override
  ConsumerState<DrtoScreen> createState() => _DrtoScreenState();
}

class _DrtoScreenState extends ConsumerState<DrtoScreen> {
  final _amountController = TextEditingController(text: '0');
  String? _selectedReason;
  String _otpCode = '';
  bool _isLoading = false;
  
  // QC Fallback State
  bool _isQcMode = false;
  String? _qcImagePath;
  final _qcReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch return reasons when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryProvider.notifier).fetchReturnReasons();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _qcReasonController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    final success = await ref.read(deliveryProvider.notifier).resendOtpSms(
          runOrderId: widget.runOrderId,
          otpType: 'store_otp_number', // Merchant OTP
        );
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to merchant')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Try again.'), backgroundColor: AppColors.statusBad),
        );
      }
    }
  }

  Future<void> _submitDrto() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_selectedReason == null || _selectedReason!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a return reason')),
      );
      return;
    }
    if (_otpCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final errorMsg = await ref.read(deliveryProvider.notifier).sendDrto(
          consignmentId: widget.consignmentId,
          runOrderId: widget.runOrderId,
          collectedAmount: amount,
          reason: _selectedReason!,
          otp: _otpCode,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (errorMsg == null) {
        // Auto-refresh lists and dashboard
        ref.invalidate(dashboardProvider);
        ref.read(deliveryProvider.notifier).loadDeliveries();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DRTO processed successfully!'), backgroundColor: AppColors.statusGood),
        );
        context.pop(); // Go back to details
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DRTO Failed: $errorMsg'), backgroundColor: AppColors.statusBad),
        );
      }
    }
  }

  // ─── QC FALLBACK FLOW ──────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _qcImagePath = result.files.single.path!);
    }
  }

  Future<void> _submitQcFallback() async {
    if (_qcImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo for QC proof')),
      );
      return;
    }
    final reason = _qcReasonController.text.trim();
    if (reason.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reason must be at least 3 characters long')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final errorMsg = await ref.read(deliveryProvider.notifier).submitQcRequest(
          consignmentId: widget.consignmentId,
          imagePath: _qcImagePath!,
          reason: reason,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (errorMsg == null) {
        // Auto-refresh lists and dashboard
        ref.invalidate(dashboardProvider);
        ref.read(deliveryProvider.notifier).loadDeliveries();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QC Request submitted successfully!'), backgroundColor: AppColors.statusGood),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QC Request Failed: $errorMsg'), backgroundColor: AppColors.statusBad),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DRTO (Return to Origin)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: state.when(
        data: (data) {
          final reasons = data.returnReasons;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _isQcMode ? _buildQcMode() : _buildNormalMode(reasons),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildNormalMode(List<String> reasons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Collected Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixText: '৳ ',
          ),
        ),
        const SizedBox(height: 20),
        const Text('Return Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (reasons.isEmpty)
          const Text('Fetching reasons...', style: TextStyle(color: Colors.grey))
        else
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Select a reason'),
            initialValue: _selectedReason,
            isExpanded: true,
            items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (val) => setState(() => _selectedReason = val),
          ),
        const SizedBox(height: 30),
        const Text('Merchant OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        OtpInput(
          onCompleted: (code) => setState(() => _otpCode = code),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _isLoading ? null : _sendOtp,
          icon: const Icon(Icons.send),
          label: const Text('Send / Resend OTP to Merchant'),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitDrto,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm DRTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _isQcMode = true),
          child: const Text('Merchant cannot provide OTP? Use QC Fallback', style: TextStyle(color: Colors.red)),
        )
      ],
    );
  }

  Widget _buildQcMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _isQcMode = false),
            ),
            const Text('QC Fallback Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Upload Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
            ),
            child: _qcImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_qcImagePath!), fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to take a photo', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('QC Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _qcReasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Describe the issue (min 3 chars)...',
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitQcFallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Submit QC Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
