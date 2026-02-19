import 'package:flutter/material.dart';
import 'package:football_predictions/core/auth/auth_notifier.dart';
import 'package:football_predictions/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:football_predictions/features/auth/presentation/pages/login_page.dart';
import 'package:football_predictions/features/auth/presentation/pages/splash_page.dart';
import 'package:football_predictions/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:football_predictions/features/auth/presentation/pages/profile_page.dart';
import 'package:football_predictions/features/competitions/presentation/pages/competitions_page.dart';
import 'package:football_predictions/features/home/presentation/pages/home_page.dart';
import 'package:football_predictions/features/home/presentation/pages/league_details_page.dart';
import 'package:football_predictions/features/matches/presentation/pages/matches_page.dart';
import 'package:football_predictions/features/ranking/presentation/pages/ranking_page.dart';
import 'package:football_predictions/features/predictions/presentation/pages/user_predictions_page.dart';
import 'package:football_predictions/features/predictions/presentation/pages/prediction_page.dart';
import 'package:go_router/go_router.dart';

GoRouter appRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isInitialized = authNotifier.isInitialized;
      final isLoggedIn =
          authNotifier.user != null && authNotifier.backendUser != null;

      final isSplash = state.matchedLocation == '/';
      final isLogin = state.matchedLocation == '/entrar';

      // 0. Limpeza: Se já estamos na rota de destino salva, limpamos o redirectPath.
      // Isso garante que o path só seja descartado quando o usuário realmente chegar lá.
      if (isInitialized && authNotifier.redirectPath != null) {
        if (state.uri.toString() == authNotifier.redirectPath) {
          authNotifier.setRedirectPath(null);
        }
      }

      // 0.5. Redirecionamento forçado (ex: Clicou em notificação enquanto logado)
      if (isInitialized && isLoggedIn && authNotifier.redirectPath != null) {
        String redirectPath = authNotifier.redirectPath!;
        authNotifier.setRedirectPath(null);
        return redirectPath;
      }

      // 1. Se ainda não inicializou o Auth
      if (!isInitialized) {
        // Se não estamos na raiz (Splash), salvamos onde o usuário queria ir e vamos para a Splash
        if (!isSplash) {
          authNotifier.setRedirectPath(state.uri.toString());
          return '/';
        }
        return null; // Já estamos na Splash, aguarda.
      }

      // 2. Inicializou e está na Splash (Raiz)
      if (isSplash && isInitialized) {
        final originalPath = authNotifier.redirectPath;

        // Se tinha um destino salvo (e não era a própria raiz), vai pra lá
        if (originalPath != null && originalPath != '/') {
          return originalPath;
        }
        // Se não tinha destino, decide com base no login
        return isLoggedIn ? '/ligas' : '/entrar';
      }

      // 3. Se não está logado e tenta acessar página protegida (nem Splash nem Login)
      if (!isLoggedIn && !isLogin && !isSplash) {
        authNotifier.setRedirectPath(state.uri.toString());
        return '/entrar';
      }

      // 4. Se está logado e tenta acessar Login, vai para Home
      if (isLoggedIn && isLogin) {
        final originalPath = authNotifier.redirectPath;
        if (originalPath != null && originalPath != '/entrar') {
          return originalPath;
        }
        return '/ligas';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'Splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/entrar',
        name: 'Login',
        builder: (context, state) => const LoginPage(),
      ),
      // Shell Route que envolve as abas principais
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Aba 1: Ligas (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ligas',
                name: 'Home',
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: ':id', // Caminho final: /ligas/:id
                    name: 'LeagueDetails',
                    builder: (context, state) {
                      final leagueId = state.pathParameters['id']!;
                      return LeagueDetailsPage(leagueId: leagueId);
                    },
                    routes: [
                      GoRoute(
                        path: 'usuario/:userId',
                        name: 'Predictions',
                        builder: (context, state) => UserPredictionsPage(
                          userId: state.pathParameters['userId']!,
                          leagueId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'palpite/:matchId',
                        name: 'Prediction',
                        builder: (context, state) => PredictionPage(
                          leagueId: state.pathParameters['id']!,
                          matchId: int.parse(state.pathParameters['matchId']!),
                          predictionId: state.uri.queryParameters['predictionId'] != null
                              ? int.parse(state.uri.queryParameters['predictionId']!)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Aba 2: Ranking
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ranking',
                name: 'Ranking',
                builder: (context, state) => const RankingPage(),
              ),
            ],
          ),
          // Aba 3: Competições
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/competicoes',
                name: 'Competitions',
                builder: (context, state) => const CompetitionsPage(),
                routes: [
                  GoRoute(
                    path: 'partidas/:id', // Caminho final: /competicoes/partidas/:id
                    name: 'Matches',
                    builder: (context, state) => MatchesPage(
                        competitionId: int.parse(state.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
          // Aba 4: Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                name: 'Profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'editar',
                    name: 'EditProfile',
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'usuario/:userId',
                    name: 'UserProfile',
                    builder: (context, state) =>
                        ProfilePage(userId: state.pathParameters['userId']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
