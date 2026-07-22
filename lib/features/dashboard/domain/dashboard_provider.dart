import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class DashboardStats {
  final double cashCollected;
  final double cashCollectableTotal;
  final int deliveryTotal;
  final int deliveryCompleted;
  final int priceChange;
  final int returned;
  final int partialDelivery;
  final int onHold;
  final int delivered;
  final int pending;
  final int drto;
  final int exchange;
  final bool isRunClosed;
  final bool hasDelivery;
  final bool hasPickup;

  int get calculatedCompleted => delivered + priceChange + returned + partialDelivery + onHold + drto + exchange;

  DashboardStats({
    required this.cashCollected,
    required this.cashCollectableTotal,
    required this.deliveryTotal,
    required this.deliveryCompleted,
    required this.priceChange,
    required this.returned,
    required this.partialDelivery,
    required this.onHold,
    required this.delivered,
    required this.pending,
    required this.drto,
    required this.exchange,
    this.isRunClosed = false,
    this.hasDelivery = true,
    this.hasPickup = false,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      cashCollected: 0,
      cashCollectableTotal: 0,
      deliveryTotal: 0,
      deliveryCompleted: 0,
      priceChange: 0,
      returned: 0,
      partialDelivery: 0,
      onHold: 0,
      delivered: 0,
      pending: 0,
      drto: 0,
      exchange: 0,
    );
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json, {int localReturnCount = 0}) {
    int delivered = json['delivery_completed'] ?? json['delivered'] ?? 0;
    int priceChange = json['price_change'] ?? 0;
    int returned = (json['returned'] ?? json['return'] ?? 0) + localReturnCount;
    int partialDelivery = json['partial_delivery'] ?? 0;
    int onHoldRaw = json['on_hold'] ?? 0;
    int onHold = (onHoldRaw - localReturnCount < 0) ? 0 : (onHoldRaw - localReturnCount);
    int drto = json['drto'] ?? 0;
    int exchange = json['exchange'] ?? 0;
    int totalCompleted = delivered + priceChange + returned + partialDelivery + onHold + drto + exchange;

    return DashboardStats(
      cashCollected: (json['cash_collected'] ?? 0).toDouble(),
      cashCollectableTotal: (json['cash_collectable_total'] ?? 0).toDouble(),
      deliveryTotal: json['delivery_total'] ?? 0,
      deliveryCompleted: totalCompleted,
      priceChange: priceChange,
      returned: returned,
      partialDelivery: partialDelivery,
      onHold: onHold,
      delivered: delivered,
      pending: json['pending'] ?? 0,
      drto: drto,
      exchange: exchange,
      isRunClosed: json['is_run_closed'] ?? false,
      hasDelivery: json['has_delivery'] ?? true,
      hasPickup: json['has_pickup'] ?? false,
    );
  }
}

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  DashboardNotifier() : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.dashboard);
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        
        final prefs = await SharedPreferences.getInstance();
        final localReturnRequests = prefs.getStringList('local_return_requests') ?? [];
        int localCount = localReturnRequests.length;
        
        state = AsyncValue.data(DashboardStats.fromJson(Map<String, dynamic>.from(data), localReturnCount: localCount));
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      // Show empty stats on error but don't fake data
      state = AsyncValue.data(DashboardStats.empty());
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>((ref) {
  return DashboardNotifier();
});

class ShiftNotifier extends StateNotifier<bool> {
  ShiftNotifier() : super(false);

  void toggleShift() {
    state = !state;
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, bool>((ref) {
  return ShiftNotifier();
});
