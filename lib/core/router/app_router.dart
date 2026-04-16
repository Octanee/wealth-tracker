import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/assets/domain/entities/asset.dart';
import '../../features/assets/presentation/pages/assets_page.dart';
import '../../features/assets/presentation/pages/asset_detail_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../shell/main_shell.dart';

class AppRouter {
  static GoRouter create(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: _AuthNotifier(authCubit),
      redirect: (context, state) {
        final authState = authCubit.state;
        final isAuth = authState is AuthAuthenticated;
        final isLoading = authState is AuthLoading || authState is AuthInitial;
        final isLoginRoute = state.matchedLocation == '/login';

        if (isLoading) return null;
        if (!isAuth && !isLoginRoute) return '/login';
        if (isAuth && isLoginRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        ShellRoute(
          builder: (_, _, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardPage(),
            ),
            GoRoute(
              path: '/assets',
              builder: (_, _) => const AssetsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final asset = state.extra as Asset;
                    return AssetDetailPage(asset: asset);
                  },
                ),
              ],
            ),
            GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          ],
        ),
      ],
    );
  }
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
