import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

const _tokenKey = 'auth_token';
const _userIdKey = 'auth_user_id';
const _usernameKey = 'auth_username';
const _roleKey = 'auth_role';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.token,
  });

  final String id;
  final String username;
  final String role;
  final String token;

  bool get isTeacher => role == 'teacher';
}

class AuthService {
  AuthService() : _dio = ApiClient.instance.dio;

  final Dio _dio;

  // ── Token persistence ─────────────────────────────────────────────────────

  Future<void> saveSession(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_roleKey, user.role);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<AuthUser?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final id = prefs.getString(_userIdKey);
    final username = prefs.getString(_usernameKey);
    final role = prefs.getString(_roleKey);
    if (token == null || id == null || username == null || role == null) {
      return null;
    }
    return AuthUser(id: id, username: username, role: role, token: token);
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/auth/login',
        data: {'username': username.trim(), 'password': password},
      );
      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw AuthException(_parseErrorMessage(e, fallback: 'Đăng nhập thất bại.'));
    }
  }

  Future<AuthUser> register({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      // Register then immediately login to get a token
      await _dio.post<dynamic>(
        '/api/auth/register',
        data: {'username': username.trim(), 'password': password, 'role': role},
      );
      return login(username: username, password: password);
    } on DioException catch (e) {
      throw AuthException(_parseErrorMessage(e, fallback: 'Đăng ký thất bại.'));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  AuthUser _parseAuthResponse(dynamic data) {
    if (data is! Map) throw AuthException('Phản hồi server không hợp lệ.');
    final token = data['token']?.toString();
    final user = data['user'];
    if (token == null || user is! Map) {
      throw AuthException('Thiếu token hoặc thông tin user trong phản hồi.');
    }
    return AuthUser(
      id: user['id']?.toString() ?? '',
      username: user['username']?.toString() ?? '',
      role: user['role']?.toString() ?? 'student',
      token: token,
    );
  }

  String _parseErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return fallback;
  }
}
