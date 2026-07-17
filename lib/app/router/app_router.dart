import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../features/auth/data/auth_state_controller.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/editor/presentation/editor_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/trash/presentation/trash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authState,
    redirect: (context, state) {
      if (!AppConfig.hasSupabaseConfig) {
        return null;
      }

      final isSignedIn = Supabase.instance.client.auth.currentSession != null;
      final location = state.matchedLocation;
      final isPasswordResetRoute = location == '/reset-password';
      final isPublicRoute =
          location == '/' || location == '/auth' || isPasswordResetRoute;

      if (authState.isPasswordRecovery && !isPasswordResetRoute) {
        return '/reset-password';
      }

      if (!isSignedIn && !isPublicRoute) {
        return '/auth';
      }

      if (isSignedIn && !authState.isPasswordRecovery && isPublicRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) =>
            AuthScreen(notice: state.uri.queryParameters['notice']),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/editor',
        name: 'editor',
        builder: (context, state) =>
            EditorScreen(noteId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/trash',
        name: 'trash',
        builder: (context, state) => const TrashScreen(),
      ),
    ],
  );
});
