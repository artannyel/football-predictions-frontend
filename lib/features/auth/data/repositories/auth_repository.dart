import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:football_predictions/core/errors/auth_exception.dart';
import 'package:football_predictions/dio_client.dart';
import 'package:image_picker/image_picker.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final DioClient _dioClient;

  AuthRepository({FirebaseAuth? firebaseAuth, required DioClient dioClient})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dioClient = dioClient;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> login({required String email, required String password}) async {
    try {
      UserCredential user = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Usuário logado: ${user.user?.email}');
      final token = await user.user?.getIdToken();
      debugPrint('Token: $token');

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      throw AuthException('Ocorreu um erro inesperado. Tente novamente.');
    }
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    XFile? photo,
  }) async {
    UserCredential? userCredential;
    try {
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);

      final formData = FormData.fromMap({
        'name': name,
        'email': email,
      });

      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          formData.files.add(MapEntry(
            'photo_url',
            MultipartFile.fromBytes(bytes, filename: photo.name),
          ));
        } else {
          formData.files.add(MapEntry(
            'photo_url',
            await MultipartFile.fromFile(photo.path, filename: photo.name),
          ));
        }
      }

      // O token será adicionado automaticamente pelo interceptor do DioClient
      await _dioClient.dio.post(
        'users',
        data: formData,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Caso falhe no updateDisplayName, por exemplo
      if (userCredential != null) {
        await userCredential.user?.delete();
      }
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      // Se falhar na chamada ao backend (Dio), deletamos o usuário do Firebase
      if (userCredential != null) {
        await userCredential.user?.delete();
      }
      debugPrint('Erro ao criar conta: $e');
      throw AuthException('Ocorreu um erro inesperado ao criar a conta');
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<String> getUserId() async {
    try {
      final response = await _dioClient.dio.get('user');
      return response.data['user']['id'];
    } catch (e) {
      throw Exception('Falha ao carregar ID do usuário: $e');
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Usuário ou senha inválidos';
      case 'invalid-email':
        return 'E-mail inválido';
      case 'user-disabled':
        return 'Este usuário foi desabilitado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'network-request-failed':
        return 'Verifique sua conexão com a internet';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso';
      case 'weak-password':
        return 'A senha é muito fraca';
      default:
        return 'Erro ao realizar login. Código: $code';
    }
  }
}