// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Serviço de autenticação que se comunica com Firebase Functions

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session_manager.dart';

class AuthService {
  static const String _functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue: 'http://localhost:5001/mesclainvest-d3745/us-central1',
  );

  static String? _uid;
  static String? _token;

  static String? get currentUid => _uid ?? SessionManager.uid;
  static bool get isAuthenticated {
    final token = _token ?? SessionManager.token;
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
    required String senha,
    required String confirmarSenha,
  }) async {
    final response = await _postJson('authentication-registerUser', {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'senha': senha,
      'confirmarSenha': confirmarSenha,
    });

    if (response['success'] == true) {

      _storeSession(response);

    }

    return response;

  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final response = await _postJson('authentication-loginUser', {
      'email': email,
      'senha': senha,
    });

    if (response['success'] == true) {
      _storeSession(response);
    }

    return response;
  }

  static Future<Map<String, dynamic>> recuperarSenha({
    required String email,
  }) async {
    return _postJson('authentication-sendPasswordReset', {'email': email});
  }

  static Map<String, String> headersAutenticados() {
    final token = _token ?? SessionManager.token;

    if (token == null || token.isEmpty) {
      throw const AuthServiceException('Usuario nao autenticado.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static void clearSession() {
    _uid = null;
    _token = null;
    SessionManager.limparSessao();
  }

  static Future<Map<String, dynamic>> _postJson(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_functionsBaseUrl/$functionName'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return {
          'success': false,
          'message': 'Resposta inválida das Functions.',
        };
      }

      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Erro de conexão. Verifique se o emulador das Functions está rodando.',
      };
    }
  }

  static void _storeSession(Map<String, dynamic> response) {
    final uid = response['uid']?.toString().trim();
    final token = response['token']?.toString().trim();
    final name = response['name']?.toString().trim();
    final telefone = response['telefone']?.toString().trim();

    if (uid == null || uid.isEmpty || token == null || token.isEmpty || name == null || name.isEmpty) {
      return;
    }

    _uid = uid;
    _token = token;
    SessionManager.salvarSessao(uid: uid, token: token, name: name , telefone:  telefone ?? '');
  }

  static String? getTelefoneUsuario() {
    final telefone = SessionManager.telefone;

    if (telefone == null || telefone.trim().isEmpty) {
      return null;
    }

    return telefone;
  }
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
