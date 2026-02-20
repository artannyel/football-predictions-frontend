import 'package:flutter/material.dart';
import 'package:football_predictions/core/providers/theme_provider.dart';
import 'package:football_predictions/features/admin/presentation/pages/admin_badges_page.dart';
import 'package:football_predictions/features/admin/presentation/pages/admin_matches_page.dart';
import 'package:football_predictions/features/admin/presentation/pages/admin_tools_page.dart';
import 'package:football_predictions/features/admin/presentation/widgets/admin_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Aqui você definiria um router específico para o Admin
    _router = GoRouter(
      initialLocation: '/',
      //refreshListenable: context.read<AuthNotifier>(),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AdminScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const AdminMatchesPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/badges',
                  builder: (context, state) => const AdminBadgesPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/tools',
                  builder: (context, state) => const AdminToolsPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: 'Admin Palpites',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C), // Vermelho para diferenciar
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return Banner(
          message: 'ADMIN',
          location: BannerLocation.topEnd,
          child: child!,
        );
      },
    );
  }
}