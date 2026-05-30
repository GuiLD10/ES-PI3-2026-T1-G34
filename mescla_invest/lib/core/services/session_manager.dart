// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Gerenciador de sessão do usuário autenticado

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazena os dados da sessão do usuário logado (uid e token)
/// retornados pela Firebase Function de login.
class SessionManager {
  SessionManager._();

  static const _storage = FlutterSecureStorage();
  static const _uidKey = 'session_uid';
  static const _tokenKey = 'session_token';
  static const _refreshTokenKey = 'session_refresh_token';
  static const _nameKey = 'session_name';
  static const _telefoneKey = 'session_telefone';

  static String? _uid;
  static String? _token;
  static String? _refreshToken;
  static String? _name;
  static String? _telefone;

  static Future<void> salvarSessao({
    required String uid,
    required String token,
    required String name,
    required String telefone,
    String? refreshToken,
    bool persistir = false,
  }) async {
    _uid = uid;
    _token = token;
    _refreshToken = refreshToken;
    _name = name;
    _telefone = telefone;

    if (!persistir) {
      await limparSessaoPersistente();
      return;
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      await limparSessaoPersistente();
      return;
    }

    try {
      await _storage.write(key: _uidKey, value: uid);
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _storage.write(key: _nameKey, value: name);
      await _storage.write(key: _telefoneKey, value: telefone);
    } catch (_) {
      await limparSessaoPersistente();
    }
  }

  static String? get uid => _uid;

  static String? get token => _token;

  static String? get refreshToken => _refreshToken;

  static String? get name => _name;

  static String? get telefone => _telefone;

  static bool get estaAutenticado => _uid != null && _uid!.isNotEmpty;

  static void limparSessao() {
    _uid = null;
    _token = null;
    _refreshToken = null;
    _name = null;
    _telefone = null;
  }

  static Future<String?> carregarRefreshTokenPersistente() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> limparSessaoPersistente() async {
    try {
      await Future.wait([
        _storage.delete(key: _uidKey),
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _nameKey),
        _storage.delete(key: _telefoneKey),
      ]);
    } catch (_) {}
  }
}
