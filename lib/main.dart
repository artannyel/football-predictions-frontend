import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/dio_client.dart';
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:football_predictions/features/auth/presentation/pages/login_page.dart';
import 'package:football_predictions/features/competitions/data/repositories/competitions_repository.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:football_predictions/features/home/presentation/pages/home_page.dart';
import 'package:football_predictions/features/matches/data/repositories/matches_repository.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:football_predictions/firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase usando as opções geradas para a plataforma atual
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => DioClient()),
        ProxyProvider<DioClient, AuthRepository>(
          update: (_, dioClient, __) => AuthRepository(dioClient: dioClient),
        ),
        ProxyProvider<DioClient, MatchesRepository>(
          update: (_, dioClient, __) => MatchesRepository(dioClient: dioClient),
        ),
        ProxyProvider<DioClient, CompetitionsRepository>(
          update: (_, dioClient, __) => CompetitionsRepository(dioClient: dioClient),
        ),
        ProxyProvider<DioClient, LeaguesRepository>(
          update: (_, dioClient, __) => LeaguesRepository(dioClient: dioClient),
        ),
        ProxyProvider<DioClient, PredictionsRepository>(
          update: (_, dioClient, __) =>
              PredictionsRepository(dioClient: dioClient),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Predictions',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20), brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: StreamBuilder<User?>(
        stream: context.read<AuthRepository>().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: LoadingWidget());
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
