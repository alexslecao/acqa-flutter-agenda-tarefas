import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../models/user_account.dart';

/// Armazenamento simples de chave/valor em texto.
///
/// Existe como abstração para que a lógica possa ser testada sem depender do
/// plugin `shared_preferences`.
abstract class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Implementação real: grava no armazenamento local do aparelho.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> read(String key) async {
    final prefs = await _instance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await _instance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await _instance();
    await prefs.remove(key);
  }
}

/// Implementação em memória (os dados somem ao fechar). Usada nos testes.
class InMemoryStore implements KeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

/// Persistência local de usuários, sessão e tarefas (em JSON).
///
/// As tarefas são gravadas separadamente para cada e-mail, de modo que cada
/// conta local enxerga apenas as suas.
class LocalStorageService {
  LocalStorageService(this._store);

  final KeyValueStore _store;

  static const String _usersKey = 'lavanda.users';
  static const String _sessionKey = 'lavanda.session';

  static String _tasksKey(String email) => 'lavanda.tasks.$email';

  Future<List<UserAccount>> loadUsers() async {
    final raw = await _store.read(_usersKey);
    return _decodeList<UserAccount>(raw, UserAccount.tryFromJson);
  }

  Future<void> saveUsers(List<UserAccount> users) {
    final encoded = jsonEncode(users.map((user) => user.toJson()).toList());
    return _store.write(_usersKey, encoded);
  }

  /// E-mail da conta que ficou conectada, se houver.
  Future<String?> loadSessionEmail() => _store.read(_sessionKey);

  Future<void> saveSessionEmail(String email) =>
      _store.write(_sessionKey, email);

  Future<void> clearSession() => _store.delete(_sessionKey);

  Future<List<Task>> loadTasks(String email) async {
    final raw = await _store.read(_tasksKey(email));
    return _decodeList<Task>(raw, Task.tryFromJson);
  }

  Future<void> saveTasks(String email, List<Task> tasks) {
    final encoded = jsonEncode(tasks.map((task) => task.toJson()).toList());
    return _store.write(_tasksKey(email), encoded);
  }

  /// Decodifica uma lista JSON ignorando registros inválidos, em vez de
  /// lançar erro quando o conteúdo gravado está corrompido.
  List<T> _decodeList<T>(
    String? raw,
    T? Function(Map<String, dynamic> json) fromJson,
  ) {
    final result = <T>[];
    if (raw == null || raw.isEmpty) return result;

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return result;
    }
    if (decoded is! List) return result;

    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        final value = fromJson(item);
        if (value != null) result.add(value);
      }
    }
    return result;
  }
}
