import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(isAuthenticated: false, isLoading: false);

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorage _storage = SecureStorage();

  AuthNotifier() : super(AuthState.initial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _storage.getToken();
    if (token != null) {
      state = AuthState(isAuthenticated: true, isLoading: false);
    }
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true);
    final dioClient = DioClient();

    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.token,
        data: {
          'username': phone,
          'password': password,
          'client_id': '1',
          'client_secret': '3OTpihlWPazZNDw9CpKwzXombbGa9wmO1Ms4O9Ne',
          'grant_type': 'password',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];
        final refreshToken = data['refresh_token'];
        await _storage.saveTokens(token: token, refreshToken: refreshToken);
        state = AuthState(isAuthenticated: true, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed: ${response.statusMessage}',
        );
        return false;
      }
    } catch (e) {
      String msg = 'Network error or invalid credentials';
      if (e is DioException) {
        final data = e.response?.data;
        if (data != null && data is Map) {
          msg = data['message'] ?? data['error_description'] ?? data['error'] ?? msg;
        } else if (e.message != null) {
          msg = 'Connection error: ${e.message}';
        }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
