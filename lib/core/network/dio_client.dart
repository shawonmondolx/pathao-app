import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

class DioClient {
  late final Dio dio;
  final SecureStorage _storage = SecureStorage();

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.talariaBase,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        // Do NOT hard-lock Content-Type here — let each request override it.
        // FormData requires 'multipart/form-data'; JSON requires 'application/json'.
        headers: {
          'App-Version': '7.1.2',
          'X-Language': 'en',
          'X-Country-Id': '1',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Bearer token on every request EXCEPT the login/token endpoint
          if (!options.path.contains(ApiEndpoints.token)) {
            final token = await _storage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          // Default Content-Type for requests that don't already set it
          // Dio sets 'multipart/form-data' automatically for FormData — don't override.
          if (options.data is! FormData &&
              !options.headers.containsKey('Content-Type')) {
            options.headers['Content-Type'] = 'application/json';
          }

          // Debug: print full request
          print('[DIO] ${options.method} ${options.uri}');
          print('[DIO] Headers: ${options.headers}');
          if (options.data is! FormData) {
            print('[DIO] Data: ${options.data}');
          } else {
            print('[DIO] Data: FormData');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('[DIO] RESPONSE ${response.statusCode}: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          print('[DIO] ERROR ${error.response?.statusCode}: ${error.response?.data}');

          // Automatic OAuth2 token refresh on 401
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains(ApiEndpoints.token)) {
            final refreshToken = await _storage.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshResponse = await Dio().post(
                  '${ApiEndpoints.talariaBase}${ApiEndpoints.token}',
                  data: {
                    'grant_type': 'refresh_token',
                    'refresh_token': refreshToken,
                    'client_id': '1',
                    'client_secret': '3OTpihlWPazZNDw9CpKwzXombbGa9wmO1Ms4O9Ne',
                  },
                  options: Options(headers: {
                    'App-Version': '7.1.2',
                    'X-Language': 'en',
                    'X-Country-Id': '1',
                    'Content-Type': 'application/json',
                  }),
                );

                if (refreshResponse.statusCode == 200) {
                  final data = refreshResponse.data['data'];
                  final newToken = data['token'] as String;
                  final newRefreshToken = data['refresh_token'] as String?;

                  await _storage.saveTokens(
                    token: newToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry original request with fresh token
                  final retryOptions = Options(
                    method: error.requestOptions.method,
                    headers: {
                      ...error.requestOptions.headers,
                      'Authorization': 'Bearer $newToken',
                    },
                  );

                  final response = await dio.request(
                    error.requestOptions.path,
                    options: retryOptions,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                  );
                  return handler.resolve(response);
                }
              } catch (e) {
                print('[DIO] Token refresh failed: $e');
                // Clear tokens — user must log in again
                await _storage.clearTokens();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
