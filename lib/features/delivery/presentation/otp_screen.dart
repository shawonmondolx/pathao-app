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

  /// If true, shows a "Submit to QC" button below Verify.
  /// Should only be true when this OTP screen was opened for a QC-related action.
  final bool needsQcButton;

  /// 'merchant' → uses store_otp_number otp_type + delivery sms-resend
  /// 'customer' → uses 'customer' otp_type + return sms-resend endpoint
  final String otpTarget;

  const OtpScreen({
    super.key,
    required this.consignmentId,
    required this.runOrderId,
    required this.recipientPhone,
    required this.collectedAmount,
    required this.status,
    this.needsQcButton = false,
    this.otpTarget = 'merchant',
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

  String get _otpType =>
      widget.otpTarget == 'customer' ? 'customer' : OtpType.storeOtpNumber;

  String get _targetLabel =>
      widget.otpTarget == 'customer' ? 'customer' : 'merchant';

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.collectedAmount.toStringAsFixed(0);
    // Trigger the OTP SMS immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialOtp());
  }

  Future<void> _sendInitialOtp() async {
    setState(() => _isLoading = true);
    final success = await _resendViaCorrectEndpoint();
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

  // Calls the right resend endpoint based on otpTarget.
  // Returns (merchant/delivery) → /sms-resend
  // Returns (customer/return)   → /return-sms-resend
  Future<bool> _resendViaCorrectEndpoint() {
    if (widget.otpTarget == 'customer') {
      return ref.read(deliveryProvider.notifier).returnSmsResend(
            runOrderId: widget.runOrderId,
            otpType: 'customer',
          );
    }
    return ref.read(deliveryProvider.notifier).resendOtpSms(
          runOrderId: widget.runOrderId,
          otpType: _otpType,
        );
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
    final success = await _resendViaCorrectEndpoint();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.otpSentSuccess)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to resend OTP. Please try again.'),
              backgroundColor: AppColors.statusBad),
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

    final errorMsg = await ref.read(deliveryProvider.notifier).verifyDeliveryOtp(
          consignmentId: widget.consignmentId,
          runOrderId: widget.runOrderId,
          collectedAmount: amount,
          otp: _otpCode,
          status: widget.status,
          otpType: _otpType,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (errorMsg == null) {
        // Only push to proof screen for actual delivery (status=1).
        // For return/exchange/partial/hold OTP, just pop back.
        if (widget.status == DeliveryStatus.delivered) {
          context.pushReplacement('/delivery/${widget.consignmentId}/proof');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Status confirmed successfully!'),
              backgroundColor: AppColors.statusGood,
            ),
          );
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    }
  }

  // Only called when needsQcButton == true (QC OTP flow)
  void _submitQcOtp() async {
    if (_otpCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final errorMsg = await ref.read(deliveryProvider.notifier).submitQcOtp(
          consignmentId: widget.consignmentId,
          runOrderId: widget.runOrderId,
          otp: _otpCode,
          otpType: _otpType,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (errorMsg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ QC OTP verified! Parcel in QC queue.'),
            backgroundColor: AppColors.statusGood,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.statusBad),
        );
      }
    }
  }

  String get _screenTitle {
    switch (widget.status) {
      case DeliveryStatus.returned:
        return 'Return OTP Confirmation';
      case DeliveryStatus.drto:
        return 'DRTO OTP Confirmation';
      case DeliveryStatus.exchange:
        return 'Exchange OTP Confirmation';
      case DeliveryStatus.priceChange:
        return 'Price Change OTP';
      case DeliveryStatus.partialDelivery:
        return 'Partial Delivery OTP';
      default:
        return 'OTP Verification';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle, style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.confirmationCodeSent,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.recipientPhone.isNotEmpty
                  ? '${widget.recipientPhone} ($_targetLabel)'
                  : 'the $_targetLabel',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 32),

            // Received Amount Field (only relevant for delivery/partial/price change)
            if (widget.status == DeliveryStatus.delivered ||
                widget.status == DeliveryStatus.partialDelivery ||
                widget.status == DeliveryStatus.priceChange) ...[
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
            ],

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
                      child: const Text(AppStrings.resendCode,
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2),
                      )
                    : const Text('Verify & Confirm',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            // QC OTP button — only shown when explicitly navigated here for QC
            if (widget.needsQcButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _submitQcOtp,
                  child: const Text('Submit as QC OTP',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
