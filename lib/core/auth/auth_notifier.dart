import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:football_predictions/features/auth/data/models/user_model.dart';

class AuthNotifier extends ChangeNotifier {
  final firebase.FirebaseAuth _auth;
  AuthRepository? _authRepository;
  //final UserNotifier _userNotifier;
  StreamSubscription<firebase.User?>? _authStateSubscription;
 
  firebase.User? _user;
  firebase.User? get user => _user;
  UserModel? _backendUser;
  UserModel? get backendUser => _backendUser;
  String? _redirectPath;
  String? get redirectPath => _redirectPath;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
 
  AuthNotifier(this._auth/*, this._userNotifier*/) {
    // Inicia a escuta do estado de autenticação do Firebase
    _listenToAuthStateChanges();
  }

  void updateAuthRepository(AuthRepository authRepository) {
    _authRepository = authRepository;
  }

  /// Salva a rota que o usuário tentou acessar para redirecionar após o login/inicialização.
  void setRedirectPath(String? path) {
    _redirectPath = path;
  }

  void _listenToAuthStateChanges() {
    _authStateSubscription = _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null && _authRepository != null) {
        try {
          // Carrega o usuário do backend antes de confirmar a inicialização
          _backendUser = await _authRepository!.getUser();
        } catch (e) {
          debugPrint('Erro ao carregar usuário do backend no AuthNotifier: $e');
        }
      } else {
        _backendUser = null;
      }

      _user = firebaseUser;
      _isInitialized = true;
      // Notifica o GoRouter sobre a mudança no estado de autenticação.
      notifyListeners();

      if (_user == null) {
        // Se o usuário do Firebase for nulo (logout), limpa os dados no UserNotifier.
        //_userNotifier.clearUser();
      } else {
        // Se há um usuário no Firebase, comanda o UserNotifier para carregar os dados.
        //await _userNotifier.loadCurrentUser();
      }
    });
  }

  /// Força a atualização do usuário interno e notifica os listeners.
  /// Útil após ações como a verificação de e-mail, que não disparam o `authStateChanges`.
  void updateUser() {
    _user = _auth.currentUser;
    notifyListeners();
  }

  /// Atualiza os dados do usuário do backend (ex: após edição de perfil).
  Future<void> refreshUser([UserModel? updatedUser]) async {
    if (updatedUser != null) {
      _backendUser = updatedUser;
      notifyListeners();
      return;
    }

    if (_authRepository != null && _user != null) {
      try {
        _backendUser = await _authRepository!.getUser(forceRefresh: true);
        notifyListeners();
      } catch (e) {
        debugPrint('Erro ao atualizar usuário do backend: $e');
      }
    }
  }

  /// Pausa o listener de autenticação. Útil durante o processo de registro.
  void pauseListener() {
    _authStateSubscription?.pause();
  }

  /// Retoma o listener de autenticação.
  void resumeListener() {
    _authStateSubscription?.resume();
  }

  Future<void> logout() async {
    if (_authRepository != null) {
      await _authRepository!.logout();
    } else {
      await _auth.signOut();
    }
    _user = null;
    _backendUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}