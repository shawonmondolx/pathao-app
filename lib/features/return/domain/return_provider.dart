import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Represents a single return parcel/consignment in the checklist.
/// Maps directly to the `return_order_statuses` object the Hermes backend expects.
class ReturnOrderStatus {
  final String consignmentId;
  String status; // e.g. 'RETURNED' or 'PENDING'
  final int? returnReasonId;

  ReturnOrderStatus({
    required this.consignmentId,
    this.status = 'RETURNED',
    this.returnReasonId,
  });

  Map<String, dynamic> toJson() => {
        'consignment_id': consignmentId,
        'status': status,
        if (returnReasonId != null) 'return_reason_id': returnReasonId,
      };

  factory ReturnOrderStatus.fromJson(Map<String, dynamic> json) {
    return ReturnOrderStatus(
      consignmentId: json['consignment_id']?.toString() ??
          json['consignment']?.toString() ??
          json['id']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'RETURNED',
      returnReasonId: json['return_reason_id'] as int?,
    );
  }
}

/// Represents a merchant group in the return list for Delivery Agent.
class MerchantReturn {
  final int storeId;
  final int? runRouteId; // needed for return-done-check payload
  final String storeName;
  final String merchantName;
  final String contactNumber;
  final String address;
  String status;

  /// The key is consignment_id (String). Stored as a Map so we can do
  /// Object.values(returnOrderStatuses) → JSON.stringify(...)
  /// which mirrors the exact Hermes JS data model.
  final Map<String, ReturnOrderStatus> returnOrderStatuses;

  MerchantReturn({
    required this.storeId,
    this.runRouteId,
    required this.storeName,
    required this.merchantName,
    required this.contactNumber,
    required this.address,
    required this.status,
    required this.returnOrderStatuses,
  });

  int get totalPackages => returnOrderStatuses.length;

  factory MerchantReturn.fromJson(Map<String, dynamic> json) {
    // Parse the consignments / orders list into the statuses map
    final Map<String, ReturnOrderStatus> statuses = {};
    final rawOrders = json['orders'] ?? json['consignments'] ?? json['packages'] ?? [];
    if (rawOrders is List) {
      for (final order in rawOrders) {
        final o = Map<String, dynamic>.from(order as Map);
        final status = ReturnOrderStatus.fromJson(o);
        if (status.consignmentId.isNotEmpty) {
          statuses[status.consignmentId] = status;
        }
      }
    }

    return MerchantReturn(
      storeId: (json['store_id'] ?? json['id'] ?? 0) as int,
      runRouteId: json['run_route_id'] as int?,
      storeName: json['store_name']?.toString() ?? json['merchant_name']?.toString() ?? 'Unknown Store',
      merchantName: json['merchant_name']?.toString() ?? 'Unknown Merchant',
      contactNumber:
          (json['contact_number'] ?? json['phone'] ?? '').toString(),
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      returnOrderStatuses: statuses,
    );
  }

  /// Builds the `return_order_statuses` field exactly as Hermes JS does:
  ///   JSON.stringify(Object.values(returnOrderStatuses))
  String buildReturnOrderStatusesPayload() {
    final list = returnOrderStatuses.values.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  MerchantReturn copyWith({String? status}) {
    return MerchantReturn(
      storeId: storeId,
      runRouteId: runRouteId,
      storeName: storeName,
      merchantName: merchantName,
      contactNumber: contactNumber,
      address: address,
      status: status ?? this.status,
      returnOrderStatuses: returnOrderStatuses,
    );
  }

  MerchantReturn copyWithUpdatedStatus(String consignmentId, String newStatus) {
    final updatedStatuses = Map<String, ReturnOrderStatus>.from(returnOrderStatuses);
    if (updatedStatuses.containsKey(consignmentId)) {
      updatedStatuses[consignmentId] = ReturnOrderStatus(
        consignmentId: consignmentId,
        status: newStatus,
        returnReasonId: updatedStatuses[consignmentId]?.returnReasonId,
      );
    }
    return MerchantReturn(
      storeId: storeId,
      runRouteId: runRouteId,
      storeName: storeName,
      merchantName: merchantName,
      contactNumber: contactNumber,
      address: address,
      status: status,
      returnOrderStatuses: updatedStatuses,
    );
  }

  MerchantReturn copyWithAllStatuses(String newStatus) {
    final updatedStatuses = <String, ReturnOrderStatus>{};
    returnOrderStatuses.forEach((key, val) {
      updatedStatuses[key] = ReturnOrderStatus(
        consignmentId: val.consignmentId,
        status: newStatus,
        returnReasonId: val.returnReasonId,
      );
    });
    return MerchantReturn(
      storeId: storeId,
      runRouteId: runRouteId,
      storeName: storeName,
      merchantName: merchantName,
      contactNumber: contactNumber,
      address: address,
      status: status,
      returnOrderStatuses: updatedStatuses,
    );
  }
}

// ---------------------------------------------------------------------------
// Return result — what happens after submitting the checklist
// ---------------------------------------------------------------------------

class ReturnDoneResult {
  /// If true, the backend accepted and completed the return (no OTP needed).
  final bool isComplete;

  /// If true, this merchant requires OTP. Show the OTP screen/dialog.
  final bool requiresOtp;

  /// Server error message, if any.
  final String? errorMessage;

  const ReturnDoneResult({
    this.isComplete = false,
    this.requiresOtp = false,
    this.errorMessage,
  });
}

// ---------------------------------------------------------------------------
// Provider State
// ---------------------------------------------------------------------------

class ReturnNotifier
    extends StateNotifier<AsyncValue<List<MerchantReturn>>> {
  ReturnNotifier() : super(const AsyncValue.loading()) {
    fetchReturns();
  }

  // ── 1. Fetch delivery agent return list ──────────────────────────────────

  Future<void> fetchReturns() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.returnList);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        List<MerchantReturn> returns = [];

        if (data is List) {
          returns = data
              .map((e) =>
                  MerchantReturn.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        } else if (data is Map) {
          final inner = data['returns'] ?? data['stores'] ?? data['data'];
          if (inner is List) {
            returns = inner
                .map((e) => MerchantReturn.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList();
          }
        }

        state = AsyncValue.data(returns);
      } else {
        state = AsyncValue.error(
            'Failed to load delivery returns', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── 2. Fetch store-level return detail (individual consignments) ──────────

  Future<MerchantReturn?> fetchReturnDetail(int storeId) async {
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio
          .get('/api/v1/user/return/$storeId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final detail = MerchantReturn.fromJson(
            Map<String, dynamic>.from(data as Map));
        _updateMerchantLocally(detail);
        return detail;
      }
    } catch (_) {}
    return null;
  }

  // ── 3. Submit the return checklist → return-done ─────────────────────────
  //
  // This is the FIRST call when the delivery agent taps "Submit Return".
  // Payload (JSON): { store_id, return_order_statuses: "<json-stringified array>" }
  //
  // Response logic:
  //   • HTTP 200/201 with no otp flag  → return complete, no OTP needed
  //   • HTTP 200/201 with otp_required → show OTP screen / dialog
  //   • Any other                      → error

  Future<ReturnDoneResult> submitReturnChecklist({
    required MerchantReturn merchant,
  }) async {
    try {
      final dioClient = DioClient();

      final payload = {
        'store_id': merchant.storeId,
        'return_order_statuses':
            merchant.buildReturnOrderStatusesPayload(),
      };

      final response = await dioClient.dio.post(
        ApiEndpoints.returnDone,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        final otpRequired = body?['otp_required'] == true ||
            body?['data']?['otp_required'] == true ||
            body?['message']
                    ?.toString()
                    .toLowerCase()
                    .contains('otp') ==
                true;

        if (otpRequired) {
          return const ReturnDoneResult(requiresOtp: true);
        }
        // No OTP needed → return success
        _updateStatusLocally(merchant.storeId, 'RETURNED');
        return const ReturnDoneResult(isComplete: true);
      }

      return ReturnDoneResult(
          errorMessage: 'Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.message ??
          'Request failed';
      return ReturnDoneResult(errorMessage: msg);
    } catch (e) {
      return ReturnDoneResult(errorMessage: e.toString());
    }
  }

  // ── 4. Verify OTP → return-done-check ────────────────────────────────────
  //
  // Only called when submitReturnChecklist returns requiresOtp == true.
  //
  // Payload: multipart/form-data
  //   • run_route_id         (int, if available)
  //   • store_id             (int)
  //   • return_order_statuses (JSON-stringified array, same as step 3)
  //   • otp                  (string, 4-digit code from merchant)
  //   • pickup_slip          (optional — base64 data URI if a slip image is present)

  Future<String?> verifyReturnOtp({
    required MerchantReturn merchant,
    required String otp,
    File? pickupSlipFile,
  }) async {
    try {
      final dioClient = DioClient();
      final formData = FormData();

      if (merchant.runRouteId != null) {
        formData.fields
            .add(MapEntry('run_route_id', merchant.runRouteId.toString()));
      }
      formData.fields
          .add(MapEntry('store_id', merchant.storeId.toString()));
      formData.fields.add(MapEntry(
        'return_order_statuses',
        merchant.buildReturnOrderStatusesPayload(),
      ));
      formData.fields.add(MapEntry('otp', otp));

      // Attach pickup slip image if provided (data:image/jpeg;base64,...)
      if (pickupSlipFile != null) {
        final bytes = await pickupSlipFile.readAsBytes();
        final b64 = base64Encode(bytes);
        final mimeType = 'image/jpeg';
        final dataUri = 'data:$mimeType;base64,$b64';
        formData.fields.add(MapEntry('pickup_slip', dataUri));
      }

      final response = await dioClient.dio.post(
        ApiEndpoints.returnDoneCheck,
        data: formData,
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _updateStatusLocally(merchant.storeId, 'RETURNED');
        return null; // null = success
      }
      return 'Server error: ${response.statusCode}';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to verify OTP. Please try again.';
    } catch (e) {
      return 'Failed to verify OTP. Please try again.';
    }
  }

  // ── 5. Resend OTP → return-sms-resend ────────────────────────────────────
  //
  // Called ONLY from the OTP UI "Resend Code" button.
  // Payload: { store_id }

  Future<bool> resendReturnOtp({required int storeId}) async {
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.post(
        ApiEndpoints.returnSmsResend,
        data: {'store_id': storeId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Package status updates ───────────────────────────────────────────────

  void updatePackageStatus(int storeId, String consignmentId, String status) {
    if (state is AsyncData) {
      final current = state.value!;
      state = AsyncValue.data([
        for (final item in current)
          if (item.storeId == storeId)
            item.copyWithUpdatedStatus(consignmentId, status)
          else
            item
      ]);
    }
  }

  void updateAllPackageStatuses(int storeId, String status) {
    if (state is AsyncData) {
      final current = state.value!;
      state = AsyncValue.data([
        for (final item in current)
          if (item.storeId == storeId)
            item.copyWithAllStatuses(status)
          else
            item
      ]);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updateMerchantLocally(MerchantReturn detail) {
    if (state is AsyncData) {
      final current = state.value!;
      final exists = current.any((element) => element.storeId == detail.storeId);
      if (exists) {
        state = AsyncValue.data([
          for (final item in current)
            if (item.storeId == detail.storeId) detail else item
        ]);
      } else {
        state = AsyncValue.data([...current, detail]);
      }
    }
  }

  void _updateStatusLocally(int storeId, String status) {
    if (state is AsyncData) {
      final current = state.value!;
      state = AsyncValue.data([
        for (final item in current)
          if (item.storeId == storeId) item.copyWith(status: status) else item
      ]);
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod Provider
// ---------------------------------------------------------------------------

final returnProvider =
    StateNotifierProvider<ReturnNotifier, AsyncValue<List<MerchantReturn>>>(
  (ref) => ReturnNotifier(),
);
