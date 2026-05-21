// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Serviço de autenticação que se comunica com Firebase Functions

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../session/user_session.dart';

class AuthService {
  static const String _functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue: 'http://localhost:5001/mesclainvest-d3745/us-central1',
  );

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

      UserSession.nome = nome;

      UserSession.email = email;

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

      UserSession.nome = response['nome'];

      UserSession.email = response['email'];

    }
    return response;
  }

  static Future<Map<String, dynamic>> recuperarSenha({
    required String email,
  }) async {
    return _postJson('authentication-sendPasswordReset', {'email': email});
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
}
