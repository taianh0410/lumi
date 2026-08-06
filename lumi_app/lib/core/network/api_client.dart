import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String _tokenKey = 'auth_token';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.backendBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  UnauthorizedHandler? _onUnauthorized;
  bool _isConfigured = false;

  Dio get dio {
    _ensureConfigured();
    return _dio;
  }

  void setUnauthorizedHandler(UnauthorizedHandler? handler) {
    _onUnauthorized = handler;
  }

  void _ensureConfigured() {
    if (_isConfigured) {
      return;
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(_tokenKey);

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else if (AppConstants.mockAuthEnabled) {
            options.headers.addAll(AppConstants.mockAuthHeaders);
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_tokenKey);
            await prefs.remove('auth_user_id');
            await prefs.remove('auth_username');
            await prefs.remove('auth_role');

            final handlerCallback = _onUnauthorized;
            if (handlerCallback != null) {
              await handlerCallback();
            }
          }

          handler.next(error);
        },
      ),
    );

    _isConfigured = true;
  }
}