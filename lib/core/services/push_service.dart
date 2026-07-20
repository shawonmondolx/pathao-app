import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../constants/api_endpoints.dart';
// Note: In a real app this would depend on Firebase Messaging to get the token.
// For now, we mock the device FCM token string.

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService();
});

class PushService {
  String? _fcmToken = 'mock_fcm_token_xyz123'; 

  /// Call this ONLY when the shift starts (Finding 76)
  Future<void> subscribeToShiftPush() async {
    if (_fcmToken == null) return;
    try {
      final dioClient = DioClient();
      await dioClient.dio.post(
        ApiEndpoints.pushSubscribe,
        data: {
          'token': _fcmToken,
          'device_type': 'android',
        },
      );
    } catch (e) {
      // Background push subscription failed
    }
  }

  /// Call this instantly when the shift ends to conserve battery and kill phantom notifications (Finding 76)
  Future<void> unsubscribeFromShiftPush() async {
    if (_fcmToken == null) return;
    try {
      final dioClient = DioClient();
      await dioClient.dio.post(
        ApiEndpoints.pushUnsubscribe,
        data: {
          'token': _fcmToken,
        },
      );
    } catch (e) {
      // Unsubscribe failed
    }
  }
}
