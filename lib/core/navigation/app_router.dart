import 'package:flutter/material.dart';
import 'package:football_predictions/core/auth/auth_notifier.dart';
import 'package:football_predictions/features/auth/presentation/pages/login_page.dart';
import 'package:football_predictions/features/auth/presentation/pages/splash_page.dart';
import 'package:football_predictions/features/home/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';

GoRouter appRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isInitialized = authNotifier.isInitialized;
      final isLoggedIn = authNotifier.user != null;
      
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToLogin = state.matchedLocation == '/entrar';

      // 1. Se ainda não inicializou o Auth, vai para a Splash
      if (!isInitialized) {
        return '/splash';
      }

      // 2. Se já inicializou e ainda está na Splash, redireciona
      if (isGoingToSplash && isInitialized) {
        return isLoggedIn ? '/' : '/entrar';
      }

      // 3. Se não está logado e tenta acessar página protegida, vai para Login
      if (!isLoggedIn && !isGoingToLogin) {
        return '/entrar';
      }

      // 4. Se está logado e tenta acessar Login, vai para Home
      if (isLoggedIn && isGoingToLogin) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'Splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/',
        name: 'Home',
        builder: (context, state) =>  const HomePage(),
      ),
      GoRoute(
        path: '/entrar',
        name: 'Entrar',
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
}
