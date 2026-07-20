import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class MerchantPickup {
  final int storeId;
  final String storeName;
  final String merchantName;
  final String contactNumber;
  final String address;
  final int totalPackages;
  final String status;

  MerchantPickup({
    required this.storeId,
    required this.storeName,
    required this.merchantName,
    required this.contactNumber,
    required this.address,
    required this.totalPackages,
    required this.status,
  });

  factory MerchantPickup.fromJson(Map<String, dynamic> json) {
    return MerchantPickup(
      storeId: json['store_id'] ?? json['id'] ?? 0,
      storeName: json['store_name'] ?? 'Unknown Store',
      merchantName: json['merchant_name'] ?? 'Unknown Merchant',
      contactNumber: json['contact_number'] ?? json['phone'] ?? '',
      address: json['address'] ?? '',
      totalPackages: json['total_packages'] ?? json['package_count'] ?? 0,
      status: json['status'] ?? 'PENDING',
    );
  }

  MerchantPickup copyWith({
    String? status,
  }) {
    return MerchantPickup(
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

class PickupNotifier extends StateNotifier<AsyncValue<List<MerchantPickup>>> {
  PickupNotifier() : super(const AsyncValue.loading()) {
    fetchPickups();
  }

  Future<void> fetchPickups() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.pickupList);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        List<MerchantPickup> pickups = [];
        if (data is List) {
          pickups = data.map((e) => MerchantPickup.fromJson(Map<String, dynamic>.from(e))).toList();
        } else if (data['pickups'] != null && data['pickups'] is List) {
          pickups = (data['pickups'] as List).map((e) => MerchantPickup.fromJson(Map<String, dynamic>.from(e))).toList();
        }

        state = AsyncValue.data(pickups);
      } else {
        state = AsyncValue.error('Failed to load pickups', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updatePickupStatus(int storeId, String status) {
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

  Future<bool> requestPickupOtp({required int storeId}) async {
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.post(
        ApiEndpoints.pickupSmsResend,
        data: {'store_id': storeId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<String?> verifyPickupOtp({
    required int storeId,
    required String otp,
  }) async {
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.post(
        ApiEndpoints.pickupDone,
        data: {
          'store_id': storeId,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        updatePickupStatus(storeId, 'PICKED');
        return null;
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return 'Failed to verify OTP. Please try again.';
    }
  }
}

final pickupProvider = StateNotifierProvider<PickupNotifier, AsyncValue<List<MerchantPickup>>>((ref) {
  return PickupNotifier();
});
