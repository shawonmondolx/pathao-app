import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import 'pickup_provider.dart'; // Re-use Pickup model

final c2cProvider = StateNotifierProvider<C2CNotifier, AsyncValue<List<MerchantPickup>>>((ref) {
  return C2CNotifier();
});

class C2CNotifier extends StateNotifier<AsyncValue<List<MerchantPickup>>> {
  C2CNotifier() : super(const AsyncValue.loading()) {
    loadC2CPickups();
  }

  Future<void> loadC2CPickups() async {
    try {
      state = const AsyncValue.loading();
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.c2cPickupList);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final pickups = data.map((json) => MerchantPickup.fromJson(json)).toList();
        state = AsyncValue.data(pickups);
      } else {
        throw Exception('Failed to load C2C Pickups: ${response.statusCode}');
      }
    } catch (e) {
      state = AsyncValue.error('Error fetching C2C Pickups: $e', StackTrace.current);
    }
  }

  /// Update C2C Pickup Attempt (Finding 84 uses UPDATE_C2C_PICKUP_ATTEMPT_URL)
  Future<String?> updateC2CAttempt(String attemptId, String newStatus) async {
    try {
      final dioClient = DioClient();
      final url = ApiEndpoints.updateC2cPickupAttempt.replaceFirst('{attemptId}', attemptId);
      
      final response = await dioClient.dio.patch(
        url,
        data: { 'status': newStatus },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadC2CPickups(); // refresh
        return null; // success
      }
      return 'Failed to update C2C status: ${response.statusCode}';
    } catch (e) {
      return 'Error updating C2C Pickup: $e';
    }
  }
}
