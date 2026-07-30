import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class DioClient {
  DioClient._();

  static final Dio instance = _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.backendBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(_AuthInterceptor());
    return dio;
  }
}

/// Automatically attaches Bearer token from SharedPreferences.
/// On 401, clears the stored session (router redirect handles navigation).
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      // Fallback to mock headers for local dev when no token is stored
      final mockEnabled =
          (AppConstants.mockAuthEnabled) && token == null;
      if (mockEnabled) {
        options.headers.addAll(AppConstants.mockAuthHeaders);
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Clear stored session — the router's redirect will send user to /login
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_username');
      await prefs.remove('auth_role');
    }
    handler.next(err);
  }
}
