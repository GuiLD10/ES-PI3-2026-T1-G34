// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Servico de startups que se comunica com Firebase Functions

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/startup_model.dart';

class StartupService {
  static const String _functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue: 'http://localhost:5001/mesclainvest-d3745/us-central1',
  );

  static Future<List<StartupModel>> listarStartups() async {
    final data = await _getJson('startups-listStartups');
    final startupsJson = data['data'];

    if (startupsJson is! List) {
      throw const StartupServiceException(
        'Resposta invalida ao buscar startups.',
      );
    }

    return startupsJson
        .whereType<Map>()
        .map((item) => StartupModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<StartupModel> buscarStartupPorId(String id) async {
    final startupId = id.trim();

    if (startupId.isEmpty) {
      throw const StartupServiceException('ID da startup e obrigatorio.');
    }

    final data = await _getJson(
      'startups-getStartupById',
      queryParameters: {'startupId': startupId},
    );
    final startupJson = data['data'];

    if (startupJson is! Map) {
      throw const StartupServiceException(
        'Resposta invalida ao buscar startup.',
      );
    }

    return StartupModel.fromJson(Map<String, dynamic>.from(startupJson));
  }
  static Future<void> criarPerguntaStartup({
    required String startupId,
    required String authorName,
    required String question,
    required String questionType,
  }) async {

    // Validacao do ID da startup
    if (startupId.trim().isEmpty) {
      throw const StartupServiceException(
        'ID da startup e obrigatorio.',
      );
    }

    // Validacao do nome do autor
    if (authorName.trim().isEmpty) {
      throw const StartupServiceException(
        'Nome do autor e obrigatorio.',
      );
    }

    // Validacao da pergunta
    if (question.trim().isEmpty) {
      throw const StartupServiceException(
        'Pergunta obrigatoria.',
      );
    }

    // Chama a Firebase Function usando _postJson
    final data = await _postJson(
      'startups-createStartupQuestion',
      {
        'startupId': startupId.trim(),

        'authorName': authorName.trim(),

        'question': question.trim(),

        // publica ou privada
        'questionType': questionType,
      },
    );

    // Verifica se deu erro
    if (data['success'] != true) {
      throw StartupServiceException(
        data['message'] ?? 'Erro ao enviar pergunta.',
      );
    }
  }

  static Future<Map<String, dynamic>> _getJson(
    String functionName, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await http
          .get(
            _functionUri(functionName, queryParameters),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw const StartupServiceException('Resposta invalida das Functions.');
      }

      final data = Map<String, dynamic>.from(decoded);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] != true) {
        throw StartupServiceException(
          _extractMessage(data) ?? 'Erro ao buscar dados de startups.',
        );
      }

      return data;
    } on StartupServiceException {
      rethrow;
    } catch (_) {
      throw const StartupServiceException(
        'Erro de conexao. Verifique se o emulador das Functions esta rodando.',
      );
    }
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

  static Uri _functionUri(
    String functionName,
    Map<String, String>? queryParameters,
  ) {
    return Uri.parse(
      '$_functionsBaseUrl/$functionName',
    ).replace(queryParameters: queryParameters);
  }

  static String? _extractMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message == null) return null;

    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class StartupServiceException implements Exception {
  final String message;

  const StartupServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
