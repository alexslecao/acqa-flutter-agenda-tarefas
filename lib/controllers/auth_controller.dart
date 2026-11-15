import 'package:flutter/foundation.dart';

import '../models/user_account.dart';
import '../services/local_storage_service.dart';

/// Estado de autenticação LOCAL e DEMONSTRATIVA.
///
/// Serve para cumprir o fluxo de login/cadastro do trabalho acadêmico. Não é
/// um mecanismo de segurança de produção: as contas ficam apenas no aparelho.
class AuthController extends ChangeNotifier {
  AuthController(this._storage);

  final LocalStorageService _storage;

  static const String _storageError =
      'Não foi possível acessar os dados locais. Tente novamente.';

  UserAccount? _currentUser;
  bool _isRestoring = true;

  /// Usuário conectado, ou `null` quando ninguém fez login.
  UserAccount? get currentUser => _currentUser;

  /// `true` enquanto o app verifica se havia uma sessão salva.
  bool get isRestoring => _isRestoring;

  /// Recupera a sessão gravada (se o usuário não saiu da conta).
  Future<void> restoreSession() async {
    UserAccount? restored;
    try {
      final email = await _storage.loadSessionEmail();
      if (email != null) {
        final users = await _storage.loadUsers();
        restored = _findByEmail(users, email);
      }
    } catch (_) {
      restored = null;
    }
    _currentUser = restored;
    _isRestoring = false;
    notifyListeners();
  }

  /// Faz login. Devolve `null` em caso de sucesso ou a mensagem de erro.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final users = await _storage.loadUsers();
      final user = _findByEmail(users, UserAccount.normalizeEmail(email));
      if (user == null || !user.matchesPassword(password)) {
        return 'E-mail ou senha incorretos.';
      }
      await _storage.saveSessionEmail(user.email);
      _currentUser = user;
      notifyListeners();
      return null;
    } catch (_) {
      return _storageError;
    }
  }

  /// Cadastra e já conecta. Devolve `null` em caso de sucesso ou a mensagem
  /// de erro.
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final users = await _storage.loadUsers();
      final normalized = UserAccount.normalizeEmail(email);
      if (_findByEmail(users, normalized) != null) {
        return 'Já existe uma conta com este e-mail. Faça login.';
      }
      final user = UserAccount.create(
        name: name,
        email: normalized,
        password: password,
      );
      await _storage.saveUsers(<UserAccount>[...users, user]);
      await _storage.saveSessionEmail(user.email);
      _currentUser = user;
      notifyListeners();
      return null;
    } catch (_) {
      return _storageError;
    }
  }

  /// Sai da conta. As tarefas continuam gravadas no aparelho.
  Future<void> signOut() async {
    try {
      await _storage.clearSession();
    } catch (_) {
      // Mesmo que a gravação falhe, o usuário sai nesta execução do app.
    }
    _currentUser = null;
    notifyListeners();
  }

  UserAccount? _findByEmail(List<UserAccount> users, String email) {
    for (final user in users) {
      if (user.email == email) return user;
    }
    return null;
  }
}
