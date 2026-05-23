import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sweatera/features/auth/presentation/pages/login_page.dart';
import 'package:sweatera/features/auth/presentation/pages/signup_page.dart';
import 'package:sweatera/features/auth/presentation/pages/otp_page.dart';
import 'package:sweatera/features/auth/presentation/pages/onboarding_page.dart';
import 'package:sweatera/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:sweatera/features/auth/domain/providers/auth_provider.dart';

part 'app_router.g.dart';

/// Route name constants
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/';
  static const String leaderboard = '/leaderboard';
  static const String aiAssistant = '/ai-assistant';
  static const String profile = '/profile';
  static const String workouts = '/workouts';
  static const String running = '/running';
}

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.onboarding;

      // If loading auth state, don't redirect
      if (authState.isLoading) return null;

      // If not authenticated and not on auth route → go to login
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;

      // If authenticated and on auth route → go to dashboard
      if (isAuthenticated && isAuthRoute) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      // ── Auth Routes ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _fadeTransition(
          state: state,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => _slideTransition(
          state: state,
          child: const SignupPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        pageBuilder: (context, state) => _slideTransition(
          state: state,
          child: OtpPage(
            phoneNumber: state.extra as String? ?? '',
            verificationId: '',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _slideTransition(
          state: state,
          child: const OnboardingPage(),
        ),
      ),

      // ── Main App Shell ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => _fadeTransition(
          state: state,
          child: const DashboardPage(),
        ),
      ),
    ],
  );
}

/// Smooth fade page transition
CustomTransitionPage<void> _fadeTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

/// Slide from right page transition
CustomTransitionPage<void> _slideTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}
