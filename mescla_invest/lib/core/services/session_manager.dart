// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Gerenciador de sessao do usuario autenticado

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazena os dados da sessao do usuario logado e o refresh token persistente.
class SessionManager {
  SessionManager._();

  static const _storage = FlutterSecureStorage();
  static const _refreshTokenKey = 'session_refresh_token';

  static String? _uid;
  static String? _token;
  static String? _refreshToken;
  static String? _name;
  static String? _telefone;
  static bool _mfaAtivo = false;

  static Future<void> salvarSessao({
    required String uid,
    required String token,
    required String name,
    required String telefone,
    String? refreshToken,
    bool mfaAtivo = false,
    bool persistir = false,
  }) async {
    _uid = uid;
    _token = token;
    _refreshToken = refreshToken;
    _name = name;
    _telefone = telefone;
    _mfaAtivo = mfaAtivo;

    await _atualizarSessaoPersistente(
      refreshToken: refreshToken,
      persistir: persistir,
    );
  }

  static String? get uid => _uid;

  static String? get token => _token;

  static String? get refreshToken => _refreshToken;

  static String? get name => _name;

  static String? get telefone => _telefone;

  static bool get mfaAtivo => _mfaAtivo;

  static void setMfaAtivo(bool value) {
    _mfaAtivo = value;
  }

  static bool get estaAutenticado => _uid != null && _uid!.isNotEmpty;

  static void limparSessao() {
    _uid = null;
    _token = null;
    _refreshToken = null;
    _name = null;
    _telefone = null;
    _mfaAtivo = false;
  }

  static Future<String?> carregarRefreshTokenPersistente() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> limparSessaoPersistente() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {}
  }

  static Future<void> _atualizarSessaoPersistente({
    required String? refreshToken,
    required bool persistir,
  }) async {
    if (!persistir || refreshToken == null || refreshToken.isEmpty) {
      await limparSessaoPersistente();
      return;
    }

    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      await limparSessaoPersistente();
    }
  }
}
