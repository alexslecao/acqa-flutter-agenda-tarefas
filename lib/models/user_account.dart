import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Conta local demonstrativa.
///
/// ATENÇÃO: isto NÃO é autenticação segura de produção. A conta fica gravada
/// apenas no aparelho. A senha não é salva em texto puro (guarda-se um hash
/// SHA-256 com "sal"), mas não há servidor, criptografia do armazenamento nem
/// recuperação de senha.
class UserAccount {
  const UserAccount({
    required this.name,
    required this.email,
    required this.salt,
    required this.passwordHash,
  });

  /// Cria uma conta nova, gerando o sal e o hash da senha.
  factory UserAccount.create({
    required String name,
    required String email,
    required String password,
  }) {
    final salt = _newSalt();
    return UserAccount(
      name: name.trim(),
      email: normalizeEmail(email),
      salt: salt,
      passwordHash: hashPassword(password, salt),
    );
  }

  final String name;

  /// E-mail normalizado (sem espaços nas pontas e em minúsculas).
  final String email;

  final String salt;
  final String passwordHash;

  /// Primeiro nome, usado na saudação da tela principal.
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return email.split('@').first;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  bool matchesPassword(String password) =>
      hashPassword(password, salt) == passwordHash;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'salt': salt,
      'passwordHash': passwordHash,
    };
  }

  /// Lê uma conta gravada; devolve `null` se o registro estiver incompleto.
  static UserAccount? tryFromJson(Map<String, dynamic> json) {
    final email = json['email'];
    final salt = json['salt'];
    final passwordHash = json['passwordHash'];
    if (email is! String || salt is! String || passwordHash is! String) {
      return null;
    }
    final name = json['name'];
    return UserAccount(
      name: name is String ? name : '',
      email: normalizeEmail(email),
      salt: salt,
      passwordHash: passwordHash,
    );
  }

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  static String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
