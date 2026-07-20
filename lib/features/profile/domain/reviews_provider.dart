import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';

class AgentReview {
  final int rating;
  final String comment;
  final String date;

  AgentReview({
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory AgentReview.fromJson(Map<String, dynamic> json) {
    return AgentReview(
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? json['feedback'] ?? '',
      date: json['date'] ?? json['created_at'] ?? '',
    );
  }
}

class ReviewsNotifier extends StateNotifier<AsyncValue<List<AgentReview>>> {
  ReviewsNotifier() : super(const AsyncValue.loading()) {
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.agentReviews);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        List<AgentReview> reviews = [];
        if (data is List) {
          reviews = data.map((e) => AgentReview.fromJson(Map<String, dynamic>.from(e))).toList();
        } else if (data['reviews'] != null && data['reviews'] is List) {
          reviews = (data['reviews'] as List).map((e) => AgentReview.fromJson(Map<String, dynamic>.from(e))).toList();
        }

        state = AsyncValue.data(reviews);
      } else {
        state = AsyncValue.error('Failed to load reviews', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reviewsProvider = StateNotifierProvider<ReviewsNotifier, AsyncValue<List<AgentReview>>>((ref) {
  return ReviewsNotifier();
});
