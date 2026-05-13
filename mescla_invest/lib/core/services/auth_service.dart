// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Serviço de autenticação que se comunica com o servidor Node.js

import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // URL base do servidor Node.js
  // Em emulador Android: 10.0.2.2 aponta para o localhost da máquina host
  // Em dispositivo físico: use o IP da sua máquina na rede local (ex: 192.168.x.x)
  // Em web/Windows: use localhost

  // Para rodar no emulador Android
  //static const String _baseUrl = 'http://10.0.2.2:3000';

  // Para rodar no Windows ou Chrome
  static const String _baseUrl = 'http://localhost:3000';
  static String? _token;
  static String? _uid;

  static String? get token => _token;
  static String? get uid => _uid;
  static bool get estaAutenticado => _token != null && _token!.isNotEmpty;

  static Map<String, String> headersAutenticados() {
    final tokenAtual = _token;

    if (tokenAtual == null || tokenAtual.isEmpty) {
      throw const AuthServiceException('Usuario nao autenticado.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $tokenAtual',
    };
  }

  /// Realiza o cadastro de um novo usuário.
  /// Retorna um mapa com:
  ///   - `success` (bool)
  ///   - `message` (String) — mensagem de sucesso ou erro
  ///   - `field` (String?) — nome do campo inválido (apenas em caso de erro de validação)
  static Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
    required String senha,
    required String confirmarSenha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'cpf': cpf,
              'telefone': telefone,
              'senha': senha,
              'confirmarSenha': confirmarSenha,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final loginData = await login(email: email, senha: senha);
        if (loginData['success'] == true) {
          data['uid'] = loginData['uid'];
          data['token'] = loginData['token'];
        }
      }
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão. Verifique se o servidor está rodando.',
      };
    }
  }

  /// Realiza o login de um usuário existente.
  /// Retorna um mapa com:
  ///   - `success` (bool)
  ///   - `message` (String) — mensagem de sucesso ou erro
  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        _armazenarSessao(data);
      }
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão. Verifique se o servidor está rodando.',
      };
    }
  }

  /// Envia e-mail de recuperação de senha.
  /// O servidor verifica se o e-mail existe no Firebase antes de enviar.
  /// Retorna um mapa com:
  ///   - `success` (bool)
  ///   - `message` (String) — mensagem de sucesso ou erro
  static Future<Map<String, dynamic>> recuperarSenha({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão. Verifique se o servidor está rodando.',
      };
    }
  }

  static void _armazenarSessao(Map<String, dynamic> data) {
    final tokenRecebido = data['token']?.toString();
    final uidRecebido = data['uid']?.toString();

    if (tokenRecebido != null && tokenRecebido.isNotEmpty) {
      _token = tokenRecebido;
    }
    if (uidRecebido != null && uidRecebido.isNotEmpty) {
      _uid = uidRecebido;
    }
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

