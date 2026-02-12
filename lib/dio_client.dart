import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DioClient {
  final Dio _dio;

  DioClient() : _dio = Dio() {
    _dio.options = BaseOptions(
      baseUrl: const String.fromEnvironment('BASE_URL',
          defaultValue: 'http://192.168.0.11/'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Pega o usuário atual do Firebase
          User? user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            // Pega o token de ID do usuário
            final token = await user.getIdToken();
            // Adiciona o token ao header de autorização
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Continua com a requisição
          return handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
