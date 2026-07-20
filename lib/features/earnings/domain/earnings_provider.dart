import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';

class Transaction {
  final String date;
  final String desc;
  final double amount;

  Transaction({required this.date, required this.desc, required this.amount});
}

class EarningsState {
  final double totalUnpaid;
  final double totalEarned;
  final double paidToDate;
  final String nextPayoutDate;
  final List<Transaction> transactions;

  EarningsState({
    this.totalUnpaid = 0.0,
    this.totalEarned = 0.0,
    this.paidToDate = 0.0,
    this.nextPayoutDate = 'Unknown',
    this.transactions = const [],
  });
}

class EarningsNotifier extends StateNotifier<AsyncValue<EarningsState>> {
  EarningsNotifier() : super(const AsyncValue.loading()) {
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    state = const AsyncValue.loading();
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.get(ApiEndpoints.earnings);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        double parseAmount(dynamic val) {
          if (val == null) return 0.0;
          if (val is num) return val.toDouble();
          if (val is String) return double.tryParse(val) ?? 0.0;
          return 0.0;
        }

        // Handle potential nested wrapper like "data"
        final body = data['data'] ?? data;

        final unpaid = parseAmount(body['total_unpaid'] ?? body['unpaid_balance'] ?? body['unpaid']);
        final earned = parseAmount(body['total_earned'] ?? body['total_earnings'] ?? body['earned']);
        final paid = parseAmount(body['paid_to_date'] ?? body['total_paid'] ?? body['paid']);
        final nextPayout = body['next_payout_date']?.toString() ?? 'Pending';

        final rawTxns = body['transactions'] ?? body['history'] ?? body['earnings_history'] ?? [];
        List<Transaction> txns = [];
        if (rawTxns is List) {
          txns = rawTxns.map((t) => Transaction(
            date: t['date']?.toString() ?? t['created_at']?.toString() ?? 'Unknown Date',
            desc: t['desc'] ?? t['description'] ?? t['title'] ?? 'Transaction',
            amount: parseAmount(t['amount'] ?? t['value']),
          )).toList();
        }

        state = AsyncValue.data(EarningsState(
          totalUnpaid: unpaid,
          totalEarned: earned,
          paidToDate: paid,
          nextPayoutDate: nextPayout,
          transactions: txns,
        ));
      } else {
        state = AsyncValue.error('Failed to load earnings', StackTrace.current);
      }
    } catch (e, st) {
      // In a real app we'd log the stacktrace `st`.
      state = AsyncValue.error(e, st);
    }
  }
}

final earningsProvider = StateNotifierProvider<EarningsNotifier, AsyncValue<EarningsState>>((ref) {
  return EarningsNotifier();
});
