import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pathao_agent_flutter/core/network/dio_client.dart';
import 'package:pathao_agent_flutter/core/constants/api_endpoints.dart';
import 'package:geolocator/geolocator.dart';

final locationPingServiceProvider = Provider<LocationPingService>((ref) {
  return LocationPingService();
});

class LocationPingService {
  Timer? _pingTimer;
  bool _isRunning = false;

  /// Starts the ping service. Fetches config first, then runs in background.
  Future<void> startService() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      final config = await _fetchPingsConfig();
      final intervalSec = config['interval_seconds'] as int? ?? 60;
      
      // Start ping loop
      _pingTimer = Timer.periodic(Duration(seconds: intervalSec), (_) {
        _submitPing();
      });
      // Fire one immediately
      _submitPing();
    } catch (e) {
      // If config fails, fallback to 60s
      _pingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _submitPing();
      });
    }
  }

  void stopService() {
    _isRunning = false;
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<Map<String, dynamic>> _fetchPingsConfig() async {
    final dioClient = DioClient();
    final response = await dioClient.dio.get(ApiEndpoints.pingsConfig);
    if (response.statusCode == 200 && response.data != null) {
      if (response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
    }
    throw Exception('Failed to load ping config');
  }

  Future<void> _submitPing() async {
    if (!_isRunning) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final dioClient = DioClient();
      await dioClient.dio.post(
        ApiEndpoints.pings,
        data: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Silently fail telemetry in background if GPS or network drops
    }
  }
}
