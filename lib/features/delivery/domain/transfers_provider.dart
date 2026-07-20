import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'transfer_request.dart';
import 'delivery_provider.dart';

class TransfersState {
  final bool isLoading;
  final List<TransferRequest> requests;
  final String? errorMessage;

  TransfersState({
    this.isLoading = false,
    this.requests = const [],
    this.errorMessage,
  });

  TransfersState copyWith({
    bool? isLoading,
    List<TransferRequest>? requests,
    String? errorMessage,
  }) {
    return TransfersState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      errorMessage: errorMessage,
    );
  }
}

class TransfersNotifier extends StateNotifier<TransfersState> {
  final Ref ref;
  TransfersNotifier(this.ref) : super(TransfersState()) {
    loadTransfers();
  }

  Future<void> loadTransfers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dioClient = DioClient();
      
      // Step 1: Get the list of transfers
      final res = await dioClient.dio.get('/api/v1/user/transfers');
      final data = res.data['data'] as List<dynamic>? ?? [];
      
      if (data.isEmpty) {
        state = state.copyWith(isLoading: false, requests: []);
        return;
      }
      
      // We take the first active transfer run route ID if there is one
      final transferRunId = data.first['run_route_id'];
      if (transferRunId == null) {
        state = state.copyWith(isLoading: false, requests: []);
        return;
      }

      // Step 2: Fetch details of that specific transfer run to get the actual orders
      final detailsRes = await dioClient.dio.get('/api/v1/user/transfers/$transferRunId');
      final detailsData = detailsRes.data['data'];
      final orders = detailsData['orders'] as List<dynamic>? ?? [];

      // Create basic request objects since the API only returns the consignment IDs for transfers
      final List<TransferRequest> requests = orders.map((o) {
        return TransferRequest(
          id: o.toString(),
          consignmentId: o.toString(),
          recipientName: 'Transfer Parcel',
          recipientPhone: 'N/A',
          address: 'Incoming from Admin',
          amount: 0,
        );
      }).toList();

      state = state.copyWith(isLoading: false, requests: requests);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.response?.data['message'] ?? e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> acceptTransfer(String orderId) async {
    try {
      final dioClient = DioClient();
      await dioClient.dio.patch('/api/v1/user/deliveries/$orderId/approve');
      
      // Remove from list
      final updatedList = state.requests.where((r) => r.id != orderId).toList();
      state = state.copyWith(requests: updatedList);
      
      // Reload main delivery list so the new parcel appears
      await ref.read(deliveryProvider.notifier).loadDeliveries();
      
      return null; // Success
    } on DioException catch (e) {
      return 'Failed to accept transfer: ${e.response?.data['message'] ?? e.message}';
    } catch (e) {
      return 'Failed to accept transfer: $e';
    }
  }
}

final transfersProvider = StateNotifierProvider<TransfersNotifier, TransfersState>((ref) {
  return TransfersNotifier(ref);
});
