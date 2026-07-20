import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROCEED_METHOD constants (from DELIVERY_AGENT_SCAN_PROCEED_METHOD)
// ─────────────────────────────────────────────────────────────────────────────
class ProceedMethod {
  static const int general = 1;     // GENERAL — standard OTP delivery
  static const int qrScan = 2;      // QR_SCAN  — QR barcode unlock
  static const int hadNoInternet = 3;
  static const int qrNotWorking = 4;
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS codes
// ─────────────────────────────────────────────────────────────────────────────
class DeliveryStatus {
  static const int pending = 0;
  static const int delivered = 1;
  static const int returned = 2;
  static const int onHold = 3;
  static const int pickedUp = 4; // Assuming legacy mapping if needed
  static const int partialDelivery = 7;
  static const int priceChange = 8;
  static const int drto = 9;
  static const int exchange = 10;
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP_TYPE options (from ADD_MERCHANT_OTP_OPTIONS)
// ─────────────────────────────────────────────────────────────────────────────
class OtpType {
  static const String storeOtpNumber = 'store_otp_number';       // DEFAULT
  static const String storeContactNumber = 'store_contact_number';
  static const String merchantPhoneNumber = 'merchant_phone_number';
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class Consignment {
  final String id;
  final String merchantName;
  final String recipientName;
  final String recipientPhone;
  final String? recipientSecondaryPhone;
  final String address;
  final String? merchantAddress;
  final String? merchantPhone;
  final double amount;
  final dynamic status;
  final int runOrderId;
  final int orderId;
  final int runRouteId;
  final String? holdReason;
  final String? failedReason;
  final String? deliveryInstruction;
  final String? orderDesc;
  final bool canMark;
  final bool isPhotoProofNeeded;
  final bool isChatEnabled;
  final int unseenMessageCount;
  final String? paymentLink;
  /// True if this parcel is a document — requires a delivery_slip photo proof.
  final bool isDocument;
  /// True if QR scanning is required for this run before taking action.
  /// Some hubs (e.g. Bhaluka, Savar) set this to false and accept proceed_method=1 directly.
  final bool isScanRequired;
  /// Total parcel count in this order (used for partial delivery count hint).
  final int? totalItems;

  Consignment({
    required this.id,
    required this.merchantName,
    required this.recipientName,
    required this.recipientPhone,
    this.recipientSecondaryPhone,
    required this.address,
    this.merchantAddress,
    this.merchantPhone,
    required this.amount,
    required this.status,
    required this.runOrderId,
    required this.orderId,
    required this.runRouteId,
    this.holdReason,
    this.failedReason,
    this.deliveryInstruction,
    this.orderDesc,
    this.canMark = true,
    this.isPhotoProofNeeded = false,
    this.isChatEnabled = true,
    this.unseenMessageCount = 0,
    this.paymentLink,
    this.isDocument = false,
    this.isScanRequired = true,
    this.totalItems,
  });

  Consignment copyWith({
    dynamic status,
    String? holdReason,
  }) {
    return Consignment(
      id: id,
      merchantName: merchantName,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      recipientSecondaryPhone: recipientSecondaryPhone,
      address: address,
      merchantAddress: merchantAddress,
      merchantPhone: merchantPhone,
      amount: amount,
      status: status ?? this.status,
      runOrderId: runOrderId,
      orderId: orderId,
      runRouteId: runRouteId,
      holdReason: holdReason ?? this.holdReason,
      failedReason: failedReason,
      deliveryInstruction: deliveryInstruction,
      orderDesc: orderDesc,
      canMark: canMark,
      isPhotoProofNeeded: isPhotoProofNeeded,
      isChatEnabled: isChatEnabled,
      unseenMessageCount: unseenMessageCount,
      paymentLink: paymentLink,
      isDocument: isDocument,
      isScanRequired: isScanRequired,
      totalItems: totalItems,
    );
  }

  factory Consignment.fromJson(Map<String, dynamic> json) {
    return Consignment(
      id: json['consignment_id']?.toString() ?? json['id']?.toString() ?? '',
      merchantName: json['merchant_name'] ?? json['merchant'] ?? '',
      recipientName: json['recipient_name'] ?? json['name'] ?? '',
      recipientPhone: json['recipient_phone'] ?? json['phone'] ?? '',
      recipientSecondaryPhone: json['recipient_secondary_phone'],
      address: json['recipient_address'] ?? json['address'] ?? '',
      merchantAddress: json['merchant_address']?.toString(),
      merchantPhone: json['merchant_phone']?.toString(),
      amount: (json['amount'] ?? json['cash_to_collect'] ?? 0).toDouble(),
      status: json['status'] ?? 1,
      runOrderId: json['run_order_id'] ??
          json['run_route_order_id'] ??
          json['run_routes_order_id'] ??
          0,
      orderId: json['order_id'] ?? 0,
      runRouteId: json['run_route_id'] ?? 0,
      holdReason: json['hold_reason'],
      failedReason: json['failed_reason'],
      deliveryInstruction: json['delivery_instruction'],
      orderDesc: json['order_desc'],
      canMark: json['can_mark'] ?? true,
      isPhotoProofNeeded: json['is_photo_proof_needed'] ?? false,
      isChatEnabled: json['is_chat_enabled'] ?? true,
      unseenMessageCount: json['unseen_message_count'] ?? 0,
      paymentLink: json['payment_link'],
      // is_document: parcel requires photo delivery proof
      isDocument: json['is_document'] == true || json['isDocument'] == true,
      // is_scan_required: hub/run requires QR scan before action.
      // Default true; server sends false for hubs like Bhaluka, Savar.
      isScanRequired: json['is_scan_required'] != false &&
          json['isScanRequired'] != false &&
          json['da_scan_required'] != false,
      totalItems: json['total_items'] ?? json['item_count'] ?? json['quantity'],
    );
  }
}

class CollectionInfo {
  final double totalCollectable;
  final double totalCollected;

  CollectionInfo({
    required this.totalCollectable,
    required this.totalCollected,
  });

  factory CollectionInfo.fromJson(Map<String, dynamic> json) {
    return CollectionInfo(
      totalCollectable: (json['total_collectable'] ?? 0).toDouble(),
      totalCollected: (json['total_collected'] ?? 0).toDouble(),
    );
  }

  factory CollectionInfo.empty() {
    return CollectionInfo(totalCollectable: 0, totalCollected: 0);
  }
}

class DeliveryState {
  final List<Consignment> orders;
  final CollectionInfo collection;
  final List<String> returnReasons;

  DeliveryState({
    required this.orders,
    required this.collection,
    this.returnReasons = const [],
  });

  DeliveryState copyWith({
    List<Consignment>? orders,
    CollectionInfo? collection,
    List<String>? returnReasons,
  }) {
    return DeliveryState(
      orders: orders ?? this.orders,
      collection: collection ?? this.collection,
      returnReasons: returnReasons ?? this.returnReasons,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: extract human-readable error from DioException
// ─────────────────────────────────────────────────────────────────────────────
String _extractError(Object e, String fallback) {
  if (e is DioException) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      if (statusCode == 422 || statusCode == 400) {
        final msg = data['message'] ?? '';
        if (msg.toString().toLowerCase().contains('otp')) {
          return 'REQUIRE_OTP';
        }
      }
      
      // Handle nested validation errors: {"errors": {"field": ["msg"]}}
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstKey = errors.keys.first;
        final firstVal = errors[firstKey];
        final msg = (firstVal is List && firstVal.isNotEmpty)
            ? firstVal.first.toString()
            : firstVal?.toString() ?? '';
        
        // Also check if field error is about otp
        if (msg.toLowerCase().contains('otp') || firstKey.toString().toLowerCase().contains('otp')) {
          return 'REQUIRE_OTP';
        }
        
        return '$msg';
      }
      final errField = data['error'];
      return data['message'] ??
          (errField is Map ? errField['description'] : errField?.toString()) ??
          'HTTP ${statusCode}: $fallback';
    }
    return 'HTTP ${statusCode ?? 'No Response'}: $fallback';
  }
  return fallback;
}

// ─────────────────────────────────────────────────────────────────────────────
// DeliveryNotifier
// ─────────────────────────────────────────────────────────────────────────────

class DeliveryNotifier extends StateNotifier<AsyncValue<DeliveryState>> {
  DeliveryNotifier() : super(const AsyncValue.loading()) {
    loadDeliveries();
  }

  Future<void> loadDeliveries() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.deliveryList);
      if (response.statusCode == 200) {
        final responseData = response.data['data'];

        // Parse collection info
        CollectionInfo collection = CollectionInfo.empty();
        if (responseData != null && responseData['collection'] != null) {
          collection = CollectionInfo.fromJson(
            Map<String, dynamic>.from(responseData['collection']),
          );
        }

        // Parse orders
        List<Consignment> orders = [];
        if (responseData != null &&
            responseData['orders'] != null &&
            responseData['orders']['data'] != null) {
          final rawList = responseData['orders']['data'];
          if (rawList is List) {
            orders = rawList
                .map((item) =>
                    Consignment.fromJson(Map<String, dynamic>.from(item)))
                .toList();
          }
        } else {
          final rawList = responseData ?? response.data;
          if (rawList is List) {
            orders = rawList
                .map((item) =>
                    Consignment.fromJson(Map<String, dynamic>.from(item)))
                .toList();
          }
        }

        state =
            AsyncValue.data(DeliveryState(orders: orders, collection: collection));
        return;
      }
      throw Exception(
          'Failed to load deliveries: Server status ${response.statusCode}');
    } catch (e) {
      String errorMsg = e.toString();
      final dynamic err = e;
      try {
        if (err.response != null && err.response.data != null) {
          final resData = err.response.data;
          if (resData is Map && resData['message'] != null) {
            errorMsg = resData['message'];
            if (resData['error'] != null &&
                resData['error']['description'] != null) {
              errorMsg = errorMsg + ': ' + resData['error']['description'].toString();
            }
          }
        }
      } catch (_) {}
      state = AsyncValue.error(errorMsg, StackTrace.current);
    }
  }

  /// Explicitly approve a delivery assignment (Findings 67 & 68).
  /// Requires a PATCH request to /api/v1/user/deliveries/:runRouteOrderId/approve
  Future<String?> approveDelivery(int runRouteOrderId) async {
    try {
      final dioClient = DioClient();
      final url = ApiEndpoints.approveDelivery.replaceFirst('{runRouteOrderId}', runRouteOrderId.toString());
      
      // Finding 68 strictly requires a PATCH method here, NOT POST.
      final response = await dioClient.dio.patch(url);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully approved, reload delivery list to get fresh states.
        await loadDeliveries();
        return null;
      }
      return 'Failed to approve delivery: ${response.statusCode}';
    } catch (e) {
      return _extractError(e, 'Failed to approve delivery');
    }
  }

  void updateStatus(String consignmentId, int newStatus, {String? reason}) {
    if (state.hasValue) {
      final currentState = state.value!;
      final updatedOrders = [
        for (final item in currentState.orders)
          if (item.id == consignmentId)
            item.copyWith(status: newStatus, holdReason: reason)
          else
            item
      ];
      state = AsyncValue.data(
        DeliveryState(
            orders: updatedOrders, collection: currentState.collection),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MARK AS DELIVERED — matches exact Hermes confirmDelivery payload
  //
  // Payload is multipart FormData, POST to DELIVERY_COMPLETE_URL.
  // Fields (from hermes lines 442966–443055):
  //   run_order_id    (always)
  //   status          (always — 1 = DELIVERED)
  //   reason          (if provided)
  //   collected_amount (if != 0 and truthy — sent as INTEGER)
  //   otp_type        (if provided)
  //   proceed_method  (if provided — 2=QR_SCAN, 1=GENERAL, 4=QR_NOT_WORKING)
  //   otp             (if provided and not isDocument)
  //
  // proceedMethod:
  //   ProceedMethod.qrScan (2)   — after successful QR scan
  //   ProceedMethod.general (1)  — for hubs that don't require scan (Bhaluka, Savar etc.)
  //   ProceedMethod.qrNotWorking (4) — fallback when QR can't be read
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> completeDeliveryWithScan({
    required String consignmentId,
    required int runOrderId,
    required double collectedAmount,
    int proceedMethod = ProceedMethod.qrScan,
    String? otp,
    String? otpType,
    String? reason,
  }) async {
    if (runOrderId <= 0) {
      return 'Invalid run order ID ($runOrderId). Cannot mark delivery.';
    }

    final dioClient = DioClient();

    // Build FormData exactly as the real Hermes app does
    final formData = FormData.fromMap({
      'run_order_id': runOrderId,
      'status': DeliveryStatus.delivered,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      // collected_amount only if non-zero (PAID delivery skips this)
      if (collectedAmount != 0) 'collected_amount': collectedAmount.toInt(),
      if (otpType != null && otpType.isNotEmpty) 'otp_type': otpType,
      if (proceedMethod != 0) 'proceed_method': proceedMethod,
      if (otp != null && otp.isNotEmpty) 'otp': otp,
    });

    print('=== DELIVERY CHECK REQUEST ===');
    print('URL: ${ApiEndpoints.deliveryComplete}');
    print('PAYLOAD: run_order_id=$runOrderId, status=${DeliveryStatus.delivered}, '
        'collected_amount=${collectedAmount.toInt()}, proceed_method=$proceedMethod'
        '${otp != null ? ', otp=$otp' : ''}'  );

    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryComplete,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      print('=== DELIVERY CHECK RESPONSE ===');
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.delivered);
        return null; // ✅ Success
      }
      return 'Server returned ${response.statusCode}';
    } catch (e) {
      print('=== DELIVERY CHECK ERROR ===');
      if (e is DioException) {
        print('STATUS: ${e.response?.statusCode}');
        print('DATA: ${e.response?.data}');
      }
      return _extractError(e, 'Failed to mark delivery');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // VERIFY DELIVERY OTP — customer provides an OTP (proceed_method=1 GENERAL)
  //
  // Payload: JSON, POST /api/v1/user/delivery/check
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> verifyDeliveryOtp({
    required String consignmentId,
    required int runOrderId,
    required double collectedAmount,
    required String otp,
    int status = DeliveryStatus.delivered,
    String otpType = OtpType.storeOtpNumber,
    String? reason,
  }) async {
    try {
      final dioClient = DioClient();

      final formData = FormData.fromMap({
        'run_order_id': runOrderId,
        'status': status,
        'otp_type': otpType,
        if (collectedAmount != 0) 'collected_amount': collectedAmount.toInt(),
        if (otp.isNotEmpty) 'otp': otp,
        'proceed_method': ProceedMethod.general,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

      print('=== VERIFY OTP REQUEST ===');
      print('URL: ${ApiEndpoints.deliveryComplete}');
      print('PAYLOAD: run_order_id=$runOrderId, status=$status, otp=$otp');

      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryComplete,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      print('=== VERIFY OTP RESPONSE ===');
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.delivered);
        return null;
      }
      return 'Server error: Status ${response.statusCode}';
    } catch (e) {
      print('=== VERIFY OTP ERROR ===');
      if (e is DioException) {
        print('STATUS: ${e.response?.statusCode}');
        print('DATA: ${e.response?.data}');
      }
      return _extractError(e, 'Failed to verify OTP');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ON HOLD — POST /api/v1/user/delivery
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> sendHoldStatus({
    required String consignmentId,
    required int runOrderId,
    required String reason,
    int? holdReasonType,
    int proceedMethod = ProceedMethod.general,
  }) async {
    if (runOrderId <= 0) {
      return 'Invalid run order ID ($runOrderId). Cannot update status.';
    }
    final dioClient = DioClient();

    final formData = FormData.fromMap({
      'run_order_id': runOrderId,
      'status': DeliveryStatus.onHold,
      'reason': reason,
      if (holdReasonType != null) 'hold_reason_type': holdReasonType,
      if (proceedMethod != 0) 'proceed_method': proceedMethod,
    });

    try {
      print('=== DELIVERY HOLD REQUEST ===');
      print('URL: ${ApiEndpoints.deliveryUpdate}');
      print('PAYLOAD: run_order_id=$runOrderId, status=${DeliveryStatus.onHold}, reason=$reason');

      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryUpdate,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      print('=== DELIVERY HOLD RESPONSE ===');
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.onHold, reason: reason);
        return null; // Success
      }
      return 'Server error: Status ${response.statusCode}';
    } catch (e) {
      print('=== HOLD FormData failed ===');
      if (e is DioException) {
        print('STATUS: ${e.response?.statusCode}');
        print('DATA: ${e.response?.data}');
      }
      return _extractError(e, 'Failed to update hold status');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // INITIATE RETURN — POST /api/v1/user/delivery (NOT PUT)
  // otpType: 'store_otp_number' (merchant) or 'customer' depending on who
  // the original app's "Universal OTP Target Selection" sends to.
  // otp: optional — only provided when the user has already entered an OTP.
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> initiateReturn({
    required String consignmentId,
    required int runOrderId,
    required String reason,
    int proceedMethod = ProceedMethod.general,
    String otpType = OtpType.storeOtpNumber,
    String? otp,
  }) async {
    if (runOrderId <= 0) {
      return 'Invalid run order ID ($runOrderId). Cannot initiate return.';
    }
    final dioClient = DioClient();

    final formData = FormData.fromMap({
      'run_order_id': runOrderId,
      'status': DeliveryStatus.returned,
      'reason': reason,
      'otp_type': otpType,
      if (otp != null && otp.isNotEmpty) 'otp': otp,
      if (proceedMethod != 0) 'proceed_method': proceedMethod,
    });

    try {
      print('=== INITIATE RETURN REQUEST ===');
      print('URL: ${ApiEndpoints.deliveryUpdate}');
      print('PAYLOAD: run_order_id=$runOrderId, status=${DeliveryStatus.returned}, reason=$reason, otp_type=$otpType');

      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryUpdate,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      print('=== INITIATE RETURN RESPONSE ===');
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.returned, reason: reason);
        return null;
      }
      return 'Server error: Status ${response.statusCode}';
    } catch (e) {
      print('=== RETURN FormData failed ===');
      if (e is DioException) {
        print('STATUS: ${e.response?.statusCode}');
        print('DATA: ${e.response?.data}');
      }
      return _extractError(e, 'Failed to initiate return');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QC OTP — POST /api/v1/user/delivery/check/qc-otp
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> submitQcOtp({
    required String consignmentId,
    required int runOrderId,
    required String otp,
    String otpType = OtpType.storeOtpNumber, // ✅ correct default
  }) async {
    try {
      final dioClient = DioClient();

      // ✅ JSON body, correct otp_type
      final payload = <String, dynamic>{
        'run_order_id': runOrderId,
        'otp': otp,
        'otp_type': otpType, // ✅ 'store_otp_number', NOT 'customer'
      };

      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryQcOtp,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.delivered);
        return null;
      }
      return 'Server error: Status ${response.statusCode}';
    } catch (e) {
      return _extractError(e, 'Failed to submit QC OTP');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RESEND OTP SMS — POST /api/v1/user/delivery/sms-resend
  //
  // The real app only sends run_order_id.
  // ───────────────────────────────────────────────────────────────────────────
  Future<bool> resendOtpSms({
    required int runOrderId,
    // The following are accepted for compatibility but the real API only needs run_order_id
    int status = DeliveryStatus.delivered,
    String otpType = OtpType.storeOtpNumber,
    String? reason,
    double? collectedAmount,
  }) async {
    try {
      final dioClient = DioClient();

      // ✅ API requires run_order_id and otp_type
      final payload = <String, dynamic>{
        'run_order_id': runOrderId,
        'otp_type': otpType,
      };

      print('=== SMS RESEND REQUEST ===');
      print('URL: ${ApiEndpoints.deliverySmsResend}');
      print('PAYLOAD: $payload');

      final response = await dioClient.dio.post(
        ApiEndpoints.deliverySmsResend,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('=== SMS RESEND RESPONSE ===');
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('=== SMS RESEND ERROR ===');
      if (e is DioException) {
        print('STATUS: ${e.response?.statusCode}');
        print('DATA: ${e.response?.data}');
      }
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RETURN SMS RESEND — POST /api/v1/user/return-sms-resend
  // Separate endpoint for return OTP resend (distinct from delivery sms-resend)
  // ───────────────────────────────────────────────────────────────────────────
  Future<bool> returnSmsResend({
    required int runOrderId,
    String otpType = OtpType.storeOtpNumber,
  }) async {
    try {
      final dioClient = DioClient();
      final payload = <String, dynamic>{
        'run_order_id': runOrderId,
        'otp_type': otpType,
      };

      print('=== RETURN SMS RESEND REQUEST ===');
      print('URL: ${ApiEndpoints.returnSmsResend}');
      print('PAYLOAD: $payload');

      final response = await dioClient.dio.post(
        ApiEndpoints.returnSmsResend,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('=== RETURN SMS RESEND RESPONSE ===');
      print('STATUS: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('=== RETURN SMS RESEND ERROR ===');
      if (e is DioException) {
        print('STATUS: ${e.response?.statusCode}');
        print('DATA: ${e.response?.data}');
      }
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PARTIAL DELIVERY — POST /api/v1/user/delivery/check, status=7
  // Always requires Merchant OTP + collected_amount + delivered_parcel_count
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> sendPartialDelivery({
    required String consignmentId,
    required int runOrderId,
    required double collectedAmount,
    required int deliveredCount,
    required String otp,
    String otpType = OtpType.storeOtpNumber,
  }) async {
    try {
      final dioClient = DioClient();

      final payload = <String, dynamic>{
        'run_order_id': runOrderId,
        'status': DeliveryStatus.partialDelivery, // 7
        'collected_amount': collectedAmount.toInt(),
        'delivered_parcel_count': deliveredCount,
        'otp_type': otpType,
        'otp': otp,
        'proceed_method': ProceedMethod.general,
      };

      print('=== PARTIAL DELIVERY REQUEST ===');
      print('URL: ${ApiEndpoints.deliveryComplete}');
      print('PAYLOAD: run_order_id=$runOrderId, status=${DeliveryStatus.partialDelivery}, amount=${collectedAmount.toInt()}, count=$deliveredCount');

      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryComplete,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.partialDelivery);
        return null;
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return _extractError(e, 'Failed to submit partial delivery');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DRTO — POST /api/v1/user/delivery/check, status=9
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> sendDrto({
    required String consignmentId,
    required int runOrderId,
    required double collectedAmount,
    required String reason,
    required String otp,
  }) async {
    try {
      final dioClient = DioClient();

      final payload = <String, dynamic>{
        'run_order_id': runOrderId,
        'status': DeliveryStatus.drto, // DRTO (9)
        'collected_amount': collectedAmount.toInt(), // Server needs integer
        'reason': reason,
        'otp_type': OtpType.storeOtpNumber,
        'otp': otp,
        'proceed_method': ProceedMethod.general,
      };

      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryComplete,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.drto);
        return null;
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return _extractError(e, 'Failed to mark DRTO');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FETCH RETURN REASONS
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> fetchReturnReasons() async {
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.returnReasons);
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          List<String> parsedReasons = [];
          for (var group in data) {
            final reasons = group['reasons'];
            if (reasons is List) {
              for (var reasonObj in reasons) {
                if (reasonObj['en'] != null) {
                  parsedReasons.add(reasonObj['en'].toString());
                }
              }
            }
          }
          if (state.hasValue) {
            state = AsyncValue.data(state.value!.copyWith(returnReasons: parsedReasons));
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch return reasons: $e');
    }
  }



  // ───────────────────────────────────────────────────────────────────────────
  // PRICE CHANGE — POST /api/v1/user/delivery/check, status=8
  // Requires Merchant OTP (v2.md section 3: "Price Change: Requires ... Merchant's OTP")
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> sendPriceChange({
    required String consignmentId,
    required int runOrderId,
    required double newAmount,
    required String otp,
    String otpType = OtpType.storeOtpNumber,
    String? reason,
  }) async {
    try {
      final dioClient = DioClient();

      final payload = <String, dynamic>{
        'run_order_id': runOrderId,
        'status': DeliveryStatus.priceChange, // PRICE_CHANGE (8)
        'collected_amount': newAmount.toInt(),
        'otp_type': otpType,
        'otp': otp,
        'proceed_method': ProceedMethod.general,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      print('=== PRICE CHANGE REQUEST ===');
      print('URL: ${ApiEndpoints.deliveryComplete}');
      print('PAYLOAD: run_order_id=$runOrderId, status=${DeliveryStatus.priceChange}, amount=${newAmount.toInt()}');

      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryComplete,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.priceChange);
        return null;
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return _extractError(e, 'Failed to submit price change');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EXCHANGE — POST /api/v1/user/delivery/check, status=10
  // Requires Merchant OTP only — no amount, no reason
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> sendExchange({
    required String consignmentId,
    required int runOrderId,
    required String otp,
    String otpType = OtpType.storeOtpNumber,
  }) async {
    try {
      final dioClient = DioClient();

      final payload = <String, dynamic>{
        'run_order_id': runOrderId,
        'status': DeliveryStatus.exchange, // EXCHANGE (10)
        'otp_type': otpType,
        'otp': otp,
        'proceed_method': ProceedMethod.general,
      };

      print('=== EXCHANGE REQUEST ===');
      print('URL: ${ApiEndpoints.deliveryComplete}');
      print('PAYLOAD: run_order_id=$runOrderId, status=${DeliveryStatus.exchange}, otp=***');

      final response = await dioClient.dio.post(
        ApiEndpoints.deliveryComplete,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateStatus(consignmentId, DeliveryStatus.exchange);
        return null;
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return _extractError(e, 'Failed to submit exchange');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UPLOAD FILE TO CDN
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> uploadFileToCdn({
    required String filePath,
    required String type,
    String? consignmentId,
  }) async {
    try {
      final dioClient = DioClient();
      final formData = FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(filePath),
        if (consignmentId != null) 'consignment_id': consignmentId,
      });

      final response = await dioClient.dio.post(
        ApiEndpoints.cdnBase + ApiEndpoints.cdnUpload,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        return response.data['url']?.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QC REQUEST SUBMISSION
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> submitQcRequest({
    required String consignmentId,
    required String imagePath,
    required String reason,
  }) async {
    try {
      // 1. Upload image
      final imageUrl = await uploadFileToCdn(
        filePath: imagePath,
        type: 'qc',
        consignmentId: consignmentId,
      );

      if (imageUrl == null) {
        return 'Failed to upload proof image to CDN';
      }

      // 2. Submit QC request
      final dioClient = DioClient();
      final response = await dioClient.dio.post(
        ApiEndpoints.qcRequest,
        data: {
          'consignment_id': consignmentId,
          'scanned_barcode': consignmentId,
          'proof_image_url': imageUrl,
          'proof_type': 'qr_scan',
          'reason': reason,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }
      return 'Server error: Status ${response.statusCode}';
    } catch (e) {
      return _extractError(e, 'Failed to submit QC Request');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DIGITAL PAYMENT LINK
  // POST /api/v1/user/payments/send-link
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> sendPaymentLink({required int runOrderId}) async {
    try {
      final dioClient = DioClient();
      final payload = {'run_order_id': runOrderId};

      print('=== SEND PAYMENT LINK REQUEST ===');
      print('URL: ${ApiEndpoints.sendPaymentLink}');
      print('PAYLOAD: $payload');

      final response = await dioClient.dio.post(
        ApiEndpoints.sendPaymentLink,
        data: payload,
      );

      print('STATUS: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success
      }
      return 'Server error: Status ${response.statusCode}';
    } catch (e) {
      return _extractError(e, 'Failed to send payment link');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final deliveryProvider =
    StateNotifierProvider<DeliveryNotifier, AsyncValue<DeliveryState>>((ref) {
  return DeliveryNotifier();
});

/// Provider to fetch hold reasons from server
final holdReasonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dioClient = DioClient();
    final response = await dioClient.dio.get(ApiEndpoints.holdReasons);
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((e) {
          if (e is Map) {
            return {
              'id': e['id'],
              'en': e['en']?.toString() ?? e['name']?.toString() ?? '',
              'bn': e['bn']?.toString() ?? e['name']?.toString() ?? '',
            };
          }
          return {
            'id': 0,
            'en': e.toString(),
            'bn': e.toString(),
          };
        }).toList();
      }
    }
  } catch (_) {}
  // Fallback reasons if API fails
  return [
    {'id': 0, 'en': 'Customer not available', 'bn': 'কাস্টমার অনুপস্থিত'},
    {'id': 0, 'en': 'Wrong phone number', 'bn': 'ভুল ফোন নাম্বার'},
    {'id': 0, 'en': 'Customer refused to receive', 'bn': 'কাস্টমার রিসিভ করতে অস্বীকৃতি জানিয়েছে'},
    {'id': 0, 'en': 'Address incorrect', 'bn': 'ভুল ঠিকানা'},
    {'id': 0, 'en': 'Will collect later', 'bn': 'পরে সংগ্রহ করবে'},
  ];
});

/// Provider to fetch return reasons from server
final returnReasonsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final dioClient = DioClient();
    final response = await dioClient.dio.get(ApiEndpoints.returnReasons);
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data
            .map((e) => e['name']?.toString() ?? e.toString())
            .toList();
      }
    }
  } catch (_) {}
  // Fallback reasons if API fails
  return [
    'Merchant requested return',
    'Customer rejected packaging',
    'Item damaged in transit',
    'Wrong item delivered',
    'Customer address not found',
  ];
});
