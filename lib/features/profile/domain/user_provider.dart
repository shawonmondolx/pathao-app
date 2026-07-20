import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';

class UserState {
  final String name;
  final String phone;
  final String? imageUrl;
  final String rating;
  final int reviewCount;
  final String agentId;
  final String roleType;

  UserState({
    this.name = 'Loading...',
    this.phone = '',
    this.imageUrl,
    this.rating = '0.00',
    this.reviewCount = 0,
    this.agentId = '',
    this.roleType = 'Freelancer',
  });
}

class UserNotifier extends StateNotifier<AsyncValue<UserState>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.userProfile);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        
        state = AsyncValue.data(UserState(
          name: data['user_name'] ?? 'Agent',
          phone: data['user_phone'] ?? '',
          imageUrl: data['user_image'],
          rating: data['average_rating']?.toString() ?? '0.00',
          reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
          agentId: data['agent_id']?.toString() ?? '',
          roleType: data['agent_type'] ?? 'Freelancer',
        ));
      } else {
        state = AsyncValue.error('Failed to load profile', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserState>>((ref) {
  return UserNotifier();
});
