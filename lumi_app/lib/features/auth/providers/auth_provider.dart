import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Auth state ────────────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service)
      : super(const AuthState(status: AuthStatus.loading)) {
    _tryRestoreSession();
  }

  final AuthService _service;

  /// Called on app start — restores persisted session if token exists.
  Future<void> _tryRestoreSession() async {
    final user = await _service.getStoredUser();
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.login(username: username, password: password);
      await _service.saveSession(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Lỗi không xác định. Vui lòng thử lại.',
      );
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.register(
        username: username,
        password: password,
        role: role,
      );
      await _service.saveSession(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Lỗi không xác định. Vui lòng thử lại.',
      );
    }
  }

  Future<void> logout() async {
    await _service.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
