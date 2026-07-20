import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'delivery_provider.dart';

class RunState {
  final bool isDeliveryStarted;
  final bool isLoading;
  final String? errorMessage;

  RunState({
    this.isDeliveryStarted = false,
    this.isLoading = false,
    this.errorMessage,
  });

  RunState copyWith({
    bool? isDeliveryStarted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RunState(
      isDeliveryStarted: isDeliveryStarted ?? this.isDeliveryStarted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RunNotifier extends StateNotifier<RunState> {
  final Ref ref;
  RunNotifier(this.ref) : super(RunState());

  Future<String?> startDelivery() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final deliveryState = ref.read(deliveryProvider).value;
      if (deliveryState == null || deliveryState.orders.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'No run route ID found (empty deliveries)');
        return 'No deliveries found';
      }
      final runRouteId = deliveryState.orders.first.runRouteId;

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final dioClient = DioClient();
      await dioClient.dio.patch(
        '/api/v1/user/runs/$runRouteId',
        data: {
          'status_id': 3,
          'lat': position.latitude.toString(),
          'lon': position.longitude.toString(),
        },
      );

      state = state.copyWith(isLoading: false, isDeliveryStarted: true);
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return 'Failed to start delivery: $msg';
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return 'Failed to start delivery: $e';
    }
  }

  Future<String?> endDelivery() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final deliveryState = ref.read(deliveryProvider).value;
      if (deliveryState == null || deliveryState.orders.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'No run route ID found');
        return 'No deliveries found';
      }
      final runRouteId = deliveryState.orders.first.runRouteId;

      final dioClient = DioClient();
      await dioClient.dio.patch(
        '/api/v1/user/runs/$runRouteId',
        data: {
          'status_id': 4,
        },
      );

      state = state.copyWith(isLoading: false, isDeliveryStarted: false);
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return 'Failed to end delivery: $msg';
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return 'Failed to end delivery: $e';
    }
  }
}

final runProvider = StateNotifierProvider<RunNotifier, RunState>((ref) {
  return RunNotifier(ref);
});
