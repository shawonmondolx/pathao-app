import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../dashboard/domain/dashboard_provider.dart';

class WalletLocation {
  final int id;
  final String name;
  final String type;
  final String address;

  WalletLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
  });

  factory WalletLocation.fromJson(Map<String, dynamic> json) {
    return WalletLocation(
      id: json['wallet_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? json['wallet_name'] ?? 'Unknown Location',
      type: json['type'] ?? json['wallet_type'] ?? 'Bank',
      address: json['address'] ?? json['location'] ?? 'N/A',
    );
  }
}

class WalletState {
  final double cashInHand;
  final List<WalletLocation> locations;

  WalletState({
    required this.cashInHand,
    required this.locations,
  });
}

class WalletNotifier extends StateNotifier<AsyncValue<WalletState>> {
  final Ref ref;

  WalletNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchWallets();
  }

  Future<void> fetchWallets() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.walletList);

      double cashInHand = 0.0;
      final dashState = ref.read(dashboardProvider);
      if (dashState is AsyncData) {
        cashInHand = dashState.value!.cashCollected;
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        List<WalletLocation> locations = [];
        if (data is List) {
          locations = data.map((e) => WalletLocation.fromJson(Map<String, dynamic>.from(e))).toList();
        } else if (data['wallets'] != null && data['wallets'] is List) {
          locations = (data['wallets'] as List).map((e) => WalletLocation.fromJson(Map<String, dynamic>.from(e))).toList();
        }

        state = AsyncValue.data(WalletState(cashInHand: cashInHand, locations: locations));
      } else {
        state = AsyncValue.error('Failed to load wallets', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, AsyncValue<WalletState>>((ref) {
  return WalletNotifier(ref);
});
