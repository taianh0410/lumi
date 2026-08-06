import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/classes/data/class_models.dart';
import '../../features/classes/screens/class_detail_screen.dart';
import '../../features/dashboard/screens/main_layout.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/home/screens/welcome_screen.dart';

final _publicRoutes = {'/welcome', '/login', '/register'};

GoRouter buildAppRouter(ProviderContainer container) {
  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: _AuthListenable(container),
    redirect: (context, state) {
      final authState = container.read(authProvider);
      final location = state.matchedLocation;

      if (authState.isLoading) return null;

      final isPublic = _publicRoutes.contains(location);

      if (!authState.isAuthenticated && !isPublic) return '/welcome';
      if (authState.isAuthenticated && isPublic) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/welcome',   builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login',     builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',  builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (_, state) => MainLayout(currentPath: state.matchedLocation),
      ),
      GoRoute(
        path: '/friends',
        builder: (_, state) => MainLayout(currentPath: state.matchedLocation),
      ),
      GoRoute(
        path: '/groups',
        builder: (_, state) => MainLayout(currentPath: state.matchedLocation),
      ),
      GoRoute(
        path: '/classes',
        builder: (_, state) => MainLayout(currentPath: state.matchedLocation),
      ),
      GoRoute(
        path: '/class-detail',
        builder: (_, state) {
          final classModel = state.extra as ClassModel;
          return ClassDetailScreen(classModel: classModel);
        },
      ),
      GoRoute(
        path: '/chat/:groupId',
        builder: (_, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          final groupName = state.extra is String ? state.extra as String : 'Phòng chat';
          return ChatScreen(groupId: groupId, groupName: groupName);
        },
      ),
    ],
  );
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(ProviderContainer container) {
    container.listen(authProvider, (_, __) => notifyListeners());
  }
}
