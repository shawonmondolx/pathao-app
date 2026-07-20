import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class MerchantReturn {
  final int storeId;
  final String storeName;
  final String merchantName;
  final String contactNumber;
  final String address;
  final int totalPackages;
  final String status;

  MerchantReturn({
    required this.storeId,
    required this.storeName,
    required this.merchantName,
    required this.contactNumber,
    required this.address,
    required this.totalPackages,
    required this.status,
  });

  factory MerchantReturn.fromJson(Map<String, dynamic> json) {
    return MerchantReturn(
      storeId: json['store_id'] ?? json['id'] ?? 0,
      storeName: json['store_name'] ?? 'Unknown Store',
      merchantName: json['merchant_name'] ?? 'Unknown Merchant',
      contactNumber: json['contact_number'] ?? json['phone'] ?? '',
      address: json['address'] ?? '',
      totalPackages: json['total_packages'] ?? json['package_count'] ?? 0,
      status: json['status'] ?? 'PENDING',
    );
  }

  MerchantReturn copyWith({
    String? status,
  }) {
    return MerchantReturn(
      storeId: storeId,
      storeName: storeName,
      merchantName: merchantName,
      contactNumber: contactNumber,
      address: address,
      totalPackages: totalPackages,
      status: status ?? this.status,
    );
  }
}

class ReturnNotifier extends StateNotifier<AsyncValue<List<MerchantReturn>>> {
  ReturnNotifier() : super(const AsyncValue.loading()) {
    fetchReturns();
  }

  Future<void> fetchReturns() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.returnList);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        List<MerchantReturn> returns = [];
        if (data is List) {
          returns = data.map((e) => MerchantReturn.fromJson(Map<String, dynamic>.from(e))).toList();
        } else if (data['returns'] != null && data['returns'] is List) {
          returns = (data['returns'] as List).map((e) => MerchantReturn.fromJson(Map<String, dynamic>.from(e))).toList();
        }

        state = AsyncValue.data(returns);
      } else {
        state = AsyncValue.error('Failed to load returns', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateReturnStatus(int storeId, String status) {
    if (state is AsyncData) {
      final currentList = state.value!;
      state = AsyncValue.data([
        for (final item in currentList)
          if (item.storeId == storeId)
            item.copyWith(status: status)
          else
            item
      ]);
    }
  }

  Future<bool> requestReturnOtp({required int storeId}) async {
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.post(
        ApiEndpoints.returnSmsResend,
        data: {'store_id': storeId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<String?> verifyReturnOtp({
    required int storeId,
    required String otp,
  }) async {
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.post(
        ApiEndpoints.returnDone,
        data: {
          'store_id': storeId,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        updateReturnStatus(storeId, 'RETURNED');
        return null;
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return 'Failed to verify OTP. Please try again.';
    }
  }
}

final returnProvider = StateNotifierProvider<ReturnNotifier, AsyncValue<List<MerchantReturn>>>((ref) {
  return ReturnNotifier();
});
