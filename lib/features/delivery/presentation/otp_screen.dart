import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/otp_input.dart';
import '../domain/delivery_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String consignmentId;
  final int runOrderId;
  final String recipientPhone;
  final double collectedAmount;
  final int status;

  const OtpScreen({
    super.key,
    required this.consignmentId,
    required this.runOrderId,
    required this.recipientPhone,
    required this.collectedAmount,
    required this.status,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _amountController = TextEditingController();
  int _timerSeconds = 30;
  Timer? _timer;
  String _otpCode = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.collectedAmount.toStringAsFixed(0);
    // Trigger the OTP SMS immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialOtp());
  }

  Future<void> _sendInitialOtp() async {
    setState(() => _isLoading = true);
    // ✅ Only run_order_id is needed by the real API
    final success = await ref.read(deliveryProvider.notifier).resendOtpSms(
      runOrderId: widget.runOrderId,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to ${widget.recipientPhone}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP. Tap "Resend Code" to try again.'),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    }
  }

  void _startTimer() {
    setState(() => _timerSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _resendCode() async {
    _startTimer();
    // ✅ Only run_order_id is needed by the real API
    final success = await ref.read(deliveryProvider.notifier).resendOtpSms(
      runOrderId: widget.runOrderId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.otpSentSuccess)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend OTP. Please try again.'), backgroundColor: AppColors.statusBad),
        );
      }
    }
  }

  void _verifyOtp() async {
    if (_otpCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit OTP')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? widget.collectedAmount;

    setState(() => _isLoading = true);
    
    // ✅ Call the real API with correct otp_type
    final errorMsg = await ref.read(deliveryProvider.notifier).verifyDeliveryOtp(
      consignmentId: widget.consignmentId,
      runOrderId: widget.runOrderId,
      collectedAmount: amount,
      otp: _otpCode,
      status: widget.status,
      otpType: 'store_otp_number', // ✅ correct value from Pathao bundle
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (errorMsg == null) {
        // Success
        context.pushReplacement('/delivery/${widget.consignmentId}/proof');
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    }
  }

  void _submitQc() async {
    if (_otpCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // ✅ Uses 'store_otp_number' otp_type by default
    final errorMsg = await ref.read(deliveryProvider.notifier).submitQcOtp(
      consignmentId: widget.consignmentId,
      runOrderId: widget.runOrderId,
      otp: _otpCode,
      otpType: 'store_otp_number',
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (errorMsg == null) {
        context.pushReplacement('/delivery/${widget.consignmentId}/proof');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.statusBad),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.confirmationCodeSent,
              style: TextStyle(fontSize: 16),
            ),
            Text(
              widget.recipientPhone,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            
            // Received Amount Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.receivedAmount,
                prefixText: '৳ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // OTP Inputs
            OtpInput(
              onCompleted: (code) {
                setState(() => _otpCode = code);
              },
            ),
            const SizedBox(height: 32),

            // Resend & Timer
            Center(
              child: _timerSeconds > 0
                  ? Text(
                      '${AppStrings.waitSec} $_timerSeconds sec',
                      style: const TextStyle(color: AppColors.greyDarker),
                    )
                  : TextButton(
                      onPressed: _resendCode,
                      child: const Text(AppStrings.resendCode, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
            ),
            const SizedBox(height: 32),

            // Verify Button & QC Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                        : const Text('Verify'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _submitQc,
                    child: const Text('Submit to QC'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
